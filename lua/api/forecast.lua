local cjson = require "cjson"
local cache = require "utils.cache"
local openweather = require "providers.openweather"
local weatherapi = require "providers.weatherapi"
local openmeteo = require "providers.openmeteo"

local args = ngx.req.get_uri_args()
local city = args.city or "Madrid"
local days = tonumber(args.days) or 5
local provider = args.provider or "all"

local cache_key = "forecast:" .. city .. ":" .. days .. ":" .. provider
local cached = cache.get(cache_key)
if cached then
    ngx.header["X-Cache"] = "HIT"
    ngx.say(cjson.encode(cached))
    return
end

ngx.header["X-Cache"] = "MISS"
ngx.header.content_type = "application/json"

local result = {
    city = city,
    days = days,
    providers = {},
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
}

if provider == "all" or provider == "openweather" then
    local data, err = openweather.get_forecast(city, days)
    if data then
        table.insert(result.providers, data)
    end
end

if provider == "all" or provider == "weatherapi" then
    local data, err = weatherapi.get_forecast(city, days)
    if data then
        table.insert(result.providers, data)
    end
end

if provider == "all" or provider == "openmeteo" then
    local data, err = openmeteo.get_forecast(city, days)
    if data then
        table.insert(result.providers, data)
    end
end

cache.set(cache_key, result, 600)
ngx.say(cjson.encode(result))
