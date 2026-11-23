-- Are You Talented?: the spec on the party frames
-- A small icon of the member's talent tree on each party frame, with the tree's name and points
-- next to it. Works on both kinds of party frames: the standard ones (portrait and bars) and the
-- raid-style ones, which also show the player.
--
-- A badge is a frame of our own, a child of the party frame so it moves, scales and hides with
-- it. It takes no mouse input, so clicks and the member's tooltip work as before.

local _, ns = ...

-- Shown while a member's talents haven't been read yet.
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local MIN_SIZE = 10
-- On raid-style frames the icon sits inside the frame, so it takes at most this much of its height.
local COMPACT_HEIGHT_SHARE = 0.45

local badges = setmetatable({}, { __mode = "k" }) -- party frame -> its badge

local function badgeOn(frame)
	local badge = badges[frame]
	if badge then return badge end
	badge = CreateFrame("Frame", nil, frame)
	badge:SetFrameLevel(frame:GetFrameLevel() + 10)
	badge.edge = badge:CreateTexture(nil, "BACKGROUND")
	badge.edge:SetColorTexture(0, 0, 0, 1)
	badge.edge:SetPoint("TOPLEFT", -1, 1)
	badge.edge:SetPoint("BOTTOMRIGHT", 1, -1)
	badge.icon = badge:CreateTexture(nil, "ARTWORK")
	badge.icon:SetAllPoints()
	badge.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- without the icon's own border
	badge.text = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	badge.text:SetShadowOffset(1, -1)
	badges[frame] = badge
	return badge
end

-- Puts the badge where the settings say. Standard frames get it outside, beside the bars, with
-- the text on its far side; raid-style frames get it inside, at the right edge, without text.
local function place(badge, frame, compact)
	local db = ns.db
	local size = db.size
	if compact then
		local height = frame:GetHeight() or 0
		size = math.max(MIN_SIZE, math.min(size, math.floor(height * COMPACT_HEIGHT_SHARE + 0.5)))
	end
	local placed = (compact and "c" or db.side) .. size
	if badge.placed == placed then return end
	badge.placed = placed
	badge:ClearAllPoints()
	badge.text:ClearAllPoints()
	badge:SetSize(size, size)
	if compact then
		badge:SetPoint("RIGHT", frame, "RIGHT", -3, 0)
	elseif db.side == "left" then
		badge:SetPoint("RIGHT", frame, "LEFT", 3, 4)
		badge.text:SetPoint("RIGHT", badge, "LEFT", -4, 0)
	else
		badge:SetPoint("LEFT", frame, "RIGHT", 2, 4)
		badge.text:SetPoint("LEFT", badge, "RIGHT", 4, 0)
	end
end

local function label(spec)
	local db = ns.db
	if db.name and db.points then return spec.name .. " " .. spec.points end
	if db.name then return spec.name end
	if db.points then return spec.points end
	return ""
end

local function update(frame, unit, compact)
	if frame:IsForbidden() then return end
	local spec
	local show = false
	if ns.db.frames and unit and UnitExists(unit) and UnitIsPlayer(unit) then
		spec = ns.Talents.SpecOf(ns.Plain(UnitGUID(unit)))
		-- No points spent: nothing to show. Not read yet: a question mark, for members who can
		-- still be read.
		show = spec or (spec == nil and UnitIsConnected(unit) and not UnitIsUnit(unit, "player"))
	end
	if not show then
		local badge = badges[frame]
		if badge then badge:Hide() end
		return
	end
	local badge = badgeOn(frame)
	place(badge, frame, compact)
	if spec then
		badge.icon:SetTexture(spec.icon or UNKNOWN_ICON)
		badge.icon:SetDesaturated(false)
		badge:SetAlpha(1)
		badge.text:SetText(compact and "" or label(spec))
	else
		badge.icon:SetTexture(UNKNOWN_ICON)
		badge.icon:SetDesaturated(true)
		badge:SetAlpha(0.6)
		badge.text:SetText("")
	end
	badge:Show()
end

-- Brings every party frame's badge up to date. Cheap, and called often: on party changes, when
-- talents are read, when a setting changes, and every look at the party (see Talents.lua), since
-- the game hands party frames their members in its own time.
function ns.Refresh()
	if not ns.db then return end
	local inParty = IsInGroup() and not IsInRaid()
	local standard = PartyFrame and PartyFrame.PartyMemberFramePool
	if standard then
		for frame in standard:EnumerateActive() do
			update(frame, inParty and (frame.unitToken or frame.unit), false)
		end
	end
	local compact = CompactPartyFrame and CompactPartyFrame.memberUnitFrames
	if compact then
		for _, frame in ipairs(compact) do
			update(frame, inParty and frame.unit, true)
		end
	end
end
