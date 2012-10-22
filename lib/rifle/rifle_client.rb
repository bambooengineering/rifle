module Rifle
  module Client
    def self.flush
      if Rifle.settings.use_rest_server
        RestClient.post("#{Rifle.settings.use_rest_server}/flush")
      else
        Rifle.flush
      end
    end
    def self.store(urn, json)
      if (json.is_a? Hash)
        json = json.to_json
      end
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