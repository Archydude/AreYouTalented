# Are You Talented?: CurseForge upload sheet

What to type into each CurseForge field, ready to copy and paste. The steps for a first upload and for releasing an update are in [UPLOADING.md](../UPLOADING.md).

Update this sheet with every release: the zip, the display name and the changelog, and rewrite the description so it covers everything in the new version.

## A. Project form

**Project name**
```
Are You Talented?
```

**Summary**
```
Shows each party member's talent spec on the party frames, as the icon of the talent tree they put the most points in, and any player's spec on their tooltip. No inspecting, no clicking. For WoW Forever.
```

**Main category:** `Unit Frames`
**Additional categories:** `Tooltip`

**License:** `MIT License`

**Logo / avatar:** `AreYouTalented\images\logo-v1.png`

**Description** (paste everything between the lines)

---
```markdown
## See your party's specs at a glance

Are You Talented? puts each party member's spec right on their party frame: the icon of the talent tree they put the most points in. No inspecting, no clicking, no asking in chat. Made for **WoW Forever**.

### Know who does what
- Is the druid healing or tanking? Is the warrior Protection or Fury? One look at the party frames tells you.
- Each member's spec shows a few seconds after they join, even when they're far away.
- A grey question mark marks a member whose talents haven't been read yet.

### On the party frames
- **Spec icon:** the talent tree's own icon, as in the talent window.
- Works on both kinds of party frames: beside the standard ones, and inside the raid-style ones, which show your own spec too.
- You pick which side of a standard frame the icon goes on, and how big it is.

### On tooltips
- Hover any player, in your party or not, and their tooltip gets a line with the spec's name and the points in each tree, like "Talents: Fury (5/41/5)".
- Size up a stranger before you invite them, or spot a hybrid build.
- For players outside your party, the line shows a moment after the mouse settles on them. Targeting them works too.
- Each can be turned off.

### Stays up to date
- Talents are read again about once a minute and on every ready check, so a respec or a switch to a second spec shows soon after.
- A spec stays on the frame when the member goes offline, and after you reload.

### Good to know
- **/ayt** opens the options. **/ayt list** writes your party's specs in chat.
- Talents are read while you're out of combat. Someone who joins mid-fight gets their icon when it ends.
- A member with no talent points spent gets no icon. With the same points in two trees, the first one shows.
- Players the game doesn't let you inspect get no tooltip line.
- The icons are for parties: raid frames aren't covered.

This addon was made with AI.

**Feedback and bug reports are welcome** in the comments.
```
---

**Source / Issues links:** `https://github.com/Archydude/AreYouTalented` and `https://github.com/Archydude/AreYouTalented/issues`

## B. Upload File form

**File:** `dist\AreYouTalented-1.1.0.zip`

**Display name**
```
Are You Talented? 1.1.0
```

**Release type:** `Release`

**Game versions:** Forever `1.60.1`.

**Changelog** (paste only the newest part; paste older parts too if they never went up)
```markdown
1.1.0
- Player tooltips now show the spec of any player you point at or target, not only your party members. The line appears a moment after the mouse settles on them, while you're out of combat.
- New option: **Players outside your party too**, on by default. Turn it off to keep the tooltip line to your party.

1.0.1
- The spec's name and the talent points no longer show next to the icon on party frames: the icon alone tells the spec. The member's tooltip still has the name and the points. The two options for them are gone.

1.0.0
- First release: see each party member's spec on their party frame, as the icon of the talent tree they put the most points in.
- The spec's name next to the icon, like "Fury", and the points in each tree, like "5/41/5", each one an option.
- Works on both kinds of party frames. Raid-style party frames show the icon inside the frame, and show your own spec too.
- Pick the icon's side and size on the options page.
- Player tooltips of your party members get a line with their spec and points.
- `/ayt list` writes your party's specs in chat, and `/ayt refresh` reads everyone's talents again.
```
