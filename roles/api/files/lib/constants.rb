# frozen_string_literal: true

require_relative '../app/controllers/analyze_controller'
require_relative '../app/controllers/health_controller'
require_relative '../app/controllers/develop_controller'

# Application wide constants
class Constants
  ROUTES = [
    { path: '/api/health', controller: HealthController },
    { path: '/api/analyze', controller: AnalyzeController },
    { path: '/', controller: DevelopController }
  ].freeze
end