class MagentoInvoiceSoapApi
  def get_invoices_from_soap_api(authentication_data, args = {})
    api = MagentoSoapApi::SalesOrderInvoice.new(magento_url: "#{authentication_data[:url]}/index.php", magento_username: authentication_data[:soap_api_username], magento_api_key: authentication_data[:soap_api_key])
    invoice_list =  api.invoice_list(complex_filters: [{key: "state", operator: "eq", value: args[:state]}, {key: 'created_at', operator: "from", value: args[:start_date] }, {key: "created_at", operator: "to", value: args[:end_date]}])
  end

  def get_creditmemo_from_soap_api(authentication_data)
    api = MagentoSoapApi::SalesOrderInvoice.new(magento_url: "#{authentication_data[:url]}/index.php", magento_username: authentication_data[:soap_api_username], magento_api_key: authentication_data[:soap_api_key])
    creditmemo_list =  api.creditmemo_list(complex_filters: [{key: 'created_at', operator: "from", value: "2016-08-01 00:00:00" }, {key: "created_at", operator: "to", value: "2016-08-31 23:59:59"}])
  end
end
