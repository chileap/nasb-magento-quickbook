require 'savon'

require 'magento_soap_api/connection'
require 'magento_soap_api/savon_client'

require 'magento_soap_api/request'
Dir[File.dirname(__FILE__) + "/magento_soap_api/requests/*.rb"].each do |file|
  require file
end

require 'magento_soap_api/response'
require 'magento_soap_api/responses'
require 'magento_soap_api/version'

require 'magento_soap_api/api'

Dir[File.dirname(__FILE__) + "/magento_soap_api/api/*.rb"].each do |file|
  require file
end

require 'magento_soap_api/api_error'

module MagentoSoapApi
  class Error < StandardError; end
  class UnknownError < StandardError; end
  class MagentoError < Error; end
  class AuthenticationError < Error; end
  class UnknownRequest < Error; end
  class UnavailableError < Error; end
  class BadRequest < Error; end
end
