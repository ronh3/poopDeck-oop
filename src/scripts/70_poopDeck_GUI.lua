poopDeck = poopDeck or {}
poopDeck.gui = poopDeck.gui or {}
poopDeck.state = poopDeck.state or {}

local gui = poopDeck.gui

gui.windowName = "poopDeck.Gui.Window"
gui.labels = gui.labels or {}
gui.styles = gui.styles or {}
gui.themeHandlers = gui.themeHandlers or {}

local baseStyle
local sectionStyle
local buttonStyle
local activeButtonStyle
local rangeButtonStyle
local seaGoodStyle
local seaReducedStyle
local seaBadStyle

local cssColors = {
  aliceblue = "#f0f8ff",
  black = "#000000",
  antiquewhite = "#faebd7",
  beige = "#f5f5dc",
  burlywood = "#deb887",
  cadetblue = "#5f9ea0",
  chartreuse = "#7fff00",
  cornflowerblue = "#6495ed",
  cyan = "#00ffff",
  darkgoldenrod = "#b8860b",
  darkkhaki = "#bdb76b",
  darkolivegreen = "#556b2f",
  darkorchid = "#9932cc",
  darkseagreen = "#8fbc8f",
  darkslateblue = "#483d8b",
  darkslategray = "#2f4f4f",
  darkslategrey = "#2f4f4f",
  darkturquoise = "#00ced1",
  deepskyblue = "#00bfff",
  firebrick = "#b22222",
  forestgreen = "#228b22",
  gainsboro = "#dcdcdc",
  gold = "#ffd700",
  goldenrod = "#daa520",
  gray = "#808080",
  green = "#008000",
  grey = "#808080",
  honeydew = "#f0fff0",
  ivory = "#fffff0",
  lavenderblush = "#fff0f5",
  lavender = "#e6e6fa",
  lightgray = "#d3d3d3",
  lightgoldenrod = "#eedd82",
  lightgoldenrodyellow = "#fafad2",
  lightgrey = "#d3d3d3",
  lightcyan = "#e0ffff",
  lightsteelblue = "#b0c4de",
  lightskyblue = "#87cefa",
  lightyellow = "#ffffe0",
  lightslategray = "#778899",
  lightslategrey = "#778899",
  magenta = "#ff00ff",
  maroon = "#800000",
  mediumaquamarine = "#66cdaa",
  midnightblue = "#191970",
  mistyrose = "#ffe4e1",
  olivedrab = "#6b8e23",
  orange = "#ffa500",
  orangered = "#ff4500",
  orchid = "#da70d6",
  palegreen = "#98fb98",
  peru = "#cd853f",
  plum = "#dda0dd",
  powderblue = "#b0e0e6",
  purple = "#800080",
  red = "#ff0000",
  rosybrown = "#bc8f8f",
  royalblue = "#4169e1",
  saddlebrown = "#8b4513",
  sandybrown = "#f4a460",
  seagreen = "#2e8b57",
  sienna = "#a0522d",
  slateblue = "#6a5acd",
  slategray = "#708090",
  slategrey = "#708090",
  springgreen = "#00ff7f",
  steelblue = "#4682b4",
  tan = "#d2b48c",
  thistle = "#d8bfd8",
  wheat = "#f5deb3",
  whitesmoke = "#f5f5f5",
  yellow = "#ffff00",
  white = "#ffffff"
}

local builtinThemes = {
  default = {
    name = "default",
    label = "Default",
    accent = "#00ffff",
    border = "#808080",
    text = "#d8dee9",
    muted = "#cbd5e1",
    background = "#0f1726",
    panel = "#172033",
    section = "#23314b",
    button = "#22304a",
    buttonBorder = "#475569",
    active = "#1d4ed8",
    range = "#7f1d1d",
    tags = {
      accent = "<cyan>",
      border = "<grey>",
      text = "<light_steel_blue>",
      muted = "<light_grey>",
      reset = "<reset>",
      good = "<green>",
      reduced = "<yellow>",
      bad = "<red>"
    }
  },
  runewarden = {
    name = "runewarden",
    label = "Runewarden",
    accent = "#4169e1",
    border = "#cd853f",
    text = "#e5edf7",
    muted = "#9ca3af",
    background = "#0f1726",
    panel = "#172033",
    section = "#23314b",
    button = "#22304a",
    buttonBorder = "#cd853f",
    active = "#1d4ed8",
    range = "#7f1d1d",
    tags = {
      accent = "<royal_blue>",
      border = "<peru>",
      text = "<alice_blue>",
      muted = "<light_slate_gray>",
      reset = "<reset>",
      good = "<green>",
      reduced = "<yellow>",
      bad = "<red>"
    }
  }
}

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function configValue(key, fallback)
  if poopDeck.config and type(poopDeck.config.get) == "function" then
    local value = poopDeck.config.get(key)
    if value ~= nil then
      return value
    end
  end
  return fallback
