require 'time'

module MagentoSoapApi
  class Request

    attr_accessor :params, :body, :call_name, :magento_url, :attributes

    def initialize(params = {})
      @call_name = params.delete(:call_name)
      @magento_url = params.delete(:magento_url)
      @attributes = params.delete(:attributes) || {}
    end

    def connect!
      MagentoSoapApi::Connection.send(:call, self)
    end

  end
end
