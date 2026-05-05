poopDeck = poopDeck or {}
poopDeck.fishing = poopDeck.fishing or {}
poopDeck.state = poopDeck.state or {}
poopDeck.state.fishing = poopDeck.state.fishing or {}

local fishing = poopDeck.fishing
local state = poopDeck.state.fishing

state.status = state.status or "Idle"
fishing.teaseCommandDelay = 2
fishing.teaseIdleDelay = 4.1
fishing.jerkRetryDelay = 1.9
fishing.jerkRetryCount = 2

local function clearJerkTimers()
  for _, timer in ipairs(state.jerkTimers or {}) do
    if killTimer then
      killTimer(timer)
    end
  end
  state.jerkTimers = {}
end

local function normalizeSize(size)
  return tostring(size or ""):gsub("^%s*[Aa][Nn]?%s+", ""):gsub("^%s*(.-)%s*$", "%1")
end

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function stripQueuePrefix(command)
  local value = trim(command)
  value = value:gsub("^queue%s+addclearfull%s+free%s+", "")
  value = value:gsub("^queue%s+add%s+free%s+", "")
  return trim(value)
end

local function baitGetCommand()
  local configured = poopDeck.config
    and type(poopDeck.config.get) == "function"
    and poopDeck.config.get("baitCommand")
  configured = stripQueuePrefix(configured)
  if configured == "" or configured:lower() == "fcast" then
    configured = "get bass from tank"
  end
  return configured
end

local function castDistance()
  local configured = poopDeck.config
    and type(poopDeck.config.get) == "function"
    and poopDeck.config.get("castDistance")
  configured = trim(configured):lower()
  if configured == "" then
    configured = "medium"
  end
  return configured
end

local function baitItemFromCommand(command)
  local value = stripQueuePrefix(command)
  local item = value:match("^[Gg][Ee][Tt]%s+(.+)%s+[Ff][Rr][Oo][Mm]%s+.+$")
    or value:match("^[Tt][Aa][Kk][Ee]%s+(.+)%s+[Ff][Rr][Oo][Mm]%s+.+$")
    or value:match("^[Gg][Ee][Tt]%s+(.+)$")
    or value:match("^[Tt][Aa][Kk][Ee]%s+(.+)$")
  return trim(item)
end

local function baitSequence()
  local getCommand = baitGetCommand()
  local baitItem = baitItemFromCommand(getCommand)
  if baitItem == "" then
    baitItem = "bait"
  end

  return {
    "queue addclearfull free " .. getCommand,
    "queue add free bait hook with " .. baitItem,
    "queue add free cast line " .. castDistance()
  }
end

function fishing.teaseSoon()
  state.teaseSequence = (state.teaseSequence or 0) + 1
  local sequence = state.teaseSequence
  state.status = "Teasing"
  state.lastAction = "tease"
  poopDeck.refreshGui()
  tempTimer(fishing.teaseCommandDelay, function()
    send("tease line")
  end)
  tempTimer(fishing.teaseIdleDelay, function()
    if state.teaseSequence == sequence and state.status == "Teasing" then
      state.status = "Idle"
      if state.lastAction == "tease" then
        state.lastAction = nil
      end
      poopDeck.refreshGui()
    end
  end)
end

function fishing.teaseNow()
  state.teaseSequence = (state.teaseSequence or 0) + 1
  local sequence = state.teaseSequence
  state.status = "Teasing"
  state.lastAction = "tease"
  send("tease line")
  poopDeck.refreshGui()
  local idleDelay = math.floor((fishing.teaseIdleDelay - fishing.teaseCommandDelay) * 10 + 0.5) / 10
  tempTimer(math.max(0.1, idleDelay), function()
    if state.teaseSequence == sequence and state.status == "Teasing" then
      state.status = "Idle"
      if state.lastAction == "tease" then
        state.lastAction = nil
      end
      poopDeck.refreshGui()
    end
  end)
end

function fishing.jerk()
  clearJerkTimers()
  state.status = "Hooking"
  send("jerk pole")
  state.jerkTimers = {}
  for index = 1, fishing.jerkRetryCount do
    state.jerkTimers[#state.jerkTimers + 1] = tempTimer(fishing.jerkRetryDelay * index, function()
      send("jerk pole")
    end)
  end
  poopDeck.refreshGui()
end

function fishing.reel()
  clearJerkTimers()
  state.hooked = true
  state.status = "Reeling"
  state.lastAction = "reel"
  send("queue addclearfull free reel line")
  if deleteLine then
    deleteLine()
  end
  poopDeck.refreshGui()
end

function fishing.showSize(size)
  clearJerkTimers()
  size = normalizeSize(size)
  state.hooked = true
  state.status = "Hooked"
  state.lastAction = nil
  state.size = size
  if deleteLine then
    deleteLine()
  end
  poopDeck.output.good("Hooked " .. tostring(size) .. " fish")
  poopDeck.refreshGui()
end

function fishing.castAgain()
  state.status = "Casting"
  state.lastAction = "bait"
  state.castQueuedWithBait = true
  poopDeck.safeSendAll(baitSequence())
  poopDeck.refreshGui()
