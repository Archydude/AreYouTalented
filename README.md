# Are You Talented?

See what spec your party members are, right on the party frames.

Each party frame gets a small icon of the talent tree that member put the most points in: Arms, Fury or Protection for a warrior, Holy, Discipline or Shadow for a priest, and so on. So you can tell at a glance whether the druid is healing, the warrior is tanking, and what the paladin who just joined is here to do.

- **No inspecting and no clicking**: each member's spec shows by itself a few seconds after they join.
- **Both kinds of party frames**: the standard ones, with the icon beside the frame, and the raid-style ones, with the icon inside the frame. Raid-style party frames show your own spec too.
- **Player tooltips**: hover a party member and the tooltip has a line with their spec's name and the points in each tree, like `Talents: Fury (5/41/5)`.

## Options

Esc > Options > AddOns > Are You Talented?, or type `/ayt`:

- **Show specs on party frames**: the icons, on or off.
- **Icon side**: right or left of the party frame.
- **Icon size**: how big the icon is.
- **Show specs on player tooltips**: the tooltip line, on or off.

## Commands

- `/ayt`: the options.
- `/ayt list`: your party's specs, in chat.
- `/ayt refresh`: read everyone's talents again now.

## Good to know

- A member's talents are read a few seconds after they join, wherever they are, once you're out of combat. Until then their frame shows a grey question mark.
- A spec that was read stays on the frame when the member goes offline, and after you reload or log back in.
- Talents are read again about once a minute, and on every ready check, so a respec or a switch to a second spec shows soon after.
- A member with no talent points spent gets no icon.
- A member with the same points in two trees shows the first of them.
- On raid-style party frames the icon is always inside the frame, at its right edge, and shrinks to fit.
- Parties only: raids aren't covered.

Works on **WoW Forever**.

## Install

Copy the `AreYouTalented` folder to `World of Warcraft\_forever_\Interface\AddOns\` and restart the game.

## Made with AI
This addon was made with AI.

## License
MIT, see `LICENSE`.
