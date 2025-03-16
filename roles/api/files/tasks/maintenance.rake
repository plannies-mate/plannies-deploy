# frozen_string_literal: true

namespace :maintenance do
  desc 'Rotate log files'
  task :rotate_logs do
    log_file = File.join(File.dirname(__FILE__), '../../log/analyze-scrapers.log')
    backup_file = "#{log_file}.1"

    FileUtils.mv(log_file, backup_file, force: true) if File.exist?(log_file)
  end

  desc 'Clean old data files (over 30 days)'
  task :clean_old_data do
    # Add implementation to remove old files
  end
end
