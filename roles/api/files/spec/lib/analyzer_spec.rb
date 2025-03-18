# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/analyzer'

RSpec.describe Analyzer do
  let(:analyzer) { Analyzer.new }


  after do
    FileUtils.rm_rf(described_class.data_dir)
  end
  
  describe '#run' do
    context 'when forced to run' do
      before do
        allow(analyzer).to receive(:perform_analysis)
      end
      
      it 'calls perform_analysis' do
        expect(analyzer).to receive(:perform_analysis)
        analyzer.run(force: true)
      end
    end
    
    context 'when not forced to run' do
      context 'and should_run? returns true' do
        before do
          pending "getting nightly run working"
          allow(analyzer).to receive(:should_run?).and_return(true)
          allow(analyzer).to receive(:perform_analysis)
        end

        it 'calls perform_analysis' do
          pending "getting nightly run working"
          expect(analyzer).to receive(:perform_analysis)
          analyzer.run
        end
      end

      context 'and should_run? returns false' do
        before do
          pending "getting nightly run working"
          allow(analyzer).to receive(:should_run?).and_return(false)
        end

        it 'logs a message and does not call perform_analysis' do
          expect(described_class).to receive(:log).with('No analysis needed at this time')
          expect(analyzer).not_to receive(:perform_analysis)
          analyzer.run
        end
      end
    end
  end

  describe '#should_run?' do
    context 'when trigger file exists' do
      before do
        pending "getting nightly run working"
        FileUtils.touch(trigger_file)
      end
      
      it 'returns true' do
        expect(analyzer.send(:should_run?)).to be true
      end
    end
    
    context 'when status file does not exist' do
      it 'returns true' do
        pending "getting nightly run working"
        expect(described_class).to receive(:log).with('Status file not found, running initial analysis')
        expect(analyzer.send(:should_run?)).to be true
      end
    end
    
    context 'when last check is nil' do
      before do
        pending "getting nightly run working"
        File.write(status_file, JSON.generate({ 'last_roundup' => nil }))
      end
      
      it 'returns true' do
        expect(described_class).to receive(:log).with('No previous check found, running initial analysis')
        expect(analyzer.send(:should_run?)).to be true
      end
    end
    
    context 'when last check is more than 24 hours ago' do
      before do
        pending "getting nightly run working"
        File.write(status_file, JSON.generate({ 'last_roundup' => (Time.now - 25 * 3600).iso8601 }))
      end
      
      it 'returns true' do
        expect(described_class).to receive(:log).with('Last check was more than 24 hours ago, running scheduled analysis')
        expect(analyzer.send(:should_run?)).to be true
      end
    end
    
    context 'when last check is less than 24 hours ago' do
      before do
        pending "getting nightly run working"
        File.write(status_file, JSON.generate({ 'last_roundup' => (Time.now - 12 * 3600).iso8601 }))
      end
      
      it 'returns false' do
        expect(analyzer.send(:should_run?)).to be false
      end
    end
  end
end
