poopDeck = poopDeck or {}
poopDeck.combat = poopDeck.combat or {}
poopDeck.state = poopDeck.state or {}
poopDeck.state.combat = poopDeck.state.combat or {}

local combat = poopDeck.combat
local state = poopDeck.state.combat

local function refreshGui()
  poopDeck.refreshGui()
end

combat.reloadTime = 4
combat.fiveMinuteWarning = 900
combat.oneMinuteWarning = 1140
combat.nextMonsterWarning = 1200

combat.monsters = {
  ["a legendary leviathan"] = 60,
  ["a hulking oceanic cyclops"] = 60,
  ["a towering oceanic hydra"] = 60,
  ["a sea hag"] = 40,
  ["a monstrous ketea"] = 40,
  ["a monstrous picaroon"] = 40,
  ["an unmarked warship"] = 40,
  ["a red-sailed Kashari raider"] = 30,
  ["a furious sea dragon"] = 30,
  ["a pirate ship"] = 30,
  ["a trio of raging sea serpents"] = 30,
  ["a raging shraymor"] = 25,
  ["a mass of sargassum"] = 25,
  ["a gargantuan megalodon"] = 25,
  ["a gargantuan angler fish"] = 25,
  ["a mudback septacean"] = 20,
  ["a flying sheilei"] = 20,
  ["a foam-wreathed sea serpent"] = 20,
  ["a red-faced septacean"] = 20
}

state.mode = state.mode or "manual"
state.active = state.active or false
state.firePending = state.firePending or false
state.firing = state.firing or false
state.outOfRange = state.outOfRange or false
state.shots = state.shots or 0
state.firedSpider = state.firedSpider or false
state.session = state.session or 0

function combat.startSession()
  state.active = true
  state.session = (state.session or 0) + 1
  refreshGui()
  return state.session
end

function combat.stopSession()
  state.active = false
  state.firePending = false
  state.firing = false
  state.outOfRange = false
  state.currentMonster = nil
  state.shots = 0
  state.session = (state.session or 0) + 1
  disableTrigger("Ship Moved Lets Try Again")
  combat.toggleCuring(true)
  refreshGui()
  return state.session
end

local function weaponCommands(weapon)
  if weapon == "ballista" then
    return {"maintain hull", "load ballista with dart", "fire ballista at seamonster"}
  end
  if weapon == "thrower" then
    return {"maintain hull", "load thrower with disc", "fire thrower at seamonster"}
  end
  if weapon == "onager" then
    if state.firedSpider then
      state.firedSpider = false
      return {"maintain hull", "load onager with starshot", "fire onager at seamonster"}
    end
    state.firedSpider = true
    return {"maintain hull", "load onager with spidershot", "fire onager at seamonster"}
  end
  return nil
end

local function ammoCommands(ammo)
  local commands = {
    b = {"maintain hull", "load ballista with dart", "fire ballista at seamonster"},
    bf = {"maintain hull", "load ballista with flare", "fire ballista at seamonster"},
    f = {"maintain hull", "load ballista with flare", "fire ballista at seamonster"},
    sp = {"maintain hull", "load onager with spidershot", "fire onager at seamonster"},
    c = {"maintain hull", "load onager with chainshot", "fire onager at seamonster"},
    st = {"maintain hull", "load onager with starshot", "fire onager at seamonster"},
    d = {"maintain hull", "load thrower with disc", "fire thrower at seamonster"}
  }
  if ammo == "o" then
    return weaponCommands("onager")
  end
  return commands[ammo]
end

function combat.toggleCuring(enable)
  if enable then
    poopDeck.safeSend("curing on")
  else
    poopDeck.safeSend("curing off")
  end
end

function combat.healthAllowsFire()
  local vitals = gmcp and gmcp.Char and gmcp.Char.Vitals
  if not vitals then
    return true
  end
  local hp = tonumber(vitals.hp)
  local maxhp = tonumber(vitals.maxhp)
  if not hp or not maxhp or maxhp <= 0 then
    return true
  end
  local threshold = tonumber(poopDeck.config.get("sipHealthPercent")) or 75
  return (hp / maxhp * 100) >= threshold
end

function combat.setAutoMode(mode)
  local enabled = mode == true or mode == "on"
  state.mode = enabled and "automatic" or "manual"
  poopDeck.config.setAutoFire(enabled)
  if enabled then
    poopDeck.output.good("AUTO FIRE ON")
  else
    combat.stopSession()
    poopDeck.output.warn("AUTO FIRE OFF")
  end
  refreshGui()
end

function combat.stop()
  combat.stopSession()
  poopDeck.output.warn("Seamonster combat stopped")
end

function combat.setWeapon(weapon)
  if poopDeck.config.setWeapon(weapon) then
    state.selectedWeapon = weapon
    poopDeck.output.good("Weapon set to " .. weapon)
    refreshGui()
  end
end

function combat.setHealth(value)
  poopDeck.config.setHealthPercent(value)
end

