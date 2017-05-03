namespace :magento_quickbooks_integrator do
  AUTHENTICATION_QBO_PRO_DATA = {
    consumer_key: ENV['QUICKBOOKS_CONSUMER_KEY'],
    consumer_secret: ENV['QUICKBOOKS_CONSUMER_SECRET'],
    quickbooks_username: ENV['QUICKBOOKS_USERNAME'],
    quickbooks_password: ENV['QUICKBOOKS_PASSWORD']
  }.freeze

  AUTHENTICATION_QBO_STAGING_DATA = {
    consumer_key: ENV['QUICKBOOKS_STAGING_CONSUMER_KEY'],
    consumer_secret: ENV['QUICKBOOKS_STAGING_CONSUMER_SECRET'],
    quickbooks_username: ENV['QUICKBOOKS_STAGING_USERNAME'],
    quickbooks_password: ENV['QUICKBOOKS_STAGING_PASSWORD']
  }.freeze

  AUTHENTICATION_QBO_DEVELOPMENT_DATA = {
    consumer_key: ENV['QUICKBOOKS_DEVELOPMENT_CONSUMER_KEY'],
    consumer_secret: ENV['QUICKBOOKS_DEVELOPMENT_CONSUMER_SECRET'],
    quickbooks_username: ENV['QUICKBOOKS_DEVELOPMENT_USERNAME'],
    quickbooks_password: ENV['QUICKBOOKS_DEVELOPMENT_PASSWORD']
  }.freeze

  AUTHENTICATION_MAGENTO_PRO_DATA = {
    consumer_key: ENV['MAGENTO_PRO_CONSUMER_KEY'],
    consumer_secret: ENV['MAGENTO_PRO_CONSUMER_SECRET'],
    url: ENV['MAGENTO_PRO_URL'],
    username: ENV['MAGENTO_PRO_ADMIN_USERNAME'],
    password: ENV['MAGENTO_PRO_ADMIN_PASSWORD'],
    soap_api_username: ENV['MAGENTO_PRO_API_USERNAME'],
    soap_api_key: ENV['MAGENTO_PRO_API_KEY']
  }.freeze

  AUTHENTICATION_MAGENTO_STAGING_DATA = {
    consumer_key: ENV['MAGENTO_STAGING_CONSUMER_KEY'],
    consumer_secret: ENV['MAGENTO_STAGING_CONSUMER_SECRET'],
    url: ENV['MAGENTO_STAGING_URL'],
    username: ENV['MAGENTO_STAGING_ADMIN_USERNAME'],
    password: ENV['MAGENTO_STAGING_ADMIN_PASSWORD'],
    soap_api_username: ENV['MAGENTO_STAGING_API_USERNAME'],
    soap_api_key: ENV['MAGENTO_STAGING_API_KEY']
  }.freeze

  desc 'Pushing data to QBO'
  task pushing_orders_to_qbo: :environment do
    date_range = ['2016-11-01 00:00:00 EST', '2016-11-01 10:59:59 EST']
    environment = Rails.env
    authentication_data = MagentoQboMethods.new.check_environment_authentication(environment)
    MagentoQboMethods.new.push_qbo_receipts_from_magento_orders(date_range, authentication_data, environment)
  end

  desc 'Get Specific order data'
  task get_specific_order_id: :environment do
    puts "Total Run: #{Run.all.size}"
    Run.all.each do |run|
      no_order_id_run_logs = run.run_logs.where(order_id: nil)
      puts "Total Run Logs: #{no_order_id_run_logs.size}"
      no_order_id_run_logs.each do |run_log|
        order = MagentoRestApi.new.get_specific_magento_order(AUTHENTICATION_MAGENTO_PRO_DATA, run_log.magento_id)
        run_log.update_attributes(order_id: order.keys[0])
        order_logs = OrderLog.joins('INNER JOIN run_logs ON (#{run_log.id} = order_logs.last_runlog_id)').uniq
        puts "Total Order Logs: #{order_logs.size}"
        order_logs.each do |order_log|
          order_log.update_attributes(order_id: order.keys[0])
        end
      end
    end
  end

  desc 'Delete Sales Receipt'
  task delete_sales_reciept_by_month: :environment do
    production_access_token = RecordToken.where(type_token: 'production').first
    date_range = ['2016-09-01 00:00:00', '2016-09-30 23:59:59']

    puts 'get order from magento that need to push today'
    invoice_list = MagentoInvoiceSoapApi.new.get_invoices_from_soap_api(AUTHENTICATION_MAGENTO_PRO_DATA, state: '2', start_date: date_range[0], end_date: date_range[1])
    puts invoice_list.count

    magento_orders = MagentoRestApi.new.order_data(AUTHENTICATION_MAGENTO_PRO_DATA, invoice_list)

    MagentoRestApi.new.write_magento_order_to_excel(magento_orders)

    QuickbooksSalesReceipt.new.delete_sales_reciept(magento_orders, AUTHENTICATION_QBO_PRO_DATA, production_access_token)
    puts 'End of processing'
  end

  desc 'get creditmemo list'
  task creditmemo_from_magento: :environment do
    creditmemo_list = MagentoInvoiceSoapApi.new.get_creditmemo_from_soap_api(AUTHENTICATION_MAGENTO_STAGING_DATA)
    magento_orders = MagentoRestApi.new.order_data(AUTHENTICATION_MAGENTO_STAGING_DATA, creditmemo_list)
    MagentoRestApi.new.write_magento_order_to_excel(magento_orders)
  end

  desc 'push all tax code from production into staging'
  task push_all_tax_code: :environment do
    production_access_token = RecordToken.where(type_token: 'production').first
    staging_access_token = RecordToken.where(type_token: 'staging').first

    tax_codes_collection = QuickbooksTaxes.new.get_all_tax_codes(AUTHENTICATION_QBO_PRO_DATA, production_access_token)
    tax_codes_with_agencies = QuickbooksTaxes.new.check_agency_name(AUTHENTICATION_QBO_PRO_DATA, production_access_token, tax_codes_collection)
    QuickbooksTaxes.new.push_production_taxes_to_staging(AUTHENTICATION_QBO_STAGING_DATA, staging_access_token, tax_codes_with_agencies)
  end
end
