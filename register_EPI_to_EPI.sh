# This script will take a participant's AP/PA bold scans and register a parcel to a sample scan. 
# Step 1. Transfer V1_TO_PA.nii.gz, V1_TO_AP.sh, AP_first_volume.nii.gz, PA_first_volume.nii.gz to the neurofeedback comp. 
# Step 2. Type in directories as indicated below. Rename the new AP/PA nifti file "newPA.nii" or "newAP.nii"


# to run this from command line: 
# bash register_EPI_to_EPI.sh AP

#FILL IN DIRECTORY HERE
olddir='PUT IN old file dir NAME HERE'/data/jux/sweisberg/neurofeedback/subjects/;


#FILL IN DIRECTORY HERE
newdir='PUT IN NEW file dir NAME HERE'/data/jux/sweisberg/neurofeedback/templates;

newNifti=new"$1".nii

#extract brain  new file

fslroi $newdir/$newNifti $newdir/$newNifti 0 104 0 104 0 72 0 1
bet $newdir/$newNifti $newdir/$newNifti


##########################
# registration
##########################

# register first volume of functional scan to MPRAGE
flirt -in $olddir/"$1"_first_volume.nii -ref $newdir/$newNifti -omat new2old"$1".mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# apply registration to kastner parcel(s)
flirt -in $olddir/V1_TO_"$1".nii -ref "$1"_first_volume.nii -out $newdir/V1_TO_new"$1".nii -applyxfm -init new2old"$1".mat -interp trilinear 






