namespace :common do
  # tasks that are common to multiple namespaces  
  
  
  # ASSUMES: @samples is a hash with folder name and target type
  # RETURNS: @images folder containing the loaded images from the folders
  desc "Gets the images from the folders described in the configuration file"
  task :get_images do
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
  
  desc "saves images to temporary directory"
  task :save_images do
    # need images and training folder
    throw "no images folder or training folder" unless @images_folder and @type_folder
    base_image_name = "%010d.jpg"
    photos = ImageList.new
    types = Array.new
    @samples.each do |folder_name, target_type|
      if File.directory?(folder_name)
        puts "Assigning #{folder_name} to type #{target_type}"
        photo_files = FileList["#{folder_name}/*.jpg","#{folder_name}/*.png"]
        photos.read(*photo_files)
        photo_files.length.times {types << target_type}
      else
        puts "Error: not a valid input folder - #{folder_name}"
      end
    end
    
    puts "writing images to #{@images_folder}"
    photos.write("#{@images_folder}/#{base_image_name}")
    photos.each {|photo| photo.destroy!}
    @type_file = File.expand_path(@type_folder)+"/types.dat"
    puts "writing results to #{@type_file}"
    File.open(@type_file,'w') do |f|
      types.each {|t| f << t+"\n"}
    end
  end
  
  desc "vectorizes the image data into one long vector."
  task :vectorize => :get_images do
    puts "vectorizing images..."
    @raw_data = Hash.new
    @images.each do |target_type, photo_array|
      vector_array = Array.new
      photo_array.each do |photo|
        vector = FeatureExtractor.convert(photo)
        vector_array << vector
      end
      @raw_data[target_type] = vector_array
    end
    puts "setting images to nil"
    @images = nil
    puts "done"
  end
  
  desc "takes data from images and converts to tables needed for RF training"
  task :create_tables => :vectorize do
    puts "creating tables..."
    output_dir = CONFIG['tables']
    throw "Error: #{output_dir} does not exist" unless File.directory?(output_dir)
    @data_set_name = "#{output_dir}/#{GROUP}-testset.dat"
    @class_set_name = "#{output_dir}/#{GROUP}-classset.dat"
    @cols, @rows = TableMaker.make_table(@data_set_name, @class_set_name, @raw_data)
    puts "setting raw_data to nil to get rid of unecessary variables"
    @raw_data = nil
    
    puts "done"
  end
 
  
end