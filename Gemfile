source 'https://rubygems.org'

gem 'coffee-rails',                 '~> 4.2'
gem 'pg',                           '~> 0.18'
gem 'puma',                         '~> 3.0'
gem 'rails',                        '~> 5.0.2'
gem 'sass-rails',                   '~> 5.0'
gem 'uglifier',                     '>= 1.3.0'

gem 'jbuilder',                     '~> 2.5'
gem 'jquery-rails'
gem 'turbolinks',                   '~> 5'

gem 'devise',                       '~> 4.2.0'
gem 'dotenv-rails',                 '~> 2.1.1'
gem 'haml',                         '~> 4.0.7'
gem 'haml-rails'
gem 'kaminari',                     '~> 0.17.0'
gem 'materialize-sass',             '~> 0.97.7'

gem 'magento_soap_api',            path: 'magento_soap_api'
gem 'mechanize',                   '~> 2.7.5'
gem 'oauth',                       '~> 0.4.7'
gem 'pry'
gem 'quickbooks-ruby',             '~> 0.4.8'
gem 'rubyntlm',                    '~> 0.3.2'
gem 'savon',                       '~> 2.11.0'
gem 'simple_form',                 '~> 3.4.0'
gem 'spreadsheet',                 '~> 1.1.4'

gem 'capybara',                     '~> 2.10.1'
gem 'launchy',                      '~> 2.4.3'
gem 'poltergeist',                  '~> 1.11.0'

gem 'appsignal',                    '~> 1.2.5'

group :development, :test do
  gem 'database_cleaner',   '~> 1.5.3'
  gem 'factory_girl_rails', '~> 4.7.0'
  gem 'ffaker',             '~> 2.3'
  gem 'listen'
  gem 'rspec-rails',        '~> 3.5.2'
  gem 'vcr',                '~> 3.0.3'
  gem 'webmock',            '~> 2.1'
end

group :test do
  gem 'json_spec',          '~> 1.1.4'
  gem 'shoulda-matchers',   '~> 3.1.1'
end

group :development do
  gem 'brakeman', require: false
  gem 'capistrano-passenger', '~> 0.2.0'
  gem 'capistrano-rails',   '~> 1.2.0'
  gem 'capistrano-rails-console', '~> 1.0.2'
  gem 'capistrano-rvm',       '0.1.2'
  gem 'capistrano-sidekiq', '0.3.5'
  gem 'haml-lint', require: false
  gem 'letter_opener', '~> 1.4.1'
  gem 'rubocop', require: false
end

group :staging, :production do
  gem 'asset_sync',         '~> 1.2.1'
  gem 'fog',                '~> 1.38.0'
end

gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
