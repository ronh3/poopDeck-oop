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

function tempTimer(delay, callback)
  local id = "timer" .. tostring(#timers + 1)
  table.insert(timers, {id = id, delay = delay, callback = callback})
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

local geyserWidget = {}
function geyserWidget:setStyleSheet(style)
  self.style = style
end
function geyserWidget:echo(text)
  self.text = text
end
function geyserWidget:setClickCallback(callback)
  self.callback = callback
end
function geyserWidget:hide()
  self.hidden = true
end
function geyserWidget:show()
  self.hidden = false
  self.shown = true
end
function geyserWidget:close()
  self.closed = true
end

local function newGeyserWidget(_, spec, parent)
  local widget = spec or {}
  widget.parent = parent
  return setmetatable(widget, {__index = geyserWidget})
end

Geyser = {
  UserWindow = {new = newGeyserWidget},
  Container = {new = newGeyserWidget},
  Label = {new = newGeyserWidget}
}

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
  "src/scripts/55_poopDeck_Stats.lua",
  "src/scripts/60_poopDeck_Help.lua",
  "src/scripts/70_poopDeck_GUI.lua"
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

local function assertEqual(actual, expected, label)
  assert(actual == expected, label .. " expected '" .. tostring(expected) .. "', got '" .. tostring(actual) .. "'")
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
poopDeck.sailing.onRiggingTangled("A monstrous ketea sprays a thick rain of venom from its barb, the foul fluid dissolving the rigging into a snarl of shreds and knots, creating a useless tangle of the ropes and sails.")
assertEqual(poopDeck.state.ship.riggings, "Tangled", "rigging tangle line should mark rigging tangled")
reset()
poopDeck.sailing.onRiggingCleared()
assertEqual(poopDeck.state.ship.riggings, "Clear", "rigging clear line should mark rigging clear")
assertSent({"queue add freestand climb rigging down"})

poopDeck.sailing.parsePrompt("= S++@h96,H80,W<-NE@8kts,C/S->E@16,II,[Rw+Sl]")
assertEqual(poopDeck.state.ship.promptMode, "cryptic", "cryptic prompt mode")
assertEqual(poopDeck.state.ship.sailSetting, "Full", "cryptic sail setting")
assertEqual(poopDeck.state.ship.sailHealth, 96, "cryptic sail health")
assertEqual(poopDeck.state.ship.hullHealth, 80, "cryptic hull health")
assertEqual(poopDeck.state.ship.windDirection, "NE", "cryptic wind direction")
assertEqual(poopDeck.state.ship.windSpeed, 8, "cryptic wind speed")
assertEqual(poopDeck.state.ship.currentHeading, "E", "cryptic heading")
assertEqual(poopDeck.state.ship.actualSpeed, 16, "cryptic speed")
assertEqual(poopDeck.state.ship.seaCode, "II", "cryptic sea code")
assertEqual(poopDeck.state.ship.seaCondition, "Smooth", "cryptic sea condition")
assertEqual(poopDeck.state.ship.seaBand, "good", "cryptic sea band")
assertEqual(poopDeck.state.ship.isRowing, true, "cryptic rowing")
assertEqual(poopDeck.state.ship.hasSailBoost, true, "cryptic sailing flag")

poopDeck.sailing.parsePrompt("= S50@h97,H78,W<-NE@8kts,C/S->NE@14,V,[Rw+Sl],T->N")
assertEqual(poopDeck.state.ship.sailSetting, "50", "cryptic numeric sail setting")
assertEqual(poopDeck.state.ship.seaCondition, "Whitecapped", "cryptic reduced sea name")
assertEqual(poopDeck.state.ship.seaBand, "reduced", "cryptic reduced sea band")
assertEqual(poopDeck.state.ship.turningTo, "N", "cryptic turn target")

poopDeck.sailing.parsePrompt("= S50@h97,H78,W<-NE@8kts,C/S->NE@14,IX,[Rw+Sl]")
assertEqual(poopDeck.state.ship.seaCondition, "Raging", "cryptic bad sea name")
assertEqual(poopDeck.state.ship.seaBand, "bad", "cryptic bad sea band")

poopDeck.sailing.parsePrompt("= Sl Full - hp 93%,Hl: 77%,Wd NE@8kts,Cr/Sp E@14,Sea Whitecapped,Row+Sail")
assertEqual(poopDeck.state.ship.promptMode, "battle", "battle prompt mode")
assertEqual(poopDeck.state.ship.sailHealth, 93, "battle sail health")
assertEqual(poopDeck.state.ship.hullHealth, 77, "battle hull health")
assertEqual(poopDeck.state.ship.seaCondition, "Whitecapped", "battle sea condition")

poopDeck.sailing.parsePrompt("= [Sail Full] [Hull] [Wind: NE@8 kts] [Crs/Spd: W@19] [Seas: Smooth] [Rowing+Sailing]")
assertEqual(poopDeck.state.ship.promptMode, "normal", "normal prompt mode")
assertEqual(poopDeck.state.ship.sailSetting, "Full", "normal sail setting")
assertEqual(poopDeck.state.ship.hullHealth, 100, "normal hull health")
assertEqual(poopDeck.state.ship.currentHeading, "W", "normal heading")
assertEqual(poopDeck.state.ship.actualSpeed, 19, "normal speed")

poopDeck.sailing.parseShipInfoLine("Ship Info for: The Obsidian Trident")
poopDeck.sailing.parseShipInfoLine("Ship ID#:      922")
poopDeck.sailing.parseShipInfoLine("Ship alias:    tot")
poopDeck.sailing.parseShipInfoLine("Sails health:  10000/10000: 100%.")
poopDeck.sailing.parseShipInfoLine("Hull health:   5000/5000: 100%.")
poopDeck.sailing.parseShipInfoLine("Course:        north")
poopDeck.sailing.parseShipInfoLine("Sailing?       No.")
poopDeck.sailing.parseShipInfoLine("Rowing?        No.")
poopDeck.sailing.parseShipInfoLine("Fires:         No.")
poopDeck.sailing.parseShipInfoLine("Crewmates:     60")
poopDeck.sailing.parseShipInfoLine("Wind from the: northeast at the rate of 8 knots.")
assertEqual(poopDeck.state.ship.name, "The Obsidian Trident", "ship info name")
assertEqual(poopDeck.state.ship.id, 922, "ship info id")
assertEqual(poopDeck.state.ship.alias, "tot", "ship info alias")
assertEqual(poopDeck.state.ship.sailHealth, 100, "ship info sail health")
assertEqual(poopDeck.state.ship.hullHealth, 100, "ship info hull health")
assertEqual(poopDeck.state.ship.currentHeading, "N", "ship info course")
assertEqual(poopDeck.state.ship.isRowing, false, "ship info rowing")
assertEqual(poopDeck.state.ship.hasSailBoost, false, "ship info sailing")
assertEqual(poopDeck.state.ship.hasFires, false, "ship info fires")
assertEqual(poopDeck.state.ship.crewmates, 60, "ship info crew")
assertEqual(poopDeck.state.ship.windDirection, "NE", "ship info wind direction")
assertEqual(poopDeck.state.ship.windSpeed, 8, "ship info wind speed")
assertEqual(poopDeck.state.ship.isAboard, true, "ship info should mark aboard")
poopDeck.sailing.onShipFire("Burning acid rains down upon the ship, setting fire to all that it touches.")
assertEqual(poopDeck.state.ship.hasFires, true, "fire line should mark ship fires")
poopDeck.sailing.parseShipInfoLine("Fires:         No.")
assertEqual(poopDeck.state.ship.hasFires, false, "ship info should clear fire state")

poopDeck.sailing.parseRepairLine("You order your crew to begin repairing the ship's hull.")
assertEqual(poopDeck.state.ship.repairingHull, true, "hull repair should be active")
assertEqual(poopDeck.state.ship.repairingSails, nil, "sail repair should not be active yet")
poopDeck.sailing.parseRepairLine("Hull repair continues. The hull is now at 90% health.")
assertEqual(poopDeck.state.ship.hullHealth, 90, "repair line should update hull health")
poopDeck.sailing.parseRepairLine("You order your crew to begin repairing the ship's sails.")
assertEqual(poopDeck.state.ship.repairingSails, true, "sail repair should be active")
poopDeck.sailing.parseRepairLine("Your crew ceases all repair activity.")
assertEqual(poopDeck.state.ship.repairingHull, false, "repair none should stop hull repair")
assertEqual(poopDeck.state.ship.repairingSails, false, "repair none should stop sail repair")
poopDeck.sailing.parseRepairLine("Your crew begins to mend your sails and repair your hull.")
assertEqual(poopDeck.state.ship.repairingHull, true, "repair all should start hull repair")
assertEqual(poopDeck.state.ship.repairingSails, true, "repair all should start sail repair")
poopDeck.sailing.parseRepairLine("Sail repair continues. The sails are now at 6% health.")
assertEqual(poopDeck.state.ship.sailHealth, 6, "repair line should update sail health")
poopDeck.sailing.parseRepairLine("The sails are now fully repaired!")
assertEqual(poopDeck.state.ship.sailHealth, 100, "fully repaired sails should set health to 100")
assertEqual(poopDeck.state.ship.repairingSails, false, "fully repaired sails should stop sail repair")

poopDeck.sailing.parsePrompt("= S50@h97,H78,W<-NE@8kts,C/S->NE@14,IX,[Rw+Sl]")
poopDeck.gui.build()
assert(poopDeck.gui.window ~= nil, "gui should create a user window")
assert(poopDeck.gui.labels.header ~= nil, "gui should create header label")
assert(poopDeck.gui.labels.shipLine1 ~= nil, "gui should create ship line")
assert(poopDeck.gui.labels.shipSea ~= nil, "gui should create sea label")
assert(poopDeck.gui.labels.fishingLine2 ~= nil, "gui should create caught fish line")
assert(poopDeck.gui.labels.events ~= nil, "gui should create event log")
assert(poopDeck.gui.labels.header.text:match("Auto:") ~= nil, "gui header should use label colons")
assert(poopDeck.gui.labels.shipLine1.text:match("Course:") ~= nil, "ship course should use label colon")
assert(poopDeck.gui.labels.shipLine1.text:match("Row:") ~= nil, "row should be on course line")
assert(poopDeck.gui.labels.shipLine1.text:match("Sail:") ~= nil, "sail should be on course line")
assert(poopDeck.gui.labels.shipSea.text == "Sea: Raging", "gui should show full sea name")
assert(poopDeck.gui.labels.shipSea.style:match("#ef4444") ~= nil, "gui should color bad seas red")
assert(poopDeck.gui.labels.shipLine2.text:match("Repair: Hull") ~= nil, "gui should show repair status instead of crew")
assert(poopDeck.gui.labels.shipLine2.text:match("Crew") == nil, "gui should not show crew on hull line")
assert(poopDeck.gui.labels.shipLine3.text:match("^Anchor:") ~= nil, "anchor should begin third ship line")
assert(poopDeck.gui.labels.shipLine3.text:match("Fires: No") ~= nil, "fires should be on rigging line")
assert(poopDeck.gui.labels.shipLine3.text:match("Rigging:") ~= nil, "rigging should be on third ship line")
assert(poopDeck.gui.labels.shipLine3.text:match("Row:") == nil, "row should not be on third ship line")
assert(poopDeck.gui.labels.shipLine3.text:match("Sail:") == nil, "sail should not be on third ship line")
assert(poopDeck.gui.labels.stopButton == nil, "gui should not create a stop button")
assert(poopDeck.gui.visible == true, "gui should show when already aboard")
poopDeck.sailing.onDisembarked()
assertEqual(poopDeck.state.ship.isAboard, false, "disembark should mark off ship")
assert(poopDeck.gui.visible == false, "disembark should hide gui")
poopDeck.sailing.onBoarded()
assertEqual(poopDeck.state.ship.isAboard, true, "board should mark aboard")
assert(poopDeck.gui.visible == true, "board should show gui")
poopDeck.gui.teardown()
assert(poopDeck.gui.window == nil, "gui teardown should clear window")

reset()
poopDeck.fishing.castAgain()
assertSent({"queue addclearfull free fcast"})
assertEqual(poopDeck.state.fishing.status, "Casting", "fcast should set casting state")
poopDeck.fishing.parseCastSuccess("You cock back your arm and smoothly cast your line over the railing into the nearby water. You judge the cast at about 71 feet.")
assertEqual(poopDeck.state.fishing.status, "Waiting", "cast success should set waiting state")
assertEqual(poopDeck.state.fishing.hooked, false, "cast success should clear hooked state")
assertEqual(poopDeck.state.fishing.lineFeetLeft, 71, "cast success should set initial line distance")

reset()
poopDeck.fishing.castMedium()
assertSent({"queue addclearfull free cast line medium"})
assertEqual(poopDeck.state.fishing.status, "Casting", "medium cast should set casting state")

reset()
resetTimers()
poopDeck.fishing.jerk()
assertSent({"jerk pole"})
assert(#timers == 2, "large strike should schedule two follow-up jerk timers")
assertEqual(timers[1].delay, 1.9, "first large-strike retry should wait for fishing balance")
assertEqual(timers[2].delay, 3.8, "second large-strike retry should wait for fishing balance")
reset()
poopDeck.fishing.showSize("an gigantic")
assertEqual(poopDeck.state.fishing.status, "Hooked", "fish size should set hooked state")
assertEqual(poopDeck.state.fishing.size, "gigantic", "fish size should be stored")
poopDeck.fishing.showSize("a colossal")
assertEqual(poopDeck.state.fishing.size, "colossal", "fish size should strip leading article")
poopDeck.fishing.onLineDistance("367")
assertEqual(poopDeck.state.fishing.lineFeetLeft, 367, "line distance should be stored")
poopDeck.fishing.reel()
assertSent({"queue addclearfull free reel line"})
assertEqual(poopDeck.state.fishing.status, "Reeling", "reel should set reeling state")
runTimers()
assertSent({"queue addclearfull free reel line"})
poopDeck.fishing.onLanded()
assertEqual(poopDeck.state.fishing.status, "Landed", "landed should set landed state")
assertEqual(poopDeck.state.fishing.hooked, false, "landed should clear hooked")
assertEqual(poopDeck.state.fishing.size, nil, "landed should clear size")
assertEqual(poopDeck.state.fishing.lineFeetLeft, nil, "landed should clear line distance")
poopDeck.fishing.parseCaughtLine("With a final tug, you finish reeling in the line and land a redfin tuna weighing 233 pounds and 7 ounces!")
assertEqual(poopDeck.state.fishing.caughtFishType, "redfin tuna", "caught fish type should be stored without article")
assertEqual(poopDeck.state.fishing.caughtPounds, 233, "caught fish pounds should be stored")
assertEqual(poopDeck.state.fishing.caughtOunces, 7, "caught fish ounces should be stored")

poopDeck.gui.build()
poopDeck.fishing.showSize("an enormous")
poopDeck.fishing.onLineDistance("367")
assert(poopDeck.gui.labels.fishingLine1.text:match("Status: Reeling") ~= nil, "gui should title-case fishing state")
assert(poopDeck.gui.labels.fishingLine1.text:match("Hooked: Yes") ~= nil, "gui should title-case hooked value")
assert(poopDeck.gui.labels.fishingLine1.text:match("Size: Enormous") ~= nil, "gui should title-case size value")
assert(poopDeck.gui.labels.fishingLine1.text:match("Line: 367 ft") ~= nil, "gui should show line distance")
assert(poopDeck.gui.labels.fishingLine1.text:match("timers") == nil, "gui should not show timers")
poopDeck.fishing.parseCaughtLine("With a final tug, you finish reeling in the line and land a redfin tuna weighing 233 pounds and 7 ounces!")
assert(poopDeck.gui.labels.fishingLine1.text:match("Status: Landed") ~= nil, "caught fish should set landed status")
assert(poopDeck.gui.labels.fishingLine1.text:match("Hooked: No") ~= nil, "caught fish should clear hooked display")
assert(poopDeck.gui.labels.fishingLine1.text:match("Line: %-") ~= nil, "caught fish should clear line distance display")
assert(poopDeck.gui.labels.fishingLine2.text == "Caught: 233lb 7oz Redfin Tuna", "gui should show caught fish summary")
poopDeck.gui.teardown()

poopDeck.stats.memory = poopDeck.stats.emptyData()
poopDeck.stats.loaded = true
poopDeck.stats.usingMemory = true
local statsTimestamp = os.time()
poopDeck.stats.recordFishCatch("a redfin tuna", 233, 7, statsTimestamp)
poopDeck.stats.recordFishCatch("redfin tuna", 200, 0, statsTimestamp)
poopDeck.stats.recordFishCatch("rock bass", 10, 3, statsTimestamp)
local fishStats = poopDeck.stats.fishSummary("all")
assertEqual(fishStats.total, 3, "stats should count all fish catches")
assertEqual(fishStats.biggest.fish_type, "redfin tuna", "stats should store normalized fish type")
assertEqual(fishStats.biggest.total_ounces, 3735, "stats should track biggest catch by total ounces")
local tunaStats = poopDeck.stats.fishSummary("all", "redfin tuna")
assertEqual(tunaStats.total, 2, "stats should filter catches by fish type")
assertEqual(poopDeck.stats.fishSummary("today").total, 3, "stats should count today's catches")
poopDeck.stats.recordSeamonsterKill("a pirate ship", statsTimestamp)
poopDeck.stats.recordSeamonsterKill("sea hag", statsTimestamp)
local monsterStats = poopDeck.stats.seamonsterSummary("all")
assertEqual(monsterStats.total, 2, "stats should count seamonster kills")
assertEqual(monsterStats.byType["pirate ship"].count, 1, "stats should normalize monster articles")
assertEqual(poopDeck.stats.seamonsterSummary("today").total, 2, "stats should count today's seamonster kills")
poopDeck.stats.show("fish all redfin tuna")
poopDeck.stats.show("monsters today")
poopDeck.stats.show("db")

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
