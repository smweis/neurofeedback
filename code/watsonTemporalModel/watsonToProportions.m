function predictedProportions = watsonToProportions(frequency, freqRange, nCategories, params)
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
    figure
    for freq = 0:0.1:64
        predictedProportions = watsonToProportions(freq, [0 64], 5, [0.004 2 1 1]);
        semilogx(freq,predictedProportions(4),'.r');
        if freq==0
hold on
        end
%        plot(freq,predictedProportions(2),'.g');
%%        plot(freq,predictedProportions(3),'.b');
 %       plot(freq,predictedProportions(4),'.c');
 %       plot(freq,predictedProportions(5),'.m');
    end
    xlim([1 100]);
%}

% Obtain the Watson model for these params across the frequency range at a
% high resolution
freqSupport = freqRange(1):0.01:freqRange(2);
y = watsonTemporalModel(freqSupport, params);

% Where is the passed frequency value in frequence support
[~,freqIdxInSupport] = min(abs(freqSupport-frequency));

% Scale the Watson model to have unit amplitude
y = y - min(y);
y = y ./ max(y);

% Loop over the categories and report the proportion value for the
% specified frequency in each amplitude category
predictedProportions = zeros(1,nCategories);
catBinSize = 1 / nCategories;
for ii = 1:nCategories
    categoryCenter = (ii-1)*catBinSize + catBinSize/2;
    predictedProportions(ii) = (catBinSize/2) - abs(y(freqIdxInSupport) - categoryCenter);    
end

predictedProportions(predictedProportions<0)=0;

end

