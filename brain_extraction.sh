# This script will extract the brains from all relevant files
# bash brain_extraction.sh TOME_3040


rawdir=/data/jux/sweisberg/neurofeedback/subjects/$1/raw;
templatedir=/data/jux/sweisberg/neurofeedback/templates;
outputdir=/data/jux/sweisberg/neurofeedback/subjects/$1/processed;



##########################
# extract brains
#########################

#extract brain from MPRAGE 
bet $rawdir/MPRAGE.nii $outputdir/MPRAGE_bet.nii



fslroi $rawdir/rfMRI_REST_AP_Run1.nii $outputdir/AP_first_volume.nii 0 104 0 104 0 72 0 1
bet $outputdir/AP_first_volume.nii $outputdir/AP_first_volume.nii

fslroi $rawdir/rfMRI_REST_PA_Run2.nii $outputdir/PA_first_volume.nii 0 104 0 104 0 72 0 1
bet $outputdir/PA_first_volume.nii $outputdir/PA_first_volume.nii

