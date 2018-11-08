function [targetIm] = extract_signal(niftiName,dicomPath,subjectPath)
%Function will take in a the name for NIFTI folder (from the file name of the DICOM) 
%a path to where the DICOM is, and a subject's path
%and output the target image in the form of a 3d matrix.



%acqTime = datetime; %save timepoint  


newNiftiPath = fullfile(subjectPath,'niftis',niftiName);

% Convert DICOM to NIFTI (.nii) and load NIFTI into Matlab
dicm2nii(fullfile(dicomPath,niftiName),newNiftiPath,0);
newNiftiName = dir(strcat(newNiftiPath,'/*.nii'));
newNiftiName = fullfile(newNiftiPath,newNiftiName.name);
targetNifti = load_untouch_nii(newNiftiName);
targetIm = targetNifti.img;



end

