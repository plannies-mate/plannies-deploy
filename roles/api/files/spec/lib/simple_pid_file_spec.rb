# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/simple_pid_file'

RSpec.describe SimplePidFile do
  let(:pid_file_name) { 'test_process' }
  let(:pid_path) { "/tmp/#{pid_file_name}.pid" }

  after do
    File.unlink(pid_path) if File.exist?(pid_path)
  end

  describe '.new' do
    it 'creates a PID file with the current process ID' do
      _pid_file = SimplePidFile.new(pid_file_name)
      expect(File.exist?(pid_path)).to be true
      expect(File.read(pid_path).to_i).to eq(Process.pid)
    end

    it 'raises an error if the process is already running' do
      # First create a pid file with the current process ID
      File.write(pid_path, Process.pid)

      # Then try to create a SimplePidFile, which should raise an error
      expect {
        SimplePidFile.new(pid_file_name)
      }.to raise_error(RuntimeError, /Process is already running/)
    end

    it 'removes stale PID files' do
      # Create a PID file with a non-existent process ID
      # Using a very large number to avoid hitting a real process
      File.write(pid_path, '999999999')

      # This should not raise an error
      expect {
        SimplePidFile.new(pid_file_name)
      }.not_to raise_error

      # The PID file should now contain the current process ID
      expect(File.read(pid_path).to_i).to eq(Process.pid)
    end

    it 'handles invalid PID files' do
      # Create an invalid PID file
      File.write(pid_path, 'not_a_pid')

      # This should not raise an error
      expect {
        SimplePidFile.new(pid_file_name)
      }.not_to raise_error

      # The PID file should now contain the current process ID
      expect(File.read(pid_path).to_i).to eq(Process.pid)
    end
  end

  describe '.create' do
    it 'is an alias for new' do
      expect(SimplePidFile).to receive(:new).with(pid_file_name)
      SimplePidFile.create(pid_file_name)
    end
  end

  describe 'at_exit behavior' do
    it 'removes the PID file when the process exits' do
      pid_file = SimplePidFile.new(pid_file_name)
      expect(File.exist?(pid_path)).to be true

      # Simulate at_exit callback
      pid_file.send(:remove_pid_file)
      expect(File.exist?(pid_path)).to be false
    end

    it 'only removes the PID file if it belongs to the current process' do
      # Create a PID file with a different PID
      File.write(pid_path, '12345')

      # Create a SimplePidFile instance and manually bypass the check_pid_file method
      pid_file = SimplePidFile.new(pid_file_name)
      
      # Overwrite with a different PID to simulate a race condition
      File.write(pid_path, '12345')

      # Simulate at_exit callback
      pid_file.send(:remove_pid_file)
      
      # The PID file should still exist
      expect(File.exist?(pid_path)).to be true
    end
  end
end
