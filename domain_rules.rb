@nodes = {}

class ZwaveId
    attr_accessor :home, :node, :value

    def initialize(zid)
        part = zid.split ":"
        self.send part[0].to_sym, *part[1..-1]
    end

    def zw_home home_id
        @home = home_id
    end

    def zw_node home_id, node_id
        @node = node_id
        zw_home home_id
    end

    def zw_value home_id, node_id, value_id
        @value = value_id
        zw_node home_id, node_id
    end

    def zw_home_key
        "zw_home:#{home}"
    end

    def zw_node_key
        "zw_node:#{home}:#{node}"
    end

    def zw_value_key
        "zw_value:#{home}:#{node}:#{value}"
    end
end

# load node addresses by name
redis.keys("zw_node:*").each do |node_key|
    @nodes[store[node_key][:nodeName].value] = node_key
end

# rule :switch_floods_with_door do
#     triggered_by :zw_value_update
#     on_message do |message|
#         id = ZwaveId.new(message)
#         if id.zw_node_key == @nodes["Side Door Light"]
#             state = store[id.zw_node_key][:v_Basic].value
#             floods = ZwaveId.new(@nodes["Flood Lights"])
#             if state.to_i > 0
#                 publish :zw_turn_on_node, "#{floods.home}:#{floods.node}"
#             else
#                 publish :zw_turn_off_node, "#{floods.home}:#{floods.node}"
#             end
#         end
#     end
# end

rule :outside_lights_with_car_signal do
    triggered_by :gpio_17
    on_message do |message|
        if message.to_i > 0
            side_door_light = ZwaveId.new(@nodes["Side Door Light"])
            front_door_light = ZwaveId.new(@nodes["Front Door Light"])
            state = store[side_door_light.zw_node_key][:v_Basic].value
            message = (state.to_i > 0) ? :zw_turn_off_node : :zw_turn_on_node
            [side_door_light, front_door_light].each do |light|
                publish message, "#{light.home}:#{light.node}"
            end
        end
    end
end

