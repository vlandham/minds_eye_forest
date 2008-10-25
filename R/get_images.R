get_images <- function(images_folder)
{
  image_names <- dir(images_folder, pattern='.*.jpg')
  # read all the images from the folder into the stack of images - images
  images <- readImage(paste(images_folder, image_names, sep="/"),colormode=TrueColor)
}