end

function gui.isEnabled()
  return configValue("guiEnabled", true) == true
end

local function cssColor(value, fallback)
  local text = trim(value)
  text = text:gsub("^<", ""):gsub(">$", ""):gsub("^ansi_", ""):gsub("^ansi", "")
  text = text:gsub("^light_", "light_")
  if text == "" or text == "reset" then
    return fallback
  end
  if text:match("^#%x%x%x%x%x%x$") or text:match("^#%x%x%x$") then
    return text
  end
  local key = text:lower():gsub("_", "")
  return cssColors[key] or fallback or text:gsub("_", "")
end

local function expandHex(hex)
  local text = tostring(hex or "")
  if text:match("^#%x%x%x$") then
    return "#" .. text:sub(2, 2) .. text:sub(2, 2)
      .. text:sub(3, 3) .. text:sub(3, 3)
      .. text:sub(4, 4) .. text:sub(4, 4)
  end
  if text:match("^#%x%x%x%x%x%x$") then
    return text
  end
  return nil
end

local function hexToRgb(hex)
  local text = expandHex(hex)
  if not text then
    return nil
  end

  return {
    r = tonumber(text:sub(2, 3), 16),
    g = tonumber(text:sub(4, 5), 16),
    b = tonumber(text:sub(6, 7), 16)
  }
end

local function rgbToHex(red, green, blue)
  local function clamp(value)
    value = math.floor((tonumber(value) or 0) + 0.5)
    if value < 0 then
      return 0
    end
    if value > 255 then
      return 255
    end
    return value
  end

  return string.format("#%02x%02x%02x", clamp(red), clamp(green), clamp(blue))
end

local function blend(left, right, rightWeight)
  local leftRgb = hexToRgb(left)
  local rightRgb = hexToRgb(right)
  if not leftRgb or not rightRgb then
    return left
  end

  local weight = tonumber(rightWeight) or 0
  if weight < 0 then
    weight = 0
  elseif weight > 1 then
    weight = 1
  end

  local leftWeight = 1 - weight
  return rgbToHex(
    leftRgb.r * leftWeight + rightRgb.r * weight,
    leftRgb.g * leftWeight + rightRgb.g * weight,
    leftRgb.b * leftWeight + rightRgb.b * weight
  )
end

local function darken(hex, amount)
  return blend(hex, "#000000", amount)
end

local function deriveAdbSurfaces(theme)
  local borderBase = expandHex(theme.border) or builtinThemes.runewarden.border
  local accentBase = expandHex(theme.accent) or builtinThemes.runewarden.accent
  local mutedBase = expandHex(theme.muted) or accentBase

  theme.background = darken(accentBase, 0.88)
  theme.panel = blend(darken(accentBase, 0.75), borderBase, 0.08)
  theme.section = blend(darken(accentBase, 0.62), borderBase, 0.12)
  theme.button = blend(darken(accentBase, 0.72), mutedBase, 0.15)
  theme.buttonBorder = theme.border
  theme.active = blend(darken(accentBase, 0.18), "#ffffff", 0.08)
end

local function adbTheme()
  local theme = {}
  for key, value in pairs(builtinThemes.runewarden) do
    theme[key] = value
  end
  local tags
  local payload = type(gui.adbThemePayload) == "table" and gui.adbThemePayload or nil
  if payload and type(payload.tags) == "table" then
    tags = payload.tags
    theme.label = payload.label or theme.label
  end
  if type(agnosticdb) == "table" and type(agnosticdb.ui) == "table" and type(agnosticdb.ui.theme_tags) == "function" then
    local ok, result = pcall(agnosticdb.ui.theme_tags)
    if ok and type(result) == "table" then
      if not gui.preferAdbThemePayload then
        tags = result
        theme.label = "agnosticDB"
      end
    end
  end
  if type(tags) ~= "table" then
    return nil
  end
  theme.name = "agnosticdb"
  theme.label = theme.label or "agnosticDB"
  theme.accent = cssColor(tags.accent, theme.accent)
  theme.border = cssColor(tags.border, theme.border)
  theme.text = cssColor(tags.text, theme.text)
  theme.muted = cssColor(tags.muted, theme.muted)
  deriveAdbSurfaces(theme)
  theme.range = "#7f1d1d"
  theme.tags = {
    accent = tags.accent or "<royal_blue>",
    border = tags.border or "<peru>",
    text = tags.text or "<alice_blue>",
    muted = tags.muted or "<light_slate_gray>",
    reset = tags.reset or "<reset>",
    good = "<green>",
    reduced = "<yellow>",
    bad = "<red>"
  }
  return theme
