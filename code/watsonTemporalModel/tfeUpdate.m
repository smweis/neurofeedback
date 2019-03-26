function [binOutput] = tfeUpdate(tfeObj, thePacket, varargin)
% My description
%
% Syntax:
%  [tfeObj, thePacket] = tfeInit(, varargin)
%
% Description:
%	.
%
% Inputs:
%   sceneGeometry         - Structure. SEE: createSceneGeometry
%
% Optional key/value pairs:
%  'eyePoseLB/UB'         - A 1x4 vector that provides the lower (upper)

%
% Outputs:
%   tfeObj               - Object handle
%   thePacket            - Structure.
%
% Examples:
%{
    % SIMULATION MODE
    nTrials = 35;
    baselineTrialRate = 6;
    nSimulatedTrials = nTrials - ceil(nTrials/baselineTrialRate);
    [tfeObj, thePacket] = tfeInit('nTrials',nTrials,'baselineTrialRate',baselineTrialRate);


    % Initialize some parameters to pass to tfeUpdate from Quest
    myQpParams = qpParams;
    % The number of outcome categories.
    myQpParams.nOutcomes = 51;

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
    
    % The headroom is the proportion of outcomes that are reserved above and
    % below the min and max output of the Watson model to account for noise
    headroom = [0.1 0.3];

    % Generate a random stimulus vector
    stimulusVec = randsample([1.875,2.5,3.75,5,7.5,10,15,20,30],nSimulatedTrials,true);
    
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
p.addParameter('boldLimits', [], @isnumeric);
p.addParameter('verbose', false, @islogical);

% Parse and check the parameters
p.parse( tfeObj, thePacket, varargin{:});



defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);

%% Test if we are in simulate mode
if isempty(thePacket.response)
    
    params0 = tfeObj.defaultParams('defaultParamsInfo', defaultParamsInfo);
    params0.noiseSd = 0.02;
    params0.noiseInverseFrequencyPower = 1;
    
    modelAmplitudeBin = zeros(length(p.Results.stimulusVec),1);
    % Here we go from frequency -> bins
    for ii = 1:length(p.Results.stimulusVec)
        modelAmplitudeBin(ii) = p.Results.qpParams.qpOutcomeF(p.Results.stimulusVec(ii));
    end
    
    % Now we go from bin # -> BOLD% signal (defined as the lower bound of
    %                                       the bin that value is in.)
    params0.paramMainMatrix = binToBold(modelAmplitudeBin,p.Results.qpParams.nOutcomes,p.Results.boldLimits)';
    
    % Estimate the response amplitude from the binned BOLD% signal
    thePacket.response = tfeObj.computeResponse(params0,thePacket.stimulus,thePacket.kernel,'AddNoise',true);

end

%% Fit the response struct with the IAMP model


% We fit the timeseries to create a list of parameters, which are
% in % BOLD signal. 

params = tfeObj.fitResponse(thePacket,...
            'defaultParamsInfo', defaultParamsInfo, ...
            'searchMethod','linearRegression');

% Then turn that BOLD% signal into bins. 
binOutput = boldToBin(params.paramMainMatrix,p.Results.qpParams.nOutcomes,p.Results.boldLimits)';








    function pctBOLD = binToBold(observedBins,nBins,boldLimits)
        % Convert a set of bin numbers to percent BOLD signals
        % 
        % Inputs:
        % observedBins - n x 1 vector of bin numbers 
        % nBins        - integer, number of possible bins
        % 
        % Optional:
        % boldLimits   - 2 x 1 vector of min and max possible BOLD percent
        %                   signal changes
        
        
        if isempty(boldLimits)
            boldLimits = [-2,3];
        end
        boldBins = linspace(boldLimits(1),boldLimits(2),nBins);
        pctBOLD = boldBins(observedBins);
        
    end


    function binOutput = boldToBin(pctBOLD,nBins,boldLimits)
        % Convert a set of bin numbers to percent BOLD signals
        % 
        % Inputs:
        % pctBold      - n x 1 vector of scalars
        % nBins        - integer, number of possible bins
        % 
        % Optional:
        % boldLimits   - 2 x 1 vector of min and max possible BOLD percent
        %                   signal changes
        
        
        if isempty(boldLimits)
            boldLimits = [-2,3];
        end
        boldBins = linspace(boldLimits(1),boldLimits(2),nBins);
        binOutput = discretize(pctBOLD,boldBins);
        
    end

end