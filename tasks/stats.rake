require 'RMagick'
include Magick

class Magick::ImageList
  def average(attribute)
     self.inject(0) {|sum, photo| sum + photo.send(attribute.to_sym)} / self.size
  end
  
  def max(attribute)
    self.inject(0) do |max, photo| 
      value = photo.send(attribute.to_sym)
      max = value > max ? value : max
    end
  end
  
  def min(attribute)
    self.inject(1000000) do |min, photo| 
      value = photo.send(attribute.to_sym)
      min = value < min ? value : min
    end
  end
end

namespace :stats do
  
  desc "Test to see how to add input arguments to a task"
  task :check_args, :one, :two do |t,args|
    puts "#{args.one}"
    puts "#{args.two}"
  end
  
  task :report => [:get_photos, :avg_height, :avg_width, :max_height, :max_width, 
                   :min_height, :min_width, :size, :print_report]
  
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/stats.yml")[GROUP]
    throw "Error: no input folder" unless CONFIG["input_dir"]
    throw "Error: not a valid input folder" unless File.directory?(CONFIG["input_dir"])
    @report = []
  end
  
  desc "gets the photos and puts them into @ping_list instance variable."
  task :get_photos => :set_options do
    puts "Getting photos from #{CONFIG['input_dir']}"
    photos = FileList["#{CONFIG["input_dir"]}/*.jpg","#{CONFIG["input_dir"]}/*.png"]
    @ping_list = ImageList.new
    @ping_list.ping(*photos)
    throw "Error: no images in #{CONFIG["input_dir"]}" if @ping_list.empty?
  end
    
  task :print_report do
    throw "Error: no report file" unless CONFIG["report"]
    File.open(CONFIG["report"],'w') do |f|
      f << @report
    end
  end
  
  task :size do
    @report << "Size:\t#{@ping_list.length}\n"
  end
  
  desc "get average height of all images in @ping_list"
  task :avg_height => :get_photos do
    avg_height = @ping_list.average(:rows)
    puts "Average Height: #{avg_height} of #{@ping_list.length} images"
    @report << "Average Height:\t#{avg_height}\n"
  end
  
  desc "get average width of all images in @ping_list"
  task :avg_width => :get_photos do
    avg_width = @ping_list.average(:columns)
    puts "Average Width: #{avg_width} of #{@ping_list.length} images"
    @report << "Average Width:\t#{avg_width}\n"
  end
  
  desc "get maximum value of height "
  task :max_height => :get_photos do 
    max_height = @ping_list.max(:rows)
    puts "Max Height: #{max_height} of #{@ping_list.length} images"
    @report << "Max Height:\t#{max_height}\n"
  end
  
  desc "get maximum value of width "
  task :max_width => :get_photos do 
    max_width = @ping_list.max(:columns)
    puts "Max Width: #{max_width} of #{@ping_list.length} images"
    @report << "Max Width:\t#{max_width}\n"
  end
  
  desc "get minimum value of height "
  task :min_height => :get_photos do 
    min_height = @ping_list.min(:rows)
    puts "Min Height: #{min_height} of #{@ping_list.length} images"
    @report << "Min Height:\t#{min_height}\n"
  end
  
  desc "get minimum value of width "
  task :min_width => :get_photos do 
    min_width = @ping_list.min(:columns)
    puts "Min Width: #{min_width} of #{@ping_list.length} images"
    @report << "Min Width:\t#{min_width}\n"
  end

end

