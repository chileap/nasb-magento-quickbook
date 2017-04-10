module MagentoSoapApi
  class SavonClient

    attr_accessor :request

    def initialize(request)
     @request = request
     @magento_url = request.magento_url
    end

    def call
      client.call(@request.call_name, message: message_with_attributes, response_parser: :nokogiri)
    end

    #message_with_attributes are required for some specific formatting when updating Magento via the SOAP API
    def message_with_attributes
      @request.body.merge!(:attributes! => @request.attributes) unless @request.attributes.empty?
      puts "REQUEST: #{@request.inspect}"
      return @request.body
    end

    #configuration of the client is mostly mandatory, however some of these options (like timeout) will be made configurable in the future
    #TODO: make timeout configurable
    def client
      Savon::Client.new do |savon|
        savon.ssl_verify_mode          :none
        savon.wsdl                     base_url
        savon.namespaces               namespaces
        savon.env_namespace            'SOAP-ENV'
        savon.raise_errors             false
        #savon.namespace_identifier     #none
        savon.convert_request_keys_to  :lower_camelcase
        savon.strip_namespaces         true
        savon.pretty_print_xml         true
        savon.log                      log_env
        savon.open_timeout             10    #seconds
        savon.read_timeout             45    #seconds
      end
    end

    #TODO: make configurable
    def log_env
      true
    end

    #correctly format MagentoSoapApi::Request call_names for SOAP v2
    def response_tag_format_lambda
      lambda { |key| key.snakecase.downcase }
    end

    def namespaces
      {
        'xmlns:SOAP-ENV' => 'http://schemas.xmlsoap.org/soap/envelope/',
        'xmlns:ns1' => 'urn:Magento',
        'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:SOAP-ENC' => 'http://schemas.xmlsoap.org/soap/encoding/',
        'SOAP-ENV:encodingStyle' => 'http://schemas.xmlsoap.org/soap/encoding/'
      }
    end

    #Use MagentoSoapApi::Api magento_url as endpoint
    def base_url
      "#{@magento_url}/api/v2_soap?wsdl=1"
    end
  end
end
