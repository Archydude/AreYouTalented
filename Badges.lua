-- Are You Talented?: the spec on the party frames
-- A small icon of the member's talent tree on each party and raid frame. The tree's name and
-- points are on the member's tooltip (see Tooltip.lua). Works on the standard party frames
-- (portrait and bars), the raid-style party frames, which also show the player, and the raid frames.
--
-- A badge is a frame of our own, a child of the party frame so it moves, scales and hides with
-- it. It takes no mouse input, so clicks and the member's tooltip work as before.

local _, ns = ...

-- Shown while a member's talents haven't been read yet.
local UNKNOWN_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

local MIN_SIZE = 8
-- On raid frames and raid-style party frames the icon sits inside the frame and is sized from
-- the frame's height, so it stays in proportion whatever size the player gave the frames. It
-- takes this much of the height at the default Icon size and above; a smaller setting shrinks it.
local COMPACT_HEIGHT_SHARE = 0.35

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
	badges[frame] = badge
	return badge
end

-- Puts the badge where the settings say. Standard frames get it outside, beside the bars;
-- raid-style frames get it inside, at the right edge.
local function place(badge, frame, compact)
	local db = ns.db
	local size = db.size
	if compact then
		local height = frame:GetHeight() or 0
		local share = COMPACT_HEIGHT_SHARE * math.min(1, size / ns.DEFAULTS.size)
		size = math.max(MIN_SIZE, math.floor(height * share + 0.5))
	end
	local placed = (compact and "c" or db.side) .. size
	if badge.placed == placed then return end
	badge.placed = placed
	badge:ClearAllPoints()
	badge:SetSize(size, size)
	if compact then
		badge:SetPoint("RIGHT", frame, "RIGHT", -3, 0)
	elseif db.side == "left" then
		badge:SetPoint("RIGHT", frame, "LEFT", 3, 4)
	else
		badge:SetPoint("LEFT", frame, "RIGHT", 2, 4)
	end
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
	else
		badge.icon:SetTexture(UNKNOWN_ICON)
		badge.icon:SetDesaturated(true)
		badge:SetAlpha(0.6)
	end
	badge:Show()
end

-- Brings every party and raid frame's badge up to date. Cheap, and called often: on group
-- changes, when talents are read, when a setting changes, and every look at the group (see
-- Talents.lua), since the game hands the frames their members in its own time.
function ns.Refresh()
	if not ns.db then return end
	local inGroup = IsInGroup()
	local standard = PartyFrame and PartyFrame.PartyMemberFramePool
	if standard then
		for frame in standard:EnumerateActive() do
			update(frame, inGroup and (frame.unitToken or frame.unit), false)
		end
	end
	local done = {}
	local function compact(frame)
		if done[frame] then return end
		done[frame] = true
		update(frame, inGroup and frame.unit, true)
	end
	local party = CompactPartyFrame and CompactPartyFrame.memberUnitFrames
	if party then
		for _, frame in ipairs(party) do compact(frame) end
	end
	-- The raid frames: each entry is one member's frame, or a group of up to five of them.
	local raid = CompactRaidFrameContainer and CompactRaidFrameContainer.frameUpdateList
	raid = raid and raid.normal
	if raid then
		for _, entry in ipairs(raid) do
			if type(entry.memberUnitFrames) == "table" then
				for _, frame in ipairs(entry.memberUnitFrames) do compact(frame) end
			else
				compact(entry)
			end
		end
	end
end
