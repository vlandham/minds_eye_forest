# assumptions:
#   images_folder -- contains the name of folder of images we're going to classify
#   forests_folder -- contains the name of the folder containing the group of forests we're going to use
#   r_directory -- the base folder for the R scripts used in this script
#   results_file --  file to store the results for the classification

print(results_folder)
# print(forests_folder)

setwd(r_directory)

library('randomForest')
library('EBImage')
source('possible_forests.R')
source('get_images.R')
# actually loads all the forest objects
source('get_forests.R')
source('to_data_array.R')

image_names <- dir(images_folder, pattern='.*.jpg')
images <- get_images(images_folder)

# get grayscale version of the images
gray_images <- channel(images, 'gray')

# loop through all possibly trained rfs
# if a rf is present, then we will use it to
# call the appropriate function for preprocessing the 
# images for it, and then classify the image using
# that forest.
possible_rfs <- possible_forests()
for (possible_rf in possible_rfs)
{
  print(possible_rf)
  # if this rf exists in our workspace
  if(exists(possible_rf))
  {
    print(paste("found forest:", possible_rf))
    # acquire the actual rf (possible_rf is just a string)
    # rf is the actual forest data structure
    rf <- get(possible_rf)
    
    # build a name for the function to call
    feature_function <- paste(possible_rf,"features",sep="_")
    feature_file <- paste(feature_function,"R",sep=".")
    source(feature_file)
    
    # evaluate the feature function, passing in the images
    print(paste('getting features for:', possible_rf))
    command <- paste('features <- ',feature_function,'(images,gray_images)',sep="")
    timer <- system.time(eval(parse(text = command)))
    print(timer)
    print(paste('features size:', dim(features)))
    
    # classify the features using the rf
    print('predicting')
    timer <- system.time(results <- predict(rf,features,type="vote", norm.votes=TRUE))
    print(timer)
    results <- cbind(image_names, results) #put filenames in 
    # save results
    results_file <- paste(results_folder, "/", possible_rf,"_out.txt",sep="")    
    write.table(results, file=results_file, sep=",", row.names=FALSE,quote=c(1), na="nil")
  }
}