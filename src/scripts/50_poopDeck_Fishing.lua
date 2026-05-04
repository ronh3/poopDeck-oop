poopDeck = poopDeck or {}
poopDeck.fishing = poopDeck.fishing or {}
poopDeck.state = poopDeck.state or {}
poopDeck.state.fishing = poopDeck.state.fishing or {}

local fishing = poopDeck.fishing
local state = poopDeck.state.fishing

state.status = state.status or "Idle"
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

function fishing.teaseSoon()
  state.status = "Teasing"
  poopDeck.refreshGui()
  tempTimer(2, function() send("tease line") end)
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
  state.size = size
  if deleteLine then
    deleteLine()
  end
  poopDeck.output.good("Hooked " .. tostring(size) .. " fish")
  poopDeck.refreshGui()
end

function fishing.castAgain()
  state.status = "Casting"
  send("queue addclearfull free fcast")
  poopDeck.refreshGui()
end

function fishing.castMedium()
  state.status = "Casting"
  send("queue addclearfull free cast line medium")
  poopDeck.refreshGui()
end

function fishing.onCastSuccess(feet)
  state.status = "Waiting"
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
  state.hooked = false
  state.size = nil
  state.lineFeetLeft = nil
  poopDeck.refreshGui()
end

function fishing.onCaught(fishType, pounds, ounces)
  state.status = "Landed"
  state.caughtFishType = normalizeSize(fishType)
  state.caughtPounds = tonumber(pounds)
  state.caughtOunces = tonumber(ounces)
  state.hooked = false
  state.size = nil
  state.lineFeetLeft = nil
  if poopDeck.stats and type(poopDeck.stats.recordFishCatch) == "function" then
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
