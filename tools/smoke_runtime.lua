local sent = {}
local sentEchoes = {}
local enabled = {}
local timers = {}
local killedTimers = {}
local eventHandlers = {}
local killedEventHandlers = {}
local eventCounter = 0
local cechoOutput = {}

if not table.contains then
  function table.contains(list, value)
    for _, item in ipairs(list or {}) do
      if item == value then
        return true
      end
    end
    return false
  end
end

if not table.deepcopy then
  function table.deepcopy(value)
    if type(value) ~= "table" then
      return value
    end
    local copy = {}
    for key, item in pairs(value) do
      copy[table.deepcopy(key)] = table.deepcopy(item)
    end
    return copy
  end
end

if not string.split then
  function string:split(separator)
    local parts = {}
    separator = separator or ""
    if separator == "" then
      for index = 1, #self do
        parts[#parts + 1] = self:sub(index, index)
      end
      return parts
    end
    local start = 1
    while true do
      local found = self:find(separator, start, true)
      if not found then
        parts[#parts + 1] = self:sub(start)
        break
      end
      parts[#parts + 1] = self:sub(start, found - 1)
      start = found + #separator
    end
    return parts
  end
end

rex = rex or {}
rex.gsub = rex.gsub or function(text, pattern, replacement)
  if pattern == "" then
    return tostring(text)
  end
  return (tostring(text):gsub(pattern, replacement))
end

function send(command, echoCommand)
  table.insert(sent, command)
  table.insert(sentEchoes, echoCommand)
end

function echo(_) end
function cecho(text)
  table.insert(cechoOutput, text)
end
function deleteLine() end

function tempTimer(delay, callback)
  local id = "timer" .. tostring(#timers + 1)
  table.insert(timers, {id = id, delay = delay, callback = callback})
  return id
end

function killTimer(id)
  killedTimers[id] = true
end

function enableTrigger(name)
  enabled[name] = true
end

function disableTrigger(name)
  enabled[name] = false
end

function registerAnonymousEventHandler(eventName, callback)
  eventCounter = eventCounter + 1
  local id = "event" .. tostring(eventCounter)
  eventHandlers[eventName] = eventHandlers[eventName] or {}
  eventHandlers[eventName][id] = callback
  return id
end

function killAnonymousEventHandler(id)
  killedEventHandlers[id] = true
  for _, handlers in pairs(eventHandlers) do
    handlers[id] = nil
  end
end

local function raiseTestEvent(eventName, payload)
  for _, callback in pairs(eventHandlers[eventName] or {}) do
    if type(callback) == "function" then
      callback(eventName, payload)
    end
  end
end

local geyserWidget = {}
function geyserWidget:setStyleSheet(style)
  self.style = style
end
function geyserWidget:echo(text)
  self.text = text
end
function geyserWidget:cecho(text)
  self.cechoText = text
  self.text = tostring(text):gsub("<[^>]->", "")
end
function geyserWidget:setClickCallback(callback)
  self.callback = callback
end
function geyserWidget:hide()
  self.hidden = true
end
function geyserWidget:show()
  self.hidden = false
  self.shown = true
end
function geyserWidget:close()
  self.closed = true
end

local function newGeyserWidget(_, spec, parent)
  local widget = spec or {}
  widget.parent = parent
  return setmetatable(widget, {__index = geyserWidget})
end

Geyser = {
  UserWindow = {new = newGeyserWidget},
  Container = {new = newGeyserWidget},
  Label = {new = newGeyserWidget}
}

function getMudletHomeDir()
  return "/tmp"
end

io.exists = function()
  return false
end

table.save = function() end
table.load = function() end

gmcp = {
  Char = {
    Vitals = {
      hp = "100",
      maxhp = "100"
    }
  }
}

local scripts = {
  "src/scripts/00_poopDeck_Init.lua",
  "src/scripts/10_poopDeck_Output.lua",
  "src/scripts/20_poopDeck_Config.lua",
  "src/scripts/30_poopDeck_Sailing.lua",
  "src/scripts/40_poopDeck_Combat.lua",
  "src/scripts/50_poopDeck_Fishing.lua",
  "src/scripts/55_poopDeck_Stats.lua",
  "src/scripts/60_poopDeck_Help.lua",
  "src/scripts/70_poopDeck_GUI.lua"
}

for _, path in ipairs(scripts) do
  assert(loadfile(path))()
end

package.preload["poopDeck.ftext"] = assert(loadfile("src/resources/ftext.lua"))

local function reset()
  sent = {}
  sentEchoes = {}
  cechoOutput = {}
end

local function resetTimers()
  timers = {}
  killedTimers = {}
end

local function runTimers()
  local pending = timers
  timers = {}
  for _, timer in ipairs(pending) do
    if not killedTimers[timer.id] and type(timer.callback) == "function" then
      timer.callback()
    end
  end
end

local function assertSent(expected)
  assert(#sent == #expected, "expected " .. #expected .. " commands, got " .. #sent)
  for index, command in ipairs(expected) do
    assert(sent[index] == command, "command " .. index .. " expected '" .. command .. "', got '" .. tostring(sent[index]) .. "'")
  end
end

local function assertEqual(actual, expected, label)
  assert(actual == expected, label .. " expected '" .. tostring(expected) .. "', got '" .. tostring(actual) .. "'")
end

local function eventCount(text)
  local count = 0
  for _, event in ipairs(poopDeck.state.events or {}) do
    if event.text == text then
      count = count + 1
    end
  end
  return count
end

local function killedTimerCount()
  local count = 0
  for _ in pairs(killedTimers) do
    count = count + 1
  end
  return count
end

reset()
poopDeck.sailing.turn("n")
assertSent({"say Bring her to the north!"})
assertEqual(sentEchoes[1], false, "poopDeck commands should be sent without command echo")

reset()
poopDeck.sailing.setSpeed("full")
assertSent({"say full sails!"})

reset()
poopDeck.sailing.setSpeed("5")
assertSent({"ship sails set 5"})

reset()
poopDeck.sailing.setSpeed("100")
assertSent({"ship sails set 100"})

reset()
poopDeck.sailing.clearRigging()
assertSent({"queue add freestand climb rigging", "queue add freestand clear rigging"})
poopDeck.sailing.onRiggingTangled("A monstrous ketea sprays a thick rain of venom from its barb, the foul fluid dissolving the rigging into a snarl of shreds and knots, creating a useless tangle of the ropes and sails.")
assertEqual(poopDeck.state.ship.riggings, "Tangled", "rigging tangle line should mark rigging tangled")
reset()
poopDeck.sailing.onRiggingCleared()
assertEqual(poopDeck.state.ship.riggings, "Clear", "rigging clear line should mark rigging clear")
assertSent({"queue add freestand climb rigging down"})

poopDeck.sailing.parsePrompt("= S++@h96,H80,W<-NE@8kts,C/S->E@16,II,[Rw+Sl]")
assertEqual(poopDeck.state.ship.promptMode, "cryptic", "cryptic prompt mode")
assertEqual(poopDeck.state.ship.sailSetting, "Full", "cryptic sail setting")
assertEqual(poopDeck.state.ship.sailHealth, 96, "cryptic sail health")
assertEqual(poopDeck.state.ship.hullHealth, 80, "cryptic hull health")
assertEqual(poopDeck.state.ship.windDirection, "NE", "cryptic wind direction")
assertEqual(poopDeck.state.ship.windSpeed, 8, "cryptic wind speed")
assertEqual(poopDeck.state.ship.currentHeading, "E", "cryptic heading")
assertEqual(poopDeck.state.ship.actualSpeed, 16, "cryptic speed")
assertEqual(poopDeck.state.ship.seaCode, "II", "cryptic sea code")
assertEqual(poopDeck.state.ship.seaCondition, "Smooth", "cryptic sea condition")
assertEqual(poopDeck.state.ship.seaBand, "good", "cryptic sea band")
assertEqual(poopDeck.state.ship.isRowing, true, "cryptic rowing")
assertEqual(poopDeck.state.ship.hasSailBoost, true, "cryptic sailing flag")

poopDeck.sailing.parsePrompt("= S50@h97,H78,W<-NE@8kts,C/S->NE@14,V,[Rw+Sl],T->N")
assertEqual(poopDeck.state.ship.sailSetting, "50", "cryptic numeric sail setting")
assertEqual(poopDeck.state.ship.seaCondition, "Whitecapped", "cryptic reduced sea name")
assertEqual(poopDeck.state.ship.seaBand, "reduced", "cryptic reduced sea band")
assertEqual(poopDeck.state.ship.turningTo, "N", "cryptic turn target")

poopDeck.sailing.parsePrompt("= S50@h97,H78,W<-NE@8kts,C/S->NE@14,IX,[Rw+Sl]")
assertEqual(poopDeck.state.ship.seaCondition, "Raging", "cryptic bad sea name")
assertEqual(poopDeck.state.ship.seaBand, "bad", "cryptic bad sea band")

poopDeck.sailing.parsePrompt("= Sl Full - hp 93%,Hl: 77%,Wd NE@8kts,Cr/Sp E@14,Sea Whitecapped,Row+Sail")
assertEqual(poopDeck.state.ship.promptMode, "battle", "battle prompt mode")
assertEqual(poopDeck.state.ship.sailHealth, 93, "battle sail health")
assertEqual(poopDeck.state.ship.hullHealth, 77, "battle hull health")
assertEqual(poopDeck.state.ship.seaCondition, "Whitecapped", "battle sea condition")

poopDeck.sailing.parsePrompt("= [Sail Full] [Hull] [Wind: NE@8 kts] [Crs/Spd: W@19] [Seas: Smooth] [Rowing+Sailing]")
assertEqual(poopDeck.state.ship.promptMode, "normal", "normal prompt mode")
assertEqual(poopDeck.state.ship.sailSetting, "Full", "normal sail setting")
assertEqual(poopDeck.state.ship.hullHealth, 100, "normal hull health")
assertEqual(poopDeck.state.ship.currentHeading, "W", "normal heading")
assertEqual(poopDeck.state.ship.actualSpeed, 19, "normal speed")

poopDeck.sailing.parseShipInfoLine("Ship Info for: The Obsidian Trident")
poopDeck.sailing.parseShipInfoLine("Ship ID#:      922")
poopDeck.sailing.parseShipInfoLine("Ship alias:    tot")
poopDeck.sailing.parseShipInfoLine("Sails health:  10000/10000: 100%.")
poopDeck.sailing.parseShipInfoLine("Hull health:   5000/5000: 100%.")
poopDeck.sailing.parseShipInfoLine("Course:        north")
poopDeck.sailing.parseShipInfoLine("Sailing?       No.")
poopDeck.sailing.parseShipInfoLine("Rowing?        No.")
poopDeck.sailing.parseShipInfoLine("Fires:         No.")
poopDeck.sailing.parseShipInfoLine("Crewmates:     60")
poopDeck.sailing.parseShipInfoLine("Wind from the: northeast at the rate of 8 knots.")
assertEqual(poopDeck.state.ship.name, "The Obsidian Trident", "ship info name")
assertEqual(poopDeck.state.ship.id, 922, "ship info id")
assertEqual(poopDeck.state.ship.alias, "tot", "ship info alias")
assertEqual(poopDeck.state.ship.sailHealth, 100, "ship info sail health")
assertEqual(poopDeck.state.ship.hullHealth, 100, "ship info hull health")
assertEqual(poopDeck.state.ship.currentHeading, "N", "ship info course")
assertEqual(poopDeck.state.ship.isRowing, false, "ship info rowing")
assertEqual(poopDeck.state.ship.hasSailBoost, false, "ship info sailing")
assertEqual(poopDeck.state.ship.hasFires, false, "ship info fires")
assertEqual(poopDeck.state.ship.crewmates, 60, "ship info crew")
assertEqual(poopDeck.state.ship.windDirection, "NE", "ship info wind direction")
assertEqual(poopDeck.state.ship.windSpeed, 8, "ship info wind speed")
assertEqual(poopDeck.state.ship.isAboard, true, "ship info should mark aboard")
poopDeck.sailing.onShipFire("Burning acid rains down upon the ship, setting fire to all that it touches.")
assertEqual(poopDeck.state.ship.hasFires, true, "fire line should mark ship fires")
poopDeck.sailing.parseFireLine("A cool rain suffuses the surroundings.")
assertEqual(poopDeck.state.ship.hasFires, false, "cool rain line should clear ship fires")
poopDeck.sailing.onShipFire("Burning acid rains down upon the ship, setting fire to all that it touches.")
assertEqual(poopDeck.state.ship.hasFires, true, "legacy fire handler should still mark ship fires")
poopDeck.sailing.parseShipInfoLine("Fires:         No.")
assertEqual(poopDeck.state.ship.hasFires, false, "ship info should clear fire state")

poopDeck.state.ship.repairingHull = nil
poopDeck.state.ship.repairingSails = nil
reset()
poopDeck.sailing.repairAll()
assertSent({"ship repair all"})
assertEqual(poopDeck.state.ship.repairingHull, nil, "repair alias should not mark hull active before confirmation")
assertEqual(poopDeck.state.ship.repairingSails, nil, "repair alias should not mark sails active before confirmation")
poopDeck.sailing.parseRepairLine("You order your crew to begin repairing the ship's hull.")
assertEqual(poopDeck.state.ship.repairingHull, nil, "hull repair order should not mark repair active")
assertEqual(poopDeck.state.ship.repairPending, "hull", "hull repair order should track pending intent")
poopDeck.sailing.parseRepairLine("Your crew starts repairing the ship's hull.")
assertEqual(poopDeck.state.ship.repairingHull, true, "hull repair start should be active")
assertEqual(poopDeck.state.ship.repairingSails, nil, "sail repair should not be active yet")
poopDeck.sailing.parseRepairLine("Hull repair continues. The hull is now at 90% health.")
assertEqual(poopDeck.state.ship.hullHealth, 90, "repair line should update hull health")
poopDeck.sailing.parseRepairLine("You order your crew to begin repairing the ship's sails.")
assertEqual(poopDeck.state.ship.repairingSails, nil, "sail repair order should not mark repair active")
assertEqual(poopDeck.state.ship.repairPending, "sails", "sail repair order should track pending intent")
poopDeck.sailing.parseRepairLine("Your crew starts repairing the ship's sails.")
assertEqual(poopDeck.state.ship.repairingSails, true, "sail repair start should be active")
poopDeck.sailing.parseRepairLine("Your crew ceases all repair activity.")
assertEqual(poopDeck.state.ship.repairingHull, false, "repair none should stop hull repair")
assertEqual(poopDeck.state.ship.repairingSails, false, "repair none should stop sail repair")
poopDeck.sailing.parseRepairLine("Your crew begins to mend your sails and repair your hull.")
assertEqual(poopDeck.state.ship.repairingHull, true, "repair all should start hull repair")
assertEqual(poopDeck.state.ship.repairingSails, true, "repair all should start sail repair")
poopDeck.sailing.parseRepairLine("Sail repair continues. The sails are now at 6% health.")
assertEqual(poopDeck.state.ship.sailHealth, 6, "repair line should update sail health")
poopDeck.sailing.parseRepairLine("The sails are now fully repaired!")
assertEqual(poopDeck.state.ship.sailHealth, 100, "fully repaired sails should set health to 100")
assertEqual(poopDeck.state.ship.repairingSails, false, "fully repaired sails should stop sail repair")

poopDeck.sailing.parsePrompt("= S50@h97,H78,W<-NE@8kts,C/S->NE@14,IX,[Rw+Sl]")
poopDeck.gui.build()
assert(poopDeck.gui.window ~= nil, "gui should create a user window")
assertEqual(poopDeck.gui.currentTheme.label, "Runewarden", "gui should fall back to runewarden theme when adb is unavailable")
assert(poopDeck.gui.root.style:match("#172033") ~= nil, "gui root should use themed panel background")
assert(poopDeck.gui.root.style:match("#cd853f") ~= nil, "gui root should use themed outer border")
assert(poopDeck.gui.window.style:match("#cd853f") ~= nil, "gui window should use themed outer border when supported")
assertEqual(poopDeck.gui.window.titleText, "poopDeck " .. tostring(poopDeck.version), "gui window title should include version")
assertEqual(poopDeck.gui.window.x, "80px", "gui should default to primary-monitor x position")
assertEqual(poopDeck.gui.window.y, "80px", "gui should default to primary-monitor y position")
assertEqual(poopDeck.gui.window.width, "720px", "gui should default to wider window width")
assertEqual(poopDeck.gui.window.height, "360px", "gui should default to compact window height")
assertEqual(poopDeck.gui.window.restoreLayout, true, "gui should ask Mudlet to restore saved userwindow layout")
assertEqual(poopDeck.gui.window.dockPosition, "floating", "gui userwindow should start floating")
assertEqual(poopDeck.gui.window.autoDock, false, "gui userwindow should not auto-dock by default")
assert(poopDeck.gui.labels.backdrop ~= nil, "gui should create a full-window themed backdrop")
assert(poopDeck.gui.labels.backdrop.style:match("#172033") ~= nil, "gui backdrop should fill empty restored-window space")
assert(poopDeck.gui.labels.backdrop.style:match("border:%s*0") ~= nil, "gui backdrop should not double the outer frame border")
assert(poopDeck.gui.labels.header ~= nil, "gui should create header label")
assert(poopDeck.gui.labels.header.text:match("poopDeck:") == nil, "gui header should not duplicate window title/version")
assert(poopDeck.gui.labels.shipLine1.style:match("border%-bottom") == nil, "gui data rows should not draw dark divider lines")
assert(poopDeck.gui.labels.shipLine1 ~= nil, "gui should create ship line")
assert(poopDeck.gui.labels.shipSea ~= nil, "gui should create sea label")
assert(poopDeck.gui.labels.fishingLine2 ~= nil, "gui should create caught fish line")
assert(poopDeck.gui.labels.eventsTitle == nil, "gui should not create squished recent event section")
assert(poopDeck.gui.labels.shipTitle.text:match("└") == nil, "ship section should not draw text-frame glyphs inside styled borders")
assert(poopDeck.gui.labels.combatTitle.text == "Seamonsters", "seamonster section should use clean section bar text")
assert(poopDeck.gui.labels.fishingTitle.text == "Fishing", "fishing section should use clean section bar text")
assert(poopDeck.gui.labels.header.text:match("Sails ") ~= nil, "gui header should show sail danger summary")
assert(poopDeck.gui.labels.header.text:match("Hull ") ~= nil, "gui header should show hull danger summary")
assert(poopDeck.gui.labels.header.text:match("Range ") ~= nil, "gui header should show range state")
assert(poopDeck.gui.labels.shipLine1.text:match("Course:") ~= nil, "ship course should use label colon")
assert(poopDeck.gui.labels.shipLine1.text:match("Row:") ~= nil, "row should be on course line")
assert(poopDeck.gui.labels.shipLine1.text:match("Sail:") ~= nil, "sail should be on course line")
assert(poopDeck.gui.labels.shipSea.text == "Sea: Raging", "gui should show full sea name")
assert(poopDeck.gui.labels.shipSea.style:match("#ef4444") ~= nil, "gui should color bad seas red")
assert(poopDeck.gui.labels.shipLine2.text:match("Repair: Hull") ~= nil, "gui should show repair status instead of crew")
assert(poopDeck.gui.labels.shipLine2.text:match("Crew") == nil, "gui should not show crew on hull line")
assert(poopDeck.gui.labels.shipLine3.text:match("^Anchor:") ~= nil, "anchor should begin third ship line")
assert(poopDeck.gui.labels.shipLine3.text:match("Fires: No") ~= nil, "fires should be on rigging line")
assert(poopDeck.gui.labels.shipLine3.text:match("Rigging:") ~= nil, "rigging should be on third ship line")
assert(poopDeck.gui.labels.shipLine3.text:match("Row:") == nil, "row should not be on third ship line")
assert(poopDeck.gui.labels.shipLine3.text:match("Sail:") == nil, "sail should not be on third ship line")
assert(poopDeck.gui.labels.stopButton == nil, "gui should not create a stop button")
assert(poopDeck.gui.labels.firingButton ~= nil, "gui should create a firing status button")
assert(poopDeck.gui.labels.combatLine2.text:match("Firing:") == nil, "gui should not duplicate firing status in mini text")
assert(poopDeck.gui.labels.combatLine2.text:match("Range:") ~= nil, "gui should keep compact range text")
assert(poopDeck.gui.labels.firingButton.style:match("#22304a") ~= nil, "firing status should be unlit while idle")
poopDeck.state.combat.mode = "manual"
poopDeck.gui.update()
assert(type(_G[poopDeck.gui.labels.autoButton.callback]) == "function", "gui auto button should register a global click wrapper")
_G[poopDeck.gui.labels.autoButton.callback]()
assertEqual(poopDeck.state.combat.mode, "automatic", "gui auto button click should toggle auto mode")
assert(poopDeck.gui.labels.autoButton.style:match("#1d4ed8") ~= nil, "gui auto button should highlight after click")
_G[poopDeck.gui.labels.onagerButton.callback]()
assertEqual(poopDeck.state.combat.selectedWeapon, "onager", "gui weapon button click should set selected weapon")
assert(poopDeck.gui.labels.onagerButton.style:match("#1d4ed8") ~= nil, "gui selected weapon should highlight after click")
assert(poopDeck.gui.labels.ballistaButton.style:match("#22304a") ~= nil, "gui unselected weapon should unhighlight after click")
assert(poopDeck.gui.labels.combatLine2.text:match("Strategy:") ~= nil, "gui should show selected onager strategy")
poopDeck.state.combat.firing = true
poopDeck.state.combat.outOfRange = false
poopDeck.gui.update()
assert(poopDeck.gui.labels.firingButton.style:match("#1d4ed8") ~= nil, "firing status should use active color while firing")
assertEqual(poopDeck.gui.labels.firingButton.text, "Firing", "firing status should label active firing")
poopDeck.state.combat.firing = false
poopDeck.state.combat.outOfRange = true
poopDeck.gui.update()
assert(poopDeck.gui.labels.firingButton.style:match("#7f1d1d") ~= nil, "firing status should use dark red while out of range")
assertEqual(poopDeck.gui.labels.firingButton.text, "Range", "firing status should label range problem")
poopDeck.state.combat.outOfRange = false
poopDeck.gui.update()
assert(poopDeck.gui.visible == true, "gui should show when already aboard")
poopDeck.gui.setPosition("120", "140")
assertEqual(poopDeck.gui.window.x, "120px", "gui position command should update x")
assertEqual(poopDeck.gui.window.y, "140px", "gui position command should update y")
assertEqual(poopDeck.gui.window.restoreLayout, false, "explicit gui position should disable layout restore")
poopDeck.gui.setSize("800", "460")
assertEqual(poopDeck.gui.window.width, "800px", "gui size command should update width")
assertEqual(poopDeck.gui.window.height, "460px", "gui size command should update height")
assertEqual(poopDeck.gui.window.restoreLayout, false, "explicit gui size should disable layout restore")
poopDeck.gui.setRestoreLayout(true)
assertEqual(poopDeck.gui.window.restoreLayout, true, "gui restore command should re-enable layout restore")
poopDeck.gui.resetSettings()
assertEqual(poopDeck.gui.window.x, "80px", "gui reset should restore default x")
assertEqual(poopDeck.gui.window.y, "80px", "gui reset should restore default y")
assertEqual(poopDeck.gui.window.height, "360px", "gui reset should restore compact default height")
assertEqual(poopDeck.gui.window.restoreLayout, true, "gui reset should restore layout restore")
poopDeck.gui.command("compact")
assertEqual(poopDeck.config.get("guiMode"), "compact", "poopgui compact should persist compact mode")
assertEqual(poopDeck.gui.window.width, "520px", "compact gui should use compact default width")
assertEqual(poopDeck.gui.window.height, "100px", "compact gui should use compact default height")
assertEqual(poopDeck.gui.window.restoreLayout, false, "compact gui should bypass saved full window layout")
poopDeck.gui.setSize("540", "110")
assertEqual(poopDeck.config.get("guiCompactWidth"), "540px", "size command in compact mode should update compact width")
assertEqual(poopDeck.config.get("guiCompactHeight"), "110px", "size command in compact mode should update compact height")
assertEqual(poopDeck.gui.window.width, "540px", "compact gui should rebuild with configured compact width")
assertEqual(poopDeck.gui.window.height, "110px", "compact gui should rebuild with configured compact height")
assert(poopDeck.gui.labels.autoButton ~= nil, "compact gui should keep auto status button")
assert(poopDeck.gui.labels.firingButton ~= nil, "compact gui should keep firing status button")
assert(poopDeck.gui.labels.ballistaButton ~= nil, "compact gui should keep weapon status buttons")
assert(poopDeck.gui.labels.fishReelButton ~= nil, "compact gui should keep fishing status buttons")
assert(poopDeck.gui.labels.shipLine1 == nil, "compact gui should omit full ship detail rows")
assert(poopDeck.gui.labels.header.text:match("Combat ") ~= nil, "compact gui header should keep danger summary")
poopDeck.gui.command("full")
assertEqual(poopDeck.config.get("guiMode"), "full", "poopgui full should persist full mode")
assertEqual(poopDeck.gui.window.width, "720px", "full gui should restore full default width")
assertEqual(poopDeck.gui.window.height, "360px", "full gui should restore full default height")
assert(poopDeck.gui.labels.shipLine1 ~= nil, "full gui should restore ship detail rows")
agnosticdb = {
  ui = {
    theme_tags = function()
      return {
        accent = "<red>",
        border = "<peru>",
        text = "<alice_blue>",
        muted = "<light_slate_gray>",
        reset = "<reset>"
      }
    end
  }
}
poopDeck.gui.setTheme("adb")
assertEqual(poopDeck.config.get("guiTheme"), "agnosticdb", "gui theme adb alias should store agnosticdb")
assertEqual(poopDeck.gui.currentTheme.name, "agnosticdb", "gui should use adb theme source when available")
assertEqual(poopDeck.gui.currentTheme.accent, "#ff0000", "gui should translate adb accent color to css")
assert(poopDeck.gui.currentTheme.panel ~= "#172033", "adb theme should derive a panel color instead of keeping built-in slate")
assertEqual(poopDeck.gui.currentTheme.background, "#1f0000", "adb background should derive primarily from accent")
assertEqual(poopDeck.gui.currentTheme.panel, "#4b0b05", "adb panel should derive primarily from accent")
assertEqual(poopDeck.gui.currentTheme.section, "#6e1008", "adb section should derive primarily from accent")
assert(poopDeck.gui.root.style:match(poopDeck.gui.currentTheme.panel) ~= nil, "gui root should use adb-derived panel background")
assert(poopDeck.gui.labels.backdrop.style:match(poopDeck.gui.currentTheme.panel) ~= nil, "gui backdrop should use adb-derived panel background")
assert(poopDeck.gui.labels.header.style:match("#cd853f") ~= nil, "gui section style should use adb border color")
assert(poopDeck.gui.labels.header.cechoText:match("<red>") ~= nil, "gui labels should use adb color tags for text")
assert(poopDeck.gui.labels.autoButton.style:match("#cd853f") ~= nil, "gui buttons should keep adb-colored border framing")
agnosticdb.ui.emit_line = function()
  error("single-line output should not delegate to multi-write emit_line")
end
reset()
poopDeck.output.good("Hooked very large fish")
assertEqual(#cechoOutput, 1, "single-line adb output should be emitted atomically")
assert(cechoOutput[1]:match("Hooked very large fish") ~= nil, "single-line adb output should include message")
assert(cechoOutput[1]:match("╔") ~= nil and cechoOutput[1]:match("╚") ~= nil, "single-line adb output should include complete frame")
reset()
poopDeck.gui.command("output compact")
assertEqual(poopDeck.config.get("outputMode"), "compact", "poopgui output compact should persist compact output mode")
reset()
poopDeck.output.good("Compact event")
assert(cechoOutput[1]:match("    >>> %[poopDeck%] Compact event <<<") ~= nil, "compact output should be an indented distinct marked line")
assert(cechoOutput[1]:match("╔") == nil and cechoOutput[1]:match("╚") == nil, "compact output should not use a full frame")
poopDeck.gui.command("output framed")
assertEqual(poopDeck.config.get("outputMode"), "framed", "poopgui output framed should restore framed output mode")
reset()
poopDeck.output.status("Table Test", {
  "Fish       Today  Biggest",
  "Test Tuna      1  123lb 5oz"
})
local framedOutput = table.concat(cechoOutput)
assert(framedOutput:match("║") ~= nil, "status output should use bordered frame when adb theme tags exist")
assert(framedOutput:match("Test Tuna%s+1%s+123lb 5oz") ~= nil, "status output should preserve padded table columns")
reset()
poopDeck.output.rawLines({"|Fish      | Today|", "|Test Tuna |    1|"})
local rawOutput = table.concat(cechoOutput)
assert(rawOutput:match("║") == nil, "raw table output should not add an outer status frame")
assert(rawOutput:match("|Fish%s+| Today|") ~= nil, "raw table output should preserve table border spacing")
poopDeck.gui.setTheme("runewarden")
assertEqual(poopDeck.config.get("guiTheme"), "runewarden", "explicit runewarden theme should store before adb event")
local preThemeWindow = poopDeck.gui.window
local preEventPanel = poopDeck.gui.currentTheme.panel
poopDeck.gui.registerThemeHandlers()
raiseTestEvent("agnosticdb.theme.changed", {
  event = "agnosticdb.theme.changed",
  reason = "set",
  name = "mhaldor",
  label = "Mhaldor",
  auto_city = false,
  tags = {
    accent = "<red>",
    border = "<dark_slate_grey>",
    text = "<misty_rose>",
    muted = "<rosy_brown>",
    reset = "<reset>"
  }
})
assertEqual(poopDeck.config.get("guiTheme"), "agnosticdb", "adb theme event should switch gui back to adb theme source")
assertEqual(poopDeck.gui.currentTheme.label, "Mhaldor", "gui should adopt adb theme event label")
assert(poopDeck.gui.window ~= preThemeWindow, "adb theme event should redraw the gui window")
assert(poopDeck.gui.currentTheme.panel ~= preEventPanel, "adb theme event should update derived gui surface colors")
assert(poopDeck.gui.root.style:match(poopDeck.gui.currentTheme.panel) ~= nil, "adb theme event should repaint the root panel background")
assert(poopDeck.gui.labels.header.style:match("#2f4f4f") ~= nil, "adb theme event should update border color from payload")
assert(poopDeck.gui.labels.header.cechoText:match("<red>") ~= nil, "adb theme event should update label color tags")
agnosticdb.ui.theme_tags = function()
  return {
    accent = "<forest_green>",
    border = "<saddle_brown>",
    text = "<honeydew>",
    muted = "<tan>",
    reset = "<reset>"
  }
end
poopDeck.gui.setTheme("adb")
assertEqual(poopDeck.gui.currentTheme.label, "agnosticDB", "live adb tags should clear stale event labels")
assertEqual(poopDeck.gui.currentTheme.accent, "#228b22", "live adb tags should override stale cached event payload")
assert(poopDeck.gui.labels.header.style:match("#8b4513") ~= nil, "live adb tags should repaint borders after stale payload")
poopDeck.gui.unregisterThemeHandlers()
agnosticdb = nil
poopDeck.gui.setTheme("runewarden")
assertEqual(poopDeck.gui.currentTheme.label, "Runewarden", "gui should support explicit runewarden theme")
poopDeck.sailing.onDisembarked()
assertEqual(poopDeck.state.ship.isAboard, false, "disembark should mark off ship")
assert(poopDeck.gui.visible == false, "disembark should hide gui")
poopDeck.gui.command("off")
assertEqual(poopDeck.config.get("guiEnabled"), false, "poopgui off should persist disabled state")
poopDeck.sailing.onBoarded()
assertEqual(poopDeck.state.ship.isAboard, true, "board should mark aboard")
assert(poopDeck.gui.visible == false, "board should not show gui while disabled")
assert(poopDeck.gui.window == nil, "disabled gui should not keep a user window")
poopDeck.sailing.parsePrompt("= S50@h97,H78,W<-NE@8kts,C/S->NE@14,V,[Rw+Sl]")
assert(poopDeck.gui.visible == false, "ship prompt should not show gui while disabled")
poopDeck.gui.command("on")
assertEqual(poopDeck.config.get("guiEnabled"), true, "poopgui on should persist enabled state")
assert(poopDeck.gui.visible == true, "enabled gui should show while aboard")
poopDeck.gui.teardown()
assert(poopDeck.gui.window == nil, "gui teardown should clear window")

reset()
poopDeck.config.set("baitCommand", "get bass from tank")
poopDeck.config.set("castDistance", "medium")
poopDeck.fishing.castAgain()
assertSent({
  "queue addclearfull free get bass from tank",
  "queue add free bait hook with bass",
  "queue add free cast line medium"
})
assertEqual(poopDeck.state.fishing.status, "Casting", "bait command should set casting state")
poopDeck.fishing.parseCastSuccess("You cock back your arm and smoothly cast your line over the railing into the nearby water. You judge the cast at about 71 feet.")
assertEqual(poopDeck.state.fishing.status, "Waiting", "cast success should set waiting state")
assertEqual(poopDeck.state.fishing.hooked, false, "cast success should clear hooked state")
assertEqual(poopDeck.state.fishing.lineFeetLeft, 71, "cast success should set initial line distance")

reset()
poopDeck.config.setBaitCommand("get shrimp from bucket")
poopDeck.config.setCastDistance("long")
poopDeck.fishing.castAgain()
assertSent({
  "queue addclearfull free get shrimp from bucket",
  "queue add free bait hook with shrimp",
  "queue add free cast line long"
})
poopDeck.config.setBaitCommand("default")
poopDeck.config.setCastDistance("default")
assertEqual(poopDeck.config.get("baitCommand"), "get bass from tank", "bait command default should restore bass from tank")
assertEqual(poopDeck.config.get("castDistance"), "medium", "cast distance default should restore medium")
reset()
poopDeck.fishing.command("bait")
assertSent({
  "queue addclearfull free get bass from tank",
  "queue add free bait hook with bass",
  "queue add free cast line medium"
})
poopDeck.fishing.command("baitcmd get rock bass from tank")
assertEqual(poopDeck.config.get("baitCommand"), "get rock bass from tank", "poopfish should set bait command")
poopDeck.fishing.command("castdistance short")
assertEqual(poopDeck.config.get("castDistance"), "short", "poopfish should set cast distance")
reset()
poopDeck.fishing.command("bait")
assertSent({
  "queue addclearfull free get rock bass from tank",
  "queue add free bait hook with rock bass",
  "queue add free cast line short"
})
poopDeck.fishing.onBaited()
assertSent({
  "queue addclearfull free get rock bass from tank",
  "queue add free bait hook with rock bass",
  "queue add free cast line short"
})

reset()
poopDeck.fishing.castMedium()
assertSent({"queue addclearfull free cast line short"})
assertEqual(poopDeck.state.fishing.status, "Casting", "medium cast should set casting state")
poopDeck.config.setBaitCommand("default")
poopDeck.config.setCastDistance("default")

reset()
resetTimers()
poopDeck.fishing.teaseSoon()
assertEqual(poopDeck.state.fishing.status, "Teasing", "tease trigger should set teasing state")
assert(#timers == 2, "tease should schedule command and idle timers")
assertEqual(timers[1].delay, 2, "tease command should wait before sending")
assertEqual(timers[2].delay, 4.1, "tease idle reset should wait for balance recovery")
runTimers()
assertSent({"tease line"})
assertEqual(poopDeck.state.fishing.status, "Idle", "tease idle timer should return to idle")

reset()
resetTimers()
poopDeck.fishing.teaseSoon()
poopDeck.fishing.showSize("an enormous")
runTimers()
assertSent({"tease line"})
assertEqual(poopDeck.state.fishing.status, "Hooked", "tease idle timer should not overwrite hook state")

reset()
resetTimers()
poopDeck.fishing.teaseNow()
assertSent({"tease line"})
assertEqual(poopDeck.state.fishing.status, "Teasing", "manual tease should set teasing state")
assert(#timers == 1, "manual tease should schedule idle reset")
assertEqual(timers[1].delay, 2.1, "manual tease idle reset should account for immediate send")
runTimers()
assertEqual(poopDeck.state.fishing.status, "Idle", "manual tease idle timer should return to idle")

reset()
resetTimers()
poopDeck.fishing.jerk()
assertSent({"jerk pole"})
assert(#timers == 2, "large strike should schedule two follow-up jerk timers")
assertEqual(timers[1].delay, 1.9, "first large-strike retry should wait for fishing balance")
assertEqual(timers[2].delay, 3.8, "second large-strike retry should wait for fishing balance")
reset()
poopDeck.fishing.showSize("an gigantic")
assertEqual(poopDeck.state.fishing.status, "Hooked", "fish size should set hooked state")
assertEqual(poopDeck.state.fishing.size, "gigantic", "fish size should be stored")
poopDeck.fishing.showSize("a colossal")
assertEqual(poopDeck.state.fishing.size, "colossal", "fish size should strip leading article")
poopDeck.fishing.onLineDistance("367")
assertEqual(poopDeck.state.fishing.lineFeetLeft, 367, "line distance should be stored")
poopDeck.fishing.reel()
assertSent({"queue addclearfull free reel line"})
assertEqual(poopDeck.state.fishing.status, "Reeling", "reel should set reeling state")
runTimers()
assertSent({"queue addclearfull free reel line"})
poopDeck.fishing.onLanded()
assertEqual(poopDeck.state.fishing.status, "Landed", "landed should set landed state")
assertEqual(poopDeck.state.fishing.hooked, false, "landed should clear hooked")
assertEqual(poopDeck.state.fishing.size, nil, "landed should clear size")
assertEqual(poopDeck.state.fishing.lineFeetLeft, nil, "landed should clear line distance")
poopDeck.fishing.parseCaughtLine("With a final tug, you finish reeling in the line and land a redfin tuna weighing 233 pounds and 7 ounces!")
assertEqual(poopDeck.state.fishing.caughtFishType, "redfin tuna", "caught fish type should be stored without article")
assertEqual(poopDeck.state.fishing.caughtPounds, 233, "caught fish pounds should be stored")
assertEqual(poopDeck.state.fishing.caughtOunces, 7, "caught fish ounces should be stored")

reset()
poopDeck.fishing.showSize("a large")
poopDeck.fishing.onLineDistance("150")
poopDeck.config.setBaitCommand("get squid from tank")
poopDeck.config.setCastDistance("far")
poopDeck.fishing.onLost()
assertSent({
  "queue addclearfull free get squid from tank",
  "queue add free bait hook with squid",
  "queue add free cast line far"
})
assertEqual(poopDeck.state.fishing.status, "Casting", "lost fish should restart casting")
assertEqual(poopDeck.state.fishing.hooked, false, "lost fish should clear hooked")
assertEqual(poopDeck.state.fishing.size, nil, "lost fish should clear size")
assertEqual(poopDeck.state.fishing.lineFeetLeft, nil, "lost fish should clear line distance")
poopDeck.config.setBaitCommand("default")
poopDeck.config.setCastDistance("default")

poopDeck.gui.build()
poopDeck.fishing.showSize("an enormous")
poopDeck.fishing.onLineDistance("367")
poopDeck.gui.fishingReel()
assert(poopDeck.gui.labels.fishingLine1.text:match("Status: Reeling") ~= nil, "gui should title-case fishing state")
assert(poopDeck.gui.labels.fishingLine1.text:match("Hooked: Yes") ~= nil, "gui should title-case hooked value")
assert(poopDeck.gui.labels.fishingLine1.text:match("Size: Enormous") ~= nil, "gui should title-case size value")
assert(poopDeck.gui.labels.fishingLine1.text:match("Line: 367 ft") ~= nil, "gui should show line distance")
assert(poopDeck.gui.labels.fishingLine1.text:match("timers") == nil, "gui should not show timers")
assertEqual(poopDeck.gui.labels.fishCastButton.text, "Bait", "gui should label fcast by its fishing role")
assertEqual(poopDeck.gui.labels.fishMediumButton.text, "Cast", "gui should use concise cast button text")
assertEqual(poopDeck.gui.labels.fishIdleButton.text, "Idle", "gui should include an idle fishing button")
assertEqual(poopDeck.gui.labels.fishReelButton.text, "Reel", "gui should use concise reel button text")
assert(poopDeck.gui.labels.fishReelButton.style:match("#1d4ed8") ~= nil, "gui should highlight reel while hooked")
assert(poopDeck.gui.labels.fishTeaseButton.style:match("#22304a") ~= nil, "gui should not highlight tease while hooked")
local preIdleStatus = poopDeck.state.fishing.status
local preIdleHooked = poopDeck.state.fishing.hooked
local preIdleLine = poopDeck.state.fishing.lineFeetLeft
reset()
_G[poopDeck.gui.labels.fishIdleButton.callback]()
assertSent({})
assertEqual(poopDeck.state.fishing.status, preIdleStatus, "gui idle indicator click should not change fishing status")
assertEqual(poopDeck.state.fishing.hooked, preIdleHooked, "gui idle indicator click should not change hooked state")
assertEqual(poopDeck.state.fishing.lineFeetLeft, preIdleLine, "gui idle indicator click should not change line distance")
assert(poopDeck.gui.labels.fishReelButton.style:match("#1d4ed8") ~= nil, "gui idle indicator click should not clear reel highlight")
poopDeck.fishing.idle()
poopDeck.updateGuiNow()
assert(poopDeck.gui.labels.fishIdleButton.style:match("#1d4ed8") ~= nil, "gui should highlight idle when fishing state is idle")
assert(poopDeck.gui.labels.fishReelButton.style:match("#22304a") ~= nil, "gui should unhighlight reel when fishing state is idle")
poopDeck.fishing.showSize("an enormous")
poopDeck.fishing.onLineDistance("367")
poopDeck.gui.fishingReel()
poopDeck.fishing.parseCaughtLine("With a final tug, you finish reeling in the line and land a redfin tuna weighing 233 pounds and 7 ounces!")
poopDeck.updateGuiNow()
assert(poopDeck.gui.labels.fishingLine1.text:match("Status: Landed") ~= nil, "caught fish should set landed status")
assert(poopDeck.gui.labels.fishingLine1.text:match("Hooked: No") ~= nil, "caught fish should clear hooked display")
assert(poopDeck.gui.labels.fishingLine1.text:match("Line: %-") ~= nil, "caught fish should clear line distance display")
assert(poopDeck.gui.labels.fishingLine2.text == "Caught: 233lb 7oz Redfin Tuna", "gui should show caught fish summary")
assert(poopDeck.gui.labels.fishCastButton.style:match("#22304a") ~= nil, "gui should clear bait highlight after landing a fish")
assert(poopDeck.gui.labels.fishReelButton.style:match("#22304a") ~= nil, "gui should unhighlight reel after landing a fish")
poopDeck.fishing.parseCastSuccess("You cock back your arm and smoothly cast your line over the railing into the nearby water. You judge the cast at about 71 feet.")
poopDeck.updateGuiNow()
assert(poopDeck.gui.labels.fishIdleButton.style:match("#1d4ed8") ~= nil, "gui should highlight idle while cast out and waiting")
assert(poopDeck.gui.labels.fishTeaseButton.style:match("#22304a") ~= nil, "gui should not highlight tease until fishing state is teasing")
local preTeaseStatus = poopDeck.state.fishing.status
reset()
_G[poopDeck.gui.labels.fishTeaseButton.callback]()
assertSent({})
assertEqual(poopDeck.state.fishing.status, preTeaseStatus, "gui tease indicator click should not change fishing status")
assert(poopDeck.gui.labels.fishTeaseButton.style:match("#22304a") ~= nil, "gui tease indicator click should not highlight tease")
poopDeck.fishing.teaseSoon()
poopDeck.updateGuiNow()
assert(poopDeck.gui.labels.fishTeaseButton.style:match("#1d4ed8") ~= nil, "gui should highlight tease when fishing state is teasing")
_G[poopDeck.gui.labels.fishCastButton.callback]()
poopDeck.updateGuiNow()
assert(poopDeck.gui.labels.fishCastButton.style:match("#1d4ed8") ~= nil, "gui should highlight bait after click")
assert(poopDeck.gui.labels.fishTeaseButton.style:match("#22304a") ~= nil, "gui should unhighlight tease after bait click")
poopDeck.gui.teardown()

poopDeck.stats.memory = poopDeck.stats.emptyData()
poopDeck.stats.loaded = true
poopDeck.stats.usingMemory = true
poopDeck.state.fishing.lastCaughtSignature = nil
poopDeck.state.fishing.lastCaughtAt = nil
local statsTimestamp = os.time()
poopDeck.fishing.parseCaughtLine("With a final tug, you finish reeling in the line and land a whiskerknot skrei weighing 74 pounds and 3 ounces!")
poopDeck.fishing.parseCaughtLine("With a final tug, you finish reeling in the line and land a whiskerknot skrei weighing 74 pounds and 3 ounces!")
assertEqual(poopDeck.stats.fishSummary("all").total, 1, "duplicate catch triggers should only record one fish")
poopDeck.stats.recordFishCatch("a redfin tuna", 233, 7, statsTimestamp)
poopDeck.stats.recordFishCatch("redfin tuna", 200, 0, statsTimestamp)
poopDeck.stats.recordFishCatch("rock bass", 10, 3, statsTimestamp)
local fishStats = poopDeck.stats.fishSummary("all")
assertEqual(fishStats.total, 4, "stats should count all fish catches")
assertEqual(fishStats.total_ounces, 8285, "stats should total all fish catch weights")
assertEqual(fishStats.gold, 2861, "stats should estimate sale gold from all fish weights")
assertEqual(fishStats.biggest.fish_type, "redfin tuna", "stats should store normalized fish type")
assertEqual(fishStats.biggest.total_ounces, 3735, "stats should track biggest catch by total ounces")
local tunaStats = poopDeck.stats.fishSummary("all", "redfin tuna")
assertEqual(tunaStats.total, 2, "stats should filter catches by fish type")
assertEqual(poopDeck.stats.fishSummary("today").total, 4, "stats should count today's catches")
poopDeck.stats.recordSeamonsterKill("a pirate ship", statsTimestamp)
poopDeck.stats.recordSeamonsterKill("sea hag", statsTimestamp)
local monsterStats = poopDeck.stats.seamonsterSummary("all")
assertEqual(monsterStats.total, 2, "stats should count seamonster kills")
assertEqual(monsterStats.byType["pirate ship"].count, 1, "stats should normalize monster articles")
assertEqual(poopDeck.stats.seamonsterSummary("today").total, 2, "stats should count today's seamonster kills")
local fishTable = table.concat(poopDeck.stats.fishTableLines(), "\n")
assert(
  fishTable:match("Fish") ~= nil
    and fishTable:match("Today") ~= nil
    and fishTable:match("Week") ~= nil
    and fishTable:match("Month") ~= nil
    and fishTable:match("All") ~= nil
    and fishTable:match("Biggest") ~= nil,
  "fish table should include period headers"
)
assert(fishTable:match("Redfin Tuna") ~= nil, "fish table should include normalized fish names")
assert(fishTable:match("Rock Bass") ~= nil, "fish table should include all fish types")
assert(fishTable:match("233lb 7oz") ~= nil, "fish table should include biggest catch weights")
assert(fishTable:match("Total") ~= nil, "fish table should include a total row")
assert(fishTable:match("Gold") ~= nil, "fish table should include a gold row")
assert(fishTable:match("2861") ~= nil, "fish table should include all-time estimated gold")
local monsterTable = table.concat(poopDeck.stats.seamonsterTableLines(), "\n")
assert(monsterTable:match("|Seamonster%s*|Today|Week|Month|All|") ~= nil, "monster table should include period headers")
assert(monsterTable:match("|Seamonster%s+|Today|Week|Month|All|") ~= nil, "mdk monster table should use tight separators")
assert(monsterTable:match("Pirate Ship") ~= nil, "monster table should include normalized monster names")
assert(monsterTable:match("Sea Hag") ~= nil, "monster table should include all monster types")
assert(monsterTable:match("Total") ~= nil, "monster table should include a total row")
poopDeck.stats.show("fish all redfin tuna")
poopDeck.stats.show("monsters today")
poopDeck.stats.show("db")
poopDeck.stats.show("reset")
assertEqual(poopDeck.stats.fishSummary("all").total, 4, "stats reset should require confirmation")
poopDeck.stats.show("reset confirm")
assertEqual(poopDeck.stats.fishSummary("all").total, 0, "confirmed reset should clear memory fish stats")
assertEqual(poopDeck.stats.seamonsterSummary("all").total, 0, "confirmed reset should clear memory monster stats")

local savedDb = db
local fakeStore = {}
db = {
  create = function(_, _, schema)
    local handle = {}
    for tableName in pairs(schema or {}) do
      fakeStore[tableName] = {}
      handle[tableName] = {__name = tableName}
    end
    return handle
  end,
  add = function(_, dbtable, record)
    local name = dbtable and dbtable.__name
    assert(name and fakeStore[name], "fake db table missing")
    local copy = {}
    for key, value in pairs(record or {}) do
      copy[key] = value
    end
    table.insert(fakeStore[name], copy)
  end,
  fetch = function(_, dbtable)
    local name = dbtable and dbtable.__name
    local rows = {}
    for index, row in ipairs(fakeStore[name] or {}) do
      local copy = {}
      for key, value in pairs(row) do
        copy[key] = value
      end
      rows[index] = copy
    end
    return rows
  end,
  delete = function(_, dbtable, query)
    local name = dbtable and dbtable.__name
    assert(name and fakeStore[name], "fake db table missing")
    if query == true then
      fakeStore[name] = {}
      return true
    end
    error("fake db only supports truncate deletes")
  end
}
poopDeck.stats.loaded = false
poopDeck.stats.load()
assertEqual(poopDeck.stats.usingMemory, false, "stats should use Mudlet DB when db API exists")
poopDeck.stats.recordFishCatch("db tuna", 12, 8, statsTimestamp)
poopDeck.stats.recordSeamonsterKill("a monstrous ketea", statsTimestamp)
assertEqual(#poopDeck.stats.fetchFishCatches(), 1, "db add should persist fish rows")
assertEqual(#poopDeck.stats.fetchSeamonsterKills(), 1, "db add should persist seamonster rows")
assertEqual(poopDeck.stats.fishSummary("all", "db tuna").total, 1, "db-backed fish summary should see persisted row")
assertEqual(poopDeck.stats.seamonsterSummary("all").byType["monstrous ketea"].count, 1, "db-backed monster summary should see persisted row")
poopDeck.combat.onMonsterKilled("a pirate ship")
assertEqual(#poopDeck.stats.fetchSeamonsterKills(), 2, "combat kill handler should persist seamonster row")
assertEqual(poopDeck.stats.seamonsterSummary("all").byType["pirate ship"].count, 1, "combat kill handler should normalize monster type")
poopDeck.stats.show("clear")
assertEqual(#poopDeck.stats.fetchFishCatches(), 1, "db stats reset should require confirmation")
poopDeck.stats.show("clear confirm")
assertEqual(#poopDeck.stats.fetchFishCatches(), 0, "confirmed reset should truncate db fish rows")
assertEqual(#poopDeck.stats.fetchSeamonsterKills(), 0, "confirmed reset should truncate db monster rows")
db = savedDb
poopDeck.stats.loaded = false
poopDeck.stats.memory = poopDeck.stats.emptyData()
poopDeck.stats.load()

reset()
poopDeck.combat.manualFire("f")
assertSent({"curing off", "maintain hull", "load ballista with flare", "fire ballista at seamonster"})
assert(poopDeck.state.combat.firePending == true, "manual fire should be pending before aiming starts")
assert(poopDeck.state.combat.firing == false, "prompt should not show FIRING before aiming starts")
poopDeck.combat.onFiringStarted()
assert(poopDeck.state.combat.firePending == false, "aiming start should clear pending fire")
assert(poopDeck.state.combat.firing == true, "aiming start should set firing")
poopDeck.combat.onWeaponFired()
assert(poopDeck.state.combat.firePending == false, "weapon fired should clear pending fire")
assert(poopDeck.state.combat.firing == false, "weapon fired should clear firing")
resetTimers()

reset()
poopDeck.combat.manualFire("o")
assertSent({"curing off", "maintain hull", "load onager with spidershot", "fire onager at seamonster"})
poopDeck.combat.onWeaponFired()
resetTimers()

poopDeck.combat.stopSession()
reset()
resetTimers()
poopDeck.combat.setWeapon("onager")
poopDeck.combat.setOnagerStrategy("star")
assertEqual(poopDeck.config.get("onagerStrategy"), "star", "star strategy should persist")
poopDeck.combat.setAutoMode("on")
poopDeck.combat.onMonsterSurfaced()
assertSent({"curing off", "maintain hull", "load onager with starshot", "fire onager at seamonster"})
poopDeck.combat.onWeaponFired()
reset()
runTimers()
assertSent({"curing off", "maintain hull", "load onager with starshot", "fire onager at seamonster"})

poopDeck.combat.stopSession()
reset()
resetTimers()
poopDeck.combat.setOnagerStrategy("sp")
assertEqual(poopDeck.config.get("onagerStrategy"), "spider", "sp alias should select spider strategy")
poopDeck.combat.setAutoMode("on")
poopDeck.combat.onMonsterSurfaced()
assertSent({"curing off", "maintain hull", "load onager with spidershot", "fire onager at seamonster"})
poopDeck.combat.onWeaponFired()
reset()
runTimers()
assertSent({"curing off", "maintain hull", "load onager with spidershot", "fire onager at seamonster"})

poopDeck.combat.stopSession()
reset()
resetTimers()
poopDeck.combat.setOnagerStrategy("alt")
assertEqual(poopDeck.config.get("onagerStrategy"), "alternate", "alt alias should select alternating strategy")
poopDeck.combat.setAutoMode("on")
poopDeck.combat.onMonsterSurfaced()
assertSent({"curing off", "maintain hull", "load onager with spidershot", "fire onager at seamonster"})
poopDeck.combat.onWeaponFired()
reset()
runTimers()
assertSent({"curing off", "maintain hull", "load onager with starshot", "fire onager at seamonster"})
poopDeck.combat.stopSession()
reset()
resetTimers()

reset()
poopDeck.state.combat.mode = "manual"
poopDeck.combat.onOutOfRange()
assertSent({"curing on"})
assert(enabled["Ship Moved Lets Try Again"] ~= true, "range retry should not enable in manual mode")

reset()
poopDeck.combat.setAutoMode("on")
poopDeck.combat.setWeapon("ballista")
poopDeck.combat.startSession()
poopDeck.state.events = {}
poopDeck.combat.onOutOfRange()
assertSent({"curing on"})
assert(enabled["Ship Moved Lets Try Again"] == true, "range retry should enable in auto mode")
assertEqual(eventCount("OUT OF RANGE"), 1, "first out-of-range should echo")
for _ = 1, 5 do
  poopDeck.combat.onOutOfRange()
end
assertEqual(eventCount("OUT OF RANGE"), 1, "next five out-of-range events should be muted")
poopDeck.combat.onOutOfRange()
assertEqual(eventCount("OUT OF RANGE"), 2, "seventh out-of-range event should echo again")
poopDeck.combat.onFiringStarted()
poopDeck.combat.onOutOfRange()
assertEqual(eventCount("OUT OF RANGE"), 3, "successful aiming should reset out-of-range echo throttle")

reset()
poopDeck.combat.setAutoMode("off")
assertSent({"curing on"})
assert(poopDeck.state.combat.active == false, "autosea off should stop active combat")
assert(poopDeck.state.combat.outOfRange == false, "autosea off should clear range state")
assert(enabled["Ship Moved Lets Try Again"] == false, "autosea off should disable movement retry trigger")

reset()
resetTimers()
poopDeck.combat.setAutoMode("on")
poopDeck.combat.onMonsterSurfaced()
poopDeck.combat.onWeaponFired()
assertEqual(#timers, 4, "monster surfacing and reload should register combat timers")
reset()
poopDeck.sailing.onDisembarked()
assertEqual(killedTimerCount(), 4, "disembark should kill active combat timers")
assertEqual(poopDeck.state.combat.active, false, "disembark should stop active combat")
assertEqual(enabled["Ship Moved Lets Try Again"], false, "disembark should disable movement retry trigger")
reset()
runTimers()
assertSent({})

reset()
resetTimers()
poopDeck.combat.setAutoMode("on")
poopDeck.combat.onMonsterSurfaced()
assertSent({"curing off", "maintain hull", "load ballista with dart", "fire ballista at seamonster"})
poopDeck.combat.onWeaponFired()
poopDeck.combat.onMonsterKilled("a pirate ship")
assert(poopDeck.state.combat.active == false, "monster kill should stop active combat")
assert(poopDeck.state.combat.outOfRange == false, "monster kill should clear out-of-range flag")
assert(enabled["Ship Moved Lets Try Again"] == false, "monster kill should disable movement retry trigger")
reset()
runTimers()
assertSent({})

reset()
poopDeck.combat.onOutOfRange()
assertSent({"curing on"})
assert(poopDeck.state.combat.outOfRange == false, "late out-of-range after kill should not set prompt flag")

print("smoke_runtime ok")
