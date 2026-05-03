-- Local Mudlet auto-reloader for muddler package builds.
--
-- Prerequisite:
--   Install the Muddler.mpackage helper in this Mudlet profile.
--   Each watched package's mfile must have `"outputFile": true` so muddler
--   writes the .output file that Muddler watches.

local ROOT = "/var/home/ron/mudletCode"

local PACKAGES = {
  {
    key = "agnosticDB",
    path = ROOT .. "/agnosticDB",
    modules = { "agnosticdb", "agnosticDB" },
  },
  {
    key = "boop",
    path = ROOT .. "/boop",
    modules = { "boop" },
    before_install = function()
      if type(boop) ~= "table" then
        return
      end

      if type(boop.handlers) == "table" and type(killAnonymousEventHandler) == "function" then
        for _, handler_id in ipairs(boop.handlers) do
          pcall(killAnonymousEventHandler, handler_id)
        end
        boop.handlers = {}
      end

      boop.bootstrapped = nil
    end,
  },
  {
    key = "poopDeck",
    path = ROOT .. "/poopDeck",
    modules = { "poopDeck" },
    before_install = function()
      if type(poopDeck) == "table" and type(poopDeck.onExit) == "function" then
        pcall(poopDeck.onExit)
      end

      poopDeck = nil
    end,
  },
  {
    key = "SubjugatorCuring",
    path = ROOT .. "/SubjugatorCuring",
    modules = { "subjugatorCuring", "SubjugatorCuring" },
    before_install = function()
      if type(subjugatorCuring) == "table"
        and type(subjugatorCuring.integrations) == "table"
        and type(subjugatorCuring.integrations.gmcp) == "table" then
        subjugatorCuring.integrations.gmcp.installed = false
      end
    end,
  },
  {
    key = "Subjugator",
    path = ROOT .. "/Subjugator",
    modules = { "subjugator", "Subjugator" },
    before_install = function()
      local bridge = type(subjugator) == "table"
        and type(subjugator.runtime) == "table"
        and subjugator.runtime.curingBridge

      if type(bridge) == "table" and type(bridge.teardown) == "function" then
        pcall(bridge.teardown)
      end
    end,
  },
  {
    key = "subjugatorUI",
    path = ROOT .. "/subjugatorUI/subjugatorUI",
    modules = { "subjugatorUI" },
    before_install = function()
      if type(subjugatorUI) ~= "table" then
        return
      end

      if type(subjugatorUI.clear_temp_triggers) == "function" then
        pcall(subjugatorUI.clear_temp_triggers)
      end

      if type(subjugatorUI.clear_runtime_owner) == "function" then
        for _, owner in ipairs({
          "adapters-events",
          "adapters-sidecars",
          "chat",
          "gmcp",
          "prompt",
        }) do
          pcall(subjugatorUI.clear_runtime_owner, owner)
        end
      end
    end,
  },
}

local function say(message, color)
  color = color or "cyan"
  if type(cecho) == "function" then
    cecho(string.format("<%s>[mudletCode updater]<reset> %s\n", color, message))
  elseif type(echo) == "function" then
    echo("[mudletCode updater] " .. message .. "\n")
  end
end

local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end
  return false
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end

  local contents = file:read("*a")
  file:close()
  return contents
end

local function escape_pattern(value)
  return tostring(value):gsub("([^%w])", "%%%1")
end

local function uncache_modules(prefixes)
  if type(package) ~= "table" or type(package.loaded) ~= "table" then
    return
  end

  for module_name in pairs(package.loaded) do
    for _, prefix in ipairs(prefixes or {}) do
      local escaped = escape_pattern(prefix)
      if module_name == prefix or module_name:match("^" .. escaped .. "%.") then
        package.loaded[module_name] = nil
        break
      end
    end
  end
end

