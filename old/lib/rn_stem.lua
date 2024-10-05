local event = require("event")
local component = require("component")
local computer = require("computer")
local stem = require("stem")
local serialization = require("serialization")
local card = {}

card.__index = card

-- Прямая отправка сообщения
function card:directsend(recAddr, recIP, ...)
  self.server:send(self.channel, serialization.serialize({recAddr, self.address, recIP, ...}))
end

-- Отправка сообщения
function card:send(recIP, ...)
  return self.server:send(self.channel, serialization.serialize({self.router, self.address, recIP, self.ip, ...}))
end

-- Получение сообщения
function card:receive(timeout)
  local ev, e
  repeat
    e = {event.pull(timeout, "stem_message")}
    if not e[3] then return nil end
    ev = serialization.unserialize(e[3])
    
    -- Ответ на ping
    if ev[1] == self.address and ev[5] == "ping" then
      self:send(ev[4], "pong")
      ev[1] = nil
    end
  until ev[1] == self.address and ev[3] == self.ip
  return table.unpack(ev, 4)
end

-- Отправка и получение сообщения
function card:sendrec(recIP, ...)
  local ok, err = self:send(recIP, ...)
  if ok then
    return self:receive(10)
  else
    return ok, err
  end
end

-- Инициализация сетевой карты
function card:init(data)
  local obj = {}
  setmetatable(obj, self)
  
  obj.address = data.address
  obj.master = data.master
  obj.shortaddr = obj.address:sub(1, 3)
  obj.channel = data.channel
  obj.host = data.host
  
  -- Подключение к Stem серверу
  obj.server = stem.connect(obj.host)
  if not obj.server then return nil, "Не удалось подключиться к Stem серверу!" end
  
  -- Подписка на канал
  local ok, err = obj.server:subscribe(obj.channel)
  if not ok then return nil, err end
  
  -- Обработка входящих сообщений
  event.listen("stem_message", function(_, _, e)
    local ev = serialization.unserialize(e)
    if ev[1] == obj.address or ev[1] == "" then
      event.push("racoonnet_message", obj.address, ev[2], 0, 0, table.unpack(ev, 3))
    end
  end)
  
  -- Если задан мастер-адрес, устанавливаем IP
  if obj.master then
    obj.ip = obj.master
    obj.routerip = obj.master
    obj.router = obj.address
    return obj
  end
  
  -- Запрос на получение IP
  obj.server:send(obj.channel, serialization.serialize({"", obj.address, "", "", "getip"}))
  while true do
    local ev, e, n
    n, _, e = event.pull(5, "stem_message")
    if e ~= nil then
      ev = serialization.unserialize(e)
      local addr, rout, locip, routip, mess = table.unpack(ev)
      if mess == "setip" then
        obj.ip = locip
        obj.router = rout
        obj.routerip = routip
        return obj
      end
    else
      return nil, "Нет ответа от роутера"
    end
  end
end

return card
