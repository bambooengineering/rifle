# encoding: UTF-8
require 'mock_redis'

describe Rifle do
  Rifle.settings.redis = MockRedis.new
  Rifle.settings.ignored_words = ["the", "and", "you", "that"]
  Rifle.settings.min_word_length = 3

  describe "Process and search" do

    processor = Rifle::Processor.new
    processor.get_words_array_from_text('The £20000 kitchen cake tin... Wonderful!').should == ['the', '20000', 'kitchen', 'cake', 'tin', 'wonderful']
    processor.get_metaphones_from_word_set(Set.new(['the', '20000', 'kitchen', 'cake', 'tin', 'wonderful'])).should == ["KXN", "KK", "TN", "WNTRFL"]

    metaphones = Rifle.store("test:3", {comment: "I think we need more chocolate cake", sources: [{
                                                                                                    id: 1, text: 'In the supermarket'
                                                                                                }, {
                                                                                                    id: 2, text: 'The kitchen cake tin'
                                                                                                }, {
                                                                                                    id: 3, text: 'A plush diner'
                                                                                                }]})

    metaphones.should == ["0NK", "NT", "MR", "XKLT", "KK", "SPRMRKT", "KXN", "TN", "PLX", "TNR"]

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

    # Test that it can return the entire payload
    Rifle.search("cheese").to_json.should == [result1].to_json

    Rifle.settings.ignored_words << 'cheddar'
    # Test that replacing a payload removes old keys, including ones in the old payload that are now "ignored"
    Rifle.store("test:5", ['red leicster', 'lancashire', 'stichelton'])
    Rifle.search("wensleydale", true).should == Set.new()
    Rifle.search("cheddar", true).should == Set.new() # This should have been removed.
    Rifle.search("lancashire", true).should == Set.new(["test:5"])
    Rifle.search("red leicster", true).should == Set.new(["test:5"])
    Rifle.search("stichelton", true).should == Set.new(["test:5"])
  end


  describe "Process and search" do
    # Test Ref codes. If a word is a block of letters and numbers it should not be split
    Rifle.store("ref:1", {ref: "LAQQWE2ZBR98765E"})

    Rifle.search("LAQQWE2ZBR98765E", true).should == Set.new(["ref:1"])
    Rifle.search("LA", true).should == Set.new()
    Rifle.search("ZBR", true).should == Set.new()
    Rifle.search("LAQQWE", true).should == Set.new()
    Rifle.search("98765", true).should == Set.new()
  end

  describe "Punctuation" do
    # Test splitting on punctuation
    Rifle.store("ref:2", {ref: "KJ/LAQQWE-2"})

    Rifle.search("LAQQWE", true).should == Set.new(["ref:2"])
    Rifle.search("KJ/LAQQWE-2", true).should == Set.new(["ref:2"])
  end

  describe "Numbers" do
    # Test store numbers
    Rifle.store("ref:3", {ref: "123467891"})

    Rifle.search("123467891", true).should == Set.new()
    Rifle.search("12346789", true).should == Set.new()
  end

end
