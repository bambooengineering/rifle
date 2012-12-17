module Rifle

  class Settings
    attr_accessor :ignored_words, :ignored_keys, :min_word_length, :redis, :use_rest_server, :resque_queue, :fuzzy_matching

    def ignored_words
      @ignored_words ||= ["the", "and", "you", "that"]
    end

    def ignored_keys
      @ignored_keys ||= [:created_at, :updated_at]
    end

    def fuzzy_matching
      @fuzzy_matching.nil? ? false : @fuzzy_matching
    end

    def min_word_length
      @min_word_length ||= 3
    end

    def resque_queue
      @resque_queue ||= :rifle
    end

    def redis
      @redis ||= Redis.current
    end
  end

  @@settings = Settings.new

  def self.settings
    @@settings
  end
end