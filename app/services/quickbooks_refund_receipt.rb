class QuickbooksRefundReceipt
  include Concerns::QuickbooksApiToken
  include Concerns::QuickbooksCustomers
  include Concerns::QuickbooksLineItems

  BASE_URL = 'https://quickbooks.api.intuit.com/v3/company'

  def renew_token(authentication_data, token)
    @token = QuickbooksRefundReceipt.new.get_new_access_tokens(authentication_data, token)
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

  def refund_receipt_service
    @refund_receipt_service = Quickbooks::Service::RefundReceipt.new
    service_setting(@refund_receipt_service)
  end

  def pushing_refund_receipt_from_magento(run_report, orders_data, authentication_data, old_access_token)
    get_access_token(authentication_data, old_access_token)
    refund_receipt_service
    customer_service
    item_service

    list_of_customer_orders = QuickbooksRefundReceipt.new.get_qbo_customers_by(@customer_service, orders_data)

    if list_of_customer_orders.present?
      create_refund_receipt(list_of_customer_orders, run_report)
    end
  end

  def create_refund_receipt(list_of_customer_orders, run_report)
    @orders_data_pushed = {}
    list_of_customer_orders.each do |order|
      customer_receipt = check_if_refund_receipt_existed(order["customer_id"], "C-#{order["increment_id"]}")

      if customer_receipt.blank?
        create_new_refund_receipt(order, run_report)
      else
        puts 'refund receipt already created'
      end
    end
  end

  def check_if_refund_receipt_existed(customer_id, customer_refund)
    refunds = @refund_receipt_service.query("select * from RefundReceipt where id = '#{customer_refund.id}'").entries
    refunds.find{ |refund_receipt| refund_receipt.customer_refund == customer_refund }
  end

  def create_new_refund_receipt(order, run_report)
    check_tax = check_if_tax_existed(order["tax_name"], @token.company_id)

    if check_tax.present?
      result_data = refund_receipt_if_tax_existed(order, run_report)
    else
      puts "this #{order["entity_id"]} #{order["customer_id"]} is failed"
      refund_receipt_id = nil
      run_log = run_report.run_logs.create!(magento_id: order["increment_id"], order_id: order["entity_id"], status: 'failed', message: "Tax Name: #{order["tax_name"]} not found in QBO", run_type: 'credit_memo')
      result_data = {refund_receipt_id: refund_receipt_id, run_log: run_log}
    end

    write_refund_receipt_into_excel(order["increment_id"], result_data)
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

  def refund_receipt_if_tax_existed(order, run_report)
    refund_receipt = Quickbooks::Model::RefundReceipt.new
    refund_receipt.customer_id = order["customer_id"]
    refund_receipt.txn_date = order["invoice_date"]
    refund_receipt.private_note = "C-#{order["increment_id"]}"
    refund_receipt.customer_memo = "C-#{order["increment_id"]}"
    refund_receipt.currency_id = order["base_currency_code"]
    refund_receipt.deposit_to_account_ref = Quickbooks::Model::BaseReference.new('4', name: 'Undeposited Funds')
    total_amount = 0
    total_refunded = 0

    if order["tax_name"].present? && order["tax_rate"].present?
      tax_detail = { tax_name: order["tax_name"], tax_rate: order["tax_rate"], total_tax_amount: order["base_tax_amount"] }
      refund_receipt.txn_tax_detail = transaction_tax_detail(tax_detail)
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
          refunded_amount = item["base_price"].to_f * item["qty_refunded"].to_i
          total_refunded = total_refunded + refunded_amount
          if item["base_discount_amount"] != "0.0000"
            total_refunded = total_refunded - item["base_discount_amount"].to_f
          end
        end
      end
    end

    product_line_item = QuickbooksRefundReceipt.new.line_item_details(service_with_token, total_refunded.round(2), product_name["product_name"], tax_info)
    total_amount = total_amount + order["base_subtotal"].to_f
    refund_receipt.line_items << product_line_item

    # Check if orders got shipped or not
    ship_qty = "0.0000"

    if order["base_shipping_amount"] != "0.0000"
      if order["status"] == "closed"
        if !order['order_items'].pluck('qty_shipped').any?{|qty| qty != ship_qty}
          shipping_price = QuickbooksRefundReceipt.new.line_item_details(service_with_token, order["base_shipping_amount"], product_name["shipping_name"], tax_info)
          refund_receipt.line_items << shipping_price
        end
      end
      total_amount = total_amount + order["base_shipping_amount"].to_f
    end

    grand_total = order["base_total_paid"].to_f - order["base_tax_amount"].to_f
    grand_total = grand_total.round(2)

    if (grand_total > total_amount) && (grand_total != total_amount)
      processing_fee = grand_total - total_amount
      processing_price = QuickbooksRefundReceipt.new.line_item_details(service_with_token, processing_fee, product_name["processing_fee"], tax_info)
      refund_receipt.line_items << processing_price
    end

    begin
      refund_receipt_upload = @refund_receipt_service.create(refund_receipt)
      puts "#{refund_receipt_upload.id}  #{refund_receipt_upload.doc_number}  #{order["entity_id"]}  #{order["customer_id"]}"
      credit_memo_id = refund_receipt_upload.id
      run_log = run_report.run_logs.create!(credit_amount: refund_receipt_upload.total,order_status: order["status"],billing_name: refund_receipt_upload.customer_ref.name,magento_id: order["increment_id"], order_id: order["entity_id"], qbo_id: refund_receipt_upload.id, status: 'success', run_type: 'credit_memo', doc_number: refund_receipt_upload.doc_number)
    rescue Exception => e
      puts e.message
      puts "this #{order["entity_id"]} #{order["customer_id"]} is failed"
      refund_receipt_id = nil
      run_log = run_report.run_logs.create!(magento_id: order["increment_id"], order_id: order["entity_id"], status: 'failed', message: e.message, run_type: 'refund_receipt')
    end
    result_data = {refund_receipt_id: refund_receipt_id, run_log: run_log}
  end

  def handle_with_orderlogs_and_runlogs(order, result_data)
    order_log = OrderLog.find_by(magento_id: order["increment_id"])
    if order_log.present?
      order_log.update_attributes(qbo_id: result_data[:run_log].qbo_id, last_runlog_id: result_data[:run_log].id)
    else
      OrderLog.create!(magento_id: order["increment_id"], order_id: order["entity_id"], qbo_id: result_data[:run_log].qbo_id, last_runlog_id: result_data[:run_log].id, run_type: 'refund_receipt')
    end
  end

  def write_refund_receipt_into_excel(increment_id, result_data)
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
