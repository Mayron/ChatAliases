local _, ns = ...;

local _G = _G;
local LibStub = _G.LibStub;
local ipairs, format = _G.ipairs, _G.format;

local APP_NAME = "ChatAliases";
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0");
local AceConfigDialog = LibStub("AceConfigDialog-3.0");

local PREVIEW_LINES = {
  { 
    channel = "2. Trade - English"; 
    player = "Victor Nefarius"; 
    message = "Your victory shall be short lived!" 
  };
  { 
    channel = "1. General - Icecrown"; 
    player = "Arthas Menethil"; 
    message = "I see... only darkness before me." 
  };
  { 
    channel = "Guild";
    player = "Jaina Proudmoore";
    message = "Anyone up for Deadmines?"
  };
};


local function Refresh()
  ns:CompileSettings();
  AceConfigRegistry:NotifyChange(APP_NAME);
end

-- "LocalDefense" -> "LD", "Party Leader" -> "PL", "Trade" -> "T"
local function GetInitials(name)
  local initials = name:gsub("[^%u]", "");
  if (initials == "") then initials = name:sub(1, 1):upper(); end
  return initials;
end

local function GetPreview()
  local lines = {};
  for _, line in ipairs(PREVIEW_LINES) do
    local channel = ns.db.profile.enabled and ns:FormatChannel(line.channel) or ("[" .. line.channel .. "]");
    local timestamp = "07:05 ";

    if (ns.db.profile.enabled and ns.db.profile.colorTimestamps) then
      timestamp = ns:ColorTimestampText(timestamp);
    end

    -- TODO: the chat line colour (orange for Trade, green for Guild, etc...) 
    -- is left out, so the preview is white
    lines[#lines + 1] = format("%s%s [%s]: %s", timestamp, channel, line.player, line.message);
  end

  return "|cffffd100Preview:|r\n" .. table.concat(lines, "\n");
end

local function CreateGeneralOptions()
  local function notEnabled() return not ns.db.profile.enabled; end
  local function getProfile() return ns.db.profile; end

  return {
    type = "group";
    name = "General";
    order = 1;
    args = {
      description = {
        type = "description";
        name = "Chat Aliases shortens channel names in chat, e.g. [2. Trade - English] can become [2. Trade], [2. T] or [2:T]. Set aliases for each channel in the Aliases tab.";
        order = 1;
      };
      enabled = {
        type = "toggle";
        name = "Enable Chat Aliases";
        order = 2;
        width = "full";
        get = function() return getProfile().enabled; end;
        set = function(_, value) getProfile().enabled = value; Refresh(); end;
      };
      removeSuffix = {
        type = "toggle";
        name = "Remove location suffix";
        desc = "Drop the part after the dash, e.g. \"Trade - English\" becomes \"Trade\" and \"General - Orgrimmar\" becomes \"General\".";
        order = 3;
        width = "full";
        disabled = notEnabled;
        get = function() return getProfile().removeSuffix; end;
        set = function(_, value) getProfile().removeSuffix = value; Refresh(); end;
      };
      channelFormatHeader = {
        type = "header";
        name = "Channel format";
        order = 10;
      };
      channelFormatDescription = {
        type = "description";
        name = "How numbered channels such as General, Trade and LookingForGroup are shown. "
          .. "Use |cffffd100{number}|r for the channel number and |cffffd100{name}|r for the channel name or alias. "
          .. "For example |cffffd100[{number}. {name}]|r shows [2. Trade], |cffffd100({number}) {name}|r shows (2) Trade "
          .. "and |cffffd100[{number}:{name}]|r shows [2:T] when Trade has the alias T.";
        order = 11;
      };
      channelFormat = {
        type = "input";
        name = "Format";
        order = 12;
        disabled = notEnabled;
        get = function() return getProfile().channelFormat; end;
        set = function(_, value) getProfile().channelFormat = ns:SanitizeFormat(value); Refresh(); end;
      };
      resetChannelFormat = {
        type = "execute";
        name = "Reset format";
        desc = function() return format("Set the channel format back to %s.", ns.defaults.profile.channelFormat); end;
        order = 13;
        disabled = notEnabled;
        func = function()
          getProfile().channelFormat = ns.defaults.profile.channelFormat;
          Refresh();
        end;
      };
      chatTypeFormatHeader = {
        type = "header";
        name = "Chat type format";
        order = 14;
      };
      chatTypeFormatDescription = {
        type = "description";
        name = "How Guild, Officer, Party, Raid and other chat types are shown. These have no number, so only "
          .. "|cffffd100{name}|r applies. For example |cffffd100({name})|r shows (Guild), and |cffffd100[{name}]|r "
          .. "shows [G] when Guild has the alias G.";
        order = 14.1;
      };
      chatTypeFormat = {
        type = "input";
        name = "Format";
        order = 14.2;
        disabled = notEnabled;
        get = function() return getProfile().chatTypeFormat; end;
        set = function(_, value) getProfile().chatTypeFormat = ns:SanitizeFormat(value); Refresh(); end;
      };
      resetChatTypeFormat = {
        type = "execute";
        name = "Reset format";
        desc = function() return format("Set the chat type format back to %s.", ns.defaults.profile.chatTypeFormat); end;
        order = 14.3;
        disabled = notEnabled;
        func = function()
          getProfile().chatTypeFormat = ns.defaults.profile.chatTypeFormat;
          Refresh();
        end;
      };
      timestampHeader = {
        type = "header";
        name = "Timestamps";
        order = 16;
      };
      timestampDescription = {
        type = "description";
        name = "Timestamps are turned on in the game's own chat settings (Options > Social). By default they take the colour of the message, e.g. orange for Trade.";
        order = 17;
      };
      colorTimestamps = {
        type = "toggle";
        name = "Fixed timestamp colour";
        desc = "Show every timestamp in the chosen colour, instead of the colour of the message.";
        order = 18;
        width = "double"; -- the default width cuts the name off
        disabled = notEnabled;
        get = function() return getProfile().colorTimestamps; end;
        set = function(_, value) getProfile().colorTimestamps = value; Refresh(); end;
      };
      timestampColor = {
        type = "color";
        name = "Timestamp colour";
        order = 19;
        disabled = function() return notEnabled() or not getProfile().colorTimestamps; end;
        get = function()
          local c = getProfile().timestampColor;
          return c.r, c.g, c.b;
        end;
        set = function(_, r, g, b)
          local c = getProfile().timestampColor;
          c.r, c.g, c.b = r, g, b;
          Refresh();
        end;
      };
      previewHeader = {
        type = "header";
        name = "";
        order = 20;
      };
      preview = {
        type = "description";
        name = GetPreview;
        fontSize = "medium";
        order = 21;
      };
      resetHeader = {
        type = "header";
        name = "";
        order = 30;
      };
      resetAll = {
        type = "execute";
        name = "Reset all settings";
        desc = "Restore every setting to its default and clear all aliases.";
        order = 31;
        confirm = true;
        confirmText = "Reset all Chat Aliases settings to their defaults? All aliases will be cleared.";
        func = function()
          ns.db:ResetProfile();
          Refresh();
        end;
      };
    };
  };
end

local function AddAliasInputs(args, names, startOrder)
  for index, name in ipairs(names) do
    local key = name:lower();

    args["alias_" .. key:gsub(" ", "_")] = {
      type = "input";
      name = name;
      order = startOrder + index;
      width = "half";
      get = function() return ns.db.profile.aliases[key] or ""; end;
      set = function(_, value)
        value = ns:SanitizeAlias(value);
        ns.db.profile.aliases[key] = (value ~= "") and value or nil;
        Refresh();
      end;
    };
  end
end

local function CreateAliasOptions()
  local args = {
    description = {
      type = "description";
      name = "Type a short name for any channel. Leave a box blank to keep the channel's own name.";
      order = 1;
    };
    channelsHeader = {
      type = "header";
      name = "Channels";
      order = 10;
    };
    chatTypesHeader = {
      type = "header";
      name = "Chat types";
      order = 30;
    };
    otherHeader = {
      type = "header";
      name = "Other channels";
      order = 50;
    };
    customAliases = {
      type = "input";
      name = "Other channels";
      desc = "One channel per line as \"Name = Alias\", e.g. \"MyGuildAlts = Alts\". Matching ignores case. "
        .. "These win over the boxes above, and a full name such as \"Trade - English = TE\" is also allowed.";
      order = 51;
      width = "full";
      multiline = 5;
      get = function() return ns.db.profile.customAliases; end;
      set = function(_, value) ns.db.profile.customAliases = value; Refresh(); end;
    };
    manageHeader = {
      type = "header";
      name = "";
      order = 60;
    };
    useInitials = {
      type = "execute";
      name = "Use first letters";
      desc = "Fill every blank box above with the channel's initials, e.g. General = G, Trade = T, LocalDefense = LD.";
      order = 61;
      func = function()
        local aliases = ns.db.profile.aliases;
        for _, list in ipairs({ ns.KNOWN_CHANNELS.channels, ns.KNOWN_CHANNELS.chatTypes }) do
          for _, name in ipairs(list) do
            local key = name:lower();
            if (not aliases[key] or aliases[key] == "") then
              aliases[key] = GetInitials(name);
            end
          end
        end
        Refresh();
      end;
    };
    clearAliases = {
      type = "execute";
      name = "Clear aliases";
      desc = "Empty every box above. The \"Other channels\" list is kept.";
      order = 62;
      confirm = true;
      confirmText = "Clear all channel and chat type aliases?";
      func = function()
        _G.wipe(ns.db.profile.aliases);
        Refresh();
      end;
    };
  };

  AddAliasInputs(args, ns.KNOWN_CHANNELS.channels, 10);
  AddAliasInputs(args, ns.KNOWN_CHANNELS.chatTypes, 30);

  return {
    type = "group";
    name = "Aliases";
    order = 2;
    disabled = function(info) return info.type ~= "group" and not ns.db.profile.enabled; end;
    args = args;
  };
end

local function GetOptions()
  return {
    type = "group";
    name = "Chat Aliases";
    childGroups = "tab";
    args = {
      general = CreateGeneralOptions();
      aliases = CreateAliasOptions();
    };
  };
end

local function OpenOptions()
  if (ns.categoryId and _G.Settings and _G.Settings.OpenToCategory) then
    _G.Settings.OpenToCategory(ns.categoryId);
  else
    AceConfigDialog:Open(APP_NAME);
  end
end

-- Called from ChatAliases.lua once the saved variables are loaded.
function ns:SetupOptions()
  AceConfigRegistry:RegisterOptionsTable(APP_NAME, GetOptions);
  local _, categoryId = AceConfigDialog:AddToBlizOptions(APP_NAME, "Chat Aliases");
  self.categoryId = categoryId;

  _G.SLASH_CHATALIASES1 = "/chataliases";
  _G.SlashCmdList.CHATALIASES = OpenOptions;
end
