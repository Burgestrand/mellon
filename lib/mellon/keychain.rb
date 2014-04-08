require "plist"

module Mellon
  class Keychain
    DEFAULT_OPTIONS = { type: :note }
    TYPES = {
      "note" => {
        kind: "secure note",
        type: "note"
      }
    }

    class << self
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

    # Open the keychain for the duration of the block, and automatically
    # close it once block has finished executing.
    #
    # @yield [keychain]
    # @yieldparam keychain [Keychain]
    def open
      command "unlock-keychain"
      yield self
    ensure
      command "lock-keychain"
    end

    # Read a key from the keychain.
    #
    # @param [String] key
    # @return [Array<Hash, String>, nil] tuple of entry info, and text contents, or nil if key does not exist
    def read(key)
      command "find-generic-password", "-g", "-l", key do |info, password_info|
        [parse_info(info), parse_password(password_info)]
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
      options = DEFAULT_OPTIONS.merge(options)

      note_type = TYPES.fetch(options.fetch(:type, :note).to_s)
      account_name = options.fetch(:account_name, "")
      service_name = options.fetch(:service_name, key)

      command "add-generic-password",
        "-a", account_name, # keychain omits account for notes
        "-s", service_name,
        "-l", options.fetch(:label, service_name),
        "-D", note_type.fetch(:kind),
        "-C", note_type.fetch(:type),
        "-T", "", # which applications have access (none)
        "-U", # upsert
        "-w", data
    end

    private

    def command(*command, &block)
      command += [path]
      Mellon.security *command, &block
    end

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

    def parse_password(password_info)
      unpacked = password_info[/password: 0x([a-f0-9]+)/i, 1]

      password = if unpacked
        [unpacked].pack("H*")
      else
        password_info[/password: "(.+)"/m, 1]
      end

      parsed = Plist.parse_xml(password.force_encoding("".encoding))
      if parsed and parsed["NOTE"]
        parsed["NOTE"]
      else
        password
      end
    end
  end
end
