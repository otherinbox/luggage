require 'spec_helper'

describe Luggage::Factory do
  include_context "factories"

  describe "::new" do
    it "accepts :connection" do
      expect(Luggage.new(:connection => connection).connection).to eq(connection)
    end

    it "accepts :server, :authenticate and creates a connection" do
      Net::IMAP.any_instance.stub(:authenticate).and_return(true)
      expect(Luggage.new(:server => :foo, :authenticate => "LOGIN username password").connection).to be_a(Net::IMAP)
    end

    it "accepts :server, :xoauth and creates a connection" do
      Net::IMAP.any_instance.stub(:send_command).and_return(true)
      expect(Luggage.new(:server => :foo, :xoauth => "token").connection).to be_a(Net::IMAP)
    end

    it "requires a way to build a connection" do
      expect { Luggage.new }.to raise_error(ArgumentError)
    end
  end

  describe '#message' do
    it "returns a Luggage::Message" do
      expect(factory.message(:mailbox)).to be_a(Luggage::Message)
    end

    it "passes arguments to initialize" do
      Luggage::Message.should_receive(:new).with(connection, "mailbox_name", :key => :value).and_return( double('Message').as_null_object )
      factory.message("mailbox_name", :key => :value)
    end
  end

  describe "#mailboxes" do
    before(:each) do
      connection.stub(:list).
        and_return([ 
          OpenStruct.new(:name => "Mailbox_1"), 
          OpenStruct.new(:name => "Mailbox_2"), 
          OpenStruct.new(:name => "Mailbox_3"),
          OpenStruct.new(:name => "Mailbox_4") ])
    end

    context "with no arguments" do
      it "returns an array of mailboxes defined on the remote server" do
        expect(factory.mailboxes.map(&:name)).to eq(["Mailbox_1", "Mailbox_2", "Mailbox_3", "Mailbox_4"])
      end
    end

    context "with a string argument (function-call syntax)" do
      it "returns a mailbox with the passed name" do
        expect(factory.mailboxes("foo").name).to eq("foo")
      end
    end

    context "with an iteger (function-call syntax)" do
      it "returns the nth mailbox on the remote server" do
        expect(factory.mailboxes(1).name).to eq("Mailbox_2")
      end
    end

    context "with a string argument (hash-index syntax)" do
      it "returns a mailbox with the passed name" do
        expect(factory.mailboxes["foo"].name).to eq("foo")
      end
    end

    context "with an integer (array-index syntax)" do
      it "returns the nth mailbox on the remote server" do
        expect(factory.mailboxes[1].name).to eq("Mailbox_2")
      end
    end

    context "with a range (array-slice syntax)" do
      it "returns a subset array of mailboxes defined on the remote server" do
        expect(factory.mailboxes[1..2].map(&:name)).to eq(["Mailbox_2", "Mailbox_3"])
      end
    end
  end
end
