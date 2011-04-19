require 'http_client'
require 'yajl'

class JsonHttpClient
  # Creates a new JsonHttpClient wrapping a HttpClient
  def initialize(http_client, symbolize_keys = true)
    @http_client = http_client
    @symbolize_keys = symbolize_keys
  end

  # Perform GET request, parsing response as JSON.
  # Auto-follows redirects until redirect_limit reached.
  # Raises Net::HTTPExceptions if response code not 2xx.
  def get(path, redirect_limit=5)
    parse_json do |parser|
      @http_client.get(path, redirect_limit) {|chunk| parser << chunk }
    end
  end

  # Perform POST request, parsing response as JSON.
  # Optionally takes a form_data hash.
  # Raises Net::HTTPExceptions if response code not 2xx.
  def post(path, form_data=nil)
    parse_json do |parser|
      @http_client.post(path, form_data) {|chunk| parser << chunk }
    end
  end

  # Creates a new JsonHttpClient based on the specified uri.
  def self.from_uri(uri)
    new(HttpClient.from_uri(uri))
  end

  # Creates a new JsonHttpClient and performs a GET based on the specified uri.
  def self.get(uri, redirect_limit=5)
    uri = URI.parse(uri) unless uri.is_a?(URI)
    from_uri(uri).get(uri.request_uri, redirect_limit)
  end

  # Creates a new JsonHttpClient and performs a POST based on the specified uri.
  def self.post(uri, form_data=nil)
    uri = URI.parse(uri) unless uri.is_a?(URI)
    from_uri(uri).post(uri.request_uri, form_data)
  end

  private
    def parse_json
      result = nil
      parser = Yajl::Parser.new(:symbolize_keys => @symbolize_keys)
      parser.on_parse_complete = lambda {|obj| result = obj}
      yield parser
      result
    end
end
