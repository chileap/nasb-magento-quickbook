namespace :magento_quickbooks_integrator do

  AUTHENTICATION_QBO_PRO_DATA = {
    consumer_key: ENV['QUICKBOOKS_CONSUMER_KEY'],
    consumer_secret: ENV['QUICKBOOKS_CONSUMER_SECRET'],
    quickbooks_username: ENV['QUICKBOOKS_USERNAME'],
    quickbooks_password: ENV['QUICKBOOKS_PASSWORD']
  }

  AUTHENTICATION_QBO_STAGING_DATA = {
    consumer_key: ENV['QUICKBOOKS_STAGING_CONSUMER_KEY'],
    consumer_secret: ENV['QUICKBOOKS_STAGING_CONSUMER_SECRET'],
    quickbooks_username: ENV['QUICKBOOKS_STAGING_USERNAME'],
    quickbooks_password: ENV['QUICKBOOKS_STAGING_PASSWORD']
  }

  AUTHENTICATION_MAGENTO_PRO_DATA = {
    consumer_key: ENV['MAGENTO_PRO_CONSUMER_KEY'],
    consumer_secret: ENV['MAGENTO_PRO_CONSUMER_SECRET'],
    url: ENV['MAGENTO_PRO_URL'],
    username: ENV['MAGENTO_PRO_ADMIN_USERNAME'],
    password: ENV['MAGENTO_PRO_ADMIN_PASSWORD'],
    soap_api_username: ENV['MAGENTO_PRO_API_USERNAME'],
    soap_api_key: ENV['MAGENTO_PRO_API_KEY']
  }

  AUTHENTICATION_MAGENTO_STAGING_DATA = {
    consumer_key: ENV['MAGENTO_STAGING_CONSUMER_KEY'],
    consumer_secret: ENV['MAGENTO_STAGING_CONSUMER_SECRET'],
    url: ENV['MAGENTO_STAGING_URL'],
    username: ENV['MAGENTO_STAGING_ADMIN_USERNAME'],
    password: ENV['MAGENTO_STAGING_ADMIN_PASSWORD'],
    soap_api_username: ENV['MAGENTO_STAGING_API_USERNAME'],
    soap_api_key: ENV['MAGENTO_STAGING_API_KEY']
  }

  desc "Delete Sales Receipt"
  task :delete_sales_reciept_by_month => :environment do
    development_access_token = RecordToken.where(type_token: 'development').first
    production_access_token = RecordToken.where(type_token: 'production').first
    staging_access_token = RecordToken.where(type_token: 'staging').first
    date_range = ['2016-08-01 00:00:00', '2016-08-31 23:59:59']

    puts 'get order from magento that need to push today'
    invoice_list = MagentoInvoiceSoapApi.new.get_invoices_from_soap_api(AUTHENTICATION_MAGENTO_PRO_DATA, state: '2', start_date: date_range[0], end_date: date_range[1])
    puts invoice_list.count

    magento_orders = MagentoRestApi.new.order_data(AUTHENTICATION_MAGENTO_PRO_DATA, invoice_list)

    MagentoRestApi.new.write_magento_order_to_excel(magento_orders)

    sales_receipts = QuickbooksSalesReceipt.new.delete_sales_reciept(magento_orders, AUTHENTICATION_QBO_PRO_DATA, production_access_token)
    puts "End of processing"
  end

  desc "Pushing data to QBO"
  task :pushing_orders_to_qbo => :environment do
    development_access_token = RecordToken.where(type_token: 'development').first
    production_access_token = RecordToken.where(type_token: 'production').first
    staging_access_token = RecordToken.where(type_token: 'staging').first

    date_range = ['2016-10-01 00:00:00', '2016-10-31 23:59:59']

    puts "Start running"
    run_report = Run.create!(run_date: DateTime.now)

    puts 'find error from last pushing'
    errors_orders = OrderLog.get_error_orders(AUTHENTICATION_MAGENTO_PRO_DATA)
    puts "end of finding. There are #{errors_orders.count} error from last time"

    puts 'get order from magento that need to push today'
    invoice_list = MagentoInvoiceSoapApi.new.get_invoices_from_soap_api(AUTHENTICATION_MAGENTO_PRO_DATA, state: '2', start_date: date_range[0], end_date: date_range[1])
    puts invoice_list.count

    magento_orders = MagentoRestApi.new.order_data(AUTHENTICATION_MAGENTO_PRO_DATA, invoice_list)

    magento_orders.merge!(errors_orders)
    puts "total order with error #{magento_orders.count}"

    MagentoRestApi.new.write_magento_order_to_excel(magento_orders)

    sales_receipts = QuickbooksSalesReceipt.new.create_sales_receipts(run_report, magento_orders, AUTHENTICATION_QBO_PRO_DATA, production_access_token)
    puts "End of processing"
  end

  desc "get creditmemo list"
  task :creditmemo_from_magento => :environment do
    creditmemo_list = MagentoInvoiceSoapApi.new.get_creditmemo_from_soap_api(AUTHENTICATION_MAGENTO_STAGING_DATA)
    magento_orders = MagentoRestApi.new.order_data(AUTHENTICATION_MAGENTO_STAGING_DATA, creditmemo_list)
    MagentoRestApi.new.write_magento_order_to_excel(magento_orders)
  end

  desc "push all tax code from production into staging"
  task :push_all_tax_code => :environment do
    development_access_token = RecordToken.where(type_token: 'development').first
    production_access_token = RecordToken.where(type_token: 'production').first
    staging_access_token = RecordToken.where(type_token: 'staging').first

    tax_codes_collection = QuickbooksTaxes.new.get_all_tax_codes(AUTHENTICATION_QBO_PRO_DATA, production_access_token)
    tax_codes_with_agencies = QuickbooksTaxes.new.check_agency_name(AUTHENTICATION_QBO_PRO_DATA, production_access_token, tax_codes_collection)

    QuickbooksTaxes.new.push_production_taxes_to_staging(AUTHENTICATION_QBO_STAGING_DATA, development_access_token, tax_codes_with_agencies)
  end
end
