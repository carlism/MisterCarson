require 'carson'

class Rule
    attr_accessor :name
    attr_reader :event_channel
    attr_reader :event_handler

    def initialize(name)
        @name = name
    end

    def triggered_by(event_channel)
        @event_channel = event_channel
    end

    def on_message(&blk)
        @event_handler = blk
    end

    def trigger(message)
        Carson.instance.instance_exec(message, &@event_handler)
    end
end
