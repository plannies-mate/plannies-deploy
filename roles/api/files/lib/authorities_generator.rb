# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../app/helpers/application_helper'
require_relative 'authority'
require_relative 'generator_base'
require_relative 'morph_scraper'

# Generates `data_dir/authorities.html`
class AuthoritiesGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    authorities = Authority.all.sort_by { |a| [a.state || 'ZZZ', a.name.downcase] }
    locals = { authorities: authorities }

    render_template('authorities', 'authorities', locals)
    log "Generated authorities index page with #{authorities.size} authorities"
  end
end