end

local function usesAdbTheme()
  local requested = tostring(configValue("guiTheme", "agnosticdb")):lower()
  return requested == "agnosticdb" or requested == "adb" or requested == "auto"
end

local function currentTheme()
  local requested = tostring(configValue("guiTheme", "agnosticdb")):lower()
  if usesAdbTheme() then
    return adbTheme() or builtinThemes.runewarden
  end
  return builtinThemes[requested] or builtinThemes.runewarden
end

local function labelStyle(background, color, options)
  options = options or {}
  local border = options.border or "0"
  local radius = options.radius and ("border-radius: " .. options.radius .. ";") or ""
  local bottomBorder = options.bottomBorder and ("border-bottom: " .. options.bottomBorder .. ";") or ""
  local weight = options.bold and "font-weight: bold;" or ""
  local size = options.size or "10pt"
  return string.format([[
  QLabel {
    background-color: %s;
    color: %s;
    border: %s;
    %s
    %s
    padding: 3px 6px;
    %s
    font-family: "DejaVu Sans Mono";
    font-size: %s;
  }
]], background, color, border, radius, bottomBorder, weight, size)
end

local function frameStyle(theme)
  return string.format([[
  QWidget {
    background-color: %s;
    border: 1px solid %s;
  }
]], theme.panel, theme.border)
end

local function rebuildStyles()
  local theme = currentTheme()
  gui.currentTheme = theme
  gui.styles.theme = theme
  baseStyle = labelStyle(theme.panel, theme.text)
  sectionStyle = labelStyle(theme.section, theme.accent, {
    border = "0",
    bottomBorder = "1px solid " .. theme.border,
    bold = true
  })
  buttonStyle = labelStyle(theme.button, theme.text, {
    border = "1px solid " .. theme.buttonBorder,
    radius = "3px",
    size = "9pt"
  })
  activeButtonStyle = labelStyle(theme.active, "#ffffff", {
    border = "1px solid " .. theme.border,
    radius = "3px",
    size = "9pt"
  })
  rangeButtonStyle = labelStyle(theme.range or "#7f1d1d", "#ffffff", {
    border = "1px solid " .. theme.border,
    radius = "3px",
    size = "9pt"
  })
  gui.styles.backdrop = labelStyle(theme.panel, theme.text)
  seaGoodStyle = labelStyle(theme.panel, "#22c55e")
  seaReducedStyle = labelStyle(theme.panel, "#facc15")
  seaBadStyle = labelStyle(theme.panel, "#ef4444")
  gui.styles.frame = frameStyle(theme)
end

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

local function fishingStatusIs(fishing, ...)
  local status = tostring((fishing or {}).status or ""):lower()
  for _, expected in ipairs({...}) do
    if status == tostring(expected):lower() then
      return true
    end
  end
  return false
end

local function fishingButtonStates(fishing)
  fishing = fishing or {}
  return {
    bait = fishing.lastAction == "bait",
    cast = fishing.lastAction == "cast",
    idle = fishing.lastAction == "idle" or (fishing.lastAction == nil and fishingStatusIs(fishing, "idle", "waiting")),
    tease = fishing.lastAction == "tease",
    reel = fishing.lastAction == "reel"
  }
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

local setLabel

local function createButton(key, spec, parent, text, callback)
  local label = createLabel(key, spec, parent, buttonStyle)
  setLabel(key, text, "text")
  local callbackName = "poopDeckGui_" .. key
  _G[callbackName] = function()
    if type(callback) == "function" then
      callback()
      return
    end

    if type(callback) == "string" then
      local context = _G
      for part in callback:gmatch("[^%.]+") do
        context = type(context) == "table" and context[part] or nil
      end
      if type(context) == "function" then
        context()
      end
    end
  end
  label:setClickCallback(callbackName)
  return label
