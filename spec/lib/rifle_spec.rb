require 'mock_redis'

describe Rifle do
  $redis = MockRedis.new

  describe "Process and search" do
    Rifle.process_resource("test:1", {comment: "A great venue for cheese."})
    Rifle.process_resource("test:2", {comment: "I like chocolate cake", place: "My favourite restaurant"})
    Rifle.process_resource("test:3", {comment: "I think we need more chocolate cake", sources: [{
                                                                                                    id: 1, text: 'In the supermarket'
                                                                                                }, {
                                                                                                    id: 2, text: 'The kitchen cake tin'
                                                                                                }, {
                                                                                                    id: 3, text: 'A plush diner'
                                                                                                }]})
    Rifle.process_resource("test:4", {comment: "A metaphone for chocolate is XKLT."})

    Rifle.search("chocolate").should == Set.new(["test:2", "test:3", "test:4"])
    Rifle.search("kitchen").should == Set.new(["test:3"])
    Rifle.search("cheese").should == Set.new(["test:1"])
  end
end
