require 'carson'

@test_rules = <<END_OF_RULES
rule :one do
    triggered_by :channel1
    on_message do |message|
        data = "Hi, this is rule 1 with message: \#{message}"
        puts data
        publish :channel2, data
        store[:test_result_1][:key] = message
    end
end

rule :two do
    triggered_by :channel2
    on_message do |message|
        data = "Hi, this is rule 2 with message: \#{message}"
        puts data
        store[:test_result_2] = message
    end
end
END_OF_RULES

describe Carson do
    subject { Carson.instance }

    describe "has rules" do
        it "lets me define a simple rule" do
            run_string = "x"
            subject.rule :test_rule do
                triggered_by :evt_q
                run_string += "eval_rules_in #{name}"
            end
            subject.rules.size.should be 1
            subject.rules[0].event_channel.should be :evt_q
            run_string.should == "xeval_rules_in test_rule"
        end
    end

    describe "rules initalization" do
        it "should load the base rule for control" do
            subject.base_rules.select{|r| r.name==:control}.size.should be 1
        end

        it "should pass control messages thru to the Carson instance" do
            subject.should_receive :jump
            control_rule = subject.base_rules.select{|r| r.name==:control}.first
            control_rule.trigger("jump")
       end
    end

    describe "rule dispatch" do
        it "should dispatch a message to the control rule" do
            subject.should_receive :sit
            subject.dispatch(:mc_control, "sit")
        end

        it "should dispatch a message to both the base_rules and the user rules" do
            subject.rule :test_rule do
                triggered_by :mc_control
                on_message do |message|
                    sit
                end
            end
            subject.should_receive(:sit).twice
            subject.dispatch(:mc_control, "sit")
        end
    end

    describe "redis functions" do
        before do
            subject.rules.clear
        end

        it "has initialized a connection to redis" do
            subject.redis.should_not be_nil
        end

        it "delegates publish directly" do
            subject.rule :test_rule do
                triggered_by :mc_repeater
                on_message do |message|
                    publish :test_channel, message
                end
            end
            subject.redis.should_receive(:publish).with(:test_channel, "the data")
            subject.dispatch(:mc_repeater, "the data")
        end

        it "supports saving individual values" do
            subject.rule :test_rule do
                triggered_by :mc_write
                on_message do |message|
                    store[:some_key] = message
                end
            end
            subject.redis.should_receive(:put).with("some_key", "the data")
            subject.dispatch(:mc_write, "the data")
        end

        it "supports reading individual values" do
            test_result = ""
            subject.rule :test_rule do
                triggered_by :mc_write
                on_message do |message|
                    test_result = store[:some_key].value
                end
            end
            subject.redis.should_receive(:get).with("some_key") { "the data returned" }
            subject.dispatch(:mc_write, "the data")
            test_result.should == "the data returned"
        end

        it "supports saving hash values" do
            subject.rule :test_rule do
                triggered_by :mc_write
                on_message do |message|
                    store[:some_key][:some_field] = message
                end
            end
            subject.redis.should_receive(:hset).with("some_key", "some_field", "the data")
            subject.dispatch(:mc_write, "the data")
        end

        it "supports reading hash values" do
            test_result = ""
            subject.rule :test_rule do
                triggered_by :mc_write
                on_message do |message|
                    test_result = store[:some_key][:some_field].value
                end
            end
            subject.redis.should_receive(:hget).with("some_key", "some_field") { "the return data" }
            subject.dispatch(:mc_write, "the data")
            test_result.should == "the return data"
        end

        it "supports increment of a key" do
            test_result = 0
            subject.rule :test_rule do
                triggered_by :mc_write
                on_message do |message|
                    test_result = store[:some_key].increment
                end
            end
            subject.redis.should_receive(:incrby).with("some_key", "1") { "43" }
            subject.dispatch(:mc_write, "the data")
            test_result.should == "43"
        end

        it "supports decrement of a key" do
            test_result = 0
            subject.rule :test_rule do
                triggered_by :mc_write
                on_message do |message|
                    test_result = store[:some_key].decrement
                end
            end
            subject.redis.should_receive(:decrby).with("some_key", "1") { "41" }
            subject.dispatch(:mc_write, "the data")
            test_result.should == "41"
        end
    end

    describe "rule loading" do
        before do
        end
    end
end