end

local function themeTag(kind)
  local theme = gui.currentTheme or currentTheme()
  local tags = theme.tags or {}
  return tags[kind or "text"] or tags.text or ""
end

local function resetTag()
  local theme = gui.currentTheme or currentTheme()
  local tags = theme.tags or {}
  return tags.reset or "<reset>"
end

function setLabel(key, text, colorKind)
  local label = gui.labels[key]
  if label then
    label.text = text
    if label.cecho then
      label:cecho(themeTag(colorKind or "text") .. tostring(text) .. resetTag())
    else
      label:echo(text)
    end
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
    return seaGoodStyle, "good"
  end
  if ship.seaBand == "reduced" then
    return seaReducedStyle, "reduced"
  end
  if ship.seaBand == "bad" then
    return seaBadStyle, "bad"
  end
  return baseStyle, "text"
end

local function normalizePosition(value)
  local text = trim(value)
  if text == "" then
    return nil
  end
  if text:match("^%-?%d+$") then
    return text .. "px"
  end
  if text:match("^%-?%d+px$") or text:match("^%d+%%$") then
    return text
  end
  return nil
end

local function normalizeSize(value)
  local text = trim(value)
  if text == "" then
    return nil
  end
  if text:match("^%d+$") then
    return text .. "px"
  end
  if text:match("^%d+px$") or text:match("^%d+%%$") then
    return text
  end
  return nil
end

local function windowSpec()
  return {
    name = gui.windowName,
    titleText = "poopDeck " .. tostring(poopDeck.version or ""),
    x = configValue("guiX", "80px"),
    y = configValue("guiY", "80px"),
    width = configValue("guiWidth", "720px"),
    height = configValue("guiHeight", "360px"),
    restoreLayout = configValue("guiRestoreLayout", true) == true,
    dockPosition = "floating",
    autoDock = false
  }
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
  if not gui.isEnabled() then
    gui.teardown()
    return false
  end

  gui.teardown()
  rebuildStyles()

  gui.window = Geyser.UserWindow:new(windowSpec())
  if gui.window.setStyleSheet then
    gui.window:setStyleSheet(gui.styles.frame)
  end

  gui.root = Geyser.Container:new({
    name = "poopDeck.Gui.Root",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%"
  }, gui.window)
  if gui.root.setStyleSheet then
    gui.root:setStyleSheet(gui.styles.frame)
  end

  createLabel("backdrop", {x = 0, y = 0, width = "100%", height = "100%"}, gui.root, gui.styles.backdrop)
  createLabel("header", {x = 0, y = 0, width = "100%", height = "28px"}, gui.root, sectionStyle)

  createLabel("shipTitle", {x = 0, y = 32, width = "100%", height = "24px"}, gui.root, sectionStyle)
  createLabel("shipLine1", {x = 0, y = 58, width = "68%", height = "23px"}, gui.root)
  createLabel("shipSea", {x = "68%", y = 58, width = "32%", height = "23px"}, gui.root)
  createLabel("shipLine2", {x = 0, y = 82, width = "100%", height = "23px"}, gui.root)
  createLabel("shipLine3", {x = 0, y = 106, width = "100%", height = "23px"}, gui.root)

  createLabel("combatTitle", {x = 0, y = 134, width = "100%", height = "24px"}, gui.root, sectionStyle)
  createLabel("combatLine1", {x = 0, y = 160, width = "100%", height = "23px"}, gui.root)
  createLabel("combatLine2", {x = 0, y = 184, width = "100%", height = "23px"}, gui.root)
  createButton("autoButton", {x = "2%", y = 210, width = "16%", height = "25px"}, gui.root, "Auto", "poopDeck.gui.toggleAutoFire")
  createButton("firingButton", {x = "20%", y = 210, width = "16%", height = "25px"}, gui.root, "Firing", "poopDeck.gui.noop")
  createButton("ballistaButton", {x = "38%", y = 210, width = "18%", height = "25px"}, gui.root, "Ballista", "poopDeck.gui.setWeaponBallista")
  createButton("onagerButton", {x = "58%", y = 210, width = "18%", height = "25px"}, gui.root, "Onager", "poopDeck.gui.setWeaponOnager")
  createButton("throwerButton", {x = "78%", y = 210, width = "20%", height = "25px"}, gui.root, "Thrower", "poopDeck.gui.setWeaponThrower")

  createLabel("fishingTitle", {x = 0, y = 242, width = "100%", height = "24px"}, gui.root, sectionStyle)
  createLabel("fishingLine1", {x = 0, y = 268, width = "100%", height = "23px"}, gui.root)
  createLabel("fishingLine2", {x = 0, y = 292, width = "100%", height = "23px"}, gui.root)
  createButton("fishCastButton", {x = "2%", y = 318, width = "17%", height = "25px"}, gui.root, "Bait", "poopDeck.gui.fishingCastAgain")
  createButton("fishMediumButton", {x = "21%", y = 318, width = "17%", height = "25px"}, gui.root, "Cast", "poopDeck.gui.fishingCastMedium")
  createButton("fishIdleButton", {x = "40%", y = 318, width = "17%", height = "25px"}, gui.root, "Idle", "poopDeck.gui.noop")
  createButton("fishTeaseButton", {x = "59%", y = 318, width = "17%", height = "25px"}, gui.root, "Tease", "poopDeck.gui.noop")
  createButton("fishReelButton", {x = "78%", y = 318, width = "20%", height = "25px"}, gui.root, "Reel", "poopDeck.gui.fishingReel")

  gui.update()
  if (poopDeck.state.ship or {}).isAboard then
    gui.show()
  else
    gui.hide()
  end
  return true
