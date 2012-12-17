require 'json'
require 'set'
require 'redis'
require 'text'
require_relative 'rifle/settings'
require_relative 'rifle/rifle_resque'
require_relative 'rifle/rifle_client'

module Rifle
  def self.flush
    p "Flushing all Rifle indices..."
    keys = Rifle.settings.redis.keys("rifle:*")
    keys.each { |k|
      Rifle.settings.redis.del(k)
    }
    p "Flushing all Rifle indices complete"
  end

  def self.store(urn, hash)
    Processor.new.index_resource(urn, hash)
  end

  def self.search(words, urns_only = false)
    Processor.new.search_for(words, urns_only)
  end

  class Processor

    def index_resource(urn, hash)
      p "Rifle indexing object with urn #{urn}"
      # First get the old values
      old_payload = get_payload_for_urn(urn)
      if old_payload
        old_words = traverse_object_for_word_set(old_payload)
        old_metaphones = get_metaphones_from_word_set(old_words)
      else
        old_metaphones = []
      end

      # Now get the new ones
      words = traverse_object_for_word_set(hash)
      metaphones = get_metaphones_from_word_set(words)

      # Clear out words that have been removed (but leave ones that are still present in the new version)
      (old_metaphones - metaphones).each do |metaphone|
        remove_urn_from_metaphone_set(urn, metaphone)
      end

      # And add the new ones (but don't bother with words that were in the old version or ignored words)
      (metaphones - old_metaphones).each do |metaphone|
        add_urn_to_metaphone_set(urn, metaphone)
      end

      # Save the entire payload for future reference
      save_payload(urn, hash)
      metaphones
    end

    def search_for(sentence, urns_only)
      p "Rifle searching for #{sentence}, urns only #{urns_only}"
      words = get_words_array_from_text(sentence)
      metaphones = get_metaphones_from_word_set(Set.new(words))

      urns = nil
      metaphones.each do |metaphone|
        new_urns = get_urns_for_metaphone(metaphone)
        p metaphone
        urns = urns.nil? ? Set.new(new_urns) : urns.intersection(new_urns)
      end
      urns ||= Set.new

      p "Rifle found #{urns.size} urns"
      if urns_only
        urns
      else
        urns.map { |u|
          {
              urn: u,
              payload: get_payload_for_urn(u)
          }
        }
      end
    end

    def traverse_object_for_word_set(input)
      words = Set.new
      examine_value(input, words)
      words
    end

    def examine_value(value, words)
      if value.is_a? Hash
        (value.keys - Rifle.settings.ignored_keys).each do |k|
          examine_value(value[k], words)
        end
      elsif value.is_a? Array
        value.each do |a|
          examine_value(a, words)
        end
      else
        words.merge(get_words_array_from_text(value))
      end
    end

    def get_words_array_from_text(text)
      return [] if !text.is_a?(String)
      text.downcase.split(/[^a-zA-Z0-9]/).select { |w| w.length >= Rifle.settings.min_word_length }
    end

    def get_metaphones_from_word_set(words)
      # Add extra search terms. EG, other phone number layouts
      words = Set.new(words.map { |w|
        # Here we have to strip all the front zeros and replace with 44.
        # Weirdly, the +can be ignored, it is not included in Redis keys.
        w.start_with?('0') ? "44#{w[1..-1]}" : w
      })

      # Removed ignored words
      words.subtract Rifle.settings.ignored_words
      # Get the parts
      if Rifle.settings.fuzzy_matching
        # Get metaphones
        ::Text::Metaphone.metaphone(words.to_a.join(' ')).split(' ')
      else
        # Get the raw words
        words.to_a
      end
    end

    def add_urn_to_metaphone_set(urn, metaphone)
      Rifle.settings.redis.sadd("rifle:m:#{metaphone}", urn)
    end

    def remove_urn_from_metaphone_set(urn, metaphone)
      Rifle.settings.redis.srem("rifle:m:#{metaphone}", urn)
    end

    def save_payload(urn, hash)
      Rifle.settings.redis.set("rifle:u:#{urn}", hash.to_json)
    end

    def get_urns_for_metaphone(metaphone)
      Rifle.settings.redis.smembers("rifle:m:#{metaphone}")
    end

    def get_payload_for_urn(urn)
      payload = Rifle.settings.redis.get("rifle:u:#{urn}")
      payload.nil? ? nil : JSON.parse(payload)
    end

  end

end
