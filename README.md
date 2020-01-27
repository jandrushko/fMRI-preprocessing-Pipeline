# fMRI-preprocessing-Pipeline
I have provided a bash script to aid in preprocessing fMRI data using ICA-AROMA. This script uses fsl tools

This bash script is written in Ubuntu 18.04 and utilizes the linux GUI 'Zenity'. If you do not have zenity, you may find the installation instructions here: https://linuxconfig.org/how-to-use-graphical-widgets-in-bash-scripts-with-zenity#h3-generic-options

For this script to work you must:
- Save the .fsf file and the script to your computer
- Have ICA-AROMA-master downloaded on your computerand fully compiled (see the AROMA readme file that came with the download for instructions)

*Note: in the current version I have uploaded I run ICA-AROMA out of a conda invironment. This will need to either be changed or setup on your own system.

This pipeline follows the guidelines recommended for ICA-AROMA use: https://www.ncbi.nlm.nih.gov/pubmed/25770991

