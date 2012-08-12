module Rifle

  class Settings
    attr_accessor :ignored_words, :min_word_length, :redis, :use_rest_server, :resque_queue

    def ignored_words
      @ignored_words ||= ["the", "and", "you", "that"]
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