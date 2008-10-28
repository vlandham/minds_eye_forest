original_rf_features <- function(images,gray_images)
{
  print('converting to data array')
  timer <- system.time(features <- to_data_array(gray_images))
  print(timer)
  features
}