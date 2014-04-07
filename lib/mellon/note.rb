require "plist"

module Mellon
  class Note
    class << self
      def find(name, keychain_name = nil)
        path = Keychain.find(keychain_name).path if keychain_name

        output = Mellon.sh "security", "find-generic-password", "-g", "-l", name, *path
        keychain = Keychain.new(output[/keychain: #{KEYCHAIN_REGEXP}/, 1])

        output = Mellon.sh "security", "find-generic-password", "-w", "-l", name, *path
        text = [output].pack("H*")
        xml = Plist.parse_xml(text)
        text = xml["NOTE"] if xml

        new(name, text, keychain)
      end
    end

    def initialize(name, content, keychain)
      @name = name
      @content = content
      @keychain = keychain

      @account = "" # keychain omits account
    end

    attr_reader :name
    attr_reader :content
    attr_reader :keychain

    def update(new_content)
      command = %w[security add-generic-password]
      command.push "-a", @account
      command.push "-s", name
      command.push "-D", "secure note"
      command.push "-C", "note"
      command.push "-T", ""
      command.push "-U"
      command.push "-w", new_content
      command.push keychain.path
      Mellon.sh(*command)

      @content = new_content
    end
  end
end
