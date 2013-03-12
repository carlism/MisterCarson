require "store"
require 'spec_helper'

describe Store do
    before do
        @redis_mock = double(:redis)
    end

    context "with basic store" do
        subject do
            Store.new(@redis_mock)
        end

        it "saves an individual value" do
            @redis_mock.should_receive(:put).with("the_key", "the data")
            subject[:the_key] = "the data"
        end

        it "provides an individual value" do
            @redis_mock.should_receive(:get).with("the_key") { "the data" }
            subject[:the_key].value.should == "the data"
        end

        it "saves a value into a hash" do
            @redis_mock.should_receive(:hset).with("the_key", "the_field", "the data")
            subject[:the_key][:the_field] = "the data"
        end

        it "provides a value from a hash" do
            @redis_mock.should_receive(:hget).with("the_key", "the_field") { "the data" }
            subject[:the_key][:the_field].value.should == "the data"
        end

        it "increments an individual value" do
            @redis_mock.should_receive(:incrby).with("the_key", "1") { "43" }
            subject[:the_key].increment.should == "43"
        end

        it "decrements an individual value" do
            @redis_mock.should_receive(:decrby).with("the_key", "1") { "41" }
            subject[:the_key].decrement.should == "41"
        end
    end
end
