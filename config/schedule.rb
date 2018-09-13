# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :environment, ENV['RAILS_ENV']
set :output, { error: 'log/cron_error_log.log', standard: 'log/cron_log.log' }

# every 1.day, at: '1:00 am' do
#   rake "magento_quickbooks_integrator:pushing_data_to_qbo"
# end

every 1.day, at: '1:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '2:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '3:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '4:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '5:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '6:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '7:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '8:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '9:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '10:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '11:00am', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '1:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '2:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '3:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '4:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '5:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '6:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '7:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '8:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '9:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '10:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end

every 1.day, at: '11:00pm', roles: [:app] do
	rake "magento_quickbooks_integrator:pushing_data_to_qbo"
end