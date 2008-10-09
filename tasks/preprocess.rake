namespace :pre do
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/preprocess.yml")[GROUP]
    @append = []
  end
  
  desc "gets the photos and puts them into @photo_list instance variable."
  task :get_photos => :set_options do
    require 'RMagick'
    include Magick    
    @photos = Hash.new
    CONFIG['folders'].each do |folder|
      # puts folder.inspect
      puts "working with : #{folder['name']}"
      throw "Error: no input folder" unless folder["input_dir"]
      throw "Error: not a valid input folder" unless File.directory?(folder["input_dir"])
      
      puts "Getting photos from #{folder['input_dir']}"
      photos = FileList["#{folder["input_dir"]}/*.jpg","#{folder["input_dir"]}/*.png"]
      photo_list = ImageList.new(*photos)
      throw "Error: no images in #{folder["input_dir"]}" if photo_list.empty?
      @photos[folder['name']] = photo_list
    end
  end
  
  desc "stores the photos in @photo_list to the output dir"
  task :store_photos => :get_photos do
    @append.unshift "%d"
    CONFIG['folders'].each do |folder|
      photo_list = @photos[folder['name']]
      output_dir = folder['output_dir']
      remove_dir(output_dir) if File.directory?(output_dir)
      mkdir(output_dir)
      
      file_name = output_dir+"/"+@append.join('_')+".jpg"
      puts "Creating modified images: #{file_name}"
      
      throw "Error: no output folder" unless folder["output_dir"]
      puts "creating directory structure for : #{folder['output_dir']}"
      mkdir_p folder['output_dir']
 
      photo_list.write(file_name)
    end 
  end
  
  desc "resize the photos in place.  w & h are in the size portion of config file"
  task :resize do
    throw "Error: no resize values" unless CONFIG['size']
    # work with @photo_list
    w = CONFIG['size']['w']
    h = CONFIG['size']['h']
    @photos.each do |name,photo_list|
      puts photo_list.inspect
      photo_list.each do |photo|
        photo.resize!(w,h)
      end
    end
    @append << "resize-#{w}x#{h}"
  end
  
  desc "process photos - chain up a bunch of tasks"
  task :process => [:get_photos, :resize, :store_photos]
  
end