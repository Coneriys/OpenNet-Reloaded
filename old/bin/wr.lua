-- Импорт необходимых библиотек
local component = require("component")
local forms = require("forms")
local io = require("io")
local fs = require("filesystem")
local term = require("term")
local event = require("event")
local rn = require("racoonnet")
local sysutils = require("sysutils")
local gpu = component.gpu
local text = require("text")
local unicode = require("unicode")

-- Чтение конфигурации
local config = sysutils.readconfig("wr")

-- Ассоциация типов файлов с MIME-типами
local file_types = {
  html = "text/html",
  css = "text/css",
  js = "application/javascript",
  png = "image/png",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  gif = "image/gif",
  ico = "image/x-icon",
  txt = "text/plain"
}

-- Инициализация сетевой карты
local card, err = rn.init(sysutils.readconfig("racoonnet"))
if not card then
  sysutils.log("Ошибка подключения к сети: \"" .. err .. "\"!", 4, "browser")
  return
end

-- Параметры экрана
local wScr, hScr = gpu.getResolution()
local WinW = wScr - 4
local WinH = hScr - 8
local cursorX, cursorY = 1, 1
local ShiftX, ShiftY = 0, 0
local Left, Top = 3, 7
local Site = ""
local txColour = 0xFFFFFF
local bgColour = 0x000000
local tagColour = 0x0080FF
local History = {}
local objects = {}
local MainForm

-- Установка значений по умолчанию в конфигурации
config.downloads_dir = config.downloads_dir or "/home/downloads"
config.home = config.home or "/"

-- Игнорирование событий от других форм
forms.ignoreAll()

-- Функция для отрисовки заголовка
local function draw_header(label)
  local head = " Wet Racoon 1.1"
  if label then
    head = head .. " (" .. label .. ")"
  end
  Header.W = wScr - unicode.len(head) - 5
  head = head .. string.rep(" ", Header.W)
  Header.caption = head
  Header:redraw()
end

-- Функция для получения файла по пути
local function get_file(path)
  if not path or path == "" or path == "\n" then return end
  path = path:gsub("\n", "")
  
  if path:sub(1, 1) == "." then
    if Site:sub(-1) ~= "/" then
      Site = Site:match(".*/") or Site
    end
    path = fs.concat(Site, path)
  end
  
  if path:sub(1, 1) ~= "/" then
    return rn_request(path)
  else
    return local_request(path)
  end
end

