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

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Make sure /who results are sent to the UI so WHO_LIST_UPDATE actually fires
        if SetWhoToUI then
            SetWhoToUI(true)
            Print("loaded. Realm = " .. PLAYER_REALM .. " (SetWhoToUI(true))")
        else
            Print("loaded. Realm = " .. PLAYER_REALM .. " (SetWhoToUI not available)")
        end
        return
    end

    if event ~= "WHO_LIST_UPDATE" then
        return
    end

    -- Try both APIs depending on client
    local numResults
    if C_FriendList and C_FriendList.GetNumWhoResults then
        numResults = C_FriendList.GetNumWhoResults()
    elseif GetNumWhoResults then
        numResults = GetNumWhoResults()
    else
        Print("No who API available on this client.")
        return
    end

    Print("WHO_LIST_UPDATE fired, numResults = " .. tostring(numResults))

    -- Only act when there is exactly one match
    if numResults ~= 1 then
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
        realm = PLAYER_REALM    -- /who is realm-local in Classic
    elseif GetWhoInfo then
        name = GetWhoInfo(1)    -- Old-style API returns name as first value
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
