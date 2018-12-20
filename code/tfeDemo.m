% tfeDemo
%
% This routine generates simulated time-series fMRI data that might arise
% from the presentation of 12 second blocks of whole-field luminance
% flicker at different temporal frequencies. The temporal response
% properties of the corted are defined by the parameteres of Beau Watson's
% temporal sensitivity model.


clear all


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
freqSet = [2 4 8 16 32 64];
freqInstances = freqSet(randi(length(freqSet),nInstances,1));

% Now obtain the BOLD fMRI %change amplitude response for each frequency
% given a set of parameters for the Watson model
watsonParams = [0.004 2 1 1];
modelAmplitudes = watsonTemporalModel(freqInstances, watsonParams);


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
params0.noiseSd = 0.5;

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




%% Construct a packet and model params
thePacket.stimulus = stimulusStruct;
thePacket.response = modelResponseStruct;
thePacket.kernel = kernelStruct;
thePacket.metaData = [];

% We will fit each average response as a single stimulus in a packet, so
% each packet therefore contains a single stimulus instamce.
defaultParamsInfo.nInstances = nInstances;

%% Test the fitter
[paramsFit,fVal,modelResponseStruct] = ...
    temporalFit.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, ...
    'searchMethod','linearRegression');

%% Report the output
fprintf('Model parameter from fits:\n');
temporalFit.paramPrint(paramsFit);
fprintf('\n');

% Plot of the temporal fit results
temporalFit.plot(modelResponseStruct,'Color',[0 1 0],'NewWindow',false,'DisplayName','model fit');
legend('show');legend('boxoff');
hold off

% Plot of simulated vs. recovered parameter values
figure
plot(params0.paramMainMatrix,paramsFit.paramMainMatrix,'or')
xlabel('simulated instance amplitudes') % x-axis label
ylabel('estimated instance amplitudes') % y-axis label
