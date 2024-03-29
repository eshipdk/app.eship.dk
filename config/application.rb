require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EShip
  HOST_ADDRESS = 'https://app.eship.dk'
  WEBMASTER_MAIL = 'tech@eship.dk'
  EPAY_MERCHANT_NUMBER = '6512100'

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    
    
    # mail settings
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.smtp_settings = {
     :address              => "smtp.mailgun.org",
     :domain               => 'mail.eship.dk',
     :user_name            => 'postmaster@mail.eship.dk',
     :password             => '4c8c07d8aa479c9f38f1ec1c63090074',
     :authentication       => "plain",
     :port                 => 587,
     :enable_starttls_auto => true
    }
    

    config.autoload_paths += Dir[Rails.root.join('app', 'models', '**/')]
    config.assets.paths << Rails.root.join('vendor', 'assets')
    
    Rails.application.routes.default_url_options[:host] = EShip::HOST_ADDRESS
  end
end
