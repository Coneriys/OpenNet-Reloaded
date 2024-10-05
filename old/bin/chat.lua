local gpu  = require("component").gpu
local text = require("text")
local wlen = require("unicode").wlen
local beep = require("computer").beep
local thread = require("thread")
local on   = require("opennet")
local term = require("term")
local event = require("event")

-- Получение IP или DNS сервера из аргументов
local server = ({...})[1]
if not server then
  print("Формат вызова:")
  print("chat <IP или dns-имя сервера>")
  return
end

-- Запрос имени пользователя через любое нажатие клавиши
ev, _, _, _, Name = event.pull(1, "key_up")
if not ev then
  term.write("Нажмите любую клавишу для ввода имени пользователя")
  ev, _, _, _, Name = event.pull("key_up")
end

-- Переменные для управления окном вывода
local cursorX, cursorY = 1, 1
local WinW, WinH = gpu.getResolution()
WinH = WinH - 2  -- Оставляем место для строки ввода
local Left, Top = 1, 1

-- Функция для вывода текста в окно чата
local function winwrite(value, color)
  if color then gpu.setForeground(color) end
  value = text.detab(tostring(value))
  if wlen(value) == 0 then return end
  
  local line, nl
  repeat
    line, value, nl = text.wrap(value, WinW - (cursorX - 1), WinW)
    gpu.set(cursorX + Left - 1, cursorY + Top - 1, line)
    cursorX = cursorX + wlen(line)
    
    if nl or (cursorX > WinW) then
      cursorX = 1
      cursorY = cursorY + 1
    end
    
    if cursorY > WinH then
      gpu.copy(Left, Top + 1, WinW, WinH - 1, 0, -1)
      gpu.fill(Left, WinH + Top - 1, WinW, 1, " ")
      cursorY = WinH
    end
  until not value

  if color then gpu.setForeground(0xFFFFFF) end
end

-- Функция для очистки экрана
local function winclear()
  gpu.fill(Left, Top, WinW, WinH, " ")
  cursorX, cursorY = 1, 1
  gpu.set(Left, Top + WinH, string.rep("═", WinW - 25) .. " Введите 'quit' для выхода")
end

-- Проверка подключения к сети OpenNet
ok, err = on.getIP()
if not ok then
  print(err)
  return
end

-- Функция для приема сообщений от сервера
local function getmess()
  while true do
    local status, ip, sender, mess = pcall(on.receive)
    if status then
      if ip == server then
        gpu.setForeground(0xFFFF00)
        winwrite(sender)
        if mess then winwrite(": ") end
        gpu.setForeground(0xFFFFFF)
        winwrite(mess or "")
        winwrite("\n")
      end
    else
      winwrite("Ошибка получения данных: " .. ip .. "\n", 0xFF0000)
    end
  end
end

-- Запуск потока для получения сообщений
local t = thread.create(getmess)

-- История сообщений
local History = {}

-- Очистка экрана и начало чата
winclear()
on.send(server, "login", Name)

while true do
  term.setCursor(Left, Top + WinH + 1)
  term.clearLine()
  
  local mess = term.read(History, false)
  mess = mess:gsub("\n", "")
  
  if mess == "quit" then
    break
  end
  
  if mess ~= "" and mess ~= History[#History] then
    History[#History + 1] = mess
  end
  
  on.send(server, "write", mess)
end

-- Отправка сообщения о выходе и завершение работы
on.send(server, "logout")
winwrite("Вы вышли из чата.\n", 0xFF0000)
os.sleep(1)
t:kill()
