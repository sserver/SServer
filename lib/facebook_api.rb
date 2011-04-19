require 'http_client'
require 'json_http_client'

module FacebookApi

  def self.authorization_code_url(redirect_url, permissions=[:email])
    url_params = {
      :client_id => SServer.facebook_app_id,
      :redirect_uri => redirect_url,
      :scope => permissions.join(',')
    }
    "https://www.facebook.com/dialog/oauth?#{url_params.to_query}"
  end

  def self.authenticate_with_redirect_url_params(redirect_url, url_params_hash)
    authorization_code = url_params_hash[:code]
    if authorization_code.blank?
      result = {:error => :authorization_code_error, :error_details => url_params_hash}
    else
      access_token_url_params = {
        :client_id => SServer.facebook_app_id,
        :client_secret => SServer.facebook_app_secret,
        :code => authorization_code,
        :redirect_uri => redirect_url
      }
      access_token_url = "https://graph.facebook.com/oauth/access_token?#{access_token_url_params.to_query}"
      http_client = HttpClient.new('graph.facebook.com', 443)
      begin
        response = http_client.get(access_token_url)
        result = Rack::Utils.parse_query(response)
        result.symbolize_keys!
        result[:expires] = result[:expires].to_i if result.key? :expires
        result
      rescue Net::HTTPExceptions => e
        response = e.response
        result = {:error => :authentication_error, :status_code => response.code}
        result[:error_details] = response.body if response.body_permitted?
      end
    end
    result
  end

  def self.me(access_token)
    client = JsonHttpClient.new(HttpClient.new("graph.facebook.com", 443))
    client.get "/me?access_token=#{access_token}"
  end

  def self.user_photo(user_id)
    "http://graph.facebook.com/#{user_id}/picture?type=small"
  end

end
