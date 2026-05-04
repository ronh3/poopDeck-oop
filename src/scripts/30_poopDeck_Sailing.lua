poopDeck = poopDeck or {}
poopDeck.sailing = poopDeck.sailing or {}
poopDeck.state = poopDeck.state or {}
poopDeck.state.ship = poopDeck.state.ship or {}

local sailing = poopDeck.sailing
local ship = poopDeck.state.ship

sailing.directions = {
  e = "east",
  ene = "east-northeast",
  ese = "east-southeast",
  n = "north",
  nnw = "north-northwest",
  nne = "north-northeast",
  ne = "northeast",
  nw = "northwest",
  s = "south",
  sse = "south-southeast",
  ssw = "south-southwest",
  se = "southeast",
  sw = "southwest",
  w = "west",
  wnw = "west-northwest",
  wsw = "west-southwest"
}

sailing.namedSpeeds = {
  strike = "say strike sails!",
  furl = "say furl sails!",
  full = "say full sails!",
  relax = "say relax sails!"
}

sailing.seaStates = {
  I = {name = "Glassy", band = "good"},
  II = {name = "Smooth", band = "good"},
  III = {name = "Calm", band = "good"},
  IV = {name = "Choppy", band = "reduced"},
  V = {name = "Whitecapped", band = "reduced"},
  VI = {name = "Rough", band = "reduced"},
  VII = {name = "Stormy", band = "reduced"},
  VIII = {name = "Tempestuous", band = "bad"},
  IX = {name = "Raging", band = "bad"}
}

sailing.seaCodes = {
  I = sailing.seaStates.I.name,
  II = sailing.seaStates.II.name,
  III = sailing.seaStates.III.name,
  IV = sailing.seaStates.IV.name,
  V = sailing.seaStates.V.name,
  VI = sailing.seaStates.VI.name,
  VII = sailing.seaStates.VII.name,
  VIII = sailing.seaStates.VIII.name,
  IX = sailing.seaStates.IX.name
}

local seaBands = {
  glassy = "good",
  smooth = "good",
  calm = "good",
  choppy = "reduced",
  whitecapped = "reduced",
  rough = "reduced",
  stormy = "reduced",
  tempestuous = "bad",
  raging = "bad"
}

local directionNames = {
  east = "E",
  ["east-northeast"] = "ENE",
  ["east-southeast"] = "ESE",
  north = "N",
  ["north-northwest"] = "NNW",
  ["north-northeast"] = "NNE",
  northeast = "NE",
  northwest = "NW",
  south = "S",
  ["south-southeast"] = "SSE",
  ["south-southwest"] = "SSW",
  southeast = "SE",
  southwest = "SW",
  west = "W",
  ["west-northwest"] = "WNW",
  ["west-southwest"] = "WSW"
}

local function trim(value)
  return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function parseHealth(value)
  value = trim(value)
  if value == "" then
    return nil
  end
  if value == "++" or value:lower() == "full" then
    return 100
  end
  return tonumber(value:match("(%d+)"))
end

local function normalizeSailSetting(value)
  value = trim(value)
  if value == "++" then
    return "Full"
  end
  if value == "--" then
    return "0"
  end
  return value
end

local function yesNo(value)
  value = trim(value):lower():gsub("%.$", "")
  if value == "yes" then
    return true
  end
  if value == "no" then
    return false
  end
  return nil
end

local function directionAbbrev(value)
  value = trim(value):lower()
  return directionNames[value] or value:upper()
end

local function showGuiIfAvailable()
  if poopDeck.gui and type(poopDeck.gui.show) == "function" then
    poopDeck.gui.show()
  else
    poopDeck.refreshGui()
  end
end