local function run_before_install(spec)
  uncache_modules(spec.modules)

  if type(spec.before_install) == "function" then
    local ok, err = pcall(spec.before_install)
    if not ok then
      say(string.format("%s cleanup failed: %s", spec.key, tostring(err)), "yellow")
    end
  end
end

local function stop_existing()
  if type(mudletCodeUpdater) ~= "table" or type(mudletCodeUpdater.helpers) ~= "table" then
    return
  end

  for _, helper in pairs(mudletCodeUpdater.helpers) do
    if type(helper) == "table" and type(helper.stop) == "function" then
      pcall(helper.stop, helper)
    end
  end
end

local function output_package_path(spec)
  local output_path = spec.path .. "/.output"
  local contents = read_file(output_path)
  if not contents then
    return nil
  end

  local package_path = contents:match('"path"%s*:%s*"([^"]+)"')
  if not package_path or package_path == "" then
    return nil
  end

  if package_path:match("^/") then
    return spec.path .. package_path
  end

  return spec.path .. "/" .. package_path
end

local function diagnose()
  say("diagnostics:", "cyan")
  say("Muddler loaded: " .. tostring(type(Muddler) == "table" and type(Muddler.new) == "function"), "cyan")

  for _, spec in ipairs(PACKAGES) do
    local mfile_path = spec.path .. "/mfile"
    local output_path = spec.path .. "/.output"
    local mfile = read_file(mfile_path) or ""
    local package_path = output_package_path(spec)
    local helper = type(mudletCodeUpdater) == "table"
      and type(mudletCodeUpdater.helpers) == "table"
      and mudletCodeUpdater.helpers[spec.key]

    say(string.format(
      "%s: root=%s mfile=%s outputFile=%s .output=%s package=%s helper=%s",
      spec.key,
      tostring(file_exists(spec.path)),
      tostring(file_exists(mfile_path)),
      tostring(mfile:match('"outputFile"%s*:%s*true') ~= nil),
      tostring(file_exists(output_path)),
      tostring(package_path ~= nil and file_exists(package_path)),
      tostring(type(helper) == "table")
    ), "cyan")

    if package_path and not file_exists(package_path) then
      say("  missing package from .output: " .. package_path, "yellow")
    elseif not package_path and file_exists(output_path) then
      say("  could not read package path from " .. output_path, "yellow")
    end
  end
end

mudletCodeUpdater = mudletCodeUpdater or {}
mudletCodeUpdater.root = ROOT
mudletCodeUpdater.packages = PACKAGES
mudletCodeUpdater.diagnose = diagnose
mudletCodeUpdater.stop = stop_existing

local function start()
  if type(Muddler) ~= "table" or type(Muddler.new) ~= "function" then
    say("Muddler helper is not loaded yet; install/load Muddler.mpackage, then rerun this script.", "yellow")
    diagnose()
    return false
  end

  stop_existing()

  mudletCodeUpdater.root = ROOT
  mudletCodeUpdater.helpers = {}
  mudletCodeUpdater.packages = PACKAGES
  mudletCodeUpdater.diagnose = diagnose
  mudletCodeUpdater.stop = stop_existing

  for _, spec in ipairs(PACKAGES) do
    local helper = Muddler:new({
      path = spec.path,
      watch = true,
      preremove = function()
        say("Reloading " .. spec.key .. " from " .. spec.path)
      end,
      postremove = function()
        run_before_install(spec)
      end,
      postinstall = function()
        say("Installed " .. spec.key, "green")
      end,
    })

    mudletCodeUpdater.helpers[spec.key] = helper
  end

  mudletCodeUpdater.start = start
  say("Watching " .. tostring(#PACKAGES) .. " muddler package roots.", "green")
  return true
end

mudletCodeUpdater.start = start

local function start_on_load()
  if start() then
    return
  end

  if type(registerAnonymousEventHandler) == "function" then
    registerAnonymousEventHandler("sysLoadEvent", function()
      start()
    end)
  end
end

start_on_load()
