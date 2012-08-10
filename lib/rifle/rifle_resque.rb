gem 'resque'
gem 'rest-client'
require_relative 'settings'

# This simple resque job pings the search server with a payload.

class RifleResque

  def initialize(urn, payload)
    @urn = urn
    @payload = payload
  end

  def self.queue
    Rifle.settings.resque_queue
  end

  def store
    RestClient.post("#{Rifle.settings.server}/store/#{@urn}", @payload, :content_type => :json, :accept => :json)
  end

  def self.perform(urn, payload)
    h = RifleResque.new(urn, payload)
    h.store
  end
end