local function applyPrompt(data)
  ship.isAboard = true
  ship.promptMode = data.promptMode or ship.promptMode
  ship.rawPrompt = data.rawPrompt or ship.rawPrompt
  ship.sailSetting = data.sails or ship.sailSetting
  ship.currentSpeed = data.sails or ship.currentSpeed
  ship.sailHealth = data.sailHealth or ship.sailHealth
  ship.hullHealth = data.hullHealth or ship.hullHealth
  ship.windDirection = data.windDirection or ship.windDirection
  ship.windSpeed = data.windSpeed or ship.windSpeed
  ship.currentHeading = data.heading or ship.currentHeading
  ship.actualSpeed = data.speed or ship.actualSpeed
  ship.seaCode = data.seaCode or ship.seaCode
  ship.seaCondition = data.seaCondition or ship.seaCondition
  ship.seaBand = data.seaBand or (ship.seaCondition and seaBands[ship.seaCondition:lower()]) or ship.seaBand
  ship.isRowing = data.isRowing == true
  ship.hasSailBoost = data.hasSailBoost == true
  ship.turningTo = data.turningTo
  showGuiIfAvailable()
end

local function parseCrypticPrompt(line)
  local sails, sailhp, hullhp, winddir, windspeed, heading, speed, sea, rest =
    line:match("^=%s*S([^@,]+)@h([^,]+),H([^,]+),W<%-([A-Z]+)@(%d+)kts,C/S%->([A-Z]+)@(%d+),([IVXLCDM]+)(.*)$")
  if not sails then
    return false
  end

  rest = rest or ""
  local flags = rest:match("%[([^%]]+)%]") or ""
  local seaState = sailing.seaStates[sea]

  applyPrompt({
    promptMode = "cryptic",
    rawPrompt = line,
    sails = normalizeSailSetting(sails),
    sailHealth = parseHealth(sailhp),
    hullHealth = parseHealth(hullhp),
    windDirection = winddir,
    windSpeed = tonumber(windspeed),
    heading = heading,
    speed = tonumber(speed),
    seaCode = sea,
    seaCondition = seaState and seaState.name or sea,
    seaBand = seaState and seaState.band or nil,
    isRowing = flags:match("Rw") ~= nil,
    hasSailBoost = flags:match("Sl") ~= nil,
    turningTo = rest:match("T%->(%w+)")
  })
  return true
end

local function parseBattlePrompt(line)
  local sails, sailhp, hullhp, winddir, windspeed, heading, speed, sea, rest =
    line:match("^=%s*Sl%s+([^%s]+)%s+%-%s+hp%s+([^,]+),Hl:%s*([^,]+),Wd%s+([A-Z]+)@(%d+)kts,Cr/Sp%s+([A-Z]+)@(%d+),Sea%s+([^,]+)(.*)$")
  if not sails then
    return false
  end

  rest = rest or ""
  applyPrompt({
    promptMode = "battle",
    rawPrompt = line,
    sails = normalizeSailSetting(sails),
    sailHealth = parseHealth(sailhp),
    hullHealth = parseHealth(hullhp),
    windDirection = winddir,
    windSpeed = tonumber(windspeed),
    heading = heading,
    speed = tonumber(speed),
    seaCondition = trim(sea),
    seaBand = seaBands[trim(sea):lower()],
    isRowing = rest:match("Row") ~= nil,
    hasSailBoost = rest:match("Sail") ~= nil,
    turningTo = rest:match("Turn%->(%w+)")
  })
  return true
end

local function parseNormalPrompt(line)
  local sails, hullhp, winddir, windspeed, heading, speed, sea, rest =
    line:match("^=%s*%[Sail%s+([^%]]+)%]%s+%[Hull([^%]]*)%]%s+%[Wind:%s*([A-Z]+)@(%d+)%s*kts%]%s+%[Crs/Spd:%s*([A-Z]+)@(%d+)%]%s+%[Seas:%s*([^%]]+)%](.*)$")
  if not sails then
    return false
  end

  rest = rest or ""
  applyPrompt({
    promptMode = "normal",
    rawPrompt = line,
    sails = normalizeSailSetting(sails),
    hullHealth = parseHealth(hullhp == "" and "full" or hullhp),
    windDirection = winddir,
    windSpeed = tonumber(windspeed),
    heading = heading,
    speed = tonumber(speed),
    seaCondition = trim(sea),
    seaBand = seaBands[trim(sea):lower()],
    isRowing = rest:match("Rowing") ~= nil,
    hasSailBoost = rest:match("Sailing") ~= nil,
    turningTo = rest:match("%[Turning%s*%-%>%s*(%w+)%]")
  })
  return true
end

