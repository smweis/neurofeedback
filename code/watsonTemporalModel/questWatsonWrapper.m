%% Right now, we can't use TBTB, so do this by hand:

addpath(genpath('/Users/nfuser/Documents/MATLAB/projects/neurofeedback'));
addpath(genpath('/tmp/neurofeedback'));
addpath(genpath('/Users/nfuser/Documents/MATLAB/toolboxes/mQUESTPlus'));
addpath(genpath('/Users/nfuser/Documents/MATLAB/toolboxes/temporalFittingEngine'));

mainDataLoc = '/tmp/neurofeedback/mainData.mat';

%% Initialize a questData struct

% stimParamsDomainList - the possible frequencies to sample
% psiParamsDomainList - Parameter space of the psychometric parameters
% qpPf - our psychometric function
% qpOutcomeF - this needs to be specified or it defaults
% nOutcomes - our possible number of outcomes (based on
%             qpWatsonTemporalModel) where we discretize the output to be 
%             .5% - 1.5% incremented by .1%



questData = qpInitialize('stimParamsDomainList',{[.5 1 2 4 8 16 32 64]},...
    'psiParamsDomainList',{-.00012:.0004:.01,.5:.5:5,1:4,.25:.5:2.25},...
    'qpPF',@qpWatsonTemporalModel,...
    'nOutcomes',21);

questDataCopy = questData;

nTrials = 21;
pctBOLDbins = -.5:.1:1.5;



%% Initialize the temporal fitting engine
temporalFit = tfeIAMP('verbosity','none');

% construct HRF kernel
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



% Temporal domain of the stimulus
% Goes from 0 to 330000 msecs, by 100msecs
deltaT = 100; % in msecs
eventDuration = 120; % how long is a trial in increments of deltaT
totalTime = 253000; % in msecs. Make this 
stimulusStruct.timebase = linspace(0,totalTime-deltaT,totalTime/deltaT);
nTimeSamples = size(stimulusStruct.timebase,2);



% Specify the stimulus struct.
initialDelay = 1000;
eventTimes=linspace(initialDelay,totalTime-(eventDuration*deltaT),nTrials);
nInstances=length(eventTimes);
defaultParamsInfo.nInstances = 1;
stimulusStruct.values = [];


% initialize the response struct
TR = 1000; % in msecs
responseStruct.timebase = linspace(0,totalTime,totalTime/TR);
responseStruct.values = zeros(1,length(responseStruct.timebase));



    
%% Construct a packet and model params
thePacket.stimulus = stimulusStruct;
thePacket.response = responseStruct;
thePacket.kernel = kernelStruct;
thePacket.metaData = [];




trigger = input('Waiting for trigger...','s');

if strcmp(trigger,'t')
    triggerTime = datetime;
else
    triggerTime = wait_for_trigger;
end

% if mainData.mat doesn't exist, wait until it does. 
while ~exist(mainDataLoc)
    pause(.01);
end

% Load mainData.mat (should just be mainData struct). 
load(mainDataLoc);

% at first, initialize this to start at the beginning. update after the
% first loop
lengthMainData = 1;


numTRsPerTrial = 4;


pctBOLD = zeros(1,nTrials);
stim = zeros(1,nTrials);
outcome = zeros(1,nTrials);


%% The main trial loop
for i = 1:nTrials
    
    
    % Get a stimulus from quest:
    stim(i) = qpQuery(questData);
    
    % update the stimulus struct
    defaultParamsInfo.nInstances = i;
    thePacket.stimulus.values(i,:) = zeros(1,nTimeSamples);
    thePacket.stimulus.values(i,eventTimes(i)/deltaT:eventTimes(i)/deltaT+eventDuration)=1;
    
    
    
    
    % Load mainData from runNeurofeedback and the neurofeedback toolbox
    while length(mainData) == lengthMainData 
        load(mainDataLoc);
    end
    
    % initialize the roiSignal vector
    if ~exist('roiSignal')
        roiSignal = mainData(1).roiSignal(1);
    end
    
    lengthRoiSignal = length(roiSignal);
    
    % vectorize roiSignal from mainData
    for j = lengthMainData:length(mainData)
        for k = 1:length(mainData(j).roiSignal)
            roiSignal(end+1) = mainData(j).roiSignal(k);
        end
    end
    
    while length(roiSignal) - lengthRoiSignal < numTRsPerTrial
        load(mainDataLoc);
        for j = lengthMainData:length(mainData)
            for k = 1:length(mainData(j).roiSignal)
                roiSignal(end+1) = mainData(j).roiSignal(k);
            end
        end 
 
    end
    
    
    
    lengthRoiSignal = length(roiSignal);
    
    % assign responses to thePacket
    thePacket.response.values(lengthMainData:lengthRoiSignal) = roiSignal(lengthMainData:end);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %This is where we would process the Packet to de-trend, etc,.%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%z
    
    
    % Update length of mainData
    lengthMainData = length(mainData);
    
 
    % we now get params for the whole time course. 
    params = temporalFit.fitResponse(thePacket,...
              'defaultParamsInfo', defaultParamsInfo, ...
              'searchMethod','linearRegression');
    
          
    % TO DO: 
    % 1. De-trending? When/where
    % 2. Baselining - how do we estimate percent signal, rather than just
    %       the raw signal from V1?
    % 3. TEST THIS: Re-run quest with all NEWLY estimated outcomes and original stim. 
    % 4. Related - need to PAUSE Quest plus for baseline trials. Need to
    %       also have a pre-initialized version of Q+ with a few random
    %       trials to start. 
    
    
    % Probably need to do the below on the de-trended data each time. But
    % it should work! 
    
    %{      
    pctBOLD(i) = params.paramMainMatrix(i)
    
    % for now, need to make sure we're not above ceiling or below floor
    if pctBOLD(i) < -.5
        pctBOLD(i) = -.4;
    elseif pctBOLD(i) > 1.5
        pctBOLD(i) = 1.4;
    end
    
    
    outcome(i) = discretize(pctBOLD(i),pctBOLDbins(i));
    
    % start quest fresh, so we can re-run it with the new 
    questData = questDataCopy;
    
    for x = 1:i
        questData = qpUpdate(questData,stim(x),outcome(x));
    end
    %}
    
end





%% Report the output
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
hold off
