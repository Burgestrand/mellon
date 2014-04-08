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

      def default
        keychain_path = Mellon.security("default-keychain")[KEYCHAIN_REGEXP, 1]
        Keychain.new(keychain_path)
      end

      def list
        Mellon.security("list-keychains").scan(KEYCHAIN_REGEXP).map do |(keychain_path)|
          Keychain.new(keychain_path)
        end
      end
    end

    def initialize(path)
      @path = path
      @name = File.basename(path, ".keychain")
    end

    attr_reader :path
    attr_reader :name

    def open
      command "unlock-keychain"
      yield self
    ensure
      command "lock-keychain"
    end

    def read(key)
      command "find-generic-password", "-g", "-l", key do |info, password_info|
        [parse_info(info), parse_password(password_info)]
      end
    end

    def write(key, data, options = {})
      options = DEFAULT_OPTIONS.merge(options)

      note_type = TYPES.fetch(options.fetch(:type).to_s)
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

      true
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
      password = [unpacked].pack("H*")

      parsed = Plist.parse_xml(password)
      if parsed and parsed["NOTE"]
        parsed["NOTE"]
      else
        password
      end
    end
  end
end
