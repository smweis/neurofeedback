clear all;
close all;

stimParams = logspace(-.9,2,100); % x3 logarithmically equally
                                 % spaced points between 10^x1 and 10^x2
                                 
                                 

questData = qpInitialize('stimParamsDomainList',{stimParams},...
'psiParamsDomainList',{.001:.002:.013,.5:.5:2,.5:.5:5},...
'qpPF',@qpWatsonTemporalModel,...
'nOutcomes',21);

questDataCopy = questData;
%% Adjust these parameters and run the script. 
watsonParams = [.009 2 1];

nTrials = 24;
sdNoise = 0.25; % Noise moves around the y-value from watsonTemporalModel.

maxPost = zeros(nTrials,1);
paramGuesses = zeros(nTrials,length(watsonParams));

guessRange = watsonTemporalModel(stimParams,watsonParams);
maxGuess = max(guessRange);
minGuess = min(guessRange);

guessBins = minGuess:(maxGuess-minGuess)/20:maxGuess;

%% 
for i = 1:nTrials
    stim(i) = qpQuery(questData);
    
    yGuess(i) = watsonTemporalModel(stim(i),watsonParams) + randn*sdNoise;

    questData = questDataCopy;
    
    for j = 1:i
        b = guessBins - yGuess(j);
        b(b>0) = 0;
        [~,outcome(j,i)] = max(b);
        questData = qpUpdate(questData,stim(j),outcome(j,i));
    end
    
    [maxPost(i),maxIndex] = max(questData.posterior);
    paramGuesses(i,:) = questData.psiParamsDomain(maxIndex,:);
    
    if maxPost(i) > .01
        guessRange = watsonTemporalModel(stimParams,paramGuesses(i,:));
        maxGuess = max(guessRange);
        minGuess = min(guessRange);
        guessBins = minGuess:(maxGuess-minGuess)/20:maxGuess;
    end
    
    
    
    if maxPost(i) > .999
        break
    end
    
    
end



freqSupport = .11:.01:64;

figure; 
semilogx(watsonTemporalModel(freqSupport,watsonParams),'.k'); hold on;
semilogx(watsonTemporalModel((freqSupport),paramGuesses(end,:)));
figure;
plot([questData.trialData.stim],watsonTemporalModel([questData.trialData.stim],watsonParams),'*r')
plot([questData.trialData.stim],yGuess,'*b')


maxPost(end)

figure; 

semilogx(freqSupport,watsonTemporalModel(freqSupport,watsonParams),'.r');
hold on;
semilogx(freqSupport,watsonTemporalModel(freqSupport,paramGuesses(i,:)),'.b');


