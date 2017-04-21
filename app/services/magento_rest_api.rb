class MagentoRestApi
  include Concerns::MagentoRestApiToken

  def auth_token(authentication_data)
    token = MagentoRestApi.new.get_new_access_tokens(authentication_data)
    consumer = ::OAuth::Consumer.new(authentication_data[:consumer_key], authentication_data[:consumer_secret], {:site => authentication_data[:url]})
    @access_token = OAuth::AccessToken.new(consumer, "#{token.token}", "#{token.secret}")
  end

  def order_data(authentication_data, lists)
    auth_token(authentication_data)
    orders = {}
    magento_order_ids = lists.map{|list| {increment_id: list[:increment_id], created_at: list[:created_at], grand_total: list[:grand_total] }}
    magento_order_ids.each do |magento_order_id|
      puts magento_order_id
      order = @access_token.get("/api/rest/orders?filter[1][attribute]=increment_id&filter[1][in]=#{magento_order_id[:increment_id]}")
      order = JSON.parse(order.body)
      order.each do |key, order_data|
        order_data["invoice_date"] = magento_order_id[:created_at]
        order_data["invoice_grand_total"] = magento_order_id[:grand_total]
      end
      orders.merge!(order)
    end
    write_order_json(orders)
    orders
  end

  def write_magento_order_to_excel(orders)
    book = Spreadsheet::Workbook.new
    book.create_worksheet
    index = 0
    book.worksheet(0).insert_row(index, ['Magento No.'])

    orders.each do |key, magento_order|
      puts key
      book.worksheet(0).insert_row (index + 1), [magento_order["increment_id"]]
    end
    book.write "log/magento_try_run_#{Time.now.strftime("%d-%m-%Y-%H-%M-%S")}.xls"
  end

  def write_order_json(key_json)
    File.open("log/magento_data_orders_#{Time.now.strftime("%d-%m-%Y-%H-%M-%S")}.json", 'w') do |file|
      file << JSON.pretty_generate(key_json)
    end
  end

  def get_specific_magento_order(authentication_data, increment_id)
    auth_token(authentication_data)
    puts "get magento Id #{increment_id}"
    orders = @access_token.get("/api/rest/orders?filter[0][attribute]=increment_id&filter[0][in]=#{increment_id}")
    orders_json = JSON.parse(orders.body)
    orders_json
  end
end
