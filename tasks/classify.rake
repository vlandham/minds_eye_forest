namespace :classify do
  desc "Sets where the folder of images to classify is, and where the random forests are."
  task :set_options do
    puts "Reading configuration for classify"
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../config/classify.yml")
    throw "Error: no sample folder" unless CONFIG["images"]
    # create directory for the training datasets
    throw "Error: no tables folder" unless CONFIG["tables"]
    puts "creating directory structure for : #{CONFIG['tables']}"
    mkdir_p CONFIG['tables']
    @tables_folder = CONFIG['tables']
    # samples is just a filename for now - should make it a list, or better, recurse through
    @sample_folder = CONFIG['samples']
    
    # Now we need to load those forests.  We'll have the forests option be an array of forests
    throw "Error: no forests present" unless CONFIG['forests']
    @forests = CONFIG['forests']
    @forests.each {|fr| puts "Using forest: #{fr}.rf"}
    
    # Lets also get that scripts folder going for us
    throw "Error: no scripts folder" unless CONFIG['script']
    @scripts_folder = CONFIG['script']
    mkdir_p @scripts_folder
  end
  
end