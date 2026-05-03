local function read(path)
  local file = assert(io.open(path, "r"))
  local contents = file:read("*a")
  file:close()
  return contents
end

local mfile = read("mfile")
local init = read("src/scripts/00_poopDeck_Init.lua")

local mfileVersion = mfile:match('"version"%s*:%s*"([^"]+)"')
local titleVersion = mfile:match('"title"%s*:%s*"poopDeck Restart ([^"]+)"')
local runtimeVersion = init:match('poopDeck%.version%s*=%s*"([^"]+)"')

assert(mfileVersion and mfileVersion ~= "", "mfile.version is missing")
assert(titleVersion and titleVersion ~= "", "mfile.title does not include version")
assert(runtimeVersion and runtimeVersion ~= "", "runtime poopDeck.version is missing")
assert(mfileVersion == titleVersion, "mfile.version and mfile.title differ")
assert(mfileVersion == runtimeVersion, "mfile.version and runtime poopDeck.version differ")

print("version ok " .. mfileVersion)
