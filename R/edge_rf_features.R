edge_rf_features <- function(images,gray_images)
{
  # get just edges
  print("Getting edges")
  timer <- system.time(edge_gray_images <- edge(gray_images))
  print(timer)
  to_data_array(edge_gray_images)
}
