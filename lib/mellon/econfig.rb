require "mellon"
require "econfig"
require "yaml"

module Econfig
  class Mellon
    def initialize(keychain = :default, project_name = Econfig.root)
      @project_name = project_name
      @keychain = if keychain == :default
        ::Mellon::Keychain.default
      else
        ::Mellon::Keychain.find(keychain)
      end
    end

    def get(key)
      load[key]
    end

    def set(key, value)
      dump load.merge(key => value)
    end

    private

    def load
      config = @keychain[@project_name]

      if config
        YAML.load(config)
      else
        {}
      end
    end

    def dump(hash)
      @keychain[@project_name] = YAML.dump(hash)
    end
  end
end

Econfig.backends << Econfig::Mellon.new("projects",
