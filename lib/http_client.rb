require 'net/http'
require 'uri'

class HttpClient
  # Creates an HTTP client from the specified host and port
  # options:
  #   :use_ssl => whether to use SSL
  #   :ca_file => certificate authority file
  #   :open_timeout => timeout in secs for connection to be established
  #   :read_timeout => timeout in secs for reading data
  def initialize(host, port, options={})
    @http = Net::HTTP.new(host, port)
    if options.key?(:use_ssl) ? options[:use_ssl] : port == 443
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      #@http.ca_file = options[:ca_file] || Intersect.ca_file
    end
    @http.open_timeout = options[:open_timeout] if options.key? :open_timeout
    @http.read_timeout = options[:read_timeout] if options.key? :read_timeout
  end

  # expose the underlying Net::HTTP object
  attr_reader :http

  # Perform a GET request. Auto-follows redirects until redirect_limit reached.
  # Optionally takes a block to receive chunks of the response.
  # Raises Net::HTTPExceptions if response code not 2xx.
  def get(path, redirect_limit=5, &block)
    request = Net::HTTP::Get.new(path)
    @http.request(request) do |response|
      if response.is_a? Net::HTTPSuccess
        return response.read_body(&block)
      elsif response.is_a? Net::HTTPRedirection
        return follow_redirect(response, redirect_limit, &block)
      else
        response.read_body
        response.error!
      end
    end
  end

  # Perform a POST request.
  # Optionally takes a form_data hash.
  # Optionally takes a block to receive chunks of the response.
  # Raises Net::HTTPExceptions if response code not 2xx.
  def post(path, form_data=nil, &block)
    request = Net::HTTP::Post.new(path)
    request.set_form_data(form_data) if form_data
    @http.request(request) do |response|
      if response.is_a? Net::HTTPSuccess
        return response.read_body(&block)
      else
        response.read_body
        response.error!
      end
    end
  end

  # Creates a new HttpClient based on the specified uri.
  def self.from_uri(uri, options={})
    uri = URI.parse(uri) unless uri.is_a?(URI)
    raise ArgumentError, 'uri should be HTTP' unless uri.is_a?(URI::HTTP)
    new(uri.host, uri.port, options.merge(:use_ssl => uri.is_a?(URI::HTTPS)))
  end

  # Creates a new HttpClient and performs a GET based on the specified uri.
  def self.get(uri, redirect_limit=5, options={}, &block)
    uri = URI.parse(uri) unless uri.is_a?(URI)
    from_uri(uri, options).get(uri.request_uri, redirect_limit, &block)
  end

  # Creates a new HttpClient and performs a POST based on the specified uri.
  def self.post(uri, form_data=nil, options={}, &block)
    uri = URI.parse(uri) unless uri.is_a?(URI)
    from_uri(uri, options).post(uri.request_uri, form_data, &block)
  end

  private
    def follow_redirect(response, redirect_limit, &block)
      response.error! unless redirect_limit > 0
      redirect_limit -= 1

      location = URI.parse(response['location'])

      # if location is relative then use self as http client
      return get(location.to_s, redirect_limit, &block) if location.relative?

      # only follow http locations
      response.error! unless location.is_a?(URI::HTTP)

      # build http_client from location and get location
      options = {
        :open_timeout => @http.open_timeout,
        :read_timeout => @http.read_timeout,
        :ca_file => @http.ca_file
      }
      return self.class.get(location, redirect_limit, options, &block)
    end
end
