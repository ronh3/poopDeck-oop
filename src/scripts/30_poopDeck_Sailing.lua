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
  poopDeck.safeSend("queue add freestand climb rigging down")
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

function sailing.parsePrompt(matches)
  if not matches then
    return
  end
  ship.currentSpeed = matches.sails or ship.currentSpeed
  ship.sailHealth = tonumber(matches.sailhp) or ship.sailHealth
  ship.hullHealth = tonumber(matches.hullhp) or ship.hullHealth
  ship.windDirection = matches.winddir or ship.windDirection
  ship.windSpeed = tonumber(matches.windspeed) or ship.windSpeed
  ship.currentHeading = matches.heading or ship.currentHeading
  ship.actualSpeed = tonumber(matches.speed) or ship.actualSpeed
  ship.seaCondition = matches.sea or ship.seaCondition
  ship.isRowing = matches.row ~= nil
  ship.hasSailBoost = matches.sail ~= nil
  ship.turningTo = matches.turn
end
