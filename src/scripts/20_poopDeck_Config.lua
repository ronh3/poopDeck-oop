poopDeck = poopDeck or {}
poopDeck.config = poopDeck.config or {}

local config = poopDeck.config

config.filename = getMudletHomeDir() .. "/poopDeckconfig.lua"
config.defaults = {
  sipHealthPercent = 75,
  autoFire = false,
  selectedWeapon = nil,
  maintainTarget = "hull"
}
config.data = config.data or {}

local function copyDefaults()
  for key, value in pairs(config.defaults) do
    if config.data[key] == nil then
      config.data[key] = value
    end
  end
end

function config.load()
  config.data = {}
  if io.exists and io.exists(config.filename) then
    local ok = pcall(function()
      table.load(config.filename, config.data)
    end)
    if not ok and poopDeck.output and poopDeck.output.warn then
      poopDeck.output.warn("Could not load config, using defaults")
    end
  end
  copyDefaults()
  return config.data
end

function config.save()
  copyDefaults()
  local ok = pcall(function()
    table.save(config.filename, config.data)
  end)
  if not ok and poopDeck.output and poopDeck.output.warn then
    poopDeck.output.warn("Could not save config")
  end
end

function config.get(key)
  copyDefaults()
  return config.data[key]
end

function config.set(key, value)
  config.data[key] = value
  return value
end

function config.setHealthPercent(value)
  local percent = tonumber(value)
  if not percent or percent < 1 or percent > 100 then
    if poopDeck.output then
      poopDeck.output.bad("Health percent must be 1-100")
    end
    return false
  end
  config.set("sipHealthPercent", percent)
  config.save()
  if poopDeck.output then
    poopDeck.output.good("Health threshold set to " .. percent .. "%")
  end
  return true
end

function config.setAutoFire(enabled)
  config.set("autoFire", enabled == true)
  config.save()
end

function config.setWeapon(weapon)
  if weapon ~= "ballista" and weapon ~= "onager" and weapon ~= "thrower" then
    if poopDeck.output then
      poopDeck.output.bad("Weapon must be ballista, onager, or thrower")
    end
    return false
  end
  config.set("selectedWeapon", weapon)
  config.save()
  return true
end

config.load()