function combat.setMaintain(target)
  local map = {h = "hull", hull = "hull", s = "sails", sails = "sails", n = nil, none = nil}
  local value = map[target]
  if target ~= "n" and target ~= "none" and not value then
    poopDeck.output.bad("Maintain target must be h, s, or n")
    return
  end
  poopDeck.config.set("maintainTarget", value)
  poopDeck.config.save()
  poopDeck.output.good(value and ("Maintaining " .. value) or "Maintaining none")
end

function combat.beginFire(commands)
  if state.firePending or state.firing then
    return
  end
  if not commands then
    poopDeck.output.bad("No weapon selected")
    combat.toggleCuring(true)
    return
  end
  if not combat.healthAllowsFire() then
    combat.toggleCuring(true)
    poopDeck.output.bad("NEED TO HEAL - HOLD FIRE")
    return
  end
  if not state.active then
    combat.startSession()
  end
  state.firePending = true
  state.firing = false
  state.outOfRange = false
  combat.toggleCuring(false)
  poopDeck.safeSendAll(commands)
  refreshGui()
end

function combat.autoFire(session)
  if session and session ~= state.session then
    return
  end
  if not state.active then
    return
  end
  local weapon = state.selectedWeapon or poopDeck.config.get("selectedWeapon")
  combat.beginFire(weaponCommands(weapon))
end

function combat.manualFire(ammo)
  combat.beginFire(ammoCommands(ammo))
end

function combat.onFiringStarted()
  state.firePending = false
  state.firing = true
  state.outOfRange = false
  refreshGui()
end

function combat.onWeaponFired()
  combat.toggleCuring(true)
  state.firePending = false
  state.firing = false
  state.outOfRange = false
  refreshGui()
  if state.mode == "automatic" then
    local session = state.session
    tempTimer(combat.reloadTime, function() combat.autoFire(session) end)
  else
    tempTimer(combat.reloadTime, function() poopDeck.output.good("READY TO FIRE") end)
  end
end

function combat.onOutOfRange()
  combat.toggleCuring(true)
  if not state.active then
    state.firePending = false
    state.firing = false
    state.outOfRange = false
    disableTrigger("Ship Moved Lets Try Again")
    refreshGui()
    return
  end
  state.firePending = false
  state.firing = false
  state.outOfRange = true
  if state.mode == "automatic" then
    enableTrigger("Ship Moved Lets Try Again")
  end
  poopDeck.output.bad("OUT OF RANGE")
  refreshGui()
end

function combat.onShipMoved()
  if state.mode == "automatic" and state.outOfRange then
    disableTrigger("Ship Moved Lets Try Again")
    state.outOfRange = false
    local session = state.session
    tempTimer(0.5, function() combat.autoFire(session) end)
    refreshGui()
  end
end

function combat.onInterrupted()
  combat.toggleCuring(true)
  state.firePending = false
  state.firing = false
  refreshGui()
  if state.mode == "automatic" then
    poopDeck.output.bad("SHOT INTERRUPTED - RETRYING")
    local session = state.session
    tempTimer(combat.reloadTime, function() combat.autoFire(session) end)
  else
    poopDeck.output.bad("SHOT INTERRUPTED")
  end
end

function combat.onMonsterSurfaced()
  local session = combat.startSession()
  state.shots = 0
  state.currentMonster = nil
  refreshGui()
  poopDeck.output.bad("Seamonster surfaced")
  if state.mode == "automatic" then
    combat.autoFire(session)
  end
  tempTimer(combat.fiveMinuteWarning, function() poopDeck.output.good("Monster in 5 minutes") end)
  tempTimer(combat.oneMinuteWarning, function() poopDeck.output.good("Monster in 1 minute") end)
  tempTimer(combat.nextMonsterWarning, function() poopDeck.output.bad("Reel in, it is monster time") end)
end

function combat.onMonsterKilled(monster)
  if poopDeck.stats and type(poopDeck.stats.recordSeamonsterKill) == "function" then
    poopDeck.stats.recordSeamonsterKill(monster or state.currentMonster)
  end
  combat.stopSession()
  poopDeck.output.good((monster or "Seamonster") .. " defeated")
end

function combat.onMonsterKilledExternal()
  combat.stopSession()
  poopDeck.output.warn("Monster killed by others")
end

function combat.onShotHit(monster)
  state.currentMonster = monster or state.currentMonster
  state.shots = (state.shots or 0) + 1
  refreshGui()
  local total = combat.monsters[state.currentMonster or ""] or 0
  if total > 0 then
    poopDeck.output.shot(state.shots .. " shots taken, " .. math.max(0, total - state.shots) .. " remain")
  else
    poopDeck.output.shot(state.shots .. " shots taken")
  end
end

function combat.onStarshot()
  poopDeck.output.good("Seamonster attack weakened")
end

function combat.onSpidershot()
  poopDeck.output.good("Seamonster attack slowed")
end

function combat.promptOverlay()
  if state.firing then
    poopDeck.output.line("FIRING", "green")
  end
  if state.outOfRange then
    poopDeck.output.line("OUT OF RANGE", "red")
  end
end
