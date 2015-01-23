require "mellon"

$stderr.puts "If asked for a password, just press enter. There is no password."

keychain_path = File.expand_path("./temporary_keychain.keychain", __dir__)
original_keychain_path = File.expand_path("./keychain.keychain", __dir__)

RSpec.configure do |config|
  config.around do |example|
    FileUtils.cp(original_keychain_path, keychain_path)
    example.run
    FileUtils.rm(keychain_path)
  end

  define_method :keychain_path do
    keychain_path
  end

  config.include(Module.new do
    def stub_command(command, stdout: "", stderr: "", status: 0)
      expect(Mellon::Utils).to receive(:sh).with(*command.split(" ")) { |&block|
        if block
          block[stdout, stderr]
        else
          stdout
        end
      }
    end
  end)
end
