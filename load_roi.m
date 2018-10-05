function v1Index = load_roi(ap_or_pa)




global subjectPath

% This is where you will load the Nifti file that is V1_TO_new[PA,AP]_bin.nii
roiPath = strcat(subjectPath,'/V1_TO_new',ap_or_pa,'_bin.nii.gz');
roiNifti = load_untouch_nii(roiPath);
v1Index = roiNifti.img;
v1Index = logical(v1Index);
