# application_controller.rb

require 'sinatra/base'
require 'sinatra/json'
require 'json'

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
