function [binAssignment, modelResponseStruct, params, thePacket] = tfeUpdate(thePacket, varargin)
% Takes in the tfeObject created with tfeInit along with thePacket. If
% thePacket.response is empty, will simulate an fMRI signal, fit that
% signal, and return outputs suitable for use with Quest +. 
%
% Syntax:
%  [binAssignment, modelResponseStruct, params, thePacket] = tfeUpdate(tfeObj, thePacket, varargin)
%
% Description:
%
%
% Inputs:
%   tfeObj                - temporal fitting engine object created using 
%                           tfeInit
%   thePacket             - struct for input into tfe, containing stimulus and kernel
%                           values and timespace.
%
% Optional key/value pairs:
%   'qpParams'     - A struct generated from qpParams. This should contain
%                    a value for nOutcomes other than the default (2) to
%                    ensure enough range of values for Q+ to work with. 
%   'headroom'     - 2x1 vector specifying what proportion of the nOutcomes 
%                    from qpParams will be used as extra on top and bottom. 
%                    Default - .1
%   'stimulusVec'  - If simulation mode, a vector of stimulus frequencies
%   'boldLimits'   - The upper and lower values of percent change for the 
%                    BOLD signal. These should be well above and below what
%                    you think the dynamic range should be. 
%                    Default - [-3,3]
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
%   binOutput      - nNoneBaselineTrials x 1 vector of integers referring to the bins
%                         that each stimulus generates
%   modelResponseStruct - The simulated response struct from tfe method fitResponse
%   thePacket           - The updated packet with response struct completed.
%   adjustedAmplitudes    - A 
%
% Examples:
%{
    % SIMULATION MODE
    nTrials = 35;
    thePacket = makePacket('nTrials',nTrials);

    % Generate a random stimulus vector
    stimulusVec = randsample([0, 0, 1.875,3.75,7.5,10,15,20,30],nTrials,true);

    % Initialize some parameters to pass to tfeUpdate from Quest
    myQpParams = qpParams;
    % The number of outcome categories.
    myQpParams.nOutcomes = 51;
    
    % The headroom is the proportion of outcomes that are reserved above and
    % below the min and max output of the Watson model to account for noise
    headroom = .1;

    % Define binned psychometric fuction
    myQpParams.qpPF = @(f,p) qpWatsonTemporalModel(f,p,myQpParams.nOutcomes,headroom);

    % Create some simulatedPsiParams
    tau = 0.5:0.5:10;	% time constant of the center filter (in msecs)
    kappa = 0.5:0.25:3;	% multiplier of the time-constant for the surround
    zeta = 0:0.25:2;	% multiplier of the amplitude of the surround
    beta = 0.8:0.1:1;   % multiplier that maps watson 0-1 to BOLD % bins
    sigma = 0:0.25:2;	% width of the BOLD fMRI noise against the 0-1 y vals
    myQpParams.psiParamsDomainList = {tau, kappa, zeta, beta, sigma};
    simulatedPsiParams = [randsample(tau,1) randsample(kappa,1) randsample(zeta,1) randsample(beta,1) 1];

    % This is the continuous psychometric fuction
    myQpParams.continuousPF = @(f) watsonTemporalModel(f,simulatedPsiParams);

    % This is the veridical psychometric fuction in binned outcomes
    myQpParams.qpOutcomeF = @(f) qpSimulatedObserver(f,myQpParams.qpPF,simulatedPsiParams);
    
    % Identify which stimulus is the "baseline" stimulus
    baselineStimulus = 0;

    % Perform the simulation
    [binAssignment, modelResponseStruct, params, thePacketOut] = tfeUpdate(thePacket, 'qpParams', myQpParams, 'headroom', headroom, 'stimulusVec',stimulusVec, 'baselineStimulus', baselineStimulus);

    % Plot the results
    figure
    subplot(2,1,1)
    plot(thePacketOut.response.timebase,thePacketOut.response.values,'.k');
    hold on
    plot(modelResponseStruct.timebase,modelResponseStruct.values,'-r');
    subplot(2,1,2)
    stimulusVecPlot = stimulusVec;
    stimulusVecPlot(stimulusVecPlot==0)=1;
    semilogx(stimulusVecPlot,binAssignment,'xk')
    refline(0,myQpParams.nOutcomes.*headroom);
    refline(0,myQpParams.nOutcomes-myQpParams.nOutcomes.*headroom);
    ylim([1 myQpParams.nOutcomes]);

%}


