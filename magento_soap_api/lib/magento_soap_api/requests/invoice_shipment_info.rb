module MagentoSoapApi::Requests
  class InvoiceShipmentInfo

    attr_accessor :data

    def initialize(data = {})
      @data = data
    end

    def body
      invoice_info_hash
    end

    def invoice_info_hash
      {
        session_id: self.session_id,
        shipment_increment_id: self.shipment_id
      }
    end

    def session_id
      data[:session_id]
    end

    def shipment_id
      data[:increment_id]
    end

  end
end