-- Функция для перехода назад
local function back()
  if #History > 1 then
    table.remove(History)
    load(History[#History])
  end
end

-- Проверка нажатия на ссылку
local function linkcheck(_, _, X, Y)
  for _, obj in ipairs(objects) do
    if obj:check(X, Y) then
      obj:work()
      break
    end
  end
end

event.listen("touch", linkcheck)

-- Функция для записи текста в окно
local function winwrite(value)
  value = text.detab(tostring(value))
  if unicode.wlen(value) == 0 then return end
  local line, nl
  repeat
    if cursorY > WinH then return end
    line, value, nl = text.wrap(value, WinW - (cursorX - 2), WinW)
    if cursorY >= 1 then
      gpu.set(cursorX + Left - 1 - ShiftX, cursorY + Top - 1, line)
    end
    cursorX = cursorX + unicode.wlen(line)
    if nl or cursorX > WinW then
      cursorX = 1
      cursorY = cursorY + 1
    end
  until not value
end

-- Функция для очистки окна
local function winclear()
  gpu.setForeground(txColour)
  gpu.setBackground(bgColour)
  objects = {}
  gpu.fill(Left, Top, WinW, WinH, " ")
  cursorX, cursorY = 1, 1
end

-- Обработка тегов HTML
local tags = {}

tags['body'] = function(arg)
  local param = tonumber(arg.text)
  if param then
    txColour = param
    gpu.setForeground(param)
  end
  param = tonumber(arg.bgcolor)
  if param then
    bgColour = param
    gpu.setBackground(param)
    winclear()
  end
end

tags['font'] = function(arg)
  local param = tonumber(arg.color)
  if param then gpu.setForeground(param) end
  param = tonumber(arg.bgcolor)
  if param then gpu.setBackground(param) end
end

tags['/font'] = function()
  gpu.setForeground(txColour)
  gpu.setBackground(bgColour)
end

tags['br'] = function()
  cursorY = cursorY + 1
  cursorX = 1
end

tags['hr'] = function(arg)
  local param = tonumber(arg.color)
  if param then gpu.setForeground(param) end
  param = tonumber(arg.bgcolor)
  if param then gpu.setBackground(param) end
  if cursorX > 1 then
    cursorY = cursorY + 1
    cursorX = 1
  end
  winwrite(string.rep('─', WinW))
  gpu.setForeground(txColour)
  gpu.setBackground(bgColour)
end

local function line_check(obj, x, y)
  if y >= obj.y1 and y <= obj.y2 then
    if (x >= obj.x1 or y > obj.y1) and (x <= obj.x2 or y < obj.y2) then
      return true
    end
  end
  return false
end

local function ref_work(obj)
  if obj.target == "download" then
    download(obj.ref)
  else
    load(obj.ref)
  end
end

tags['a'] = function(arg)
  if arg.href then
    table.insert(objects, {
      check = line_check,
      x1 = cursorX + Left - 1 - ShiftX,
      y1 = cursorY + Top - 1,
      work = ref_work,
      ref = arg.href,
      target = arg.target,
      col = gpu.getForeground()
    })
  end
  local color = tonumber(arg.color) or tagColour
  gpu.setForeground(color)
end

tags['/a'] = function()
  local ref = objects[#objects]
  if ref and not ref.x2 then
    gpu.setForeground(ref.col or txColour)
    ref.x2 = cursorX + Left - 2 - ShiftX
    ref.y2 = cursorY + Top - 1
  end
end

local function tagWork(tag)
  local name = tag:match('%S+')
  if tags[name] then
    local params = {}
    for k, v in tag:gmatch('(%w+)=([^%s"]+)') do params[k] = v end
    for k, v in tag:gmatch('(%w+)="([^"]+)"') do params[k] = v end
    tags[name](params)
  else
    winwrite('<' .. tag .. '>')
  end
end

local function winline(line)
  if line then
    cursorY = line.Y - ShiftY
    cursorX = line.X
    local sLine = line.text
    while sLine:len() > 0 do
      local p1, p2 = sLine:find("<"), nil
      if p1 then p2 = sLine:find(">", p1) end
      if p2 then
        winwrite(sLine:sub(1, p1 - 1))
        tagWork(sLine:sub(p1 + 1, p2 - 1))
        sLine = sLine:sub(p2 + 1)
      else
        winwrite(sLine)
        sLine = ""
      end
    end
    if cursorY <= WinH then return true end
  end
  return false
end

local function htmltext()
  winclear()
  local line = 1
  for i = #lines, 1, -1 do
    if lines[i].Y <= ShiftY then line = i break end
  end
  while winline(lines[line]) do
    line = line + 1
    if lines[line] then
      lines[line].Y = ShiftY + cursorY
      lines[line].X = cursorX
    end
  end
end

local function codetext()
  winclear()
  for i = 1, WinH do
    if lines[i + ShiftY] then
      gpu.set(Left - ShiftX, i + Top - 1, lines[i + ShiftY].text)
    else
      break
    end
  end
end

local wintext = htmltext

local function winshift(shX, shY)
  ShiftX = ShiftX + shX
  ShiftY = ShiftY + shY
  if ShiftX < 0 then ShiftX = 0 end
  if ShiftY < 0 then ShiftY = 0 end
  wintext()
end

local function download(path)
  if not path then path = Site end
  local fname = path:match("/([^/]+)$") or "downloaded_file"
  SaveForm.src = path
  SavePath.text = fs.concat(config.downloads_dir, fname)
  forms.run(SaveForm)
end

local function rn_request(site)
  if card then
    local host, doc = site:match('([^/]+)/?(.*)')
    host = host or site
    doc = "/" .. (doc or "")
    local request = "GET " .. doc .. " HTTP/1.1\r\nHost: " .. host .. "\r\nConnection: close\r\n\r\n"
    
    card:send(host, request)
    local timeout = 5
    local response = {}
    local adr, data
    
    while true do
      adr, data = card:receive(timeout)
      if not adr then
        local err = "<html><body>Превышено время ожидания ответа.</body></html>"
        return err, err, nil, nil, site, "text/html"
      elseif adr == host then
        table.insert(response, data)
        if data:find("\r\n\r\n") then
          break
        end
      end
    end
    
    local full_response = table.concat(response)
    local headers_str, body = full_response:match("^(.-\r\n\r\n)(.*)")
    local headers = {}
    for line in headers_str:gmatch("([^\r\n]+)") do
      local key, value = line:match("^(.-):%s*(.*)")
      if key and value then
        headers[key:lower()] = value
      end
    end
    
    local code = tonumber(full_response:match("HTTP/%d%.%d (%d%d%d)"))
    local content_type = headers["content-type"] or "text/html"
    
    if code == 302 and headers["location"] then
      return get_file(headers["location"])
    else
      return full_response, body, code, headers, site, content_type
    end
  else
    local err = "<html><body>Ошибка подключения к сети OpenNet: <font color=0xFF0000>" .. err .. "</font></body></html>"
    return err, err, nil, nil, site, "text/html"
  end
end

local function local_request(path)
  if fs.exists(path) then
    if fs.isDirectory(path) then
      if path:sub(-1) ~= "/" then
        return get_file(path .. "/")
      else
        local fcontent = "<html><body>Индекс \"" .. path .. "\":<br><a href=\"../\">../</a><br>"
        for name in fs.list(path) do
          fcontent = fcontent .. "<a href=\"" .. name .. "\">" .. name .. "</a><br>"
        end
        fcontent = fcontent .. "</body></html>"
        return fcontent, fcontent, nil, nil, path, "text/html"
      end
    else
      local file = io.open(path, "r")
      if file then
        local body = file:read("*a")
        file:close()
        local ext = path:match("%.([%w%d]+)$") or "txt"
        local ftype = file_types[ext] or "text/plain"
        return body, body, nil, nil, path, ftype
      else
        local err = "<html><body>Ошибка при открытии файла!</body></html>"
        return err, err, nil, nil, path, "text/html"
      end
    end
  else
    local err = "<html><body>Файл не найден!</body></html>"
    return err, err, nil, nil, path, "text/html"
  end
end

local function render(text, content_type)
  text = tostring(text)
  lines = {}
  ShiftX, ShiftY = 0, 0
  txColour, bgColour = 0xFFFFFF, 0x000000
  if content_type == "text/html" then
    text = text:match("<body.->(.*)</body>") or text
    wintext = htmltext
  else
    wintext = codetext
  end
  lines = {}
  local line_num = 1
  for line in text:gmatch("[^\n]*") do
    lines[line_num] = {X = 1, Y = math.huge, text = line}
    line_num = line_num + 1
  end
  if lines[1] then
    lines[1].Y = 1
  end
  wintext()
end

local function load(sPath)
  local raw, body, code, headers, path, content_type = get_file(sPath)
  if not raw then return end
  Site = path
  AddressLine.text = path
  AddressLine:redraw()
  render(body, content_type)
  local title = body:match("<title>(.-)</title>") or ""
  draw_header(title)
  if History[#History] ~= Site then
    table.insert(History, Site)
  end
end

-- Создание форм и компонентов GUI

-- MainForm
MainForm = forms.addForm()
MainForm.border = 1

function MainForm:draw()
  forms.Form.draw(self)
  load(AddressLine.text)
end

-- Заголовок
Header = MainForm:addLabel(2, 2, "")
Header.W = wScr - 4

-- Кнопка закрытия
Close = MainForm:addButton(wScr - 3, 2, "X", forms.stop)
Close.W = 3
Close.color = 0xff3333

-- Адресная строка
AddressLine = MainForm:addEdit(26, 3, function() load(AddressLine.text) end)
AddressLine.W = wScr - 37

-- Кнопки навигации
Refresh = MainForm:addButton(3, 3, " Меню", function() MenuForm:setActive() end)
Refresh.H, Refresh.W = 3, 7
Back = MainForm:addButton(11, 3, "Назад", back)
Back.H, Back.W = 3, 7
Home = MainForm:addButton(19, 3, "Домой", function() load(config.home) end)
Home.H, Home.W = 3, 7
Go = MainForm:addButton(wScr - 10, 3, "Вперёд!", function() load(AddressLine.text) end)
Go.H, Go.W = 3, 9

-- Основная рамка
Frame1 = MainForm:addFrame(2, 6, 1)
Frame1.H = hScr - 6
Frame1.W = wScr - 2

-- Установка цветов при поддержке
if gpu.getDepth() > 1 then
  Go.color = 0x33cc33
  Back.color = 0x6699ff
  Home.color = 0x6699ff
  Refresh.color = 0x6699ff
  Close.color = 0xff3333
  Header.color = 0x333399
else
  Go.color = 0x000000
  Back.color = 0x000000
  Refresh.color = 0x000000
  Home.color = 0x000000
  Home.border = 2
  Go.border = 2
  Back.border = 2
  Refresh.border = 2
  Close.color = 0xffffff
  Close.fontColor = 0x000000
  Header.color = 0x000000
end

-- Форма сохранения файла
SaveForm = forms.addForm()
SaveForm.H = 9
SaveForm.W = 34
SaveForm.top = (hScr - SaveForm.H) / 2
SaveForm.left = (wScr - SaveForm.W) / 2
SaveForm.border = 1

local SaveLabel1 = SaveForm:addLabel(3, 2, "Куда Вы хотите сохранить файл?")
SaveLabel1.W = 30

local SavePath = SaveForm:addEdit(2, 3)
SavePath.W = 32

local function save_file()
  local save_to = SavePath.text
  local download_src = SaveForm.src
  if download_src and download_src ~= "" then
    if not fs.exists(fs.path(save_to)) then
      fs.makeDirectory(fs.path(save_to))
    end
    local file = io.open(save_to, "w")
    local _, body = get_file(download_src)
    file:write(body)
    file:close()
  end
  SaveForm:hide()
  MainForm:setActive()
end

local SaveSave = SaveForm:addButton(5, 6, "Сохранить", save_file)
SaveSave.H, SaveSave.W = 3, 11

local SaveCancel = SaveForm:addButton(20, 6, "Отмена", function()
  SaveForm:hide()
  MainForm:setActive()
end)
SaveCancel.H, SaveCancel.W = 3, 11

-- Меню
MenuForm = forms.addForm()
MenuForm.W = 20
MenuForm.H = 5
MenuForm.left = 3
MenuForm.top = 3

local Menu = MenuForm:addList(1, 1, function(_, _, item)
  MenuForm:hide()
  MainForm:setActive()
  if type(item) == "function" then item() end
end)
Menu.W = MenuForm.W
Menu.H = MenuForm.H

Menu:insert("Сохранить файл", download)
Menu:insert("Сделать домашней", function()
  config.home = AddressLine.text
  sysutils.writeconfig("wr", config)
end)
Menu:insert("Закрыть меню", function() end)

-- Запуск браузера
draw_header()
AddressLine.text = config.home
forms.run(MainForm)
term.clear()
