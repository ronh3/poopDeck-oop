poopDeck = poopDeck or {}
poopDeck.fishing = poopDeck.fishing or {}
poopDeck.state = poopDeck.state or {}
poopDeck.state.fishing = poopDeck.state.fishing or {}

local fishing = poopDeck.fishing
local state = poopDeck.state.fishing

local function clearJerkTimers()
  for _, timer in ipairs(state.jerkTimers or {}) do
    if killTimer then
      killTimer(timer)
    end
  end
  state.jerkTimers = {}
end

function fishing.teaseSoon()
  tempTimer(2, function() send("tease line") end)
end

function fishing.jerk()
  clearJerkTimers()
  send("jerk pole")
  state.jerkTimers = {
    tempTimer(1.67, function() send("jerk pole") end),
    tempTimer(3.34, function() send("jerk pole") end)
  }
end

function fishing.reel()
  clearJerkTimers()
  state.hooked = true
  send("queue addclearfull free reel line")
  if deleteLine then
    deleteLine()
  end
end

function fishing.showSize(size)
  clearJerkTimers()
  state.hooked = true
  if deleteLine then
    deleteLine()
  end
  poopDeck.output.good("Hooked " .. tostring(size) .. " fish")
end

function fishing.castAgain()
  send("queue addclearfull free fcast")
end

function fishing.castMedium()
  send("queue addclearfull free cast line medium")
end
