# application_controller.rb

require 'sinatra/base'
require 'sinatra/json'
require 'json'

require_relative '../helpers/application_helper'

# Base Controller for Sinatra API Application
class ApplicationController < Sinatra::Base
  include ApplicationHelper

  before do
    content_type :json
    # OAuth2 proxy will handle authentication
  end

  # don't enable logging when running tests
  configure :production, :development do
    enable :logging
  end
end
