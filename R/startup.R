# assumptions:
#   images_folder -- contains the name of folder of images we're going to classify
#   r_directory -- the base folder for the R scripts used in this script

library('randomForest')
library('EBImage')
source('possible_forests.R')
source('get_images.R')
# actually loads all the forest objects

source('to_data_array.R')

image_names <- dir(images_folder, pattern='.*.jpg')
images <- get_images(images_folder)

# get grayscale version of the images
gray_images <- channel(images, 'gray')
gray_images <- normalize(gray_images)