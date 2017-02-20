$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require File.expand_path '../dallas.rb', __FILE__
run Sinatra::Application
