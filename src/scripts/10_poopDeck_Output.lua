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

function output.line(text, color)
  local colorName = color or output.colors.info
  output.remember(text, colorName)
  local formatted = "\n[poopDeck] " .. tostring(text) .. "\n\n"
  if cecho then
    cecho("<" .. colorName .. ">" .. formatted)
  else
    echo(formatted)
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
  output.good(title)
  for _, row in ipairs(rows or {}) do
    echo("  " .. row .. "\n")
  end
end
