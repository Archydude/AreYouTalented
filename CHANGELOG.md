# Changelog

## 1.2.1
- The spec icon on raid frames and raid-style party frames now sizes itself from the frame: about a third of its height, so it stays in proportion whatever size your frames are. A smaller **Icon size** shrinks it.

## 1.2.0
- Now works in raids: each raid member's spec icon shows on their raid frame, whether you keep groups together or combine them.
- In a raid, everyone's talents are read within about a minute, then again every five minutes and on every ready check.
- Two options are renamed to match: **Show specs on party and raid frames** and **Players outside your group too**.

## 1.1.0
- Player tooltips now show the spec of any player you point at or target, not only your party members. The line appears a moment after the mouse settles on them, while you're out of combat.
- New option: **Players outside your party too**, on by default. Turn it off to keep the tooltip line to your party.

## 1.0.1
- The spec's name and the talent points no longer show next to the icon on party frames: the icon alone tells the spec. The member's tooltip still has the name and the points. The two options for them are gone.

## 1.0.0
- First release: see each party member's spec on their party frame, as the icon of the talent tree they put the most points in.
- The spec's name next to the icon, like "Fury", and the points in each tree, like "5/41/5", each one an option.
- Works on both kinds of party frames. Raid-style party frames show the icon inside the frame, and show your own spec too.
- Pick the icon's side and size on the options page.
- Player tooltips of your party members get a line with their spec and points.
- `/ayt list` writes your party's specs in chat, and `/ayt refresh` reads everyone's talents again.
