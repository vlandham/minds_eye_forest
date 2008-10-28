namespace :classify do
  
  desc "Sets where the folder of images to classify is, and where the random forests are."
  task :set_options do
    puts "Reading configuration for classify"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/classify.yml")
    
    throw "Error: no results folder" unless CONFIG["results"]
    puts "creating directory structure for : #{CONFIG['results']}"
    mkdir_p CONFIG['results']
    @results_folder = File.expand_path(CONFIG['results'])
    
    # samples is just a filename for now - should make it a list, or better, recurse through
    throw "Error: no sample folder" unless CONFIG["samples"]
    @sample_folder = CONFIG['samples']

    # Lets also get that scripts folder going for us
    throw "Error: no scripts folder" unless CONFIG['script']
    @scripts_folder = CONFIG['script']
    puts "creating directory structure for scripts: #{@scripts_folder}"
    mkdir_p @scripts_folder
    
    throw "Error: no temp directory" unless CONFIG['temp']
    @temp_folder = CONFIG['temp']
    
  end
  
  desc "loads images from samples folder"
  task :load_images do
    require 'RMagick'
    include Magick
    if File.directory?(@sample_folder)
      puts "Loading images from #{@sample_folder}"
      photo_files = FileList["#{@sample_folder}/*.jpg","#{@sample_folder}/*.png","#{@sample_folder}/*.JPG"]
      @original_images = ImageList.new(*photo_files)
    else
      puts "Error: not a valid input folder - #{@sample_folder}"
    end 
    puts "loaded #{@original_images.size} images"
  end
  
  desc "gets the names of the trees to be used and ensures that they are all valid"
  task :check_trees => :set_options do
    throw "Error: no forests present" unless CONFIG['forests']
    
    puts "reading in preprocessing data"
    training_config = YAML.load_file("#{File.dirname(__FILE__)}/../config/preprocess.yml")
    @sizes = Hash.new
    @forest_groups = CONFIG['forests']  
    @forest_groups.each do |fr|
      if File.exists?("#{fr}") && File.directory?("#{fr}")
        puts "Using forest directory: #{fr}"
        rf_name = fr.split("/")[-1]
        throw "Error: now size for #{rf_name} " unless training_config[rf_name]['size']
        @sizes[rf_name] = training_config[rf_name]['size']
        
        puts "size for #{rf_name}: #{@sizes[rf_name]['w']}x#{@sizes[rf_name]['h']}"
      else
        throw "Error: #{fr} not a present or not a folder"
      end
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
    @original_images.each do |im| 
      im.destroy!
    end  
    @original_images = nil
  end
  
  
  desc ""
  task :classify => [:create_pyramid, :check_trees ] do
    base_image_name = "%010d.jpg"
    helper_script = File.expand_path(File.dirname(__FILE__)+"/../R/classify.R")
    # results_file = "#{@results_folder}/#{GROUP}.txt"
    @results = ClassificationResults.new
    @pyramids.each do |filename, img_array|
      image_result = ImageResult.new(filename)
      puts "analyzing #{filename}"
      while img_array.size > 0
        img = img_array.shift   
        @forest_groups.each do |full_forest_group|
          forest_group = full_forest_group.split('/')[-1]
          puts "working with forest group #{forest_group}"
          window_cols = @sizes[forest_group]['w']
          window_rows = @sizes[forest_group]['h']
          window_step = CONFIG['window'] || 10
          puts "Windowing #{img.filename} - #{img.columns}x#{img.rows}"
          windower = ImageWindower.new(img, window_cols, window_rows, window_step)
          # save to temp directory
          puts "removing #{@temp_folder}"
          rm_rf(@temp_folder)
          puts "Saving to #{@temp_folder}"
          mkdir_p @temp_folder
          image_name = "#{@temp_folder}/#{base_image_name}"
          windower.write(image_name)
          result_image_name = img.filename.split("/")[-1].split(".")[0]

          # run r script       
          full_temp_folder = File.expand_path(File.dirname(__FILE__)+"/../"+@temp_folder)
          forest_group_full_path = File.expand_path(full_forest_group)

          script = RScriptMaker.new("#{@scripts_folder}/#{forest_group}_classify.R")
          script.assign("images_folder", "\'#{full_temp_folder}\'")
          script.assign("forests_folder", "\'#{forest_group_full_path}\'")
          script.assign("results_folder", "\'#{@results_folder}\'")
          script.assign("r_directory", "\'#{File.expand_path(File.dirname(__FILE__)+"/../R/")}\'")
          script.run(helper_script)
          script.quit
          script.close
          puts "Executing script: #{script.name}..."
          threads = []
          threads << Thread.new {GC.start}
          threads << Thread.new {script.execute}
          threads.each  {|t| t.join }
          # get results
          puts "Reading results"
          r_reader = ResultReader.new(@results_folder)
          targets = r_reader.positives
          windower.add_boxes(targets)
          b_img = windower.boxed_image
          b_img.write "#{@results_folder}/#{result_image_name}_#{b_img.columns}x#{b_img.rows}_#{GROUP}.jpg"
          b_img.destroy!
          img.destroy!
          # store results
        end
      end
    end
  end
    
  # desc ""
  # task :classify => [:create_pyramid, :check_trees ] do
  #   # MemoryProfiler.start
  #   # require 'ruby-prof'
  #   # RubyProf.measure_mode = RubyProf:::MEMORY
  #   # RubyProf.start
  #   @results = ClassificationResults.new
  #   @pyramids.each do |filename, img_array|
  #     image_result = ImageResult.new(filename)
  #     while img_array.size > 0
  #       img = img_array.shift
  #       @forests.each do |full_forest|
  #         forest = full_forest.split("/")[-1]
  #         table_name = "#{@tables_folder}/#{forest}_classify.dat"
  #         window_cols = @sizes[full_forest][x]
  #         window_rows = @sizes[full_forest][y]
  #         window_step = CONFIG['window'] || 10
  #         puts "Windowing #{img.filename} - #{img.columns}x#{img.rows}"
  #         windower = ImageWindower.new(img, window_cols, window_rows, window_step)
  #         
  #         puts "Creating table: #{table_name}"
  #         # RubyProf.start
  #         rows, cols = windower.create_table(table_name)
  #         # result = RubyProf.stop
  #         puts "Table created with #{rows} rows and #{cols} columns"
  #         # windower.write("#{File.dirname(__FILE__)}/../test/windows/window.jpg")
  #         
  #         puts "Writing R script for classification"
  #         matrix_name = "classify_set"
  #         output_name = "result"
  #         output_file = "#{@tables_folder}/#{forest}_output.txt"
  #         script = RScriptMaker.new("#{@scripts_folder}/#{forest}_classify.R")
  #         script.library "randomForest"
  #         script.load_matrix(matrix_name,table_name,rows,cols)
  #         script.load "#{full_forest}.rf"
  #         script.assign(output_name, "predict(#{forest}_rf, #{matrix_name})")
  #         # script.command "#{output_name} <- predict(#{forest}_rf, #{matrix_name})"
  #         script.save_matrix(output_name, output_file)
  #         script.quit
  #         script.close
  #         
  #         puts "Executing script: #{script.name}..."
  #         gc = Thread.new {GC.start}
  #         exe = Thread.new {  script.execute }
  #         gc.join
  #         exe.join
  #         puts "done"
  #         
  #         puts "Reading results"        
  #         r_reader = ResultReader.new(output_file)
  #         # r_reader.print
  #         
  #         targets = r_reader.positives
  # 
  #         # add boxes to matches in image
  #         windower.add_boxes(targets)
  #         img = windower.boxed_image
  #         img.write "#{@tables_folder}/#{filename.split("/")[-1].split(".")[0]}_#{img.columns}x#{img.rows}_#{forest}.jpg"
  #         
  #         image_result.add_target(forest,windower.get_scaled_boxes)
  #         
  #         puts "original size: #{img.base_columns}x#{img.base_rows}"
  #         
  #         windower = nil
  #         img.destroy!
  #         img = nil
  #         
  #         
  #         # printer = RubyProf::FlatPrinter.new(result)
  #         # printer.print(File.new("result.txt","w"))
  #         # printer = RubyProf::GraphHtmlPrinter.new(result)
  #         # printer.print(File.new("result.html","w"))
  #         
  #       end #each forest
  #     end 
  #     @results.add(image_result)
  #   end
  #   
  #   # result = RubyProf.stop
  #   # printer = RubyProf::FlatPrinter.new(result)
  #   # printer.print(File.new("memory.txt","w"))
  #   # printer = RubyProf::GraphHtmlPrinter.new(result)
  #   # printer.print(File.new("memory.html","w"))
  # end
  
  desc "link up the tasks and run this thing"
  task :samples => [:set_options, :load_images, :check_trees, :resize, :create_pyramid, :classify]
  
end