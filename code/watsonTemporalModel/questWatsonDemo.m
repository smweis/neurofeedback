% initialize a questData struct
% stimParamsDomainList - the possible frequencies to sample
% psiParamsDomainList - right now just letting the first two vary. Letting
%                       the others vary takes a while. But just to
%                       initialize.
% qpPf - our psychometric function
% qpOutcomeF - this needs to be specified or it defaults
% nOutcomes - our possible number of outcomes (based on
%             watsonTemporalModel) where we discretize the output to be 
%             .5% - 1.5% incremented by .1%

questData = qpInitialize('stimParamsDomainList',{[0:1:64]}, ...
    'psiParamsDomainList',{0:.0004:.008,-10:2:10,1,1},...
    'qpPF',@watsonTemporalModel,...
    'qpOutcomeF',@(x) qpSimulatedObserver(x,@watsonTemporalModel,[.003,2,2,1]),...
    'nOutcomes',21);

% we'll make a copy so we can show it in two ways
questDataRand = questData;


% these are our simulated psychometric parameters
simulatedPsiParams = [.004,2,1,1];


% let's simulate a random observer for 10 trials. 
% output needs to match watsonTemporalModel where each outcome is a 
% bin (where 1 = .5% - .6% and 21 = 1.4% - 1.5%
simulatedObserverRand = randi(21,10,1);


% we can also simulate an observer who is modeled by watsonTemporalModel
simulatedObserverFun = @(x) qpSimulatedObserver(x,@watsonTemporalModel,simulatedPsiParams);

% the random one
for i = 1:10
    stim = qpQuery(questDataRand);
    outcome = simulatedObserverRand(i);
    questDataRand = qpUpdate(questDataRand,stim,outcome);
end


psiParamsIndex = qpListMaxArg(questDataRand.posterior);
psiParamsQuest = questDataRand.psiParamsDomain(psiParamsIndex,:);
fprintf('Simulated parameters: %f, %f, %f, %f\n', ...
    simulatedPsiParams(1),simulatedPsiParams(2),simulatedPsiParams(3),simulatedPsiParams(4));
fprintf('Max posterior QUEST+ parameters, RANDOM: %f, %f, %f, %f\n', ...
    psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4));


psiParamsFit = qpFit(questDataRand.trialData,questDataRand.qpPF,psiParamsQuest,questDataRand.nOutcomes,...
    'lowerBounds', [0 -10 -1 -1],'upperBounds',[.008 10 1 1]);
fprintf('Maximum likelihood fit parameters, RANDOM: %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsFit(1),psiParamsFit(2),psiParamsFit(3),psiParamsFit(4));


% the simulated observer one. Should converge
for i = 1:10
    stim = qpQuery(questData);
    outcome = simulatedObserverFun(stim);
    questData = qpUpdate(questData,stim,outcome);
end


psiParamsIndex = qpListMaxArg(questData.posterior);
psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
fprintf('Simulated parameters: %f, %f, %f, %f\n', ...
    simulatedPsiParams(1),simulatedPsiParams(2),simulatedPsiParams(3),simulatedPsiParams(4));
fprintf('Max posterior QUEST+ parameters, MODEL: %f, %f, %f, %f\n', ...
    psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4));


psiParamsFit = qpFit(questData.trialData,questData.qpPF,psiParamsQuest,questData.nOutcomes,...
    'lowerBounds', [0 -10 -1 -1],'upperBounds',[.008 10 1 1]);
fprintf('Maximum likelihood fit parameters, MODEL: %0.1f, %0.1f, %0.1f, %0.2f\n', ...
    psiParamsFit(1),psiParamsFit(2),psiParamsFit(3),psiParamsFit(4));



