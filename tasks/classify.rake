namespace :classify do
  
  desc "Sets where the folder of images to classify is, and where the random forests are."
  task :set_options do
    puts "Reading configuration for classify"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/classify.yml")
    
    throw "Error: no tables folder" unless CONFIG["tables"]
    puts "creating directory structure for : #{CONFIG['tables']}"
    mkdir_p CONFIG['tables']
    @tables_folder = CONFIG['tables']
    
    # samples is just a filename for now - should make it a list, or better, recurse through
    throw "Error: no sample folder" unless CONFIG["samples"]
    @sample_folder = CONFIG['samples']

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
  task :check_trees => :set_options do
    throw "Error: no forests present" unless CONFIG['forests']
    @forests = CONFIG['forests']  
    @forests.each do |fr|
      puts "Using forest: #{fr}.rf"
      throw "Error: #{fr}.rf not a forest present in the forest folder" unless File.exists?("#{fr}.rf")
    end
  end
  
  desc "resize the image initially to standardize all images"
  task :resize => :load_images do
    geometry = '800x600>'
    puts "resizing to : #{geometry}"
    @original_images.each do |img|
      img.change_geometry!(geometry) { |cols, rows, img|
       img.resize!(cols, rows)
       } 
    end
  end
  
  desc "create gaussian pyramid for each image to test - different sizes to find different sized targets"
  task :create_pyramid => :load_images do
    scale_min = CONFIG['scale']['min'] || 0.4
    scale_max = CONFIG['scale']['max'] || 1.2
    scale_step = CONFIG['scale']['step'] || 0.2
    @pyramids = Hash.new
    puts "Resizing each image from #{scale_min} to #{scale_max} by #{scale_step} each time"
    @original_images.each do |img|
      pym = Array.new      
      (scale_min..scale_max).step(scale_step) do |step|
        pym << img.scale(step)
      end
      @pyramids[img.filename] = pym
    end
    # is this needed ? we have the base_columns and base_rows still in the resized images...
    @steps = Array.new
    (scale_min..scale_max).step(scale_step) do |step|
      @steps << step
    end
  end
  
  desc ""
  task :classify => [:create_pyramid, :check_trees ] do
    # require 'ruby-prof'
    
    @pyramids.each do |filename, img_array|
      # img_array.each do |img|
      img = img_array[0]
        @forests.each do |full_forest|
          forest = full_forest.split("/")[-1]
          table_name = "#{@tables_folder}/#{forest}_classify.dat"
          window_cols = 80
          window_rows = 90
          window_step = CONFIG['window'] || 10
          puts "Windowing #{img.filename}"
          windower = ImageWindower.new(img, window_cols, window_rows, window_step)
          
          puts "Creating table: #{table_name}"
          # RubyProf.start
          rows, cols = windower.create_table(table_name)
          # result = RubyProf.stop
          puts "Table created with #{rows} rows and #{cols} columns"
          # windower.write("#{File.dirname(__FILE__)}/../test/windows/window.jpg")
          
          puts "Writing R script for classification"
          matrix_name = "classify_set"
          output_name = "result"
          output_file = "#{@tables_folder}/#{forest}_output.txt"
          script = RScriptMaker.new("#{@scripts_folder}/#{forest}_classify.R")
          script.library "randomForest"
          script.load_matrix(matrix_name,table_name,rows,cols)
          script.load "#{full_forest}.rf"
          script.assign(output_name, "predict(#{forest}_rf, #{matrix_name})")
          # script.command "#{output_name} <- predict(#{forest}_rf, #{matrix_name})"
          script.save_matrix(output_name, output_file)
          script.quit
          script.close
          
          puts "Executing script: #{script.name}..."
          script.execute
          puts "done"
          
          puts "Reading results"        
          r_reader = ResultReader.new(output_file)
          # r_reader.print
          
          targets = r_reader.positives

          # add boxes to matches in image
          windower.add_boxes(targets)
          img = windower.boxed_image
          img.write "#{@tables_folder}/#{forest}_#{img.columns}x#{img.rows}_box.jpg"
          
          puts "original size: #{img.base_columns}x#{img.base_rows}"
          # save resulting matches in original image somehow...
          
          # printer = RubyProf::FlatPrinter.new(result)
          # printer.print(File.new("result.txt","w"))
          # printer = RubyProf::GraphHtmlPrinter.new(result)
          # printer.print(File.new("result.html","w"))
          
        end
      # end #TODO: get this back up
      break  #!!!!!!!!!!!!
    end

    
  end
  
  desc "link up the tasks and run this thing"
  task :samples => [:set_options, :load_images, :check_trees, :resize, :create_pyramid, :classify]
  
end