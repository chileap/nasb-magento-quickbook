module Concerns::QuickbooksCustomers

  def get_qbo_customers_by(customer_service, magento_order_data)
    @customer_service = customer_service
    list_of_customers_name = get_existed_customers
    customers = []
    magento_order_data.each do |k, order_items|
      display_name = "#{order_items["addresses"][0]["firstname"]} #{order_items["addresses"][0]["lastname"]}".squish
      display_name = display_name.gsub("’"){"'"}
      create_new_customer(order_items, display_name, list_of_customers_name)
      display_name = display_name.gsub("'"){"\\'"}
      if display_name == 'Sinan Daş'
        customer_id = '295' if Rails.env == 'staging'
        customer_id = '2876' if Rails.env == 'production'
      elsif display_name == 'james Daʀʀօա'
        customer_id = '3606' if Rails.env == 'staging'
        customer_id = '2877' if Rails.env == 'production'
      else
        customer_id = @customer_service.query("Select id From Customer where DisplayName = '#{display_name}'").entries.first.id
      end
      order_items["customer_id"] = customer_id
      customers.push(order_items)
      puts "#{display_name} #{k} #{order_items["customer_id"]}"
    end
    customers
  end

  def get_existed_customers
    list_of_customers_name = []
    customer_displayname = []
    i = 1
    get_customers_per_page = @customer_service.query("Select DisplayName From Customer", :page => i, :per_page => 1000).entries
    while get_customers_per_page != []
      puts "page #{i}"
      customer_displayname.push(get_customers_per_page)
      i = i + 1
      get_customers_per_page = @customer_service.query("Select DisplayName From Customer", :page => i, :per_page => 1000).entries
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
      if display_name == "珊珊 李"
        binding.pry
      end
      begin
        customer = @customer_service.create(customer)
      rescue Exception => e
        binding.pry
      end
      array_name.push(display_name.downcase)
    end
  end

  def customer_detail(customer_detail, display_name)
    customer_model = Quickbooks::Model::Customer.new
    customer_model.display_name = display_name
    if customer_detail["addresses"][0]["email"].present?
      customer_model.primary_email_address = Quickbooks::Model::EmailAddress.new(customer_detail["addresses"][0]["email"])
    end

    telephones = customer_detail["addresses"][0]["telephone"].split('/')
    telephones = customer_detail["addresses"][0]["telephone"].split(',')
    if customer_detail["addresses"][0]["telephone"].split(' ').second.present? and customer_detail["addresses"][0]["telephone"].split(' ').second.match(/^[[:alpha:]]+$/).present?
      telephones = customer_detail["addresses"][0]["telephone"].split(' ').first
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
    address.line1 = customer_detail["addresses"][0]["street"]
    address.city = customer_detail["addresses"][0]["city"]
    address.country_sub_division_code = customer_detail["addresses"][0]["country_id"]
    address.postal_code = customer_detail["addresses"][0]["postcode"]
    customer_model.billing_address = address
    customer_model.shipping_address = address

    customer_model
  end
end
