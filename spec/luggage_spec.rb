require 'spec_helper'

describe Luggage do
  it "should have a VERSION constant" do
    subject.const_get('VERSION').should_not be_empty
  end

  include_context "factories"

  describe "::new" do
    it "proxies Luggage::Factory" do
      Luggage::Factory.should_receive(:new).with(:server => :foo, :authenticate => :bar)
      Luggage.new(:server => :foo, :authenticate => :bar)
    end
  end
end
