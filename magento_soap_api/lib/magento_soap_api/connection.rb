module MagentoSoapApi
  class Connection

    class << self

      attr_writer :adapter

      define_method :call do |request|
        response = self.adapter(request).send(:call)
        self.raw_response(request, response)
      end

      def adapter(request)
        @adapter || MagentoSoapApi::SavonClient.new(request)
      end

      #Receives both the request and the response back in order to give more complete error reporting when MagentoSoapApi::ApiError is raised
      #response is defined in MagentoSoapApi::Response
      def raw_response(request, response)
        if error_present?(response.body)
          response_info = {request: request, response: response.body}
          raise_magento_error(response_info)
        else
          response
        end
      end

      def error_present?(response)
        response.keys[0] == :fault
      end

      #Magento fault codes:
      #0: Unknown Error
      #1: Internal Error. Please see log for details.
      #2: Access denied.
      #3: Invalid api path.
      #4: Resource path is not callable.
      def raise_magento_error(response)
        api_error = parse_error(response)
        case api_error.code(response)
        when "0"
          raise MagentoSoapApi::UnknownError, api_error.to_s(response)
        when "1"
          raise MagentoSoapApi::MagentoError, api_error.to_s(response)
        when "2"
          raise MagentoSoapApi::AuthenticationError, api_error.to_s(response)
        when "3"
          raise MagentoSoapApi::UnknownRequest, api_error.to_s(response)
        when "4"
          raise MagentoSoapApi::UnavailableError, api_error.to_s(response)
        when "SOAP-ENV:Server"
          raise MagentoSoapApi::BadRequest, api_error.to_s(response)
        when "SOAP-ENV:Client"
          raise MagentoSoapApi::BadRequest, api_error.to_s(response)
        else
          raise MagentoSoapApi::Error, api_error.to_s(response)
        end
      end

      def parse_error(response)
        MagentoSoapApi::ApiError.new(response)
      end
    end
  end
end
