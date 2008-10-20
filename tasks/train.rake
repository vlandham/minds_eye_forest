namespace :train do
  
  desc "Chains the processing steps together to create a dataset from folders of images and train the RF"
  task :rf => [:set_options, 'common:save_images', :run_r]
  
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/train.yml")[GROUP]
    throw "Error: no samples folder" unless CONFIG["samples"]
    @samples = CONFIG["samples"]
    throw "Error: no forests folder" unless CONFIG["forests"]  
    @forests_folder = CONFIG['forests']
    # create directory for the training datasets
    throw "Error: no temp folder" unless CONFIG["images"]
    @images_folder = CONFIG['images']
    puts "removing #{@temp_folder}"
    rm_rf(@images_folder)
    puts "creating directory structure for : #{@temp_folder}"
    mkdir_p @images_folder
    # samples is a hash with folder/name => classification_type
    throw "Error: no script folder given" unless CONFIG["script"] and File.directory?(CONFIG["script"])
    @script_folder = CONFIG['script']
    @type_folder = CONFIG['types'] || @script_folder
    
  end
  
  desc "Runs the R script, passing in the necessary variables"
  task :run_r => 'common:save_images' do
   script_name = "#{@script_folder}/#{GROUP}_train.R"
   puts "Creating script: #{script_name}"
   trees = CONFIG['trees'] || "100"
   helper_script = File.expand_path(File.dirname(__FILE__)+"/../R/train.R")
   full_images_folder = File.expand_path(File.dirname(__FILE__)+"/../"+@images_folder)
   forest_group_full_path = File.expand_path(@forests_folder)

   script = RScriptMaker.new(script_name)
   script.assign("images_folder", "\'#{full_images_folder}\'")
   script.assign("forests_folder", "\'#{forest_group_full_path}\'")
   script.assign("r_directory", "\'#{File.expand_path(File.dirname(__FILE__)+"/../R/")}\'")
   script.assign("types", "\'#{@type_file}\'")
   script.run(helper_script)
   script.quit
   script.close
   puts "Executing script: #{script.name}..."
   script.execute 
  end
  
  # desc "write the R script to train with this dataset"
  # task :run_r_script => 'common:create_tables' do
    # script_folder = CONFIG['script'] || "scripts"
    # tree_folder = CONFIG['forest'] || "forests"
    # forest_name = CONFIG['name'] || GROUP
    # puts "Creating script folder if necessary: #{script_folder}"
    # mkdir_p script_folder
    # mkdir_p tree_folder
    # @script_name = "#{script_folder}/#{forest_name}_train.R"
    # puts "Creating script: #{@script_name}"
    
    # if # of tress or # of attributes to look at are given, set that up here.
    # tree_string = CONFIG['trees'] ? ", ntree=#{CONFIG['trees']}" :  ", ntree=100"
    # tries_string = CONFIG['tries'] ? ", mtry=#{CONFIG['tries']}" : ""
    
    # training_name = "training_set"
    # class_name = "class_set"
    # factor_name = "#{class_name}+_factor"
    # output_name = "result"
    # output_file = "#{@tables_folder}/#{forest_name}_output.txt"
    # 
    # 
    # script = RScriptMaker.new(@script_name)
    # script.library "randomForest"
    # script.load_matrix(training_name,@data_set_name,@rows,@cols)
    # script.load_vector(class_name,@class_set_name,@rows)
    # script.assign(factor_name,"factor(#{class_name})")
    # script.assign("#{forest_name}_rf", "randomForest(#{training_name}, #{factor_name}#{tree_string}#{tries_string})")
    # script.save("#{forest_name}_rf", "#{tree_folder}/#{forest_name}.rf")
    # script.quit
    # script.close
    # 
    # puts "Running script"
    # script.execute
    
    # Create the R script for this traingset / RF
    # script_file = File.open(@script_name, 'w') do |file|
      # file << "library(\'randomForest\')\n"
      # file << "training_set = matrix(scan(\'#{File.expand_path(@data_set_name)}\', n=#{@rows*@cols}),"
      # file << " #{@rows}, #{@cols}, byrow = TRUE)\n"
      # file << "class_set = matrix(scan(file=\'#{File.expand_path(@class_set_name)}\', what=\"\", n=#{@rows}),"
      # file << " #{@rows}, 1, byrow = TRUE)\n"
      # file << "class_set_factor <- factor(class_set)\n"
      # file << "#{tree_name}_rf <- randomForest(training_set, class_set_factor#{tree_string}#{tries_string})\n"
      # file << "save(#{tree_name}_rf, file=\'#{File.expand_path(tree_folder)}/#{tree_name}.rf\')\n"
      # file << "q(save = \"no\")\n"
    # end
  # end
  
  
end