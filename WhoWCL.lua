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

-- Try to read Who results in a way that works on both old and newer clients
local function GetWhoCount()
    if C_FriendList and C_FriendList.GetNumWhoResults then
        return C_FriendList.GetNumWhoResults()
    elseif GetNumWhoResults then
        return GetNumWhoResults()
    end
    return nil
end

local function GetWhoName(index)
    if C_FriendList and C_FriendList.GetWhoInfo then
        local info = C_FriendList.GetWhoInfo(index)
        if info then
            return info.fullName or info.name
        end
    elseif GetWhoInfo then
        -- Classic GetWhoInfo signature: name, guild, level, race, class, zone, classFileName, sex
        local name = GetWhoInfo(index)
        return name
    end
    return nil
end

-- We hook CHAT_MSG_SYSTEM and look for the summary line like "1 player total"
local function SystemFilter(self, event, msg, ...)
    if not msg then return false end

    -- Very naive enUS-style checks; adjust if your client text differs
    -- Examples:
    --  "1 player total"
    --  "1 Alliance player"
    --  "1 Horde player"
    if msg:find("1 player total") or msg:find("1 Alliance player") or msg:find("1 Horde player") then
        -- Give the client a tiny moment to populate Who results
        C_Timer.After(0.1, function()
            local num = GetWhoCount()
            if not num then
                Print("Could not read who results (no API).")
                return
            end

            Print("Detected /who summary: " .. msg .. " (numResults=" .. num .. ")")

            if num ~= 1 then
                -- Don't spam if the query returned more than 1
                return
            end

            local name = GetWhoName(1)
            if not name then
                Print("Could not read who result name.")
                return
            end

            local url = buildWclUrl(name, PLAYER_REALM)
            Print(string.format("%s-%s: %s", name, PLAYER_REALM, url))
        end)
    end

    -- Don't block the original system message
    return false
end

-- Basic frame just to say "loaded"
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        Print("loaded. Realm = " .. PLAYER_REALM .. " (chat hook active)")
    end
end)
frame:RegisterEvent("PLAYER_LOGIN")

-- Hook system messages from /who
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemFilter)

-- Optional: super-simple /wclwho just to confirm slash commands work at all
SLASH_WCLWHO1 = "/wclwho"
SlashCmdList["WCLWHO"] = function(msg)
    msg = msg and msg:match("^%s*(.-)%s*$") or ""
    Print('Slash test fired. Arg="' .. msg .. '"')
end
