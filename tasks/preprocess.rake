namespace :pre do
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/preprocess.yml")[GROUP]
    throw "Error: no input folder" unless CONFIG["input_dir"]
    throw "Error: not a valid input folder" unless File.directory?(CONFIG["input_dir"])
    throw "Error: no output folder" unless CONFIG["output_dir"]
    puts "#{CONFIG['input_dir']}"
  end
  
  desc "converts the original images as defined by the yml file and adds them to the output_dir"
  task :process => :set_options do
    require 'RMagick'
    include Magick
    photos = FileList["#{CONFIG["input_dir"]}/*.jpg","#{CONFIG["input_dir"]}/*.png"]
    photo_list = ImageList.new(*photos)
    photo_list.each {|po| puts po}
  end
end