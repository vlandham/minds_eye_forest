namespace :test do
  
  desc "Set a set of images against a trained random forest"
  task :rf => [:set_options, "common:create_tables", :write_r_script]
  
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/test.yml")[GROUP]
    throw "Error: no samples folder" unless CONFIG["samples"]  
    throw "Error: no forest folder" unless CONFIG["forest"]  
    # create directory for the training datasets
    throw "Error: no tables folder" unless CONFIG["tables"]
    puts "creating directory structure for : #{CONFIG['tables']}"
    mkdir_p CONFIG['tables']
    # samples is a hash with folder/name => classification_type
    @samples = CONFIG["samples"]
  end
  
  desc "Write R script to test a random forest"
  task :write_r_script => "common:create_tables" do
    script_folder = CONFIG['script'] || "scripts"
    tree_folder = CONFIG['forest']
    
    tree_name = CONFIG['name'] || GROUP
    puts "Creating script folder if necessary: #{script_folder}"
    mkdir_p script_folder
    @script_name = "#{script_folder}/#{tree_name}_test.R"
    puts "Creating script: #{@script_name}"
    
    puts "#{File.expand_path(tree_folder)} --"
    # Create the R script for this traingset / RF
    
    forest_file_name = "#{tree_folder}/#{tree_name}.rf"
    set_name = 'testing_set'
    output_name = 'predictions'
    output_file = "#{File.expand_path(script_folder)}/#{tree_name}_preditions.txt"
    
    script = RScriptMaker.new(@script_name)
    script.library 'randomForest'
    script.load_matrix(set_name, @data_set_name, @rows,@cols)
    script.load forest_file_name
    script.command "#{output_name} <- predict(#{tree_name}_rf, #{set_name})"
    script.save_matrix(output_name,output_file)
    script.close
    
    script.execute
    # script_file = File.open(@script_name, 'w') do |file|
    #   file << "library(\'randomForest\')\n"
    #   file << "testing_set = matrix(scan(\'#{File.expand_path(@data_set_name)}\', n=#{@rows*@cols}),"
    #   file << " #{@rows}, #{@cols}, byrow = TRUE)\n"
    #   file << "load(file=\'#{File.expand_path(tree_folder)}/#{tree_name}.rf\')\n"
    #   file << "predictions <- predict(#{tree_name}_rf, testing_set)\n"
    #   file << "write.table(predictions, file=\"#{File.expand_path(script_folder)}/#{tree_name}_preditions.txt\" )\n"
    # end
  end
  
  
end