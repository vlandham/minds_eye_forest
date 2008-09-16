namespace :train do
  
  desc "Chains the processing steps together to create a dataset from folders of images and train the RF"
  task :rf => [:set_options, :get_images, :vectorize, :create_tables, :write_r_script, :train]
  
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
  task :get_images do
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
  
  desc "write the R script to train with this dataset"
  task :write_r_script => :create_tables do
    script_folder = CONFIG['script'] || "scripts"
    tree_folder = CONFIG['tree'] || "trees"
    tree_name = CONFIG['name'] || GROUP
    puts "Creating script folder if necessary: #{script_folder}"
    mkdir_p script_folder
    mkdir_p tree_folder
    @script_name = "#{script_folder}/#{GROUP}_train.R"
    puts "Creating script: #{@script_name}"
    
    # if # of tress or # of attributes to look at are given, set that up here.
    tree_string = CONFIG['trees'] ? ", ntree=#{CONFIG['trees']}" :  ", ntree=100"
    tries_string = CONFIG['tries'] ? ", mtry=#{CONFIG['tries']}" : ""
    
    # Create the R script for this traingset / RF
    script_file = File.open(@script_name, 'w') do |file|
      file << "library(\'randomForest\')\n"
      file << "training_set = matrix(scan(\'#{File.expand_path(@data_set_name)}\', n=#{@rows*@cols}),"
      file << " #{@rows}, #{@cols}, byrow = TRUE)\n"
      file << "class_set = matrix(scan(file=\'#{File.expand_path(@class_set_name)}\', what=\"\", n=#{@rows}),"
      file << " #{@rows}, 1, byrow = TRUE)\n"
      file << "class_set_factor <- factor(class_set)\n"
      file << "#{tree_name}_rf <- randomForest(training_set, class_set_factor#{tree_string}#{tries_string})\n"
      file << "save(#{tree_name}_rf, file=\'#{File.expand_path(tree_folder)}/#{tree_name}.rf\')\n"
    end
  end
  
  desc "calls R in batch mode with the script created by this run"
  task :train => :write_r_script do 
    puts "running script in R"
    `r CMD BATCH #{File.expand_path(@script_name)} #{File.expand_path(@script_name)}out`
  end
  
end