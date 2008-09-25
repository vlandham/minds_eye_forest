require 'rubygems'
require 'yaml'
require 'RMagick'
include Magick


Dir["#{File.dirname(__FILE__)}/lib/*.rb"].each do |file|
  require file
end

GROUP = 'head1'
Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each do |file|
  load file
end

