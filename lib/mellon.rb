require "mellon/version"
require "mellon/shell_utils"
require "mellon/keychain"
require "mellon/store"

module Mellon
  KEYCHAIN_REGEXP = /"(.+)"/

  class Error < StandardError; end
  class CommandError < Error; end
end
