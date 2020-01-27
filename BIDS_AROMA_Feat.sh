#!/bin/bash

zenity --info --width=400 --height=200 --text "FSL Pre-Processing Pipeline with ICA-AROMA Cleanup 

Created by Justin W. Andrushko, January 22, 2020

For this pipeline to work you must first go into the PreProcess_NoHP.fsf file and change the path to non-processed data"

#--------------------------------------#
#          Define Directories          #
#--------------------------------------#
#TOP=/media/4TB/justin/
TOP=$(zenity --file-selection --title "Select Default Directory That Will Serve As A Starting Location For Pop-Up Windows" --directory --filename "${TOP}/")
WFOLDER=/media/4TB/justin/Usask_001_imaging_data_1/BIDS/dataset
#DESIGNDIR=/media/4TB/justin/feat_setup
DESIGNDIR=$(zenity --file-selection --title "Select Directory where your .fsf design file is located" --directory --filename "${TOP}/")
SCRIPTDIR=/home/neurolab/Documents/bash_scripts	
#ICAAROMA=/home/neurolab/Documents/python/ICA-AROMA-master
ICAAROMA=$(zenity --file-selection --title "Select your ICA-AROMA-master Directory" --directory --filename "${TOP}/")

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
        NEWANATFOLDER=(*T1w.anat)
        cd $WFOLDER/$subj_dir  
        echo $subj_dir/$NEWSUBSTRUCT
        for NEWPARTICIPANTSESFOLDER in ses-* ; do
            echo $subj_dir/$NEWPARTICIPANTSESFOLDER
            cd $NEWPARTICIPANTSESFOLDER
            cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
            echo $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
            for NEWSCAN in sub-*_ses-*_task-*_bold.nii ; do
			    echo $NEWSCAN
                NEWSCAN_name=$(basename -- "$NEWSCAN")
                NEWSCAN_no_ext="${NEWSCAN_name%.*}"
			    cp $DESIGNDIR/PreProcess_NoHP.fsf $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/PreProcess_${NEWSCAN_no_ext}_NoHP.fsf
                sed 's/PARTICIPANTFOLDER/'$subj_dir'/g' PreProcess_${NEWSCAN_no_ext}_NoHP.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf
                sed 's/PARTICIPANTSESSIONFOLDER/'$NEWPARTICIPANTSESFOLDER'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp1.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf
                sed 's/FUNCTIONALDATAFOLDER/'func'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp2.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf
                sed 's/PARTICIPANTSTRUCTFOLDER/'$NEWPARTICIPANTANAT'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp3.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf
                sed 's/ANATFOLDER/'$NEWANATFOLDER'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp4.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf
                RepTime=$(sed -n 23p $NEWSCAN_no_ext.json)
                TRtime="${RepTime:18:5}"
                NEWDURATION=$TRtime
                zeros=0000
                NEWDURATIONZEROS=($NEWDURATION$zeros)
                echo 'Repetition Time is ' $NEWDURATIONZEROS
                sed 's/INTENSITYFILE/'$NEWSCAN_no_ext'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp5.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf
                sed 's/SCAN/'$NEWSCAN'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp6.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf
                sed 's/DURATION/'$NEWDURATIONZEROS'/g' PreProcess_${NEWSCAN_no_ext}_NoHP_temp7.fsf > PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf
                HP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$HighpassFrequency))" | bc)
                echo 'Highpass sigma set to ' $HP_sigma
                if [[ "$LowpassFrequency" == "-1" ]] ; then
                    LP_sigma='-1'
                    echo 'lowpass sigma set to ' $LP_sigma ': Lowpass filtering will be skipped'
                else 
                    LP_sigma=$(echo "scale=9; (1/(2*$NEWDURATIONZEROS*$LowpassFrequency))" | bc)
                    echo 'lowpass sigma set to ' $LP_sigma
                fi
                echo 'Running FEAT Pre-Processing (No Temporal Filtering)'
			    feat PreProcess_${NEWSCAN_no_ext}_NoHP_temp8.fsf
				echo 'Running ICA AROMA with Non-Aggressive Clean up'
                source ~/anaconda2/bin/activate neuro-aroma
                python $ICAAROMA/ICA_AROMA.py -feat $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat -den $AROMAMETHOD nonaggr -out $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/ICA_AROMA
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
                    fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50
                    fslmaths mask -dilF mask
                    fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                    #fslmaths denoised_func_data_nonaggr_thresh -mul 1.0337616041 denoised_func_data_nonaggr_intnorm
                    #fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                    #fslmaths denoised_func_data_nonaggr_thresh -Tmean tempMean
                    echo 'Applying Temporal Filtering'
                    fslmaths denoised_func_data_nonaggr_thresh -bptf $HP_sigma $LP_sigma denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                    #fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma -1 -add tempMean denoised_func_data_nonaggr_tempfilt
                    #imrm tempMean
                    #fslmaths denoised_func_data_nonaggr_intnorm denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                    fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                    #rm -rf prefiltered_func_data*
                    applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
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
                    fslstats denoised_func_data_aggr.nii.gz -k mask -p 50
                    fslmaths mask -dilF mask
                    fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                    #fslmaths denoised_func_data_aggr_thresh -mul 1.0337616041 denoised_func_data_aggr_intnorm
                    #fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                    #fslmaths denoised_func_data_aggr_thresh -Tmean tempMean
                    echo 'Applying Temporal Filtering'
                    fslmaths denoised_func_data_aggr_thresh -bptf $HP_sigma $LP_sigma denoised_func_data_aggr_highpassedFSL.nii.gz 
                    #fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma -1 -add tempMean denoised_func_data_aggr_tempfilt
                    #imrm tempMean
                    #fslmaths denoised_func_data_aggr_intnorm denoised_func_data_aggr_highpassedFSL.nii.gz 
                    fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                    #rm -rf prefiltered_func_data*
                    applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                    cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                elif [[ "$AROMAMETHOD" == "both" ]]; then
                    echo 'Non-Aggressive ICA-AROMA Clean up - Almost done'
                    fslmaths denoised_func_data_nonaggr.nii.gz -Tmean mean_func
                    bet2 mean_func mask -f 0.3 -n -m; 
                    immv mask_mask mask
                    fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_bet
                    Threshstattemp1=$(fslstats denoised_func_data_nonaggr_bet -p 2 -p 98)
                    Threshstattemp2="${Threshstattemp1:9:12}"
                    Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                    fslmaths denoised_func_data_nonaggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                    fslstats denoised_func_data_nonaggr.nii.gz -k mask -p 50
                    fslmaths mask -dilF mask
                    fslmaths denoised_func_data_nonaggr.nii.gz -mas mask denoised_func_data_nonaggr_thresh
                    #fslmaths denoised_func_data_nonaggr_thresh -mul 1.0337616041 denoised_func_data_nonaggr_intnorm
                    #fslmaths denoised_func_data_nonaggr_intnorm -Tmean tempMean
                    #fslmaths denoised_func_data_nonaggr_thresh -Tmean tempMean
                    echo 'Applying Temporal Filtering on Non-Aggressive Data'
                    fslmaths denoised_func_data_nonaggr_thresh -bptf $HP_sigma $LP_sigma denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                    #fslmaths denoised_func_data_nonaggr_intnorm -bptf $HP_sigma -1 -add tempMean denoised_func_data_nonaggr_tempfilt
                    #imrm tempMean
                    #fslmaths denoised_func_data_nonaggr_intnorm denoised_func_data_nonaggr_highpassedFSL.nii.gz 
                    fslmaths denoised_func_data_nonaggr_highpassedFSL.nii.gz  -Tmean mean_func
                    #rm -rf prefiltered_func_data*
                    applywarp -i denoised_func_data_nonaggr_highpassedFSL.nii.gz -o denoised_func_data_nonaggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                    echo 'Aggressive ICA-AROMA Clean up - Almost done'
                    fslmaths denoised_func_data_aggr.nii.gz -Tmean mean_func
                    bet2 mean_func mask -f 0.3 -n -m; 
                    immv mask_mask mask
                    fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_bet
                    Threshstattemp1=$(fslstats denoised_func_data_aggr_bet -p 2 -p 98)
                    Threshstattemp2="${Threshstattemp1:9:12}"
                    Threshstat=$(echo "scale=7; (($Threshstattemp2*0.10))" | bc)
                    fslmaths denoised_func_data_aggr_bet -thr $Threshstat -Tmin -bin mask -odt char
                    fslstats denoised_func_data_aggr.nii.gz -k mask -p 50
                    fslmaths mask -dilF mask
                    fslmaths denoised_func_data_aggr.nii.gz -mas mask denoised_func_data_aggr_thresh
                    #fslmaths denoised_func_data_aggr_thresh -mul 1.0337616041 denoised_func_data_aggr_intnorm
                    #fslmaths denoised_func_data_aggr_intnorm -Tmean tempMean
                    #fslmaths denoised_func_data_aggr_thresh -Tmean tempMean
                    echo 'Applying Temporal Filtering on Aggressive Data'
                    fslmaths denoised_func_data_aggr_thresh -bptf $HP_sigma $LP_sigma denoised_func_data_aggr_highpassedFSL.nii.gz 
                    #fslmaths denoised_func_data_aggr_intnorm -bptf $HP_sigma -1 -add tempMean denoised_func_data_aggr_tempfilt
                    #imrm tempMean
                    #fslmaths denoised_func_data_aggr_intnorm denoised_func_data_aggr_highpassedFSL.nii.gz 
                    fslmaths denoised_func_data_aggr_highpassedFSL.nii.gz  -Tmean mean_func
                    #rm -rf prefiltered_func_data*
                    applywarp -i denoised_func_data_aggr_highpassedFSL.nii.gz -o denoised_func_data_aggr_highpassedFSL_MNI152.nii.gz -r $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/standard.nii.gz --premat=$WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/example_func2highres.mat -w $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/${NEWSCAN_no_ext}_ICA.feat/reg/highres2standard_warp.nii.gz
                    cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                    rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                else 
                cd $WFOLDER/$subj_dir/$NEWPARTICIPANTSESFOLDER/func/
                rm -rf PreProcess_${NEWSCAN_no_ext}_NoHP_temp*.fsf
                fi
            done
            cd $WFOLDER/$subj_dir
		done
        cd $WFOLDER
    fi 
done
exit 0