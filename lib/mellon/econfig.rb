require "mellon"
require "econfig"
require "yaml"

module Econfig
  class Mellon < Mellon::Store
    alias_method :get, :[]
    alias_method :set, :[]=
  end
end
