# config valid only for current version of Capistrano
lock '3.8.0'

set :application, 'nasb-magento-quickbooks'
set :repo_url, "git@github.com:rotati/#{fetch(:application)}.git"

ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :deploy_to, "/var/www/#{fetch(:application)}"
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets')
set :linked_files, fetch(:linked_files, []).push('.env')

set :scm, :git

set :pty, true
set :passenger_restart_with_touch, true

set :keep_releases, 5

namespace :deploy do

  task :cleanup_assets do
    on roles :all do
      execute "cd #{release_path}/ && ~/.rvm/bin/rvm default do bundle exec rake assets:clobber RAILS_ENV=#{fetch(:stage)}"
    end
  end

  task :whenever do
    on roles :app do
      execute "cd #{release_path}/ && ~/.rvm/bin/rvm default do bundle exec whenever RAILS_ENV=#{fetch(:stage)}"
    end
  end

  before :updated, :cleanup_assets
  before :updated, :whenever
end

require 'appsignal/capistrano'
