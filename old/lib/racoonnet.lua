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
  
  print("Попытка загрузки модуля: rn_" .. data.type)
  local success, mod_or_err = pcall(require, "rn_" .. data.type)
  
  if not success then
    print("Ошибка загрузки модуля: " .. mod_or_err)
    return nil, "Ошибка загрузки модуля: " .. mod_or_err
  end
  
  print("Модуль загружен успешно: rn_" .. data.type)
  
  local init_result, init_err = mod_or_err:init(data)
  if not init_result then
    return nil, "Ошибка инициализации модуля: " .. init_err
  end

  return init_result
end

return rn
