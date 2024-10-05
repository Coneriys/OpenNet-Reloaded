local rn=require("racoonnet")
local component=require("component")
local sysutils=require("sysutils")

local opennet = {}
local card = {}
local err

function opennet.ver()
  return rn.ver()
end

function opennet.getIP()
  local config = sysutils.readconfig("racoonnet")
  if config.type then
    card, err = rn.init(config)
    if card then
      return card.ip, 0
    else
      return nil, err
    end
  else
    return nil, "Отсутствует конфигурация RacoonNet. Запустите rnconfig."
  end
end


function opennet.send(recIP, ... )
  return card:send(recIP, ... )
end

function opennet.receive(timeout)
  return card:receive(timeout)
end

function opennet.sendrec(recIP, ... )
  return card:sendrec(recIP, ... )
end

return opennet