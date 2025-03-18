# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/helpers/application_helper'

RSpec.describe ApplicationHelper do
  let(:helper_instance) do
    Class.new do
      include ApplicationHelper
    end.new
  end

  describe '#log' do
    it 'outputs a timestamped message' do
      expect { helper_instance.log('test message') }.to output(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} - test message/).to_stdout
    end
  end

  describe '#rack_env' do
    context 'when RACK_ENV is set' do
      before { ENV['RACK_ENV'] = 'test' }
      after { ENV['RACK_ENV'] = nil }

      it 'returns the environment variable value' do
        expect(helper_instance.rack_env).to eq('test')
      end
    end

    context 'when RACK_ENV is not set' do
      before { ENV['RACK_ENV'] = nil }

      it 'returns development as default' do
        expect(helper_instance.rack_env).to eq('development')
      end
    end
  end

  describe '#production?' do
    context 'when in production environment' do
      before { allow(helper_instance).to receive(:rack_env).and_return('production') }

      it 'returns true' do
        expect(helper_instance.production?).to be true
      end
    end

    context 'when not in production environment' do
      before { allow(helper_instance).to receive(:rack_env).and_return('development') }

      it 'returns false' do
        expect(helper_instance.production?).to be false
      end
    end
  end

  describe '#site_dir' do
    context 'when in production environment' do
      before { allow(helper_instance).to receive(:production?).and_return(true) }

      it 'returns the production path' do
        expect(helper_instance.site_dir).to eq('/var/www/html')
      end
    end

    context 'when not in production environment' do
      before { allow(helper_instance).to receive(:production?).and_return(false) }

      it 'returns the development path' do
        expected_path = File.expand_path('../../../../../tmp/html', __dir__)
        expect(helper_instance.site_dir).to eq(expected_path)
      end
    end
  end

  describe '#data_dir' do
    it 'returns a data directory inside the site directory' do
      allow(helper_instance).to receive(:site_dir).and_return('/test/site')
      expect(helper_instance.data_dir).to eq('/test/site/data')
    end
  end
end
