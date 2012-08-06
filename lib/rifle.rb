require 'set'
require 'redis'
require 'text'

module Rifle
  @@ignore_words = ["the", "of", "to", "and", "a", "in", "is", "it", "you", "that"]
  @@redis = Redis.new

  def self.ignore_words
    @@ignore_words
  end

  def self.redis
    @@redis
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
      p metaphones
      metaphones.each do |metaphone|
        save_processed(urn, metaphone)
      end
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
      words = text.split(/[^a-zA-Z]/)
      return words - Rifle.ignore_words
    end

    def get_metaphones(words)
      ::Text::Metaphone.metaphone(words.to_a.join(' ')).split(' ')
    end

    def save_processed(urn, metaphone)
      Rifle.redis.sadd("rifle:#{metaphone}", urn)
    end

    def get_urns_for_metaphone(metaphone)
      Rifle.redis.smembers("rifle:#{metaphone}")
    end

  end

end
