module Mellon
  class Keychain
    def initialize(path)
      @path = path
    end

    attr_reader :path

    def name
      File.basename(path, ".keychain")
    end

    def ===(name)
      path =~ Regexp.new(name, Regexp::IGNORECASE)
    end
  end
end
