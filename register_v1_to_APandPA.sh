# This script will take MPRAGE and a run of functional data from a subject, and register a parcel to the first image. 

# to run this from command line: 
# bash register_v1_to_APandPA.sh TOME_3040


rawdir=/data/jux/sweisberg/neurofeedback/subjects/$1/raw;
templatedir=/data/jux/sweisberg/neurofeedback/templates;
outputdir=/data/jux/sweisberg/neurofeedback/subjects/$1/processed;

cd $outputdir
##########################
# registration
##########################

# register MPRAGE to MNI space (where v1 parcel comes from)
flirt -in MPRAGE_bet.nii -ref /share/apps/fsl/5.0.5/data/standard/MNI152_T1_2mm_brain.nii.gz -omat coreg2standard1.mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 12


declare -a arr=("AP" "PA")
for i in "${arr[@]}"
do

# register first volume of functional scan to MPRAGE
flirt -in "$i"_first_volume.nii -ref MPRAGE_bet.nii.gz -omat coreg2standard2"$i".mat -bins 256 -cost corratio -searchrx -180 180 -searchry -180 180 -searchrz -180 180 -dof 6

# concatenate these two registration matrices
convert_xfm -concat coreg2standard1.mat -omat coreg2standard"$i".mat coreg2standard2"$i".mat


# calculate the inverse, just in case
convert_xfm -omat standard2coreg"$i".mat -inverse coreg2standard"$i".mat


# apply registration to kastner parcel(s)
flirt -in $templatedir/kastner_v1lh_10.nii -ref "$i"_first_volume.nii -out V1_TO_"$i".nii -applyxfm -init standard2coreg"$i".mat -interp trilinear 


#binarize mask
fslmaths V1_TO_"$i".nii V1_TO_"$i"_bin.nii

done





