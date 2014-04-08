require "mellon/version"
require "mellon/keychain"
require "mellon/note"

module Mellon
  KEYCHAIN_REGEXP = /"(.+)"/

  class << self
    def security(*command, &block)
      sh("security", *command, &block)
    end

    def sh(*command)
      $stderr.puts command.join(" ") if $VERBOSE
      output, stderr, status = Open3.capture3(*command)

      unless status.success?
        error_string = Shellwords.join(command)
        error_string << "\n"

        stderr = "<no output>" if stderr.empty?
        error_string << "  " << stderr.chomp

        $stderr.puts "[ERROR] #{error_string}"
        exit false
      end

      output.chomp
    end
  end
end
