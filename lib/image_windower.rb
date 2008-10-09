# segments up an image based on the height and width of the the 
#  desired segments as well as the windowing parmeter
#  returns an array of images from the original, each of size width x height,
#   where the image at 

class Box
  attr_accessor :x
  attr_accessor :y
  attr_accessor :width
  attr_accessor :height
  attr_accessor :x_scale
  attr_accessor :y_scale
  attr_accessor :votes
  def initialize(posx,posy,w,h)
    @x = posx
    @y = posy
    @width = w
    @height = h
    @votes = 0
  end
  
  def scale!
    @x = (@x.to_f / @x_scale).round
    @y = (@y.to_f / @y_scale).round
    @width = (@width / @x_scale).round
    @height = (@height / @y_scale).round
  end
  
  def drawing
    box_draw = Draw.new
    box_draw.stroke('red')
    box_draw.stroke_width(2)
    box_draw.fill_opacity(0)
    # puts "rec: #{win.x}, #{win.y} --  #{win.x+win.width}, #{win.y+win.height}"
    box_draw.rectangle(@x,@y,@x+@width, @y+@height)
    box_draw
  end
  
  def draw(im)
    draw_box = drawing
    draw_box.draw(im)
  end
end

class Window
  attr_accessor :image
  attr_accessor :box
  def initialize(im, posx,posy,w,h)
    @image = im
    @box = Box.new(posx,posy,w,h)
    @box.x_scale = (im.columns.to_f / im.base_columns.to_f).to_f
    @box.y_scale = (im.rows.to_f / im.base_rows.to_f).to_f
  end
  
  def to_a
    # puts "getting #{@width} by #{@height} from #{@image.inspect}"
    temp= @image.get_pixels(@box.x,@box.y,@box.width,@box.height)
    # puts temp.length.to_s
    temp
  end
  
  def write(filename)
    window_image = Image.constitute(@box.width,@box.height, 'RGBA', self.to_a)
    window_image.write(filename)
    # new_eye.store_pixels(0,0,col,row,pixs)
  end
  
  def window
    img = Image.new(@box.width,@box.height)
    img.store_pixels(0,0,@box.width,@box.height,self.to_a)
    img
  end
  
  def draw(image)
    @box.draw(image)
  end
  
  def x
    @box.x
  end
  def y
    @box.y
  end
  def width
    @box.width
  end
  def height
    @box.height
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
    tot_rows = 0
    tot_cols = nil
    file_string = ""
    # vector_array = Array.new
      @windows.each do |win|
        wi = win.window
        vec = FeatureExtractor.convert(wi)
        tot_cols ||= vec.size
        # vector_array << vec
        file_string << "#{vec.to_int_s_quick}\n"
        tot_rows += 1
        wi.destroy!
        wi = nil
        vec = nil
      end #each window
      # s = vector_array.to_matrix
    File.open(table_name,'w') do |f|
      # f << s
      f << file_string
    end #file

    s = nil
    vector_array = nil

    [tot_rows,tot_cols]
  end
  
  def add_boxes(indices)
    # lazy boxing
    @box_indices = indices
  end
  
  def boxed_image
    box_image = @image.copy
     @windows.values_at(*@box_indices).each {|win| draw_box(box_image,win)}
     box_image
  end
  
  def get_boxes
    @windows.values_at(*@box_indices).map {|win| win.box}
  end
  
  def get_scaled_boxes
    boxes = get_boxes
    boxes.each {|b| b.scale!}
    boxes
  end
  
  def draw_box(image, win)
    win.draw(image)
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