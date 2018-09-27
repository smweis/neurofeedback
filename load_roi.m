global v1Index

sequence_order = input('Is this a PA or AP scan?','s');

% This is where you will load the Nifti file that is V1_TO_new[PA,AP].nii
roiPath = strcat('/Users/iron/Documents/neurofeedback/TOME_3040/V1_TO_new',sequence_order,'.nii.gz');
roiNifti = load_untouch_nii(roiPath);
v1Index = roiNifti.img;
v1Index = logical(v1Index);


% sham region
%v1Index = zeros(96,96,80);
%v1Index(45:55,45:55,45:55) = 1;
%v1Index = logical(v1Index);


