# frozen_string_literal: true

# Application wide constants
class Constants
  ROUTES = [
    { path: '/api/health', controller: HealthController },
    { path: '/api/analyze', controller: AnalyzeController },
    { path: '/', controller: DevelopController }
  ].freeze
end