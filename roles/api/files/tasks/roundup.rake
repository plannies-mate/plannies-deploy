# frozen_string_literal: true

namespace :roundup do
  desc 'Roundup everything (fetch, analyze, generate)'
  task all: %i[singleton fetch:all analyze:all generate:all] do
    puts 'Finished roundup:all'
  end
end
