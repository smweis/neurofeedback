%% QP + Watson TTF + TFE + real fmri data


%% Do we want to reinitialize?
reinitializeQuest = 1;

% Clean up
if reinitializeQuest
    clearvars('-except','questDataCopy','reinitializeQuest');
    close all;
else
    clearvars('-except','reinitializeQuest');
    close all;
end



%% Load in fMRI + stim frequency data and create tfeObj and thePacket


% Let's do this with 1 run for now. 
runNum = 1; % possible values: ints 1-5

% Where is stimulus data?
% Optimal results
stimDataLoc = ['processed_fmri_data', filesep, 'optimalResults.mat'];

% Real-time pipline results
% stimDataLoc = ['processed_fmri_data', filesep, 'rtSimResults.mat'];


load(stimDataLoc);

%% Define the veridical model params

% Which stimulus (in freq Hz) is the "baseline" stimulus? This stimulus
% should be selected with the expectation that the neural response to this
% stimulus will be minimal as compared to all other stimuli.
baselineStimulus = 0;



% Create the stimulus vec (with zero trials = baseline)
stimulusVec = stimParams(runNum).params.stimFreq;
stimulusVec(stimulusVec == 0) = baselineStimulus;

% Some information about the trials?
nTrials = length(stimulusVec); % how many trials
trialLengthSecs = 12; % seconds per trial
baselineTrialRate = 6; % present a gray screen (baseline trial) every X trials
stimulusStructDeltaT = 100; % the resolution of the stimulus struct in msecs
boldTRmsecs = 800; % msecs


% Use this for calculating the stim struct resolution
stimulusStructPerTrial = trialLengthSecs * 1000 / stimulusStructDeltaT;
responseStructPerTrial = trialLengthSecs * 1000 / boldTRmsecs;


% Initialize thePacket
thePacket = createPacket('nTrials',nTrials,...
                         'trialLengthSecs',trialLengthSecs,...
                         'stimulusStructDeltaT',stimulusStructDeltaT);

% Set up the response struct;
thePacket.response.values = detrendTimeseries(runNum,:);
responseTimebaseLength = length(thePacket.stimulus.timebase)/(boldTRmsecs/stimulusStructDeltaT);
thePacket.response.timebase = linspace(0,(responseTimebaseLength-1)*boldTRmsecs,responseTimebaseLength);

% We'll see how quickly we can converge on the full model, but Beta is set
% for now...
watsonParams = watsonParams(runNum,:);
watsonParams(:,4) = 1;

% How talkative is the simulation?
showPlots = true;
verbose = true;

options = optimoptions(@fmincon,'Display', 'off');


%% Set up Q+

% Get the default Q+ params
myQpParams = qpParams;

% Add the stimulus domain. Log spaced frequencies between ~2 and 30 Hz
myQpParams.stimParamsDomainList = {[stimParams(1).params.allFreqs]};

% Add 0 to the stimulus domain manually
myQpParams.stimParamsDomainList{1}(end+1) = 0;
nStims = length(myQpParams.stimParamsDomainList{1}); 

% The number of outcome categories.
myQpParams.nOutcomes = 51;

% The headroom is the proportion of outcomes that are reserved above and
% below the min and max output of the Watson model to account for noise
headroom = .1;

% Create an anonymous function from qpWatsonTemporalModel in which we
% specify the number of outcomes for the y-axis response
myQpParams.qpPF = @(f,p) qpWatsonTemporalModel(f,p,myQpParams.nOutcomes,headroom);

% Define the parameter ranges
tau = 0.5:0.5:8;	% time constant of the center filter (in msecs)
kappa = 0.5:0.25:2;	% multiplier of the time-constant for the surround
zeta = 0:0.25:2;	% multiplier of the amplitude of the surround
beta = 0.8:0.1:1; % multiplier that maps watson 0-1 to BOLD % bins
sigma = 0:0.5:2;	% width of the BOLD fMRI noise against the 0-1 y vals
myQpParams.psiParamsDomainList = {tau, kappa, zeta, beta, sigma};


