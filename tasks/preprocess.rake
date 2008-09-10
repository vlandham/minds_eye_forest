namespace :pre do
  desc "Sets where the folder of images to preprocess is, destination and preprocessing requirements"
  task :set_options do
    CONFIG = YAML.load_file("#{File.dirname(__FILE__)/config/preprocess.yml}")
    throw "Error: no input folder" unless CONFIG["source_dir"]
    throw "Error: no output folder" unless CONFIG["output_dir"]
  end
end