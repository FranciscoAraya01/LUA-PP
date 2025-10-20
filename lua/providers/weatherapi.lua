local http_client = require "utils.http_client"

local _M = {}

function _M.get_current(city)
    local api_key = os.getenv("WEATHERAPI_KEY") or "demo_key"
    
    local url = "https://api.weatherapi.com/v1/current.json"
    local params = {
        key = api_key,
        q = city,
        lang = "es"
    }
    
    local data, err = http_client.get(url, params)
    if err then
        return nil, err
    end
    
    return {
        provider = "WeatherAPI",
        temperature = data.current.temp_c,
        feels_like = data.current.feelslike_c,
        humidity = data.current.humidity,
        pressure = data.current.pressure_mb,
        description = data.current.condition.text,
        wind_speed = data.current.wind_kph / 3.6,
        clouds = data.current.cloud,
        timestamp = os.time()
    }
end

function _M.get_forecast(city, days)
    local api_key = os.getenv("WEATHERAPI_KEY") or "demo_key"
    
    local url = "https://api.weatherapi.com/v1/forecast.json"
    local params = {
        key = api_key,
        q = city,
        days = days or 3,
        lang = "es"
    }
    
    local data, err = http_client.get(url, params)
    if err then
        return nil, err
    end
    
    local forecast = {}
    for _, day in ipairs(data.forecast.forecastday) do
        table.insert(forecast, {
            date = day.date,
            max_temp = day.day.maxtemp_c,
            min_temp = day.day.mintemp_c,
            description = day.day.condition.text,
            humidity = day.day.avghumidity,
            wind_speed = day.day.maxwind_kph / 3.6
        })
    end
    
    return {
        provider = "WeatherAPI",
        city = city,
        forecast = forecast
    }
end

return _M
