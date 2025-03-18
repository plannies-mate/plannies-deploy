# frozen_string_literal: true

require 'fileutils'

# Spec support module for setting up test data
module DataSupport
  # Link data from a named example directory to the data_dir
  # @param example_name [String] Name of the example data directory (default: "example_data")
  # @return [String] Path to the data directory
  def self.link_data(example_name = 'example_data')
    fixtures_dir = File.expand_path('../fixtures', __dir__)
    example_dir = File.join(fixtures_dir, example_name)

    data_dir = setup_data_dir

    # Link all files from the example directory to the data directory
    system("cd #{example_dir} && find . -type f -print0 | cpio -pdl0 #{data_dir}")

    data_dir
  end

  # Clean up and create a new empty data directory
  # @return [String] Path to the new data directory
  def self.setup_data_dir
    data_dir = AuthoritiesFetcher.data_dir

    FileUtils.rm_rf(data_dir)
    FileUtils.mkdir_p(data_dir)

    data_dir
  end

  # Clean up the data directory
  def self.cleanup
    data_dir = AuthoritiesFetcher.data_dir
    FileUtils.rm_rf(data_dir)
  end
end
