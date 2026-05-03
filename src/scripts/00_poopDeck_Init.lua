poopDeck = poopDeck or {}

poopDeck.version = "0.0.3"
poopDeck.packageName = "poopDeck"

poopDeck.state = poopDeck.state or {}
poopDeck.state.ship = poopDeck.state.ship or {}
poopDeck.state.combat = poopDeck.state.combat or {}
poopDeck.state.fishing = poopDeck.state.fishing or {}

poopDeck.config = poopDeck.config or {}
poopDeck.output = poopDeck.output or {}
poopDeck.sailing = poopDeck.sailing or {}
poopDeck.combat = poopDeck.combat or {}
poopDeck.fishing = poopDeck.fishing or {}
poopDeck.help = poopDeck.help or {}

function poopDeck.safeSend(command)
  if command and command ~= "" then
    send(command)
  end
end

function poopDeck.safeSendAll(commands)
  if type(commands) ~= "table" then
    return
  end
  for _, command in ipairs(commands) do
    poopDeck.safeSend(command)
  end
end

function poopDeck.boolText(value)
  return value and "yes" or "no"
end

function poopDeck.onLoad()
  if poopDeck.config and poopDeck.config.load then
    poopDeck.config.load()
  end
  if poopDeck.output and poopDeck.output.info then
    poopDeck.output.info("poopDeck " .. poopDeck.version .. " loaded")
  end
end

function poopDeck.onExit()
  if poopDeck.config and poopDeck.config.save then
    poopDeck.config.save()
  end
end

if not poopDeck._coreHandlersRegistered then
  registerAnonymousEventHandler("sysLoadEvent", "poopDeck.onLoad")
  registerAnonymousEventHandler("sysExitEvent", "poopDeck.onExit")
  poopDeck._coreHandlersRegistered = true
end
