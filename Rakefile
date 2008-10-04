require 'rubygems'
require 'yaml'
require 'RMagick'
include Magick

GROUP = 'head'

Dir["#{File.dirname(__FILE__)}/lib/*.rb"].each do |file|
  require file
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each do |file|
  load file
end

