require 'spec_helper'

describe Luggage::MailboxQueryBuilder do
  include_context "factories"

  describe "::new" do
    it "sets the mailbox" do
      expect(Luggage::MailboxQueryBuilder.new(mailbox).mailbox).to eq(mailbox)
    end

    it "requires a mailbox" do
      expect { Luggage::MailboxQueryBuilder.new(:not_a_mailbox) }.to raise_error(ArgumentError)
    end

    it "sets the connection" do
      expect(Luggage::MailboxQueryBuilder.new(mailbox).connection).to eq(connection)
    end
  end

  describe "#each" do
    it "yields to each member of #messages" do
      block = Proc.new {}
      query_builder.stub(:message_ids).and_return(['<one@example.com>', '<two@example.com>'])
      query_builder.messages.should_receive(:each) #.with(block)

      query_builder.each(&block)
    end
  end

  describe "::where" do
    it "returns self" do
      expect(query_builder.where(:foo => :bar)).to be_a(Luggage::MailboxQueryBuilder)
    end

    it "appends to the query" do
      expect(query_builder.where(:foo => :bar).where(:baz => :qux).query).to eq([:foo, :bar, :baz, :qux])
    end
  end

  describe "::[]" do
    it "returns messages[]" do
      query_builder.stub(:message_ids).and_return(['<one@example.com>', '<two@example.com>'])
      query_builder.messages.should_receive(:[]).with((1..2))

      query_builder[1..2]
    end
  end
end
