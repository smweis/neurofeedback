%% Initialize the stimuli text file
mkdir(fullfile(subjectPath,'stimLog'));


%% Initialize a questData struct

% stimParamsDomainList - the possible frequencies to sample
% psiParamsDomainList - Parameter space of the psychometric parameters
% qpPf - our psychometric function
% qpOutcomeF - this needs to be specified or it defaults
% nOutcomes - our possible number of outcomes (based on
%             qpWatsonTemporalModel) where we discretize the output to be 
%             .5% - 1.5% incremented by .1%

questData = qpInitialize('stimParamsDomainList',{[2 4 8 16 32 64]},...
    'psiParamsDomainList',{-.00012:.0004:.01,.5:.5:5,1:4,.25:.5:2.25},...
    'qpPF',@qpWatsonTemporalModel,...
    'nOutcomes',21);



% we want an initialized copy of this so we can re-run it each time. 
questDataCopy = questData;





nTrials = 21;





% this is the range of outcomes that Q+ wants. We can set this dynamically
% after it is initialized and we get a few values back.

pctBOLDbinsMin = -.5;
pctBOLDbinsMax = 1.5;

pctBOLDbins = pctBOLDbinsMin:(pctBOLDbinsMax-pctBOLDbinsMin)/20:pctBOLDbinsMax;



%% Initialize the temporal fitting engine
temporalFit = tfeIAMP('verbosity','none');

%% Construct HRF kernel


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


%% Specify the stimulus struct.
deltaT = 100; % in msecs
totalTime = 336000; % in msecs. This is a 5:36 duration experiment
stimulusStruct.timebase = linspace(0,totalTime-deltaT,totalTime/deltaT);
nTimeSamples = size(stimulusStruct.timebase,2);


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
    stimulusStruct.values(ii,eventTimes(ii)/deltaT:eventTimes(ii)/deltaT+eventDuration/deltaT)=1;
end


%% Initialize the response struct
TR = 1000; % in msecs
responseStruct.timebase = linspace(0,totalTime,totalTime/TR);
responseStruct.values = zeros(1,length(responseStruct.timebase));



    
%% Construct a packet and model params
thePacket.stimulus = stimulusStruct;
thePacket.response = responseStruct;
thePacket.kernel = kernelStruct;
thePacket.metaData = [];

