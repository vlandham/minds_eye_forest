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
image_name <- image_names[1]

# read all the images from the folder into the stack of images - images
# images <- readImage(paste(images_folder, image_names, sep="/"),colormode=TrueColor)
# gray_images <- readImage(paste(images_folder, image_names, sep="/"))

forest_names <- dir(forests_folder, pattern='.*.rf')
forests <- paste(forests_folder, forest_names,sep="/")
print(forests)
load(file=forests)


source('possible_forests.R')

# loop through all possibly trained rfs
possible_rfs <- possible_forests()
for (possible_rf in possible_rfs)
{
  print(possible_rf)
  # if this rf exists in our workspace
  if(exists(possible_rf))
  {
    # acquire the actual rf (possible_rf is just a string)
    rf <- get(possible_rf)
    # build a name for the function to call
    feature_function <- paste(possible_rf,"features",sep="_")
    feature_file <- paste(feature_function,"R",sep=".")
    source(feature_file)
    # evaluate the feature function, passing in the images
  }
}