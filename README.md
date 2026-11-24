# Are You Talented?

See what spec your party and raid members are, right on their frames.

Each party and raid frame gets a small icon of the talent tree that member put the most points in: Arms, Fury or Protection for a warrior, Holy, Discipline or Shadow for a priest, and so on. So you can tell at a glance whether the druid is healing, the warrior is tanking, and what the paladin who just joined is here to do.

- **No inspecting and no clicking**: each member's spec shows by itself a few seconds after they join.
- **Party frames, both kinds**: the standard ones, with the icon beside the frame, and the raid-style ones, with the icon inside the frame. Raid-style party frames show your own spec too.
- **Raid frames**: the icon inside each member's frame, whether you keep groups together or combine them.
- **Player tooltips**: hover any player, in your group or not, and the tooltip has a line with their spec's name and the points in each tree, like `Talents: Fury (5/41/5)`.

## Options

Esc > Options > AddOns > Are You Talented?, or type `/ayt`:

- **Show specs on party and raid frames**: the icons, on or off.
- **Icon side**: right or left of a standard party frame.
- **Icon size**: how big the icon is beside a standard party frame. Inside raid frames and raid-style party frames the icon follows the frame's size, and a smaller setting shrinks it.
- **Show specs on player tooltips**: the tooltip line, on or off.
- **Players outside your group too**: the tooltip line for any player you point at or target. On by default; turn it off to keep the line to your party or raid.

## Commands

- `/ayt`: the options.
- `/ayt list`: your party's or raid's specs, in chat, starting with a summary count of each spec.
- `/ayt refresh`: read everyone's talents again now.
- `/ayt debug`: print what is read in chat until you run it again or reload.

## Good to know

- A member's talents are read a few seconds after they join, wherever they are, once you're out of combat. A full raid fills in shortly after. Until a member is read, their frame shows a grey question mark.
- A spec that was read stays on the frame when the member goes offline, and after you reload or log back in.
- Talents refresh periodically while you're grouped, and on every ready check, so a respec or a switch to a second spec shows soon after.
- A player outside your group is read a moment after the mouse settles on them, or after you target them, while you're out of combat. The line then shows on the tooltip you're looking at.
- Players the game doesn't let you inspect get no tooltip line.
- A member with no talent points spent gets no icon.
- A member with the same points in two trees shows the first of them.
- On raid frames and raid-style party frames the icon is always inside the frame, at its right edge, and about a third of the frame's height, so it grows and shrinks with your frames.

Works on **WoW Forever**.

## Install

Copy the `AreYouTalented` folder to `World of Warcraft\_forever_\Interface\AddOns\` and restart the game.

## Made with AI
This addon was made with AI.

## License
MIT, see `LICENSE`.
