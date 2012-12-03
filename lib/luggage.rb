require 'net/imap'
require 'mail'
require 'uuidtools'

require 'luggage/factory'
require 'luggage/mailbox'
require 'luggage/mailbox_array'
require 'luggage/mailbox_query_builder'
require 'luggage/message'
require 'luggage/version'

module Luggage
  def self.new(*args, &block)
    Factory.new(*args, &block)
  end
end
