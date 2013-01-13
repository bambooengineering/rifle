# encoding: UTF-8
require 'mock_redis'

describe Rifle do
  Rifle.settings.redis = MockRedis.new
  Rifle.settings.ignored_words = ["the", "and", "you", "that"]
  Rifle.settings.min_word_length = 3

  context "fuzzy matching" do
    before(:each) {
      Rifle.settings.fuzzy_matching = true
    }

    it "Process and search" do

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


    it "Process and search" do
      # Test Ref codes. If a word is a block of letters and numbers it should not be split
      Rifle.store("ref:1", {ref: "LAQQWE2ZBR98765E"})

      Rifle.search("LAQQWE2ZBR98765E", true).should == Set.new(["ref:1"])
      Rifle.search("LA", true).should == Set.new()
      Rifle.search("ZBR", true).should == Set.new()
      Rifle.search("LAQQWE", true).should == Set.new()
      Rifle.search("98765", true).should == Set.new()
    end

    it "Punctuation" do
      # Test splitting on punctuation
      Rifle.store("ref:2", {ref: "KJ/LAQQWE-2"})

      Rifle.search("LAQQWE", true).should == Set.new(["ref:2"])
      Rifle.search("KJ/LAQQWE-2", true).should == Set.new(["ref:2"])
    end

    it "Numbers" do
      # Test store numbers
      Rifle.store("ref:3", {ref: "123467891"})

      Rifle.search("123467891", true).should == Set.new()
      Rifle.search("12346789", true).should == Set.new()
    end

    it "Ignored keys" do
      # Test store numbers

      Rifle.settings.ignored_keys << :ignore_me
      Rifle.store("ref:4", {
        ignore_me: 'Fish',
        but_not_me: 'License',
        created_at: '20th December 2012'
      })

      Rifle.search("Fish", true).should == Set.new()
      Rifle.search("License", true).should == Set.new(['ref:4'])
      Rifle.search("December", true).should == Set.new()
    end

    it "Short names and flush" do
      # Test store short names
      Rifle.store("ref:bobby", {name: "Bobby"})
      Rifle.search("bobby", true).should == Set.new(["ref:bobby"])

      Rifle.flush
      Rifle.search("bobby", true).should == Set.new()
    end

  end

  context "without fuzzy matching" do
    before(:each) {
      Rifle.settings.fuzzy_matching = false
    }

    it "Without fuzzy matching" do
      Rifle.flush

      # Test capital urns
      result1 = {comment: "A great venue for cheese."}
      Rifle.store("TEST:1", result1)
      # Test subhashes
      Rifle.store("test:2", {comment: "I like chocolate cake", place: "My favourite restaurant"})
      # Test re-storing multiple times only returns one result
      Rifle.store("test:4", {comment: "Rain in spain"})
      Rifle.store("test:4", {comment: "Rain in spain"})
      # Test the root being an array
      Rifle.store("test:5", ['cheddar', 'stichelton', 'wensleydale'])
      # Test storing phone numbers
      Rifle.store("test:6", {number: "+447987654567"})


      p "Flushing all Rifle indices..."
      keys = Rifle.settings.redis.keys("rifle:*")
      keys.each { |k|
        p "#{k}"
      }
      p "Flushing all Rifle indices complete"


      Rifle.search("chocolate", true).should == Set.new(["test:2"])
      Rifle.search("kitchen", true).should == Set.new
      Rifle.search("cheese", true).should == Set.new(["TEST:1"])
      Rifle.search("Spain", true).should == Set.new(["test:4"])
      Rifle.search("Spain Rain Chocolate", true).should == Set.new()
      Rifle.search("SPAIN", true).should == Set.new(["test:4"])
      Rifle.search("Span", true).should == Set.new # Not using metaphones
      Rifle.search("wensleydale", true).should == Set.new(["test:5"]) # Search for array containers

      # Test that it can return the entire payload
      Rifle.search("cheese").to_json.should == [{urn: 'TEST:1', payload: result1}].to_json

      Rifle.settings.ignored_words << 'cheddar'
      # Test that replacing a payload removes old keys, including ones in the old payload that are now "ignored"
      Rifle.store("test:5", ['red leicster', 'lancashire', 'stichelton'])
      Rifle.search("wensleydale", true).should == Set.new()
      Rifle.search("cheddar", true).should == Set.new() # This should have been removed.
      Rifle.search("lancashire", true).should == Set.new(["test:5"])
      Rifle.search("red leicster", true).should == Set.new(["test:5"])
      Rifle.search("stichelton", true).should == Set.new(["test:5"])

      Rifle.search("07987654567", true).should == Set.new(["test:6"])
      Rifle.search("+(44)7987654567", true).should == Set.new(["test:6"])
      Rifle.search("+44 7987654567", true).should == Set.new(["test:6"])

    end

  end

  context 'ordering' do
    before(:each) {
      Rifle.settings.fuzzy_matching = false
    }

    it "returns results by updated at" do
      Rifle.flush

      # Add a load with update_at, and check results against a sorted version
      expected = []
      (10..90).to_a.shuffle.each_with_index { |n, i| # This produces a unique random list of numbers
        result = {
          'urn' => "test:#{i}",
          'comment' => "Fetch the comfy chair",
          'updated_at' => "20#{n+9}-01-04T1#{Random.rand(9)}:20:58Z"
        }
        expected << result
        Rifle.store(result['urn'], result)
      }
      expected.sort! { |a, b| DateTime.parse(b['updated_at']) <=> DateTime.parse(a['updated_at']) }

      res = Rifle.search("comfy", false).map { |r| r[:payload] }
      (DateTime.parse(res[0]['updated_at']) <=> DateTime.parse(res[1]['updated_at'])).should == 1 # zeroth result should be more recent
      res.should == expected # Predictable order
    end
  end

  context 'processor' do
    it 'should create lots of subwords for punctuation delimited strings, as well as the full string' do
      str = "Lots like +44799999999 O'Connor with 123,456 punctuation urn:this:that every/type"
      results = Rifle::Processor.new.get_words_array_from_text(str)
      results.sort.should == ["0799999999", "123", "123456", "44799999999", "456", "799999999", "connor", "every", "everytype", "like", "lots", "oconnor", "punctuation", "that", "this", "type", "urn", "urnthisthat", "with"].sort

    end
  end

  context 'additional_search_terms' do
    before(:each) {
      Rifle.flush
    }

    it 'should use additional_search_terms' do
      Rifle.store('test:10', ['red leicster', 'lancashire', 'stichelton'], 'Tasty') # Note, this additional search term has an uppercase
      Rifle.store('test:11', ['bourbon', 'whiskey'], ['spirits'])
      Rifle.search("leicster", true).should == Set.new(['test:10'])
      Rifle.search("tasty", true).should == Set.new(['test:10'])
      Rifle.search("spirits", true).should == Set.new(['test:11'])

      # Check that the returned payload doesn't include the additional search terms
      Rifle.search("bourbon").to_json.should_not include('spirits')
    end
  end


end
