namespace :pre do
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/preprocess.yml")[GROUP]
    throw "Error: no input folder" unless CONFIG["input_dir"]
    throw "Error: not a valid input folder" unless File.directory?(CONFIG["input_dir"])
    throw "Error: no output folder" unless CONFIG["output_dir"]
  end
  
  desc "gets the photos and puts them into @photo_list instance variable."
  task :get_photos => :set_options do
    require 'RMagick'
    include Magick
    photos = FileList["#{CONFIG["input_dir"]}/*.jpg","#{CONFIG["input_dir"]}/*.png"]
    @photo_list = ImageList.new(*photos)
    throw "Error: no images in #{CONFIG["output_dir"]}" if @photo_list.empty?
  end
  
  desc "process the photos as dictated by config file"
  task :process => :get_photos do
    
  end
end