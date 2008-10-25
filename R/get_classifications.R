get_classifications <- function(class_file,size)
{
  class_set = matrix(scan(file=class_file, what="", n=size), size, 1, byrow = TRUE)
  class_set_factor <- factor(class_set)
  class_set_factor
}