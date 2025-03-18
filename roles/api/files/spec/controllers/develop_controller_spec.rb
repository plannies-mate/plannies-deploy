# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack/test'
require_relative '../../app/controllers/develop_controller'

RSpec.describe DevelopController do
  include Rack::Test::Methods

  def app
    DevelopController
  end

  before do
    # Set the host header for requests
    header 'HOST', '127.0.0.1'
  end

  describe 'GET /' do
    it 'returns HTML content' do
      get '/'

      expect(last_response).to be_ok
      expect(last_response.content_type).to include('text/html')
      expect(last_response.body).to include('API Endpoints')
      expect(last_response.body).to include('GET Endpoints')
      expect(last_response.body).to include('POST Endpoints')
    end
  end

  describe 'GET /debug' do
    before do
      allow(DevelopController).to receive(:load_status).and_return({ 'status' => 'test' })
    end

    it 'returns debug information' do
      get '/debug'

      expect(last_response).to be_ok
      json_response = JSON.parse(last_response.body)
      expect(json_response).to include('env', 'status', 'roundup_request_file', 'roundup_request_file_exists', 'roundup_status_file')
      expect(json_response['status']).to eq({ 'status' => 'test' })
    end
  end

  describe 'GET /*' do
    context 'when the file exists' do
      before do
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:directory?).and_return(false)
        allow_any_instance_of(DevelopController).to receive(:send_file)
      end

      it 'sets the appropriate content type and sends the file' do
        expect_any_instance_of(DevelopController).to receive(:send_file)
                                                       .with("#{described_class.site_dir}/test_path.html")

        get '/test_path.html'
        expect(last_response).to be_ok
      end

      it 'sets the appropriate content type for JS files' do
        allow(File).to receive(:extname).and_return('.js')

        allow_any_instance_of(DevelopController).to receive(:content_type)
        expect_any_instance_of(DevelopController).to receive(:content_type).with('application/javascript').at_least(:once)

        expect_any_instance_of(DevelopController).to receive(:send_file)
        get '/test.js'
      end

      it 'sets the appropriate content type for CSS files' do
        allow(File).to receive(:extname).and_return('.css')

        allow_any_instance_of(DevelopController).to receive(:content_type)
        expect_any_instance_of(DevelopController).to receive(:content_type).with('text/css').at_least(:once)

        expect_any_instance_of(DevelopController).to receive(:send_file)
        get '/test.css'
      end
    end

    context 'when the file does not exist' do
      before do
        allow(File).to receive(:exist?).and_return(false)
        allow_any_instance_of(DevelopController).to receive(:set_content_type)
      end

      it 'returns a 404 error' do
        get '/nonexistent'

        expect(last_response.status).to eq(404)
        expect(last_response.body).to include('File not found: nonexistent')
      end
    end
  end
end
