namespace :classify do
  desc "Sets where the folder of images to classify is, and where the random forests are."
  task :set_options do
    puts "Reading configuration for classify"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/classify.yml")
    
    # create directory for the training datasets
    throw "Error: no tables folder" unless CONFIG["tables"]
    puts "creating directory structure for : #{CONFIG['tables']}"
    mkdir_p CONFIG['tables']
    @tables_folder = CONFIG['tables']
    
    # samples is just a filename for now - should make it a list, or better, recurse through
    throw "Error: no sample folder" unless CONFIG["samples"]
    @sample_folder = CONFIG['samples']
    
    # Now we need to load those forests.  We'll have the forests option be an array of forests
    throw "Error: no forests present" unless CONFIG['forests']
    @forests = CONFIG['forests']
    @forests.each {|fr| puts "Using forest: #{fr}.rf"}
    
    # Lets also get that scripts folder going for us
    throw "Error: no scripts folder" unless CONFIG['script']
    @scripts_folder = CONFIG['script']
    puts "creating directory structure for scripts: #{@scripts_folder}"
    mkdir_p @scripts_folder
  end
  
  desc "loads images from samples folder"
  task :load_images do
    require 'RMagick'
    include Magick
    if File.directory?(@sample_folder)
      puts "Loading images from #{@sample_folder}"
      photo_files = FileList["#{@sample_folder}/*.jpg","#{@sample_folder}/*.png"]
      @original_images = ImageList.new(*photo_files)
    else
      puts "Error: not a valid input folder - #{@sample_folder}"
    end 
    puts "loaded #{@original_images.size} images"
  end
  
  desc "gets the names of the trees to be used and ensures that they are all valid"
  task :load_trees => :set_options do
    @forest_names = Array.new
    @forests.each do |fr|
      if File.exists?("#{fr}.rf")
        @forest_names << "#{fr}.rf"
      else
        throw "Error: #{fr}.rf not a forest present in the forest folder"
      end
    end
  end
  
  desc "create gaussian pyramid for each image to test - different sizes to find different sized targets"
  task :create_pyramid => :load_images do
    scale_min = CONFIG['scale']['min'] || 0.4
    scale_max = CONFIG['scale']['max'] || 1.2
    scale_step = CONFIG['scale']['step'] || 0.2
    @pyramid = Hash.new
    puts "Resizing each image from #{scale_min} to #{scale_max} by #{scale_step} each time"
    @original_images.each do |img|
      pym = Array.new
      (scale_min..scale_max).step(scale_step) do |step|
        pym << img.scale(step)
      end
      @pyramid[img.filename] = pym
    end
  end
  
  desc ""
  task :classify => :create_pyramid do
    @pyramid.each do |filename, img_array|
      img_array.each do |img|
        windower = ImageWindower.new(img, window_cols, window_rows, window_step)
        window_set = windower.window()
        vectors = FeatureExtractor.extract_without_classes(window_set)
        TableMaker.make_table_without_classes(vectors)
        # write the R program
        # execute the r program
        # results will be saved to file...
        
        # read results
        # every window with + for 
      end
    end
  end
  
  desc "link up the tasks and run this thing"
  task :samples => [:set_options, :load_images, :load_trees, :create_pyramid]
  
end