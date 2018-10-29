function ROIIndex = load_roi(subject,ap_or_pa)





subjectPath = getpref('neurofeedback','currentSubjectBasePath');
subjectPath = [subjectPath filesep subject];

% This is where you will load the Nifti file that is ROI_to_new[PA,AP]_bin.nii
roiPath = strcat(subjectPath,'/ROI_to_new',ap_or_pa,'_bin.nii.gz');
roiNifti = load_untouch_nii(roiPath);
ROIIndex = roiNifti.img;
ROIIndex = logical(ROIIndex);
