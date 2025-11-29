local ADDON_PREFIX = "|cff00ff00[WhoWCL]|r "
local REGION = "US"  -- change if you're not on US
local PLAYER_REALM = GetRealmName() or "Unknown"

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(ADDON_PREFIX .. tostring(msg))
end

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

local lastQuery = nil

-- Create frame for events
local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        Print("loaded. Realm = " .. PLAYER_REALM)
        return
    end

    if event ~= "WHO_LIST_UPDATE" then
        return
    end

    -- Use classic-style who APIs
    local numResults
    if C_FriendList and C_FriendList.GetNumWhoResults then
        numResults = C_FriendList.GetNumWhoResults()
    elseif GetNumWhoResults then
        numResults = GetNumWhoResults()
    else
        Print("No who API available on this client.")
        return
    end

    Print("WHO_LIST_UPDATE fired, numResults = " .. tostring(numResults) ..
          (lastQuery and (" (query: \"" .. lastQuery .. "\")") or ""))

    if numResults ~= 1 then
        -- We only act when there's exactly 1 result to avoid spam/ambiguity
        return
    end

    local name, realm

    if C_FriendList and C_FriendList.GetWhoInfo then
        local info = C_FriendList.GetWhoInfo(1)
        if not info then
            Print("C_FriendList.GetWhoInfo(1) returned nil")
            return
        end
        name = info.fullName or info.name
        realm = PLAYER_REALM
    elseif GetWhoInfo then
        -- Classic GetWhoInfo signature: name, guild, level, race, class, zone, classFileName, sex
        local n = GetWhoInfo(1)
        name = n
        realm = PLAYER_REALM
    end

    if not name then
        Print("Could not read who result.")
        return
    end

    local url = buildWclUrl(name, realm)
    Print(string.format("%s-%s: %s", name, realm or "?", url))
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("WHO_LIST_UPDATE")

-- Slash command: /wclwho name
SLASH_WCLWHO1 = "/wclwho"
SlashCmdList["WCLWHO"] = function(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""
    if msg == "" then
        Print("Usage: /wclwho Name  (make it specific enough to return 1 result)")
        return
    end

    lastQuery = msg
    Print("Sending who query for: \"" .. msg .. "\"")

    if C_FriendList and C_FriendList.SendWho then
        C_FriendList.SendWho(msg)
    elseif SendWho then
        SendWho(msg)
    else
        Print("No SendWho API available on this client.")
    end
end
