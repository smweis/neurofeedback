function [binOutput, modelResponseStruct, thePacket] = tfeUpdate(tfeObj, thePacket, varargin)
% Takes in the tfeObject created with tfeInit along with thePacket. If
% thePacket.response is empty, will
%
% Syntax:
%  [tfeObj, thePacket] = tfeInit(, varargin)
%
% Description:
%
%
% Inputs:
%   tfeObj         - temporal fitting engine object created using tfeInit
%   thePacket      - struct for input into tfe, containing stimulus and kernel
%                    values and timespace.
%                    size(thePacket.stimulus.values,1) = nNonBaselineTrials
%
% Optional key/value pairs:
%  'eyePoseLB/UB'         - A 1x4 vector that provides the lower (upper)

%
% Outputs:
%   binOutput      - nNoneBaselineTrials x 1 vector of integers referring to the bins
%                    that each stimulus generates
%
% Examples:
%{
    % SIMULATION MODE
    nTrials = 35;
    baselineTrialRate = 6;
    nNonBaselineTrials = nTrials - ceil(nTrials/baselineTrialRate);
    [tfeObj, thePacket] = tfeInit('nTrials',nTrials,'baselineTrialRate',baselineTrialRate);


    % Initialize some parameters to pass to tfeUpdate from Quest
    myQpParams = qpParams;
    % The number of outcome categories.
    myQpParams.nOutcomes = 51;
    
    % The headroom is the proportion of outcomes that are reserved above and
    % below the min and max output of the Watson model to account for noise
    headroom = [0.1 0.3];

    % Create an anonymous function from qpWatsonTemporalModel in which we
    % specify the number of outcomes for the y-axis response
    myQpParams.qpPF = @(f,p) qpWatsonTemporalModel(f,p,myQpParams.nOutcomes,headroom);
    tau = 0.5:0.5:10;	% time constant of the center filter (in msecs)
    kappa = 0.5:0.25:3;	% multiplier of the time-constant for the surround
    zeta = 0:0.25:2;	% multiplier of the amplitude of the surround
    beta = 0.8:0.1:1.1; % multiplier that maps watson 0-1 to BOLD % bins
    sigma = 0:0.25:2;	% width of the BOLD fMRI noise against the 0-1 y vals
    myQpParams.psiParamsDomainList = {tau, kappa, zeta, beta, sigma};
    simulatedPsiParams = [randsample(tau,1) randsample(kappa,1) randsample(zeta,1) randsample(beta,1) 1];
    myQpParams.qpOutcomeF = @(f) qpSimulatedObserver(f,myQpParams.qpPF,simulatedPsiParams);
    

    % Generate a random stimulus vector
    stimulusVec = randsample([1.875,2.5,3.75,5,7.5,10,15,20,30],nNonBaselineTrials,true);
    
    [binOutput] = tfeUpdate(tfeObj, thePacket, 'qpParams', myQpParams, 'headroom', headroom, 'stimulusVec',stimulusVec)


    

%}


%% Parse input
p = inputParser;

% Required input
p.addRequired('tfeObj',@isobject);
p.addRequired('thePacket',@isstruct);

% Optional params
%p.addParameter('qpOutcomeF', [], @(x)(isempty(x) | isa(x,'function_handle')));
p.addParameter('qpParams',[],@isstruct);
p.addParameter('headroom', [], @isnumeric);
p.addParameter('stimulusVec', [], @isnumeric);
p.addParameter('boldLimits', [-2,3], @isnumeric);
p.addParameter('noiseSD',0.25, @isscalar);
p.addParameter('pinkNoise',1, @isnumeric);
p.addParameter('TRmsecs',800, @isnumeric);
p.addParameter('verbose', false, @islogical);

% Parse and check the parameters
p.parse( tfeObj, thePacket, varargin{:});



defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);

%% Test if we are in simulate mode
% If we are in simulate mode, we need to have the temporal fitting engine
% generate the parameter estimates based on the qpWatsonTemporalModel
% expected bins (based on the stimulus frequencies in stimulusVec).

if isempty(thePacket.response)
    % If we're in simulation mode, we need a stimulus vector of frequencies.
    if isempty(p.Results.stimulusVec)
        error('No timeseries (thePacket.reponse is empty) and no stimulusVec.')
    end
    
    if isempty(p.Results.qpParams)
        error('No qpParams. You need to initialize Q+ to use this in simulation mode.');
    end
    
    
    % Initialize params0, which will allow us to create the forward model.
    params0 = tfeObj.defaultParams('defaultParamsInfo', defaultParamsInfo);
    params0.noiseSd = p.Results.noiseSD;
    params0.noiseInverseFrequencyPower = p.Results.pinkNoise;
    modelAmplitudeBin = zeros(length(p.Results.stimulusVec),1);
    
    % Here we go from stimulus frequency -> bins (what qpOutcomeF returns)
    for ii = 1:length(p.Results.stimulusVec)
        modelAmplitudeBin(ii) = p.Results.qpParams.qpOutcomeF(p.Results.stimulusVec(ii));
    end
    
    % Now we go from bin # -> BOLD% signal (defined as the lower bound of
    %                                       the bin that value is in.)
    params0.paramMainMatrix = binToBold(modelAmplitudeBin,p.Results.qpParams.nOutcomes,p.Results.boldLimits)';
    
    % Estimate the response amplitude from the BOLD% signal. Lock the
    % MATLAB random number generator to give us the same BOLD noise on
    % every iteration.
    rng(1);
    thePacket.response = tfeObj.computeResponse(params0,thePacket.stimulus,thePacket.kernel,'AddNoise',true);
    
    % Resample the response to the BOLD fMRI TR
    BOLDtimebase = min(thePacket.response.timebase):p.Results.TRmsecs:max(thePacket.response.timebase);
    thePacket.response= tfeObj.resampleTimebase(thePacket.response,BOLDtimebase);
    
end

%% Fit the response struct with the IAMP model
% Note, if we skipped simulation mode, this means we have a response struct
% in thePacket and we can estimate the parameters directly.
%
% If we did not skip simulation mode, the response struct was created above
% using the stimulus frequencies passed through stimulusVec.


% We fit the timeseries to create a list of parameters, which are
% in % BOLD signal.

[params,fVal,modelResponseStruct] = tfeObj.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, ...
    'searchMethod','linearRegression');

% Then turn that BOLD% signal into bins.
binOutput = boldToBin(params.paramMainMatrix,p.Results.qpParams.nOutcomes,p.Results.boldLimits)';

end % main function




function pctBOLD = binToBold(observedBins,nBins,boldLimits)
% Convert a set of bin numbers to percent BOLD signals
%
% Inputs:
% observedBins - n x 1 vector of bin numbers
% nBins        - integer, number of possible bins
% boldLimits   - 2 x 1 vector of min and max possible BOLD percent
%                   signal changes

boldBins = linspace(boldLimits(1),boldLimits(2),nBins);
pctBOLD = boldBins(observedBins);

end


function binOutput = boldToBin(pctBOLD,nBins,boldLimits)
% Convert a set of bin numbers to percent BOLD signals
%
% Inputs:
% pctBold      - n x 1 vector of scalars
% nBins        - integer, number of possible bins
% boldLimits   - 2 x 1 vector of min and max possible BOLD percent
%                   signal changes

boldBins = linspace(boldLimits(1),boldLimits(2),nBins);
binOutput = discretize(pctBOLD,boldBins);

end

