local rn = require("racoonnet")
local component = require("component")
local sysutils = require("sysutils")

local opennet = {}
local card
local err

function opennet.ver()
  return rn.ver()
end

function opennet.getIP()
  local config = sysutils.readconfig("racoonnet")
  
  if not config.type then
    return nil, "Отсутствует конфигурация RacoonNet. Запустите rnconfig."
  end
  
  card, err = rn.init(config)
  
  if card then
    return card.ip, nil
  else
    return nil, err
  end
end

function opennet.send(recIP, ...)
  if not card then
    return nil, "Сеть не инициализирована. Пожалуйста, проверьте конфигурацию."
  end
  
  local success, errMsg = card:send(recIP, ...)
  
  if not success then
    return nil, "Ошибка отправки: " .. (errMsg or "неизвестная ошибка")
  end
  
  return true, nil
end

function opennet.receive(timeout)
  if not card then
    return nil, "Сеть не инициализирована. Пожалуйста, проверьте конфигурацию."
  end
  
  local packet, errMsg = card:receive(timeout)
  
  if not packet then
    return nil, "Ошибка получения: " .. (errMsg or "неизвестная ошибка")
  end
  
  return packet, nil
end

function opennet.sendrec(recIP, ...)
  if not card then
    return nil, "Сеть не инициализирована. Пожалуйста, проверьте конфигурацию."
  end
  
  local packet, errMsg = card:sendrec(recIP, ...)
  
  if not packet then
    return nil, "Ошибка отправки/получения: " .. (errMsg or "неизвестная ошибка")
  end
  
  return packet, nil
end

return opennet
