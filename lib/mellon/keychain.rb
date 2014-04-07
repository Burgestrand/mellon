module Mellon
  class Keychain
    class << self
      def find(name)
        keychain = list.find { |keychain| keychain === name }

        if keychain.nil?
          raise KeyError, "Could not find keychain “#{name}” in #{list.map(&:name).join(", ")}"
        end

        keychain
      end

      def default
        keychain_path = Mellon.sh("security", "default-keychain")[KEYCHAIN_REGEXP, 1]
        Keychain.new(keychain_path)
      end

      def list
        Mellon.sh("security", "list-keychains").scan(KEYCHAIN_REGEXP).map do |(keychain_path)|
          Keychain.new(keychain_path)
        end
      end
    end

    def initialize(path)
      @path = path
    end

    attr_reader :path

    def name
      File.basename(path, ".keychain")
    end

    def ===(name)
      quoted = Regexp.quote(name)
      path =~ Regexp.new(quoted, Regexp::IGNORECASE)
    end
  end
end
