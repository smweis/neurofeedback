% plot

colors = ['g','b','r','k','m'];

figure(1);
figure(2);
for i = 1:5
    
    stims = stimParams(i).params.stimFreq(stimParams(i).params.stimFreq>0);
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
    figure(1);subplot(3,2,i);
    semilogx(stims,scaledBOLDresponse(i,:),horzcat(colors(i),'*'));
    figure(2);
    p1(i) = semilogx(uniqueStims,meanBoldPerStim,'Marker','d','MarkerEdgeColor',colors(i),'MarkerFaceColor',colors(i),'MarkerSize',12,'LineStyle','none');
    figure(1:2)
    hold on;semilogx(stimulusFreqHzFine,watsonTemporalModel(stimulusFreqHzFine,watsonParams(i,:)),horzcat(colors(i),'-'));
    
   
end
axis([1 64 0 1.5])
xlabel('Stimulus Frequency, log');
ylabel('Arbitrary units, relative activation');
legend(p1,'1','2','3','4','5');