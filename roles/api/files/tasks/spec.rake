# frozen_string_literal: true

if ENV['RACK_ENV'] != 'production'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task default: :spec

  namespace :spec do
    desc 'Run App specs'
    RSpec::Core::RakeTask.new(:app) do |t|
      t.pattern = 'spec/app/**/*_spec.rb'
    end

    desc 'Run Library specs'
    RSpec::Core::RakeTask.new(:lib) do |t|
      t.pattern = 'spec/lib/**/*_spec.rb'
    end

    desc 'Run Rake Task specs'
    RSpec::Core::RakeTask.new(:tasks) do |t|
      t.pattern = 'spec/tasks/**/*_spec.rb'
    end
  end
else
  puts "Run 'rake -T' for list of rake tasks (no default task in production)"
end
