# fMRI-preprocessing-Pipeline
I have provided a bash script to aid in preprocessing fMRI data using ICA-AROMA. This script uses fsl tools

This bash script is written in Ubuntu 18.04 and utilizes the linux GUI 'Zenity'. If you do not have zenity, you may find the installation instructions here: https://linuxconfig.org/how-to-use-graphical-widgets-in-bash-scripts-with-zenity#h3-generic-options

For this script to work you must:
- Save the .fsf file and the script to your computer. This path is currently set to : /media/4TB/justin/Usask_001_imaging_data_1/BIDS/dataset/. All of this will need to change depending on the location of your non-processed BIDS data.
- Have ICA-AROMA-master downloaded on your computerand fully compiled (see the AROMA readme file that came with the download for instructions)
- Have your data setup in the BIDS-standard format

*Note: in the current version I have uploaded I run ICA-AROMA out of a conda environment. This will need to be changed or setup on your own system. The important thing is that ICA-AROMA is run out of a python 2.7 with the necessary dependencies. I have been successfully running ICA-AROMA out of python version 2.7.15.

This pipeline follows the guidelines recommended for ICA-AROMA use: https://www.ncbi.nlm.nih.gov/pubmed/25770991

