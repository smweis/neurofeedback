function [tfeParams,scaledBOLDresponse,watsonParams] = optimalFlickerAnalysisTFE(detrendTimeseries,stimParams,TR,nTrials,trialLength)
% Fit a timeseries of fMRI data using the TFE
% In particular this code is built for fitting flicker using
% watsonTemporalModel

% Syntax:
%  [tfeParams,scaledBOLDresponse,watsonParams] = optimalFlickerAnalysisTFE(detrendTimeseries,stimParams,TR,ntrials,trialLength)
%
% Description:
%	
% Inputs:
%   detrendTimeseries     - 1xn vector in which each entry is a timepoint
%                           in average signal from an ROI per TR in an fMRI 
%                           dataset that has been detrended.  
%   stimParams            - a struct extracted from the play_flash.m
%                           paradigm. One field of the struct must be
%                           stimFreq. A 1xnTrials vector of stimulus
%                           frequencies. 
%   TR                    - length of TR in msecs
%   nTrials               - number of trials
%   trialLength           - length of each trial in msecs
% Outputs:
%   tfeParams             - parameter estimates from tfe
%   watsonParams          - estimate of Watson temporal model parameters
%                           using fmincon
%   scaledBOLDresponse    - the detrended BOLD parameter estimates
% Examples
%{
    
%}
%{
    
%}

%% Model V1 timeseries with tFE
% Construct the model object
temporalFit = tfeIAMP('verbosity','none');


%% Temporal domain of the stimulus
deltaT = 100; % in msecs
totalTime = length(detrendTimeseries)*TR; % in msecs.

stimulusStruct.timebase = linspace(0,totalTime-deltaT,totalTime/deltaT);
nTimeSamples = size(stimulusStruct.timebase,2);


% We will create a set of stimulus blocks, each 12 seconds in duration.
% Every 6th stimulus block (starting with the first) is a "zero frequency"
% stimulus condition and thus will serve as the reference condition for a
% linear regression model
eventTimes=[];
for ii=0:nTrials-1
    if mod(ii,6)~=0
        eventTimes(end+1) = ii*trialLength;
    end
end
nInstances=length(eventTimes);
defaultParamsInfo.nInstances = nInstances;
for ii=1:nInstances
    stimulusStruct.values(ii,:)=zeros(1,nTimeSamples);
    stimulusStruct.values(ii,(eventTimes(ii)/deltaT)+1:(eventTimes(ii)/deltaT+trialLength/deltaT))=1;
end


% Define a kernelStruct. In this case, a double gamma HRF
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



%% Initialize the response struct
responseStruct.timebase = linspace(0,totalTime-TR,totalTime/TR);
responseStruct.values = zeros(1,length(responseStruct.timebase));
responseStruct.values = detrendTimeseries;


%% Construct a packet and model params
thePacket.stimulus = stimulusStruct;
thePacket.response = responseStruct;
thePacket.kernel = kernelStruct;
thePacket.metaData = [];


tfeParams = temporalFit.fitResponse(thePacket,...
            'defaultParamsInfo', defaultParamsInfo, ...
            'searchMethod','linearRegression');
    
% Load stim frequencies that ARE NOT zero
stims = stimParams.params.stimFreq(stimParams.params.stimFreq>0);

% scale the BOLD response by the min.
pctBOLDresponse = tfeParams.paramMainMatrix';
minBOLD = min(pctBOLDresponse);
if minBOLD < 0
    scaledBOLDresponse = pctBOLDresponse - minBOLD;
else
    scaledBOLDresponse = pctBOLDresponse;
    minBOLD = 0;
end

% Identify the unique stims and the mean of the BOLD response for those
% stims
[uniqueStims,~,k] = unique(stims(1,:));
numberUniqueStims = numel(uniqueStims);
meanBoldPerStim = zeros(size(stims,1),numberUniqueStims);
for nu = 1:numberUniqueStims
    indexToThisUniqueValue = (nu==k)';
    meanBoldPerStim(:,nu) = mean(scaledBOLDresponse(:,indexToThisUniqueValue),2);
    stdBoldPerStim(:,nu) = std(scaledBOLDresponse(:,indexToThisUniqueValue));
end



stimulusFreqHzFine = logspace(log10(1.875),log10(30),100);
splineInterpolatedMax = max(spline(uniqueStims,meanBoldPerStim,stimulusFreqHzFine));
% Scale the x vector so that the max is zero
meanBoldPerStim = meanBoldPerStim ./ splineInterpolatedMax;
scaledBOLDresponse = scaledBOLDresponse ./splineInterpolatedMax;
myObj = @(p) sqrt(sum((meanBoldPerStim-watsonTemporalModel(uniqueStims,p)).^2));
x0 = [2 2 2];
watsonParams = fmincon(myObj,x0);

figure
semilogx(stims,scaledBOLDresponse,'b*');
hold on; semilogx(uniqueStims,meanBoldPerStim,'r*');
xlabel('Stimulus Frequency, log');
ylabel('Arbitrary units, relative activation');
semilogx(stimulusFreqHzFine,watsonTemporalModel(stimulusFreqHzFine,watsonParams),'-k');
legend('Individual trial data','Mean per freqHz','Best Watson fit');


end

