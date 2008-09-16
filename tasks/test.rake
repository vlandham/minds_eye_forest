namespace :test do
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/train.yml")[GROUP]
    throw "Error: no samples folder" unless CONFIG["samples"]  
    # create directory for the training datasets
    puts "creating directory structure for : #{CONFIG['tables']}"
    mkdir_p CONFIG['tables']
    # samples is a hash with folder/name => classification_type
    @samples = CONFIG["samples"]
  end
  
  desc "Gets the images from the folders described in the configuration file"
  task :get_images => :set_options do
    require 'RMagick'
    include Magick
    @images = Hash.new
    @samples.each do |folder_name, target_type|
      if File.directory?(folder_name)
        puts "Assigning #{folder_name} to type #{target_type}"
        photo_files = FileList["#{folder_name}/*.jpg","#{folder_name}/*.png"]
        photos = ImageList.new(*photo_files)
        @images[target_type] = photos
      else
        puts "Error: not a valid input folder - #{folder_name}"
      end
    end
  end
  
  desc "vectorizes the image data into one long vector."
  task :vectorize => :get_images do
    @raw_data = Hash.new
    @images.each do |target_type, photo_array|
      vector_array = Array.new
      photo_array.each do |photo|
        temp_photo = photo.export_pixels(0,0,photo.columns,photo.rows,CONFIG['pixel_info'])
        temp_photo.map! {|pixel| pixel.to_f / QuantumRange.to_f}
        vector_array << temp_photo
      end
      @raw_data[target_type] = vector_array
    end
  end
  
  desc "takes data from images and converts to tables needed for RF training"
  task :create_tables => :vectorize do
    output_dir = CONFIG['tables']
    throw "Error: #{output_dir} does not exist" unless File.directory?(output_dir)
    @data_set_name = "#{output_dir}/#{GROUP}-testset.dat"
    @class_set_name = "#{output_dir}/#{GROUP}-classset.dat"
    data_set = File.new(@data_set_name, "w")
    class_set = File.new(@class_set_name, "w")
    @cols = nil
    @rows = 0
    
    @raw_data.each do |target_type, vector_array|
      @rows += vector_array.size
      vector_array.each do |vector|
        @cols ||= vector.size
        data_set << vector.join(" ") << "\n"
        class_set << '"'<< target_type << '"' << "\n"
      end      
    end  
    data_set.close
    class_set.close
  end
  
end