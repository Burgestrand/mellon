require "mellon/version"
require "mellon/keychains"

module Mellon
  class << self
    def keychain(name)
      keychain = keychains.find { |keychain| keychain === name }

      if keychain.nil?
        crash "Could not find keychain “#{name}” in #{keychains.map(&:name).join(", ")}"
      end

      keychain
    end

    def keychains
      sh("security", "list-keychains").scan(/"(.+)"/).map do |(keychain)|
        Keychain.new(keychain)
      end
    end

    private

    def crash(message)
      $stderr.puts "[ERROR] #{message}"
      exit false
    end

    def sh(*command)
      output, stderr, status = Open3.capture3(*command)

      unless status.success?
        error_string = Shellwords.join(command)
        error_string << "\n"

        stderr = "<no output>" if stderr.empty?
        error_string << "  " << stderr.chomp

        Mellon.crash(error_string)
      end

      output.chomp
    end
  end
end
