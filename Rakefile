namespace :rules do
    require "redis"

    desc "Load a text file into carson as rules"
    task :load, :file_name do |t, args|
        redis = Redis.new
        redis.set "mc_rules", File.read(args[:file_name])
        redis.publish "mc_control", "reload"
    end

    desc "Dump carson rules out to a text file"
    task :dump, :file_name do |t, args|
        redis = Redis.new
        File.open(args[:file_name], "w") do |f|
            f.write(redis.get "mc_rules")
        end
    end
end

namespace :carson do
    require "redis"

    desc "get carson to shutdown gracefully"
    task :quit do |t|
        redis = Redis.new
        redis.publish "mc_control", "quit"
    end
end


