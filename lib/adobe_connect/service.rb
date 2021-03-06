module AdobeConnect
  class Service
    attr_reader :username, :domain, :session

    def initialize(options = AdobeConnect::Config)
      @username      = options[:username]
      @password      = options[:password]
      @domain        = URI.parse(options[:domain])
      @authenticated = false
    end

    def log_in
      response = request('login', { :login => username, :password => password }, false)
      if response.at_xpath('//status').attr('code') == 'ok'
        session_regex  = /BREEZESESSION=([^;]+)/
        @session       = response.fetch('set-cookie').match(session_regex)[1]
        @authenticated = true
      else
        false
      end
    end

    def authenticated?
      @authenticated
    end

    def client
      if @client.nil?
        @client         = Net::HTTP.new(domain.host, domain.port)
        @client.use_ssl = (domain.scheme == 'https')
      end

      @client
    end

    def method_missing(method, *args)
      action = method.to_s.dasherize
      params = args.first

      request(action, params)
    end

    private
    attr_reader :password

    def request(action, params, use_session = true)
      if use_session
        log_in unless authenticated?
        params[:session] = session
      end

      query_string = ParamFormatter.new(params).format
      response     = client.get("/api/xml?action=#{action}#{query_string}")
      AdobeConnect::Response.new(response)
    end
  end
end
