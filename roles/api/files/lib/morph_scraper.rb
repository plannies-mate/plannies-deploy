# frozen_string_literal: true

# Morph Scraper details collected Authority details
#
# Note: Assumes morph_url ends in unique name for each scraper
class MorphScraper
  attr_reader :name, :morph_url, :github_url, :authorities

  # Initialize from authority
  def initialize(authority)
    @morph_url = authority.morph_url
    @name = authority.morph_url.split('/').last
    @github_url = authority.github_url
    @authorities = [authority]
  end

  # Equal if its name matches
  #
  # The other details may differ
  def ==(other)
    name == other.name
  end

  alias eql? ==
end
