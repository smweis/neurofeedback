function [binOutput, modelResponseStruct, thePacket, pctBOLD] = tfeUpdate(tfeObj, thePacket, varargin)
% Takes in the tfeObject created with tfeInit along with thePacket. If
% thePacket.response is empty, will simulate an fMRI signal, fit that
% signal, and return outputs suitable for use with Quest +. 
%
% Syntax:
%  [binOutput, modelResponseStruct, thePacket] = tfeUpdate(tfeObj, thePacket, varargin)
%
% Description:
%
%
% Inputs:
%   tfeObj         - temporal fitting engine object created using tfeInit
%   thePacket      - struct for input into tfe, containing stimulus and kernel
%                    values and timespace.
%
% Optional key/value pairs:
%   'qpParams'     - A struct generated from qpParams. This should contain
%                    a value for nOutcomes other than the default (2) to
%                    ensure enough range of values for Q+ to work with. 
%   'headroom'     - 2x1 vector specifying what proportion of the nOutcomes 
%                    from qpParams will be used as extra on top and bottom. 
%                    Default - [0.1 0.3]
%   'stimulusVec'  - If simulation mode, a vector of stimulus frequencies
%   'boldLimits'   - The upper and lower values of percent change for the 
%                    BOLD signal. These should be well above and below what
%                    you think the dynamic range should be. 
%                    Default - [-2,3]
%   'noiseSD'      - How many standard deviations of noise should TFE use 
%                    to simulate neural data. 
%                    Default - .25
%   'pinkNoise'    - Logical, whether or not to include 1/f noise in the TFE
%                    simulation. 
%                    Default - 1 (true)
%   'TRmsecs'      - If in simulation mode, how to downsample the simulated
%                    BOLD signal so that the response.values struct has 
%                    one value per TR. 
%                    Default - 800
%   'verbose'      - How talkative. 
%                    Default - False
% 
% Outputs:
%   binOutput           - nNoneBaselineTrials x 1 vector of integers referring to the bins
%                         that each stimulus generates
%   modelResponseStruct - The simulated response struct from tfe method fitResponse
%   thePacket           - The updated packet with response struct completed.
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
    
    [binOutput, modelResponseStruct, thePacketOut] = tfeUpdate(tfeObj, thePacket, 'qpParams', myQpParams, 'headroom', headroom, 'stimulusVec',stimulusVec);


    

%}



%% Begin function

%% Parse input
p = inputParser;

% Required input
p.addRequired('tfeObj',@isobject);
p.addRequired('thePacket',@isstruct);

% Optional params
p.addParameter('rngSeed',rng(1),@isstruct);
p.addParameter('qpParams',[],@isstruct);
p.addParameter('headroom', [], @isnumeric);
p.addParameter('stimulusVec', [], @isnumeric);
p.addParameter('boldLimitsSimulate', [-3,3], @isnumeric);
p.addParameter('boldLimitsFit', [-3,3], @isnumeric);
p.addParameter('noiseSD',.25, @isscalar);
p.addParameter('pinkNoise',1, @isnumeric);
p.addParameter('TRmsecs',800, @isnumeric);
p.addParameter('verbose', false, @islogical);

% Parse and check the parameters
p.parse( tfeObj, thePacket, varargin{:});


% Set a default params value based on how many stimulus values there should
% have been (which is based on the number of rows in the stimulus.values
% struct)
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
    params0.paramMainMatrix = binToBold(modelAmplitudeBin,p.Results.qpParams.nOutcomes,p.Results.boldLimitsSimulate)';
    
    % Estimate the response amplitude from the BOLD% signal. Lock the
    % MATLAB random number generator to give us the same BOLD noise on
    % every iteration.
    rng(p.Results.rngSeed);
    thePacket.response = tfeObj.computeResponse(params0,thePacket.stimulus,thePacket.kernel,'AddNoise',true);
    
    % Resample the response to the BOLD fMRI TR
    BOLDtimebase = min(thePacket.response.timebase):p.Results.TRmsecs:max(thePacket.response.timebase);
    thePacket.response= tfeObj.resampleTimebase(thePacket.response,BOLDtimebase);
    
    % Mean center the response
    thePacket.response.values = thePacket.response.values - mean(thePacket.response.values);
    
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
binOutput = boldToBin(params.paramMainMatrix,p.Results.qpParams.nOutcomes,p.Results.boldLimitsFit)';
pctBOLD = params.paramMainMatrix;


end % main function




function pctBOLD = binToBold(observedBins,nBins,boldLimits)
% Convert a set of bin numbers to percent BOLD signals
%
% Inputs:
% observedBins - n x 1 vector of bin numbers
% nBins        - integer, number of possible bins
% boldLimits   - 2 x 1 vector of min and max possible BOLD percent
%                   signal changes

if observedBins > nBins
    error('An observed bin falls outside the number of possible bins.');
end


boldBins = linspace(min(boldLimits),max(boldLimits),nBins);
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


% If pctBOLD falls outside of the bold limit range, set it equal to the 
% maximum (or minimum) possible bold limit. 
pctBOLD(pctBOLD > max(boldLimits)) = max(boldLimits);
pctBOLD(pctBOLD < min(boldLimits)) = min(boldLimits);



boldBins = linspace(min(boldLimits),max(boldLimits),nBins);
binOutput = discretize(pctBOLD,boldBins);

end

