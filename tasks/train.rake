namespace :train do
  
  desc "Chains the processing steps together to create a dataset from folders of images and train the RF"
  task :rf => [:set_options, 'common:create_tables', :write_r_script, :train]
  
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
  task :write_r_script => 'common:create_tables' do
    script_folder = CONFIG['script'] || "scripts"
    tree_folder = CONFIG['forest'] || "forests"
    tree_name = CONFIG['name'] || GROUP
    puts "Creating script folder if necessary: #{script_folder}"
    mkdir_p script_folder
    mkdir_p tree_folder
    @script_name = "#{script_folder}/#{tree_name}_train.R"
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