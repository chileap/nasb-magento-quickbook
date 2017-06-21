class QuickbooksCreditsMemo
  include Concerns::QuickbooksApiToken
  include Concerns::QuickbooksCustomers
  include Concerns::QuickbooksLineItems

  BASE_URL = 'https://quickbooks.api.intuit.com/v3/company'

  def renew_token(authentication_data, token)
    @token = QuickbooksCreditsMemo.new.get_new_access_tokens(authentication_data, token)
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

  def credit_memo_service
    @credit_memo_service = Quickbooks::Service::CreditMemo.new
    service_setting(@credit_memo_service)
  end

  def pushing_credit_memo_from_magento(run_report, orders_data, authentication_data, old_access_token)
    get_access_token(authentication_data, old_access_token)
    credit_memo_service
    customer_service
    item_service

    list_of_customer_orders = QuickbooksCreditsMemo.new.get_qbo_customers_by(@customer_service, orders_data)

    if list_of_customer_orders.present?
      create_credit_memo(list_of_customer_orders, run_report)
    end
  end

  def create_credit_memo(list_of_customer_orders, run_report)
    @orders_data_pushed = {}
    list_of_customer_orders.each do |order|
      customer_receipt = check_if_credit_memo_existed(order["customer_id"], "C-#{order["increment_id"]}")

      if customer_receipt.blank?
        create_new_credit_memos(order, run_report)
      else
        puts 'credit memo already created'
      end
    end
  end

  def check_if_credit_memo_existed(customer_id, customer_memo)
    credit_memos = @credit_memo_service.query("select * from CreditMemo where CustomerRef = '#{customer_id}'").entries
    credit_memos.find{ |credit_memo| credit_memo.customer_memo == customer_memo }
  end

  def create_new_credit_memos(order, run_report)
    check_tax = check_if_tax_existed(order["tax_name"], @token.company_id)

    if check_tax.present?
      result_data = credit_memos_if_tax_existed(order, run_report)
    else
      puts "this #{order["entity_id"]} #{order["customer_id"]} is failed"
      credit_memo_id = nil
      run_log = run_report.run_logs.create!(magento_id: order["increment_id"], order_id: order["entity_id"], status: 'failed', message: "Tax Name: #{order["tax_name"]} not found in QBO", run_type: 'credit_memo')
      result_data = {credit_memo_id: credit_memo_id, run_log: run_log}
    end

    write_credit_memos_into_excel(order["increment_id"], result_data)
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

  def credit_memos_if_tax_existed(order, run_report)
    credit_memo = Quickbooks::Model::CreditMemo.new
    credit_memo.customer_id = order["customer_id"]
    credit_memo.txn_date = order["invoice_date"]
    credit_memo.private_note = "C-#{order["increment_id"]}"
    credit_memo.customer_memo = "C-#{order["increment_id"]}"
    credit_memo.currency_id = order["base_currency_code"]
    total_amount = 0
    total_refunded = 0

    if order["tax_name"].present? && order["tax_rate"].present?
      tax_detail = { tax_name: order["tax_name"], tax_rate: order["tax_rate"], total_tax_amount: order["base_tax_amount"] }
      credit_memo.txn_tax_detail = transaction_tax_detail(tax_detail)
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

    order["order_items"].map do |item|
      if item["base_row_total_incl_tax"] != "0.0000"
        if item["qty_refunded"] != "0.0000"
          refunded_amount = item["base_original_price"].to_f * item["qty_refunded"].to_i
          total_refunded = total_refunded + refunded_amount
          if item["base_discount_amount"] != "0.0000"
            total_refunded = total_refunded - item["base_discount_amount"].to_f
          end
        end
      end
    end

    product_line_item = QuickbooksCreditsMemo.new.line_item_details(service_with_token, total_refunded, product_name["product_name"], tax_info)
    total_amount = total_amount + order["base_subtotal"].to_f
    credit_memo.line_items << product_line_item

    if order["base_shipping_amount"] != "0.0000"
      total_amount = total_amount + order["base_shipping_amount"].to_f
    end

    grand_total = order["base_total_paid"].to_f - order["base_tax_amount"].to_f
    grand_total = grand_total.round(2)

    if (grand_total > total_amount) && (grand_total != total_amount)
      processing_fee = grand_total - total_amount
      processing_price = QuickbooksCreditsMemo.new.line_item_details(service_with_token, processing_fee, product_name["processing_fee"], tax_info)
      credit_memo.line_items << processing_price
    end

    begin
      credit_memo_upload = @credit_memo_service.create(credit_memo)
      puts "#{credit_memo_upload.id}  #{credit_memo_upload.doc_number}  #{order["entity_id"]}  #{order["customer_id"]}"
      credit_memo_id = credit_memo_upload.id
      run_log = run_report.run_logs.create!(magento_id: order["increment_id"], order_id: order["entity_id"], qbo_id: credit_memo_upload.id, status: 'success', run_type: 'credit_memo')
    rescue Exception => e
      puts e.message
      puts "this #{order["entity_id"]} #{order["customer_id"]} is failed"
      credit_memo_id = nil
      run_log = run_report.run_logs.create!(magento_id: order["increment_id"], order_id: order["entity_id"], status: 'failed', message: e.message, run_type: 'credit_memo')
    end
    result_data = {credit_memo_id: credit_memo_id, run_log: run_log}
  end

  def handle_with_orderlogs_and_runlogs(order, result_data)
    order_log = OrderLog.find_by(magento_id: order["increment_id"])
    if order_log.present?
      order_log.update_attributes(qbo_id: result_data[:run_log].qbo_id, last_runlog_id: result_data[:run_log].id)
    else
      OrderLog.create!(magento_id: order["increment_id"], order_id: order["entity_id"], qbo_id: result_data[:run_log].qbo_id, last_runlog_id: result_data[:run_log].id, run_type: 'credit_memo')
    end
  end

  def write_credit_memos_into_excel(increment_id, result_data)
    order_pushed = { increment_id: increment_id, qbo_id: result_data[:credit_memo_id], result_data: result_data[:run_log] }
    @orders_data_pushed.merge!({"#{increment_id}" => order_pushed})
    write_magento_order_to_excel(@orders_data_pushed)
  end

  def write_magento_order_to_excel(orders)
    book = Spreadsheet::Workbook.new
    book.create_worksheet
    index = 0
    book.worksheet(0).insert_row(index, ['Magento No.', 'Quickbooks Credit Memo ID', 'Error Message'])

    orders.each do |key, magento_order|
      puts key
      if magento_order[:result_data].status === 'success'
        book.worksheet(0).insert_row (index + 1), [magento_order[:increment_id], magento_order[:qbo_id],'']
      else
        book.worksheet(0).insert_row (index + 1), [magento_order[:increment_id], magento_order[:qbo_id], magento_order[:result_data].message]
      end
    end
    book.write "log/magento_try_run_credit_memo.xls"
    puts "wrote to log/magento_try_run_credit_memo.xls"
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
    elsif magento_number.first(2) == '40'
      item_name = 'Product Sale - CC Nexus'
      shipping_name = "Shipping & Delivery Income - CC Nexus"
      processing_fee = "Processing Fee - CC Nexus"
    elsif magento_number.first(2) == '50'
      item_name = 'Product Sale - Canuk'
      shipping_name = "Shipping & Delivery Income - Canuk"
      processing_fee = "Processing Fee - Canuk"
    end
    product_name["processing_fee"] = processing_fee
    product_name["product_name"] = item_name
    product_name["shipping_name"] = shipping_name
    product_name
  end

end
