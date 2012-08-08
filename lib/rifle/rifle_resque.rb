gem 'resque'
gem 'rest-client'

# This simple resque job pings the search server with a payload.

class RifleResque
  @queue = Rifle.settings.resque_queue

  def initialize(urn, payload)
    @urn = urn
    @payload = payload
  end

  def store
    RestClient.post("#{Rifle.settings.server}/store/#{@urn}", @payload)
  end

  def self.perform(urn, payload)
    h = RifleResque.new(urn, payload)
    h.store
  end
end
