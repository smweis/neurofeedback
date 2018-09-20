# This script will take MPRAGE and a run of functional data from a subject, and register a parcel to the first image. 

# to run this from command line: 
# bash register_v1_to_PA.sh TOME_3040

subjdir=/data/jux/sweisberg/neurofeedback/subjects/$1/;
templatedir=/data/jux/sweisberg/neurofeedback/templates;

cd $subjdir



##########################
# extract brains
#########################

#extract brain from MPRAGE
bet MPRAGE.nii MPRAGE_bet.nii

# get first volume from functional scan and extract brain
fslroi rfMRI_REST_PA_Run2.nii PA_first_volume.nii 0 104 0 104 0 72 0 1
bet PA_first_volume.nii PA_first_volume_bet.nii


##########################
# registration
##########################

# register MPRAGE to MNI space (where v1 parcel comes from)
flirt -in MPRAGE_bet.nii -ref /share/apps/fsl/5.0.5/data/standard/MNI152_T1_2mm_brain.nii.gz -omat coreg2standard1.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12

# register first volume of functional scan to MPRAGE
flirt -in PA_first_volume_bet.nii -ref MPRAGE_bet.nii.gz -omat coreg2standard2.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# concatenate these two registration matrices
convert_xfm -concat coreg2standard1.mat -omat coreg2standard.mat coreg2standard2.mat

# calculate the inverse, just in case
convert_xfm -omat standard2coreg.mat -inverse coreg2standard.mat


# apply registration to kastner parcel(s)
flirt -in $templatedir/kastner_v1lh_10.nii -ref PA_first_volume_bet.nii -out V1_TO_PA.nii -applyxfm -init standard2coreg.mat -interp trilinear 








