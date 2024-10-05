local shell = require("shell")
local fs = require("filesystem")
local prefix = "https://raw.githubusercontent.com/Coneriys/OpenNet-Reloaded/main/main/"
local comp = require("computer")

-- Объявляем список файлов для скачивания
local files = {
    "/bin/chat.lua",
    "/bin/chat_server.lua",
    "/bin/ping.lua",
    "/bin/rnconfig.lua",
    "/bin/routconf.lua",
    "/bin/router.lua",
    "/bin/webserver.lua",
    "/bin/wr.lua",
    "/etc/config/sys.cfg",
    "/etc/lang/ru.router.lang",
    "/lib/opennet.lua",
    "/lib/racoonnet.lua",
    "/lib/rn_modem.lua",
    "/lib/rn_stem.lua",
    "/lib/rn_tunnel.lua",
}

-- Функция для скачивания файла с проверкой на существование
local function downloadFile(url, destination)
    if not fs.exists(destination) then
        local success = shell.execute("wget -f " .. url .. " " .. destination)
        if success then
            print("Successfully downloaded: " .. destination)
        else
            print("Failed to download: " .. destination)
        end
    else
        print("File already exists, skipping: " .. destination)
    end
end

-- Установка необходимых библиотек
downloadFile("https://pastebin.com/raw/iKzRve2g", "/lib/forms.lua")
downloadFile("https://pastebin.com/raw/C5aBuY5e", "/lib/rainbow.lua")
downloadFile("https://pastebin.com/raw/nt0j4iXU", "/lib/stem.lua")
downloadFile("https://pastebin.com/raw/e5uEpxpZ", "/lib/sysutils.lua")
downloadFile("https://pastebin.com/raw/WBH19bBg", "/boot/05_config.lua")

-- Создание директории для тем
local themesDir = "/etc/themes/"
if not fs.exists(themesDir) then
    fs.makeDirectory(themesDir)
end
downloadFile("https://pastebin.com/raw/00XsAdhf", themesDir .. "standart.thm")

-- Скачивание остальных файлов
for _, v in ipairs(files) do
    local fileDir = v:match(".*/")
    if not fs.exists(fileDir) then 
        fs.makeDirectory(fileDir) 
    end
    downloadFile(prefix .. v, v)
end

comp.shutdown(true)
