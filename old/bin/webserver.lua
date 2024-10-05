local rn = require("racoonnet")
local sysutils = require("sysutils")
local component = require("component")
local io = require("io")
local filesystem = require("filesystem")
local thread = require("thread")
local event = require("event")
local card, err = rn.init(sysutils.readconfig("racoonnet"))
local config = {}
config.directory = "/www/"
local clientip, request, path

file_types = {
  html = "text/html",
  css = "text/css",
  js = "application/javascript",
  png = "image/png",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  gif = "image/gif",
  ico = "image/x-icon"
}

local codes = {
  [200] = "OK",
  [302] = "Found",
  [400] = "Bad Request",
  [403] = "Forbidden",
  [404] = "Not Found",
  [500] = "Internal Server Error"
}

if not card then
  sysutils.log("Ошибка подключения к сети: \""..err.."\"!", 4, "webserver")
  return
end

-- Отправка ошибок
function senderror(code)
  local codestr = code.." "..codes[code]
  local html = "<html><body>"..codestr.."</body></html>"
  local str = "HTTP/1.1 "..codestr.."\nContent-Type: text/html\nContent-Length:"..html:len().."\n\n"..html
  card:send(clientip, str)
end

-- Редирект
function redirect(redirto)
  local resp = "HTTP/1.1 302 Found\nLocation: "..redirto.."\n\n";
  card:send(clientip, resp)
end

-- Обработка запроса
function response()
  clientip, request = card:receive()
  if not request or request:sub(1,3) ~= "GET" then
    senderror(400)
    return
  end

  sysutils.log("Получен запрос. IP: \""..clientip.."\".", 1, "webserver")
  path = request:match("GET .* HTTP/"):sub(5, request:match("GET .* HTTP/"):len()-6):gsub("[\n ]", "")
  if not path or path:match("%.%.") then senderror(400) return end
  
  local fpath = filesystem.concat(config.directory, path)
  
  if not filesystem.exists(fpath) then
    senderror(404)
    return
  end

  -- Если это директория
  if filesystem.isDirectory(fpath) then 
    if path:sub(-1) ~= "/" then
      redirect(filesystem.concat(card.ip, path).."/")
      return
    end
    if filesystem.exists(filesystem.concat(fpath, "index.html")) then
      redirect(filesystem.concat(card.ip, path, "index.html"))
      return
    else
      local fcontent = "<html><body>Индекс \""..path.."\":<br><a href=\"../\">../</a><br>"
      for name in filesystem.list(fpath) do
        fcontent = fcontent.."<a href=\"./"..name.."\">"..name.."</a><br>"
      end
      fcontent = fcontent.."</body></html>"
      local resp = "HTTP/1.1 200 OK\nContent-Type: text/html\nContent-Length: "..fcontent:len().."\n\n"..fcontent
      card:send(clientip, resp)
      return
    end
  else
    if path:sub(-1) == "/" then
      redirect(filesystem.concat(card.ip, path))
      return
    end
  end

  local file = io.open(fpath, "r")
  if not file then
    senderror(500)
    return
  end

  local fcontent = file:read("*a")
  file:close()
  
  local ext = path:match("%.([%a%d]*)")
  local ftype = file_types[ext] or "text/plain"

  local resp = "HTTP/1.1 200 OK\nContent-Type: "..ftype.."\nContent-Length: "..fcontent:len().."\n\n"..fcontent
  card:send(clientip, resp)
end

sysutils.log("Запущен WEB сервер. IP: \""..card.ip.."\".", 0, "webserver")

-- Функция обработки клиентов в отдельном потоке
function server()
  while true do
    response()
  end
end

local t = thread.create(server)

while true do
  local ev = {event.pull(_, "key_down")}
  local key = ev[4]
  if key == 16 then -- Q для завершения сервера
    t:kill()
    break
  end
end
