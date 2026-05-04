poopDeck = poopDeck or {}
poopDeck.gui = poopDeck.gui or {}
poopDeck.state = poopDeck.state or {}

local gui = poopDeck.gui

gui.windowName = "poopDeck.Gui.Window"
gui.labels = gui.labels or {}

local baseStyle = [[
  QLabel {
    background-color: #101318;
    color: #d8dee9;
    border: 0;
    padding: 3px 6px;
    font-family: "DejaVu Sans Mono";
    font-size: 10pt;
  }
]]

local sectionStyle = [[
  QLabel {
    background-color: #202733;
    color: #f1f5f9;
    border-bottom: 1px solid #374151;
    padding: 3px 6px;
    font-weight: bold;
    font-family: "DejaVu Sans Mono";
    font-size: 10pt;
  }
]]

local buttonStyle = [[
  QLabel {
    background-color: #263241;
    color: #cbd5e1;
    border: 1px solid #475569;
    border-radius: 3px;
    padding: 3px 6px;
    font-family: "DejaVu Sans Mono";
    font-size: 9pt;
  }
]]

local activeButtonStyle = [[
  QLabel {
    background-color: #166534;
    color: #ffffff;
    border: 1px solid #22c55e;
    border-radius: 3px;
    padding: 3px 6px;
    font-family: "DejaVu Sans Mono";
    font-size: 9pt;
  }
]]

local seaGoodStyle = [[
  QLabel {
    background-color: #101318;
    color: #22c55e;
    border: 0;
    padding: 3px 6px;
    font-family: "DejaVu Sans Mono";
    font-size: 10pt;
  }
]]

local seaReducedStyle = [[
  QLabel {
    background-color: #101318;
    color: #facc15;
    border: 0;
    padding: 3px 6px;
    font-family: "DejaVu Sans Mono";
    font-size: 10pt;
  }
]]

local seaBadStyle = [[
  QLabel {
    background-color: #101318;
    color: #ef4444;
    border: 0;
    padding: 3px 6px;
    font-family: "DejaVu Sans Mono";
    font-size: 10pt;
  }
]]

local function valueOrDash(value)
  if value == nil or value == "" then
    return "-"
  end
  return tostring(value)
end

