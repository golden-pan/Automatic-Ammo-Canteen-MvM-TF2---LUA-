--Canteener MvM by golden pan

local state = {
usedCanteen = false,
enabled = false,
_jDebounce = false
}

local ammoCfg = {
x = 10,
y = 60,
enabled = 0,
toggle_key = nil,
transparent = 0
}

local function SaveAmmoCfg(filename, cfg)
cfg.enabled = (cfg.enabled == true) and 1 or ((cfg.enabled == 1) and 1 or 0)
cfg.transparent = (cfg.transparent == true) and 1 or ((cfg.transparent == 1) and 1 or 0)
local f = io.open(filename, "w")
if not f then return false end
f:write("x=" .. tostring(math.floor(cfg.x)) .. "\n")
f:write("y=" .. tostring(math.floor(cfg.y)) .. "\n")
f:write("enabled=" .. tostring((cfg.enabled == 1) and 1 or 0) .. "\n")
if cfg.toggle_key then
f:write("toggle_key=" .. tostring(cfg.toggle_key) .. "\n")
end
f:write("transparent=" .. tostring((cfg.transparent == 1) and 1 or 0) .. "\n")
f:close()
return true
end

local function LoadAmmoCfg(filename)
local f = io.open(filename, "r")
if not f then return nil end
local cfg = {}
for line in f:lines() do
local k, v = line:match("^(.-)=(.+)$")
if k and v then
local n = tonumber(v)
cfg[k] = n or v
end
end
f:close()
if type(cfg.x) ~= "number" or type(cfg.y) ~= "number" then return nil end
return cfg
end

local TOGGLE_KEY = KEY_J
local IGNORE_TOGGLE_UNTIL = 0

local CFG_DIR="gp_cant"
local CFG_NAME="gp_cant_settings.cfg"
local function GP_TryMkdir(d)
pcall(function() filesystem.CreateDirectory(d) end)
pcall(function() filesystem.CreateDir(d) end)
pcall(function() file.CreateDir(d) end)
pcall(function() file.CreateDirectory(d) end)
pcall(function() file.CreateFolder(d) end)
pcall(function() os.execute('mkdir "'..d..'"') end)
pcall(function() os.execute("mkdir "..d) end)
end
local function GP_CfgPath()
GP_TryMkdir(CFG_DIR)
return CFG_DIR.."/"..CFG_NAME
end

do
local loaded = LoadAmmoCfg(GP_CfgPath())
if loaded then
ammoCfg.x = loaded.x
ammoCfg.y = loaded.y
if type(loaded.enabled) == "number" then ammoCfg.enabled = loaded.enabled end
if type(loaded.transparent) == "number" then ammoCfg.transparent = loaded.transparent end
if type(loaded.toggle_key) == "number" then
ammoCfg.toggle_key = loaded.toggle_key
TOGGLE_KEY = loaded.toggle_key
end
end
end

state.enabled = (ammoCfg.enabled == 1)

local UI = {
font = draw.CreateFont("Tahoma", 16, 600),
colors = {
gold = {255, 215, 0, 255},
gray = {150, 150, 150, 255},
background = {15, 15, 15, 230},
text = {255, 255, 255, 255}
}
}

local BOX_SIZE = 44

local MENU_W, MENU_H = 150, 74

local function AlphaBox(a)
if ammoCfg.transparent == 1 then
return math.max(18, math.floor(a * 0.38))
end
return a
end

local function ColorUI(r, g, b, a, mul)
if a == nil then a = 255 end
if mul == nil then mul = 1 end
local aa = math.floor(a * mul)
if aa < 0 then aa = 0 end
if aa > 255 then aa = 255 end
draw.Color(r, g, b, aa)
end

local function ColorBox(r, g, b, a, mul)
if a == nil then a = 255 end
if mul == nil then mul = 1 end
local aa = math.floor(a * mul)
if aa < 0 then aa = 0 end
if aa > 255 then aa = 255 end
draw.Color(r, g, b, AlphaBox(aa))
end

