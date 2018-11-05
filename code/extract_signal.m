function [targetIm] = extract_signal(niftiName,dicomPath,subjectPath)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here



%acqTime = datetime; %save timepoint  


newNiftiPath = fullfile(subjectPath,'niftis',niftiName);

% Step 1. Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
dicm2nii(fullfile(dicomPath,niftiName),newNiftiPath,0);
newNiftiName = dir(strcat(newNiftiPath,'/*.nii'));
newNiftiName = fullfile(newNiftiPath,newNiftiName.name);
targetNifti = load_untouch_nii(newNiftiName);
targetIm = targetNifti.img;



end

