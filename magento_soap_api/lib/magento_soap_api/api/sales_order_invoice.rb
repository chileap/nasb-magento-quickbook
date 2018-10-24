module MagentoSoapApi
  class SalesOrderInvoice < MagentoSoapApi::Api
    def initialize(options = {})
      super
    end

    def invoice_list(params = {})
      params.merge!(session_params)
      document = MagentoSoapApi::Requests::InvoiceList.new(params)
      request = MagentoSoapApi::Request.new(magento_url: params[:magento_url], call_name: :sales_order_invoice_list)
      request.body = document.body
      request.attributes = document.attributes
      orders = MagentoSoapApi::InvoiceList.new(request.connect!)
      orders.collection
    end

    def invoice_info(params = {})
      params.merge!(session_params)
      document = MagentoSoapApi::Requests::InvoiceInfo.new(params)
      request = MagentoSoapApi::Request.new(magento_url: params[:magento_url], call_name: :sales_order_info)
      request.body = document.body
      invoice = MagentoSoapApi::InvoiceInfo.new(request.connect!)
      invoice.item_invoice
    end

    def creditmemo_list(params = {})
      params.merge!(session_params)
      document = MagentoSoapApi::Requests::CreditmemoList.new(params)
      request = MagentoSoapApi::Request.new(magento_url: params[:magento_url], call_name: :sales_order_creditmemo_list)
      request.body = document.body
      request.attributes = document.attributes
      orders = MagentoSoapApi::CreditmemoList.new(request.connect!)
      orders.collection
    end

    def invoice_shipment_list(params = {})
      params.merge!(session_params)
      document = MagentoSoapApi::Requests::InvoiceShipmentList.new(params)
      request = MagentoSoapApi::Request.new(magento_url: params[:magento_url], call_name: :sales_order_shipment_list)
      request.body = document.body
      invoice = MagentoSoapApi::InvoiceShipmentList.new(request.connect!)
      invoice.collection
    end

    def invoice_shipment_info(params = {})
      params.merge!(session_params)
      document = MagentoSoapApi::Requests::InvoiceShipmentInfo.new(params)
      request = MagentoSoapApi::Request.new(magento_url: params[:magento_url], call_name: :sales_order_shipment_info)
      request.body = document.body
      invoice = MagentoSoapApi::InvoiceShipmentInfo.new(request.connect!)
      invoice.item_invoice
    end

  end
end
