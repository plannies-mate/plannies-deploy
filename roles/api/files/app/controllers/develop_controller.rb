# frozen_string_literal: true

require_relative 'application_controller'
require_relative '../helpers/status_helper'

# Development / debug endpoints not visible from outside
class DevelopController < ApplicationController
  extend StatusHelper

  # We're already using Sinatra::JSON from contrib
  register Sinatra::Contrib

  get '/' do
    root_page
  end

  get '/debug' do
    content_type :json
    json(
      env: ENV['RACK_ENV'],
      roundup_status_file: self.class.roundup_status_file,
      roundup_request_file: self.class.roundup_request_file,
      roundup_request_file_exists: File.exist?(self.class.roundup_request_file),
      status: self.class.load_status
    )
  end

  get '/*' do
    # puts "AAAA, #{params.inspect}"
    # Only used in production where we want to serve through the application
    # Or for development paths not automatically mapped to static files
    path = params[:splat].first
    file_path = File.join(self.class.site_dir, path)

    try_paths = %W[#{file_path}
                  #{file_path}.html
                  #{file_path}/index.html
                  #{file_path}.default.html
                  #{file_path}/default.html
    ]
    try_path = try_paths.find { |p| File.exist?(p) && !File.directory?(p) } unless self.class.production?
    if try_path
      set_content_type(try_path)
      send_file try_path
    else
      set_content_type('.txt')
      halt 404, "File not found: #{path}"
    end
  end

  private

  def root_page
    content_type :html

    method_routes = {}
    %w[GET POST].map do |http_method|
      routes = []
      Constants::ROUTES.each do |route|
        routes << route[:controller].routes[http_method]&.map do |r|
          "#{route[:path]}#{r[0]}".sub(%r{\A/+}, '/').sub(%r{(?!^)/\z}, '')
        end
      end
      method_routes[http_method] = routes.flatten.compact.sort
    end
    method_routes['GET'] << '/index.html'
    method_routes['GET'] << '/authorities'
    method_routes['GET'] << '/crikey-whats-that'
    method_routes['GET'] << '/scrapers'
    method_routes['GET'] << '/repos'
    method_routes['GET'] << '/robots.txt'
    layout('API Endpoints') do
      get_list_entry(method_routes['GET']) +
        post_list_entry(method_routes['POST'])
    end
  end

  def set_content_type(filename)
    value = case File.extname(filename).downcase
            when '.html' then 'text/html'
            when '.js' then 'application/javascript'
            when '.css' then 'text/css'
            when '.ico' then 'image/x-icon'
            when '.json' then 'application/json'
            when '.png' then 'image/png'
            when '.txt' then 'text/plain'
            else filename
            end
    content_type(value)
    value
  end

  def get_list_entry(get_paths)
    get_li = '<li><span class="endpoint get-endpoint">'
    end_li = '</span></li>'
    get_list = get_paths.map { |path| "#{get_li}<a href=\"#{path}\">#{path}</a>#{end_li}" }

    <<~HTML
      <h2>GET Endpoints</h2>
      <ul>
        #{get_list.join("\n")}
      </ul>
    HTML
  end

  def post_list_entry(post_paths)
    post_li = '<li><span class="endpoint post-endpoint">'
    end_li = '</span></li>'
    post_list = post_paths.map do |path|
      # "#{post_li}#{path} <form action=\"#{path}\" method=\"post\"><input type=\"submit\"></input></form>#{end_li}"
      "#{post_li}<form action=\"#{path}\" method=\"post\"><button>#{path}</button></form>#{end_li}"
    end

    <<~HTML
      <h2>POST Endpoints</h2>
      <ul>
        #{post_list.join("\n")}
      </ul>
    HTML
  end

  def layout(title)
    <<~HTML
            <!DOCTYPE html>
            <html>
            <head>
              <title>#{title}</title>
              <style>
                body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
                h1 { color: #0066cc; }
                h2 { color: #444; margin-top: 20px; }
                ul { list-style-type: none; padding: 0; }
                li { padding: 8px 0; border-bottom: 1px solid #eee; }
                li:last-child { border-bottom: none; }
                .endpoint { font-family: monospace; font-size: 1.1em; display: block; padding: 5px; }
                .get-endpoint { color: #0066cc; background: #f0f8ff; }
                .post-endpoint { color: #008800; background: #f0fff0; }
              </style>
            </head>
            <body>
              <h1>#{title}</h1>
              #{yield}
            </body>
      </html>
    HTML
  end
end
