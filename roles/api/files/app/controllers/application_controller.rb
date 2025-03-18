# application_controller.rb

require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/contrib'
require 'json'

require_relative '../helpers/application_helper'

# Base Controller for Sinatra API Application
class ApplicationController < Sinatra::Base
  extend ApplicationHelper

  # don't enable logging when running tests
  configure :production, :development do
    enable :logging
  end
end
