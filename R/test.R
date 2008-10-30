# assumptions:
#   images_folder -- contains the name of folder of images we're going to classify
#   forests_folder -- contains the name of the folder containing the group of forests we're going to use
#   r_directory -- the base folder for the R scripts used in this script
#   results_folder --  folder to store the results for the classification

# print(images_folder)
# print(forests_folder)

setwd(r_directory)

source('startup.R')
source('get_forests.R')
