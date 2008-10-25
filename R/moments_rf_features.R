moments_rf_features <- function(images)
{
  # get grayscale version of the images
  gray_images <- channel(images, 'gray')
  # get just edges
  edge_gray_images <- edge(gray_images)
  
  # get moments for both and combine them
  m1 <- moments(gray_images)
  m2 <- moments(edge_gray_images)
  
  # image_moments = c(m1,m2)
  image_moments = m1
  image_moments
}