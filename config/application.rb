require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"

if defined?(Bundler)
  Bundler.require(:default, Rails.env)
end

module Rifle
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.assets.version = '1.0'
  end
end
