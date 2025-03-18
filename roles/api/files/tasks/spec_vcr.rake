# frozen_string_literal: true

namespace :spec do
  namespace :vcr do
    desc 'Clobber VCR cassettes so next spec run will re-record them'
    task :clobber do
      cassette_dir = File.join(File.dirname(__FILE__), '../spec/cassettes')

      puts "Removing #{cassette_dir} ..."
      FileUtils.rm_rf(cassette_dir)
      puts '... Run your specs to re-record them.'
    end
  end
end
