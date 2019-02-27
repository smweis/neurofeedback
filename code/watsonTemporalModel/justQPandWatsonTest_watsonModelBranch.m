%% demonstration of QP applied to Watson TTF fit to BOLD fMRI data

% Clean up
clearvars('-except','questDataCopy');
close all


%% Define the veridical model params

% Leave the simulatedPsiParams empty to try a random set of params.
% Here are some params to try for specific TTF shapes:
%	 A low-pass TTF in noisy fMRI data: [10 1 0.83 1 1]
%  A band-pass TTF in noisy fMRI data: [1.47 1.75 0.83 1 1]
simulatedPsiParams = [];

% How many trials to run?
nTrials = 128;

% How talkative is the simulation?
showPlots = true;
verbose = true;


%% Set up Q+

% Get the default Q+ params
myQpParams = qpParams;

% Add the stimulus domain. Log spaced frequencies between 2 and 64 Hz
nStims = 24; 
myQpParams.stimParamsDomainList = {logspace(log10(1),log10(64),nStims)};

% The number of outcome categories.
myQpParams.nOutcomes = 31;

% The headroom is the proportion of outcomes that are reserved above and
% below the min and max output of the Watson model to account for noise
headroom = [0.1 0.3];

% Create an anonymous function from qpWatsonTemporalModel in which we
% specify the number of outcomes for the y-axis response
myQpParams.qpPF = @(f,p) qpWatsonTemporalModel(f,p,myQpParams.nOutcomes,headroom);

% Define the parameter ranges
tau = 0.5:1:10.5;	% time constant of the center filter (in msecs)
kappa = 0.5:0.5:3;	% multiplier of the time-constant for the surround
zeta = 0:0.5:2;	% multiplier of the amplitude of the surround
beta = 0.8:0.1:1.1; % multiplier that maps watson 0-1 to BOLD % bins
sigma = 0:0.25:2;	% width of the BOLD fMRI noise against the 0-1 y vals
myQpParams.psiParamsDomainList = {tau, kappa, zeta, beta, sigma};

% Pick some random params to simulate if none provided (but insist on some
% noise)
if isempty(simulatedPsiParams)
    simulatedPsiParams = [randsample(tau,1) randsample(kappa,1) randsample(zeta,1) randsample(beta,1) 1];
end

% Derive some lower and upper bounds from the parameter ranges. This is
% used later in maximum likelihood fitting
lowerBounds = [tau(1) kappa(1) zeta(1) beta(1) sigma(1)];
upperBounds = [tau(end) kappa(end) zeta(end) beta(end) sigma(end)];

% Create a simulated observer
myQpParams.qpOutcomeF = @(f) qpSimulatedObserver(f,myQpParams.qpPF,simulatedPsiParams);

% Warn the user that we are initializing
if verbose
    tic
    fprintf('Initializing Q+. This may take a minute...\n');
end


% Initialize Q+

if exist('questDataCopy','var')
    questData = questDataCopy;
else
    questData = qpInitialize(myQpParams);
    questDataCopy = questData;
end

% Prompt the user we to start the simulation
if verbose
    toc
    fprintf('Press space to start.\n');
    pause
    fprintf('Fitting...');
end

% Create a plot in which we can track the model progress
if showPlots
    % Set up the TTF figure
    figure
    subplot(2,1,1)
    freqDomain = logspace(0,log10(100),100);
    semilogx(freqDomain,watsonTemporalModel(freqDomain,simulatedPsiParams(1:end-2)),'-k');
    ylim([-0.5 1.5]);
    xlabel('log stimulus Frequency [Hz]');
    ylabel('Relative response amplitude');
    title('Estimate of Watson TTF');
    hold on
    currentFuncHandle = plot(freqDomain,watsonTemporalModel(freqDomain,simulatedPsiParams(1:end-2)),'-k');

    % Calculate the lower headroom bin offset. We'll use this later
    nLower = round(headroom(1)*myQpParams.nOutcomes);
    nUpper = round(headroom(1)*myQpParams.nOutcomes);
    nMid = myQpParams.nOutcomes - nLower - nUpper;
    
    % Set up the entropy x trial figure
    subplot(2,1,2)
    entropyAfterTrial = nan(1,nTrials);
    currentEntropyHandle = plot(1:nTrials,entropyAfterTrial,'*k');
    xlim([1 nTrials]);
    title('Model entropy by trial number');
    xlabel('Trial number');
    ylabel('Entropy');
