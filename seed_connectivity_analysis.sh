#!/bin/bash

zenity --info --width=400 --height=200 --text "Seed-Based Connectivity Analaysis Using Dual Regression

Created by Justin W. Andrushko, January 29, 2020"

#--------------------------------------#
#          Define Directories          #
#--------------------------------------#


WDIR=$(zenity --file-selection --title "Select Processed Data Directory " --directory)
echo 'You have selected ' $WDIR ' as your processed data directory.'
ROI_MASK=$(zenity --file-selection --title "Select mask for region of interest ")
echo 'You have selected' $ROI_MASK ' as your region of interest mask.'
ROI_MASK_DIR=$(dirname -- "$ROI_MASK")
ROI_MASK_name=$(basename -- "$ROI_MASK")
ROI_MASK_name_no_ext="${ROI_MASK_name%.*}"

cd $WDIR

for subject in sub-* ; do
    if [ -d "$subject" ]; then
        echo ${subject}
        cd $WDIR/$subject/
        for session in ses-* ; do
            echo $WDIR/$subject/$session/
            cd $WDIR/$subject/$session/func/
            for feat in *.feat ; do
                cd $WDIR/$subject/$session/func/$feat/ICA_AROMA/
                feat_dir=$(basename -- "$feat")
                echo $feat_dir
                convert_xfm -omat $WDIR/$subject/$session/func/$feat/reg/highres2example_func.mat -inverse $WDIR/$subject/$session/func/$feat/reg/example_func2highres.mat
                invwarp -r $WDIR/$subject/$session/func/$feat/reg/highres.nii.gz -w $WDIR/$subject/$session/func/$feat/reg/highres2standard_warp -o $WDIR/$subject/$session/func/$feat/reg/highres2standard_warp_inv
                applywarp -i ${ROI_MASK} -r $WDIR/$subject/$session/func/$feat/reg/standard.nii.gz -o ${ROI_MASK_name_no_ext}_func --postmat=$WDIR/$subject/$session/func/$feat/reg/highres2example_func.mat -w $WDIR/$subject/$session/func/$feat/reg/highres2standard_warp_inv
                fslmaths ${ROI_MASK_name_no_ext}_func -bin ${ROI_MASK_name_no_ext}_func
                fslmeants -i denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz -o ${ROI_MASK_name_no_ext}_func.txt -m ${ROI_MASK_name_no_ext}_func
                echo 'Running Seed-Based Connectivity Analysis Using Dual Regression'
                dual_regression ${ROI_MASK_name_no_ext}_func.nii.gz 0 -1 0 ${ROI_MASK_name_no_ext}_SCA_DR denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz
                echo 'Finished Running Seed-Based Connectivity Analaysis for ' $subject/$feat_dir
                cd $WDIR/$subject/$session/func/
            done
            cd $WDIR/$subject/
        done
    fi
    cd $WDIR
done

exit 0



#applywarp --ref=example_func --in=mask_in_standard_space --warp=$WDIR/$subject/$session/func/$feat/reg/highres2standard_warp_inv --postmat=$WDIR/$subject/$session/func/$feat/reg/highres2example_func.mat --out=mask_in_functional_space