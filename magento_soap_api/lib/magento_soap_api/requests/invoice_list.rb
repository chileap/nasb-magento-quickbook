module MagentoSoapApi::Requests
  class InvoiceList

    attr_accessor :data

    def initialize(data = {})
      @data = data
    end

    def body
      merge_filters!(sales_order_invoice_list_hash)
    end

    def attributes
      { session_id: { "xsi:type" => "xsd:string" },
        filters: { "xsi:type" => "ns1:filters" },
      }
    end

    def sales_order_invoice_list_hash
      {
        session_id: self.session_id
      }
    end

    def merge_filters!(sales_order_invoice_list_hash)
      if !filters_array.empty?
        sales_order_list_filters = {
          filters: filters_array,
        }
        sales_order_invoice_list_hash.merge!(sales_order_list_filters)
      else
        sales_order_invoice_list_hash
      end
    end

    def filters_array
      custom_filters = {}
      custom_filters.compare_by_identity
      if !simple_filters.nil?
        add_simple_filters(custom_filters)
      end

      if !complex_filters.nil?
        add_complex_filters(custom_filters)
      end
      custom_filters
    end

    def add_simple_filters(custom_filters)
      simple_filters.each do |sfilter|
        custom_filters[:attributes!] = {
          "filter" => {
            "SOAP-ENC:arrayType" => "ns1:associativeEntity[2]",
            "xsi:type" => "ns1:associativeArray"
          }
        }
        custom_filters["filter"] = {
          item: {
            key: sfilter[:key],
            value: sfilter[:value],
            :attributes! => {
              key: { "xsi:type" => "xsd:string" },
              value: { "xsi:type" => "xsd:string" }
            },
          },
          :attributes! => {
            item: { "xsi:type" => "ns1:associativeEntity" },
          },
        }
      end
      custom_filters
    end

    def add_complex_filters(custom_filters)
      custom_filters[:attributes!] = {
        "complex_filter" => {
          "SOAP-ENC:arrayType" => "ns1:complexFilter[2]",
          "xsi:type" => "ns1:complexFilterArray"
        }
      }
      item = []
      complex_filters.each do |complex_filter|
        item << {
            key: complex_filter[:key],
            value:{
              key: complex_filter[:operator],
              value: complex_filter[:value]
            },
            :attributes! => {
              key: { "xsi:type" => "xsd:string" },
              value: { "xsi:type" => "xsd:associativeEntity" }
            },
          }
      end
      custom_filters["complex_filter"] = {
        item: item,
        :attributes! => {
          item: { "xsi:type" => "ns1:complexFilter" },
        },
      }
      custom_filters
    end

    def session_id
      @data[:session_id]
    end

    def simple_filters
      @data[:simple_filters]
    end

    def complex_filters
      @data[:complex_filters]
    end
  end
end
