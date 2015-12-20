require 'rails/all'
require 'raven/integrations/rails'

class TestApp < Rails::Application
  config.secret_key_base = "test"

  # Usually set for us in production.rb
  config.eager_load = true
  config.cache_classes = true
  config.serve_static_files = false

  config.log_level = :error
  config.logger = Logger.new(STDOUT)

  routes.append do
    get "/exception", :to => "hello#exception"
    root :to => "hello#world"
  end
end

class HelloController < ActionController::Base
  def exception
    raise "An unhandled exception!"
  end

  def world
    render :text => "Hello World!"
  end
end

Rails.env = "production"
