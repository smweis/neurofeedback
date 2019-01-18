clear all;
close all;

stimParams = logspace(.1,2,100); % 100 logarithmically equally
                                 % spaced points between 10^.1 and 10^2
                                 
                                 

questData = qpInitialize('stimParamsDomainList',{stimParams},...
'psiParamsDomainList',{.001:.001:.012,.5:.5:2,.5:.5:5,.5:.5:3},...
'qpPF',@qpWatsonTemporalModel,...
'nOutcomes',21);


outcomes = 1:21;


%% Adjust these parameters and run the script. 
watsonParams = [.004 2 1 1];

nTrials = 512;
sdNoise = 0.07; % Noise moves around the y-value from watsonTemporalModel.

maxPost = zeros(nTrials,1);
paramGuesses = zeros(nTrials,length(watsonParams));

guessRange = watsonTemporalModel(stimParams,watsonParams);
maxGuess = max(guessRange)+.1;
minGuess = min(guessRange)-.1;

guessBins = minGuess:(maxGuess-minGuess)/20:maxGuess;

%% 
for i = 1:nTrials
    stim = qpQuery(questData);
    
    yGuess(i) = watsonTemporalModel(stim,watsonParams) + randn*sdNoise;
    b = guessBins - yGuess(i);
    b(b>0) = 0;
    [~,idx] = max(b);
    
    questData = qpUpdate(questData,stim,idx);
    
    [maxPost(i),maxIndex] = max(questData.posterior);
    paramGuesses(i,:) = questData.psiParamsDomain(maxIndex,:);
    

end



freqSupport = 0:.01:64;

figure; hold on;
semilogx(freqSupport,watsonTemporalModel(freqSupport,watsonParams),'.k');
semilogx(freqSupport,watsonTemporalModel((freqSupport),paramGuesses(end,:)));
semilogx([questData.trialData.stim],watsonTemporalModel([questData.trialData.stim],watsonParams),'*r')
semilogx([questData.trialData.stim],yGuess,'*b')
maxPost(end)
