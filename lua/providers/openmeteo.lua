-- ============================================
-- ARCHIVO: lua/providers/openmeteo.lua
-- Versión con información de país
-- ============================================

local http_client = require "utils.http_client"

local _M = {}

-- Geocoding para obtener coordenadas y país
local function get_coordinates(city)
    local url = "https://geocoding-api.open-meteo.com/v1/search"
    local params = {
        name = city,
        count = 1,
        language = "es"
    }
    
    local data, err = http_client.get(url, params)
    if err then
        ngx.log(ngx.ERR, "Geocoding error for ", city, ": ", err)
        return nil, "Geocoding failed: " .. err
    end
    
    if not data.results or #data.results == 0 then
        ngx.log(ngx.ERR, "City not found: ", city)
        return nil, "City not found"
    end
    
    local result = data.results[1]
    
    return {
        lat = result.latitude,
        lon = result.longitude,
        name = result.name,
        country = result.country or "Unknown",
        country_code = result.country_code or "",
        admin1 = result.admin1 or ""  -- Estado/Provincia
    }
end

function _M.get_current(city)
    local coords, err = get_coordinates(city)
    if err then
        ngx.log(ngx.ERR, "Open-Meteo get_current failed: ", err)
        return nil, err
    end
    
    local url = "https://api.open-meteo.com/v1/forecast"
    local params = {
        latitude = coords.lat,
        longitude = coords.lon,
        current_weather = "true",
        temperature_unit = "celsius",
        windspeed_unit = "ms"
    }
    
    local data, err = http_client.get(url, params)
    if err then
        ngx.log(ngx.ERR, "Open-Meteo weather API error: ", err)
        return nil, err
    end
    
    if not data.current_weather then
        ngx.log(ngx.ERR, "Open-Meteo: no current_weather in response")
        return nil, "No current weather data"
    end
    
    local current = data.current_weather
    
    return {
        provider = "Open-Meteo",
        city_name = coords.name,
        country = coords.country,
        country_code = coords.country_code,
        admin1 = coords.admin1,
        temperature = current.temperature,
        feels_like = current.temperature,
        wind_speed = current.windspeed,
        wind_direction = current.winddirection,
        weathercode = current.weathercode,
        timestamp = os.time()
    }
end

function _M.get_forecast(city, days)
    local coords, err = get_coordinates(city)
    if err then
        ngx.log(ngx.ERR, "Open-Meteo get_forecast failed: ", err)
        return nil, err
    end
    
    local url = "https://api.open-meteo.com/v1/forecast"
    local params = {
        latitude = coords.lat,
        longitude = coords.lon,
        daily = "temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max",
        timezone = "auto",
        forecast_days = days or 7
    }
    
    local data, err = http_client.get(url, params)
    if err then
        ngx.log(ngx.ERR, "Open-Meteo forecast API error: ", err)
        return nil, err
    end
    
    if not data.daily or not data.daily.time then
        ngx.log(ngx.ERR, "Open-Meteo: no daily forecast in response")
        return nil, "No forecast data"
    end
    
    local forecast = {}
    for i = 1, #data.daily.time do
        table.insert(forecast, {
            date = data.daily.time[i],
            max_temp = data.daily.temperature_2m_max[i],
            min_temp = data.daily.temperature_2m_min[i],
            precipitation = data.daily.precipitation_sum[i],
            wind_speed = data.daily.windspeed_10m_max[i]
        })
    end
    
    return {
        provider = "Open-Meteo",
        city = coords.name,
        country = coords.country,
        country_code = coords.country_code,
        forecast = forecast
    }
end

return _M