function sailing.allStop()
  ship.currentSpeed = "stopped"
  poopDeck.safeSend("say All stop!")
end

function sailing.anchor(action)
  if action == "r" or action == "raise" then
    ship.anchored = false
    poopDeck.safeSend("say weigh anchor!")
  elseif action == "l" or action == "lower" or action == "drop" then
    ship.anchored = true
    poopDeck.safeSend("say drop the anchor!")
  else
    poopDeck.output.bad("Use ranc or lanc")
  end
end

function sailing.castOff()
  ship.isDocked = false
  poopDeck.safeSend("say castoff!")
end

function sailing.chop()
  poopDeck.safeSend("chop tether")
end

function sailing.clearRigging()
  poopDeck.safeSendAll({
    "queue add freestand climb rigging",
    "queue add freestand clear rigging"
  })
end

function sailing.onRiggingCleared()
  ship.riggings = "Clear"
  poopDeck.refreshGui()
  poopDeck.safeSend("queue add freestand climb rigging down")
end

function sailing.onRiggingTangled(rawLine)
  local line = trim(rawLine)
  if line == "" then
    return
  end

  ship.riggings = "Tangled"
  poopDeck.refreshGui()
end

function sailing.commScreen(mode)
  if mode == "on" then
    ship.commScreenRaised = true
    poopDeck.safeSend("ship commscreen raise")
  elseif mode == "off" then
    ship.commScreenRaised = false
    poopDeck.safeSend("ship commscreen lower")
  else
    poopDeck.output.bad("Use scomm on or scomm off")
  end
end

function sailing.dock(direction)
  if not direction or direction == "" then
    poopDeck.output.bad("Dock direction required")
    return
  end
  ship.isDocked = true
  ship.dockedDirection = direction
  poopDeck.safeSend("ship dock " .. direction .. " confirm")
end

function sailing.douse(target)
  local commands = {
    r = {"queue add freestand fill bucket with water", "queue add freestand douse room"},
    m = {"queue add freestand fill bucket with water", "queue add freestand douse me"},
    s = {"queue add freestand fill bucket with water", "queue add freestand douse sails"}
  }
  if not commands[target] then
    poopDeck.output.bad("Use dour, doum, or dous")
    return
  end
  poopDeck.safeSendAll(commands[target])
end

function sailing.maintain(target)
  local commands = {
    h = {"queue add freestand maintain hull", "hull"},
    s = {"queue add freestand maintain sails", "sails"},
    n = {"queue add freestand maintain none", nil}
  }
  local item = commands[target]
  if not item then
    poopDeck.output.bad("Use mainh, mains, or mainn")
    return
  end
  poopDeck.config.set("maintainTarget", item[2])
  poopDeck.config.save()
  poopDeck.safeSend(item[1])
end

function sailing.plank(action)
  if action == "r" or action == "raise" then
    ship.plankLowered = false
    poopDeck.safeSend("say raise the plank!")
  elseif action == "l" or action == "lower" then
    ship.plankLowered = true
    poopDeck.safeSend("say lower the plank!")
  else
    poopDeck.output.bad("Use rpla or lpla")
  end
end

function sailing.rainstorm()
  poopDeck.safeSend("invoke rainstorm")
end

function sailing.relaxOars()
  ship.isRowing = false
  poopDeck.safeSend("say stop rowing.")
end

function sailing.row()
  ship.isRowing = true
  poopDeck.safeSend("say row!")
end

function sailing.setSpeed(speed)
  if not speed or speed == "" then
    poopDeck.output.bad("Speed required")
    return
  end
  speed = tostring(speed):lower()
  if sailing.namedSpeeds[speed] then
    ship.currentSpeed = speed
    poopDeck.safeSend(sailing.namedSpeeds[speed])
    return
  end
  local numeric = tonumber(speed)
  if numeric and numeric >= 0 and numeric <= 100 then
    ship.currentSpeed = speed
    poopDeck.safeSend("ship sails set " .. speed)
    return
  end
  poopDeck.output.bad("Speed must be full, furl, relax, strike, or 0-100")
end

function sailing.repairAll()
  ship.repairingSails = true
  ship.repairingHull = true
  poopDeck.refreshGui()
  poopDeck.safeSend("ship repair all")
end

