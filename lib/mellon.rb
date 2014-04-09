require "mellon/version"
require "mellon/shell_utils"
require "mellon/keychain"

module Mellon
  KEYCHAIN_REGEXP = /"(.+)"/

  class Error < StandardError; end
  class CommandError < Error; end
end