local KEY_NAME_MAP = {
a = KEY_A, b = KEY_B, c = KEY_C, d = KEY_D, e = KEY_E, f = KEY_F,
g = KEY_G, h = KEY_H, i = KEY_I, j = KEY_J, k = KEY_K, l = KEY_L,
m = KEY_M, n = KEY_N, o = KEY_O, p = KEY_P, q = KEY_Q, r = KEY_R,
s = KEY_S, t = KEY_T, u = KEY_U, v = KEY_V, w = KEY_W, x = KEY_X,
y = KEY_Y, z = KEY_Z,
space = KEY_SPACE,
shift = KEY_LSHIFT,
ctrl = KEY_LCONTROL,
alt = KEY_LALT
}

local isMouseDown = false
local downX, downY = 0, 0
local startBoxX, startBoxY = 0, 0
local isDragging = false
local clickCandidate = false
local DRAG_THRESHOLD = 4

local function IsGameBlocked()

local lboxMenuOpen = (gui and gui.IsMenuOpen and gui.IsMenuOpen()) or false
if engine.IsGameUIVisible() and not lboxMenuOpen then
return true
end
if engine.Con_IsVisible() then
return true
end
if (not engine.GetServerIP()) and (not lboxMenuOpen) then
return true
end
return false
end

local function ClampToScreen(x, y, w, h)
local sw, sh = draw.GetScreenSize()
if x < 0 then x = 0 end
if y < 0 then y = 0 end
if x + w > sw then x = sw - w end
if y + h > sh then y = sh - h end
return x, y
end

local menu = {

want = false,
anim = 0,
open = false,
waitKey = false,
waitKeyArmed = false,
lastR = false,
lastL = false,
keyPrev = {}
}

