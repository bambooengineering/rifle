require 'mock_redis'

describe Rifle do
  Rifle.settings.redis = MockRedis.new
  Rifle.settings.ignored_words = ["the", "and", "you", "that"]
  Rifle.settings.min_word_length = 3

  describe "Process and search" do

    metaphones = Rifle.process_resource("test:3", {comment: "I think we need more chocolate cake", sources: [{
                                                                                                    id: 1, text: 'In the supermarket'
                                                                                                }, {
                                                                                                    id: 2, text: 'The kitchen cake tin'
                                                                                                }, {
                                                                                                    id: 3, text: 'A plush diner'
                                                                                                }]})

    metaphones.should == ["0NK", "NT", "MR", "XKLT", "KK", "SPRMRKT", "KXN", "KK", "TN", "PLX", "TNR"]

    Rifle.process_resource("test:1", {comment: "A great venue for cheese."})
    Rifle.process_resource("test:2", {comment: "I like chocolate cake", place: "My favourite restaurant"})
    Rifle.process_resource("test:4", {comment: "A metaphone for the above flavour is XKLT."})

    Rifle.search("chocolate").should == Set.new(["test:2", "test:3"])
    Rifle.search("kitchen").should == Set.new(["test:3"])
    Rifle.search("cheese").should == Set.new(["test:1"])
  end
end
