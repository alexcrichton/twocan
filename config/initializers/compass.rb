Rails.application.config.after_initialize do
  compass = Gem.loaded_specs['compass'].full_gem_path
  config = Rails.application.config
  config.sass.load_paths << "#{compass}/frameworks/compass/stylesheets"
  config.sass.load_paths << "#{compass}/frameworks/blueprint/stylesheets"
end
