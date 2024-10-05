local component = require("component")
local sysutils = require("sysutils")
local forms = require("forms")
local term = require("term")
local theme = sysutils.gettheme()

local cardlist = {}

-- Функция для конфигурации карты
function configurate()
  local selectedCard = List1.items[List1.index]
  local port = tonumber(Edit1.text)
  
  -- Проверка на корректность выбранной карты и порта
  if selectedCard and (port or component.type(selectedCard) == "tunnel") then
    local config = {
      address = selectedCard,
      port = port,
      type = component.type(selectedCard)
    }
    sysutils.writeconfig("racoonnet", config)
    term.clear()
    forms.stop()
  else
    -- Если порт некорректен, очищаем ввод и показываем ошибку
    Edit1.text = ""
    Label3.visible = true
    Label3:redraw()
  end
end

-- Собираем список доступных сетевых карт (модемы и туннели)
for address in pairs(component.list("modem")) do
  cardlist[address] = "(Сетевая карта) " .. address
end
for address in pairs(component.list("tunnel")) do
  cardlist[address] = "(Туннель) " .. address
end

-- Если карт нет, показываем предупреждение и выходим
if next(cardlist) == nil then
  print("Нет доступных сетевых карт для конфигурации.")
  return
end

-- Очищаем терминал и настраиваем интерфейс
term.clear()
forms.ignoreAll()

-- Настройка основной формы
local Form1 = forms.addForm()
Form1.border = 1
Form1.H = 16
Form1.W = 50
Form1.color = theme.cl1[2]
Form1.fontcolor = theme.cl1[1]

-- Метка для выбора сетевой карты
local Label1 = Form1:addLabel(2, 2, "Выберите сетевую карту RacoonNet:")
Label1.W = 33
Label1.color = theme.cl1[2]
Label1.fontcolor = theme.cl1[1]

-- Список сетевых карт
local List1 = Form1:addList(2, 3)
List1.W = 48
List1.H = 6
List1.color = theme.cl1[2]
List1.fontcolor = theme.cl1[1]
List1.selColor = theme.cl3[2]
List1.sfColor = theme.cl3[1]

-- Заполнение списка карт
for addr, text in pairs(cardlist) do
  List1:insert(text, addr)
end

-- Метка для ввода порта
local Label2 = Form1:addLabel(5, 10, "Введите порт:")
Label2.W = 13
Label2.color = theme.cl1[2]
Label2.fontcolor = theme.cl1[1]

-- Метка для ошибки неверного порта
local Label3 = Form1:addLabel(2, 12, "Неверно указан порт!")
Label3.color = theme.cl2[2]
Label3.fontcolor = theme.cl2[1]
Label3.visible = false

-- Поле для ввода порта
local Edit1 = Form1:addEdit(20, 9)
Edit1.W = 8
Edit1.color = theme.cl1[2]
Edit1.fontcolor = theme.cl1[1]

-- Кнопка подтверждения
local Button1 = Form1:addButton(35, 9, "Готово", configurate)
Button1.H = 3
Button1.W = 8
Button1.color = theme.cl4[2]
Button1.fontcolor = theme.cl4[1]

-- Запуск формы
forms.run(Form1)
term.clear()
