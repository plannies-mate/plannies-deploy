# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../app/helpers/application_helper'
require_relative 'authority'
require_relative 'generator_base'
require_relative 'morph_scraper'

# Generates `data_dir/authorities/#{authority.short_name}.html`
class AuthorityGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate(authority)
    locals = {
      authority: authority,
      title: authority.name
    }

    render_template('authority', "authorities/#{authority.short_name}", locals)
    log "Generated authority page for #{authority.name} (#{authority.short_name})"
  end

  # Generate pages for all authorities
  def self.generate_all
    Authority.all.each do |authority|
      generate(authority)
    end
    log 'Generated all authority pages'
  end
end
