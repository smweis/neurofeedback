questData = qpInitialize('stimParamsDomainList',{[2:64]},...
'psiParamsDomainList',{.001:.001:.012,.5:.5:3,.5:.5:3,.5:.5:3},...
'qpPF',@qpWatsonTemporalModel,...
'nOutcomes',21);

simParams = [.004 2 1 1];

outcomes = 1:21;

for i = 1:256
    stim = qpQuery(questData);
    predictedProportions = qpWatsonTemporalModel(stim,simParams);
    x = rand;
    if x < max(predictedProportions)
        [~,idx] = max(predictedProportions);
    else
        [~,idx] = maxk(predictedProportions,2);
        idx = idx(2);
    end
    outcome = outcomes(idx);
    questData = qpUpdate(questData,stim,outcome);
end
maxParamGuess = max(questData.posterior);
maxIndex = questData.posterior == maxParamGuess;
paramGuesses = questData.psiParamsDomain(maxIndex,:);