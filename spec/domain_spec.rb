require 'carson'

DOMAIN_RULES = File.open("domain_rules.rb").read

describe "HomeDomain" do
    subject { Carson.instance }

    before do
        subject.redis.should_receive(:get).with("mc_rules") { DOMAIN_RULES }
        subject.redis.should_receive(:keys).with("zw_node:*") { ["zw_node:02:1234","zw_node:02:2345","zw_node:02:3456"] }
        subject.redis.should_receive(:hget).with("zw_node:02:1234", "nodeName") { "Side Door Light" }
        subject.redis.should_receive(:hget).with("zw_node:02:2345", "nodeName") { "Other Thing" }
        subject.redis.should_receive(:hget).with("zw_node:02:3456", "nodeName") { "Flood Lights" }
    end

    it "turns on the floods when I turn on the side light" do
        subject.load_rules
        subject.redis.should_receive(:hget).with("zw_node:02:1234", "v_Basic") { "1" }
        subject.redis.should_receive(:publish).with(:zw_turn_on_node, "zw_node:02:3456")
        subject.dispatch(:zw_value_update, "zw_value:02:1234:valueId")
    end
end
