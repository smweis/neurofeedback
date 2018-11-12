function [roiSignal, dataTimepoint] = scanner_function(targetIm,roiIndex)


% Compute mean from v1 ROI, then plot it against a timestamp
roiSignal = mean(targetIm(roiIndex));

dataTimepoint = datetime;



end