%% Begin function


%% Parse input
p = inputParser;

% Required input
p.addRequired('thePacket',@isstruct);

% Optional params
p.addParameter('rngSeed',rng(1),@isstruct);
p.addParameter('qpParams',[],@isstruct);
p.addParameter('headroom', .1, @isnumeric);
p.addParameter('stimulusVec', [], @isnumeric);
p.addParameter('baselineStimulus', [], @isscalar);
p.addParameter('simulateMaxBOLD', 3, @isscalar);
p.addParameter('fitMaxBOLD', 3, @isscalar);
p.addParameter('noiseSD',.25, @isscalar);
p.addParameter('pinkNoise',1, @isnumeric);
p.addParameter('TRmsecs',800, @isnumeric);
p.addParameter('verbose', false, @islogical);

% Parse and check the parameters
p.parse( thePacket, varargin{:});

% We need to have at least one "baseline" stimulus in the vector of
% stimuli to support reference-coding of the BOLD fMRI responses
if isempty(find(p.Results.stimulusVec==p.Results.baselineStimulus, 1))
    error('The stimulusVec must have at least one instance of the baselineStimulus.');
end

% Set a default params value based on how many stimulus values there should
% have been (which is based on the number of rows in the stimulus.values
% struct)
defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);

% Construct the model object
tfeObj = tfeIAMP('verbosity','none');

%% Test if we are in simulate mode
% If we are in simulate mode, we need to have the temporal fitting engine
% generate the parameter estimates based on the qpWatsonTemporalModel
% expected bins (based on the stimulus frequencies in stimulusVec).

if isempty(thePacket.response)
    % If we're in simulation mode, we need a stimulus vector of frequencies.
    if isempty(p.Results.stimulusVec)
        error('No timeseries (thePacket.reponse is empty) and no stimulusVec.')
    end
    
    % We also need qpParams
    if isempty(p.Results.qpParams)
        error('No qpParams. You need to initialize Q+ to use this in simulation mode.');
    end
    
    % Initialize params0, which will allow us to create the forward model.
    params0 = tfeObj.defaultParams('defaultParamsInfo', defaultParamsInfo);
    params0.noiseSd = p.Results.noiseSD;
    params0.noiseInverseFrequencyPower = p.Results.pinkNoise;
    modelAmplitude = zeros(length(p.Results.stimulusVec),1);
        
    % Obtain the continuous amplitude response
    for ii = 1:length(p.Results.stimulusVec)        
        modelAmplitude(ii) = p.Results.qpParams.continuousPF(p.Results.stimulusVec(ii));    
    end

    % We enforce reference coding, such that the response to the baseline
    % stimulus is assigned the bin for a 0% BOLD response.
    modelAmplitude = modelAmplitude - round(mean(modelAmplitude==p.Results.baselineStimulus));

    % Scale the responses by the simulateMaxBold and place in the
    % paramMainMatrix
    params0.paramMainMatrix = modelAmplitude.*p.Results.simulateMaxBOLD;
        
    % Lock the MATLAB random number generator to give us the same BOLD
    % noise on every iteration.
    rng(p.Results.rngSeed);
    
    % Create a simulated BOLD fMRI time series
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

% Fit the timeseries, providing a set of amplitudes for the stimulus events
[params,~,modelResponseStruct] = tfeObj.fitResponse(thePacket,...
    'defaultParamsInfo', defaultParamsInfo, 'searchMethod','linearRegression');

% We engage in reference coding, such that the amplitude of any stimulus is
% expressed w.r.t. the "baseline" stimuli
adjustedAmplitudes = params.paramMainMatrix - mean(params.paramMainMatrix(p.Results.stimulusVec==p.Results.baselineStimulus));

% Convert the adjusted BOLD amplitudes into outcome bins.
yVals = adjustedAmplitudes./p.Results.fitMaxBOLD;

% Get the number of outcomes (bins)
nOutcomes = p.Results.qpParams.nOutcomes;

% Determine the number of bins to be reserved for upper and lower headroom
nLower = round(nOutcomes.*p.Results.headroom);
nUpper = round(nOutcomes.*p.Results.headroom);
nMid = nOutcomes - nLower - nUpper;

% Map the responses to categories
binAssignment = 1+round(yVals.*nMid)+nLower;
binAssignment(binAssignment > nOutcomes)=nOutcomes;
binAssignment(binAssignment < 1)=1;


end % main function



