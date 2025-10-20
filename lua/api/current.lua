-- ============================================
-- ARCHIVO: lua/api/current.lua
-- Versión con información de país
-- ============================================

local cjson = require "cjson"
local cache = require "utils.cache"
local openweather = require "providers.openweather"
local weatherapi = require "providers.weatherapi"
local openmeteo = require "providers.openmeteo"

ngx.req.read_body()
local args = ngx.req.get_uri_args()
local city = args.city or "Madrid"
local provider = args.provider or "all"

-- Verificar cache
local cache_key = "current:" .. city .. ":" .. provider
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
    providers = {},
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
}

-- Variables para capturar información de país
local country_info = nil

if provider == "all" or provider == "openweather" then
    local data, err = openweather.get_current(city)
    if data then
        table.insert(result.providers, data)
    end
end

if provider == "all" or provider == "weatherapi" then
    local data, err = weatherapi.get_current(city)
    if data then
        table.insert(result.providers, data)
    end
end

if provider == "all" or provider == "openmeteo" then
    local data, err = openmeteo.get_current(city)
    if data then
        -- Capturar información del país del primer proveedor
        if not country_info and data.country then
            country_info = {
                country = data.country,
                country_code = data.country_code,
                city_name = data.city_name,
                admin1 = data.admin1
            }
        end
        table.insert(result.providers, data)
    end
end

if #result.providers == 0 then
    ngx.status = 500
    ngx.say(cjson.encode({
        error = "No se pudieron obtener datos de ningún proveedor"
    }))
    return
end

-- Agregar información de país al resultado principal
if country_info then
    result.country = country_info.country
    result.country_code = country_info.country_code
    result.city_name = country_info.city_name
    result.admin1 = country_info.admin1
end

-- Guardar en cache por 5 minutos
cache.set(cache_key, result, 300)

ngx.say(cjson.encode(result))