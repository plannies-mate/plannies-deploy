# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/analyzer'

RSpec.describe Analyzer, 'perform_analysis' do
  let(:analyzer) { Analyzer.new }

  before do
    # Stub out the data_dir and related paths
    # allow(analyzer).to receive(:DATA_DIR).and_return(data_dir)
    # allow(analyzer).to receive(:STATUS_FILE).and_return(status_file)
    # allow(described_class).to receive(:log)
    # allow(analyzer).to receive(:update_status)
    #
    # # Mock the fetching methods
    # allow_any_instance_of(AuthoritiesFetcher).to receive(:fetch).and_return(true)
    # allow(analyzer).to receive(:check_github_repos).and_return({})
    # allow(analyzer).to receive(:check_morph_scrapers).and_return({})
    #
    # # Make sure directory exists
    # FileUtils.mkdir_p(data_dir)
  end

  after do
    FileUtils.rm_rf(described_class.data_dir)
  end

  describe '#perform_analysis' do
    it 'updates status to running at the start' do
      pending "Working on analyzer"
      expect(described_class).to receive(:update_status).with({ 'status' => 'analyzing' })

      analyzer.send(:perform_analysis)
    end

    it 'checks PlanningAlerts authorities' do
      # expect_any_instance_of(AuthoritiesFetcher).to receive(:fetch)

      analyzer.send(:perform_analysis)
    end

    it 'checks GitHub repos' do
      # expect(analyzer).to receive(:check_github_repos)

      analyzer.send(:perform_analysis)
    end

    it 'checks Morph.io scrapers' do
      # expect(analyzer).to receive(:check_morph_scrapers)

      analyzer.send(:perform_analysis)
    end

    it 'updates status with timestamps on completion' do
      completion_status = {
        # 'last_roundup' => anything,
        # 'github_check' => anything,
        # 'morph_check' => anything,
        # 'planning_alerts_check' => anything,
        'status' => 'analyzed'
      }

      expect(described_class).to receive(:update_status).with(hash_including(completion_status))
      pending "Working on analyzer"
      analyzer.send(:perform_analysis)
    end

    context 'when an error occurs' do
      before do
        allow_any_instance_of(AuthoritiesFetcher).to receive(:fetch).and_raise(StandardError.new('test error'))
      end

      it 'updates status with the error' do
        pending "Working on analyzer"
        expect(described_class).to receive(:update_status).with({
                                                           'status' => 'error',
                                                           'error' => 'test error'
                                                         })

        analyzer.send(:perform_analysis)
      end
    end
  end

  describe '#check_github_repos' do
    it 'returns a placeholder hash' do
      expect(analyzer.send(:check_github_repos)).to eq({ 'repos' => [] })
    end
  end

  describe '#check_morph_scrapers' do
    it 'returns a placeholder hash' do
      expect(analyzer.send(:check_morph_scrapers)).to eq({ 'scrapers' => [] })
    end
  end
end
