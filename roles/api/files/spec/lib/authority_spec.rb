# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/authority'

RSpec.describe Authority do
  let(:attributes1) { { 'short_name' => 'test1', 'name' => 'Test Authority1', 'url' => 'https://example.com/test1' } }


  context 'With sample of live data' do
    before(:all) do
      # Set up the test data once for all tests
      DataSupport.link_data
      # Make sure the cache uses the linked data
      described_class.reset!
    end

    after(:all) do
      # Clean up after all tests
      DataSupport.cleanup
    end

    describe '.all' do
      it 'loads authorities from json data and maps them to Authority objects' do
        authorities = Authority.all
        expect(authorities.size).to eq(12)
        expect(authorities.first).to be_a(Authority)
        expect(authorities.first.short_name).to eq('act')
      end
    end

    describe 'lazy loading' do
      let(:authority) { Authority.all.find { |a| a.short_name == 'act' } }

      before do
        # Reset the instance variables to ensure lazy loading works as expected
        authority.instance_variable_set(:@details, nil)
        authority.instance_variable_set(:@stats, nil)
      end

      it 'loads details only when needed' do
        expect(AuthorityDetailsFetcher).to receive(:find).with('act').once.and_call_original

        # Just access a basic attribute, shouldn't trigger loading details
        authority.name

        # This should trigger loading details
        authority.morph_url

        # This should use the cached details
        authority.github_url
      end

      it 'loads stats only when needed' do
        expect(AuthorityStatsFetcher).to receive(:find).with('act').once.and_call_original

        # Just access a basic attribute, shouldn't trigger loading stats
        authority.name

        # This should trigger loading stats
        authority.week_count

        # This should use the cached stats
        authority.month_count
      end
    end

    describe 'accessor methods' do
      it 'accesses properties from all sources' do
        act = Authority.all.first

        expect(act.short_name).to eq('act')
        expect(act.morph_url).to eq('https://morph.io/planningalerts-scrapers/act')
        expect(act.github_url).to eq('https://github.com/planningalerts-scrapers/act')
        expect(act.app_count).to eq(64)

        expect(act.warning?).to eq(nil)
        expect(act.week_count).to eq(11)
        expect(act.month_count).to eq(56)
        expect(act.total_count).to eq(8731)
      end

      it 'provides hash-like access via []' do
        act = Authority.all.first
        # Direct attribute
        expect(act['short_name']).to eq('act')

        # From details
        expect(act['morph_url']).to eq('https://morph.io/planningalerts-scrapers/act')

        # From stats
        expect(act['week_count']).to eq(11)

        # Non-existent
        expect(act['nonexistent']).to be_nil
      end
    end
  end

  describe '#initialize' do
    it 'sets up basic attributes' do
      authority1 = Authority.new(attributes1)
      expect(authority1.short_name).to eq('test1')
      expect(authority1.name).to eq('Test Authority1')
      expect(authority1.url).to eq('https://example.com/test1')
    end

    it 'requires a short_name' do
      expect do
        Authority.new({})
      end.to raise_error(ArgumentError, 'short_name is required')
    end
  end

end
