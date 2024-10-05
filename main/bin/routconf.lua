local component = require("component")
local sysutils = require("sysutils")
local rconf = {
  wan = {},
  lan = {}
}
local cardlist = {}

-- Сбор списка доступных модемов и туннелей
for address in pairs(component.list("modem")) do
  table.insert(cardlist, address)
end
for address in pairs(component.list("tunnel")) do
  table.insert(cardlist, address)
end

-- Функция для выбора карты
function selcard()
  if #cardlist == 0 then
    print("Нет доступных сетевых карт.")
    return nil, nil
  end

  print("Выберите карту:")
  for i, address in ipairs(cardlist) do
    print(i .. ") " .. address)
  end

  local answ = tonumber(io.read())
  if not answ or not cardlist[answ] then
    print("Некорректный выбор карты.")
    return nil, nil
  end

  local cardaddr = cardlist[answ]
  local port
  local cardType = component.type(cardaddr)

  if cardType == "tunnel" then
    port = 0
  else
    print("Введите порт: ")
    port = tonumber(io.read())
    if not port then
      print("Некорректный порт.")
      return nil, nil
    end
  end

  -- Удаляем выбранную карту из списка
  table.remove(cardlist, answ)
  return cardaddr, port, cardType
end

-- Выбор WAN-карты
print("Выберите WAN-карту. Введите \"N\", если у вас нет WAN-карты.")
rconf.wan.address, rconf.wan.port, rconf.wan.type = selcard()

-- Выбор LAN-карт
while true do
  print("Выберите LAN-карту. Введите \"N\" для завершения.")
  local address, port, cardType = selcard()
  if address then
    rconf.lan[address:sub(1, 3)] = {
      address = address,
      type = cardType,
      port = port
    }
  else
    break
  end
end

-- Запись конфигурации роутера
sysutils.writeconfig("router", rconf)
print("Конфигурация роутера успешно сохранена.")
