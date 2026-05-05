poopDeck = poopDeck or {}
poopDeck.help = poopDeck.help or {}

local help = poopDeck.help

help.sections = {
  sailing = {
    title = "Sailing",
    rows = {
      "sstop - all stop",
      "scast - cast off",
      "sss <full|furl|relax|strike|0-100> - set sails",
      "stt <heading> - turn ship",
      "dock <dir> - dock ship",
      "wav <dir> <1-8> - wavecall",
      "lanc/ranc - lower/raise anchor",
      "lpla/rpla - lower/raise plank",
      "scomm on|off - commscreen",
      "mainh/mains/mainn - maintain hull/sails/none",
      "crig - clear rigging",
      "dour/doum/dous - douse room/me/sails"
    }
  },
  seamonsters = {
    title = "Seamonsters",
    rows = {
      "seaweapon <ballista|onager|thrower> - select auto weapon",
      "autosea on|off - toggle automatic fire",
      "seastop - stop seamonster firing and clear range state",
      "poophp <percent> - minimum health for firing",
      "firb - ballista dart",
      "firf or firbf - ballista flare",
      "firo - alternating onager shot",
      "firsp/first/firc - onager spider/star/chain",
      "fird - thrower disc"
    }
  },
  stats = {
    title = "Stats",
    rows = {
      "poopstats - overview tables",
      "poopstats db - database status",
      "poopstats reset confirm - delete all recorded stats",
      "poopstats today|week|month|all - period overview",
      "poopstats fish [today|week|month|all] [type] - fish catches and biggest catches",
      "poopstats monsters [today|week|month|all] - seamonster kills"
    }
  },
  fishing = {
    title = "Fishing",
    rows = {
      "poopfish - show fishing settings",
      "poopfish bait - run configured get/bait/cast sequence",
      "poopfish baitcmd <get command> - set bait retrieval command",
      "poopfish castdistance <distance> - set cast distance",
      "poopfish baitcmd default - restore get bass from tank",
      "poopfish castdistance default - restore medium cast distance"
    }
  },
  gui = {
    title = "GUI",
    rows = {
      "poopgui - show GUI position and size",
      "poopgui theme adb|runewarden|default - set GUI theme source",
      "poopgui restore on|off - use Mudlet's saved UserWindow layout",
      "poopgui pos <x> <y> - set spawn position",
      "poopgui size <width> <height> - set spawn size",
      "poopgui reset - restore default GUI geometry"
    }
  }
}

function help.showSection(name)
  local section = help.sections[name]
  if not section then
    help.showSplash()
    return
  end
  poopDeck.output.status(section.title, section.rows)
end

function help.showSplash()
  poopDeck.output.status("poopDeck " .. poopDeck.version, {
    "poopsail - sailing commands",
    "poopmonster - seamonster commands",
    "poopfish - fishing settings",
    "poopstats - catch and kill stats",
    "poopgui - GUI position and size",
    "poopfull - all commands",
    "ship status - current tracked ship/combat state"
  })
end

function help.showFull()
  help.showSplash()
  help.showSection("sailing")
  help.showSection("seamonsters")
  help.showSection("fishing")
  help.showSection("stats")
  help.showSection("gui")
end

function help.shipStatus()
  local ship = poopDeck.state.ship or {}
  local combat = poopDeck.state.combat or {}
  poopDeck.output.status("Ship Status", {
    "heading: " .. tostring(ship.currentHeading or "unknown"),
    "speed: " .. tostring(ship.currentSpeed or "unknown") .. " actual: " .. tostring(ship.actualSpeed or "unknown"),
    "hull: " .. tostring(ship.hullHealth or "unknown") .. " sails: " .. tostring(ship.sailHealth or "unknown"),
    "wind: " .. tostring(ship.windDirection or "unknown") .. "@" .. tostring(ship.windSpeed or "unknown"),
    "sea: " .. tostring(ship.seaCondition or "unknown"),
    "rowing: " .. poopDeck.boolText(ship.isRowing),
    "combat mode: " .. tostring(combat.mode or "manual"),
    "active: " .. poopDeck.boolText(combat.active),
    "fire pending: " .. poopDeck.boolText(combat.firePending),
    "weapon: " .. tostring(combat.selectedWeapon or poopDeck.config.get("selectedWeapon") or "none"),
    "firing: " .. poopDeck.boolText(combat.firing),
    "out of range: " .. poopDeck.boolText(combat.outOfRange)
  })
end