end



% Here we set what the bins should be. The BOLD bins will be determined by
% arbitrary values for now. But in the scanner, we will empirically derive
% these. 
maxBOLD = 3;
minBOLD = -2;
boldBINS = linspace(minBOLD,maxBOLD,myQpParams.nOutcomes);

% The outcome bins will be determined by how much noise we expect around 0
% and 1. 
%maxOutcome = 1+3*simulatedPsiParams(end);
%minOutcome = -3*simulatedPsiParams(end);
maxOutcome = 1 + headroom(2);
minOutcome = 0 - headroom(1);
outcomeBINS = linspace(minOutcome,maxOutcome,myQpParams.nOutcomes);


%% Run simulated trials
for tt = 1:nTrials

    % Get stimulus for this trial
    stim = qpQuery(questData);
    
    % Simulate outcome
    %outcome = myQpParams.qpOutcomeF(stim);
    
    % Watson output is in the range of 0 to 1. We multiply this by the
    % simulated Beta parameter to see what the scaling should be. 
    watsonOutcome = watsonTemporalModel(stim,simulatedPsiParams(1:end-2)).*simulatedPsiParams(end-1);
    
    % We then add noise to the Watson output based on the simulated Sigma
    % parameter. 
    watsonOutcomeNoise = watsonOutcome+simulatedPsiParams(end)/10*randn();
    
    % Some logic that will ensure that we're not outside of our bins (see
    % above loop). 
    if watsonOutcomeNoise < minOutcome
        watsonOutcomeCapped = minOutcome;
    elseif watsonOutcomeNoise > maxOutcome
        watsonOutcomeCapped = maxOutcome;
    else
        watsonOutcomeCapped = watsonOutcomeNoise;
    end
    
    % Now we assign the watsonOutcome to a bin. 
    outcome = discretize(watsonOutcomeCapped,outcomeBINS);
    
    
    % This step should take the discretized outcome and turn it into BOLD
    % signal. Somehow. yOutcome is another way to calculate this in
    % watsonOutcome range. 
    
    boldOutcome(tt) = boldBINS(outcome);
    yOutcome(tt) = ((outcome-nLower)/nMid)-(1/myQpParams.nOutcomes)/2;

    % Update quest data structure
    questData = qpUpdate(questData,stim,outcome); 
    
    % Update the plot
    if showPlots
        
        % Current guess at the TTF, along with stims and outcomes
        subplot(2,1,1)
        scatter(stim,watsonOutcomeNoise,'o','MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',.2)
        psiParamsIndex = qpListMaxArg(questData.posterior);
        psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
        delete(currentFuncHandle)
        currentFuncHandle = plot(freqDomain,watsonTemporalModel(freqDomain,psiParamsQuest(1:end-2).*psiParamsQuest(end-1)),'-r');

        % Entropy plot
        subplot(2,1,2)
        delete(currentEntropyHandle)
        entropyAfterTrial(1:tt)=questData.entropyAfterTrial;
        plot(1:nTrials,entropyAfterTrial,'*k');
        xlim([1 nTrials]);
        ylim([0 nanmax(entropyAfterTrial)]);
        xlabel('Trial number');
        ylabel('Entropy');

        drawnow
    end
    
end

% Done with the simulation
if verbose
    fprintf('\n');
end


%% Find out QUEST+'s estimate of the stimulus parameters, obtained
% on the gridded parameter domain.
psiParamsIndex = qpListMaxArg(questData.posterior);
psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
fprintf('Simulated parameters: %0.1f, %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    simulatedPsiParams(1),simulatedPsiParams(2),simulatedPsiParams(3),simulatedPsiParams(4),simulatedPsiParams(5));
fprintf('Max posterior QUEST+ parameters: %0.1f, %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4),psiParamsQuest(5));

%% Find maximum likelihood fit. Use psiParams from QUEST+ as the starting
% parameter for the search, and impose as parameter bounds the range
% provided to QUEST+.
psiParamsFit = qpFit(questData.trialData,questData.qpPF,psiParamsQuest,questData.nOutcomes,...
    'lowerBounds', lowerBounds,'upperBounds',upperBounds);
fprintf('Maximum likelihood fit parameters: %0.1f, %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsFit(1),psiParamsFit(2),psiParamsFit(3),psiParamsFit(4),psiParamsFit(5));

