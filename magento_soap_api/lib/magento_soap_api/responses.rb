module MagentoSoapApi

  class Login < MagentoSoapApi::Response
    def initialize(response)
      super
    end

    def key
      @document[:login_response][:login_return].to_s
    end
  end

  class InvoiceList < MagentoSoapApi::Response
    def initialize(response)
      super
      result
    end

    def result
      @document[:sales_order_invoice_list_response][:result]
    end

    def collection
      result[:item]
    end
  end

  class InvoiceInfo < MagentoSoapApi::Response
    def initialize(response)
      super
      result
    end

    def result
      @document[:sales_order_info_response][:result]
    end

    def item_invoice
      result
    end

    def exists_for_order?
      true if invoice_id
    end
  end

  class CreditmemoList < MagentoSoapApi::Response
    def initialize(response)
      super
      result
    end

    def result
      @document[:sales_order_creditmemo_list_response][:result]
    end

    def collection
      result[:item]
    end
  end

  class InvoiceShipmentList < MagentoSoapApi::Response
    def initialize(response)
      super
      result
    end

    def result
      @document[:sales_order_shipment_list_response][:result]
    end

    def collection
      result[:item]
    end
  end

  class InvoiceShipmentInfo < MagentoSoapApi::Response
    def initialize(response)
      super
      result
    end

    def result
      @document[:sales_order_shipment_info_response][:result]
    end

    def item_invoice
      result
    end

    def exists_for_order?
      true if invoice_id
    end
  end
end