% Derive some lower and upper bounds from the parameter ranges. This is
% used later in maximum likelihood fitting
lowerBounds = [tau(1) kappa(1) zeta(1) beta(1) sigma(1)];
upperBounds = [tau(end) kappa(end) zeta(end) beta(end) sigma(end)];

% Create a simulated observer
%myQpParams.qpOutcomeF = @(f) qpSimulatedObserver(f,myQpParams.qpPF,watsonParams);

% Warn the user that we are initializing
if verbose
    tic
    fprintf('Initializing Q+. This may take a minute...\n');
end



% Initialize Q+. Save some time if we're debugging
if reinitializeQuest
    if exist('questDataCopy','var')
        questData = questDataCopy;
    else
        questData = qpInitialize(myQpParams);
        questDataCopy = questData;
    end
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
    figure

    % Set up the BOLD fMRI response and model fit
    subplot(2,1,1)
    currentBOLDHandleData = plot(thePacket.stimulus.timebase,zeros(size(thePacket.stimulus.timebase)),'-k');
    hold on
    currentBOLDHandleFit = plot(thePacket.stimulus.timebase,zeros(size(thePacket.stimulus.timebase)),'-r');
    xlim([min(thePacket.stimulus.timebase) max(thePacket.stimulus.timebase)]);
    ylim([min(thePacket.response.values)-.2 max(thePacket.response.values)+.2]);    
    xlabel('time [msecs]');
    ylabel('BOLD fMRI % change');
    title('BOLD fMRI data');
    
    % Set up the TTF figure
    subplot(2,1,2)
    freqDomain = logspace(0,log10(40),100);
    setup = semilogx(freqDomain,watsonTemporalModel(freqDomain,watsonParams),'-k');
    delete(setup);
    ylim([-0.5 1.5]);
    xlabel('log stimulus Frequency [Hz]');
    ylabel('Relative response amplitude');
    title('Estimate of Watson TTF');
    hold on
    % These are just fillers;
    scatterFuncHandle = semilogx(freqDomain,watsonTemporalModel(freqDomain,watsonParams));
    currentFuncHandle = semilogx(freqDomain,watsonTemporalModel(freqDomain,watsonParams),'-k');
    currentFuncHandle2 = semilogx(freqDomain,watsonTemporalModel(freqDomain,watsonParams),'-b');


end


% Create clean copies of each of these
thePacketOrig = thePacket;
questDataUntrained = questData;

% Randomly (?) initialize
fitMaxBOLD = 3;

