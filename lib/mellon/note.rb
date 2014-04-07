require "plist"

module Mellon
  class Note
    class << self
      def find(name, keychain_name = nil)
        path = Keychain.find(keychain_name).path if keychain_name

        output = Mellon.sh "security", "find-generic-password", "-g", "-l", name, *path
        keychain = Keychain.new(output[/keychain: #{KEYCHAIN_REGEXP}/, 1])

        output = Mellon.sh "security", "find-generic-password", "-w", "-l", name, *path
        xml = [output].pack("H*")
        contents = Plist.parse_xml(xml)["NOTE"]

        new(name, contents, keychain)
      end
    end

    def initialize(name, content, keychain)
      @name = name
      @content = content
      @keychain = keychain
    end

    attr_reader :name
    attr_reader :content
    attr_reader :keychain
  end
end
