
% datapoints from Spitschan, V1, L + M + S: 

stimulusDomain = [.5 1 2 4 8 16 32 64];
stimulusFreqHzFine = stimulusDomain(1):0.1:stimulusDomain(end);

figure
stimulusFreqHz = stimulusDomain;
pctBOLDresponse = [0.095 0.162 0.327 0.38 0.497 0.711 0.67 0.098];
myObj = @(p) sqrt(sum((pctBOLDresponse-watsonTemporalModelOriginalForFitting(stimulusFreqHz,p)).^2));
x0 = [0.004 2 1 1];
params = fmincon(myObj,x0,[],[]);
semilogx(stimulusFreqHzFine,watsonTemporalModelOriginal(stimulusFreqHzFine,params),'-k');
hold on
semilogx(stimulusFreqHz, pctBOLDresponse, '*r');
hold off

% use these as our simulated psychometric parameters
simulatedPsiParams = params;

%% Initialize a questData struct

% stimParamsDomainList - the possible frequencies to sample
% psiParamsDomainList - Parameter space of the psychometric parameters
% qpPf - our psychometric function
% qpOutcomeF - this needs to be specified or it defaults
% nOutcomes - our possible number of outcomes (based on
%             watsonTemporalModel) where we discretize the output to be 
%             .5% - 1.5% incremented by .1%



questData = qpInitialize('stimParamsDomainList',{stimulusDomain},...
    'psiParamsDomainList',{-.0004:.0004:.01,.5:.5:5,1:4,.25:.5:2.25},...
    'qpPF',@watsonTemporalModel,...
    'qpOutcomeF',@(x) qpSimulatedObserver(x,@watsonTemporalModelNoise,simulatedPsiParams),...
    'nOutcomes',21);



% we can also simulate an observer who is modeled by watsonTemporalModel
simulatedObserverFun = @(x)qpSimulatedObserver(x,@watsonTemporalModelNoise,simulatedPsiParams);
figure
hold on

bins = -.5:.1:1.5;

%% The simulated observer. 
for i = 1:1000
    if mod(i,50) == 9
        psiParamsIndex = qpListMaxArg(questData.posterior);
        psiParamsQuest = questData.psiParamsDomain(psiParamsIndex,:);
        fprintf('Max posterior QUEST+ parameters, MODEL: %f, %f, %f, %f\n', ...
        psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4));
        

        colorRand = rand(1,3);
        for j = 1:length([questData.trialData.stim])
            b(j) = bins([questData.trialData(j).outcome]);
        end
        semilogx([questData.trialData.stim],b,'*','color',colorRand); hold on;
        semilogx(stimulusFreqHzFine,watsonTemporalModelOriginal(stimulusFreqHzFine,psiParamsQuest),'-','color',colorRand);


        prompt = 'Stop? [Type anything]: ';
        str = input(prompt,'s');
        if isempty(str)
            continue;
        else
            break;
        end
        
    end
    
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


%% if we want to benchmark against random observer
% we'll make a copy so we can show it in two ways
%{
%questDataRand = questData;


% let's simulate a random observer for 1000 trials. 
% output needs to match watsonTemporalModel where each outcome is a 
% bin (where 1 = .5% - .6% and 21 = 1.4% - 1.5%
simulatedObserverRand = randi(21,1000,1);


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


%}

