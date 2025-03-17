# frozen_string_literal: true

# lib/simple_pid_file.rb

# Simple Pid File Lock
class SimplePidFile
  attr_reader :path, :name

  def initialize(name)
    @name = name
    @path = "/tmp/#{name.gsub(/\W+/, '_')}.pid"
    check_pid_file
    write_pid_file
    at_exit { remove_pid_file }
  end

  def self.create(name)
    new(name)
  end

  private

  def check_pid_file
    return unless File.exist?(path)

    old_pid = File.read(path).to_i
    if old_pid.positive?
      begin
        # Check if process is still running
        Process.kill(0, old_pid)
        raise "Process is already running with PID: #{old_pid}"
      rescue Errno::ESRCH
        # Process not running, we can remove stale pid file
        File.unlink(path)
      rescue Errno::EPERM
        # Process running but owned by another user
        raise "Process #{old_pid} already running but owned by another user"
      end
    else
      # Invalid PID in file, remove it
      File.unlink(path)
    end
  end

  def write_pid_file
    File.open(path, 'w') { |f| f.puts Process.pid }
  end

  def remove_pid_file
    File.unlink(path) if File.exist?(path) && File.read(path).to_i == Process.pid
  end
end
