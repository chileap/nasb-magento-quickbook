module Concerns::QuickbooksLineItems
  BASE_URL = 'https://quickbooks.api.intuit.com/v3/company'.freeze

  def line_item_details(service_with_token, orders_type_price, item_type, tax_info)
    @item_service = service_with_token[:service]
    @company_id = service_with_token[:company_id]
    @access_token = service_with_token[:access_token]

    line_item = Quickbooks::Model::Line.new
    item_lists = @item_service.query("Select id From Item where name = '#{item_type}'").entries
    item = item_lists.first || create_new_item(item_type)
    line_item.amount = orders_type_price
    tax_type = tax_type_shipping_or_service(tax_info)

    line_item.sales_item! do |detail|
      detail.unit_price = orders_type_price
      detail.quantity = 1
      detail.item_id = item.id
      detail.tax_code_ref = Quickbooks::Model::BaseReference.new(tax_type)
    end
    line_item
  end

  def create_new_item(item_name)
    item = Quickbooks::Model::Item.new
    item.name = item_name
    ref_no = @item_service.query('Select * From Item').entries.last.income_account_ref['value']
    income_account_ref = ::Quickbooks::Model::BaseReference.new(ref_no)
    income_account_ref.name = 'Sales'
    item.income_account_ref = income_account_ref
    item.type = 'Service'
    @item_service.create(item)
  end

  def tax_type_shipping_or_service(tax_info)
    query_end_point = "#{BASE_URL}/#{@company_id}"
    tax_name = tax_info[:tax_name]
    if tax_name == 'HST NB'
      if tax_info[:tax_rate] == '13.0000'
        tax_name = 'HST NB (13%25)'
      elsif tax_info[:tax_rate] == '15.0000'
        tax_name = 'HST NB 2016'
      end
    elsif tax_name == 'HST NL'
      if tax_info[:tax_rate] == '13.0000'
        tax_name = 'HST NL (13%25)'
      elsif tax_info[:tax_rate] == '15.0000'
        tax_name = 'HST NL 2016'
      end
    end
    tax_code_response = @access_token.get("#{query_end_point}/query?query=Select * from TaxCode where Name LIKE '#{tax_name}'")
    tax_code = Hash.from_xml(tax_code_response.body)['IntuitResponse']['QueryResponse']['TaxCode']
    if tax_code.class == Array
      tax_code[0]['Id']
    else
      tax_code['Id']
    end
    tax_code
  end
end
