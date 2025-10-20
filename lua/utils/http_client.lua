local http = require "resty.http"
local cjson = require "cjson"

local _M = {}

-- Realiza petición GET y retorna datos JSON decodificados
function _M.get(url, params, headers)
    local httpc = http.new()
    httpc:set_timeout(5000)  -- 5 segundos timeout
    
    -- Realizar petición HTTP
    local res, err = httpc:request_uri(url, {
        method = "GET",
        query = params,
        headers = headers or {
            ["User-Agent"] = "WeatherAggregator/1.0"
        },
        ssl_verify = false  -- Desactivar verificación SSL para desarrollo
    })
    
    -- Validar respuesta
    if not res then
        ngx.log(ngx.ERR, "HTTP request failed: ", err)
        return nil, "HTTP request failed: " .. (err or "unknown error")
    end
    
    if res.status ~= 200 then
        ngx.log(ngx.WARN, "HTTP status: ", res.status, " for URL: ", url)
        return nil, "HTTP status: " .. res.status
    end
    
    -- Decodificar JSON
    local success, data = pcall(cjson.decode, res.body)
    if not success then
        ngx.log(ngx.ERR, "JSON decode failed for response: ", res.body)
        return nil, "JSON decode failed"
    end
    
    return data, nil
end

-- Realiza petición POST
function _M.post(url, body, headers)
    local httpc = http.new()
    httpc:set_timeout(5000)
    
    local encoded_body = cjson.encode(body)
    
    local res, err = httpc:request_uri(url, {
        method = "POST",
        body = encoded_body,
        headers = headers or {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "WeatherAggregator/1.0"
        },
        ssl_verify = false
    })
    
    if not res then
        return nil, "HTTP request failed: " .. (err or "unknown error")
    end
    
    if res.status < 200 or res.status >= 300 then
        return nil, "HTTP status: " .. res.status
    end
    
    local success, data = pcall(cjson.decode, res.body)
    if not success then
        return nil, "JSON decode failed"
    end
    
    return data, nil
end

return _M