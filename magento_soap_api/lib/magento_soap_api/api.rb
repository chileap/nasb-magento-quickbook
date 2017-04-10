module MagentoSoapApi
  class Api
    attr_accessor :magento_url, :magento_username, :magento_api_key

    def initialize(options = {})
      @magento_url = options.delete(:magento_url)
      @magento_username = options.delete(:magento_username)
      @magento_api_key = options.delete(:magento_api_key)
    end

    def common_params
      {
        magento_url: magento_url,
        magento_username: magento_username,
        magento_api_key: magento_api_key
      }
    end

    def login(params = {})
      begin
        params.merge!(common_params)
        document = MagentoSoapApi::Requests::Login.new(params)
        request = MagentoSoapApi::Request.new(magento_url: params[:magento_url], call_name: :login)
        request.body = document.body
        login = MagentoSoapApi::Login.new(request.connect!)
        @session_id = login.key
        login.key
      rescue MagentoSoapApi::AuthenticationError => e
        raise e
      end
    end

    def begin_session
      begin
        true if login
      rescue
        false
      end
    end

    def session_params(params = {})
      session_id = login
      params.merge!(common_params)
      params.merge!(session_id: session_id)
      params
    end

  end
end
