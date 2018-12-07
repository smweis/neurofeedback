%% Initialize a questData struct

% stimParamsDomainList - the possible frequencies to sample
% psiParamsDomainList - Parameter space of the psychometric parameters
% qpPf - our psychometric function
% qpOutcomeF - this needs to be specified or it defaults
% nOutcomes - our possible number of outcomes (based on
%             watsonTemporalModel) where we discretize the output to be 
%             .5% - 1.5% incremented by .1%



questData = qpInitialize('stimParamsDomainList',{[.5 1 2 4 8 16 32 64]},...
    'psiParamsDomainList',{-.00012:.0004:.01,.5:.5:5,1:4,.25:.5:2.25},...
    'qpPF',@watsonTemporalModel,...
    'nOutcomes',21);



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




%% The main quest part 
for i = 1:nTrials
    
    
    % Get a stimulus from quest:
    stim = qpQuery(questData);
    
    % update the stimulus struct
    defaultParamsInfo.nInstances = i;
    thePacket.stimulus.values(i,:) = zeros(1,nTimeSamples);
    thePacket.stimulus.values(i,eventTimes(i)/deltaT:eventTimes(i)/deltaT+eventDuration)=1;

    
    % INSERT NEUROFEEDBACK CODE IN HERE TO GET RAW V1 value
    % This then gets plugged into the thePacket.response for the stimulus
    %rawV1seed = bins(randi(21));
    
    rawV1seed = input('Pick a # ');
    for j = 1:12
        thePacket.response.values((j+(i-1)*12)) = rawV1seed + .1 * normrnd(0,1);
    end
    
    
    
    params = temporalFit.fitResponse(thePacket,...
              'defaultParamsInfo', defaultParamsInfo, ...
              'searchMethod','linearRegression');
    
    pctBOLD = params.paramMainMatrix(i);
    
    % for now, need to make sure we're not above ceiling or below floor
    if pctBOLD < -.5
        pctBOLD = -.4;
    elseif pctBOLD > 1.5
        pctBOLD = 1.4;
    end
    
    
    outcome = discretize(pctBOLD,pctBOLDbins);
    
    
    questData = qpUpdate(questData,stim,outcome);
end


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
