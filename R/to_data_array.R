to_data_array <- function(images)
{
  matrix(imageData(images), nrow=dim(images)[3])
}