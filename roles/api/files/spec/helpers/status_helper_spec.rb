# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/helpers/status_helper'

RSpec.describe StatusHelper do
  let(:class_with_helper) do
    Class.new do
      extend ApplicationHelper
      extend StatusHelper
    end
  end

  let(:data_dir) { '/tmp/test_data_dir' }
  let(:status_file) { File.join(data_dir, 'roundup_status.json') }
  let(:request_file) { File.join(data_dir, 'roundup_request.dat') }

  before do
    allow(class_with_helper).to receive(:data_dir).and_return(data_dir)
    FileUtils.mkdir_p(data_dir)
  end

  after do
    FileUtils.rm_rf(data_dir)
  end

  describe '#roundup_status_file' do
    it 'returns the path to the status file' do
      expect(class_with_helper.roundup_status_file).to eq(status_file)
    end
  end

  describe '#roundup_request_file' do
    it 'returns the path to the request file' do
      expect(class_with_helper.roundup_request_file).to eq(request_file)
    end
  end

  describe '#roundup_requested?' do
    context 'when request file exists' do
      before do
        FileUtils.touch(request_file)
      end

      it 'returns true' do
        expect(class_with_helper.roundup_requested?).to be true
      end
    end

    context 'when request file does not exist' do
      it 'returns false' do
        expect(class_with_helper.roundup_requested?).to be false
      end
    end
  end

  describe '#roundup_requested=' do
    context 'when set to true' do
      it 'creates the request file with timestamp' do
        class_with_helper.roundup_requested = true
        expect(File.exist?(request_file)).to be true
        expect(File.read(request_file)).to match(/\d{4}-\d{2}-\d{2}/)
      end
    end

    context 'when set to false' do
      before do
        FileUtils.touch(request_file)
      end

      it 'removes the request file' do
        class_with_helper.roundup_requested = false
        expect(File.exist?(request_file)).to be false
      end
    end
  end

  describe '#load_status' do
    context 'when status file does not exist' do
      it 'returns default status with "missing" state' do
        expect(class_with_helper.load_status).to eq({
          'last_roundup' => nil,
          'status' => 'missing'
        })
      end
    end

    context 'when status file exists but is empty' do
      before do
        FileUtils.touch(status_file)
      end

      it 'returns default status with "missing" state' do
        expect(class_with_helper.load_status).to eq({
          'last_roundup' => nil,
          'status' => 'missing'
        })
      end
    end

    context 'when status file exists with content' do
      let(:status) do
        {
          'last_roundup' => '2025-01-01T12:00:00Z',
          'status' => 'completed'
        }
      end

      before do
        File.write(status_file, JSON.pretty_generate(status))
      end

      it 'returns the content of the status file' do
        expect(class_with_helper.load_status).to eq(status)
      end
    end

    context 'when JSON is invalid' do
      before do
        File.write(status_file, 'invalid json')
        allow(class_with_helper).to receive(:log)
      end

      it 'returns default status with "error" state' do
        expect(class_with_helper.load_status).to eq({
          'last_roundup' => nil,
          'status' => 'error'
        })
      end
    end
  end

  describe '#default_status' do
    it 'returns a hash with default values' do
      expect(class_with_helper.default_status).to eq({
        'last_roundup' => nil,
        'status' => 'unknown'
      })
    end

    it 'allows overriding the status value' do
      expect(class_with_helper.default_status('test')).to eq({
        'last_roundup' => nil,
        'status' => 'test'
      })
    end
  end

  describe '#update_status' do
    let(:original_status) do
      {
        'last_roundup' => '2025-01-01T12:00:00Z',
        'status' => 'initial'
      }
    end

    before do
      allow(class_with_helper).to receive(:load_status).and_return(original_status)
      allow(class_with_helper).to receive(:save_status)
    end

    it 'merges the update with existing status and saves it' do
      update = { 'status' => 'updated' }
      expected = original_status.merge(update)

      expect(class_with_helper).to receive(:save_status).with(expected)
      class_with_helper.update_status(update)
    end
  end

  describe '#save_status' do
    let(:status) do
      {
        'last_roundup' => '2025-03-15T12:00:00Z',
        'status' => 'test_status'
      }
    end

    it 'creates data directory if it does not exist' do
      FileUtils.rm_rf(data_dir)
      class_with_helper.save_status(status)
      expect(Dir.exist?(data_dir)).to be true
    end

    it 'writes the status to the file as formatted JSON' do
      class_with_helper.save_status(status)
      expect(File.exist?(status_file)).to be true
      
      file_content = File.read(status_file)
      expect(file_content).to include('"last_roundup": "2025-03-15T12:00:00Z"')
      expect(file_content).to include('"status": "test_status"')
    end
  end

  describe '#time_ago_in_words' do
    let(:now) { Time.new(2025, 3, 15, 12, 0, 0) }

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    it 'returns "just now" for times less than 10 seconds ago' do
      time = now - 5
      expect(class_with_helper.time_ago_in_words(time)).to eq('just now')
    end

    it 'returns minutes for times less than 100 minutes ago' do
      time = now - (15 * 60)
      expect(class_with_helper.time_ago_in_words(time)).to eq('15.0 minutes ago')
    end

    it 'returns hours for times more than 100 minutes ago' do
      time = now - (3 * 3600)
      expect(class_with_helper.time_ago_in_words(time)).to eq('3.0 hours ago')
    end
  end
end
