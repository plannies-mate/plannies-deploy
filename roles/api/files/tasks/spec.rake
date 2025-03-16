# frozen_string_literal: true

if ENV['RACK_ENV'] != 'production'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task default: :spec

  namespace :spec do
    desc 'Run analyzer specs'
    RSpec::Core::RakeTask.new(:analyzer) do |t|
      t.pattern = 'spec/analyzer/**/*_spec.rb'
    end

    desc 'Run API specs'
    RSpec::Core::RakeTask.new(:api) do |t|
      t.pattern = 'spec/api/**/*_spec.rb'
    end
  end
else
  # FIXME: default route
end
