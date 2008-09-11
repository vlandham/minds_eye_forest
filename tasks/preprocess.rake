namespace :pre do
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/preprocess.yml")[GROUP]
    throw "Error: no input folder" unless CONFIG["input_dir"]
    throw "Error: not a valid input folder" unless File.directory?(CONFIG["input_dir"])
    throw "Error: no output folder" unless CONFIG["output_dir"]
    @append = []
  end
  
  desc "gets the photos and puts them into @photo_list instance variable."
  task :get_photos => :set_options do
    require 'RMagick'
    include Magick
    puts "Getting photos from #{CONFIG['input_dir']}"
    photos = FileList["#{CONFIG["input_dir"]}/*.jpg","#{CONFIG["input_dir"]}/*.png"]
    @photo_list = ImageList.new(*photos)
    throw "Error: no images in #{CONFIG["input_dir"]}" if @photo_list.empty?
  end
  
  desc "stores the photos in @photo_list to the output dir"
  task :store_photos => :get_photos do
    output_dir = CONFIG['output_dir']
    remove_dir(output_dir) if File.directory?(output_dir)
    mkdir(output_dir)
    @append.unshift "%d"
    file_name = output_dir+"/"+@append.join('_')+".jpg"
    puts "Creating modified images: #{file_name}"
  
    @photo_list.write(file_name)
  end
  
  desc "resize the photos in place.  w & h are in the size portion of config file"
  task :resize do
    throw "Error: no resize values" unless CONFIG['size']
    # work with @photo_list
    w = CONFIG['size']['w']
    h = CONFIG['size']['h']
    @photo_list.each do |photo|
      photo.resize!(w,h)
    end
    @append << "resize-#{w}x#{h}"
  end
  
  desc "process photos - chain up a bunch of tasks"
  task :process => [:get_photos, :resize, :store_photos]
  
end