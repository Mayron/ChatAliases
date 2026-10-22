local addonName, ns = ...;

local _G = _G;
local pairs, ipairs, type = _G.pairs, _G.ipairs, _G.type;
local strsplit, strtrim, format, canaccessvalue = _G.strsplit, _G.strtrim,
                                                  _G.format, _G.canaccessvalue;

-- lower-case channel name aliases built from the saved settings by ns:CompileSettings()
ns.compiled = {};

-- Removes characters that would break the channel link or other addons reading it.
function ns:SanitizeAlias(alias)
    if (type(alias) ~= "string") then return ""; end
    return strtrim((alias:gsub("[|%[%]]", "")));
end

-- Brackets are allowed in formats, but "|" 
-- would start an escape sequence and break the link.
function ns:SanitizeFormat(text)
    if (type(text) ~= "string") then return ""; end
    return (text:gsub("|", ""));
end

-- Parses "Name = Alias" lines into { [lowerName] = alias }
function ns:ParseCustomAliases(text)
    local list = {};
    if (type(text) ~= "string") then return list; end

    for _, line in ipairs({strsplit("\n", text)}) do
        local name, alias = line:match("^(.-)=(.*)$");

        if (name) then
            name = strtrim(name):lower();
            alias = self:SanitizeAlias(alias);

            if (name ~= "" and alias ~= "") then list[name] = alias; end
        end
    end

    return list;
end

function ns:CompileSettings()
    local compiled = {};
    self.compiled = compiled;

    if (not self.db) then return end

    local profile = self.db.profile;

    for name, alias in pairs(profile.aliases) do
        alias = self:SanitizeAlias(alias);
        if (alias ~= "") then compiled[name:lower()] = alias; end
    end

    -- "Other channels" lines win over the per-channel boxes
    for name, alias in pairs(self:ParseCustomAliases(profile.customAliases)) do
        compiled[name] = alias;
    end
end

-- Formats the visible text of a channel link, e.g. "2. Trade - English" becomes "[2:T]"
-- Returns the new visible text of the link, built from the channel or chat type format
function ns:FormatChannel(text)
    local profile = self.db.profile;
    local number, name = text:match("^(%d+)%.%s*(.+)$");
    if (not number) then name = text; end

    -- an alias for the full name ("Trade - English") replaces all of it,
    -- otherwise look up the name without its location suffix ("Trade")
    local base, suffix = name:match("^(.-)( %- .+)$");
    local alias = self.compiled[name:lower()];

    if (alias) then
        name = alias;
    elseif (base) then
        name = self.compiled[base:lower()] or base;

        if (not profile.removeSuffix) then name = name .. suffix; end
    end

    local template = number and profile.channelFormat or profile.chatTypeFormat;
    if (strtrim(template) == "") then template = "[{name}]"; end

    -- replacement functions, so a "%" in a name or alias is not read as a capture
    local result =
        template:gsub("{number}", function() return number or ""; end);
    result = result:gsub("{name}", function() return name; end);
    result = result:gsub("{channel}", function() return name; end); -- older name for {name}
    return result;
end

-- Wraps a timestamp in the chosen timestamp colour.
function ns:ColorTimestampText(timestamp)
    local c = self.db.profile.timestampColor;
    local function toByte(value) return math.floor(value * 255 + 0.5); end
    return format("|cff%02x%02x%02x%s|r", toByte(c.r), toByte(c.g), toByte(c.b),
                  timestamp);
end

local CHANNEL_LINK_PATTERN = "(|Hchannel:[^|]*|h)%[(.-)%](|h)";

-- Only the visible text of the link changes; the link data stays, so clicking it still works.
local function ReplaceChannelLink(link, text, close)
    return link .. ns:FormatChannel(text) .. close;
end

-- Note to self: WoW Forever reads the "showTimestamps" setting through ChatFrameUtil;
-- older clients store the format in the CHAT_TIMESTAMP_FORMAT global!
-- This fixes silly bug by Mayron...
local function GetTimestampFormat()
    local ChatFrameUtil = _G.ChatFrameUtil;

    if (ChatFrameUtil and ChatFrameUtil.GetTimestampFormat) then
        return ChatFrameUtil.GetTimestampFormat();
    end

    return _G.CHAT_TIMESTAMP_FORMAT;
end

