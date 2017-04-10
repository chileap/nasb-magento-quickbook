module MagentoSoapApi
  class ApiError < MagentoSoapApi::Response

    def path_to_error(response)
      response[:response][:fault]
    end

    def path_to_request_info(response)
      response[:request]
    end

    def code(response)
      path = path_to_error(response)
      path[:faultcode] if path
    end

    def message(response)
      path = path_to_error(response)
      path[:faultstring] if path
    end

    def call(response)
      path = path_to_request_info(response)
      path.call_name if path
    end

    def call_details(response)
      path = path_to_request_info(response)
      path.body if path
    end

    def magento_url(response)
      path = path_to_request_info(response)
      path.magento_url if path
    end

    #MagentoSoapApi::ApiError to_s gives you information about the response from Magento's API, like the HTTP status code and the Magento API message, but even if the response does not contain this information, you get information about the request to help diagnose the cause of the error.
    def to_s(response)
      "[Magento Fault Code: #{self.code(response)}] Error Message: #{self.message(response)} Received while attempting #{self.call(response)} for Magento URL: #{self.magento_url(response)}. Details: #{self.call_details(response)}"
    end

  end
end
