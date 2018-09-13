Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.js_compressor = :uglifier

  config.assets.compile = false

  config.action_controller.asset_host = "//#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com"
  config.assets.prefix = "/assets"
  config.assets.digest = true
  config.assets.enabled = true
  config.assets.initialize_on_precompile = true

  config.log_level = :debug

  config.log_tags = [ :request_id ]

  config.action_mailer.perform_caching = false

  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  config.log_formatter = ::Logger::Formatter.new

  config.time_zone = 'Eastern Time (US & Canada)'

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false
  config.action_mailer.default_url_options = { host: 'magentoqbo.rotati.com' }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.asset_host = "http://magentoqbo.rotati.com"

  config.action_mailer.smtp_settings = {
    address:               'email-smtp.us-west-2.amazonaws.com',
    authentication:        :login,
    user_name:             ENV['AWS_SES_USER_NAME'],
    password:              ENV['AWS_SES_PASSWORD'],
    enable_starttls_auto:  true,
    port:                  465,
    openssl_verify_mode:   OpenSSL::SSL::VERIFY_NONE,
    ssl:                   true,
    tls:                   true
  }
end
