class MagentoQboMethods
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

  def push_one_receipt_from_error_order(increment_id)
    authentication_data = check_environment_authentication(Rails.env)

    order = MagentoRestApi.new.get_specific_magento_order(authentication_data[:magento_auth], increment_id)
    run_report = Run.create!(run_date: DateTime.now, start_date: order['invoice_date'].in_time_zone('UTC').in_time_zone('America/Toronto').strftime('%Y-%m-%d %H:%M:%S %z'), end_date: order['invoice_date'].in_time_zone('UTC').in_time_zone('America/Toronto').strftime('%Y-%m-%d %H:%M:%S %z'))
    QuickbooksSalesReceipt.new.create_new_sales_receipts(order, run_report)
  end

  def push_qbo_receipts_from_magento_orders(date_range, authentication_data, environment, run_report)
    access_token = RecordToken.where(type_token: environment).first
    include_stores = Store.where(checked: false).pluck(:name)
    include_status = State.where(checked: true).pluck(:name)

    puts 'Start running pusing sale receipt'
    magento_orders = get_orders_from_magento(authentication_data[:magento_auth], date_range)

    magento_order_without_store_name = []

    if !magento_orders.nil?
      magento_orders.map do |order|
        store_name = order.last['store_name']
        store_status = order.last['status'].titleize
        if include_stores.include?store_name and include_status.include?store_status
          magento_order_without_store_name.push(order)
          puts "#{store_name} => #{store_status}"
        else
          run_log = RunLog.find_by(magento_id: order.last["increment_id"])
          if include_stores.include?store_name && run_log.nil?
            message = "Unable to push order to QBO due to invalid status `#{order.last['status'].titleize}`"
            run_log = run_report.run_logs.create!(magento_id: order.last["increment_id"], order_id: order.last["entity_id"], status: 'failed', message: message)
            OrderLog.create!(magento_id: order.last["increment_id"], order_id: order.last["entity_id"], last_runlog_id: run_log.id)
            puts "#{store_name} => #{store_status}"
          end
        end
      end
    end

    if !magento_order_without_store_name.nil? && magento_order_without_store_name.count > 0
      failed_and_active_orders = []
      count = 0
      magento_order_without_store_name.map do |order|
        record_log = RunLog.where(magento_id: order.last["increment_id"]).where(status: 'success')
        if record_log.count == 0
          failed_and_active_orders = failed_and_active_orders.push(order)
        end
        puts count = count + 1
      end
      puts "Total Failed & Active records => #{failed_and_active_orders.count}"
      QuickbooksSalesReceipt.new.pushing_sales_receipt_from_magento(run_report, failed_and_active_orders, authentication_data[:qbo_auth], access_token)
    end
    puts 'End of sale receipt processing'
  end

  def push_qbo_credit_memos_from_magento_orders(date_range, authentication_data, environment, run_report)
    access_token = RecordToken.where(type_token: environment).first
    include_stores = Store.where(checked: false).pluck(:name)

    puts 'Start running pushing credit memo'
    magento_credit_memo = get_credit_memos_from_magento(authentication_data[:magento_auth], date_range)

    if !magento_credit_memo.nil? && magento_credit_memo.count > 0
      magento_order_without_store_name = []
      magento_credit_memo.map do |order|
        store_name = order.last['store_name']
        store_status = order.last['status'].titleize
        if include_stores.include?store_name
          magento_order_without_store_name.push(order)
          puts "#{store_name} => #{store_status}"
        end
      end

      QuickbooksRefundReceipt.new.pushing_refund_receipt_from_magento(run_report, magento_order_without_store_name, authentication_data[:qbo_auth], access_token)
    end
    puts 'End of create refund receipt processing'
  end

  def push_qbo_refund_receipt_from_magento_orders(date_range, authentication_data, environment, run_report)
    
  end

  def get_credit_memos_from_magento(authentication_magento_data, date_range)
    puts 'find error from last pushing'
    errors_orders = OrderLog.where(run_type: 'credit_memo').get_error_orders(authentication_magento_data)
    puts "end of finding. There are #{errors_orders.count} error from last time"

    puts 'get order from magento that need to push today'
    invoice_list = MagentoInvoiceSoapApi.new.get_creditmemo_from_soap_api(authentication_magento_data, start_date: date_range[0].in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S %Z'), end_date: date_range[1].in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S %Z'))
    if invoice_list.instance_of? Hash 
      invoice_list = [invoice_list]
    end

    if invoice_list.nil?
      puts "Refund order of #{date_range[0]} to #{date_range[1]} are empty"
      magento_credit_memo = invoice_list
    else
      puts invoice_list.count
      magento_credit_memo = MagentoRestApi.new.order_data(authentication_magento_data, invoice_list)

      magento_credit_memo.merge!(errors_orders)
      MagentoRestApi.new.write_magento_order_to_excel(magento_credit_memo)
      puts "total credits memo with error #{magento_credit_memo.count}"
      magento_credit_memo
    end
  end

  def get_orders_from_magento(authentication_magento_data, date_range)
    puts 'find error from last pushing'
    errors_orders = OrderLog.get_error_orders(authentication_magento_data)
    puts "end of finding. There are #{errors_orders.count} error from last time"

    puts 'get order from magento that need to push today'
    invoice_list = MagentoInvoiceSoapApi.new.get_invoice_shipment_from_soap_api(authentication_magento_data, start_date: date_range[0].in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S %Z'), end_date: date_range[1].in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S %Z'))
   
    if invoice_list.nil?
      puts "Sale order of #{date_range[0]} to #{date_range[1]} are empty"
      magento_orders = invoice_list
    else
      puts invoice_list.count

      magento_orders = MagentoRestApi.new.order_shipment_data(authentication_magento_data, invoice_list)
      magento_orders.merge!(errors_orders)
      puts "total order with error #{magento_orders.count}"
      magento_orders
    end
  end

  def check_environment_authentication(environment)
    if environment == 'development'
      { magento_auth: AUTHENTICATION_MAGENTO_PRO_DATA, qbo_auth: AUTHENTICATION_QBO_DEVELOPMENT_DATA }
    elsif environment == 'staging'
      { magento_auth: AUTHENTICATION_MAGENTO_STAGING_DATA, qbo_auth: AUTHENTICATION_QBO_STAGING_DATA }
    else
      { magento_auth: AUTHENTICATION_MAGENTO_PRO_DATA, qbo_auth: AUTHENTICATION_QBO_PRO_DATA }
    end
  end
end
