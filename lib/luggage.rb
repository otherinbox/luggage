require 'luggage/version'

module Luggage
  def self.new(eea, &block)
    Factory.new(eea, &block)
  end
end
