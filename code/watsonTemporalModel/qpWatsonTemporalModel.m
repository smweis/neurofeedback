function predictedProportions = qpWatsonTemporalModel(frequency, params)
% Express the returned value from the Watson model as amplitude proportions
%
% Syntax:
%  predictedProportions = watsonToProportions(nCategories)
%
% Description:
%	Given a number of categories, the parameters of a Watson temporal model
%
%
% Examples:
%{
    figure; hold on;
    i = 0;
    labels = {};
    %simParams = [-0.00251422630566837,1.00595645717933,3.79738894349084,0.951504640228191];
    simParams = [.004 2 1 1];
    bins = 21;
    colorm = rand(bins,3);
    for freq = 0:0.1:64
        i = i + 1;
        predictedProportions = qpWatsonTemporalModel(freq, simParams);
        maxProbabilityMiss(i) = abs(sum(predictedProportions)) - 1;
       

        for j = 1:bins
            semilogx(freq,predictedProportions(j),'.','color',colorm(j,:));
            labels{j} = strcat('cat',num2str(j));
        end
    end
    labels{end+1} = 'watson curve';
    watsonData = watsonTemporalModel(0:.1:64,simParams);
    watsonData = watsonData - min(watsonData);
    if max(watsonData) ~= 0
        watsonData = watsonData/max(watsonData);
    end
    hold on;
    plot(0:.1:64,watsonData,'k.');
    
    hold on; legend(labels);
    max(maxProbabilityMiss)
%}


freqRange=[0 64];
nCategories=21;

smoothSize = 12;

% Obtain the Watson model for these params across the frequency range at a
% high resolution

%defaults

freqSupport = freqRange(1):0.01:freqRange(2);
y = watsonTemporalModel(freqSupport, params);

% Where is the passed frequency value in frequence support
predictedProportions = zeros(length(frequency),nCategories);

for jj = 1:length(frequency)
    [~,freqIdxInSupport] = min(abs(freqSupport-frequency(jj)));

% Scale the Watson model to have unit amplitude
%    y = y - min(y);
%    if max(y) ~= 0
%        y = y ./ max(y);
%    end


% Loop over the categories and report the proportion value for the
% specified frequency in each amplitude category
    catBinSize = 1 / nCategories;
    for ii = 1:nCategories
    
        categoryCenter = (ii-1)*catBinSize + catBinSize/2;
        distFromCatCenter = y(freqIdxInSupport) - categoryCenter;
        if ii == 1
            if distFromCatCenter < 0 
                predictedProportions(jj,ii) = 1;
            else
                predictedProportions(jj,ii) = (1 - abs(distFromCatCenter)/catBinSize); 
            end
        elseif ii == nCategories
            if distFromCatCenter > 0
                predictedProportions(jj,ii) = 1;
            else
                predictedProportions(jj,ii) = (1 - abs(distFromCatCenter)/catBinSize);
            end
        else
            predictedProportions(jj,ii) = (1 - abs(distFromCatCenter)/catBinSize);
        end
    
    end
    
    
    predictedProportions(predictedProportions<0)=0;


    predictedProportions(jj,:) = smoothdata(predictedProportions(jj,:),'gaussian',smoothSize);
    predictedProportions(jj,:) = predictedProportions(jj,:)/sum(predictedProportions(jj,:));
end


end

