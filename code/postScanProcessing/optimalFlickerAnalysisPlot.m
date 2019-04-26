% plot
clear stimsAll;
load('/Users/nfuser/Documents/rtQuest/TOME_3021/optimalResults.mat');

colors = ['g','b','r','c','m'];

figure(1);
figure(2);
for i = 1:5
    
    stims = stimParams(i).params.stimFreq(stimParams(i).params.stimFreq>0);
    stimsAll(i,:) = stims;
    % Identify the unique stims and the mean of the BOLD response for those
    % stims
    [uniqueStims,~,k] = unique(stims(1,:));
    numberUniqueStims = numel(uniqueStims);
    meanBoldPerStim = zeros(size(stims,1),numberUniqueStims);
    for nu = 1:numberUniqueStims
        indexToThisUniqueValue = (nu==k)';
        meanBoldPerStim(:,nu) = mean(scaledBOLDresponse(i,indexToThisUniqueValue),2);
        stdBoldPerStim(:,nu) = std(scaledBOLDresponse(i,indexToThisUniqueValue));
    end
    
    stimulusFreqHzFine = logspace(log10(1.875),log10(30),100);
    splineInterpolatedMax = max(spline(uniqueStims,meanBoldPerStim,stimulusFreqHzFine));
    % Scale the x vector so that the max is zero
    meanBoldPerStim = meanBoldPerStim ./ splineInterpolatedMax;
    
    figure(1);
    subplot(3,2,i);
    semilogx(stims,scaledBOLDresponse(i,:),horzcat(colors(i),'*'));hold on;
    figure(2);
    p1(i) = semilogx(uniqueStims,meanBoldPerStim,'Marker','d','MarkerEdgeColor',colors(i),'MarkerFaceColor',colors(i),'MarkerSize',12,'LineStyle','none'); 
    hold on;
    figure(1)
    semilogx(stimulusFreqHzFine,watsonTemporalModel(stimulusFreqHzFine,watsonParams(i,:)),horzcat(colors(i),'-'));
    figure(2)
    semilogx(stimulusFreqHzFine,watsonTemporalModel(stimulusFreqHzFine,watsonParams(i,:)),horzcat(colors(i),'-'));
    
   
end
xlabel('Stimulus Frequency, log');
ylabel('Arbitrary units, relative activation');
legend(p1,'Run 1','Run 2','Run 3','Run 4','Run 5');

stimsAll = reshape(stimsAll,1,size(stimsAll,1)*size(stimsAll,2));
scaledBOLDresponseAll = reshape(scaledBOLDresponse,1,size(scaledBOLDresponse,1)*size(scaledBOLDresponse,2));
[uniqueStims,~,k] = unique(stimsAll(1,:));
numberUniqueStims = numel(uniqueStims);
meanBoldPerStim = zeros(size(stimsAll,1),numberUniqueStims);
for nu = 1:numberUniqueStims
    indexToThisUniqueValue = (nu==k)';
    meanBoldPerStim(:,nu) = mean(scaledBOLDresponseAll(1,indexToThisUniqueValue),2);
    stdBoldPerStim(:,nu) = std(scaledBOLDresponseAll(1,indexToThisUniqueValue));
end
    
myObj = @(p) sqrt(sum((meanBoldPerStim-watsonTemporalModel(uniqueStims,p)).^2));
x0 = [2 2 2];
watsonParamsAll = fmincon(myObj,x0);

figure(3);
p2 = semilogx(uniqueStims,meanBoldPerStim,'Marker','d','MarkerEdgeColor','k','MarkerFaceColor','k','MarkerSize',12,'LineStyle','none');
hold on;semilogx(stimulusFreqHzFine,watsonTemporalModel(stimulusFreqHzFine,watsonParamsAll),'k-');
xlabel('Stimulus Frequency, log');
ylabel('Arbitrary units, relative activation');
legend(p2,'Grand mean across runs');

