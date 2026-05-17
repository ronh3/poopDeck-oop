poopDeck = poopDeck or {}
poopDeck.stats = poopDeck.stats or {}

local stats = poopDeck.stats

stats.dbName = "poopdeck_stats"
stats.loaded = stats.loaded or false
stats.memory = stats.memory or {
  fish_catches = {},
  seamonster_kills = {}
}

local function trim(value)
  return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function stripArticle(value)
  return trim(value):gsub("^%s*[Aa][Nn]?%s+", "")
end

local function normalizeType(value)
  return stripArticle(value):lower()
end

local function titleCase(value)
  local text = stripArticle(value)
  if text == "" then
    return "Unknown"
  end
  return text:gsub("(%a)([%w']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
end

local function now()
  return os.time()
end

local function dateKeys(timestamp)
  timestamp = tonumber(timestamp) or now()
  return {
    day = os.date("%Y-%m-%d", timestamp),
    week = os.date("%Y-W%U", timestamp),
    month = os.date("%Y-%m", timestamp)
  }
end

local function ensureMemoryShape()
  stats.memory = type(stats.memory) == "table" and stats.memory or {}
  stats.memory.fish_catches = type(stats.memory.fish_catches) == "table" and stats.memory.fish_catches or {}
  stats.memory.seamonster_kills = type(stats.memory.seamonster_kills) == "table" and stats.memory.seamonster_kills or {}
end

local function safeFetch(tbl)
  if type(db) ~= "table" or type(db.fetch) ~= "function" or not tbl then
    return nil
  end
  local ok, rows = pcall(db.fetch, db, tbl)
  if not ok then
    return nil
  end
  return rows or {}
end

function stats.emptyData()
  return {
    fish_catches = {},
    seamonster_kills = {}
  }
end

function stats.load()
  ensureMemoryShape()
  stats.usingMemory = true

  if type(db) ~= "table" or type(db.create) ~= "function" then
    stats.loaded = true
    return false
  end

  stats.schema = {
    fish_catches = {
      fish_type = "",
      pounds = 0,
      ounces = 0,
      total_ounces = 0,
      caught_at = 0,
      day_key = "",
      week_key = "",
      month_key = ""
    },
    seamonster_kills = {
      monster_type = "",
      killed_at = 0,
      day_key = "",
      week_key = "",
      month_key = ""
    }
  }

  local ok, handle = pcall(db.create, db, stats.dbName, stats.schema)
  if not ok or not handle then
    if poopDeck.output and poopDeck.output.warn then
      poopDeck.output.warn("Could not initialize stats database; using session-only stats")
    end
    stats.loaded = true
    return false
  end

  stats.handle = handle
  stats.fish_catches = handle.fish_catches
  stats.seamonster_kills = handle.seamonster_kills
  stats.usingMemory = false
  stats.loaded = true
  return true
end

function stats.ensureLoaded()
  if not stats.loaded then
    stats.load()
  end
  ensureMemoryShape()
end

local function reportWriteFailure(err)
  if stats.writeErrorReported then
    return
  end
  stats.writeErrorReported = true
  if poopDeck.output and poopDeck.output.warn then
    poopDeck.output.warn("Could not write stats database: " .. tostring(err or "unknown error"))
  end
end

local function safeAdd(tbl, record)
  if type(db) ~= "table" or type(db.add) ~= "function" or not tbl then
    return false, "Mudlet DB add API unavailable"
  end

  local ok, err = pcall(db.add, db, tbl, record)
  if not ok then
    reportWriteFailure(err)
    return false, err
  end
  return true
end

local function safeDeleteAll(tbl)
  if type(db) ~= "table" or type(db.delete) ~= "function" or not tbl then
    return false, "Mudlet DB delete API unavailable"
  end

  local ok, result, err = pcall(db.delete, db, tbl, true)
  if not ok then
    return false, result
  end
  if result == nil and err ~= nil then
    return false, err
  end
  return true
end

local function copyList(list)
  local result = {}
  for index, value in ipairs(list or {}) do
    result[index] = value
  end
  return result
end

function stats.fetchFishCatches()
  stats.ensureLoaded()
  if not stats.usingMemory then
    return safeFetch(stats.fish_catches) or {}
  end
  return copyList(stats.memory.fish_catches)
end

function stats.fetchSeamonsterKills()
  stats.ensureLoaded()
  if not stats.usingMemory then
    return safeFetch(stats.seamonster_kills) or {}
  end
  return copyList(stats.memory.seamonster_kills)
end

function stats.resetData()
  stats.ensureLoaded()
  stats.memory = stats.emptyData()
  stats.writeErrorReported = nil

  if stats.usingMemory then
    return true
  end

  local fishOk, fishErr = safeDeleteAll(stats.fish_catches)
  local monsterOk, monsterErr = safeDeleteAll(stats.seamonster_kills)
  if not fishOk or not monsterOk then
    if poopDeck.output and poopDeck.output.warn then
      poopDeck.output.warn(
        "Could not reset stats database: " ..
        tostring(fishErr or monsterErr or "unknown error")
      )
    end
    return false
  end

  return true
end

function stats.periodKey(period, timestamp)
  local keys = dateKeys(timestamp)
  if period == "today" then
    return "day_key", keys.day
  end
  if period == "week" then
    return "week_key", keys.week
  end
  if period == "month" then
    return "month_key", keys.month
  end
  return nil, nil
end

function stats.recordsFor(records, period)
  local list = records or {}
  if not period or period == "all" then
    return copyList(list)
  end

  local key, value = stats.periodKey(period)
  if not key then
    return copyList(list)
  end

  local result = {}
  for _, record in ipairs(list) do
    if record[key] == value then
      result[#result + 1] = record
    end
  end
  return result
end

local function compareBiggest(left, right)
  return (tonumber(left.total_ounces) or 0) > (tonumber(right.total_ounces) or 0)
end

local function recordOunces(record)
  local total = tonumber(record and record.total_ounces)
  if total then
    return total
  end
  return (tonumber(record and record.pounds) or 0) * 16 + (tonumber(record and record.ounces) or 0)
end

function stats.goldForOunces(totalOunces)
  return math.floor((tonumber(totalOunces) or 0) * 221 / 640 + 0.5)
end

local function periodLabel(period)
  local labels = {
    today = "Today",
    week = "This Week",
    month = "This Month",
    all = "All Time"
  }
  return labels[period or "all"] or labels.all
end

local tablePeriods = {
  {key = "today"},
  {key = "week"},
  {key = "month"},
  {key = "all"}
}

local function cellText(value)
  return tostring(value == nil and "" or value)
end

local function padCell(value, width, alignRight)
  value = cellText(value)
  local padding = string.rep(" ", math.max(0, width - #value))
  if alignRight then
    return padding .. value
  end
  return value .. padding
end

local function splitLines(text)
  local lines = {}
  text = tostring(text or "")
  for line in (text .. "\n"):gmatch("(.-)\n") do
    if line ~= "" then
      lines[#lines + 1] = line
    end
  end
  return lines
end

local function tableMaker()
  if stats.tableMakerUnavailable then
    return nil
  end
  for _, moduleName in ipairs({"@PKGNAME@.ftext", "poopDeck.ftext", "MDK.ftext"}) do
    local ok, ftext = pcall(require, moduleName)
    if ok and type(ftext) == "table" and type(ftext.TableMaker) == "table" then
      return ftext.TableMaker
    end
  end
  stats.tableMakerUnavailable = true
  return nil
end

local function tableMakerLines(headers, rows, rightAligned, title)
  if #rows == 0 then
    return nil
  end

  local TableMaker = tableMaker()
  if not TableMaker then
    return nil
  end

  local widths = {}
  for index, header in ipairs(headers) do
    widths[index] = #cellText(header)
  end
  for _, row in ipairs(rows) do
    for index, value in ipairs(row) do
      widths[index] = math.max(widths[index] or 0, #cellText(value))
    end
  end

  local ok, maker = pcall(TableMaker.new, TableMaker, {
    title = title or "",
    printTitle = title ~= nil and title ~= "",
    printHeaders = true,
    separateRows = false,
    forceHeaderSeparator = true,
    formatType = "",
    frameColor = "",
    separatorColor = "",
    titleColor = "",
    headCharacter = "=",
    footCharacter = "=",
    rowSeparator = "-",
    edgeCharacter = "|",
    separator = "|"
  })
  if not ok or type(maker) ~= "table" then
    return nil
  end

  for index, header in ipairs(headers) do
    maker:addColumn({
      name = header,
      width = widths[index],
      alignment = rightAligned and rightAligned[index] and "right" or "left",
      formatType = "",
      textColor = "",
      wrap = false,
      nogap = true
    })
  end
  for _, row in ipairs(rows) do
    local textRow = {}
    for index, value in ipairs(row) do
      textRow[index] = cellText(value)
    end
    maker:addRow(textRow)
  end

  local assembledOk, assembled = pcall(function()
    return maker:assemble()
  end)
  if not assembledOk or type(assembled) ~= "string" then
    return nil
  end
  return splitLines(assembled)
end

local function tableLines(headers, rows, rightAligned, title)
  if #rows == 0 then
    return {"(none)"}
  end

  local mdkLines = tableMakerLines(headers, rows, rightAligned, title)
  if mdkLines then
    return mdkLines
  end

  local widths = {}
  for index, header in ipairs(headers) do
    widths[index] = #cellText(header)
  end

  for _, row in ipairs(rows) do
    for index, value in ipairs(row) do
      widths[index] = math.max(widths[index] or 0, #cellText(value))
    end
  end

  local lines = {}
  local headerCells = {}
  local separatorCells = {}
  for index, header in ipairs(headers) do
    headerCells[index] = padCell(header, widths[index], rightAligned and rightAligned[index])
    separatorCells[index] = string.rep("-", widths[index])
  end
  lines[#lines + 1] = table.concat(headerCells, "  ")
  lines[#lines + 1] = table.concat(separatorCells, "  ")

  for _, row in ipairs(rows) do
    local cells = {}
    for index, value in ipairs(row) do
      cells[index] = padCell(value, widths[index], rightAligned and rightAligned[index])
    end
    lines[#lines + 1] = table.concat(cells, "  ")
  end

  return lines
end

function stats.formatWeight(record, includeType)
  if not record then
    return "-"
  end
  local text = string.format("%dlb %doz", tonumber(record.pounds) or 0, tonumber(record.ounces) or 0)
  if includeType then
    text = text .. " " .. titleCase(record.fish_type)
  end
  return text
end

function stats.recordFishCatch(fishType, pounds, ounces, timestamp)
  stats.ensureLoaded()
  local normalized = normalizeType(fishType)
  if normalized == "" then
    normalized = "unknown"
  end

  pounds = tonumber(pounds) or 0
  ounces = tonumber(ounces) or 0
  timestamp = tonumber(timestamp) or now()
  local keys = dateKeys(timestamp)
  local record = {
    fish_type = normalized,
    pounds = pounds,
    ounces = ounces,
    total_ounces = pounds * 16 + ounces,
    caught_at = timestamp,
    day_key = keys.day,
    week_key = keys.week,
    month_key = keys.month
  }

  if not stats.usingMemory then
    local ok = safeAdd(stats.fish_catches, record)
    if ok then
      return record
    end
  end

  table.insert(stats.memory.fish_catches, record)
  return record
end

function stats.recordSeamonsterKill(monsterType, timestamp)
  stats.ensureLoaded()
  local normalized = normalizeType(monsterType)
  if normalized == "" then
    normalized = "unknown"
  end

  timestamp = tonumber(timestamp) or now()
  local keys = dateKeys(timestamp)
  local record = {
    monster_type = normalized,
    killed_at = timestamp,
    day_key = keys.day,
    week_key = keys.week,
    month_key = keys.month
  }

  if not stats.usingMemory then
    local ok = safeAdd(stats.seamonster_kills, record)
    if ok then
      return record
    end
  end

  table.insert(stats.memory.seamonster_kills, record)
  return record
end

function stats.fishSummary(period, fishType)
  local typeFilter = fishType and normalizeType(fishType) or nil
  local records = stats.recordsFor(stats.fetchFishCatches(), period or "all")
  local summary = {
    total = 0,
    total_ounces = 0,
    biggest = nil,
    byType = {}
  }

  for _, record in ipairs(records) do
    if not typeFilter or record.fish_type == typeFilter then
      summary.total = summary.total + 1
      summary.total_ounces = summary.total_ounces + recordOunces(record)
      if not summary.biggest or compareBiggest(record, summary.biggest) then
        summary.biggest = record
      end

      local entry = summary.byType[record.fish_type]
      if not entry then
        entry = {fish_type = record.fish_type, count = 0, biggest = nil}
        summary.byType[record.fish_type] = entry
      end
      entry.count = entry.count + 1
      if not entry.biggest or compareBiggest(record, entry.biggest) then
        entry.biggest = record
      end
    end
  end

  summary.gold = stats.goldForOunces(summary.total_ounces)
  return summary
end

function stats.seamonsterSummary(period)
  local records = stats.recordsFor(stats.fetchSeamonsterKills(), period or "all")
  local summary = {
    total = 0,
    byType = {}
  }

  for _, record in ipairs(records) do
    summary.total = summary.total + 1
    local entry = summary.byType[record.monster_type]
    if not entry then
      entry = {monster_type = record.monster_type, count = 0}
      summary.byType[record.monster_type] = entry
    end
    entry.count = entry.count + 1
  end

  return summary
end

local function sortedMapValues(map, countField)
  local values = {}
  for _, value in pairs(map or {}) do
    values[#values + 1] = value
  end
  table.sort(values, function(left, right)
    local leftCount = tonumber(left[countField]) or 0
    local rightCount = tonumber(right[countField]) or 0
    if leftCount ~= rightCount then
      return leftCount > rightCount
    end
    return tostring(left.fish_type or left.monster_type) < tostring(right.fish_type or right.monster_type)
  end)
  return values
end

local function typeNamesFromSummaries(summaries)
  local names = {}
  local seen = {}
  for _, period in ipairs(tablePeriods) do
    local summary = summaries[period.key]
    for name in pairs(summary and summary.byType or {}) do
      if not seen[name] then
        seen[name] = true
        names[#names + 1] = name
      end
    end
  end

  table.sort(names, function(left, right)
    local leftCount = tonumber(summaries.all.byType[left] and summaries.all.byType[left].count) or 0
    local rightCount = tonumber(summaries.all.byType[right] and summaries.all.byType[right].count) or 0
    if leftCount ~= rightCount then
      return leftCount > rightCount
    end
    return titleCase(left) < titleCase(right)
  end)
  return names
end

local function summaryCount(summaries, period, name)
  local entry = summaries[period] and summaries[period].byType and summaries[period].byType[name]
  return entry and entry.count or 0
end

function stats.fishTableLines(title)
  local summaries = {}
  for _, period in ipairs(tablePeriods) do
    summaries[period.key] = stats.fishSummary(period.key)
  end

  local rows = {}
  for _, name in ipairs(typeNamesFromSummaries(summaries)) do
    local allEntry = summaries.all.byType[name]
    rows[#rows + 1] = {
      titleCase(name),
      summaryCount(summaries, "today", name),
      summaryCount(summaries, "week", name),
      summaryCount(summaries, "month", name),
      summaryCount(summaries, "all", name),
      stats.formatWeight(allEntry and allEntry.biggest, false)
    }
  end

  if #rows > 0 then
    rows[#rows + 1] = {
      "Total",
      summaries.today.total,
      summaries.week.total,
      summaries.month.total,
      summaries.all.total,
      stats.formatWeight(summaries.all.biggest, true)
    }
    rows[#rows + 1] = {
      "Gold",
      summaries.today.gold,
      summaries.week.gold,
      summaries.month.gold,
      summaries.all.gold,
      "-"
    }
  end

  return tableLines(
    {"Fish", "Today", "Week", "Month", "All", "Biggest"},
    rows,
    {[2] = true, [3] = true, [4] = true, [5] = true},
    title
  )
end

function stats.seamonsterTableLines(title)
  local summaries = {}
  for _, period in ipairs(tablePeriods) do
    summaries[period.key] = stats.seamonsterSummary(period.key)
  end

  local rows = {}
  for _, name in ipairs(typeNamesFromSummaries(summaries)) do
    rows[#rows + 1] = {
      titleCase(name),
      summaryCount(summaries, "today", name),
      summaryCount(summaries, "week", name),
      summaryCount(summaries, "month", name),
      summaryCount(summaries, "all", name)
    }
  end

  if #rows > 0 then
    rows[#rows + 1] = {
      "Total",
      summaries.today.total,
      summaries.week.total,
      summaries.month.total,
      summaries.all.total
    }
  end

  return tableLines(
    {"Seamonster", "Today", "Week", "Month", "All"},
    rows,
    {[2] = true, [3] = true, [4] = true, [5] = true},
    title
  )
end

local function parsePeriod(value)
  value = tostring(value or ""):lower()
  if value == "today" or value == "day" or value == "daily" then
    return "today"
  end
  if value == "week" or value == "weekly" then
    return "week"
  end
  if value == "month" or value == "monthly" then
    return "month"
  end
  if value == "all" or value == "alltime" or value == "all-time" then
    return "all"
  end
  return nil
end

function stats.showOverview(period)
  if period then
    local fish = stats.fishSummary(period)
    local monsters = stats.seamonsterSummary(period)
    poopDeck.output.status("poopDeck Stats - " .. periodLabel(period), {
      "Fish catches: " .. tostring(fish.total),
      "Seamonster kills: " .. tostring(monsters.total),
      "Biggest catch: " .. stats.formatWeight(fish.biggest, true)
    })
    return
  end

  local periods = {"today", "week", "month", "all"}
  local fishParts = {}
  local monsterParts = {}

  for _, item in ipairs(periods) do
    fishParts[#fishParts + 1] = periodLabel(item) .. ": " .. tostring(stats.fishSummary(item).total)
    monsterParts[#monsterParts + 1] = periodLabel(item) .. ": " .. tostring(stats.seamonsterSummary(item).total)
  end

  local allFish = stats.fishSummary("all")
  poopDeck.output.status("poopDeck Stats", {
    "Fish catches - " .. table.concat(fishParts, " | "),
    "Seamonster kills - " .. table.concat(monsterParts, " | "),
    "Biggest catch: " .. stats.formatWeight(allFish.biggest, true)
  })
  poopDeck.output.rawLines(stats.fishTableLines("Fish Catches"))
  poopDeck.output.rawLines(stats.seamonsterTableLines("Seamonster Kills"))
end

function stats.showFish(period, fishType)
  period = period or "all"
  local summary = stats.fishSummary(period, fishType)
  local title = fishType
    and ("Fish Stats - " .. titleCase(fishType) .. " - " .. periodLabel(period))
    or ("Fish Stats - " .. periodLabel(period))
  local rows = {
    "Total catches: " .. tostring(summary.total),
    "Biggest catch: " .. stats.formatWeight(summary.biggest, true)
  }

  local values = sortedMapValues(summary.byType, "count")
  for index, entry in ipairs(values) do
    if index > 10 then
      break
    end
    rows[#rows + 1] = string.format(
      "%s: %d caught, biggest %s",
      titleCase(entry.fish_type),
      entry.count,
      stats.formatWeight(entry.biggest, false)
    )
  end

  poopDeck.output.status(title, rows)
end

function stats.showSeamonsters(period)
  period = period or "all"
  local summary = stats.seamonsterSummary(period)
  local rows = {
    "Total kills: " .. tostring(summary.total)
  }

  local values = sortedMapValues(summary.byType, "count")
  for index, entry in ipairs(values) do
    if index > 10 then
      break
    end
    rows[#rows + 1] = string.format("%s: %d", titleCase(entry.monster_type), entry.count)
  end

  poopDeck.output.status("Seamonster Stats - " .. periodLabel(period), rows)
end

function stats.showDb()
  stats.load()
  local fishRows = stats.fetchFishCatches()
  local monsterRows = stats.fetchSeamonsterKills()
  poopDeck.output.status("poopDeck Stats DB", {
    "DB API: " .. tostring(type(db) == "table" and type(db.create) == "function"),
    "Backend: " .. (stats.usingMemory and "Session memory" or "Mudlet DB"),
    "Database: " .. tostring(stats.dbName),
    "Fish rows: " .. tostring(#fishRows),
    "Seamonster rows: " .. tostring(#monsterRows)
  })
end

function stats.showReset(rest)
  if trim(rest):lower() ~= "confirm" then
    poopDeck.output.status("poopDeck Stats Reset", {
      "This permanently deletes all fish catches and seamonster kills.",
      "Run: poopstats reset confirm"
    })
    return
  end

  if stats.resetData() then
    poopDeck.output.warn("Stats database reset")
  end
end

function stats.show(args)
  local input = trim(args)
  if input == "" then
    stats.showOverview()
    return
  end

  local first, rest = input:match("^(%S+)%s*(.-)$")
  first = tostring(first or ""):lower()
  rest = trim(rest)

  local period = parsePeriod(first)
  if period then
    stats.showOverview(period)
    return
  end

  if first == "fish" or first == "fishes" then
    local second, tail = rest:match("^(%S+)%s*(.-)$")
    local fishPeriod = parsePeriod(second)
    if fishPeriod then
      stats.showFish(fishPeriod, trim(tail) ~= "" and tail or nil)
    else
      stats.showFish("all", rest ~= "" and rest or nil)
    end
    return
  end

  if first == "monster" or first == "monsters" or first == "seamonster" or first == "seamonsters" then
    local monsterPeriod = parsePeriod(rest)
    stats.showSeamonsters(monsterPeriod or "all")
    return
  end

  if first == "db" or first == "database" then
    stats.showDb()
    return
  end

  if first == "reset" or first == "clear" then
    stats.showReset(rest)
    return
  end

  poopDeck.output.status("poopDeck Stats", {
    "poopstats - overview",
    "poopstats db - database status",
    "poopstats reset confirm - delete all recorded stats",
    "poopstats today|week|month|all",
    "poopstats fish [today|week|month|all] [type]",
    "poopstats monsters [today|week|month|all]"
  })
end

stats.load()
