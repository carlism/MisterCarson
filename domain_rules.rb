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

rule :switch_floods_with_door do
    triggered_by :zw_value_update
    on_message do |message|
        id = ZwaveId.new(message)
        if id.zw_node_key == @nodes["Side Door Light"]
            state = store[id.zw_node_key][:v_Basic]
            if state == "0"
                publish :zw_turn_off_node, @nodes["Flood Lights"]
            else
                publish :zw_turn_on_node, @nodes["Flood Lights"]
            end
        end
    end
end
