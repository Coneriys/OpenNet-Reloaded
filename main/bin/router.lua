local component = require("component")
local event = require("event")
local rn = require("racoonnet")
local computer = require('computer')
local sysutils = require("sysutils")
local thread = require("thread")

local clients = {}
local clientscard = {}
local client_cache = {}  -- Кэш для клиентов
local wan
local lan = {}
local ip
local err
local config = sysutils.readconfig("router")
local lang = sysutils.readlang("router")

--//Функция отправки пакета по IP получателя
function route(recieverip, senderip, ... )
  local cl
  -- Используем кэш клиентов
  if not client_cache[recieverip] then
    for client in pairs(clients) do
      if recieverip:find(client) then
        client_cache[recieverip] = client
        break
      end
    end
  end
  cl = client_cache[recieverip]
  
  if cl then
    -- Отправляем пакет через LAN
    lan[clientscard[cl]:sub(1,3)]:directsend(clients[cl], recieverip, senderip, ...)
  else
    -- Если не найден LAN клиент, используем WAN
    if wan then
      wan:directsend(wan.router, recieverip, senderip, ...)
    else
      sysutils.log(lang.deliverr..": \""..recieverip.."\".", 2, "router")
    end
  end
end

--//Список команд роутера
commands = {}

--//Пинг
function commands.ping()
  sysutils.log(lang.ping..": "..sendIP, 1, "router")
  route(sendIP, recIP, "pong")
end

--//Версия
function commands.ver()
  sysutils.log(lang.ver..": "..sendIP, 1, "router")
  route(sendIP, recIP, "WiFi router ver 1.0")
end

--//Выдача IP
function commands.getip()
  if lan[acceptedAdr:sub(1,3)] then
    local adr = ip.."."..senderAdr:sub(1,3)
    
    -- Проверяем, не занят ли адрес
    if not clients[adr] then
      clients[adr] = senderAdr
      clientscard[adr] = acceptedAdr
      lan[acceptedAdr:sub(1,3)]:directsend(senderAdr, adr, ip, "setip")
      sysutils.log(lang.givenip..": "..adr, 1, "router")
    else
      sysutils.log(lang.ipalreadyassigned..": "..adr, 3, "router") -- Новое сообщение о том, что адрес уже занят
    end
  end
end

sysutils.log(lang.launch, 1, "router")
if not config.lan then
  sysutils.log(lang.noconfig, 4, "router")
  return
end

--//Инициализируем WAN карту
if config.wan and config.wan.type then
  wan, err = rn.init(config.wan)
  if wan then
    sysutils.log(string.format("%s: \"%s\". %s: \"%s\"", lang.waninit, wan.address:sub(1, 3), lang.gateway, wan.routerip), 0, "router")
  else
    sysutils.log(lang.wanerr..": \""..err.."\"!", 3, "router")
    return -- Завершаем выполнение, если WAN не инициализирован
  end
else
  sysutils.log(lang.nowan, 2, "router")
end

if wan then
  ip = wan.ip
else
  ip = computer.address():sub(1,3)
end
sysutils.log("IP: \""..ip.."\"", 1, "router")

--//Инициализируем LAN карты
for saddr, obj in pairs(config.lan) do
  obj.master = ip
  lan[obj.address:sub(1,3)], err = rn.init(obj)
  if lan[obj.address:sub(1,3)] then
    sysutils.log(string.format("%s: \"%s\"", lang.laninit, lan[obj.address:sub(1,3)].address:sub(1,3)), 0, "router")
  else 
    sysutils.log(lang.lanerr..": \""..err.."\"!", 3, "router")
  end
end

--//Маршрутизация
function routing()
  while true do
    local status, packet, acceptedAdr, senderAdr, recIP, sendIP, command = pcall(rn.receiveall)
    if not status then
      sysutils.log("Error receiving packet: " .. packet, 3, "router")
    else
      local unpacked_packet = table.unpack(packet, 9)
      if recIP == ip or recIP == "" then
        if commands[command] then
          commands[command](unpacked_packet)
        end  
      else
        route(recIP, sendIP, unpacked_packet)
      end
    end
  end
end

local t = thread.create(routing)

--//Graceful shutdown
function graceful_shutdown()
  sysutils.log(lang.shutdown, 1, "router")
  t:kill()
end

while true do
  ev = {event.pull(_, "key_down")}
  local key = ev[4]
  if key == 16 then -- Q
    graceful_shutdown()
    break
  end
end