local function titleValue(value)
  if value == nil or value == "" then
    return "-"
  end

  local text = tostring(value):gsub("_", " ")
  return (text:gsub("(%a)([%w']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end))
end

local function boolText(value)
  if value == nil then
    return "-"
  end
  return value and "Yes" or "No"
end

local function healthText(value)
  if value == nil then
    return "-"
  end
  return tostring(value) .. "%"
end

local function repairText(ship)
  if ship.repairingSails and ship.repairingHull then
    return "All"
  end
  if ship.repairingSails then
    return "Sails"
  end
  if ship.repairingHull then
    return "Hull"
  end
  return "None"
end

local function combatStatus()
  local combat = poopDeck.state.combat or {}
  if combat.outOfRange then
    return "Out of Range"
  end
  if combat.firing then
    return "Firing"
  end
  if combat.firePending then
    return "Pending"
  end
  if combat.active then
    return "Active"
  end
  return "Idle"
end

local function autoText(mode)
  return mode == "automatic" and "On" or "Off"
end

local function fishingLineText(fishing)
  if not fishing.lineFeetLeft then
    return "Line: -"
  end
  return "Line: " .. tostring(fishing.lineFeetLeft) .. " ft"
end

local function caughtText(fishing)
  if not fishing.caughtFishType or not fishing.caughtPounds then
    return "Caught: -"
  end

  return string.format(
    "Caught: %slb %soz %s",
    tostring(fishing.caughtPounds),
    tostring(fishing.caughtOunces or 0),
    titleValue(fishing.caughtFishType)
  )
end

local function createLabel(key, spec, parent, style)
  local label = Geyser.Label:new({
    name = "poopDeck.Gui." .. key,
    x = spec.x,
    y = spec.y,
    width = spec.width,
    height = spec.height
  }, parent)
  label:setStyleSheet(style or baseStyle)
  gui.labels[key] = label
  return label
end

local function createButton(key, spec, parent, text, callback)
  local label = createLabel(key, spec, parent, buttonStyle)
  label:echo(text)
  label:setClickCallback(callback)
  return label
end

local function setLabel(key, text)
  local label = gui.labels[key]
  if label then
    label:echo(text)
  end
end

local function setLabelStyle(key, style)
  local label = gui.labels[key]
  if label then
    label:setStyleSheet(style or baseStyle)
  end
end

local function seaStyle(ship)
  if ship.seaBand == "good" then
    return seaGoodStyle
  end
  if ship.seaBand == "reduced" then
    return seaReducedStyle
  end
  if ship.seaBand == "bad" then
    return seaBadStyle
  end
  return baseStyle
end

function gui.teardown()
  gui.labels = {}
  if gui.window then
    pcall(function()
      if gui.window.hide then
        gui.window:hide()
      end
    end)
    pcall(function()
      if gui.window.close then
        gui.window:close()
      end
    end)
  end
  gui.window = nil
  gui.root = nil
  gui.visible = false
end

function gui.build()
  gui.teardown()

  gui.window = Geyser.UserWindow:new({
    name = gui.windowName,
    titleText = "poopDeck",
    x = "65%",
    y = "5%",
    width = "430px",
    height = "430px"
  })

  gui.root = Geyser.Container:new({
    name = "poopDeck.Gui.Root",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%"
  }, gui.window)

  createLabel("header", {x = 0, y = 0, width = "100%", height = "28px"}, gui.root, sectionStyle)

  createLabel("shipTitle", {x = 0, y = 32, width = "100%", height = "24px"}, gui.root, sectionStyle)
  createLabel("shipLine1", {x = 0, y = 58, width = "68%", height = "23px"}, gui.root)
  createLabel("shipSea", {x = "68%", y = 58, width = "32%", height = "23px"}, gui.root)
  createLabel("shipLine2", {x = 0, y = 82, width = "100%", height = "23px"}, gui.root)
  createLabel("shipLine3", {x = 0, y = 106, width = "100%", height = "23px"}, gui.root)

  createLabel("combatTitle", {x = 0, y = 134, width = "100%", height = "24px"}, gui.root, sectionStyle)
  createLabel("combatLine1", {x = 0, y = 160, width = "100%", height = "23px"}, gui.root)
  createLabel("combatLine2", {x = 0, y = 184, width = "100%", height = "23px"}, gui.root)
  createButton("autoButton", {x = "2%", y = 210, width = "18%", height = "25px"}, gui.root, "Auto", "poopDeck.gui.toggleAutoFire")
  createButton("ballistaButton", {x = "22%", y = 210, width = "23%", height = "25px"}, gui.root, "Ballista", "poopDeck.gui.setWeaponBallista")
  createButton("onagerButton", {x = "47%", y = 210, width = "23%", height = "25px"}, gui.root, "Onager", "poopDeck.gui.setWeaponOnager")
  createButton("throwerButton", {x = "72%", y = 210, width = "24%", height = "25px"}, gui.root, "Thrower", "poopDeck.gui.setWeaponThrower")

  createLabel("fishingTitle", {x = 0, y = 242, width = "100%", height = "24px"}, gui.root, sectionStyle)
  createLabel("fishingLine1", {x = 0, y = 268, width = "100%", height = "23px"}, gui.root)
  createLabel("fishingLine2", {x = 0, y = 292, width = "100%", height = "23px"}, gui.root)
  createButton("fishCastButton", {x = "2%", y = 318, width = "22%", height = "25px"}, gui.root, "Fcast", "poopDeck.gui.fishingCastAgain")
  createButton("fishMediumButton", {x = "26%", y = 318, width = "22%", height = "25px"}, gui.root, "Medium", "poopDeck.gui.fishingCastMedium")
  createButton("fishTeaseButton", {x = "50%", y = 318, width = "22%", height = "25px"}, gui.root, "Tease", "poopDeck.gui.fishingTease")
  createButton("fishReelButton", {x = "74%", y = 318, width = "22%", height = "25px"}, gui.root, "Reel", "poopDeck.gui.fishingReel")

  createLabel("eventsTitle", {x = 0, y = 350, width = "100%", height = "24px"}, gui.root, sectionStyle)
  createLabel("events", {x = 0, y = 376, width = "100%", height = "50px"}, gui.root)

  gui.update()
  if (poopDeck.state.ship or {}).isAboard then
    gui.show()
  else
    gui.hide()
  end
end

function gui.update()
  if not gui.window then
    return
  end

  local ship = poopDeck.state.ship or {}
  local combat = poopDeck.state.combat or {}
  local fishing = poopDeck.state.fishing or {}
  local events = poopDeck.state.events or {}
  local weapon = combat.selectedWeapon or (poopDeck.config and poopDeck.config.get and poopDeck.config.get("selectedWeapon")) or "-"
  local mode = combat.mode or "manual"

  setLabel("header", string.format(
    "poopDeck: %s | Auto: %s | Weapon: %s | Status: %s",
    poopDeck.version or "-",
    autoText(mode),
    titleValue(weapon),
    combatStatus()
  ))

  setLabel("shipTitle", string.format(
    "Ship: %s%s%s",
    valueOrDash(ship.name),
    ship.alias and (" / " .. ship.alias) or "",
    ship.id and (" #" .. tostring(ship.id)) or ""
  ))
  setLabel("shipLine1", string.format(
    "Course: %s @ %s | Wind: %s %skts | Row: %s | Sail: %s",
    valueOrDash(ship.currentHeading),
    valueOrDash(ship.actualSpeed),
    valueOrDash(ship.windDirection),
    valueOrDash(ship.windSpeed),
    boolText(ship.isRowing),
    boolText(ship.hasSailBoost)
  ))
  setLabelStyle("shipSea", seaStyle(ship))
  setLabel("shipSea", "Sea: " .. valueOrDash(ship.seaCondition or ship.seaCode))
  setLabel("shipLine2", string.format(
    "Sails: %s (%s) | Hull: %s | Repair: %s",
    healthText(ship.sailHealth),
    valueOrDash(ship.sailSetting),
    healthText(ship.hullHealth),
    repairText(ship)
  ))
  setLabel("shipLine3", string.format(
    "Anchor: %s | Fires: %s | Rigging: %s",
    boolText(ship.anchored),
    boolText(ship.hasFires),
    titleValue(ship.riggings)
  ))

  setLabel("combatTitle", "Seamonsters")
  setLabel("combatLine1", string.format(
    "Status: %s | Shots: %s | Monster: %s",
    combatStatus(),
    valueOrDash(combat.shots),
    titleValue(combat.currentMonster)
  ))
  setLabel("combatLine2", string.format(
    "Pending: %s | Firing: %s | Range: %s",
    boolText(combat.firePending),
    boolText(combat.firing),
    combat.outOfRange and "Out" or "Ok"
  ))
  setLabelStyle("autoButton", mode == "automatic" and activeButtonStyle or buttonStyle)
  setLabelStyle("ballistaButton", weapon == "ballista" and activeButtonStyle or buttonStyle)
  setLabelStyle("onagerButton", weapon == "onager" and activeButtonStyle or buttonStyle)
  setLabelStyle("throwerButton", weapon == "thrower" and activeButtonStyle or buttonStyle)

  setLabel("fishingTitle", "Fishing")
  setLabel("fishingLine1", string.format(
    "Status: %s | Hooked: %s | Size: %s | %s",
    titleValue(fishing.status),
    boolText(fishing.hooked),
    titleValue(fishing.size),
    fishingLineText(fishing)
  ))
  setLabel("fishingLine2", caughtText(fishing))

  local lines = {}
  for index = 1, math.min(#events, 3) do
    table.insert(lines, events[index].text)
  end
  setLabel("events", table.concat(lines, "\n"))
end

function gui.show()
  if not gui.window then
    gui.build()
    return
  end
  if gui.window.show then
    gui.window:show()
  end
  gui.visible = true
  gui.update()
end

function gui.hide()
  if gui.window and gui.window.hide then
    gui.window:hide()
  end
  gui.visible = false
end

function gui.toggleAutoFire()
  local mode = (poopDeck.state.combat or {}).mode
  poopDeck.combat.setAutoMode(mode == "automatic" and "off" or "on")
  gui.update()
end

function gui.stopCombat()
  poopDeck.combat.stop()
  gui.update()
end

function gui.setWeaponBallista()
  poopDeck.combat.setWeapon("ballista")
  gui.update()
end

function gui.setWeaponOnager()
  poopDeck.combat.setWeapon("onager")
  gui.update()
end

function gui.setWeaponThrower()
  poopDeck.combat.setWeapon("thrower")
  gui.update()
end

function gui.fishingCastAgain()
  poopDeck.fishing.castAgain()
end

function gui.fishingCastMedium()
  poopDeck.fishing.castMedium()
end

function gui.fishingTease()
  poopDeck.safeSend("tease line")
end

function gui.fishingReel()
  poopDeck.fishing.reel()
  gui.update()
end
