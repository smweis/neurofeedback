clear all;
close all;

%% Set up Q+. 

numStims = 20; % This parameter matters a lot for how Q+ calculates things.

stimParams = logspace(-.9,2,numStims); % x3 logarithmically equally
                                 % spaced points between 10^x1 and 10^x2                                 
%stimParams = [2 4 8 16 32 64];                                 


% The number of categories. DO NOT CHANGE THIS VALUE without also changing 
% qpWatsonTemporalModel. Right now, it is not a parameter that Q+ will
% search for, though it could be. 
nCategories = 21;


% Initialize Q+ 
questData = qpInitialize('stimParamsDomainList',{stimParams},...
'psiParamsDomainList',{.001:.002:.013,.5:.5:2,.5:.5:5},...
'qpPF',@qpWatsonTemporalModel,...
'nOutcomes',nCategories);

 
%% Adjust these parameters and run the script. 

% These are the simulated Watson parameters. The "right answer."
watsonParams = [.009 2 1];


% Number of trials to iterate through. 
nTrials = 128;

% Noise moves around the y-value from watsonTemporalModel. It's "dumb
% noise" at the moment, in the sense that the SD is the same across all
% possible frequencies. 
% I've tried from between 0 and .3. 
sdNoise = 0.4; 

%% Initialize a few things.
 
maxPost = zeros(nTrials,1); % the max posterior prob value in Q+
paramGuesses = zeros(nTrials,length(watsonParams)); % the current Watson parameters that are assigned that value.

% Setting the guess range based on max and min from the watsonTemporalModel
% for the given parameters. (Though, watsonTemporalModel currently just
% ranges from +1 to -1. So this step may be unnecessary. 
guessRange = watsonTemporalModel(stimParams,watsonParams);
maxGuess = max(guessRange);
minGuess = min(guessRange);

guessBins = minGuess:(maxGuess-minGuess)/(nCategories-1):maxGuess;

%% The main Q+ loop. 
for i = 1:nTrials
    
    % Get a stim from Q+ 
    stim(i) = qpQuery(questData);
    
    % Add noise to the watsonTemporalModel value, based on the simulated
    % parameters and the amount of noise.
    yGuess(i) = watsonTemporalModel(stim(i),watsonParams) + randn*sdNoise;

    % Assign the noisy y-value to a bin. 
    b = guessBins - yGuess(i);
    b(b>0) = 0;
    [~,outcome(i)] = max(b);
    
    % update Q+
    questData = qpUpdate(questData,stim(i),outcome(i));
   
%{
    The following is commented out because there is no need to update the
    bins based on the output from watsonTemporalModel for each iteration and 
    to rerun Q+ with the new bins. 
    
    
    questData = questDataCopy;
    

    for j = 1:i
        b = guessBins - yGuess(j);
        b(b>0) = 0;
        [~,outcome(j,i)] = max(b);
        questData = qpUpdate(questData,stim(j),outcome(j,i));
    end
    
    if maxPost(i) > .01
        guessRange = watsonTemporalModel(stimParams,paramGuesses(i,:));
        maxGuess = max(guessRange);
        minGuess = min(guessRange);
        guessBins = minGuess:(maxGuess-minGuess)/20:maxGuess;
    end
    
%}    
    
    % Update the maximum posterior and get the latest parameter estimates.
    [maxPost(i),maxIndex] = max(questData.posterior);
    paramGuesses(i,:) = questData.psiParamsDomain(maxIndex,:);
    
    
    

    
end



freqSupport = .11:.01:64;


%% Plots

% Plot the watsonTemporalModel from the simulated parameters and from the
% best guess parameters. 
figure;
semilogx([questData.trialData.stim],watsonTemporalModel([questData.trialData.stim],watsonParams),'*r'); hold on;
semilogx([questData.trialData.stim],yGuess,'*b'); hold on;
semilogx(freqSupport,watsonTemporalModel(freqSupport,watsonParams),'.r');
hold on;
semilogx(freqSupport,watsonTemporalModel(freqSupport,paramGuesses(i,:)),'.b');



% Very klugey code that attempts to recreate Figure 15 from Watson's 2017
% q+ paper with multiple categories. 

% The line plots are the predicted probabilities for each of the
% nCategories, as calcaulted by qpWatsonTemporalModel. 

% The dots are the actual stimulus frequencies and the proportion of each
% outcome (colors) for that stimulus frequency. 

% The size of the dots corresponds to the number of trials at that
% probability. 
colors = repmat([0 0 0; 1 0 0; 0 1 0; .5 .5 .5; 1 0 1; 0 1 1; 0 0 1],3,1);

outOfStruct = [questData.trialData.stim; questData.trialData.outcome];
sortedStims = sort(outOfStruct');
crossTab = crosstab(sortedStims(:,1),sortedStims(:,2));
uniqueStims = unique(sortedStims(:,1));
uniqueOutcomes = unique(sortedStims(:,2));


freqProbs = qpWatsonTemporalModel(freqSupport,paramGuesses(end,:));
figure;
for i = 1:size(freqProbs,2)
    semilogx(freqSupport,freqProbs(:,i),'Color',colors(i,:),'LineWidth',3); hold on;
end

for i = 1:length(uniqueStims)
    props(i,:) = crossTab(i,:)/sum(crossTab(i,:));
    for j = 1:length(uniqueOutcomes)
        semilogx(uniqueStims(i),props(i,j),'.','Color',colors(uniqueOutcomes(j),:),'MarkerSize',sum(crossTab(i,:))); hold on;
    end
end


