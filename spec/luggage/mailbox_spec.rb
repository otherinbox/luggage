require 'spec_helper'

describe Luggage::Mailbox do
  include_context "factories"

  describe "::new" do
    it "executes a passed block" do
      m = Luggage::Mailbox.new(connection, :mailbox) do
        @name = "woot"
      end
      expect(m.name).to eq("woot")
    end

    it "sets the connection" do
      expect(Luggage::Mailbox.new(connection, :mailbox).connection).to eq(connection)
    end

    it "sets the name" do
      expect(Luggage::Mailbox.new(connection, :mailbox).name).to eq(:mailbox)
    end
  end

  describe "message" do
    it "executes a passed block" do
      m = mailbox.message do
        subject("new subject")
      end
      expect(m.subject).to eq("new subject")
    end


    it "returns an Luggage::Message" do
      expect(mailbox.message).to be_a(Luggage::Message)
    end

    it "instantiates with expected arguments" do
      message = Luggage::Message.new(connection, mailbox, :foo => :bar)
      Luggage::Message.should_receive(:new).with(connection, mailbox, :foo => :bar).and_return(message)

      mailbox.message(:foo => :bar)
    end
  end

  describe "all" do
    it "returns a QueryBuilder" do
      expect(mailbox.all).to be_a(Luggage::MailboxQueryBuilder)
    end
  end

  describe "each" do
    it "delegates to QueryBuilder instance" do
      block = Proc.new {}
      Luggage::MailboxQueryBuilder.any_instance.should_receive(:each).with(&block)

      mailbox.each(&block)
    end
  end

  describe "first" do
    it "delegates to QueryBuilder instance" do
      Luggage::MailboxQueryBuilder.any_instance.should_receive(:first)

      mailbox.first
    end
  end

  describe "where" do
    it "delegates to QueryBuilder instance" do
      Luggage::MailboxQueryBuilder.any_instance.should_receive(:where).with(:foo => :bar)

      mailbox.where(:foo => :bar)
    end
  end

  describe "select!" do
    it "selects the mailbox" do
      connection.should_receive(:select).with(:mailbox)

      mailbox.select!
    end
  end

  describe "save!" do
    it "creates the mailbox if it doesn't exist" do
      connection.should_receive(:create).with(:mailbox)

      mailbox.save!
    end

    it "doesn't create the mailbox if the mailbox exists" do
      mailbox.stub(:exists?).and_return(true)
      connection.should_not_receive(:create)

      mailbox.save!
    end
  end

  describe "expunge!" do
    it "selects the mailbox" do
      connection.should_receive(:select).with(:mailbox)

      mailbox.expunge!
    end

    it "expunges the mailbox" do
      connection.should_receive(:expunge)

      mailbox.expunge!
    end
  end

  describe "delete!" do
    it "deletes the mailbox" do
      connection.should_receive(:delete)

      mailbox.delete!
    end
  end

  describe "exists?" do
    it "returns true if list includes the mailbox name" do
      connection.stub(:list).with("", :mailbox).and_return([:results])

      expect(mailbox.exists?).to be_true
    end

    it "returns false if the list doesn't include the mailbox name" do
      expect(mailbox.exists?).to be_false
    end
  end
end
