# frozen_string_literal: true

require 'slim'
require 'json'
require 'fileutils'
require 'date'

require_relative 'view_context'

# Module providing common functionality for generators
#
# use `extend GeneratorBase` so everything become class methods
module GeneratorBase
  # Get the views directory path
  def views_dir
    File.expand_path('../views', __dir__)
  end

  # Create directories for the output path if they don't exist
  def ensure_directory_for_file(path)
    dirname = File.dirname(path)
    FileUtils.mkdir_p(dirname)
  end

  # Render a template with layouts and write to a file
  def render_template(view, url_path, locals = {})
    # Add default locals that all templates need
    locals[:title] ||= view.capitalize
    layout = locals[:layout] || 'default'

    # Get the template paths
    template_path = add_slim_extensions File.join(views_dir, "pages/#{view}")
    layout_path = add_slim_extensions File.join(views_dir, "layouts/#{layout}")

    # Create view context with proper access to view helpers
    context = ViewContext.new(views_dir)

    # Render the template with the layout
    template = Slim::Template.new(template_path)
    layout = Slim::Template.new(layout_path)

    content = template.render(context, locals)
    output = layout.render(context, locals) { content }

    # Write the output to the file
    output_path = File.join(site_dir, "#{url_path}.html")
    ensure_directory_for_file(output_path)
    File.write(output_path, output)

    log "Generated: #{output_path}"
  end

  def add_slim_extensions(path)
    ['', '.slim', '.html.slim'].each do |suffix|
      this_path = "#{path}#{suffix}"
      return this_path if File.exist?(this_path)
    end
    path
  end
end
