# assumptions:
#   images_folder -- contains the name of folder of images we're going to classify
#   forests_folder -- contains the name of the folder containing the group of forests we're going to use
#   r_directory -- the base folder for the R scripts used in this script

# print(images_folder)
# print(forests_folder)

setwd(r_directory)

library('randomForest')
# library('EBImage')

image_names <- dir(images_folder, pattern='.*.jpg')
# read all the images from the folder into the stack of images - images
# images <- readImage(paste(images_folder, image_names, sep="/"),colormode=TrueColor)
# gray_images <- readImage(paste(images_folder, image_names, sep="/"))

source('possible_forests.R')
rf_names <- possible_forests()
for (rf_name in rf_names)
{
  print(rf_name)
  feature_function <- paste(rf_name,"features",sep="_")
  feature_file <- paste(feature_function,"R",sep=".")
  if(file.exists(feature_file))
   {
     print(rf_name)
     source(feature_file)
     # if this rf exists in our workspace
   }
  
