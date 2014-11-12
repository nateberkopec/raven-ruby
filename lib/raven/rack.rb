require 'time'

module Raven
  # Middleware for Rack applications. Any errors raised by the upstream
  # application will be delivered to Sentry and re-raised.
  #
  # Synopsis:
  #
  #   require 'rack'
  #   require 'raven'
  #
  #   Raven.configure do |config|
  #     config.server = 'http://my_dsn'
  #   end
  #
  #   app = Rack::Builder.app do
  #     use Raven::Rack
  #     run lambda { |env| raise "Rack down" }
  #   end
  #
  # Use a standard Raven.configure call to configure your server credentials.
  class Rack
    def self.capture_exception(exception, env, options = {})
      if env['requested_at']
        options[:time_spent] = Time.now - env['requested_at']
      end
      Raven.capture_exception(exception, options) do |evt|
        evt.interface :http do |int|
          int.from_rack(env)
        end
      end
    end

    def self.capture_message(message, env, options = {})
      if env['requested_at']
        options[:time_spent] = Time.now - env['requested_at']
      end
      Raven.capture_message(message, options) do |evt|
        evt.interface :http do |int|
          int.from_rack(env)
        end
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      # clear context at the beginning of the request to ensure a clean slate
      Context.clear!

      # store the current environment in our local context for arbitrary
      # callers
      env['requested_at'] = Time.now
      Raven.rack_context(env)

      begin
        response = @app.call(env)
      rescue Error
        raise # Don't capture Raven errors
      rescue Exception => e
        Raven.logger.debug "Collecting %p: %s" % [ e.class, e.message ]
        Raven::Rack.capture_exception(e, env)
        raise
      end

      error = env['rack.exception'] || env['sinatra.error']

      Raven::Rack.capture_exception(error, env) if error

      response
    end

    def interface_from_rack(env)
      require 'rack'
      req = ::Rack::Request.new(env)
      self.url = req.url.split('?').first
      self.method = req.request_method
      self.query_string = req.query_string
      self.headers, self.env = {}, {}
      env.each_pair do |key, value|
        next unless key.upcase == key # Non-upper case stuff isn't either
        if key.start_with?('HTTP_')
          # Header
          http_key = key[5..key.length - 1].split('_').map { |s| s.capitalize }.join('-')
          self.headers[http_key] = value.to_s
        elsif ['CONTENT_TYPE', 'CONTENT_LENGTH'].include? key
          self.headers[key.capitalize] = value.to_s
        elsif ['REMOTE_ADDR', 'SERVER_NAME', 'SERVER_PORT'].include? key
          # Environment
          self.env[key] = value.to_s
        end
      end

      self.data =
        if req.form_data?
          req.POST
        elsif req.body
          data = req.body.read
          req.body.rewind
          data
        end
    end
  end
end
