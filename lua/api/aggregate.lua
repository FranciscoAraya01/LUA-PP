local cjson = require "cjson"
local cache = require "utils.cache"
local openweather = require "providers.openweather"
local weatherapi = require "providers.weatherapi"
local openmeteo = require "providers.openmeteo"

local args = ngx.req.get_uri_args()
local city = args.city or "Madrid"

local cache_key = "aggregate:" .. city
local cached = cache.get(cache_key)
if cached then
    ngx.header["X-Cache"] = "HIT"
    ngx.say(cjson.encode(cached))
    return
end

ngx.header["X-Cache"] = "MISS"
ngx.header.content_type = "application/json"

-- Obtener datos de todos los proveedores
local providers_data = {}
local data1, _ = openweather.get_current(city)
local data2, _ = weatherapi.get_current(city)
local data3, _ = openmeteo.get_current(city)

if data1 then table.insert(providers_data, data1) end
if data2 then table.insert(providers_data, data2) end
if data3 then table.insert(providers_data, data3) end

if #providers_data == 0 then
    ngx.status = 500
    ngx.say(cjson.encode({ error = "No hay datos disponibles" }))
    return
end

-- Calcular promedios
local sum_temp = 0
local sum_humidity = 0
local sum_wind = 0
local count = #providers_data

for _, data in ipairs(providers_data) do
    sum_temp = sum_temp + (data.temperature or 0)
    sum_humidity = sum_humidity + (data.humidity or 0)
    sum_wind = sum_wind + (data.wind_speed or 0)
end

local result = {
    city = city,
    aggregated = {
        temperature_avg = math.floor(sum_temp / count * 10) / 10,
        humidity_avg = math.floor(sum_humidity / count),
        wind_speed_avg = math.floor(sum_wind / count * 10) / 10,
        sources_count = count
    },
    individual_sources = providers_data,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
}

cache.set(cache_key, result, 300)
ngx.say(cjson.encode(result))