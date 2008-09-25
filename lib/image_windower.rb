# segments up an image based on the height and width of the the 
#  desired segments as well as the windowing parmeter
#  returns an array of images from the original, each of size width x height,
#   where the image at 

class Window
  attr_accessor :image
  attr_accessor :x
  attr_accessor :y
  attr_accessor :width
  attr_accessor :height
  def initialize(im, posx,posy,w,h)
    @image = im
    @x = posx
    @y = posy
    @width = w
    @height = h
  end
end

class ImageWindower
  def initialize()
  end
  def window()
  end
end