# This script will take a participant's AP/PA bold scans and register a parcel to a sample scan.
# Step 1. Transfer ROI_to_PA.nii.gz, ROI_to_AP.nii.gz, AP_first_volume.nii.gz, PA_first_volume.nii.gz to the neurofeedback comp.
# Step 2. Execute this (run from matlab script) with required variables, scan direction (AP or PA) and subj. number
#           bash register_EPI_to_EPI.sh AP TOME_3040




#FILL IN SUBJECT NUMBER AT END OF THIS PATH HERE
subject_dir="/Users/nfuser/Documents/rtQuest/${2}"


newNifti=new"$1".nii

#extract brain  new file

fslroi $subject_dir/$newNifti $subject_dir/$newNifti 0 104 0 104 0 72 0 1
bet $subject_dir/$newNifti $subject_dir/$newNifti


##########################
# registration
##########################

# register first volume of old functional scan to new functional scan
flirt -in $subject_dir/"$1"_first_volume.nii.gz -ref $subject_dir/$newNifti -omat $subject_dir/new2old"$1".mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# apply registration to v1 parcel(s)
flirt -in $subject_dir/ROI_to_"$1"_bin.nii.gz -ref $subject_dir/$newNifti -out $subject_dir/ROI_to_new"$1".nii.gz -applyxfm -init $subject_dir/new2old"$1".mat -interp trilinear

#binarize mask again
fslmaths $subject_dir/ROI_to_new"$1".nii.gz -bin $subject_dir/ROI_to_new"$1"_bin.nii.gz
