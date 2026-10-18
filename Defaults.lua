local _, ns = ...;

ns.defaults = {
  profile = {
    enabled = true;
    removeSuffix = true; -- "Trade - English" becomes "Trade"

    -- {number} is the channel number and {name} the channel name or alias, e.g. "({number}) {name}"
    channelFormat = "[{number}. {name}]"; -- numbered channels such as Trade
    chatTypeFormat = "[{name}]"; -- chat types without a number, such as Guild

    -- timestamps normally take the colour of the message (e.g. orange for Trade)
    colorTimestamps = false;
    timestampColor = { r = 0.6; g = 0.6; b = 0.6; };

    aliases = {}; -- lower-case channel name/alias mappings (blank or missing keeps the name)
    customAliases = ""; -- one "Name = Alias" per line, for channels not listed in ns.KNOWN_CHANNELS
  };
};

-- channel names listed in the options menu 
-- (aliases are matched ignoring case)
ns.KNOWN_CHANNELS = {
  channels = {
    "General", "Trade", "LocalDefense", "LookingForGroup", "WorldDefense", "GuildRecruitment",
  };
  chatTypes = {
    "Guild", "Officer", "Party", "Party Leader", "Raid", "Raid Leader", "Raid Warning",
    "Instance", "Instance Leader",
  };
};
