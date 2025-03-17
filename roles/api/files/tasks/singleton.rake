# frozen_string_literal: true

require_relative '../lib/simple_pid_file'

desc 'Run only one copy of rake at a time'
task :singleton do
  @pidfile = SimplePidFile.new('plannies-mate-task')
end
