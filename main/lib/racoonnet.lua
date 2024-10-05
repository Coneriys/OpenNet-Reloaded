local event = require("event")
local rn ={}

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

function rn.receiveall(timeout)
  local ev
  ev = {event.pull(timeout,"racoonnet_message")}
  return ev, ev[2], ev[3], table.unpack(ev, 6)
end

function rn.init(data)
  if not data.type then return nil, "Отсутствует конфигурация RacoonNet. Запустите rnconfig."end
  local mod = require("rn_"..data.type)
  return mod:init(data)
end

return rn
