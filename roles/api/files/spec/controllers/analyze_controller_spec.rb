# frozen_string_literal: true

require_relative '../spec_helper'

require 'rack/test'
require_relative '../../app/controllers/analyze_controller'

RSpec.describe AnalyzeController do
  include Rack::Test::Methods

  def app
    AnalyzeController
  end

  before do
    # Set the host header for requests
    header 'HOST', '127.0.0.1'
  end

  let(:roundup_status_file) { '/tmp/test_status.json' }
  let(:roundup_request_file) { '/tmp/test_trigger' }

  before do
    allow(AnalyzeController).to receive(:roundup_status_file).and_return(roundup_status_file)
    allow(AnalyzeController).to receive(:roundup_request_file).and_return(roundup_request_file)

    # Clean up any existing files
    File.unlink(roundup_status_file) if File.exist?(roundup_status_file)
    File.unlink(roundup_request_file) if File.exist?(roundup_request_file)

    # Create the directory for files
    FileUtils.mkdir_p(File.dirname(roundup_status_file))
  end

  after do
    # Clean up
    File.unlink(roundup_status_file) if File.exist?(roundup_status_file)
    File.unlink(roundup_request_file) if File.exist?(roundup_request_file)
  end

  describe 'GET /' do
    let(:status) do
      {
        'last_roundup' => '2025-03-15T10:00:00Z',
        'github_check' => '2025-03-15T09:30:00Z',
        'morph_check' => '2025-03-15T09:45:00Z',
        'roundup_requested' => false
      }
    end

    before do
      allow(AnalyzeController).to receive(:load_status).and_return(status)
      allow(Time).to receive(:parse).and_return(Time.new(2025, 3, 15, 12, 0, 0))
    end

    it 'returns the status with time ago information' do
      get '/'

      expect(last_response).to be_ok
      json_response = JSON.parse(last_response.body)

      expect(json_response['last_roundup']).to eq('2025-03-15T10:00:00Z')
      expect(json_response).to include('last_roundup_ago')
      expect(json_response).to include('github_check_ago')
      expect(json_response).to include('morph_check_ago')
    end

    context 'with invalid time formats' do
      let(:status) do
        {
          'last_roundup' => 'invalid-time',
          'github_check' => nil,
          'morph_check' => nil,
          'status' => 'completed'
        }
      end

      it 'handles invalid time formats gracefully' do
        get '/'

        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)

        expect(json_response['last_roundup_ago']).to eq('unknown')
        expect(json_response['github_check_ago']).to eq('never')
        expect(json_response['morph_check_ago']).to eq('never')
      end
    end
  end

  describe 'POST /' do
    before do
      allow(AnalyzeController).to receive(:load_status).and_return({
                                                                     'status' => 'analyzed'
                                                                   })

      allow(AnalyzeController).to receive(:save_status)
    end

    it 'creates a trigger file and updates the status' do
      post '/'

      expect(last_response).to be_ok
      json_response = JSON.parse(last_response.body)

      expect(json_response['success']).to eq(true)
      expect(json_response['message']).to eq('Roundup requested')
      expect(File.exist?(roundup_request_file)).to be true

      # Verify that save_status was called with roundup_requested=true
      expected_status = { 'roundup_requested' => true, 'status' => 'pending' }
      expect(AnalyzeController).to have_received(:save_status).with(expected_status)
    end
  end
end
