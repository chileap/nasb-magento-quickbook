class MagentoInvoiceSoapApi
  def get_invoices_from_soap_api(authentication_data, args = {})
    api = MagentoSoapApi::SalesOrderInvoice.new(magento_url: "#{authentication_data[:url]}/index.php", magento_username: authentication_data[:soap_api_username], magento_api_key: authentication_data[:soap_api_key])
    api.invoice_list(complex_filters: [{ key: 'state', operator: 'eq', value: args[:state] }, { key: 'created_at', operator: 'from', value: args[:start_date] }, { key: 'created_at', operator: 'to', value: args[:end_date] }])
  end

  def get_specific_invoice_from_soap_api(authentication_data, increment_id)
    api = MagentoSoapApi::SalesOrderInvoice.new(magento_url: "#{authentication_data[:url]}/index.php", magento_username: authentication_data[:soap_api_username], magento_api_key: authentication_data[:soap_api_key])
    api.invoice_list(complex_filters: [{ key: 'increment_id', operator: 'eq', value: increment_id }])
  end

  def get_creditmemo_from_soap_api(authentication_data, args = {})
    api = MagentoSoapApi::SalesOrderInvoice.new(magento_url: "#{authentication_data[:url]}/index.php", magento_username: authentication_data[:soap_api_username], magento_api_key: authentication_data[:soap_api_key])
    api.creditmemo_list(complex_filters: [{ key: 'created_at', operator: 'from', value: args[:start_date] }, { key: 'created_at', operator: 'to', value: args[:end_date] }])
  end
end
