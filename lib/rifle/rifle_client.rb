module Rifle
  module Client
    def self.store(urn, json)
      Resque.enqueue(RifleResque, urn, json)
    end
    def self.search(query)
      if Rifle.settings.use_rest_server
        results = RestClient.get("#{Rifle.settings.use_rest_server}/search", {params: {q: query}})
        if (results.is_a? String)
          results = JSON.parse(results)
        end
        results
      else
        Rifle.search(query)
      end
    end
  end
end