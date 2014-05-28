require "plist"

module Mellon
  # Keychain provides simple methods for reading and storing keychain entries.
  class Keychain
    ENTRY_MISSING = /SecKeychainSearchCopyNext/.freeze

    class << self
      # Find the first keychain that contains the key.
      #
      # @param [String] key
      # @return [Keychain, nil]
      def search(key)
        output = ShellUtils.security("find-generic-password", "-l", key)
        new(output[/keychain: "(.+)"/i, 1], ensure_exists: false)
      rescue CommandError => e
        raise unless e.message =~ ENTRY_MISSING
        nil
      end

      # Find a keychain matching the given name.
      #
      # @param [String] name
      # @return [Keychain]
      # @raise [KeyError] if no matching keychain was found
      def find(name)
        quoted = Regexp.quote(name)
        regexp = Regexp.new(quoted, Regexp::IGNORECASE)

        keychain = list.find do |keychain|
          keychain.path =~ regexp
        end

        if keychain.nil?
          raise KeyError, "Could not find keychain “#{name}” in #{list.map(&:name).join(", ")}"
        end

        keychain
      end

      # @return [Keychain] default keychain
      def default
        keychain_path = ShellUtils.security("default-keychain")[KEYCHAIN_REGEXP, 1]
        new(keychain_path, ensure_exists: false)
      end

      # @return [Array<Keychain>] all available keychains
      def list
        ShellUtils.security("list-keychains").scan(KEYCHAIN_REGEXP).map do |(keychain_path)|
          new(keychain_path, ensure_exists: false)
        end
      end
    end

    # Initialize a keychain on the given path.
    #
    # @param [String] path
    # @param [Boolean] ensure_exists check if keychain exists or not
    def initialize(path, ensure_exists: true)
      @path = path
      @name = File.basename(path, ".keychain")
      command "show-keychain-info" if ensure_exists
    end

    # @return [String] path to keychain
    attr_reader :path

    # @return [String] keychain name (without extension)
    attr_reader :name

    # Retrieve a value, but if it does not exist return the default value,
    # or call the provided block, or raise an error. See Hash#fetch.
    #
    # @param [String] key
    # @param default
    # @return [String] value for key, default, or value from block
    # @yield if key does not exist, and block is given
    # @raise [KeyError] if key does not exist, and no default is given
    def fetch(key, *args, &block)
      self[key] or {}.fetch(key, *args, &block)
    end

    # @param [String] key
    # @return [String, nil] contents of entry at key, or nil if not set
    def [](key)
      _, data = read(key)
      data
    end

    # Write data to entry key, or updating existing one if it exists.
    #
    # @param [String] key
    # @param [String] data
    def []=(key, data)
      info, _ = read(key)
      info ||= {}

      if data
        write(key, data, info)
      else
        delete(key, info)
      end
    end

    # Retrieve all available keys.
    #
    # @return [Array<String>]
    def keys
      Utils.parse_dump(command "dump-keychain").map do |keychain, info|
        info[:label]
      end
    end

    # @return a hash unique to keychains of the same path
    def hash
      path.hash
    end

    # @param other
    # @return [Boolean] true if the keychains have the same path
    def eql?(other)
      self == other or super
    end

    # @param other
    # @return [Boolean] true if the keychains have the same path
    def ==(other)
      if other.is_a?(Keychain)
        path == other.path
      else
        super
      end
    end

    private

    # Read a key from the keychain.
    #
    # @param [String] key
    # @return [Array<Hash, String>, nil] tuple of entry info, and text contents, or nil if key does not exist
    def read(key)
      command "find-generic-password", "-g", "-l", key do |info, password_info|
        [Utils.parse_info(info), Utils.parse_contents(password_info)]
      end
    rescue CommandError => e
      raise unless e.message =~ ENTRY_MISSING
      nil
    end

    # Write data with given key to the keychain, or update existing key if it exists.
    #
    # @note keychain entries are not unique by key, but also by the information
    #       provided through options; two entries with same key but different
    #       account name (for example), will become two different entries when
    #       writing.
    #
    # @param [String] key
    # @param [String] data
    # @param [Hash] options
    # @option options [#to_s] :type (:note) one of Mellon::TYPES
    # @option options [String] :account_name ("")
    # @option options [String] :service_name (key)
    # @option options [String] :label (service_name)
    # @raise [CommandError] if writing fails
    def write(key, data, options = {})
      info = Utils.build_info(key, options)

      command "add-generic-password",
        "-a", info[:account_name],
        "-s", info[:service_name],
        "-l", info[:label],
        "-D", info[:kind],
        "-C", info[:type],
        "-T", "", # which applications have access (none)
        "-U", # upsert
        "-w", data
    end

    # Delete the entry matching key and options.
    #
    # @param [String] key
    # @param [Hash] options
    # @option (see #write)
    def delete(key, options = {})
      info = Utils.build_info(key, options)

      command "delete-generic-password",
        "-a", info[:account_name],
        "-s", info[:service_name],
        "-l", info[:label],
        "-D", info[:kind],
        "-C", info[:type]
    end

    # Execute a command with the context of this keychain.
    #
    # @param [Array<String>] command
    def command(*command, &block)
      command += [path]
      ShellUtils.security *command, &block
    end
  end
end
