# assumptions:
#   images_folder -- contains the name of folder of images we're going to classify
#   forests_folder -- contains the name of the folder containing the group of forests we're going to use
#   r_directory -- the base folder for the R scripts used in this script
#   classifications_file -- the file containing the actual classifications of our images
#   classifications_size -- size of the types vector to import
setwd(r_directory)
# print(images_folder)
# print(forests_folder)
source('startup.R')
source('get_classifications.R')

classes <- get_classifications(classifications_file,classifications_size)

# for each of the possible forests to create
#  if the function to extract features for that
#  rf has been implemented, then run it, and
#  then train a rf from the generated features
#  and given true values
rf_names <- possible_forests()
for (rf_name in rf_names)
{
  # print(rf_name)
  feature_function <- paste(rf_name,"features",sep="_")
  feature_file <- paste(feature_function,"R",sep=".")
  # print(feature_file)
  if(file.exists(feature_file))
   {
     print(rf_name)
     source(feature_file)
     # evaluate the feature function, passing in the images
     command <- paste('features <- ',feature_function,'(images,gray_images)',sep="")
     eval(parse(text = command)) 
     print('training random forest')
     print(paste('features size:', dim(features)))
     print(paste('training set size:',dim(classes),length(classes)))
     # create new rf with correct name, train it with features & classes
     assign(rf_name, randomForest(features, classes, ntree=100))
     # save rf to the correct file
     rf_file <- paste(forests_folder,"/",rf_name,".rf",sep="")
     print(paste('saving random forest to:',rf_file))
     # rf <- get(rf_name)
     # print(rf_file)
     save(list=as.character(rf_name), file=rf_file)
   }
}  