end

function gui.update()
  if not gui.window then
    return
  end

  local ship = poopDeck.state.ship or {}
  local combat = poopDeck.state.combat or {}
  local fishing = poopDeck.state.fishing or {}
  local weapon = combat.selectedWeapon or (poopDeck.config and poopDeck.config.get and poopDeck.config.get("selectedWeapon")) or "-"
  local onagerStrategy = combat.onagerStrategy or (poopDeck.config and poopDeck.config.get and poopDeck.config.get("onagerStrategy")) or "alternate"
  local mode = combat.mode or "manual"

  setLabel("header", string.format(
    "Auto: %s | Weapon: %s | Status: %s",
    autoText(mode),
    titleValue(weapon),
    combatStatus()
  ), "accent")

  setLabel("shipTitle", string.format(
    "Ship: %s%s%s",
    valueOrDash(ship.name),
    ship.alias and (" / " .. ship.alias) or "",
    ship.id and (" #" .. tostring(ship.id)) or ""
  ), "accent")
  setLabel("shipLine1", string.format(
    "Course: %s @ %s | Wind: %s %skts | Row: %s | Sail: %s",
    valueOrDash(ship.currentHeading),
    valueOrDash(ship.actualSpeed),
    valueOrDash(ship.windDirection),
    valueOrDash(ship.windSpeed),
    boolText(ship.isRowing),
    boolText(ship.hasSailBoost)
  ))
  local shipSeaStyle, shipSeaColor = seaStyle(ship)
  setLabelStyle("shipSea", shipSeaStyle)
  setLabel("shipSea", "Sea: " .. valueOrDash(ship.seaCondition or ship.seaCode), shipSeaColor)
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

  setLabel("combatTitle", "Seamonsters", "accent")
  setLabel("combatLine1", string.format(
    "Status: %s | Shots: %s | Monster: %s",
    combatStatus(),
    valueOrDash(combat.shots),
    titleValue(combat.currentMonster)
  ))
  setLabel("combatLine2", string.format(
    "Pending: %s | Range: %s | Strategy: %s",
    boolText(combat.firePending),
    combat.outOfRange and "Out" or "Ok",
    titleValue(onagerStrategy)
  ))
  setLabelStyle("autoButton", mode == "automatic" and activeButtonStyle or buttonStyle)
  setLabel("autoButton", "Auto")
  setLabelStyle("firingButton", combat.outOfRange and rangeButtonStyle or (combat.firing and activeButtonStyle or buttonStyle))
  setLabel("firingButton", combat.outOfRange and "Range" or "Firing")
  setLabelStyle("ballistaButton", weapon == "ballista" and activeButtonStyle or buttonStyle)
  setLabel("ballistaButton", "Ballista")
  setLabelStyle("onagerButton", weapon == "onager" and activeButtonStyle or buttonStyle)
  setLabel("onagerButton", "Onager")
  setLabelStyle("throwerButton", weapon == "thrower" and activeButtonStyle or buttonStyle)
  setLabel("throwerButton", "Thrower")

  setLabel("fishingTitle", "Fishing", "accent")
  setLabel("fishingLine1", string.format(
    "Status: %s | Hooked: %s | Size: %s | %s",
    titleValue(fishing.status),
    boolText(fishing.hooked),
    titleValue(fishing.size),
    fishingLineText(fishing)
  ))
  setLabel("fishingLine2", caughtText(fishing))
  local fishButtons = fishingButtonStates(fishing)
  setLabelStyle("fishCastButton", fishButtons.bait and activeButtonStyle or buttonStyle)
  setLabelStyle("fishMediumButton", fishButtons.cast and activeButtonStyle or buttonStyle)
  setLabelStyle("fishIdleButton", fishButtons.idle and activeButtonStyle or buttonStyle)
  setLabelStyle("fishTeaseButton", fishButtons.tease and activeButtonStyle or buttonStyle)
  setLabelStyle("fishReelButton", fishButtons.reel and activeButtonStyle or buttonStyle)
  setLabel("fishCastButton", "Bait")
  setLabel("fishMediumButton", "Cast")
  setLabel("fishIdleButton", "Idle")
  setLabel("fishTeaseButton", "Tease")
  setLabel("fishReelButton", "Reel")

