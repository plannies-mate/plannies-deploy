# config.ru

require 'rubygems'
require 'bundler/setup'
env = ENV['RACK_ENV'] || 'development'
Bundler.require(:default, env.to_sym)

# pull in the helpers and controllers
Dir.glob(File.join(File.dirname(__FILE__), 'app/{helpers,controllers}/*.rb')).each { |file| require file }

ROUTES = [
  { path: '/api/health', controller: HealthController },
  { path: '/api/analyze', controller: AnalyzeController },
  { path: '/', controller: DevelopController }
].freeze

# map the controllers to routes
ROUTES.each do |route|
  map(route[:path]) { run route[:controller] }
end
