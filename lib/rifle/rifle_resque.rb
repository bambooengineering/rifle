gem 'resque'

# This simple resque job pings the search server with a payload

class RifleResque
  @queue = :rifle

  def initialize(urn, payload)
    @urn = urn
    @payload = payload
  end

  def store
    broker_gateway_service.event({generator: @generator, timestamp: DateTime.now, payload: @payload})
  end

  def self.perform(urn, payload)
    h = RifleResque.new(urn, payload)
    h.execute
  end
end
