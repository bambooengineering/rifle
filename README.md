# Rifle

Rifle is a search engine backed by [Redis](www.redis.io). It is designed to be very simple and very fast.
Unlike other similar projects, it can operate not only in a simple single application mode, but also in a
distributed architecture without one single monolithic Rails application or redis instance.

# Installation

Just use the gem.

    gem 'rifle'

Now, all of your Rails based servers can write to and query the search engine using the following commands.
The store method can take a hash, or a json string. The search method returns an array of hashes, each with a
urn and a payload

    Rifle::Client.store('urn:monty:sketch:MP3242', {
        quote: 'I would like to buy a cat license'
    }

    Rifle::Client.search('Cat')

    # => [{
    #    urn: 'urn:monty:sketch:MP3242',
    #    payload: {
    #        quote: 'I would like to buy a cat license'
    #    }
    # }]


# Payloads

Payloads are expected to be hashes, identified by a company-wide unique id (a urn). These are indexed on store by exact words, and collapsed words if punctuation
is in the middle of a word.

E.g, given the following payload

    O'Connor has telephone +(44)798765432?

Any of the following search terms will match

    O'Connor
    Oconnor
    +44798765432
    +(44)798765432
    0798765432     # <= Special case, UK phone prefixes are ignored

# Fuzzy Matching

Items can be searched by metaphone if fuzzy_matching is enabled. That is, the search term need not be exact.

E.g, given the following payload

    Is this the right room for an argument?

Any of the following search terms will match

    Right
    rite
    RYTE
    Argument
    arguments
    RYTE  Argument       # => ie, an AND match

# Client configuration

You can supply a rifle_config.rb initializer with the following options. Defaults given in comments.

    Rifle.settings.ignored_words     # = ["the", "and", "you", "that"]
    Rifle.settings.min_word_length   # = 3
    Rifle.settings.resque_queue      # = :rifle
    Rifle.settings.redis             # = Redis.current  (used both by the client in "inline mode" and the server in "standalone mode")
    Rifle.settings.use_rest_server   # = nil
    Rifle.settings.fuzzy_matching    # = false

# Server deployment modes

Rifle searches happen inline in the current application, or can sent to an instance of Rifle running as a standalone server.

## Inline mode

No config necessary.

## Standalone Server Mode

Rifle can start on its own as a Rails application. To start the server, run

    rails -s

To use the standalone server, the clients must have the following in their initializer

    Rifle.settings.use_rest_server = 'http://<standalone.ip>:3000'

## License

MIT License.