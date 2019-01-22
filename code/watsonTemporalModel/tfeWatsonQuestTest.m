
clearvars;
close all;





% Leave the simulatedPsiParams empty to try a random set of params
simulatedPsiParams = [];

% This is a low-pass TTF in noisy fMRI data
simulatedPsiParams = [10 1 0.83 1];

% This is a band-pass TTF in noisy fMRI data
%simulatedPsiParams = [1.47 1.75 0.83 1];

% How talkative is the simulation
showPlots = true;
verbose = true;
nTrials = 128;

%% Set up Q+.

% Get the default Q+ params
myQpParams = qpParams;

% Add the stimulus domain. Log spaced frequencies between 2 and 64 Hz
nStims = 24; 
myQpParams.stimParamsDomainList = {logspace(log10(2),log10(64),nStims)};

% The number of outcome categories.
myQpParams.nOutcomes = 25;

% The headroom is the proportion of outcomes that are reserved above and
% below the min and max output of the Watson model to account for noise
headroom = [0.1 0.1];

% Create an anonymous function from qpWatsonTemporalModel in which we
% specify the number of outcomes for the y-axis response
myQpParams.qpPF = @(f,p) qpWatsonTemporalModel(f,p,myQpParams.nOutcomes,headroom);


% Define the parameter ranges
tau = 0.5:0.5:10;	% time constant of the center filter (in msecs)
kappa = 0.5:0.25:3;	% multiplier of the time-constant for the surround
zeta = 0:0.25:2;	% multiplier of the amplitude of the surround
sigma = 0:0.25:2;	% width of the BOLD fMRI noise against the 0-1 y vals
myQpParams.psiParamsDomainList = {tau, kappa, zeta, sigma};

% Pick some random params to simulate if none provided (but insist on some
% noise)
if isempty(simulatedPsiParams)
    simulatedPsiParams = [randsample(tau,1) randsample(kappa,1) randsample(zeta,1) 1];
end

% Derive some lower and upper bounds from the parameter ranges. This is
% used later in maximum likelihood fitting
lowerBounds = [tau(1) kappa(1) zeta(1) sigma(1)];
upperBounds = [tau(end) kappa(end) zeta(end) sigma(end)];

% Create a simulated observer
myQpParams.qpOutcomeF = @(f) qpSimulatedObserver(f,myQpParams.qpPF,simulatedPsiParams);

% Warn the user that we are initializing
if verbose
    tic
    fprintf('Initializing Q+. This may take a minute...\n');
end

% Initialize Q+
questData = qpInitialize(myQpParams);

% Warn the user we are about to start
if verbose
    toc
    fprintf('Press space to start.\n');
    pause
    fprintf('Fitting...');
end










%% Construct the model object
temporalFit = tfeIAMP('verbosity','none');


%% Temporal domain of the stimulus
deltaT = 100; % in msecs
totalTime = 336000; % in msecs. This is a 5:36 duration experiment
stimulusStruct.timebase = linspace(0,totalTime-deltaT,totalTime/deltaT);
nTimeSamples = size(stimulusStruct.timebase,2);


%% Specify the stimulus struct.
% We will create a set of stimulus blocks, each 12 seconds in duration.
% Every 6th stimulus block (starting with the first) is a "zero frequency"
% stimulus condition and thus will serve as the reference condition for a
% linear regression model
eventTimes=[];
eventDuration=12000; % block duration in msecs
for ii=0:27
    if mod(ii,6)~=0
        eventTimes(end+1) = ii*eventDuration;
    end
end
nInstances=length(eventTimes);
defaultParamsInfo.nInstances = nInstances;
for ii=1:nInstances
    stimulusStruct.values(ii,:)=zeros(1,nTimeSamples);
    stimulusStruct.values(ii,(eventTimes(ii)/deltaT)+1:eventTimes(ii)/deltaT+eventDuration/deltaT)=1;
end

% Create a set of parameter values that are derived from the Watson model
% We first assign a random stimulus frequency to each stimulus instance

freqInstances = myQpParams.stimParamsDomainList(randi(length(myQpParams.stimParamsDomainList),nInstances,1));

%freqInstances = [2,4,8,16,32,64,2,4,8,16,32,64,2,4,8,16,32,64,2,4,8,16,32];
%freqInstances = [2 4 8 16 32 64 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4];


% Now obtain the BOLD fMRI %change amplitude response for each frequency
% given a set of parameters for the Watson model
modelAmplitudes = watsonTemporalModel(freqInstances, simulatedPsiParams);


%% Get the default forward model parameters
params0 = temporalFit.defaultParams('defaultParamsInfo', defaultParamsInfo);

% Set the amplitude params to those defined by the Watson model above
params0.paramMainMatrix=modelAmplitudes';

fprintf('Default model parameters:\n');
temporalFit.paramPrint(params0);
fprintf('\n');



