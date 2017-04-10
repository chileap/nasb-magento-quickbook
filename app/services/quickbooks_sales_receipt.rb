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
    consumer=OAuth::Consumer.new(authentication_data[:consumer_key], authentication_data[:consumer_secret], {:site => "https://oauth.intuit.com"})
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

  def check_if_sales_receipts_existed(customer_id, customer_memo)
    sales_receipts = @sale_receipt_service.query("select * from SalesReceipt where CustomerRef = '#{customer_id}'").entries
    sales_receipts.find{ |sales_receipt| sales_receipt.customer_memo == customer_memo }
  end

  def create_sales_receipts(run_report, orders_data, authentication_data, old_access_token)
    get_access_token(authentication_data, old_access_token)
    sale_receipt_service
    customer_service
    item_service

    list_of_customer_orders = QuickbooksSalesReceipt.new.get_qbo_customers_by(@customer_service, orders_data)
    orders_data_pushed = {}

    if list_of_customer_orders.present?
      list_of_customer_orders.each do |order|
        customer_receipt = check_if_sales_receipts_existed(order["customer_id"], "M-#{order["increment_id"]}")

        if customer_receipt.blank?
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
            run_log = run_report.run_logs.create!(magento_id: order["increment_id"], qbo_id: sales_receipt_upload.id, status: 'success')
          rescue Exception => e
            puts e.message
            puts "this #{order["entity_id"]} #{order["customer_id"]} is failed"
            run_log = run_report.run_logs.create!(magento_id: order["increment_id"], status: 'failed', message: e.message)
          end

          order_pushed = { increment_id: order["increment_id"], qbo_id: sales_receipt_upload.id }
          orders_data_pushed.merge!({"#{order["increment_id"]}" => order_pushed})

          order_log = OrderLog.find_by(magento_id: order["increment_id"])
          if order_log.present?
            order_log.update_attributes(qbo_id: run_log.qbo_id, last_runlog_id: run_log.id)
          else
            OrderLog.create!(magento_id: order["increment_id"], qbo_id: run_log.qbo_id, last_runlog_id: run_log.id)
          end

        else
          puts 'sales receipt already created'
        end
      end
      write_magento_order_to_excel(orders_data_pushed)
    end
  end

  def write_magento_order_to_excel(orders)
    book = Spreadsheet::Workbook.new
    book.create_worksheet
    index = 0
    book.worksheet(0).insert_row(index, ['Magento No.', 'Quickbooks ID'])

    orders.each do |key, magento_order|
      puts key
      book.worksheet(0).insert_row (index + 1), [magento_order[:increment_id], magento_order[:qbo_id]]
    end
    book.write "log/magento_try_run_31_aug.xls"
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
    query_end_point   = "#{BASE_URL}/#{@token[:realm_id]}"
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
