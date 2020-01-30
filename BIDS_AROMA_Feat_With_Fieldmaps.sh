#!/bin/bash

#zenity --info --width=400 --height=200 --text "FSL Pre-Processing Pipeline with ICA-AROMA Cleanup 

#Created by Justin W. Andrushko, January 22, 2020

#For this pipeline to work you must first go into the PreProcess_NoHP.fsf file and change the path to non-processed data"

#--------------------------------------#
#          Define Directories          #
#--------------------------------------#
TOP=/media/4TB/justin/
#TOP=$(zenity --file-selection --title "Select Default Directory That Will Serve As A Starting Location For Pop-Up Windows" --directory --filename "${TOP}/")
WFOLDER=/media/4TB/justin/Oxford_imaging_data/BIDS/dataset
#DESIGNDIR=/media/4TB/justin/feat_setup
DESIGNDIR=$(zenity --file-selection --title "Select Directory where your .fsf design file is located" --directory --filename "${TOP}/")
SCRIPTDIR=/home/neurolab/Documents/bash_scripts	
ICAAROMA=/home/neurolab/Documents/python/ICA-AROMA-master
#ICAAROMA=$(zenity --file-selection --title "Select your ICA-AROMA-master Directory" --directory --filename "${TOP}/")

HighpassFrequency=$(zenity --entry --title "Highpass Frequency" --text "Please enter your desired highpass frequency cutoff (FSL default = 0.01, SPM default = 0.008):")
LowpassFrequency=$(zenity --entry --title "Lowpass Frequency" --text "Please enter your desired lowpass frequency cutoff (To skip = -1):")
zenity --info --width=400 --height=200 --text "Now select your desired ICA-AROMA clean up method. Non-aggressive 'nonaggr' is the FSL default. Selecting no performs component classification only"
AROMAMETHOD=$(zenity --list --column Selection --column Method TRUE nonaggr FALSE aggr FALSE both FALSE no --radiolist)
echo 'You have selected ' $AROMAMETHOD ' for your ICA based clean up strategy'
cd $WFOLDER
echo $WFOLDER
for subj_dir in sub-* ; do
    if [ -d "$subj_dir" ]; then
        echo $WFOLDER/${subj_dir}
        cd $WFOLDER/$subj_dir/
	    NEWPARTICIPANTANAT=(anat-mean)
        cd $NEWPARTICIPANTANAT
        NEWANATFILE=(*T1w_brain.nii.gz)
        #NEWANATFOLDER=(*T1w.anat)
        cd $WFOLDER/$subj_dir  
        echo $subj_dir
        for NEWPARTICIPANTSESFOLDER in ses-* ; do
            echo $subj_dir/$NEWPARTICIPANTSESFOLDER
            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER
            if [ -d "fmap" ]; then
                echo "$subj_dir/$NEWPARTICIPANTSESFOLDER/fmap"
                cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/fmap/
                if [[ -f "${subj_dir}_${NEWPARTICIPANTSESFOLDER}_run-2_fmap_rads.nii.gz" ]]; then
                    NEWFMAPRUN1RADS=(*run-1_fmap_rads.nii.gz)
                    NEWFMAPRUN2RADS=(*run-2_fmap_rads.nii.gz)
                    NEWFMAPRUN1MAG=(*run-1_magnitude_mean_brain.nii.gz)
                    NEWFMAPRUN2MAG=(*run-2_magnitude_mean_brain.nii.gz)
                    cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    echo $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    if [[ -f "${subj_dir}_${NEWPARTICIPANTSESFOLDER}_task-low_run-1_bold.nii.gz" ]]; then
                        task_intensity='low'
                        echo $NEWPARTICIPANTSESFOLDER ' condition: ' $task_intensity
                    else
                        task_intensity='high'
                        echo $NEWPARTICIPANTSESFOLDER ' condition: ' $task_intensity
                    fi
                    for NEWSCAN in ${subj_dir}_${NEWPARTICIPANTSESFOLDER}_task-${task_intensity}_run-1_bold.nii.gz ; do
                        NEWSCAN_name=$(basename -- "$NEWSCAN")
                        NEWSCAN_no_ext="${NEWSCAN_name%%.*}"
                        echo 'Running analysis on: ' $NEWSCAN_name
			            cp $DESIGNDIR/PreProcess_NoHP_with_fieldmap.fsf $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        sed 's/PARTICIPANTFOLDER/'$subj_dir'/g' PreProcess_${NEWSCAN_no_ext}_NoHP.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf
                        sed 's/PARTICIPANTSESSIONFOLDER/'$NEWPARTICIPANTSESFOLDER'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf
                        sed 's/FUNCTIONALDATAFOLDER/'func'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf
                        sed 's/PARTICIPANTSTRUCTFOLDER/'$NEWPARTICIPANTANAT'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf
                        sed 's/ANATFILE/'$NEWANATFILE'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf
                        sed 's/FMAPRUNRADS/'$NEWFMAPRUN1RADS'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf
                        sed 's/FMAPRUNMAG/'$NEWFMAPRUN1MAG'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf
                        #sed 's/ANATFOLDER/'$NEWANATFOLDER'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf
                        RepTime_Location=$(grep -n 'RepetitionTime' $NEWSCAN_no_ext.json)
                        TRtime="${RepTime_Location:22:5}"
                        NEWDURATION=$TRtime
                        zeros=0000
                        NEWDURATIONZEROS=($NEWDURATION$zeros)
                        echo 'Repetition Time is ' $NEWDURATIONZEROS
                        EffectiveSpacing=$(grep 'EffectiveEchoSpacing' $NEWSCAN_no_ext.json)
                        EES="${EffectiveSpacing:24:11}"
                        NEWEES=$(echo "scale=9; ($EES*1000)" | bc)
                        echo "Effective Echo Spacing :" $NEWEES
                        EchoTime=$(grep 'EchoTime' $NEWSCAN_no_ext.json)
                        TETime="${EchoTime:13:5}"
                        #echo "The Echo Time is: " $TETime
                        NEWRECORD=$(echo "scale=9; ($TETime*1000)" | bc)
                        echo "The Echo Time is: " $NEWRECORD 
                        fslinfo $NEWSCAN >> ${NEWSCAN_no_ext}_info.txt
                        grep -v 'pixdim' ${NEWSCAN_no_ext}_info.txt >> ${NEWSCAN_no_ext}_no_pixdim_info.txt
                        NumberofVolumes1=$(grep -n 'dim4' ${NEWSCAN_no_ext}_no_pixdim_info.txt)
                        NumberofVolumes="${NumberofVolumes1:8:3}"
                        echo 'Number of Volumes in run ' $NumberofVolumes
                        sed 's/EFFECTIVEECHO/'$NEWEES'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf
                        sed 's/NRECORD/'$NEWRECORD'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp9.fsf
                        sed 's/NVOLUME/'$NumberofVolumes'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp9.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp10.fsf
                        sed 's/INTENSITYFILE/'$NEWSCAN_no_ext'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp10.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp11.fsf
                        sed 's/SCAN/'$NEWSCAN'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp11.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp12.fsf
                        sed 's/DURATION/'$NEWDURATIONZEROS'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp12.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp13.fsf
                        HP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$HighpassFrequency))" | bc)
                        echo 'Highpass sigma set to ' $HP_sigma
                        echo 'Highpass cutoff set to ' $HighpassFrequency 'Hz'
                        rm *info.txt
                        if [[ "$LowpassFrequency" == "-1" ]] ; then
                            LP_sigma='-1'
                            echo 'lowpass sigma set to ' $LP_sigma ': Lowpass filtering will be skipped'
                        else 
                            LP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$LowpassFrequency))" | bc)
                            echo 'lowpass sigma set to ' $LP_sigma
                            echo 'lowpass cutoff set to ' $LowpassFrequency 'Hz'
                        fi
                        echo 'Running FEAT Pre-Processing (No Temporal Filtering)'
			            feat PreProcess_${NEWSCAN_no_ext}_NoHP_temp13.fsf
				        echo 'Running ICA AROMA'
                        source ~/anaconda2/bin/activate neuro-aroma
                        python $ICAAROMA/ICA_AROMA.py -feat $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat -den $AROMAMETHOD -out $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/ICA_AROMA
				        conda deactivate
                        echo 'ICA AROMA Complete'
                        cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/ICA_AROMA/
                        if [[ "$AROMAMETHOD" == "nonaggr" ]] ; then
                            fslmaths denoised_func_data_nonaggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_nonaggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_nonaggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_nonaggr_thresh -mul $scaling denoised_func_data_nonaggr_intnorm
                            fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_nonaggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                        elif [[ "$AROMAMETHOD" == "aggr" ]]; then
                            fslmaths denoised_func_data_aggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_aggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_aggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_aggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_aggr_thresh -mul $scaling denoised_func_data_aggr_intnorm
                            fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_aggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                        elif [[ "$AROMAMETHOD" == "both" ]]; then
                            # Non-Aggressive ICA-Clean Up
                            echo 'Non-Aggressive ICA-Clean Up'
                            fslmaths denoised_func_data_nonaggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_nonaggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_nonaggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_nonaggr_thresh -mul $scaling denoised_func_data_nonaggr_intnorm
                            fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_nonaggr_highpassedFSL_MNI152_brain.nii.gz
                            # Aggressive ICA-Clean Up
                            echo 'Aggressive ICA-Clean Up'
                            fslmaths denoised_func_data_aggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_aggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_aggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_aggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_aggr_thresh -mul $scaling denoised_func_data_aggr_intnorm
                            fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_aggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                        else 
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                        fi
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                    done
                    cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    if [[ -f "${subj_dir}_${NEWPARTICIPANTSESFOLDER}_task-low_run-1_bold.nii.gz" ]]; then
                        task_intensity='low'
                        echo $NEWPARTICIPANTSESFOLDER ' condition: ' $task_intensity
                    else
                        task_intensity='high'
                        echo $NEWPARTICIPANTSESFOLDER ' condition: ' $task_intensity
                    fi
                    for NEWSCAN in ${subj_dir}_${NEWPARTICIPANTSESFOLDER}_task-${task_intensity}_run-2_bold.nii.gz ; do
                        NEWSCAN_name=$(basename -- "$NEWSCAN")
                        NEWSCAN_no_ext="${NEWSCAN_name%%.*}"
                        echo 'Running analysis on: ' $NEWSCAN_name
                        cp $DESIGNDIR/PreProcess_NoHP_with_fieldmap.fsf $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        sed 's/PARTICIPANTFOLDER/'$subj_dir'/g' PreProcess_${NEWSCAN_no_ext}_NoHP.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf
                        sed 's/PARTICIPANTSESSIONFOLDER/'$NEWPARTICIPANTSESFOLDER'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf
                        sed 's/FUNCTIONALDATAFOLDER/'func'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf
                        sed 's/PARTICIPANTSTRUCTFOLDER/'$NEWPARTICIPANTANAT'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf
                        sed 's/ANATFILE/'$NEWANATFILE'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf
                        sed 's/FMAPRUNRADS/'$NEWFMAPRUN2RADS'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf
                        sed 's/FMAPRUNMAG/'$NEWFMAPRUN2MAG'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf
                        RepTime_Location=$(grep -n 'RepetitionTime' $NEWSCAN_no_ext.json)
                        TRtime="${RepTime_Location:22:5}"
                        NEWDURATION=$TRtime
                        zeros=0000
                        NEWDURATIONZEROS=($NEWDURATION$zeros)
                        echo 'Repetition Time is ' $NEWDURATIONZEROS
                        EffectiveSpacing=$(grep 'EffectiveEchoSpacing' $NEWSCAN_no_ext.json)
                        EES="${EffectiveSpacing:24:11}"
                        NEWEES=$(echo "scale=9; ($EES*1000)" | bc)
                        echo "Effective Echo Spacing :" $NEWEES
                        EchoTime=$(grep 'EchoTime' $NEWSCAN_no_ext.json)
                        TETime="${EchoTime:13:5}"
                        #echo "The Echo Time is: " $TETime
                        NEWRECORD=$(echo "scale=9; ($TETime*1000)" | bc)
                        echo "The Echo Time is: " $NEWRECORD 
                        fslinfo $NEWSCAN >> ${NEWSCAN_no_ext}_info.txt
                        grep -v 'pixdim' ${NEWSCAN_no_ext}_info.txt >> ${NEWSCAN_no_ext}_no_pixdim_info.txt
                        NumberofVolumes1=$(grep -n 'dim4' ${NEWSCAN_no_ext}_no_pixdim_info.txt)
                        NumberofVolumes="${NumberofVolumes1:8:3}"
                        echo 'Number of Volumes in run ' $NumberofVolumes
                        sed 's/EFFECTIVEECHO/'$NEWEES'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf
                        sed 's/NRECORD/'$NEWRECORD'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp9.fsf
                        sed 's/NVOLUME/'$NumberofVolumes'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp9.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp10.fsf
                        sed 's/INTENSITYFILE/'$NEWSCAN_no_ext'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp10.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp11.fsf
                        sed 's/SCAN/'$NEWSCAN'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp11.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp12.fsf
                        sed 's/DURATION/'$NEWDURATIONZEROS'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp12.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp13.fsf
                        HP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$HighpassFrequency))" | bc)
                        echo 'Highpass sigma set to ' $HP_sigma
                        echo 'Highpass cutoff set to ' $HighpassFrequency 'Hz'
                        rm *info.txt
                        if [[ "$LowpassFrequency" == "-1" ]] ; then
                            LP_sigma='-1'
                            echo 'lowpass sigma set to ' $LP_sigma ': Lowpass filtering will be skipped'
                        else 
                            LP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$LowpassFrequency))" | bc)
                            echo 'lowpass sigma set to ' $LP_sigma
                            echo 'lowpass cutoff set to ' $LowpassFrequency 'Hz'
                        fi
                        echo 'Running FEAT Pre-Processing (No Temporal Filtering)'
			            feat PreProcess_${NEWSCAN_no_ext}_NoHP_temp13.fsf
                        echo 'Running ICA AROMA'
                        source ~/anaconda2/bin/activate neuro-aroma
                        python $ICAAROMA/ICA_AROMA.py -feat $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat -den $AROMAMETHOD -out $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/ICA_AROMA
                        conda deactivate
                        echo 'ICA AROMA Complete'
                        cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/ICA_AROMA/
                        if [[ "$AROMAMETHOD" == "nonaggr" ]] ; then
                            fslmaths denoised_func_data_nonaggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_nonaggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_nonaggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_nonaggr_thresh -mul $scaling denoised_func_data_nonaggr_intnorm
                            fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_nonaggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        elif [[ "$AROMAMETHOD" == "aggr" ]]; then
                            fslmaths denoised_func_data_aggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_aggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_aggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_aggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_aggr_thresh -mul $scaling denoised_func_data_aggr_intnorm
                            fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_aggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        elif [[ "$AROMAMETHOD" == "both" ]]; then
                            # Non-Aggressive ICA-Clean Up
                            echo 'Non-Aggressive ICA-Clean Up'
                            fslmaths denoised_func_data_nonaggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_nonaggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_nonaggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_nonaggr_thresh -mul $scaling denoised_func_data_nonaggr_intnorm
                            fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_nonaggr_highpassedFSL_MNI152_brain.nii.gz
                            # Aggressive ICA-Clean Up
                            echo 'Aggressive ICA-Clean Up'
                            fslmaths denoised_func_data_aggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_aggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_aggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_aggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                            # Intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_aggr_thresh -mul $scaling denoised_func_data_aggr_intnorm
                            fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_aggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        else 
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        fi
                    done
                else
                    NEWFMAPRUN1RADS=(*run-1_fmap_rads.nii.gz)
                    NEWFMAPRUN1MAG=(*run-1_magnitude_mean_brain.nii.gz)
                    cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    echo $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    if [[ -f "${subj_dir}_${NEWPARTICIPANTSESFOLDER}_task-low_run-1_bold.nii.gz" ]]; then
                        task_intensity='low'
                        echo $NEWPARTICIPANTSESFOLDER ' condition: ' $task_intensity
                    else
                        task_intensity='high'
                        echo $NEWPARTICIPANTSESFOLDER ' condition: ' $task_intensity
                    fi
                    for NEWSCAN in ${subj_dir}_${NEWPARTICIPANTSESFOLDER}_task-${task_intensity}_run-*_bold.nii.gz ; do
                        echo $NEWSCAN
                        NEWSCAN_name=$(basename -- "$NEWSCAN")
                        NEWSCAN_no_ext="${NEWSCAN_name%%.*}"
                        echo 'Running analysis on: ' $NEWSCAN_name
                        cp $DESIGNDIR/PreProcess_NoHP_with_fieldmap.fsf $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        sed 's/PARTICIPANTFOLDER/'$subj_dir'/g' PreProcess_${NEWSCAN_no_ext}_NoHP.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf
                        sed 's/PARTICIPANTSESSIONFOLDER/'$NEWPARTICIPANTSESFOLDER'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf
                        sed 's/FUNCTIONALDATAFOLDER/'func'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf
                        sed 's/PARTICIPANTSTRUCTFOLDER/'$NEWPARTICIPANTANAT'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf
                        sed 's/ANATFILE/'$NEWANATFILE'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf
                        sed 's/FMAPRUNRADS/'$NEWFMAPRUN1RADS'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf
                        sed 's/FMAPRUNMAG/'$NEWFMAPRUN1MAG'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf
                        RepTime_Location=$(grep -n 'RepetitionTime' $NEWSCAN_no_ext.json)
                        echo 'Repetition Time is ' $NEWDURATIONZEROS
                        EffectiveSpacing=$(grep 'EffectiveEchoSpacing' $NEWSCAN_no_ext.json)
                        EES="${EffectiveSpacing:24:11}"
                        NEWEES=$(echo "scale=9; ($EES*1000)" | bc)
                        echo "Effective Echo Spacing :" $NEWEES
                        EchoTime=$(grep 'EchoTime' $NEWSCAN_no_ext.json)
                        TETime="${EchoTime:13:5}"
                        NEWRECORD=$(echo "scale=9; ($TETime*1000)" | bc)
                        echo "The Echo Time is: " $NEWRECORD 
                        fslinfo $NEWSCAN >> ${NEWSCAN_no_ext}_info.txt
                        grep -v 'pixdim' ${NEWSCAN_no_ext}_info.txt >> ${NEWSCAN_no_ext}_no_pixdim_info.txt
                        NumberofVolumes1=$(grep -n 'dim4' ${NEWSCAN_no_ext}_no_pixdim_info.txt)
                        NumberofVolumes="${NumberofVolumes1:8:3}"
                        echo 'Number of Volumes in run ' $NumberofVolumes
                        sed 's/EFFECTIVEECHO/'$NEWEES'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf
                        sed 's/NRECORD/'$NEWRECORD'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp9.fsf
                        sed 's/NVOLUME/'$NumberofVolumes'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp9.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp10.fsf
                        sed 's/INTENSITYFILE/'$NEWSCAN_no_ext'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp10.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp11.fsf
                        sed 's/SCAN/'$NEWSCAN'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp11.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp12.fsf
                        sed 's/DURATION/'$NEWDURATIONZEROS'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp12.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp13.fsf
                        HP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$HighpassFrequency))" | bc)
                        echo 'Highpass sigma set to ' $HP_sigma
                        echo 'Highpass cutoff set to ' $HighpassFrequency 'Hz'
                        rm *info.txt
                        if [[ "$LowpassFrequency" == "-1" ]] ; then
                            LP_sigma='-1'
                            echo 'lowpass sigma set to ' $LP_sigma ': Lowpass filtering will be skipped'
                        else 
                            LP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$LowpassFrequency))" | bc)
                            echo 'lowpass sigma set to ' $LP_sigma
                            echo 'lowpass cutoff set to ' $LowpassFrequency 'Hz'
                        fi
                        echo 'Running FEAT Pre-Processing (No Temporal Filtering)'
			            feat PreProcess_${NEWSCAN_no_ext}_NoHP_temp13.fsf
                        echo 'Running ICA AROMA'
                        source ~/anaconda2/bin/activate neuro-aroma
                        python $ICAAROMA/ICA_AROMA.py -feat $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat -den $AROMAMETHOD -out $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/ICA_AROMA
                        conda deactivate
                        echo 'ICA AROMA Complete'
                        cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/ICA_AROMA/
                        if [[ "$AROMAMETHOD" == "nonaggr" ]] ; then
                            fslmaths denoised_func_data_nonaggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_nonaggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_nonaggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                            #intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_nonaggr_thresh -mul $scaling denoised_func_data_nonaggr_intnorm
                            fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_nonaggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        elif [[ "$AROMAMETHOD" == "aggr" ]]; then
                            fslmaths denoised_func_data_aggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_aggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_aggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_aggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                            #intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_aggr_thresh -mul $scaling denoised_func_data_aggr_intnorm
                            fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_aggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        elif [[ "$AROMAMETHOD" == "both" ]]; then
                            # Non-Aggressive ICA-Clean Up
                            echo 'Non-Aggressive ICA-Clean Up'
                            fslmaths denoised_func_data_nonaggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_nonaggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_nonaggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                            #intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_nonaggr_thresh -mul $scaling denoised_func_data_nonaggr_intnorm
                            fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_nonaggr_highpassedFSL_MNI152_brain.nii.gz
                            # Aggressive ICA-Clean Up
                            echo 'Aggressive ICA-Clean Up'
                            fslmaths denoised_func_data_aggr.nii.gz -Tmean mean_func
                            bet2 mean_func mask -f 0.3 -n -m; 
                            immv mask_mask mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_bet
                            Threshstattemp1=$(fslstats denoised_func_data_aggr_bet -p 2 -p 98)
                            Threshstattemp2="${Threshstattemp1:9:12}"
                            Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                            fslmaths denoised_func_data_aggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                            median_intensity=$(fslstats denoised_func_data_aggr.nii.gz -k mask -p 50)
                            echo 'median intensity = ' $median_intensity
                            fslmaths mask -dilF mask
                            fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                            #intensity normalization
                            normmean='10000'
                            scaling=$(echo "scale=9; ($normmean/$median_intensity)" | bc)
                            echo 'scaling = ' $scaling
                            echo "grand-mean intensity normalisation of the entire 4D dataset by a single multiplicative factor"
                            fslmaths denoised_func_data_aggr_thresh -mul $scaling denoised_func_data_aggr_intnorm
                            fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                            fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma $LP_sigma -add tempMean denoised_func_data_aggr_highpassedFSL.nii.gz 
                            imrm tempMean
                            fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                            applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                            fslmaths denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -mul ${FSLDIR}/data/standard/MNI152_T1_2mm_brain_mask.nii.gz denoised_func_data_aggr_highpassedFSL_MNI152_brain.nii.gz
                            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                            rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        else 
                        cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                        rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                        rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                        fi
                    done
                    cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    rm -rf PreProcess_NoHP_temp*.fsf
                    rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                fi
            fi
		done
        cd $WFOLDER
    fi 
done
exit 0
