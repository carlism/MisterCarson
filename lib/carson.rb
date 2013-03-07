require "logger"
require "redis"
require "store"
require "rule"
require "singleton"

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
        @log = Logger.new(STDOUT)
        @log.level = Logger::DEBUG
        control_rule = Rule.new(:control)
        control_rule.instance_eval do
            triggered_by :mc_control
            on_message do |message|
                self.send message.to_sym
            end
        end
        @base_rules << control_rule
        @log.info "Carson initialized"
    end

    def rule(name, &blk)
        new_rule = Rule.new(name)
        @rules << new_rule
        new_rule.instance_eval(&blk)
    end

    def dispatch(channel, message)
        @log.info "Received message on #{channel}"
        matching_rules = (@base_rules + @rules).select{ |r| r.event_channel==channel }
        @log.debug "Dispatching message to #{matching_rules.size} rules"
        matching_rules.each do |rule|
            rule.trigger(message)
        end
    end

    def publish(channel, message)
        Redis.new.publish(channel.to_s, message)
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
        @log.info "Loaded #{@rules.size} rules"
    end

    def quit
        @run = false
        redis.unsubscribe
    end

    def launch
        load_rules
        while run do
            redis.subscribe( (@base_rules + @rules).map{ |r| r.event_channel } ) do |on|
                on.subscribe do |channel, subscriptions|
                    @log.info "Subscribed to ##{channel} (#{subscriptions} subscriptions)"
                end
                on.message do |channel, message|
                  dispatch(channel, message)
                end
                on.unsubscribe do |channel, subscriptions|
                    @log.info "Unsubscribed from ##{channel} (#{subscriptions} subscriptions)"
                end
            end
            load_rules if @run
        end
    end
end
