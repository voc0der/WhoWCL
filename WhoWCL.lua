local REGION = "US"              -- change if you're not on US
local PLAYER_REALM = GetRealmName()

local function slugRealm(realm)
  -- "Dreamscythe" -> "dreamscythe"
  -- "My Realm Name" -> "my-realm-name"
  return realm:gsub("%s+", "-"):lower()
end

local function buildWclUrl(name, realm)
  realm = realm or PLAYER_REALM
  return string.format(
    "https://fresh.warcraftlogs.com/character/%s/%s/%s",
    REGION:lower(),
    slugRealm(realm),
    name
  )
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("WHO_LIST_UPDATE")

frame:SetScript("OnEvent", function(self, event)
  if event ~= "WHO_LIST_UPDATE" then return end

  local numResults = GetNumWhoResults()
  -- To avoid spam, only act when there's exactly one match
  if numResults ~= 1 then return end

  local name, guild, level, race, class, zone, classFileName, sex = GetWhoInfo(1)
  if not name then return end

  local url = buildWclUrl(name, PLAYER_REALM)
  DEFAULT_CHAT_FRAME:AddMessage(string.format(
    "|cff00ff00[WCL]|r %s-%s: %s",
    name,
    PLAYER_REALM,
    url
  ))
end)
