module Concerns::QuickbooksCustomers
  def get_qbo_customers_by(customer_service, magento_order_data)
    @customer_service = customer_service
    list_of_customers_name = get_existed_customers
    customers = []
    magento_order_data.each do |k, order_items|
      display_name = "#{order_items['addresses'][0]['firstname']} #{order_items['addresses'][0]['lastname']}".squish
      display_name = display_name.gsub('~@~Y') { "'" }
      gcName = display_name.gsub("'") { "\\'" }

      if gcName.downcase == 'mark brown'
        display_name = 'Mark Brown Co.'
      elsif gcName.downcase == 'rob stevenson'
        display_name = 'Rob Stevenson Co.'
      end

      puts "===========**==========="
      puts "GcName => #{gcName}"
      puts display_name

      create_new_customer(order_items, display_name, list_of_customers_name)
      display_name = display_name.gsub("'") { "\\'" }

      if display_name == 'Sinan Da~_'
        customer_id = '295' if Rails.env == 'staging'
        customer_id = '2876' if Rails.env == 'production'
      elsif display_name == 'james Da~@~@~Eա'
        customer_id = '3606' if Rails.env == 'staging'
        customer_id = '2877' if Rails.env == 'production'
      elsif display_name == 'Chris Davidson~@~K'
        customer_id = '12464'
      elsif display_name == 'Chris Davidson'
        customer_id = '12464'
      else
        puts "finding customer id"
        customer_id = @customer_service.query("Select id From Customer where DisplayName = '#{display_name}'").entries.first.id
      end
      order_items['customer_id'] = customer_id
      customers.push(order_items)
      puts "#{display_name} #{k} #{order_items['customer_id']}"
      puts "=========end==========="
    end
    customers
  end

  def get_existed_customers
    list_of_customers_name = []
    customer_displayname = []
    i = 1
    get_customers_per_page = @customer_service.query('Select DisplayName From Customer', page: i, per_page: 1000).entries
    while get_customers_per_page != []
      puts "page #{i}"
      customer_displayname.push(get_customers_per_page)
      i += 1
      get_customers_per_page = @customer_service.query('Select DisplayName From Customer', page: i, per_page: 1000).entries
    end
    customer_displayname.flatten!
    customer_displayname.each do |name|
      list_of_customers_name.push(name.display_name.downcase)
    end
    list_of_customers_name
  end

  def create_new_customer(order_items, display_name, array_name)
    if array_name.empty? || !array_name.include?(display_name.downcase)
      customer = customer_detail(order_items, display_name)
      begin
        @customer_service.create(customer)
      rescue StandardError => e
        puts e
      end
      array_name.push(display_name.downcase)
    end
  end

  def customer_detail(customer_detail, display_name)
    customer_model = Quickbooks::Model::Customer.new
    customer_model.display_name = display_name

    if customer_detail['addresses'][0]['email'].present?
      customer_model.primary_email_address = Quickbooks::Model::EmailAddress.new(customer_detail['addresses'][0]['email'])
    end

    telephones = customer_detail['addresses'][0]['telephone'].split(',') || customer_detail['addresses'][0]['telephone'].split('/')
    if customer_detail['addresses'][0]['telephone'].split(' ').second.present?
      telephones = customer_detail['addresses'][0]['telephone'].split(' ').first if customer_detail['addresses'][0]['telephone'].split(' ').second.match(/^[[:alpha:]]+$/).present?
    end
    phone = Quickbooks::Model::TelephoneNumber.new
    phone.free_form_number = telephones[0].gsub('or', '').squish
    customer_model.primary_phone = phone
    if telephones.class != String
      if telephones.length > 1
        telephones.each_with_index do |telephone, index|
          if index == 1
            phone = Quickbooks::Model::TelephoneNumber.new
            phone.free_form_number = telephone.gsub('or', '').squish
            customer_model.alternate_phone = phone
          elsif index == 2
            phone = Quickbooks::Model::TelephoneNumber.new
            phone.free_form_number = telephone.gsub('or', '').squish
            customer_model.mobile_phone = phone
          end
        end
      end
    end

    address = Quickbooks::Model::PhysicalAddress.new
    address.line1 = customer_detail['addresses'][0]['street']
    address.city = customer_detail['addresses'][0]['city']
    address.country_sub_division_code = customer_detail['addresses'][0]['country_id']
    address.postal_code = customer_detail['addresses'][0]['postcode']
    customer_model.billing_address = address
    customer_model.shipping_address = address

    customer_model
  end
end
