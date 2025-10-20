local redis = require "resty.redis"
local cjson = require "cjson"

local _M = {}

function _M.get(key)
    local red = redis:new()
    red:set_timeout(1000)
    
    -- Usar nombre del servicio directamente (Docker lo resuelve)
    local ok, err = red:connect("redis", 6379)
    if not ok then
        ngx.log(ngx.WARN, "Cache unavailable: ", err)
        return nil
    end
    
    local data, err = red:get(key)
    if not data or data == ngx.null then
        red:set_keepalive(10000, 100)
        return nil
    end
    
    red:set_keepalive(10000, 100)
    
    local success, decoded = pcall(cjson.decode, data)
    if not success then
        return nil
    end
    
    return decoded
end

function _M.set(key, value, ttl)
    local red = redis:new()
    red:set_timeout(1000)
    
    local ok, err = red:connect("redis", 6379)
    if not ok then
        ngx.log(ngx.WARN, "Cache unavailable: ", err)
        return false
    end
    
    local json_value = cjson.encode(value)
    red:setex(key, ttl or 300, json_value)
    red:set_keepalive(10000, 100)
    
    return true
end

return _M