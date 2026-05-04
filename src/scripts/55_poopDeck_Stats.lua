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

local function sqlQuote(value)
  if value == nil then
    return "''"
  end
  return "'" .. tostring(value):gsub("'", "''") .. "'"
end

local function dbConn()
  if type(db) ~= "table" or type(db.__conn) ~= "table" then
    return nil
  end
  return db.__conn[stats.dbName:lower()]
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

local function insertSql(sql)
  local conn = dbConn()
  if not conn or type(conn.execute) ~= "function" then
    return false
  end
  local ok = pcall(conn.execute, conn, sql)
  if ok and type(conn.commit) == "function" then
    pcall(conn.commit, conn)
  end
  return ok
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

local function periodLabel(period)
  local labels = {
    today = "Today",
    week = "This Week",
    month = "This Month",
    all = "All Time"
  }
  return labels[period or "all"] or labels.all
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
    local ok = insertSql(string.format(
      "INSERT INTO fish_catches (fish_type, pounds, ounces, total_ounces, caught_at, day_key, week_key, month_key) VALUES (%s, %d, %d, %d, %d, %s, %s, %s)",
      sqlQuote(record.fish_type),
      record.pounds,
      record.ounces,
      record.total_ounces,
      record.caught_at,
      sqlQuote(record.day_key),
      sqlQuote(record.week_key),
      sqlQuote(record.month_key)
    ))
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
    local ok = insertSql(string.format(
      "INSERT INTO seamonster_kills (monster_type, killed_at, day_key, week_key, month_key) VALUES (%s, %d, %s, %s, %s)",
      sqlQuote(record.monster_type),
      record.killed_at,
      sqlQuote(record.day_key),
      sqlQuote(record.week_key),
      sqlQuote(record.month_key)
    ))
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
    biggest = nil,
    byType = {}
  }

  for _, record in ipairs(records) do
    if not typeFilter or record.fish_type == typeFilter then
      summary.total = summary.total + 1
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

  poopDeck.output.status("poopDeck Stats", {
    "poopstats - overview",
    "poopstats db - database status",
    "poopstats today|week|month|all",
    "poopstats fish [today|week|month|all] [type]",
    "poopstats monsters [today|week|month|all]"
  })
end

stats.load()
