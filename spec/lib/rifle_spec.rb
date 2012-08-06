require 'mock_redis'

describe Rifle do
  $redis = MockRedis.new

  describe "Process and search" do
    Rifle.process_resource("test:1", {name: "This is the place to be."})
    Rifle.process_resource("test:2", {name: "I like chocolate cake", place: "My favourite restaurant"})
    Rifle.process_resource("test:3", {name: "I think we need more chocolate cake"})

    Rifle.search("chocolate").should == Set.new(["test:2", "test:3"])
  end
end
