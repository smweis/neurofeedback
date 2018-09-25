function [acqTime, v1Signal, dataTimepoint] = plot_at_scanner(niftiName,dicomPath)


global v1Index
global niftiPath

acqTime = datetime; %save timepoint  


% Step 1. Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
dicm2nii(dicomPath,strcat(niftiPath,niftiName),0);
targetNifti = load_untouch_nii(strcat(niftiPath,niftiName,'/BOLD_RUN1.nii'));
targetIm = targetNifti.img;

% Step 2. Compute mean from v1 ROI, then plot it against a timestamp
v1Signal = mean(targetIm(v1Index));
    
dataTimepoint = datetime;

end