local PICK_KEYS = {}
do
local tmp = {}
for name, code in pairs(_G) do
if type(name) == "string" and type(code) == "number" and name:match("^KEY_") then
if not name:match("MOUSE") and not name:match("MWHEEL") and not name:match("BUTTON")
and name ~= "KEY_ESCAPE" then
tmp[#tmp+1] = code
end
end
end
table.sort(tmp)
local last = nil
for i = 1, #tmp do
local c = tmp[i]
if c ~= last then
PICK_KEYS[#PICK_KEYS+1] = c
last = c
end
end
end

local function KeyPressed(code)
local down = input.IsButtonDown(code)
local was = menu.keyPrev[code] or false
menu.keyPrev[code] = down
return down and not was
end

local function DrawButton(x, y, w, h, label, accent, mx, my, mul)
local hover = (mx >= x and mx <= x + w and my >= y and my <= y + h)

ColorUI(25,25,25,235, mul)
draw.FilledRect(x, y, x+w, y+h)

local col = hover and accent or UI.colors.gray
ColorUI(col[1], col[2], col[3], col[4], mul)
draw.FilledRect(x, y, x+w, y+2)
draw.FilledRect(x, y+h-2, x+w, y+h)

draw.SetFont(UI.font)
local tw, th = draw.GetTextSize(label)
ColorUI(col[1], col[2], col[3], col[4], mul)
draw.Text(math.floor(x + w/2 - tw/2), math.floor(y + h/2 - th/2), label)

return hover
end

local function DrawMenu(boxX, boxY, mx, my)
local px, py = boxX + BOX_SIZE + 8, boxY
local sw, sh = draw.GetScreenSize()
if px + MENU_W > sw then px = boxX - MENU_W - 8 end
if py + MENU_H > sh then py = sh - MENU_H end
if py < 0 then py = 0 end

local anim = (menu.anim or 0)
local dir = (px >= boxX) and 1 or -1
local slide = math.floor((1 - anim) * 12) * dir
px = px + slide
if px < 0 then px = 0 end
if px + MENU_W > sw then px = sw - MENU_W end

ColorUI(15,15,15,240, (menu.anim or 0))
draw.FilledRect(px, py, px+MENU_W, py+MENU_H)

local accent = UI.colors.gold
ColorUI(accent[1], accent[2], accent[3], 255, (menu.anim or 0))
draw.FilledRect(px, py, px+MENU_W, py+2)
draw.FilledRect(px, py+MENU_H-2, px+MENU_W, py+MENU_H)

local label = menu.waitKey and "Press..." or "Set Hotkey"
local bHotkey = DrawButton(px+10, py+10, MENU_W-20, 24, label, accent, mx, my, (menu.anim or 0))

local tLabel = (ammoCfg.transparent == 1) and "Transparent: ON" or "Transparent: OFF"

local bTrans = DrawButton(px+10, py+40, MENU_W-20, 24, tLabel, accent, mx, my, (menu.anim or 0))

return px, py, MENU_W, MENU_H, bHotkey, bTrans
end

local function onAmmoStringCmd(cmd)
local raw = cmd:Get()
if not raw or raw == "" then return end

local args = {}
for w in string.gmatch(raw:lower(), "%S+") do
table.insert(args, w)
end
if args[1] == "gp_cant_toggle" then
local v = args[2] or ""
local on = (v == "on" or v == "1" or v == "true")
local off = (v == "off" or v == "0" or v == "false")
if on or off then
ammoCfg.enabled = on and 1 or 0
state.enabled = on
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
end
cmd:Set("")
return false
end
if args[1] == "gp_cant_ui_reset" then
local sw, sh = draw.GetScreenSize()
ammoCfg.x = math.floor(sw/2 - BOX_SIZE/2)
ammoCfg.y = math.floor(sh/2 - BOX_SIZE/2)
ammoCfg.x, ammoCfg.y = ClampToScreen(ammoCfg.x, ammoCfg.y, BOX_SIZE, BOX_SIZE)
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
cmd:Set("")
return false
end
if args[1] == "gp_cant_cfg_reset" then
ammoCfg.x = 10
ammoCfg.y = 60
ammoCfg.enabled = 0
ammoCfg.toggle_key = nil
ammoCfg.transparent = 0
state.enabled = false
TOGGLE_KEY = KEY_J
IGNORE_TOGGLE_UNTIL=0
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
cmd:Set("")
return false
end

if args[1] == "gp_cant_key" then
local val = args[2]
local key = tonumber(val)
if not key and val then
key = KEY_NAME_MAP[val]
end

if key then
TOGGLE_KEY = key
IGNORE_TOGGLE_UNTIL = globals.RealTime() + 0.35
ammoCfg.toggle_key = key
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
end

cmd:Set("")
return false
end
end

callbacks.Register("SendStringCmd", "gp_cant_hotkey_trans_20260128_v1_keycmd", onAmmoStringCmd)

local function onCantTransCmd(cmd)
local s = cmd:Get()
if not s or s == "" then return end
local args = {}
for w in s:gmatch("%S+") do args[#args+1] = w end
if args[1] ~= "gp_cant_trans" then return end

if args[2] == "on" then
ammoCfg.transparent = 1
elseif args[2] == "off" then
ammoCfg.transparent = 0
else
return
end

SaveAmmoCfg(GP_CfgPath(), ammoCfg)
cmd:Set("")
return false
end

callbacks.Register("SendStringCmd", "gp_cant_trans_cmd_unique", onCantTransCmd)

callbacks.Register("Draw", "gp_cant_hotkey_trans_20260128_v1_draw", function()
local me = entities.GetLocalPlayer()

if (not me) or (me and (not me:IsAlive())) then
state.usedCanteen = false
end

if IsGameBlocked() then
return
end

if (input.IsButtonDown(TOGGLE_KEY) and globals.RealTime() > IGNORE_TOGGLE_UNTIL) and not state._jDebounce then
state._jDebounce = true

state.enabled = not state.enabled
ammoCfg.enabled = state.enabled and 1 or 0
SaveAmmoCfg(GP_CfgPath(), ammoCfg)

if not state.enabled and state.usedCanteen then
client.Command("-use_action_slot_item", true)
state.usedCanteen = false
end
elseif not input.IsButtonDown(TOGGLE_KEY) then
state._jDebounce = false
end

local x, y = ammoCfg.x, ammoCfg.y
local w, h = BOX_SIZE, BOX_SIZE

local mousePos = input.GetMousePos()
local mx, my = mousePos[1], mousePos[2]

local inBox = (mx >= x and mx <= (x + w) and my >= y and my <= (y + h))

local mr = input.IsButtonDown(MOUSE_RIGHT)
local rPressed = mr and not menu.lastR
menu.lastR = mr
if rPressed and inBox and not isDragging then
menu.want = not menu.want
menu.waitKey = false
menu.waitKeyArmed = false
menu.keyPrev = {}
end

do
local ft = (globals.FrameTime and globals.FrameTime()) or 0
local target = (menu.want and 1 or 0)
local speed = 14
local t = math.min(1, ft * speed)
menu.anim = (menu.anim or 0) + (target - (menu.anim or 0)) * t
if (menu.anim or 0) < 0.01 and (not menu.want) then
menu.anim = 0
end
menu.open = (menu.anim or 0) > 0
end

local mouseDownNow = input.IsButtonDown(MOUSE_LEFT)

if mouseDownNow and not isMouseDown and inBox then
isMouseDown = true
downX, downY = mx, my
startBoxX, startBoxY = x, y
isDragging = false
clickCandidate = true
end

if mouseDownNow and isMouseDown then
local dx = mx - downX
local dy = my - downY

if not isDragging and (math.abs(dx) > DRAG_THRESHOLD or math.abs(dy) > DRAG_THRESHOLD) then
isDragging = true
clickCandidate = false
end

if isDragging then
ammoCfg.x, ammoCfg.y = ClampToScreen(startBoxX + dx, startBoxY + dy, w, h)
x, y = ammoCfg.x, ammoCfg.y
end
end

if not mouseDownNow and isMouseDown then
isMouseDown = false

if clickCandidate and inBox and not menu.open then
state.enabled = not state.enabled
ammoCfg.enabled = state.enabled and 1 or 0
SaveAmmoCfg(GP_CfgPath(), ammoCfg)

if not state.enabled and state.usedCanteen then
client.Command("-use_action_slot_item", true)
state.usedCanteen = false
end
end

if isDragging then
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
end

clickCandidate = false
isDragging = false
end

local accent = state.enabled and UI.colors.gold or UI.colors.gray

local bg = UI.colors.background
ColorBox(bg[1], bg[2], bg[3], bg[4])
draw.FilledRect(x, y, x + w, y + h)

ColorBox(accent[1], accent[2], accent[3], accent[4])
draw.FilledRect(x, y, x + w, y + 2)
draw.FilledRect(x, y + h - 2, x + w, y + h)

draw.SetFont(UI.font)
local label = "ammo"
local tw, th = draw.GetTextSize(label)

ColorBox(accent[1], accent[2], accent[3], accent[4])
draw.Text(math.floor(x + (w / 2) - (tw / 2)), math.floor(y + (h / 2) - (th / 2)), label)

if menu.open then
local px, py, pw, ph, bHotkey, bTrans = DrawMenu(x, y, mx, my)

menu.lastMenuRect = { x = px, y = py, w = pw, h = ph }
local lDown = input.IsButtonDown(MOUSE_LEFT)
local lPressed = lDown and not menu.lastL
menu.lastL = lDown

local inPanel = (mx >= px and mx <= px+pw and my >= py and my <= py+ph)

if lPressed and bHotkey then
menu.waitKey = true
menu.waitKeyArmed = false
menu.keyPrev = {}
end

if lPressed and bTrans then
ammoCfg.transparent = (ammoCfg.transparent == 1) and 0 or 1
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
end

if (not menu.waitKey) and lPressed and (not inPanel) and (not inBox) then
menu.want = false
menu.waitKey = false
menu.waitKeyArmed = false
menu.keyPrev = {}
end

if menu.waitKey then
if not menu.waitKeyArmed then
if (not input.IsButtonDown(MOUSE_LEFT)) and (not input.IsButtonDown(MOUSE_RIGHT)) then
menu.waitKeyArmed = true
menu.keyPrev = {}
end
else
if KeyPressed(KEY_ESCAPE) then
menu.waitKey = false
menu.waitKeyArmed = false
menu.keyPrev = {}
else
for i = 1, #PICK_KEYS do
local k = PICK_KEYS[i]
if KeyPressed(k) then
TOGGLE_KEY = k
IGNORE_TOGGLE_UNTIL = globals.RealTime() + 0.35
ammoCfg.toggle_key = k
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
menu.waitKey = false
menu.waitKeyArmed = false
menu.keyPrev = {}
break
end
end
end
end

local sw, sh = draw.GetScreenSize()
ColorUI(0, 0, 0, 170)
draw.FilledRect(0, 0, sw, sh)

local ow, oh = 320, 92
local ox, oy
if menu.lastMenuRect then
ox = menu.lastMenuRect.x
oy = menu.lastMenuRect.y + menu.lastMenuRect.h + 6
else
ox, oy = math.floor(sw/2 - ow/2), math.floor(sh/2 - oh/2)
end

if ox + ow > sw then ox = sw - ow end
if ox < 0 then ox = 0 end
if oy + oh > sh then oy = sh - oh end
if oy < 0 then oy = 0 end

ColorUI(15,15,15,245)
draw.FilledRect(ox, oy, ox+ow, oy+oh)
local render_latency_bias = "gp:goldenpan:2026-01-28:7f3c9b2a"

ColorUI(255,215,0,255)
draw.FilledRect(ox, oy, ox+ow, oy+2)
draw.FilledRect(ox, oy+oh-2, ox+ow, oy+oh)

draw.SetFont(UI.font)
local t1 = "Press key to select"
local t2 = "ESC to cancel"
local w1 = select(1, draw.GetTextSize(t1))
local w2 = select(1, draw.GetTextSize(t2))

ColorUI(255,215,0,255)
draw.Text(ox + math.floor(ow/2 - w1/2), oy + 22, t1)
ColorUI(255,215,0,255)
draw.Text(ox + math.floor(ow/2 - w2/2), oy + 52, t2)
end
else
menu.lastL = input.IsButtonDown(MOUSE_LEFT)
end

if not state.enabled then
return
end

if not me then
return
end

local ammoTable = me:GetPropDataTableInt("localdata", "m_iAmmo")
local ammo = ammoTable and ammoTable[2] or nil

if ammo ~= nil and ammo <= 1 and not state.usedCanteen then
client.Command("+use_action_slot_item", true)
state.usedCanteen = true
elseif state.usedCanteen and ammo ~= 1 then
client.Command("-use_action_slot_item", true)
state.usedCanteen = false
end
end)

callbacks.Register("Unload", "gp_cant_hotkey_trans_20260128_v1_unload", function()
ammoCfg.enabled = state.enabled and 1 or 0
SaveAmmoCfg(GP_CfgPath(), ammoCfg)

if state.usedCanteen then
client.Command("-use_action_slot_item", true)
state.usedCanteen = false
end
end)

local function GP_ResetCantUI()
local sw, sh = draw.GetScreenSize()
ammoCfg.x = math.floor((sw - BOX_SIZE) / 2)
ammoCfg.y = math.floor((sh - BOX_SIZE) / 2)
SaveAmmoCfg(GP_CfgPath(), ammoCfg)
end

local function GP_CantUIResetCmd(cmd)
local raw = cmd:Get()
if not raw then return end
if raw:lower() == "gp_cant_ui_reset" then
GP_ResetCantUI()
cmd:Set("")
return false
end
end

callbacks.Register("SendStringCmd", "gp_cant_hotkey_trans_20260128_v1_uireset", GP_CantUIResetCmd)