-- Turns a timestamp format such as "%I:%M %p " into a pattern matching "07:05 PM "
local timestampPatterns = {};
local function GetTimestampPattern(timestampFormat)
    local pattern = timestampPatterns[timestampFormat];
    if (not pattern) then
        pattern = timestampFormat:gsub("%%(%a)", "\1%1"); -- mark the date codes before escaping
        pattern = pattern:gsub("[%^%$%(%)%.%[%]%*%+%-%?%%]", "%%%0");
        pattern = pattern:gsub("\1(%a)", function(code)
            return (code == "p") and "%a+" or "%d+"; -- %p is the AM/PM text, everything else is a number
        end);
        pattern = "^(" .. pattern .. ")";
        timestampPatterns[timestampFormat] = pattern;
    end
    return pattern;
end

-- The timestamp is plain text at the start of the line, so it takes the message colour;
-- wrapping it in a colour code gives it a fixed colour instead.
local function ColorTimestamp(text)
    local timestampFormat = GetTimestampFormat();

    if (not timestampFormat) then
        -- silly Mayron bug fixed here...
        return text;
    end

    local timestamp = text:match(GetTimestampPattern(timestampFormat));
    if (not timestamp) then return text; end

    return ns:ColorTimestampText(timestamp) .. text:sub(#timestamp + 1);
end

-- Returns the new text for a chat line, or nil if ChatAliases should leave it alone.
local function GetNewText(text)
    -- (New to WoW Forever?) secret/restricted chat text (battlegrounds, instances)
    -- cannot be inspected by addons, so leave it untouched!
    if (canaccessvalue and not canaccessvalue(text)) then return end
    if (type(text) ~= "string" or not (ns.db and ns.db.profile.enabled)) then
        return
    end

    local newText = text:gsub(CHANNEL_LINK_PATTERN, ReplaceChannelLink);

    if (ns.db.profile.colorTimestamps) then
        newText = ColorTimestamp(newText);
    end

    if (newText ~= text) then return newText; end
end

-- Why not just replace chatFrame.AddMessage (like older versions did)?
-- In WoW Forever, ChatFrameMixin:AddMessage is a secure barrier. Replacing it taints
-- Blizzard's chat handler, and in battlegrounds the handler passes a secret table
-- (eventArgs) that cannot be read while tainted: "attempted to iterate a table that
-- cannot be accessed while tainted" on every chat line.
--
-- Chat message filters can't do it either: Blizzard adds the channel link and the
-- timestamp after the filters have run.
--
-- So instead:
--   1. hooksecurefunc runs OnAddMessage *after* the secure AddMessage, without tainting it.
--   2. The line is already in the frame by then, so we rewrite it with TransformMessages.
--      That runs as a secure elevation barrier (ScrollingMessageFrameSecureMixin) and only
--      calls our two functions inside tainted closures, so Blizzard's code stays secure.
local pendingText, pendingNewText;

local function IsPendingLine(message)
    -- secret lines can't be compared, and are never ours anyway
    if (canaccessvalue and not canaccessvalue(message)) then return false; end
    return message == pendingText;
end

local function SetPendingText(message, ...) return pendingNewText, ...; end

local function OnAddMessage(chatFrame, text)
    local newText = GetNewText(text);
    if (not newText) then return end

    pendingText, pendingNewText = text, newText;
    chatFrame:TransformMessages(IsPendingLine, SetPendingText);
    pendingText, pendingNewText = nil, nil;
end

-- Fallback for clients without TransformMessages: replacing AddMessage taints chat,
-- but those clients have no secret chat values, so it does no harm there.
local originalAddMessage = {};

local function NewAddMessage(self, text, ...)
    originalAddMessage[self](self, GetNewText(text) or text, ...);
end

local eventFrame = _G.CreateFrame("Frame");
eventFrame:RegisterEvent("ADDON_LOADED");
eventFrame:SetScript("OnEvent", function(self, _, arg1)
    if (arg1 ~= addonName) then return end
    self:UnregisterEvent("ADDON_LOADED");

    ns.db = _G.LibStub("AceDB-3.0"):New("ChatAliasesDB", ns.defaults, true);
    ns:CompileSettings();
    ns:SetupOptions();
end);

for _, chatFrameName in ipairs(_G.CHAT_FRAMES) do
    local chatFrame = _G[chatFrameName];

    if (chatFrame:GetID() ~= 2) then
        -- if not combat log...
        if (chatFrame.TransformMessages) then
            _G.hooksecurefunc(chatFrame, "AddMessage", OnAddMessage);
        else
            originalAddMessage[chatFrame] = chatFrame.AddMessage;
            chatFrame.AddMessage = NewAddMessage;
        end
    end
end
