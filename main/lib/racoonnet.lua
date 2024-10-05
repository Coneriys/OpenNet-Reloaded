local event = require("event")
local rn = {}

-- Функция для получения версии RacoonNet
function rn.ver(typ)
  if typ == "major" then
    return 0
  elseif typ == "minor" then
    return 3
  elseif typ == "text" then
    return "RacoonNet v0.3"
  else
    return "0.3"
  end
end

-- Функция для получения всех сообщений RacoonNet
function rn.receiveall(timeout)
  local ev = {event.pull(timeout, "racoonnet_message")}
  
  -- Проверяем, если событие не было получено
  if not ev[1] then
    return nil, "Время ожидания истекло или ошибка получения сообщения."
  end

  return ev, ev[2], ev[3], table.unpack(ev, 6)
end

-- Функция инициализации RacoonNet
function rn.init(data)
  if not data.type then
    return nil, "Отсутствует конфигурация RacoonNet. Запустите rnconfig."
  end
  
  -- Пытаемся загрузить соответствующий модуль
  local mod, err = pcall(require, "rn_" .. data.type)
  
  if not mod then
    return nil, "Ошибка загрузки модуля: " .. err
  end
  
  return mod:init(data)
end

return rn
