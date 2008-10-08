class ImageResult
  attr_reader :filename
  attr_accessor :targets
  def initialize(filename)
    @filename = filename
    @targets = Hash.new
  end
  
  def add_target(type,boxes)
    @targets[type] = boxes
  end
end

class ClassificationResults
  attr_accessor :images
  def initialize
    @images = Array.new
  end
  def add(im_result)
    @images << im_result
  end
end