%% Define a kernelStruct. In this case, a double gamma HRF
hrfParams.gamma1 = 6;   % positive gamma parameter (roughly, time-to-peak in secs)
hrfParams.gamma2 = 12;  % negative gamma parameter (roughly, time-to-peak in secs)
hrfParams.gammaScale = 10; % scaling factor between the positive and negative gamma componenets

kernelStruct.timebase=linspace(0,15999,16000);

% The timebase is converted to seconds within the function, as the gamma
% parameters are defined in seconds.
hrf = gampdf(kernelStruct.timebase/1000, hrfParams.gamma1, 1) - ...
    gampdf(kernelStruct.timebase/1000, hrfParams.gamma2, 1)/hrfParams.gammaScale;
kernelStruct.values=hrf;

% Normalize the kernel to have unit amplitude
[ kernelStruct ] = normalizeKernelArea( kernelStruct );




%% Create and plot modeled responses

% Set the noise level and report the params
params0.noiseSd = simulatedPsiParams(end);

% Make the noise pink
params0.noiseInverseFrequencyPower = 1;

fprintf('Simulated model parameters:\n');
temporalFit.paramPrint(params0);
fprintf('\n');

% First create and plot the response without noise and without convolution
modelResponseStruct = temporalFit.computeResponse(params0,stimulusStruct,[],'AddNoise',false);

% Create a figure window
figure;
temporalFit.plot(modelResponseStruct,'NewWindow',false,'DisplayName','neural response');
hold on
% Add the stimulus profile to the plot
plot(stimulusStruct.timebase/1000,stimulusStruct.values(1,:),'-k','DisplayName','stimulus');

% Now plot the response with convolution and noise, as well as the kernel
modelResponseStruct = temporalFit.computeResponse(params0,stimulusStruct,kernelStruct,'AddNoise',true);

temporalFit.plot(modelResponseStruct,'NewWindow',false,'DisplayName','noisy BOLD response');
plot(kernelStruct.timebase/1000,kernelStruct.values/max(kernelStruct.values),'-b','DisplayName','kernel');


%% Initialize the response struct
TR = 1000; % in msecs
responseStruct.timebase = linspace(0,totalTime,totalTime/TR);
responseStruct.values = zeros(1,length(responseStruct.timebase));



%% Construct a packet and model params
thePacket.stimulus = stimulusStruct;
thePacket.response = responseStruct;
thePacket.kernel = kernelStruct;
thePacket.metaData = [];



% downsample the modelResponseStruct.values to match what we have for the
% fmri study: 

testRoiSignal = decimate(modelResponseStruct.values,10);

sampleSignal = testRoiSignal(1);

latestPoint = 1;

pctBOLDbins = 0:(myQpParams.noOutcomes - 1):1;

while latestPoint < length(testRoiSignal)
    if length(testRoiSignal) - latestPoint < 5
        sampleLength = length(testRoiSignal) - latestPoint;
    else
        sampleLength = randi(5);
    end
    
    clear sampleSignal
    
    latestPoint = latestPoint + sampleLength; 

    sampleSignal = testRoiSignal(1:latestPoint);

    sampleSignal = detrend(sampleSignal);
    sampleSignal = detrend(sampleSignal,'constant');
    
    thePacket.response.values(1:length(sampleSignal)) = sampleSignal;
    
    params = temporalFit.fitResponse(thePacket,...
        'defaultParamsInfo', defaultParamsInfo, ...
        'searchMethod','linearRegression');
    
    % how many "stims" have we presented? 
    stimNumber = ceil(length(sampleSignal)/12);
    stimNumberReal = stimNumber - floor(stimNumber/6) - 1;
    
    %pctBOLDbins = changePctSignalBins(params.paramMainMatrix,21);
    
    questData = questDataCopy;
    
    for i = 1:stimNumberReal
        outcome = discretize(params.paramMainMatrix(i),pctBOLDbins);
        questData = qpUpdate(questData,freqInstances(i),outcome);
    end
    


end



%% Test the fitter
[paramsFit,fVal,modelResponseStruct] = ...
    temporalFit.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, ...
    'searchMethod','linearRegression');


fprintf('Model parameter from fits:\n');
temporalFit.paramPrint(paramsFit);
fprintf('\n');
% Plot of the temporal fit results
temporalFit.plot(modelResponseStruct,'Color',[0 1 0],'NewWindow',false,'DisplayName','model fit');
legend('show');legend('boxoff');
hold on;
plot(sampleSignal,'r');


% what does Quest think?
maxParamGuess = max(questData.posterior); 
maxIndex = questData.posterior == maxParamGuess;
paramGuesses = questData.psiParamsDomain(maxIndex,:);

hold off;
figure;
hold on;

for i = 1:size(paramGuesses,1)
    watsonRecoveredData = watsonTemporalModel([questData.trialData.stim],paramGuesses(i,:));
    semilogx([questData.trialData.stim],watsonRecoveredData,'*r');
end

