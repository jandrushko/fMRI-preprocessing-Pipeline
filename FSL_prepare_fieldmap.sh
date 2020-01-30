#!/bin/bash

# Created by Justin Andrushko, May 29 2019

echo '1_FSL_prepare_fieldmap.sh

This Script runs the FMRIB SOFTWARE LIBRARY (FSL) prepare fieldmap function'

TOP=/media/4TB/justin/
#TOP=$(zenity --file-selection --title "Select Default Directory That Will Serve As A Starting Location For Pop-Up Windows" --directory --filename "${TOP}/")
WDIR=$(zenity --file-selection --title "Select Raw Data BIDS Directory " --directory --filename "${TOP}/")

cd $WDIR

for subject in sub-* ; do
    if [ -d "$subject" ]; then
        echo ${subject}
        cd $WDIR/$subject/
        for session in ses-* ; do
            echo $WDIR/$subject/$session/
            cd $WDIR/$subject/$session/fmap/
            fslmaths ${subject}_${session}_run-1_magnitude1.nii.gz -add ${subject}_${session}_run-1_magnitude2.nii.gz ${subject}_${session}_run-1_magnitude_sum.nii.gz
            fslmaths ${subject}_${session}_run-1_magnitude_sum.nii.gz -div 2 ${subject}_${session}_run-1_magnitude_mean.nii.gz
            fslmaths ${subject}_${session}_run-2_magnitude1.nii.gz -add ${subject}_${session}_run-2_magnitude2.nii.gz ${subject}_${session}_run-2_magnitude_sum.nii.gz
            fslmaths ${subject}_${session}_run-2_magnitude_sum.nii.gz -div 2 ${subject}_${session}_run-2_magnitude_mean.nii.gz
            rm ${subject}_${session}_run-1_magnitude_sum.nii.gz
            rm ${subject}_${session}_run-2_magnitude_sum.nii.gz
            MAGNITUDE1=(${subject}_${session}_run-1_magnitude_mean.nii.gz)
            PHASE1=(${subject}_${session}_run-1_phasediff.nii.gz)
            MAGNITUDE2=(${subject}_${session}_run-2_magnitude_mean.nii.gz)
            PHASE2=(${subject}_${session}_run-2_phasediff.nii.gz)
            bet $MAGNITUDE1 ${subject}_${session}_run-1_magnitude_mean_brain.nii.gz -R
            bet $MAGNITUDE2 ${subject}_${session}_run-2_magnitude_mean_brain.nii.gz -R 
            fsl_prepare_fieldmap SIEMENS $PHASE1 ${subject}_${session}_run-1_magnitude_mean_brain.nii.gz ${subject}_${session}_run-1_fmap_rads 2.46
            fsl_prepare_fieldmap SIEMENS $PHASE2 ${subject}_${session}_run-2_magnitude_mean_brain.nii.gz ${subject}_${session}_run-2_fmap_rads 2.46
            cd $WDIR/$subject/
        done
    fi
    cd $WDIR
done

exit 0