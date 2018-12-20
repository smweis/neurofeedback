function [newBins] = changePctSignalBins(params,numBins)
% Take an array of params (e.g., from TFE's params.paramMainMatrix) and
% return the new ways to bin parameters into numBins. 

newBinMin = min(params) - .01;

newBinMax = max(params) + .01;

% Return newBins as going from the newBinMin to the newBinMax divided into
% numBins bins. 
newBins = newBinMin:(newBinMax-newBinMin)/(numBins-1):newBinMax;



end
