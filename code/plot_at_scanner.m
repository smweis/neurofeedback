function [acqTime, dicomAcqTime, roiSignal, dataTimepoint] = plot_at_scanner(niftiName,dicomPath,roiIndex,subjectPath)



acqTime = datetime; %save timepoint  

newNiftiPath = fullfile(subjectPath,'niftis',niftiName);

% Step 1. Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
dicm2nii(fullfile(dicomPath,niftiName),newNiftiPath,0);
newNiftiName = dir(strcat(newNiftiPath,'/*.nii'));
newNiftiName = fullfile(newNiftiPath,newNiftiName.name);
targetNifti = load_untouch_nii(newNiftiName);
targetIm = targetNifti.img;







% Step 2. Compute mean from v1 ROI, then plot it against a timestamp
roiSignal = mean(targetIm(roiIndex));
load(fullfile(newNiftiPath,'dcmHeaders.mat'),'h')
subHNames = fieldnames(h);
dicomAcqTime = str2double(h.(subHNames{1}).AcquisitionTime);
dataTimepoint = datetime;



end

