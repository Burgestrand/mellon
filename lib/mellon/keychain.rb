module Mellon
  class Keychain
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


  end
end
