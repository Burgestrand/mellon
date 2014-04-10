require "mellon/version"
require "mellon/utils"
require "mellon/shell_utils"
require "mellon/keychain"
require "mellon/store"

module Mellon
  KEYCHAIN_REGEXP = /"(.+)"/

  DEFAULT_OPTIONS = { type: :note }
  TYPES = {
    "note" => {
      kind: "secure note",
      type: "note"
    }
  }

  class Error < StandardError; end
  class CommandError < Error; end
end
