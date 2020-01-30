#!/bin/bash

#zenity --info --width=400 --height=200 --text "Created by Justin W. Andrushko, January 22, 2020"

#--------------------------------------#
#          Define Directories          #
#--------------------------------------#
TOP=/media/4TB/justin/
#TOP=$(zenity --file-selection --title "Select Default Directory That Will Serve As A Starting Location For Pop-Up Windows" --directory --filename "${TOP}/")
WDIR=$(zenity --file-selection --title "Select Raw Data BIDS Directory " --directory --filename "${TOP}/")
echo 'You have selected ' $WDIR ' as your processed data directory.'
#SUBDIR=$(zenity --list --column Selection --column Sub-directory TRUE ses-1/func FALSE ses-2/func FALSE mean FALSE none --radiolist)
#echo 'You have selected ' $SUBDIR ' as your sub directories.'
#ROI_MASK=$(zenity --file-selection --title "Select mask for region of interest ")
#echo 'You have selected' $ROI_MASK ' as your region of interest mask.'
#ROI_MASK_DIR=$(dirname -- "$ROI_MASK")
#ROI_MASK_name=$(basename -- "$ROI_MASK")
#ROI_MASK_name_no_ext="${ROI_MASK_name%.*}"
#ROI_MASK_reg=${ROI_MASK_name_no_ext}_reg
#ROI_MASK_reg_bin=${ROI_MASK_name_no_ext}_reg_bin

cd $WDIR

for subject in sub-* ; do
    if [ -d "$subject" ]; then
    echo ${subject}
    cd $WDIR/$subject/anat-mean/
    #mkdir anat-mean
    #flirt -in ses-2/anat/*T1w.nii.gz -ref ses-1/anat/*T1w.nii.gz -dof 12 -out ses-2/anat/${subject}_ses-2_to_ses-1_T1w.nii.gz -omat ses-2/anat/${subject}_ses-2_to_ses-1_T1w.mat
    #fslmaths ses-1/anat/*T1w.nii.gz -add ses-2/anat/${subject}_ses-2_to_ses-1_T1w.nii.gz -div 2 anat-mean/${subject}_ses-mean_T1w.nii.gz -odt float
    #fsl_anat -i ${subject}_ses-mean_T1w.nii.gz
    bet ${subject}_ses-mean_T1w.nii.gz ${subject}_ses-mean_T1w_brain.nii.gz -R
    cd $WDIR/
    fi
done







#if [[ "$SUBDIR" == "none" ]] ; then 