end

function gui.show()
  if not gui.isEnabled() then
    gui.hide()
    return false
  end
  if not gui.window then
    return gui.build()
  end
  if gui.window.show then
    gui.window:show()
  end
  gui.visible = true
  gui.update()
  return true
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

function gui.fishingIdle()
  poopDeck.fishing.idle()
end

function gui.fishingTease()
  poopDeck.fishing.teaseNow()
end

function gui.fishingReel()
  poopDeck.fishing.reel()
  gui.update()
end

function gui.noop()
end

function gui.rebuild()
  local shouldShow = gui.isEnabled() and (gui.visible or (poopDeck.state.ship or {}).isAboard)
  gui.build()
  if shouldShow then
    gui.show()
  end
end

function gui.onAdbThemeChanged(eventName, payload)
  local themePayload = payload
  if type(eventName) == "table" and payload == nil then
    themePayload = eventName
  end
  if type(themePayload) == "table" then
    gui.adbThemePayload = themePayload
  end
  if not usesAdbTheme() then
    if poopDeck.config and type(poopDeck.config.set) == "function" then
      poopDeck.config.set("guiTheme", "agnosticdb")
    end
    if poopDeck.config and type(poopDeck.config.save) == "function" then
      poopDeck.config.save()
    end
  end
  if gui.window then
    gui.preferAdbThemePayload = true
    gui.rebuild()
    gui.preferAdbThemePayload = false
  end
end

function gui.registerThemeHandlers()
  if gui.themeHandlerRegistered or type(registerAnonymousEventHandler) ~= "function" then
    return
  end
  local handlerId = registerAnonymousEventHandler("agnosticdb.theme.changed", function(eventName, payload)
    gui.onAdbThemeChanged(eventName, payload)
  end)
  if handlerId then
    table.insert(gui.themeHandlers, handlerId)
  end
  gui.themeHandlerRegistered = true
end

function gui.unregisterThemeHandlers()
  if type(killAnonymousEventHandler) == "function" then
    for _, handlerId in ipairs(gui.themeHandlers or {}) do
      pcall(killAnonymousEventHandler, handlerId)
    end
  end
  gui.themeHandlers = {}
  gui.themeHandlerRegistered = false
end

function gui.showSettings()
  local spec = windowSpec()
  local theme = currentTheme()
  poopDeck.output.status("poopDeck GUI", {
    "Enabled: " .. tostring(gui.isEnabled()),
    "Restore layout: " .. tostring(spec.restoreLayout),
    "Theme: " .. tostring(configValue("guiTheme", "agnosticdb")) .. " (" .. tostring(theme.label or theme.name) .. ")",
    "Position: " .. tostring(spec.x) .. ", " .. tostring(spec.y),
    "Size: " .. tostring(spec.width) .. " x " .. tostring(spec.height),
    "poopgui on|off - enable or disable the GUI window",
    "poopgui theme adb|runewarden|default - set GUI theme source",
    "poopgui restore on|off - use Mudlet's saved window layout",
    "poopgui pos <x> <y> - set spawn position",
    "poopgui size <width> <height> - set spawn size",
    "poopgui reset - restore default position and size"
  })
