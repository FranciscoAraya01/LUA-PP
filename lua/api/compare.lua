-- ============================================
-- ARCHIVO: lua/api/compare.lua
-- Versión corregida con información de país
-- ============================================

local cjson = require "cjson"
local cache = require "utils.cache"
local openmeteo = require "providers.openmeteo"

local args = ngx.req.get_uri_args()
local city1 = args.city1 or "Madrid"
local city2 = args.city2 or "Barcelona"

-- Verificar cache
local cache_key = "compare:" .. city1 .. ":" .. city2
local cached = cache.get(cache_key)
if cached then
    ngx.header["X-Cache"] = "HIT"
    ngx.header.content_type = "application/json"
    ngx.say(cjson.encode(cached))
    return
end

ngx.header["X-Cache"] = "MISS"
ngx.header.content_type = "application/json"

-- Obtener datos de ambas ciudades usando openmeteo
local data1, err1 = openmeteo.get_current(city1)
local data2, err2 = openmeteo.get_current(city2)

if not data1 or not data2 then
    ngx.status = 500
    ngx.say(cjson.encode({
        error = "No se pudieron obtener datos de comparación",
        details = {
            city1_error = err1,
            city2_error = err2
        }
    }))
    return
end

local comparison = {
    cities = {
        {
            name = data1.city_name or city1,
            country = data1.country or "",
            country_code = data1.country_code or "",
            temperature = data1.temperature,
            feels_like = data1.feels_like or data1.temperature,
            humidity = data1.humidity or 0,
            wind_speed = data1.wind_speed or 0,
            description = data1.description or ""
        },
        {
            name = data2.city_name or city2,
            country = data2.country or "",
            country_code = data2.country_code or "",
            temperature = data2.temperature,
            feels_like = data2.feels_like or data2.temperature,
            humidity = data2.humidity or 0,
            wind_speed = data2.wind_speed or 0,
            description = data2.description or ""
        }
    },
    differences = {
        temperature = math.floor((data1.temperature - data2.temperature) * 10) / 10,
        humidity = (data1.humidity or 0) - (data2.humidity or 0),
        wind_speed = math.floor(((data1.wind_speed or 0) - (data2.wind_speed or 0)) * 10) / 10
    },
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
}

-- Guardar en cache por 5 minutos
cache.set(cache_key, comparison, 300)

ngx.say(cjson.encode(comparison))