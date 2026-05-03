poopDeck = poopDeck or {}
poopDeck.output = poopDeck.output or {}

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
  if cecho then
    cecho("<" .. colorName .. ">[poopDeck] " .. tostring(text) .. "\n")
  else
    echo("[poopDeck] " .. tostring(text) .. "\n")
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