function sailing.rescue()
  poopDeck.safeSendAll({"get token from pack", "ship rescue me"})
end

function sailing.shipWarning(mode)
  if mode == "on" or mode == "off" then
    ship.warningEnabled = mode == "on"
    poopDeck.safeSend("shipwarning " .. mode)
  else
    poopDeck.output.bad("Use shw on or shw off")
  end
end

function sailing.turn(heading)
  if not heading then
    poopDeck.output.bad("Heading required")
    return
  end
  local direction = sailing.directions[heading:lower()]
  if not direction then
    poopDeck.output.bad("Unknown heading: " .. tostring(heading))
    return
  end
  ship.currentHeading = direction
  poopDeck.safeSend("say Bring her to the " .. direction .. "!")
end

function sailing.wavecall(direction, distance)
  if not direction or not distance then
    poopDeck.output.bad("Wavecall requires direction and distance")
    return
  end
  poopDeck.safeSend("invoke wavecall " .. direction .. " " .. distance)
end

function sailing.windboost()
  poopDeck.safeSend("invoke windboost")
end

function sailing.onBalanceRecovered()
  ship.hasBalance = true
end

function sailing.parsePrompt(prompt)
  if not prompt then
    return
  end

  if type(prompt) == "table" then
    if prompt[1] then
      prompt = prompt[1]
    else
      applyPrompt({
        promptMode = "battle",
        sails = normalizeSailSetting(prompt.sails),
        sailHealth = parseHealth(prompt.sailhp),
        hullHealth = parseHealth(prompt.hullhp),
        windDirection = prompt.winddir,
        windSpeed = tonumber(prompt.windspeed),
        heading = prompt.heading,
        speed = tonumber(prompt.speed),
        seaCondition = prompt.sea,
        isRowing = prompt.row ~= nil,
        hasSailBoost = prompt.sail ~= nil,
        turningTo = prompt.turn
      })
      return
    end
  end

  local line = tostring(prompt):gsub("%[poopDeck%].*$", "")
  line = trim(line)

  if line == "" then
    return
  end

  if parseCrypticPrompt(line) then
    return
  end
  if parseBattlePrompt(line) then
    return
  end
  parseNormalPrompt(line)
end

function sailing.parseShipInfoLine(rawLine)
  local line = trim(rawLine)
  if line == "" then
    return
  end

  local value = line:match("^Ship Info for:%s*(.+)$")
  if value then
    ship.infoSource = "ship info"
    ship.name = trim(value)
    poopDeck.refreshGui()
    return
  end

  local key, text = line:match("^([^:]+):%s*(.-)%s*$")
  if not key then
    key, text = line:match("^(.+%?)%s+(.-)%s*$")
  end
  if not key then
    return
  end

  key = trim(key)
  text = trim(text)
  ship.isAboard = true
  ship.infoSource = "ship info"

  if key == "Ship ID#" then
    ship.id = tonumber(text) or text
  elseif key == "Ship alias" then
    ship.alias = text
  elseif key == "Ship type" then
    ship.type = text
  elseif key == "Ship flag" then
    ship.flag = text
  elseif key == "Ship Vis" then
    ship.visibility = text
  elseif key == "Owned by" then
    ship.owner = text
  elseif key == "Captained by" then
    ship.captain = text
  elseif key == "Seaworthiness" then
    ship.seaworthiness = text:gsub("%.$", "")
  elseif key == "Sails health" then
    local current, maximum, percent = text:match("^(%d+)/(%d+):%s*(%d+)%%%.?$")
    ship.sailHealthCurrent = tonumber(current) or ship.sailHealthCurrent
    ship.sailHealthMax = tonumber(maximum) or ship.sailHealthMax
    ship.sailHealth = tonumber(percent) or ship.sailHealth
  elseif key == "Hull health" then
    local current, maximum, percent = text:match("^(%d+)/(%d+):%s*(%d+)%%%.?$")
    ship.hullHealthCurrent = tonumber(current) or ship.hullHealthCurrent
    ship.hullHealthMax = tonumber(maximum) or ship.hullHealthMax
    ship.hullHealth = tonumber(percent) or ship.hullHealth
  elseif key == "Leaking Now?" then
    ship.isLeaking = yesNo(text)
  elseif key == "Fires" then
    ship.hasFires = yesNo(text)
  elseif key == "Riggings" then
    ship.riggings = text
  elseif key == "Course" then
    ship.currentHeading = directionAbbrev(text)
  elseif key == "Sailing?" then
    ship.hasSailBoost = yesNo(text)
  elseif key == "Rowing?" then
    ship.isRowing = yesNo(text)
  elseif key == "In harbour?" then
    ship.inHarbour = yesNo(text)
  elseif key == "Locale" then
    ship.locale = text
  elseif key == "In Ship Arena?" then
    ship.inShipArena = yesNo(text)
  elseif key == "Anchored?" then
    ship.anchored = yesNo(text)
  elseif key == "Gangplank" then
    ship.gangplank = text
  elseif key == "Crewmates" then
    ship.crewmates = tonumber(text) or ship.crewmates
  elseif key == "Rope Ladders" then
    ship.ropeLadders = text
  elseif key == "Wind from the" then
    local winddir, windspeed = text:match("^(.+) at the rate of (%d+) knots%.?$")
    ship.windDirection = winddir and directionAbbrev(winddir) or ship.windDirection
    ship.windSpeed = tonumber(windspeed) or ship.windSpeed
  elseif key == "Manoeuvres" then
    ship.manoeuvres = text
  elseif key == "Diving Bell" then
    ship.divingBell = text
  elseif key == "Buoy" then
    ship.buoy = yesNo(text)
  elseif key == "Cargo Float" then
    ship.cargoFloat = yesNo(text)
  elseif key == "Warn of low wages in strongbox" then
    ship.lowWageWarning = text
  elseif key == "Notify of changes in captaincy" then
    ship.notifyCaptaincyChanges = text
  end

  showGuiIfAvailable()
