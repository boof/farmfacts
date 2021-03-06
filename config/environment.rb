require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  config.gem 'nokogiri'
  config.gem 'haml'
  config.gem 'xbel'
  config.gem 'v'
  config.gem 'tidy_ffi'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  config.frameworks -= [ :active_resource ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  config.i18n.default_locale = 'en-US'

  config.action_view.field_error_proc = proc do |html, context|
      case html
      when /label/; %Q'<span class="ui-state-error-text">#{ html }</span>'
      else html
      end
    end
end

ENV['RAILS_ASSET_ID'] = Time.now.to_i.to_s
ActionController::Base.asset_host = "assets%d.booya.local"
