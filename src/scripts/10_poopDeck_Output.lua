poopDeck = poopDeck or {}
poopDeck.output = poopDeck.output or {}
poopDeck.state = poopDeck.state or {}
poopDeck.state.events = poopDeck.state.events or {}

local output = poopDeck.output

output.colors = {
  info = "cyan",
  good = "green",
  warn = "yellow",
  bad = "red",
  muted = "gray"
}

local function adbUi()
  if type(agnosticdb) ~= "table" or type(agnosticdb.ui) ~= "table" then
    return nil
  end
  return agnosticdb.ui
end

local function colorTag(color)
  local name = tostring(color or output.colors.info)
  if name == "" or name == "reset" then
    return ""
  end
  if name:sub(1, 1) == "<" then
    return name
  end
  return "<" .. name .. ">"
end

local function resetTag()
  local ui = adbUi()
  if ui and type(ui.theme_tags) == "function" then
    local ok, tags = pcall(ui.theme_tags)
    if ok and type(tags) == "table" and tags.reset then
      return tags.reset
    end
  end
  return "<reset>"
end

local function adbThemeTags()
  local ui = adbUi()
  if ui and type(ui.theme_tags) == "function" then
    local ok, tags = pcall(ui.theme_tags)
    if ok and type(tags) == "table" then
      return tags
    end
  end
  return nil
end

local function stripColorTags(text)
  return (tostring(text or ""):gsub("<[^>]->", ""))
end

local function visibleLength(text)
  return #stripColorTags(text)
end

local function frameWidth()
  local wrap = 80
  if type(getWindowWrap) == "function" then
    local ok, value = pcall(getWindowWrap, "main")
    if ok and type(value) == "number" and value > 0 then
      wrap = value
    end
  end
  local width = wrap - 2
  if width < 40 then
    width = 40
  end
  return width
end

local function frameLine(theme, left, fill, right, label)
  local width = frameWidth()
  local border = theme.border or "<grey>"
  local accent = theme.accent or "<cyan>"
  local reset = theme.reset or "<reset>"
  if label and label ~= "" then
    local text = " " .. tostring(label) .. " "
    local pad = math.max(0, width - visibleLength(text))
    local leftPad = math.floor(pad / 2)
    local rightPad = pad - leftPad
    return border .. left .. string.rep(fill, leftPad) .. accent .. text .. border .. string.rep(fill, rightPad) .. right .. reset
  end
  return border .. left .. string.rep(fill, width) .. right .. reset
end

local function frameContentLine(theme, text)
  local width = frameWidth()
  local border = theme.border or "<grey>"
  local body = theme.text or "<white>"
  local reset = theme.reset or "<reset>"
  local content = " " .. tostring(text or "") .. " "
  local padding = string.rep(" ", math.max(0, width - visibleLength(content)))
  return border .. "║" .. body .. content .. padding .. border .. "║" .. reset
end

local function framedStatus(title, rows)
  local theme = adbThemeTags()
  if not theme or type(cecho) ~= "function" then
    return false
  end

  cecho("\n" .. frameLine(theme, "╔", "═", "╗") .. "\n")
  cecho(frameLine(theme, "║", " ", "║", "poopDeck - " .. tostring(title)) .. "\n")
  for _, row in ipairs(rows or {}) do
    cecho(frameContentLine(theme, row) .. "\n")
  end
  cecho(frameLine(theme, "╚", "═", "╝") .. "\n")
  return true
end

function output.line(text, color)
  local colorName = color or output.colors.info
  output.remember(text, colorName)
  local message = "[poopDeck] " .. tostring(text)
  local ui = adbUi()
  if ui and type(ui.emit_line) == "function" then
    ui.emit_line(colorTag(colorName) .. message .. resetTag(), { prefix = "" })
  elseif cecho then
    cecho("\n" .. colorTag(colorName) .. message .. resetTag() .. "\n\n")
  else
    echo("\n" .. message .. "\n\n")
  end
  poopDeck.refreshGui()
end

function output.remember(text, color)
  local events = poopDeck.state.events
  table.insert(events, 1, {
    text = tostring(text),
    color = color or output.colors.info
  })
  while #events > 10 do
    table.remove(events)
  end
end

function output.info(text)
  output.line(text, output.colors.info)
end

function output.good(text)
  output.line(text, output.colors.good)
end

function output.warn(text)
  output.line(text, output.colors.warn)
end

function output.bad(text)
  output.line(text, output.colors.bad)
end

function output.shot(text)
  output.line(text, output.colors.warn)
end

function output.status(title, rows)
  if framedStatus(title, rows) then
    output.remember(title, output.colors.good)
  else
    output.good(title)
    for _, row in ipairs(rows or {}) do
      echo("  " .. row .. "\n")
    end
  end
  poopDeck.refreshGui()
end

function output.rawLines(rows)
  local theme = adbThemeTags() or {}
  local textTag = theme.text or ""
  local reset = theme.reset or "<reset>"

  if cecho then
    cecho("\n")
    for _, row in ipairs(rows or {}) do
      cecho(textTag .. tostring(row) .. reset .. "\n")
    end
    cecho("\n")
  else
    echo("\n")
    for _, row in ipairs(rows or {}) do
      echo(tostring(row) .. "\n")
    end
    echo("\n")
  end
  poopDeck.refreshGui()
end
