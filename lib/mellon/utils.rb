module Mellon
  module Utils
    module_function

    # Build an entry info hash.
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
    def parse_contents(password_string)
      unpacked = password_string[/password: 0x([a-f0-9]+)/i, 1]

      password = if unpacked
        [unpacked].pack("H*")
      else
        password_string[/password: "(.+)"/m, 1]
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
