module Concerns::MagentoRestApiToken
  def create_consumer(authentication_data)
    OAuth::Consumer.new(
      authentication_data[:consumer_key],
      authentication_data[:consumer_secret],
      request_token_path: '/oauth/initiate',
      authorize_path: "/#{ENV['ADMIN_URL_SLASH']}/oauth_authorize",
      access_token_path: '/oauth/token',
      site: authentication_data[:url]
    )
  end

  def request_token(args = {})
    args[:consumer].get_request_token(oauth_callback: args[:url])
  end

  def get_authorize_url(args = {})
    args[:request_token].authorize_url
  end

  def authorize_application(args = {})
    m = Mechanize.new
    m.get(args[:authorize_url]) do |login_page|
      auth_page = login_page.form_with(action: "#{args[:authentication_data][:url]}/index.php/admin/#{ENV['ADMIN_URL_SLASH']}/oauth_authorize/index/") do |form|
        form.elements[2].value = args[:authentication_data][:username]
        if Rails.env == 'production'
          form.elements[4].value = args[:authentication_data][:password]
        else
          form.elements[4].value = args[:authentication_data][:password]
        end
      end.submit
      authorize_form = auth_page.forms[0]
      @callback_page = authorize_form.submit
    end

    @callback_page.uri.to_s
  end

  def extract_oauth_verifier(args = {})
    callback_page = args[:callback_page].gsub!("#{args[:url]}/?", '')
    callback_page_query_string = CGI.parse(callback_page)
    callback_page_query_string['oauth_verifier'][0]
  end

  def get_access_token(args = {})
    args[:request_token].get_access_token(oauth_verifier: args[:oauth_verifier])
  end

  def get_new_access_tokens(authentication_data)
    new_consumer = create_consumer(authentication_data)
    new_request_token = request_token(consumer: new_consumer, url: authentication_data[:url])
    new_authorize_url = get_authorize_url(request_token: new_request_token)
    authorize_new_application = authorize_application(authorize_url: new_authorize_url, authentication_data: authentication_data)
    extract_new_oauth_verifier = extract_oauth_verifier(callback_page: authorize_new_application, url: authentication_data[:url])
    new_access_token = get_access_token(request_token: new_request_token, oauth_verifier: extract_new_oauth_verifier)
    new_access_token
  end
end
