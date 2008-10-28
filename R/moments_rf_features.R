moments_rf_features <- function(images,gray_images)
{  
  # get moments for both and combine them
  print("Getting moments")
  timer <- system.time(m1 <- moments(gray_images))
  print(timer)
  # m2 <- moments(edge_gray_images)
  
  # image_moments = c(m1,m2)
  # image_moments = m1
  m1
}