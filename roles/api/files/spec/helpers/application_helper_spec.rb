# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/helpers/application_helper'

RSpec.describe ApplicationHelper do
  let(:class_with_helper) do
    Class.new do
      extend ApplicationHelper
    end
  end

  describe '#log' do
    it 'outputs a timestamped message' do
      expect { class_with_helper.log('test message') }.to output(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} - test message/).to_stdout
    end
  end

  describe '#rack_env' do
    context 'when RACK_ENV is set' do
      before { ENV['RACK_ENV'] = 'test' }

      it 'returns the environment variable value' do
        expect(class_with_helper.rack_env).to eq('test')
      end
    end

    context 'when RACK_ENV is not set' do
      before { ENV['RACK_ENV'] = nil }
      after { ENV['RACK_ENV'] = 'test' }

      it 'returns development as default' do
        expect(class_with_helper.rack_env).to eq('development')
      end
    end
  end

  describe '#production?' do
    context 'when in production environment' do
      before { ENV['RACK_ENV'] = 'production' }
      after { ENV['RACK_ENV'] = 'test' }

      it 'returns true' do
        expect(class_with_helper.production?).to be true
      end
    end

    context 'when not in production environment' do
      before { ENV['RACK_ENV'] = nil }
      after { ENV['RACK_ENV'] = 'test' }

      it 'returns false' do
        expect(class_with_helper.production?).to be false
      end
    end
  end

  describe '#site_dir' do
    context 'when in production environment' do
      before { ENV['RACK_ENV'] = 'test' }
      it 'returns the test path' do
        expected_path = File.expand_path('../../../../../tmp/html-test', __dir__)
        expect(class_with_helper.site_dir).to eq(expected_path)
      end
    end

    context 'when in production environment' do
      before { ENV['RACK_ENV'] = 'production' }
      after { ENV['RACK_ENV'] = 'test' }

      it 'returns the production path' do
        expect(class_with_helper.site_dir).to eq('/var/www/html')
      end
    end

    context 'when in development environment' do
      before { ENV['RACK_ENV'] = nil }
      after { ENV['RACK_ENV'] = 'test' }

      it 'returns the development path' do
        expected_path = File.expand_path('../../../../../tmp/html', __dir__)
        expect(class_with_helper.site_dir).to eq(expected_path)
      end
    end
  end

  describe '#data_dir' do
    it 'returns a data directory inside the site directory' do
      allow(class_with_helper).to receive(:site_dir).and_return('/test/site')
      expect(class_with_helper.data_dir).to eq('/test/site/data')
    end
  end
end
