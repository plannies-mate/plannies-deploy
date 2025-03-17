# frozen_string_literal: true

# develop_controller.rb

require_relative 'application_controller'

# Development / debug endpoints not visible from outside
class DevelopController < ApplicationController
  include StatusHelper

  # We're already using Sinatra::JSON from contrib
  register Sinatra::Contrib

  get '/' do
    root_page
  end

  get '/debug' do
    halt 403, json(error: 'Debug endpoint disabled in production') if production?

    json(
      env: ENV['RACK_ENV'],
      roundup_status_file: STATUS_FILE,
      trigger_file: TRIGGER_FILE,
      trigger_exists: File.exist?(TRIGGER_FILE),
      status: load_status
    )
  end

  get '/*' do
    puts "AAAA, #{params.inspect}"
    # Only used in production where we want to serve through the application
    # Or for development paths not automatically mapped to static files
    path = params[:splat].first
    file_path = File.join(site_dir, path)

    puts "FILE_PATH: #{file_path}"

    try_path = %W[#{file_path}
                  #{file_path}.html
                  #{file_path}/index.html
                  #{file_path}.default.html
                  #{file_path}/default.html
      ].find { |p| File.exist?(p) && !File.directory?(p) }
    if try_path
      puts "try_path: #{try_path}"
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
      ROUTES.each do |route|
        routes << route[:controller].routes[http_method]&.map do |r|
          "#{route[:path]}#{r[0]}".sub(%r{\A/+}, '/').sub(%r{(?!^)/\z}, '')
        end
      end
      method_routes[http_method] = routes.flatten.compact.sort
    end
    method_routes['GET'] << '/robots.txt'
    method_routes['GET'] << '/whats_that/'
    method_routes['GET'] << '/whats_that/index.html'
    layout('API Endpoints') do
      get_list_entry(method_routes['GET']) +
        post_list_entry(method_routes['POST'])
    end
  end

  def set_content_type(filename)
    case File.extname(filename).downcase
    when '.html' then content_type 'text/html'
    when '.js' then content_type 'application/javascript'
    when '.css' then content_type 'text/css'
    when '.ico' then content_type 'image/x-icon'
    when '.json' then content_type 'application/json'
    when '.png' then content_type 'image/png'
    when '.txt' then content_type 'text/plain'
    else content_type 'application/octet-stream' # Default binary content type
    end
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
