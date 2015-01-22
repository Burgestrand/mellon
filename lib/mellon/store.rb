require "yaml"

module Mellon
  # Used for storing multiple values in a single Keychain entry.
  #
  # This is useful for configuring applications, e.g. having one entry per application,
  # where each entry contains all configuration for said application.
  class Store
    attr_reader :project_name
    attr_reader :keychain
    attr_reader :serializer

    # @example use keychain where entry exists, or default keychain
    #   Store.new("myapp")
    #
    # @example automatically find keychain
    #   Store.new("myapp", "shared_keychain")
    #
    # @example explicitly use keychain
    #   Store.new("myapp", Mellon::Keychain.new("/path/to/keychain.keychain"))
    #
    # @overload initialize(project_name)
    # @overload initialize(project_name, keychain_name)
    # @overload initialize(project_name, keychain)
    #
    # @param [String] project_name
    # @param [String, Keychain, nil] keychain
    # @param [#dump, #load] serializer
    def initialize(project_name, keychain: Keychain.search(project_name), serializer: YAML)
      @project_name = project_name.to_s
      @keychain = if keychain.is_a?(Keychain)
        keychain
      elsif keychain.nil?
        Keychain.default
      else
        Keychain.find(keychain.to_s)
      end
      @serializer = serializer
    end

    # @see Hash#fetch
    def fetch(*args, &block)
      data.fetch(*args, &block)
    end

    # Retrieve a key from the store.
    #
    # @param [String] key
    # @return [String, nil] value stored, or nil
    def [](key)
      data[key]
    end

    # Set a key in the store.
    #
    # @param [String] key
    # @param [String] value
    def []=(key, value)
      dump data.merge(key => value)
    end

    # @return [Hash]
    def to_h
      data
    end

    private

    def data
      config = @keychain[@project_name]
      data = @serializer.load(config) if config
      data or {}
    end

    def dump(hash)
      @keychain[@project_name] = @serializer.dump(hash)
    end
  end
end
