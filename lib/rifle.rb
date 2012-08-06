require 'set'
require 'redis'
require 'text'

module Rifle

  class Settings
    attr_accessor :ignored_words, :min_word_length, :redis
    def ignored_words
      @ignored_words ||= ["the", "and", "you", "that"]
    end
    def min_word_length
      @min_word_length ||= 3
    end
    def redis
      @redis ||= Redis.new
    end
  end

  @@settings = Settings.new

  def self.settings
    @@settings
  end

  def self.process_resource(urn, hash)
    p = Processor.new
    p.index_resource(urn, hash)
  end

  def self.search(words)
    p = Processor.new
    p.search_for(words)
  end

  class Processor

    def index_resource(urn, hash)
      words = Set.new
      traverse_sentences(hash, words)
      metaphones = get_metaphones(words)
      metaphones.each do |metaphone|
        save_processed(urn, metaphone)
      end
      metaphones
    end

    def search_for(sentence)
      words = get_words_from_text(sentence)
      metaphones = get_metaphones(words)
      urns = Set.new
      metaphones.each do |metaphone|
        new_urns = get_urns_for_metaphone(metaphone)
        urns =urns.merge(new_urns)
      end
      urns
    end

    private

    def traverse_sentences(input, words)
      input.each do |key, value|
        examine_value(value, words)
      end
    end

    def examine_value(value, words)
      if value.is_a? Hash
        traverse_sentences(value, words)
      elsif value.is_a? Array
        value.each do |a|
          examine_value(a, words)
        end
      else
        words.add(get_words_from_text(value))
      end
    end

    def get_words_from_text(text)
      return [] if !text.is_a?(String)
      words = text.downcase.split(/[^a-zA-Z]/).select{|w| w.length >= Rifle.settings.min_word_length}
      return words - Rifle.settings.ignored_words
    end

    def get_metaphones(words)
      ::Text::Metaphone.metaphone(words.to_a.join(' ')).split(' ')
    end

    def save_processed(urn, metaphone)
      Rifle.settings.redis.sadd("rifle:#{metaphone}", urn)
    end

    def get_urns_for_metaphone(metaphone)
      Rifle.settings.redis.smembers("rifle:#{metaphone}")
    end

  end

end
