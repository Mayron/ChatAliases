# Chat Aliases

**Shorter, cleaner chat channel names.** Chat Aliases turns long channel prefixes like `[2. Trade - English]` into whatever you like, e.g. `[2. Trade]`, `[2. T]`, `[2:T]` or `(2) T`. Your chat window has more room for the messages that matter.

### Before

```
[2. Trade - English] [Victor Nefarius]: Your victory shall be short lived!
[1. General - Icecrown] [Arthas Menethil]: I see... only darkness before me.
```

### After

```
[2:T] [Victor Nefarius]: Your victory shall be short lived!
[1:G] [Arthas Menethil]: I see... only darkness before me.
```

## Features

- **Remove the location suffix**: drop the ` - English` or ` - Orgrimmar` part, so `[2. Trade - English]` becomes `[2. Trade]`.
- **Channel aliases**: give any channel a short name, e.g. Trade -> `T`, General -> `G` or LookingForGroup -> `LFG`.
  - Boxes are ready for General, Trade, LocalDefense, LookingForGroup, WorldDefense and GuildRecruitment.
  - **Use first letters** fills in every empty box with the channel's initials in one click.
  - Add any custom channel under **Other channels**, one `Name = Alias` per line.
- **Chat type aliases**: shorten Guild, Officer, Party, Party Leader, Raid, Raid Leader, Raid Warning, Instance, Instance Leader, Battleground and Battleground Leader too, e.g. `[Guild]` -> `[G]`.
- **Your own format**: decide exactly how channels look using `{number}` and `{name}`:

  | Format               | Result       |
  | -------------------- | ------------ |
  | `[{number}. {name}]` | `[2. Trade]` |
  | `[{number}:{name}]`  | `[2:T]`      |
  | `({number}) {name}`  | `(2) Trade`  |
  | `{name}`             | `Trade`      |

  Chat types such as Guild and Party have their own format, e.g. `({name})` for `(Guild)`.

- **Timestamp colour**: by default, chat timestamps take the colour of the message, such as orange for Trade. Give them one fixed colour instead, such as a subtle grey, so they stay out of the way.
- **Live preview**: see the result in the options panel as you type.
- **Clickable links still work**: only the visible text changes, so clicking a channel name still opens chat to that channel.
- **Plays nicely with others**: built to work alongside chat addons such as Chat Highlighter.

## How to use

Open the settings from **Options -> AddOns -> Chat Aliases**, or type `/chataliases` in chat.

- **General tab**: turn the addon on or off, remove location suffixes, set the channel and chat type formats, and choose a timestamp colour.
- **Aliases tab**: type a short name next to any channel or chat type. Leave a box empty to keep the original name.

Timestamps themselves are turned on in the game's own settings (**Options -> Social**). Chat Aliases only changes their colour.

## Notes

- Chat Aliases changes what _you_ see in your chat window only. Other players see nothing different.
- Settings are shared across all your characters, and can be reset to their defaults at any time.
- In battlegrounds and instances, some chat lines are protected by the game and no addon can change them. Those lines keep their original channel name and timestamp colour.
