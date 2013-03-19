require 'spec_helper'

describe Luggage::Message do
  include_context "factories"

  describe "::new_local" do
    it "executes a passed block" do
      m = Luggage::Message.new_local(connection, "Inbox") do
        subject("new subject")
      end
      expect(m.subject).to eq("new subject")
    end

    it "returns an Luggage::Message" do
      expect(Luggage::Message.new_local(connection, "Inbox")).to be_a(Luggage::Message)
    end

    [:subject, :body, :to].each do |method|
      context "with #{method} passed as argument" do
        it "sets #{method} on Mail object" do
          message = Luggage::Message.new_local(connection, :mailbox, method => "string")
          expect(message.to_s).to match(/string/)
        end
      end
    end

    context "without template" do
      it "instatiates a Mail object" do
        mail = Mail.new
        Mail.should_receive(:new).and_return(mail)
        Luggage::Message.new_local(connection, :mailbox)
      end
    end

    context "with a template" do
      it "instatiates a Mail object" do
        Mail.should_receive(:read).and_return({})

        Luggage::Message.new_local(connection, :mailbox, :template =>"base")
      end
    end

    context "with flags passed as argument" do
      it "sets flags" do
        message = Luggage::Message.new_local(connection, :mailbox, :flags => :Seen)
        expect(message.flags).to include(:Seen)
      end
    end

    context "with flags array passed as argument" do
      it "sets flags" do
        message = Luggage::Message.new_local(connection, :mailbox, :flags => [:Seen])
        expect(message.flags).to include(:Seen)
      end
    end
  end

  describe "::new" do
    it "executes a passed block" do
      m = Luggage::Message.new(connection, "Inbox") do
        subject("new subject")
      end
      expect(m.subject).to eq("new subject")
    end

    it "sets connection" do
      expect(Luggage::Message.new(connection, :mailbox).connection).to eq(connection)
    end

    it "sets mailbox if Mailbox passed" do
      expect(Luggage::Message.new(connection, mailbox).mailbox).to eq(mailbox)
    end

    it "instantiates new mailbox if string passed" do
      expect(Luggage::Message.new(connection, :mailbox).mailbox).to be_a(Luggage::Mailbox)
    end

    it "sets date if passed" do
      date = Date.today - 2
      expect(Luggage::Message.new(connection, :mailbox, :date => date).date).to eq(date)
    end

    it "sets date to now if not passed" do
      expect(Luggage::Message.new(connection, :mailbox).date).to be_a(Time)
    end

    it "sets message_id if passed" do
      message_id = "<foo@example.com>"
      expect(Luggage::Message.new(connection, :mailbox, :message_id => message_id).message_id).to eq(message_id)
    end

    it "creates message_id if not passed" do
      expect(Luggage::Message.new(connection, :mailbox).message_id).to match(/<\S*@\S*>/)
    end
  end

  describe "#reload" do
    it "selects mailbox" do
      connection.should_receive(:select).with("Inbox")

      message.reload
    end

    it "fetches raw email" do
      connection.should_receive(:uid_fetch).
        with([1], ["FLAGS", "INTERNALDATE.PEEK", "BODY.PEEK[]"]).
        and_return( [{:attr => {"BODY[]" => "raw_body", "FLAGS" => [], "INTERNALDATE" => (Time.now - 60 * 60 * 24).to_s}}]  )

      message.reload
    end

    it "fetches flags" do
      connection.should_receive(:uid_fetch).
        with([1], ["FLAGS", "INTERNALDATE.PEEK", "BODY.PEEK[]"]).
        and_return( [{:attr => {"BODY[]" => "raw_body", "FLAGS" => [], "INTERNALDATE" => (Time.now - 60 * 60 * 24).to_s}}]  )

      message.reload
    end

    it "creates new Mail instance" do
      message # To instantiate the first one...

      Mail.should_receive(:new).with("raw_body")

      message.reload
    end
  end

  describe "#save!" do
    it "selects mailbox" do
      connection.should_receive(:select).with("Inbox")

      message.save!
    end

    it "appends message to mailbox" do
      message_date = Date.today - 2
      message.stub(:raw_message).and_return("Random Content")
      message.stub(:flags).and_return([:Seen])
      message.stub(:date).and_return(message_date)

      connection.should_receive(:append).with("Inbox", "Random Content", [:SEEN], message_date)
      message.save!
    end
  end

  describe "#to_s" do
    it "returns a string" do
      expect(message.to_s).to be_a(String)
    end
  end


  describe "#delete!" do
    it "selects mailbox" do
      connection.should_receive(:select).with("Inbox")

      message.delete!
    end

    it "sets Deleted flag" do
      connection.should_receive(:uid_store).with([1], "+FLAGS", [:Deleted])

      message.delete!
    end

    it "resets cached mail instance" do
      message.delete!
      expect(message.instance_variable_get(:@mail)).to be_nil
    end
  end

  describe "#exists?" do
    it "selects mailbox" do
      connection.should_receive(:select).with("Inbox")

      message.exists?
    end

    it "searches for message with message_id" do
      message.stub(:message_id).and_return("<foo@example.com>")
      connection.should_receive(:uid_search).with("HEADER.PEEK Message-ID <foo@example.com>").and_return([1])

      message.exists?
    end
  end
end
