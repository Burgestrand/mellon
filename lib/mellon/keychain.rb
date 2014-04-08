require "plist"
require "open3"

module Mellon
  # Keychain provides simple methods for reading and storing keychain entries.
  class Keychain
    DEFAULT_OPTIONS = { type: :note }
    TYPES = {
      "note" => {
        kind: "secure note",
        type: "note"
      }
    }

    class << self
      # Find the first keychain that contains the key.
      #
      # @param [String] key
      # @return [Keychain, nil]
      def search(key)
        output = Mellon.security("find-generic-password", "-l", key)
        new(output[/keychain: "(.+)"/i, 1])
      rescue CommandError
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
        keychain_path = Mellon.security("default-keychain")[KEYCHAIN_REGEXP, 1]
        Keychain.new(keychain_path)
      end

      # @return [Array<Keychain>] all available keychains
      def list
        Mellon.security("list-keychains").scan(KEYCHAIN_REGEXP).map do |(keychain_path)|
          Keychain.new(keychain_path)
        end
      end
    end

    # Initialize a keychain on the given path.
    #
    # @param [String] path
    def initialize(path)
      @path = path
      @name = File.basename(path, ".keychain")
    end

    # @return [String] path to keychain
    attr_reader :path

    # @return [String] keychain name (without extension)
    attr_reader :name

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

    private

    # Read a key from the keychain.
    #
    # @param [String] key
    # @return [Array<Hash, String>, nil] tuple of entry info, and text contents, or nil if key does not exist
    def read(key)
      command "find-generic-password", "-g", "-l", key do |info, password_info|
        [parse_info(info), parse_contents(password_info)]
      end
    rescue CommandError => e
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
    # @option options [#to_s] :type (:note) one of Keychain::TYPES
    # @option options [String] :account_name ("")
    # @option options [String] :service_name (key)
    # @option options [String] :label (service_name)
    # @raise [CommandError] if writing fails
    def write(key, data, options = {})
      info = build_info(key, options)

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
      info = build_info(key, options)

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
    # @see Mellons.h
    def command(*command, &block)
      command += [path]
      Mellon.security *command, &block
    end

    private

    # Build an info hash used for #write and #delete.
    #
    # @param [String] key
    # @param [Hash] options
    # @return [Hash]
    def build_info(key, options = {})
      options = DEFAULT_OPTIONS.merge(options)

      note_type = TYPES.fetch(options.fetch(:type, :note).to_s)
      account_name = options.fetch(:account_name, "")
      service_name = options.fetch(:service_name, key)
      label = options.fetch(:label, service_name)

      {
        account_name: account_name,
        service_name: service_name,
        label: label,
        kind: note_type.fetch(:kind),
        type: note_type.fetch(:type),
      }
    end

    # Parse entry information.
    #
    # @param [String] info
    # @return [Hash]
    def parse_info(info)
      extract = lambda { |key| info[/#{key}.+=(?:<NULL>|[^"]*"(.+)")/, 1].to_s }
      {
        account_name: extract["acct"],
        kind: extract["desc"],
        type: extract["type"],
        label: extract["0x00000007"],
        service_name: extract["svce"],
      }
    end

    # Parse entry contents.
    #
    # @param [String]
    # @return [String]
    def parse_contents(password_info)
      unpacked = password_info[/password: 0x([a-f0-9]+)/i, 1]

      password = if unpacked
        [unpacked].pack("H*")
      else
        password_info[/password: "(.+)"/m, 1]
      end

      password ||= ""

      parsed = Plist.parse_xml(password.force_encoding("".encoding))
      if parsed and parsed["NOTE"]
        parsed["NOTE"]
      else
        password
      end
    end
  end
end
