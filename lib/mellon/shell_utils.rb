require "open3"
require "shellwords"

module Mellon
  module ShellUtils
    module_function

    def security(*command, &block)
      sh("security", *command, &block)
    end

    def sh(*command)
      $stderr.puts "$ " + command.join(" ") if $VERBOSE
      stdout, stderr, status = Open3.capture3(*command)

      stdout.chomp!
      stderr.chomp!

      if $DEBUG
        $stderr.puts stdout.gsub(/(?<=\n|\A)/, "--> ") unless stdout.empty?
        $stderr.puts stderr.gsub(/(?<=\n|\A)/, "--! ") unless stderr.empty?
      end

      unless status.success?
        error_string = Shellwords.join(command)
        error_string << "\n"

        stderr = "<no output>" if stderr.empty?
        error_string << "  " << stderr.chomp

        raise CommandError, "[ERROR] #{error_string}"
      end

      if block_given?
        yield [stdout, stderr]
      else
        stdout
      end
    end
  end
end
