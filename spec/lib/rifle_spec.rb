require 'mock_redis'

describe Rifle do
  Rifle.settings.redis = MockRedis.new
  Rifle.settings.ignored_words = ["the", "and", "you", "that"]
  Rifle.settings.min_word_length = 3

  describe "Process and search" do

    metaphones = Rifle.store("test:3", {comment: "I think we need more chocolate cake", sources: [{
                                                                                                    id: 1, text: 'In the supermarket'
                                                                                                }, {
                                                                                                    id: 2, text: 'The kitchen cake tin'
                                                                                                }, {
                                                                                                    id: 3, text: 'A plush diner'
                                                                                                }]})

    metaphones.should == ["0NK", "NT", "MR", "XKLT", "KK", "SPRMRKT", "KXN", "KK", "TN", "PLX", "TNR"]

    result1 = {
        urn: "TEST:1",
        payload: {comment: "A great venue for cheese."}
    }

    # Test capital urns
    Rifle.store("TEST:1", {comment: "A great venue for cheese."})
    # Test subhashes
    Rifle.store("test:2", {comment: "I like chocolate cake", place: "My favourite restaurant"})
    # Test re-storing multiple times only returns one result
    Rifle.store("test:4", {comment: "A metaphone for the above flavour is XKLT."})
    Rifle.store("test:4", {comment: "A metaphone for the above flavour is XKLT."})
    Rifle.store("test:4", {comment: "A metaphone for the above flavour is XKLT."})
    # Test the root being an array
    Rifle.store("test:5", ['cheddar', 'stichelton', 'wensleydale'])

    Rifle.search("chocolate", true).should == Set.new(["test:2", "test:3"])
    Rifle.search("kitchen", true).should == Set.new(["test:3"])
    Rifle.search("cheese", true).should == Set.new(["TEST:1"])
    Rifle.search("METAphone", true).should == Set.new(["test:4"])
    Rifle.search("wensleydale", true).should == Set.new(["test:5"]) # Search for array containers

    Rifle.search("cheese").to_json.should == [result1].to_json
  end
end
