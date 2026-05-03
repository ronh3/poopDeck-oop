local sent = {}
local enabled = {}
local timers = {}
local killedTimers = {}

function send(command)
  table.insert(sent, command)
end

function echo(_) end
function cecho(_) end
function deleteLine() end

function tempTimer(_, callback)
  local id = "timer" .. tostring(#timers + 1)
  table.insert(timers, {id = id, callback = callback})
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

function registerAnonymousEventHandler(_, _) end

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
  "src/scripts/60_poopDeck_Help.lua"
}

for _, path in ipairs(scripts) do
  assert(loadfile(path))()
end

local function reset()
  sent = {}
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

reset()
poopDeck.sailing.turn("n")
assertSent({"say Bring her to the north!"})

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

reset()
poopDeck.fishing.castAgain()
assertSent({"queue addclearfull free fcast"})

reset()
poopDeck.fishing.castMedium()
assertSent({"queue addclearfull free cast line medium"})

reset()
resetTimers()
poopDeck.fishing.jerk()
assertSent({"jerk pole"})
assert(#timers == 2, "large strike should schedule two follow-up jerk timers")
reset()
poopDeck.fishing.reel()
assertSent({"queue addclearfull free reel line"})
runTimers()
assertSent({"queue addclearfull free reel line"})

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

reset()
poopDeck.combat.onOutOfRange()
assertSent({"curing on"})
assert(enabled["Ship Moved Lets Try Again"] ~= true, "range retry should not enable in manual mode")

reset()
poopDeck.combat.setAutoMode("on")
poopDeck.combat.setWeapon("ballista")
poopDeck.combat.onOutOfRange()
assertSent({"curing on"})
assert(enabled["Ship Moved Lets Try Again"] == true, "range retry should enable in auto mode")

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
