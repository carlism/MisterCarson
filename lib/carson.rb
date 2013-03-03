require "singleton"
require "redis"
require "store"

class Carson
    include Singleton
    attr_reader :base_rules
    attr_reader :rules
    attr_reader :redis
    attr_accessor :run

    def initialize
        @redis = Redis.new
        @base_rules = []
        @rules = []
        @run = true
        control_rule = Rule.new(:control)
        control_rule.instance_eval do
            triggered_by :mc_control
            on_message do |message|
                self.send message.to_sym
            end
        end
        @base_rules << control_rule
    end

    def rule(name, &blk)
        new_rule = Rule.new(name)
        @rules << new_rule
        new_rule.instance_eval(&blk)
    end

    def dispatch(channel, message)
        (@base_rules + @rules).select{ |r| r.event_channel==channel }.each do |rule|
            rule.trigger(message)
        end
    end

    def publish(channel, message)
        redis.publish(channel, message)
    end

    def store
        return Store.new(redis)
    end

    def reload
        redis.unsubscribe
    end

    def load_rules
        @rules.clear
        self.instance_eval redis.get("mc_rules")
    end

    def quit
        @run = false
    end

    def launch
        load_rules
        while run do
            redis.subscribe( (@base_rules + @rules).map{ |r| r.event_channel } ) do |on|
                on.message do |channel, message|
                  dispatch(channel, message)
                end
            end
            load_rules
        end
    end
end
