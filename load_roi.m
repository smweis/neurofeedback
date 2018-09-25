
% This is where you will load the Nifti file that is V1_TO_new[PA,AP].nii
% roiPath = PATH_TO_NIFTI
% roiNifti = load_untouch_nii(roiPath);
% v1Index = roiNifti.img;
% v1Index = logical(v1Index);



global v1Index 
v1Index = zeros(96,96,80);
v1Index(45:55,45:55,45:55) = 1;
v1Index = logical(v1Index);


