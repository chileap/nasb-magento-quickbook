class QuickbooksSalesReceipt
  include Concerns::QuickbooksApiToken
  include Concerns::QuickbooksCustomers
  include Concerns::QuickbooksLineItems

  BASE_URL = 'https://quickbooks.api.intuit.com/v3/company'

  def renew_token(authentication_data, token)
    @token = QuickbooksSalesReceipt.new.get_new_access_tokens(authentication_data, token)
  end

  def get_access_token(authentication_data, token)
    if token.token_expires_at < 30.days.from_now
      renew_token(authentication_data, token)
    end
    @token = token
    consumer = OAuth::Consumer.new(authentication_data[:consumer_key], authentication_data[:consumer_secret], {:site => "https://oauth.intuit.com"})
    @access_token = OAuth::AccessToken.new(consumer, token.access_token, token.access_secret)
  end

  def service_setting(type_service)
    type_service.access_token = @access_token
    type_service.company_id = @token.company_id
  end

  def item_service
    @item_service = Quickbooks::Service::Item.new
    service_setting(@item_service)
  end

  def customer_service
    @customer_service = Quickbooks::Service::Customer.new
    service_setting(@customer_service)
  end

  def sale_receipt_service
    @sale_receipt_service = Quickbooks::Service::SalesReceipt.new
    service_setting(@sale_receipt_service)
  end

  def pushing_sales_receipt_from_magento(run_report, orders_data, authentication_data, old_access_token)
    get_access_token(authentication_data, old_access_token)
    sale_receipt_service
    customer_service
    item_service

    list_of_customer_orders = QuickbooksSalesReceipt.new.get_qbo_customers_by(@customer_service, orders_data)

    if list_of_customer_orders.present?
      create_sales_receipts(list_of_customer_orders, run_report)
    end
  end

  def create_sales_receipts(list_of_customer_orders, run_report)
    @orders_data_pushed = {}
    list_of_customer_orders.each do |order|
      customer_receipt = check_if_sales_receipts_existed(order["customer_id"], "M-#{order["increment_id"]}")

      if customer_receipt.blank? && order["increment_id"].first(2) != '90'
        create_new_sales_receipts(order, run_report)
      else
        puts 'sales receipt already created'
        RunLog.where(order_id: order["entity_id"]).update_all(order_date: order["created_at"])
      end
    end
  end

  def check_if_sales_receipts_existed(customer_id, customer_memo)
    sales_receipts = @sale_receipt_service.query("select * from SalesReceipt where CustomerRef = '#{customer_id}'").entries
    sales_receipts.find{ |sales_receipt| sales_receipt.customer_memo == customer_memo }
  end

  def create_new_sales_receipts(order, run_report)
    check_tax = check_if_tax_existed(order["tax_name"], @token.company_id)

    if check_tax.present?
      result_data = sales_receipts_if_tax_existed(order, run_report)
    else
      puts "this #{order["entity_id"]} #{order["customer_id"]} is failed"
      sales_receipt_id = nil
      run_log = run_report.run_logs.create!(magento_id: order["increment_id"], order_id: order["entity_id"], status: 'failed', message: "Tax Name: #{order["tax_name"]} not found in QBO")
      result_data = {sales_receipt_id: sales_receipt_id, run_log: run_log}
    end

    write_receipts_into_excel(order["increment_id"], result_data)
    handle_with_orderlogs_and_runlogs(order, result_data)
  end

  def check_if_tax_existed(tax_name, company_id)
    if tax_name.present?
      query_end_point   = "#{BASE_URL}/#{company_id}"
      if tax_name == 'HST NB'
        tax_name = 'HST NB (13%25)'
      elsif tax_name == 'HST NL'
        tax_name = 'HST NL (13%25)'
      end
      tax_code_response = @access_token.get("#{query_end_point}/query?query=Select * from TaxCode where Name LIKE '#{tax_name}'")
      response_json     = Hash.from_xml(tax_code_response.body)['IntuitResponse']['QueryResponse']
    else
      check_tax = 'dont have tax'
    end
  end

  def sales_receipts_if_tax_existed(order, run_report)
    sales_receipt = Quickbooks::Model::SalesReceipt.new
    sales_receipt.customer_id = order["customer_id"]
    sales_receipt.txn_date = order["invoice_date"]
    sales_receipt.private_note = "M-#{order["increment_id"]}"
    sales_receipt.customer_memo = "M-#{order["increment_id"]}"
    sales_receipt.currency_id = order["base_currency_code"]

    total_amount = 0
    if order["tax_name"].present? && order["tax_rate"].present?
      tax_detail = { tax_name: order["tax_name"], tax_rate: order["tax_rate"], total_tax_amount: order["base_tax_amount"] }
      sales_receipt.txn_tax_detail = transaction_tax_detail(tax_detail)
      puts "#{order["tax_name"]} #{order["tax_rate"]}"
    else
      order["tax_name"] = 'Exempt'
    end

    if order["base_discount_amount"] != "0.0000"
      order["base_subtotal"] = order["base_subtotal"].to_f - order["base_discount_amount"].split('-')[1].to_f
    end

    product_name = identify_product_name(order["increment_id"])

    tax_info = { tax_name: order["tax_name"], tax_rate: order["tax_rate"] }
    service_with_token = { service: @item_service, company_id: @token.company_id, access_token: @access_token }

    product_line_item = QuickbooksSalesReceipt.new.line_item_details(service_with_token, order["base_subtotal"], product_name["product_name"], tax_info)
    total_amount = total_amount + order["base_subtotal"].to_f
    sales_receipt.line_items << product_line_item

    if order["base_shipping_amount"] != "0.0000"
      shipping_price = QuickbooksSalesReceipt.new.line_item_details(service_with_token, order["base_shipping_amount"], product_name["shipping_name"], tax_info)
      sales_receipt.line_items << shipping_price
      total_amount = total_amount + order["base_shipping_amount"].to_f
    end

    grand_total = order["base_total_paid"].to_f - order["base_tax_amount"].to_f
    grand_total = grand_total.round(2)

    if (grand_total > total_amount) && (grand_total != total_amount)
      processing_fee = grand_total - total_amount
      processing_price = QuickbooksSalesReceipt.new.line_item_details(service_with_token, processing_fee, product_name["processing_fee"], tax_info)
      sales_receipt.line_items << processing_price
    end

    begin
      sales_receipt_upload = @sale_receipt_service.create(sales_receipt)
      puts "#{sales_receipt_upload.id}  #{sales_receipt_upload.doc_number}  #{order["entity_id"]}  #{order["customer_id"]}"
      sales_receipt_id = sales_receipt_upload.id
      check_failed_run_log = RunLog.find_by(magento_id: order['increment_id'])
      if check_failed_run_log.present?
        run_log = check_failed_run_log.update_attributes(order_amount: order['base_grand_total'],credit_amount: sales_receipt_upload.total, order_status: order["status"], billing_name: sales_receipt_upload.customer_ref.name , magento_id: order["increment_id"], order_id: order["entity_id"], doc_number: sales_receipt_upload.doc_number, qbo_id: sales_receipt_upload.id, status: 'success', message: '', order_date: order["created_at"])
      else
        run_log = run_report.run_logs.create!(order_amount: order['base_grand_total'],credit_amount: sales_receipt_upload.total, order_status: order["status"], billing_name: sales_receipt_upload.customer_ref.name , magento_id: order["increment_id"], order_id: order["entity_id"], doc_number: sales_receipt_upload.doc_number, qbo_id: sales_receipt_upload.id, status: 'success', order_date: order["created_at"])
      end
    rescue Exception => e
      puts e.message
      puts "this #{order["entity_id"]} #{order["customer_id"]} is failed"
      sales_receipt_id = nil
      run_log = run_report.run_logs.create!(magento_id: order["increment_id"], order_id: order["entity_id"], status: 'failed', message: e.message)
    end
    result_data = {sales_receipt_id: sales_receipt_id, run_log: run_log}
  end

  def handle_with_orderlogs_and_runlogs(order, result_data)
    order_log = OrderLog.find_by(magento_id: order["increment_id"])
    if order_log.present?
      order_log.update_attributes(qbo_id: result_data[:run_log].qbo_id, last_runlog_id: result_data[:run_log].id)
    else
      OrderLog.create!(magento_id: order["increment_id"], order_id: order["entity_id"], qbo_id: result_data[:run_log].qbo_id, last_runlog_id: result_data[:run_log].id)
    end
  end

  def write_receipts_into_excel(increment_id, result_data)
    order_pushed = { increment_id: increment_id, qbo_id: result_data[:sales_receipt_id], result_data: result_data[:run_log] }
    @orders_data_pushed.merge!({"#{increment_id}" => order_pushed})
    write_magento_order_to_excel(@orders_data_pushed)
  end

  def write_magento_order_to_excel(orders)
    book = Spreadsheet::Workbook.new
    book.create_worksheet
    index = 0
    book.worksheet(0).insert_row(index, ['Magento No.', 'Quickbooks Sale Receipt ID', 'Error Message'])

    orders.each do |key, magento_order|
      puts key
      if magento_order[:result_data].status === 'success'
        book.worksheet(0).insert_row (index + 1), [magento_order[:increment_id], magento_order[:qbo_id],'']
      else
        book.worksheet(0).insert_row (index + 1), [magento_order[:increment_id], magento_order[:qbo_id], magento_order[:result_data].message]
      end
    end
    book.write "log/magento_try_run_oct.xls"
    puts "wrote to log/magento_try_run_oct.xls"
  end

  def transaction_tax_detail(tax_detail)
    tax_code = tax_code(tax_detail[:tax_name], tax_detail[:tax_rate])
    transaction_tax = Quickbooks::Model::TransactionTaxDetail.new
    transaction_tax.txn_tax_code_id = tax_code
    transaction_tax.total_tax = tax_detail[:total_tax_amount]
    transaction_tax
  end

  def tax_code(tax_name, tax_rate)
    # Check existing tax rate
    query_end_point   = "#{BASE_URL}/#{@token.company_id}"
    if tax_name == 'HST NB'
      tax_code_response = @access_token.get("#{query_end_point}/query?query=Select * from TaxRate WHERE Name LIKE 'HST NB (13%25)' AND RateValue = '#{tax_rate}'")
    elsif tax_name == 'HST NL'
      tax_code_response = @access_token.get("#{query_end_point}/query?query=Select * from TaxRate WHERE Name LIKE 'HST NL (13%25)' AND RateValue = '#{tax_rate}'")
    else
      tax_code_response = @access_token.get("#{query_end_point}/query?query=Select * from TaxRate where Name = '#{tax_name}' AND RateValue = '#{tax_rate}'")
    end
    tax_code          = Hash.from_xml(tax_code_response.body)['IntuitResponse']['QueryResponse']
    tax_code
  end

  def identify_product_name(magento_number)
    product_name = {}
    if magento_number.first(2) == '10'
      item_name = "Product Sale"
      shipping_name = "Shipping and Delivery Income"
      processing_fee = "Processing Fee - On Line"
    elsif magento_number.first(2) == '20'
      item_name = "Product Sale"
      shipping_name = "Shipping & Delivery Income"
      processing_fee = "Processing Fee - Phone Orders"
    elsif magento_number.first(2) == '30'
      item_name = "Product Sale"
      shipping_name = "Shipping & Delivery Income"
      processing_fee = "Processing Fee - Mail"
    elsif magento_number.first(2) == '40' || magento_number.first(2) == '70'
      item_name = 'Product Sale - CC Nexus'
      shipping_name = "Shipping & Delivery Income - CC Nexus"
      processing_fee = "Processing Fee - CC Nexus"
    elsif magento_number.first(2) == '50'
      item_name = 'Product Sale - Canuk'
      shipping_name = "Shipping & Delivery Income - Canuk"
      processing_fee = "Processing Fee - Canuk"
    else
      puts magento_number
      puts 'Invoive dose not exited!!!!'
    end
    product_name["processing_fee"] = processing_fee
    product_name["product_name"] = item_name
    product_name["shipping_name"] = shipping_name
    product_name
  end

  def delete_sales_reciept(magento_order_data, authentication_data, old_access_token)
    get_access_token(authentication_data, old_access_token)
    sale_receipt_service
    customer_service
    customers = {}
    magento_order_data.each do |k, order_items|
      display_name = "#{order_items["addresses"][0]["firstname"]} #{order_items["addresses"][0]["lastname"]}".squish
      display_name = display_name.gsub("'"){"\\'"}
      display_name = display_name.gsub("’"){"\\'"}
      if display_name == "珊珊 李"
        customer_id = '915'
      else
        customer_id = @customer_service.query("Select id From Customer where DisplayName = '#{display_name}'").entries.first.id
      end
      customers.merge!({"#{order_items["increment_id"]}" => {"customer_id" => "#{customer_id}", "customer_name" => "#{display_name}"}})
      puts k
    end
    customers.each do |key, customer|
      sales_receipts = @sale_receipt_service.query("select * from SalesReceipt where CustomerRef = '#{customer["customer_id"]}'").entries
      puts "=========================================================="
      puts "There are #{sales_receipts.count} sales_receipts of #{customer['customer_name']}"
      sales_receipts.each do |sales_receipt|
        if sales_receipt.customer_memo == "M-#{key}"
          puts "#{sales_receipt.id}  #{sales_receipt.customer_memo}  #{sales_receipt.doc_number}"
          begin
            @sale_receipt_service.delete(sales_receipt)
          rescue
            binding.pry
            puts "this #{sales_receipt.id} is failed"
          end
        end
      end
      puts "=========================================================="
    end
  end
end
