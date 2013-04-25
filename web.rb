require 'sinatra'
require 'redis'
require 'json'

def load_node(nodeId)
  result = Redis.new.hgetall(nodeId)
  result["nodeKey"] = nodeId
  result
end

get '/node' do
  content_type :json
  redis = Redis.new
  redis.keys("zw_node:*").map { |key|
    {key: key, name: redis.hget(key, "nodeName"), v_Basic: redis.hget(key, "v_Basic")}
  }.to_json
end

get '/node/:nodeId' do
  content_type :json
  load_node(params['nodeId']).to_json
end

post '/node/:nodeId' do
  content_type :json
  publish_key = params['nodeId'].split(":")[1..-1].join(":")
  case params['operation']
  when "on"
    Redis.new.publish("zw_turn_on_node", publish_key)
  when "off"
    Redis.new.publish("zw_turn_off_node", publish_key)
  when "set"
    Redis.new.publish("zw_set_node_#{params['field']}", "#{publish_key}:#{params['value']}")
  end
end

get '/rules' do
  content_type :json
  redis = Redis.new
  { :rules => redis.get("mc_rules")}.to_json
end