%% Run simulated trials
for tt = 1:nTrials
    
    
    % Get stimulus for this trial, which we are ignoring.
    questStim(tt) = qpQuery(questData);
    
    % Get current stim
    stim(tt) = stimulusVec(tt);
    
    % Update thePacket to be just the current trials.
    thePacket.stimulus.values = thePacketOrig.stimulus.values(1:tt,1:tt*stimulusStructPerTrial);
    thePacket.stimulus.timebase = thePacketOrig.stimulus.timebase(:,1:tt*stimulusStructPerTrial);
    
    thePacket.response.values = thePacketOrig.response.values(1:tt*responseStructPerTrial);
    thePacket.response.timebase = thePacketOrig.response.timebase(:,1:tt*responseStructPerTrial);
    
    % Mean center the response
    thePacket.response.values = thePacket.response.values - mean(thePacket.response.values);
    
    
    
    % Find max bold according to Quest. 
    psiParamsIndex = qpListMaxArg(questData.posterior);
    psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
    fitMaxBOLD = fitMaxBOLD.*psiParamsQuest(4);
    
    
    questData = questDataUntrained;
    
    % Simulate outcome with tfe
    [outcomes, modelResponseStruct, thePacketOut, yVals]  = tfeUpdate(thePacket,myQpParams,stim,0,'fitMaxBOLD',fitMaxBOLD);

    
    
    % Update quest data structure
    
    for yy = 1:tt
        questData = qpUpdate(questData,stim(yy),outcomes(yy));
    end
    
    % This is a lot of code to try to fit the data to obtain watson
    % parameters for plotting. We end up fitting the average of each
    % stimulus frequency across all presentations of that frequency.
    
    % Only works with more than 1 trial of data
    if tt > 2
        
        % Identify the unique stims and the mean of the BOLD response for those
        % stims
        [uniqueStims,~,k] = unique(stim(1,:));
        numberUniqueStims = numel(uniqueStims);
        meanBoldPerStim = zeros(size(stim,1),numberUniqueStims);
        for nu = 1:numberUniqueStims
            indexToThisUniqueValue = (nu==k)';
            meanBoldPerStim(:,nu) = mean(yVals(indexToThisUniqueValue));
            stdBoldPerStim(:,nu) = std(yVals(indexToThisUniqueValue));
        end
        
        stimulusFreqHzFine = logspace(log10(min(stim)),log10(max(stim)),100);
        splineInterpolatedMax = max(spline(uniqueStims,meanBoldPerStim,stimulusFreqHzFine));        
        myObj = @(p) sqrt(sum((meanBoldPerStim-watsonTemporalModel(uniqueStims,p)).^2));
        x0 = [randsample(tau,1), randsample(kappa,1), randsample(zeta,1),randsample(beta,1),randsample(sigma,1)];
        watsonParams = fmincon(myObj,x0,[],[],[],[],[],[],[], options);
        
    
    
    end
    


    % Update the plot
    if tt > 2 && showPlots
        
        
        

        psiParamsIndex = qpListMaxArg(questData.posterior);
        psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
        
        % Current guess at the TTF, along with stims and outcomes

        % Simulated BOLD fMRI time-series and fit       
        subplot(2,1,1)
        delete(currentBOLDHandleData)
        delete(currentBOLDHandleFit)
        currentBOLDHandleData = plot(thePacket.response.timebase,thePacket.response.values,'.k');
        currentBOLDHandleFit = plot(modelResponseStruct.timebase,modelResponseStruct.values,'-r');
        
        
        % TTF figure
        subplot(2,1,2)
        delete(scatterFuncHandle);
        scatterFuncHandle = scatter(stim(1:tt),yVals(1:tt),'o','MarkerFaceColor','b','MarkerEdgeColor','none','MarkerFaceAlpha',.2);
        delete(currentFuncHandle);
        delete(currentFuncHandle2);
        currentFuncHandle = semilogx(freqDomain,watsonTemporalModel(freqDomain,watsonParams),'-r');
        currentFuncHandle2 = semilogx(freqDomain,watsonTemporalModel(freqDomain,psiParamsQuest),'-b');
        legend('Single trials','fmincon fit','Quest+ fit');
        ylim([-10 10]);
        drawnow
    end
    
    

end


%% Find out QUEST+'s estimate of the stimulus parameters, obtained
% on the gridded parameter domain.
psiParamsIndex = qpListMaxArg(questData.posterior);
psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
fprintf('Max posterior QUEST+ parameters: %0.1f, %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4),psiParamsQuest(5));

%% Find maximum likelihood fit. Use psiParams from QUEST+ as the starting
% parameter for the search, and impose as parameter bounds the range
% provided to QUEST+.
psiParamsFit = qpFit(questData.trialData,questData.qpPF,psiParamsQuest,questData.nOutcomes,...
    'lowerBounds', lowerBounds,'upperBounds',upperBounds);
fprintf('Maximum likelihood fit parameters: %0.1f, %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsFit(1),psiParamsFit(2),psiParamsFit(3),psiParamsFit(4),psiParamsFit(5));

%% Fmincon solution
fprintf('fmincon solution:                  %0.1f, %0.1f, %0.1f, %0.1f, %0.1f\n', ...
    watsonParams(1),watsonParams(2),watsonParams(3),watsonParams(4),watsonParams(5));


