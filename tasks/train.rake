namespace :train do
  
  desc "Chains the processing steps together to create a dataset from folders of images and train the RF"
  task :rf => [:set_options, 'common:create_tables', :run_r_script]
  
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/train.yml")[GROUP]
    throw "Error: no samples folder" unless CONFIG["samples"]  
    # create directory for the training datasets
    throw "Error: no tables folder" unless CONFIG["tables"]
    puts "creating directory structure for : #{CONFIG['tables']}"
    mkdir_p CONFIG['tables']
    # samples is a hash with folder/name => classification_type
    @samples = CONFIG["samples"]
  end
  
  desc "write the R script to train with this dataset"
  task :run_r_script => 'common:create_tables' do
    script_folder = CONFIG['script'] || "scripts"
    tree_folder = CONFIG['forest'] || "forests"
    forest_name = CONFIG['name'] || GROUP
    puts "Creating script folder if necessary: #{script_folder}"
    mkdir_p script_folder
    mkdir_p tree_folder
    @script_name = "#{script_folder}/#{forest_name}_train.R"
    puts "Creating script: #{@script_name}"
    
    # if # of tress or # of attributes to look at are given, set that up here.
    tree_string = CONFIG['trees'] ? ", ntree=#{CONFIG['trees']}" :  ", ntree=100"
    tries_string = CONFIG['tries'] ? ", mtry=#{CONFIG['tries']}" : ""
    
    training_name = "training_set"
    class_name = "class_set"
    factor_name = "#{class_name}+_factor"
    output_name = "result"
    output_file = "#{@tables_folder}/#{forest_name}_output.txt"
    
    
    script = RScriptMaker.new(@script_name)
    script.library "randomForest"
    script.load_matrix(training_name,@data_set_name,@rows,@cols)
    script.load_vector(class_name,@class_set_name,@rows)
    script.assign(factor_name,"factor(#{class_name})")
    script.assign("#{forest_name}_rf", "randomForest(#{training_name}, #{factor_name}#{tree_string}#{tries_string})")
    script.save("#{forest_name}_rf", "#{tree_folder}/#{forest_name}.rf")
    script.quit
    script.close
    
    puts "Running script"
    script.execute
    
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
  end
  
  
end