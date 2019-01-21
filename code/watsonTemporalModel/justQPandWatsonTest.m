clearvars
close all

% Define the veridical model params

% Leave the simulatedPsiParams empty to try a random set of params
simulatedPsiParams = [];

% This is a low-pass TTF in noisy fMRI data
%simulatedPsiParams = [10 1 0.83 1];

% This is a band-pass TTF in noisy fMRI data
%simulatedPsiParams = [1.47 1.75 0.83 1];

% How talkative is the simulation
showPlots = true;
verbose = true;
nTrials = 128;

%% Set up Q+.

% Get the default Q+ params
myQpParams = qpParams;

% Add the stimulus domain. Log spaced frequencies between 2 and 64 Hz
nStims = 24; 
myQpParams.stimParamsDomainList = {logspace(log10(2),log10(64),nStims)};

% The number of outcome categories.
myQpParams.nOutcomes = 25;

% The headroom is the proportion of outcomes that are reserved above and
% below the min and max output of the Watson model to account for noise
headroom = [0.1 0.1];

% Create an anonymous function from qpWatsonTemporalModel in which we
% specify the number of outcomes for the y-axis response
myQpParams.qpPF = @(f,p) qpWatsonTemporalModel(f,p,myQpParams.nOutcomes,headroom);


% Define the parameter ranges
tau = 0.5:0.5:10;	% time constant of the center filter (in msecs)
kappa = 0.5:0.25:3;	% multiplier of the time-constant for the surround
zeta = 0:0.25:2;	% multiplier of the amplitude of the surround
sigma = 0:0.25:2;	% width of the BOLD fMRI noise against the 0-1 y vals
myQpParams.psiParamsDomainList = {tau, kappa, zeta, sigma};

% Pick some random params to simulate if none provided (but insist on some
% noise)
if isempty(simulatedPsiParams)
    simulatedPsiParams = [randsample(tau,1) randsample(kappa,1) randsample(zeta,1) 1];
end

% Derive some lower and upper bounds from the parameter ranges. This is
% used later in maximum likelihood fitting
lowerBounds = [tau(1) kappa(1) zeta(1) sigma(1)];
upperBounds = [tau(end) kappa(end) zeta(end) sigma(end)];

% Create a simulated observer
myQpParams.qpOutcomeF = @(f) qpSimulatedObserver(f,myQpParams.qpPF,simulatedPsiParams);

% Warn the user that we are initializing
if verbose
    tic
    fprintf('Initializing Q+. This may take a minute...\n');
end

% Initialize Q+
questData = qpInitialize(myQpParams);

% Warn the user we are about to start
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
    semilogx(freqDomain,watsonTemporalModel(freqDomain,simulatedPsiParams(1:end-1)),'-k');
    ylim([-0.5 1.5]);
    xlabel('log stimulus Frequency [Hz]');
    ylabel('Relative response amplitude');
    title('Estimate of Watson TTF');
    hold on
    currentFuncHandle = plot(freqDomain,watsonTemporalModel(freqDomain,simulatedPsiParams(1:end-1)),'-k');

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

%% Run simulated trials
for tt = 1:nTrials

    % Get stimulus for this trial
    stim = qpQuery(questData);
    
    % Simulate outcome
    outcome = myQpParams.qpOutcomeF(stim);
    
    % Update quest data structure
    questData = qpUpdate(questData,stim,outcome); 
    
    % Update the plot
    if showPlots
        
        % Current guess at the TTF, along with stims and outcomes
        yOutcome = ((outcome-nLower)/nMid)-(1/myQpParams.nOutcomes)/2;
        subplot(2,1,1)
        scatter(stim,yOutcome,'o','MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',.2)
        psiParamsIndex = qpListMaxArg(questData.posterior);
        psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
        delete(currentFuncHandle)
        currentFuncHandle = plot(freqDomain,watsonTemporalModel(freqDomain,psiParamsQuest(1:end-1)),'-r');

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

if verbose
    fprintf('\n');
end


%% Find out QUEST+'s estimate of the stimulus parameters, obtained
% on the gridded parameter domain.
psiParamsIndex = qpListMaxArg(questData.posterior);
psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
fprintf('Simulated parameters: %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    simulatedPsiParams(1),simulatedPsiParams(2),simulatedPsiParams(3),simulatedPsiParams(4));
fprintf('Max posterior QUEST+ parameters: %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4));

%% Find aximum likelihood fit.  Use psiParams from QUEST+ as the starting
% parameter for the search, and impose as parameter bounds the range
% provided to QUEST+.
psiParamsFit = qpFit(questData.trialData,questData.qpPF,psiParamsQuest,questData.nOutcomes,...
    'lowerBounds', lowerBounds,'upperBounds',upperBounds);
fprintf('Maximum likelihood fit parameters: %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsFit(1),psiParamsFit(2),psiParamsFit(3),psiParamsFit(4));

