# config.ru

require 'rubygems'
require 'bundler/setup'
env = ENV['RACK_ENV'] || 'development'
Bundler.require(:default, env.to_sym)

require_relative 'lib/constants'
# pull in the helpers and controllers
Dir.glob(File.join(File.dirname(__FILE__), 'app/{helpers,controllers}/*.rb')).each { |file| require file }

# map the controllers to routes
Constants::ROUTES.each do |route|
  map(route[:path]) { run route[:controller] }
end

set :default_content_type, :json

set :public_folder, ApplicationController.site_dir

enable :static
