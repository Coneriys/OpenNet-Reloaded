local on = require("opennet")

local clients = {}
local myIP, err = on.getIP("chatroom")
if not myIP then
  print(err)
  return
end
print("Server started at IP: " .. myIP)

local sendIP, command

-- Функция для рассылки сообщений всем подключенным клиентам
local function broadcast(senderIP, message, ...)
  for ip in pairs(clients) do
    if ip ~= senderIP then  -- Не отправляем сообщение самому отправителю
      local status, err = pcall(on.send, ip, message, ...)
      if not status then
        print("Ошибка отправки на IP: " .. ip .. " - " .. err)
      end
    end
  end
end

-- Команды для чата
local commands = {}

-- Пинг
function commands.ping()
  on.send(sendIP, "pong")
end

-- Версия
function commands.ver()
  on.send(sendIP, "Разговорная комната 1.0")
end

-- Логин пользователя
function commands.login(Name)
  clients[sendIP] = Name
  broadcast(sendIP, Name .. " подключился(ась) к чату")
  print(Name .. " (" .. sendIP .. ") подключился(ась) к чату")
end

-- Сообщение в чат
function commands.write(message)
  local senderName = clients[sendIP] or "Неизвестный"
  broadcast(sendIP, senderName .. ":", message)
  print(senderName .. ": " .. message)
end

-- Логаут пользователя
function commands.logout()
  local senderName = clients[sendIP] or "Неизвестный"
  broadcast(sendIP, senderName .. " отключился(ась) от чата")
  print(senderName .. " (" .. sendIP .. ") отключился(ась) от чата")
  clients[sendIP] = nil
end

-- Основной цикл обработки входящих данных
while true do
  local dat = {on.receive()}
  sendIP, command = dat[1], dat[2]

  if command then
    print("Получена команда от IP: " .. sendIP .. " - " .. command)

    -- Проверка наличия команды
    if commands[command] then
      local status, err = pcall(commands[command], table.unpack(dat, 3))
      if not status then
        print("Ошибка при выполнении команды: " .. err)
        on.send(sendIP, "Ошибка при выполнении команды: " .. err)
      end
    else
      print("Неизвестная команда: " .. command)
      on.send(sendIP, "Неизвестная команда: " .. command)
    end
  end
end
