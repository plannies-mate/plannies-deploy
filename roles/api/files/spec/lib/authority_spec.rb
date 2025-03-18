# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/authority'

RSpec.describe Authority do
  let(:attributes1) { { 'short_name' => 'test1', 'name' => 'Test Authority1', 'url' => 'https://example.com/test1' } }
  let(:attributes2) { { 'short_name' => 'test2', 'name' => 'Test Authority2', 'url' => 'https://example.com/test2' } }
  let(:authority1) { Authority.new(attributes1) }

  describe '.all' do
    it 'loads authorities from json data and maps them to Authority objects' do
      expect(AuthoritiesFetcher).to receive(:all).and_return([attributes1, attributes2])
      authorities = Authority.all
      expect(authorities.size).to eq(2)
      expect(authorities.first).to be_a(Authority)
      expect(authorities.first.short_name).to eq('test1')
    end
  end

  describe '#initialize' do
    it 'sets up basic attributes' do
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

  context 'When there are stats and details data' do
    let(:stats) do
      {
        'short_name' => 'authority1',
        'warning' => true,
        'last_received' => 'about 3 years ago',
        'week_count' => 0,
        'month_count' => 0,
        'total_count' => 2055,
        'added' => '14 dec 2009',
        'median_per_week' => 7
      }
    end

    let(:details) do
      {
        'short_name' => 'authority1',
        'morph_url' => 'https://morph.io/planningalerts-scrapers/scraper1',
        'github_url' => 'https://github.com/planningalerts-scrapers/scraper1',
        'last_log' => "0 applications found for Authority 1, VIC with date from 2025-03-11\nTook 0 s to import applications from Authority 1, VIC",
        'app_count' => 0,
        'import_time' => '0 s'
      }
    end

    describe 'lazy loading' do
      it 'loads details only when needed' do
        allow(AuthorityDetailsFetcher).to receive(:find).and_return(details)

        authority1.name # Just instantiate, don't access details
        expect(AuthorityDetailsFetcher).not_to have_received(:find)

        authority1.morph_url # This should trigger loading details
        expect(AuthorityDetailsFetcher).to have_received(:find).with('test1').once

        authority1.github_url # This should use the cached stats
        expect(AuthorityDetailsFetcher).to have_received(:find).with('test1').once
      end

      it 'loads stats only when needed' do
        allow(AuthorityStatsFetcher).to receive(:find).and_return(stats)

        authority1.name # Just instantiate, don't access stats
        expect(AuthorityStatsFetcher).not_to have_received(:find)

        authority1.week_count # This should trigger loading stats
        expect(AuthorityStatsFetcher).to have_received(:find).with('test1').once

        authority1.month_count # This should use the cached stats
        expect(AuthorityStatsFetcher).to have_received(:find).with('test1').once
      end
    end

    describe 'accessor methods' do
      it 'accesses properties from all sources' do
        expect(AuthorityDetailsFetcher).to receive(:find).with('test1').once.and_return(details)
        expect(AuthorityStatsFetcher).to receive(:find).with('test1').once.and_return(stats)

        expect(authority1.short_name).to eq('test1')
        expect(authority1.morph_url).to eq('https://morph.io/planningalerts-scrapers/scraper1')
        expect(authority1.github_url).to eq('https://github.com/planningalerts-scrapers/scraper1')
        expect(authority1.app_count).to eq(0)

        expect(authority1.warning?).to eq(true)
        expect(authority1.week_count).to eq(0)
        expect(authority1.month_count).to eq(0)
        expect(authority1.total_count).to eq(2055)
      end

      it 'provides hash-like access via []' do
        expect(AuthorityDetailsFetcher).to receive(:find).once.and_return(details)
        expect(AuthorityStatsFetcher).to receive(:find).once.and_return(stats)

        # Direct attribute
        expect(authority1['short_name']).to eq('test1')

        # From details
        expect(authority1['morph_url']).to eq('https://morph.io/planningalerts-scrapers/scraper1')

        # From stats
        expect(authority1['week_count']).to eq(0)

        # Non-existent
        expect(authority1['nonexistent']).to be_nil
      end
    end
  end
end
