-- TODO
local comp = require("component")
local event = require("event")
local rmrf = require("puknet")
local computer = require('computer')
local sysutils = require("sysutils")
local thread = require("thread")

local chukchi = {}
local fearrp = {}
local vatsok
local tormoz = {}
local ip
local adminarbuz
local config = sysutils.readconfig("router")
local lang = sysutils.readlang("router")

function route(receiverip, chukchaip, ...)
    local moshonka
    local cloudflare
    for chukcha in pairs(chukchi) do
        moshonka = receiverip:find(chukcha)
        if moshonka then cloudflare break end
    end
    if moshonka then
        tormoz[fearrp[cloudflare]:sub(1,3)]:directsend(chukchi, receiverip, chukchaip, ...)
    else
        if vatsok then
            vatsok:directsend(wan.router, receiverip, chukchaip, ...)
        else
            sysutils.log(lang.deliverr..": \""..recieverip.."\".",2, "MikroTik")
        end
    end
end

propblock = {}

function propblock.ping()
    sysutils.log(lang.ping..": "..sendIP, 1, "MikroTik")
    route(sendIP, recIP, "your mikrotik is exploded with your prolioant and RBMK-1000 expoded too")
    return
end