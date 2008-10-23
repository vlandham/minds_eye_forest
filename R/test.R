# assumptions:
#   images_folder -- contains the name of folder of images we're going to classify
#   forests_folder -- contains the name of the folder containing the group of forests we're going to use
#   r_directory -- the base folder for the R scripts used in this script
#   types -- the .dat file that contains the sample classification

# print(images_folder)
# print(forests_folder)

setwd(r_directory)

library('randomForest')
# library('EBImage')