end

function gui.setEnabled(enabled)
  local value = enabled == true
  poopDeck.config.set("guiEnabled", value)
  poopDeck.config.save()
  if value then
    if (poopDeck.state.ship or {}).isAboard then
      gui.show()
    else
      gui.build()
    end
  else
    gui.teardown()
  end
  poopDeck.output.good("GUI " .. (value and "enabled" or "disabled"))
  return true
end

function gui.setPosition(x, y)
  local normalizedX = normalizePosition(x)
  local normalizedY = normalizePosition(y)
  if not normalizedX or not normalizedY then
    poopDeck.output.bad("Use: poopgui pos <x> <y>  Example: poopgui pos 80 80")
    return false
  end
  poopDeck.config.set("guiRestoreLayout", false)
  poopDeck.config.set("guiX", normalizedX)
  poopDeck.config.set("guiY", normalizedY)
  poopDeck.config.save()
  gui.rebuild()
  poopDeck.output.good("GUI position set to " .. normalizedX .. ", " .. normalizedY)
  return true
end

function gui.setSize(width, height)
  local normalizedWidth = normalizeSize(width)
  local normalizedHeight = normalizeSize(height)
  if not normalizedWidth or not normalizedHeight then
    poopDeck.output.bad("Use: poopgui size <width> <height>  Example: poopgui size 720 360")
    return false
  end
  poopDeck.config.set("guiRestoreLayout", false)
  poopDeck.config.set("guiWidth", normalizedWidth)
  poopDeck.config.set("guiHeight", normalizedHeight)
  poopDeck.config.save()
  gui.rebuild()
  poopDeck.output.good("GUI size set to " .. normalizedWidth .. " x " .. normalizedHeight)
  return true
end

function gui.resetSettings()
  poopDeck.config.set("guiX", "80px")
  poopDeck.config.set("guiY", "80px")
  poopDeck.config.set("guiWidth", "720px")
  poopDeck.config.set("guiHeight", "360px")
  poopDeck.config.set("guiRestoreLayout", true)
  poopDeck.config.save()
  gui.rebuild()
  poopDeck.output.good("GUI position, size, and layout restore reset")
end

function gui.setRestoreLayout(enabled)
  poopDeck.config.set("guiRestoreLayout", enabled == true)
  poopDeck.config.save()
  gui.rebuild()
  poopDeck.output.good("GUI restore layout " .. (enabled and "enabled" or "disabled"))
end

function gui.setTheme(theme)
  local key = tostring(theme or ""):lower()
  if key == "adb" or key == "agnosticdb" or key == "auto" then
    key = "agnosticdb"
  end
  if key ~= "agnosticdb" and key ~= "runewarden" and key ~= "default" then
    poopDeck.output.bad("Use: poopgui theme adb|runewarden|default")
    return false
  end
  poopDeck.config.set("guiTheme", key)
  poopDeck.config.save()
  gui.rebuild()
  poopDeck.output.good("GUI theme set to " .. key)
  return true
end

function gui.command(args)
  local input = trim(args)
  if input == "" then
    gui.showSettings()
    return
  end

  local command, rest = input:match("^(%S+)%s*(.-)$")
  command = tostring(command or ""):lower()
  rest = trim(rest)

  if command == "on" or command == "show" or command == "enable" or command == "enabled" then
    gui.setEnabled(true)
    return
  end

  if command == "off" or command == "hide" or command == "disable" or command == "disabled" then
    gui.setEnabled(false)
    return
  end

  if command == "pos" or command == "position" then
    local x, y = rest:match("^(%S+)%s+(%S+)$")
    gui.setPosition(x, y)
    return
  end

  if command == "size" then
    local width, height = rest:match("^(%S+)%s+(%S+)$")
    gui.setSize(width, height)
    return
  end

  if command == "restore" or command == "layout" then
    local value = rest:lower()
    if value == "on" or value == "true" or value == "yes" then
      gui.setRestoreLayout(true)
    elseif value == "off" or value == "false" or value == "no" then
      gui.setRestoreLayout(false)
    else
      poopDeck.output.bad("Use: poopgui restore on|off")
    end
    return
  end

  if command == "theme" then
    if rest == "" then
      gui.showSettings()
    else
      gui.setTheme(rest)
    end
    return
  end

  if command == "reset" then
    gui.resetSettings()
    return
  end

  gui.showSettings()
end
