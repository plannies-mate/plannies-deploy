# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack/test'
require_relative '../../app/controllers/health_controller'

RSpec.describe HealthController do
  include Rack::Test::Methods

  def app
    HealthController
  end

  let(:time_now) { Time.new(2025, 3, 15, 12, 0, 0) }

  before do
    allow(Time).to receive(:now).and_return(time_now)

    # Set the host header for requests
    header 'HOST', '127.0.0.1'
  end

  describe 'GET /' do
    before do
      # Stub the StatusHelper methods that are now class methods due to extend
      allow(HealthController).to receive(:load_status).and_return(status)
    end

    context 'when scraper has never run' do
      let(:status) { { 'last_roundup' => nil } }

      it 'returns a warning status' do
        get '/'

        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response['status']).to eq('warning')
        expect(json_response['message']).to eq('Scraper has never run')
        expect(json_response['time']).to eq(time_now.iso8601)
      end
    end

    context 'when scraper ran recently' do
      let(:status) { { 'last_roundup' => (time_now - 3600).iso8601 } }

      it 'returns an ok status' do
        get '/'

        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response['status']).to eq('ok')
        expect(json_response['message']).to eq('API is operational')
        expect(json_response['time']).to eq(time_now.iso8601)
      end
    end

    context 'when scraper data is stale' do
      let(:status) { { 'last_roundup' => (time_now - 26 * 3600).iso8601 } }

      it 'returns a warning status' do
        get '/'

        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response['status']).to eq('warning')
        expect(json_response['message']).to eq('Scraper data is stale (not run in past 25 hours)')
        expect(json_response['time']).to eq(time_now.iso8601)
      end
    end

    context 'when last_roundup has an invalid format' do
      let(:status) { { 'last_roundup' => 'invalid-date' } }

      it 'handles the error and returns a warning' do
        get '/'

        expect(last_response).to be_ok
        json_response = JSON.parse(last_response.body)
        expect(json_response['status']).to eq('warning')
        expect(json_response['message']).to eq('Scraper has invalid run time')
      end
    end
  end
end
