class QuickbooksTaxes
  include Concerns::QuickbooksApiToken

  BASE_URL = 'https://quickbooks.api.intuit.com/v3/company'

  def renew_token(authentication_data, token)
    @token = QuickbooksTaxes.new.get_new_access_tokens(authentication_data, token)
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
    puts @token.company_id
  end

  def tax_code_service
    @tax_code_service = Quickbooks::Service::TaxCode.new
    service_setting(@tax_code_service)
  end

  def tax_rate_service
    @tax_rate_service = Quickbooks::Service::TaxRate.new
    service_setting(@tax_rate_service)
  end

  def taxservice_service
    @taxservice_service = Quickbooks::Service::TaxService.new
    service_setting(@taxservice_service)
  end

  def tax_agency_service
    @tax_agency_service = Quickbooks::Service::TaxAgency.new
    service_setting(@tax_agency_service)
  end

  def get_all_tax_codes(authentication_data, old_access_token)
    get_access_token(authentication_data, old_access_token)
    tax_code_service
    tax_codes_collection = []
    page_num = 1
    tax_codes = @tax_code_service.query('Select * from TaxCode', :page => page_num, :per_page => 45)
    tax_codes_collection.concat(tax_codes.entries)

    while tax_codes.count != 0
      page_num = page_num + 1
      tax_codes = @tax_code_service.query('Select * from TaxCode', :page => page_num, :per_page => 45)
      tax_codes_collection.concat(tax_codes.entries)
    end
    tax_codes_collection
  end

  def get_tax_rate_details(tax_rate_id)
    tax_rate_detail = @tax_rate_service.query("Select * from TaxRate where Id = '#{tax_rate_id}'").entries.first
    tax_agency_detail = @tax_agency_service.query("Select * from TaxAgency where Id = '#{tax_rate_detail.agency_ref.value}'").entries.first
    tax_rate = { tax_rate: tax_rate_detail, tax_agency: tax_agency_detail }
  end

  def check_agency_name(authentication_data, old_access_token, tax_codes_collection)
    get_access_token(authentication_data, old_access_token)
    tax_agency_service
    tax_rate_service
    production_tax_codes_collection = {}
    tax_codes_collection.each do |tax_code|
      tax_code_name = tax_code.name
      sales_tax_rates = {}
      purchase_tax_rates = {}
      if tax_code.sales_tax_rate_list.present?
        sales_tax_rate_details = tax_code.sales_tax_rate_list["tax_rate_detail"]
        sales_tax_rate_details.each do |sales_tax_rate|
          tax_rate_id = sales_tax_rate.tax_rate_ref["value"]
          tax_rate_name = sales_tax_rate.tax_rate_ref["name"].gsub("\"", '')
          sales_tax_rate_detail = get_tax_rate_details(tax_rate_id)
          sales_tax_rates.merge!({"#{tax_rate_name}": sales_tax_rate_detail})
        end
      end
      if tax_code.purchase_tax_rate_list.present?
        purchase_tax_rate_details = tax_code.purchase_tax_rate_list["tax_rate_detail"]
        purchase_tax_rate_details.each do |purchase_tax_rate|
          tax_rate_id = purchase_tax_rate.tax_rate_ref["value"]
          tax_rate_name = purchase_tax_rate.tax_rate_ref["name"].gsub("\"", '')
          purchase_tax_rate_detail= get_tax_rate_details(tax_rate_id)
          purchase_tax_rates.merge!({"#{tax_rate_name}": purchase_tax_rate_detail})
        end
      end
      puts tax_code_name
      production_tax_code = { name: tax_code_name, description: tax_code.description, sales_tax_rate_details: sales_tax_rates, purchase_tax_rate_details: purchase_tax_rates }
      production_tax_codes_collection.merge!({"#{tax_code_name}": production_tax_code})
    end
    production_tax_codes_collection
  end

  def is_not_yet_existed(tax_code_name)
    check_tax_name = @tax_code_service.query("Select * from TaxCode where name = '#{tax_code_name}'")
    check_tax_name.count == 0
  end

  def check_agency_name_in_staging(tax_rate_name, tax_agency_name)
    check_tax_name = @tax_agency_service.query("Select * from TaxAgency where name = '#{tax_agency_name}'")
    if check_tax_name.count == 0
      if tax_rate_name.include?("GST") || tax_rate_name.include?("HST")
        tax_agency_name = 'Canada Revenue Agency'
        check_tax_name = @tax_agency_service.query("Select * from TaxAgency where name = '#{tax_agency_name}'")
        check_tax_name.entries.first
      end
    else
      check_tax_name.entries.first
    end
  end

  def push_production_taxes_to_staging(authentication_data, old_access_token, tax_codes_with_agencies)
    get_access_token(authentication_data, old_access_token)
    query_end_point   = "#{BASE_URL}/#{@token.company_id}"
    tax_code_service
    tax_agency_service
    tax_codes_with_agencies.each do |key, tax_code|
      if is_not_yet_existed(key)
        tax_rate_details = []
        if tax_code[:sales_tax_rate_details].present?
          tax_code[:sales_tax_rate_details].each do |key, sales_tax_rate|
            tax_agency = check_agency_name_in_staging(sales_tax_rate[:tax_rate].name, sales_tax_rate[:tax_agency].display_name)
            sales_tax_rate = {
              "TaxRateName": "#{sales_tax_rate[:tax_rate].name}",
              "RateValue": sales_tax_rate[:tax_rate].rate_value,
              "TaxAgencyId": tax_agency.id,
              "TaxApplicableOn": "Sales"
            }
            puts "#{tax_agency.id} #{tax_agency.display_name}"
            tax_rate_details << sales_tax_rate
          end
        end

        if tax_code[:purchase_tax_rate_details].present?
          tax_code[:purchase_tax_rate_details].each do |key, sales_tax_rate|
            tax_agency = check_agency_name_in_staging(sales_tax_rate[:tax_rate].name, sales_tax_rate[:tax_agency].display_name)
            sales_tax_rate = {
              "TaxRateName": "#{sales_tax_rate[:tax_rate].name}",
              "RateValue": sales_tax_rate[:tax_rate].rate_value,
              "TaxAgencyId": tax_agency.id,
              "TaxApplicableOn": "Purchase"
            }
            puts "#{tax_agency.id} #{tax_agency.display_name}"
            tax_rate_details << sales_tax_rate
          end
        end
        tax_code_params = {
          "TaxCode": key,
          "TaxRateDetails": tax_rate_details
        }
        end_point = "#{BASE_URL}/#{@token.company_id}/taxservice/taxcode/"
        tax_code_response = @access_token.post(end_point, tax_code_params.to_json, { 'Content-Type' => 'application/json' })
        tax_code_id = JSON.parse(tax_code_response.body)["TaxCodeId"]
        puts "#{tax_code_id} #{key}"
      else
        puts 'already existed'
      end
    end
  end

  def get_all_tax_rates
    tax_rates_collection = []
    page_num = 1
    tax_rates = @tax_rate_service.query('Select * from TaxRate', :page => page_num, :per_page => 45)
    tax_rates_collection.concat(tax_rates.entries)

    while tax_rates.count != 0
      page_num = page_num + 1
      tax_rates = @tax_rate_service.query('Select * from TaxRate', :page => page_num, :per_page => 45)
      tax_rates_collection.concat(tax_rates.entries)
    end
    tax_rates_collection
  end
end
