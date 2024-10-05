local comp = require("component")
local utils = require("sysutils")
local rconf = {
    wan = {},
    lan = {}
  }
local cardlist = {}

for addr in pairs(comp.list("modem")) do
    table.insert(cardlist, adrrs)
end

for addr in pairs(comp.list("tunnel")) do
    table.insert(cardlist, addrs)
end

function selectCard() 
    if #cardlist == 0 then
        return nil, nil
    end

    print("Выберите карту:")

    for i, addrs in ipairs(cardlist) do
        print(i..") "..addrs)
    end

    local answer = tonumber(io.read())

    if not answer or not cardlist[answer] do
        print("насисечник")
    end

    local cardAddr = cardlist[answ]
    local port
    local cardType = comp.type(cardAddr)

    if cardType == "tunnel" then
        port = 0
        else
            print("Введите порт: ")
            port = tonumber(io.read())
            if not port then
            print("порт насисечник")
            return nil, nil
        end
    end
    
    table.remove(cardlist, answ)
    return cardaddr, port, cardType
end

print("Выберите WAN-карту. Если вам он нахой не нужон, оставьте пустым")
rconf.wan.addrs, rconf.wan.port, rconf.wan.type = selectCard()

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

sysutils.writeconfig("router", rconf)
print("Конфигурация роутера успешно сохранена.")