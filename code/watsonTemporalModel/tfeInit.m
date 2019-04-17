function [tfeObj, thePacket] = tfeInit(varargin)
% Returns an initiated tfeObject and thePacket for use with tfeUpdate
%
% Syntax:
%  [tfeObj, thePacket] = tfeInit(varargin)
%
% Description:
%	Generates a stimulusStruct and kernelStruct based on optional inputs
%	and prepares tfeObj and thePacket for use with tfeUpdate. 
%
% Inputs:
%   tfeObj         - temporal fitting engine object created using tfeInit
%   thePacket      - struct for input into tfe, containing stimulus and kernel
%                    values and timespace.
%
% Optional key/value pairs:
%   'nTrials'               - How many trials (including baseline trials)
%                             Default - 25
%   'trialLengthSecs'       - How long is each trial
%                             Default - 12
%   'baselineTrialRate'     - How often should a baseline trial occur (every X trials)
%                             Default - 6
%   'stimulusStructDeltaT'  - The resolution of the stimulus struct in msecs
%                             Default - 100
%   'verbose'               - How talkative. 
%                             Default - False
% Outputs:
%   tfeObj               - Object handle
%   thePacket            - Structure.
%
% Examples:
%{
%   [tfeObj, thePacket] = tfeInit()
%}


%% Parse input
p = inputParser;

% Required input
%p.addRequired('sceneGeometry',@isstruct);

% Optional params
p.addParameter('nTrials', 25, @isscalar);
p.addParameter('trialLengthSecs', 12, @isscalar);
p.addParameter('baselineTrialRate', 6, @isscalar);
p.addParameter('stimulusStructDeltaT',100,@isnumeric);
p.addParameter('verbose', false, @islogical);

% Parse and check the parameters
p.parse( varargin{:});

%% Construct the model object
tfeObj = tfeIAMP('verbosity','none');


%% Temporal domain of the stimulus
deltaT = p.Results.stimulusStructDeltaT; % in msecs
totalTime = p.Results.nTrials*p.Results.trialLengthSecs*1000; % in msecs.
eventDuration = p.Results.trialLengthSecs*1000; % block duration in msecs

% Define the timebase
stimulusStruct.timebase = linspace(0,totalTime-deltaT,totalTime/deltaT);
nTimeSamples = size(stimulusStruct.timebase,2);

% Create the stimulus struct
nonBaselineEvents = 1;
totalEvents = 0;
eventTimes=[];
stimulusStruct.values(1,:) = zeros(1,nTimeSamples);


% This loop will create a stimulus struct that has the property that each 
% non-baseline trial will create its own regressor (row). Each baseline
% trial will be added to the first regressor. 
for ii=1:(p.Results.nTrials)
    totalEvents = totalEvents + 1;
    eventTimes(totalEvents) = (ii-1)*eventDuration;
    if mod(ii-1,p.Results.baselineTrialRate)~=0
        nonBaselineEvents = nonBaselineEvents + 1;
        stimulusStruct.values(nonBaselineEvents,:)=zeros(1,nTimeSamples);
        stimulusStruct.values(nonBaselineEvents,(eventTimes(totalEvents)/deltaT)+1:eventTimes(totalEvents)/deltaT+eventDuration/deltaT)=1;
    else
        stimulusStruct.values(1,(eventTimes(totalEvents)/deltaT+1):eventTimes(totalEvents)/deltaT+eventDuration/deltaT)=1;       
    end
    
    
end

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



%% Construct a packet and model params
thePacket.stimulus = stimulusStruct;
thePacket.response = [];
thePacket.kernel = kernelStruct;
thePacket.metaData = [];


end