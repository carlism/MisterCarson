require 'rule'
require 'spec_helper'

describe Rule do
    subject { Rule.new(:test_rule) }

    it "initializes with a name" do
        subject.name.should be :test_rule
    end

    it "gets to know how it's triggered" do
        subject.triggered_by :some_event
        subject.event_channel.should == "some_event"
    end

    it "lets you define a call-back for the trigger" do
        subject.on_message do |message|
            fail "this shouldn't actually execute"
        end
        subject.event_handler.should_not be_nil
    end

    it "will call the call-back when triggered" do
        test_string = "x"
        subject.on_message do |message|
            test_string += "called with #{message}"
        end
        subject.trigger "msg"
        test_string.should == "xcalled with msg"
    end
end
