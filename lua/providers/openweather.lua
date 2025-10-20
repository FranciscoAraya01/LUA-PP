local http_client = require "utils.http_client"

local _M = {}

function _M.get_current(city)
    local api_key = os.getenv("OPENWEATHER_API_KEY") or "demo_key"
    
    local url = "https://api.openweathermap.org/data/2.5/weather"
    local params = {
        q = city,
        appid = api_key,
        units = "metric",
        lang = "es"
    }
    
    local data, err = http_client.get(url, params)
    if err then
        return nil, err
    end
    
    return {
        provider = "OpenWeatherMap",
        temperature = data.main.temp,
        feels_like = data.main.feels_like,
        humidity = data.main.humidity,
        pressure = data.main.pressure,
        description = data.weather[1].description,
        wind_speed = data.wind.speed,
        clouds = data.clouds.all,
        timestamp = os.time()
    }
end

function _M.get_forecast(city, days)
    local api_key = os.getenv("OPENWEATHER_API_KEY") or "demo_key"
    
    local url = "https://api.openweathermap.org/data/2.5/forecast"
    local params = {
        q = city,
        appid = api_key,
        units = "metric",
        cnt = (days or 5) * 8,
        lang = "es"
    }
    
    local data, err = http_client.get(url, params)
    if err then
        return nil, err
    end
    
    local forecast = {}
    for _, item in ipairs(data.list) do
        table.insert(forecast, {
            datetime = item.dt_txt,
            temperature = item.main.temp,
            description = item.weather[1].description,
            humidity = item.main.humidity,
            wind_speed = item.wind.speed
        })
    end
    
    return {
        provider = "OpenWeatherMap",
        city = city,
        forecast = forecast
    }
end

return _M
