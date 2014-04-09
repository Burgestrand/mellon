require "mellon"
require "econfig"

module Econfig
  class Mellon < Mellon::Store
    alias_method :get, :[]
    alias_method :set, :[]=
  end
end
