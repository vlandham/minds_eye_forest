namespace :test do
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    puts "Reading configuration for #{GROUP}"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/test.yml")[GROUP]
    throw "Error: no samples folder" unless CONFIG["samples"]  
    # create directory for the training datasets
    puts "creating directory structure for : #{CONFIG['tables']}"
    mkdir_p CONFIG['tables']
    # samples is a hash with folder/name => classification_type
    @samples = CONFIG["samples"]
  end
  
  
  desc "Set a set of images against a trained random forest"
  task :rf => [:set_options, "train:create_tables", :write_r_script, :test]
  
  desc "Write R script to test a random forest"
  task :write_r_script => "train:create_tables" do
    
  end
  
  desc "Execute testing"
  task :test => :write_r_script do
    
  end
  
  
end