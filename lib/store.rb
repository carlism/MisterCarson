class Store
    def initialize(redis)
        @redis = redis
    end

    def []=(key, message)
        @redis.put(key.to_s, message)
    end

    def [](key)
        StoreHash.new(@redis, key)
    end

    class StoreData
        attr_reader :key
        attr_reader :value

        def initialize(key, value)
            @key = key
            @value = value
        end
    end

    class StoreHash < StoreData
        def initialize(redis, key)
            @redis = redis
            @key = key
        end

        def []=(field, message)
            @redis.hset(@key.to_s, field.to_s, message)
        end

        def [](field)
            StoreData.new(@key, @redis.hget(@key.to_s, field.to_s))
        end

        def value
            @redis.get(@key.to_s)
        end

        def increment(by="1")
            @redis.incrby(@key.to_s, by)
        end

        def decrement(by="1")
            @redis.decrby(@key.to_s, by)
        end
    end
end
