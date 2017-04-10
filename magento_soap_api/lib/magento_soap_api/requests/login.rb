module MagentoSoapApi::Requests
  class Login
    attr_accessor :data

    def initialize(data = {})
      @data = data
    end

    def body
      login_hash
    end

    def login_hash
      {
        username:   self.username,
        api_key:    self.user_key
      }
    end

    def username
      data[:magento_username]
    end

    def user_key
      data[:magento_api_key]
    end
  end
end
