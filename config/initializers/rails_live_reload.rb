# Rails Live Reload configuration
if Rails.env.development?
  RailsLiveReload.configure do |config|
    # Watch all erb files
    config.watch %r{app/views/.+\.(erb|haml|slim)$}
    # Watch all scss files
    config.watch %r{app/assets/stylesheets/.+\.(css|scss)$}
    # Watch JavaScript files
    config.watch %r{app/javascript/.+\.(js|jsx)$}
    # Watch Ruby files
    config.watch %r{(app|config)/(.+)\.rb$}
  end
end