end

function fishing.castMedium()
  state.status = "Casting"
  state.lastAction = "cast"
  send("queue addclearfull free cast line " .. castDistance())
  poopDeck.refreshGui()
end

function fishing.idle()
  clearJerkTimers()
  state.status = "Idle"
  state.lastAction = "idle"
  state.castQueuedWithBait = false
  state.hooked = false
  state.size = nil
  state.lineFeetLeft = nil
  poopDeck.refreshGui()
end

function fishing.onBaited()
  if state.castQueuedWithBait then
    state.castQueuedWithBait = false
    state.status = "Casting"
    state.lastAction = "bait"
    poopDeck.refreshGui()
    return
  end

  fishing.castMedium()
end

function fishing.onCastSuccess(feet)
  state.castQueuedWithBait = false
  state.status = "Waiting"
  state.lastAction = nil
  state.hooked = false
  state.size = nil
  state.lineFeetLeft = tonumber(feet) or state.lineFeetLeft
  poopDeck.refreshGui()
end

function fishing.parseCastSuccess(rawLine)
  local feet = tostring(rawLine or ""):match("You judge the cast at about (%d+) feet%.?$")
  fishing.onCastSuccess(feet)
end

function fishing.onLineDistance(feet)
  state.status = "Reeling"
  state.hooked = true
  state.lineFeetLeft = tonumber(feet) or state.lineFeetLeft
  poopDeck.refreshGui()
end

function fishing.onLanded()
  clearJerkTimers()
  state.status = "Landed"
  state.lastAction = nil
  state.hooked = false
  state.size = nil
  state.lineFeetLeft = nil
  poopDeck.refreshGui()
end

function fishing.onLost()
  clearJerkTimers()
  state.status = "Lost"
  state.lastAction = nil
  state.hooked = false
  state.size = nil
  state.lineFeetLeft = nil
  poopDeck.refreshGui()
  fishing.castAgain()
end

function fishing.onCaught(fishType, pounds, ounces)
  state.status = "Landed"
  state.lastAction = nil
  state.caughtFishType = normalizeSize(fishType)
  state.caughtPounds = tonumber(pounds)
  state.caughtOunces = tonumber(ounces)
  state.hooked = false
  state.size = nil
  state.lineFeetLeft = nil
  local signature = table.concat({
    tostring(state.caughtFishType or ""),
    tostring(state.caughtPounds or 0),
    tostring(state.caughtOunces or 0)
  }, "|")
  local timestamp = os.time()
  local duplicate = state.lastCaughtSignature == signature
    and state.lastCaughtAt
    and timestamp - state.lastCaughtAt <= 2
  state.lastCaughtSignature = signature
  state.lastCaughtAt = timestamp
  if not duplicate and poopDeck.stats and type(poopDeck.stats.recordFishCatch) == "function" then
    poopDeck.stats.recordFishCatch(state.caughtFishType, state.caughtPounds, state.caughtOunces)
  end
  poopDeck.refreshGui()
end

function fishing.parseCaughtLine(rawLine)
  local line = tostring(rawLine or "")
  local fishType, pounds, ounces = line:match("^With a final tug, you finish reeling in the line and land an? (.-) weighing (%d+) pounds? and (%d+) ounces?!$")
  if fishType then
    fishing.onCaught(fishType, pounds, ounces)
    return
  end

  fishType, pounds, ounces = line:match("^With a final tug, you finish reeling in the line and land an? (.-) weighing (%d+) pounds? and (%d+)$")
  if fishType then
    state.pendingCaughtFish = {
      fishType = fishType,
      pounds = pounds,
      ounces = ounces
    }
    return
  end

  ounces = line:match("^(%d+) ounces?!$")
  if ounces and state.pendingCaughtFish then
    fishing.onCaught(state.pendingCaughtFish.fishType, state.pendingCaughtFish.pounds, ounces)
    state.pendingCaughtFish = nil
  end
end

function fishing.showSettings()
  local command = baitGetCommand()
  poopDeck.output.status("Fishing", {
    "Bait get command: " .. command,
    "Bait item: " .. (baitItemFromCommand(command) ~= "" and baitItemFromCommand(command) or "bait"),
    "Cast distance: " .. castDistance(),
    "poopfish baitcmd <get command> - set bait get command",
    "poopfish castdistance <distance> - set cast distance",
    "poopfish bait - run the configured bait sequence"
  })
end

function fishing.command(args)
  local input = tostring(args or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if input == "" then
    fishing.showSettings()
    return
  end

  local command, rest = input:match("^(%S+)%s*(.-)$")
  command = tostring(command or ""):lower()
  rest = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")

  if command == "bait" then
    fishing.castAgain()
    return
  end

  if command == "baitcmd" or command == "baitcommand" then
    if rest == "" then
      fishing.showSettings()
      return
    end
    poopDeck.config.setBaitCommand(rest)
    return
  end

  if command == "castdistance" or command == "distance" or command == "castdist" then
    if rest == "" then
      fishing.showSettings()
      return
    end
    poopDeck.config.setCastDistance(rest)
    return
  end

  fishing.showSettings()
end
