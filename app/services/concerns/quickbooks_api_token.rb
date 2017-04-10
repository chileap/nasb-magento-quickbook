module Concerns::QuickbooksApiToken
  URL = "https://oauth.intuit.com"

  def create_consumer(consumer_data)
    consumer = OAuth::Consumer.new(consumer_data[:consumer_key], consumer_data[:consumer_secret], {
      :site                 => URL,
      :request_token_path   => "/oauth/v1/get_request_token",
      :authorize_url        => "https://appcenter.intuit.com/Connect/Begin",
      :access_token_path    => "/oauth/v1/get_access_token"
    })
  end

  def get_new_access_tokens(authentication_data, old_access_token)
    consumer = create_consumer(authentication_data)
    access_token = OAuth::AccessToken.new(consumer, old_access_token.access_token, old_access_token.access_secret)
    service = Quickbooks::Service::AccessToken.new
    service.access_token = access_token
    service.company_id = old_access_token.company_id
    new_token = service.renew
    case new_token.error_code
    when "0"
      old_access_token.update_attributes!(
        access_token: new_token.token,
        access_secret: new_token.secret,
        token_expires_at: 180.days.from_now.utc,
      )
      puts "Renewal succeeded"
    when "270"
      puts "Renewal failed"
    when "212"
      puts "Renewal ignored, tried too soon"
    else
      puts "Renewal failed, code: #{new_token.error_code} message: #{new_token.error_message}"
    end
  end
end
