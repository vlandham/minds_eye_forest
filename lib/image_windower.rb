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
  attr_accessor :box
  def initialize(im, posx,posy,w,h)
    @image = im
    @x = posx
    @y = posy
    @width = w
    @height = h
    @box = false
  end
  
  def to_a
    # puts "getting #{@width} by #{@height} from #{@image.inspect}"
    temp= @image.get_pixels(@x,@y,@width,@height)
    # puts temp.length.to_s
    temp
  end
  
  def write(filename)
    window_image = Image.constitute(@width,@height, 'RGBA', self.to_a)
    window_image.write(filename)
    # new_eye.store_pixels(0,0,col,row,pixs)
  end
  
  def window
    img = Image.new(@width,@height)
    img.store_pixels(0,0,@width,@height,self.to_a)
    img
  end
end

class ImageWindower
  attr_reader :image
  attr_reader :window_width
  attr_reader :window_height
  attr_reader :window_step
  attr_accessor :box_indices
  def initialize(im, cols, rows, increment)
    @image = im
    @window_width = cols
    @window_height = rows
    @window_step = increment
    @windows = Array.new
    window
  end
  
  def window_images
    @windows.map {|win| win.window}
  end
  
  def write(filename)
    wind_img = window_images
    imgs = ImageList.new
    wind_img.each {|wi| imgs << wi}
    imgs.write(filename)
  end
  
  def create_table(table_name)
    # require 'feature_extractor'
    tot_rows = 0
    tot_cols = nil
    # file_string = ""
    vector_array = Array.new
      @windows.each do |win|
        wi = win.window
        vec = FeatureExtractor.convert(wi)
        tot_cols ||= vec.size
        vector_array << vec
        # st = vec.join(" ") 
        # file_string << "#{st}\n"
        tot_rows += 1
      end #each window
      s = vector_array.to_matrix
    File.open(table_name,'w') do |f|
      f << s
    end #file
    
    [tot_rows,tot_cols]
  end
  
  def add_boxes(indices)
    @box_indices = indices
  end
  
  def boxed_image
    box_image = @image.copy
     @windows.values_at(*@box_indices).each {|win| add_box(box_image,win)}
     box_image
  end
  
  def add_box(image, win)
    box = Draw.new
    box.stroke('red')
    box.stroke_width(2)
    box.fill_opacity(0)
    # puts "rec: #{win.x}, #{win.y} --  #{win.x+win.width}, #{win.y+win.height}"
    box.rectangle(win.x,win.y,win.x+win.width, win.y+win.height)
    box.draw(image)
  end
  
  private
  def window()
    (0...(@image.rows - @window_height)).step(@window_step) do |cur_y|
      (0...(@image.columns - @window_width)).step(@window_step) do |cur_x|
        # TODO: check if valid?
        @windows << Window.new(@image, cur_x, cur_y, @window_width, @window_height)
      end #cur_x
    end #cur_y
  end
end