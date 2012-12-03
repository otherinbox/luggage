require 'rspec'
require 'rspec/mocks'
require 'rspec/expectations'
require 'active_support/time'
require 'pry'

require 'luggage'
require 'net_imap'

include Luggage

RSpec.configure do |config|
  require File.dirname(__FILE__) + "/net_imap"
end

shared_context "factories" do
  let(:connection) do
    c = Net::IMAP.new("imap.foo.com")
    c.stub(:append)
    c.stub(:authenticate)
    c.stub(:create)
    c.stub(:delete)
    c.stub(:expunge)
    c.stub(:select)
    c.stub(:send_command)
    c.stub(:uid_store)
    c.stub(:uid_fetch).and_return( [{:attr => {"BODY[]" => "raw_body", "FLAGS" => [], "INTERNALDATE" => 1.day.ago.to_s}}]  )
    c.stub(:uid_search).and_return([1])
    c.stub(:list).and_return([])
    c
  end
  let(:factory) { Luggage.new(:connection => connection) }
  let(:mailbox) { Luggage::Mailbox.new(connection, :mailbox) }
  let(:message)  { Luggage::Message.new_local(connection, "Inbox") }
  let(:query_builder) { Luggage::MailboxQueryBuilder.new(mailbox) }
end