end

function sailing.parseRepairLine(rawLine)
  local line = trim(rawLine)
  if line == "" then
    return
  end

  if line:match("^You order your crew to begin repairing the ship's hull%.$") then
    ship.repairingHull = true
  elseif line:match("^You order your crew to begin repairing the ship's sails%.$") then
    ship.repairingSails = true
  elseif line:match("^Your crew begins to mend your sails and repair your hull%.$") then
    ship.repairingSails = true
    ship.repairingHull = true
  elseif line:match("^Your crew begins to mend the sails%.") then
    ship.repairingSails = true
  elseif line:match("^It was already busy repairing your hull%.$") then
    ship.repairingHull = true
  elseif line:match("^Your crew ceases all repair activity%.$") then
    ship.repairingSails = false
    ship.repairingHull = false
  else
    local sailHealth = line:match("^Sail repair continues%. The sails are now at (%d+)%% health%.$")
    if sailHealth then
      ship.repairingSails = true
      ship.sailHealth = tonumber(sailHealth) or ship.sailHealth
    end

    local hullHealth = line:match("^Hull repair continues%. The hull is now at (%d+)%% health%.$")
    if hullHealth then
      ship.repairingHull = true
      ship.hullHealth = tonumber(hullHealth) or ship.hullHealth
    end

    if line:match("^The sails are now fully repaired!$") then
      ship.repairingSails = false
      ship.sailHealth = 100
    elseif line:match("^The hull is now fully repaired!$") then
      ship.repairingHull = false
      ship.hullHealth = 100
    elseif not sailHealth and not hullHealth then
      return
    end
  end

  poopDeck.refreshGui()
end

function sailing.onShipFire(rawLine)
  local line = trim(rawLine)
  if line == "" then
    return
  end

  ship.hasFires = true
  poopDeck.refreshGui()
end

function sailing.onBoarded()
  ship.isAboard = true
  if poopDeck.gui and type(poopDeck.gui.show) == "function" then
    poopDeck.gui.show()
  else
    poopDeck.refreshGui()
  end
end

function sailing.onDisembarked()
  ship.isAboard = false
  ship.isRowing = false
  ship.hasSailBoost = false
  ship.actualSpeed = nil
  ship.turningTo = nil
  if poopDeck.gui and type(poopDeck.gui.hide) == "function" then
    poopDeck.gui.hide()
  else
    poopDeck.refreshGui()
  end
end
