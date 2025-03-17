# roles/api/files/lib/site_generator.rb

require 'slim'
require 'json'
require 'fileutils'

# Generate pages to be served statically
class SiteGenerator
  include ApplicationHelper

  TEMPLATE_DIR = File.expand_path('templates', __dir__)

  def initialize
    @output_dir = site_dir
    FileUtils.mkdir_p(@output_dir)
  end

  def generate_site
    puts "Generating static site in #{@output_dir}..."

    # Generate index page
    generate_index(authorities)

    # Generate individual authority pages
    authorities.each do |authority|
      generate_authority_page(authority)
    end

    # Copy assets in production mode (in dev they're symlinked)
    copy_assets if @env == 'production'

    puts 'Static site generation complete!'
  end

  private

  def authorities
    @authorities ||= Authority.all
  end

  def generate_index(authorities)
    template = File.join(TEMPLATE_DIR, 'index.slim')
    output_file = File.join(@output_dir, 'index.html')

    render_template(template, output_file, all: authorities, env: @env)
  end

  def generate_authority_page(authority)
    template = File.join(TEMPLATE_DIR, 'authority.slim')
    @output_dir = File.join(@output_dir, 'all')
    FileUtils.mkdir_p(@output_dir)

    output_file = File.join(@output_dir, "#{authority['short_name']}.html")

    render_template(template, output_file, authority: authority, env: @env)
  end

  def render_template(template_path, output_path, locals = {})
    # Ensure layout is available in templates
    locals[:layout] = lambda do |&block|
      layout_template = File.join(TEMPLATE_DIR, 'layouts/default.slim')
      Tilt.new(layout_template).render(Object.new, locals) { block.call }
    end

    # Render template
    content = Tilt.new(template_path).render(Object.new, locals)

    # Write to file
    File.write(output_path, content)
    puts "Generated: #{output_path}"
  end

  def copy_assets
    assets_dir = File.expand_path('../site/assets', __dir__)
    output_assets_dir = File.join(@output_dir, 'assets')

    return unless Dir.exist?(assets_dir)

    FileUtils.mkdir_p(output_assets_dir)
    FileUtils.cp_r(Dir.glob("#{assets_dir}/*"), output_assets_dir)
    puts "Copied assets to #{output_assets_dir}"
  end
end
