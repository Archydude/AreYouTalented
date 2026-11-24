-- Are You Talented?: reading talents
-- The player's own talents are read directly. A party or raid member's are read by inspecting
-- them, one member at a time, out of combat. So are those of any other player the mouse is on or who is
-- targeted, for their tooltip. What was read is kept (ns.db.seen) so it still shows when the
-- member is offline, and right after a reload or a login.
--
-- WoW Forever lets a player be inspected from any distance, so there is no range check.
--
-- On WoW Forever a class has one trait tree whose node groups are the three talent trees. The
-- points spent in each group say what the spec is: the group with the most points.

local _, ns = ...

local Talents = {}
ns.Talents = Talents

-- The trait config the game fills with the inspected player's talents.
local INSPECT_CONFIG = Constants and Constants.TraitConsts and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID or -1

local TICK = 1.5      -- seconds between looks at the party: at most one inspect request per look
local TIMEOUT = 4     -- seconds to wait for an inspect answer before asking for someone else's
local RECHECK = 60    -- seconds before a party member's talents are read again, to catch a respec
local RAID_RECHECK = 300 -- the same in a raid, where there are many more members to get through
local RAID_SIZE = 40
local RETRY = 10      -- seconds before asking again about a member who didn't answer
local OTHER_RECHECK = 300 -- seconds before a player outside the party is read again
local HOVER_DELAY = 0.3   -- seconds the mouse has to stay on a player before their talents are asked for
local GAP = 1             -- seconds between two requests, at least

local pending         -- the request waiting for its answer: { guid = , sent = GetTime() }

-- With /ayt debug on, says in chat what is asked for and what comes back.
local function note(...)
	if ns.debug then ns.Print(("|cff999999" .. (...) .. "|r"):format(select(2, ...))) end
end
local checked = {}    -- [guid] = GetTime() of the last answer
local tried = {}      -- [guid] = GetTime() of the last request
local lastSent = 0    -- GetTime() of the last request to anyone
local whyNot = {}     -- [guid] = why the last try to read them came to nothing (a key of WHY_NOT)

-- For /ayt list, after "not read yet: ".
local WHY_NOT = {
	refused = "the game won't let you inspect them from where you are",
	silent = "the game didn't answer",
	empty = "the game answered without their talents",
	unreadable = "their talents couldn't be read",
}

---------------------------------------------------------------------------
-- Trees and points
---------------------------------------------------------------------------

local groupsByTree = {}

-- A trait tree's talent trees in the talent window's order: { { id = , name = , icon = }, ... }, or nil.
local function groupsOf(treeID)
	local groups = groupsByTree[treeID]
	if groups then return groups end
	if treeID == 0 then return end
	local ok, displays = pcall(C_Traits.GetGroupDisplayInfoByTreeID, treeID)
	if not ok or type(displays) ~= "table" then return end
	groups = {}
	for _, display in ipairs(displays) do
		local id, name = ns.Plain(display.groupID), ns.Plain(display.displayName)
		if type(id) == "number" then
			groups[#groups + 1] = {
				id = id,
				name = type(name) == "string" and name or "",
				icon = ns.Plain(display.icon),
				order = tonumber(ns.Plain(display.orderIndex)) or #groups,
			}
		end
	end
	if #groups == 0 then return end
	table.sort(groups, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.id < b.id
	end)
	groupsByTree[treeID] = groups
	return groups
end

-- The talents in a trait config, as saved in ns.db.seen. When the game has none to give: nil and why.
local function readConfig(configID)
	local config = C_Traits.GetConfigInfo(configID)
	local treeID = type(config) == "table" and type(config.treeIDs) == "table" and ns.Plain(config.treeIDs[1])
	if type(treeID) ~= "number" then return nil, "the game gave no talent tree" end
	local groups = groupsOf(treeID)
	if not groups then return nil, "talent tree " .. treeID .. " has no trees in it" end
	local ids = {}
	for i, group in ipairs(groups) do ids[i] = group.id end
	local infos = C_Traits.GetGroupCurrencyInfo(configID, ids)
	if type(infos) ~= "table" then return nil, "the game gave no talent points" end
	-- A tree with no points in it can be missing from the answer.
	local spent = {}
	for _, info in ipairs(infos) do
		local id = ns.Plain(info.traitNodeGroupID)
		local currency = type(info.currencyInfos) == "table" and info.currencyInfos[1]
		local points = type(currency) == "table" and ns.Plain(currency.spent)
		if type(id) == "number" and type(points) == "number" then spent[id] = points end
	end
	return { tree = treeID, spent = spent, at = time() }
end

local function read(configID)
	local ok, entry, why = pcall(readConfig, configID)
	if not ok then return nil, tostring(entry) end
	return entry, why
end

-- What to show for a player: { name = "Fury", icon = file, points = "5/41/5" }; false when their
-- talents were read and no points are spent; nil when their talents haven't been read.
function Talents.SpecOf(guid)
	local entry = type(guid) == "string" and ns.db.seen[guid]
	if not entry then return nil end
	local groups = groupsOf(entry.tree)
	if not groups then return nil end
	local best, most, points = nil, 0, {}
	for i, group in ipairs(groups) do
		local n = tonumber(entry.spent[group.id]) or 0
		points[i] = n
		if n > most then best, most = group, n end
	end
	if not best then return false end
	return { name = best.name, icon = best.icon, points = table.concat(points, "/") }
end

---------------------------------------------------------------------------
-- The group: a party or a raid
---------------------------------------------------------------------------

-- The unit tokens of the other members of the player's party or raid, after "player" when asked for.
function Talents.Units(withPlayer)
	local units = {}
	if withPlayer then units[1] = "player" end
	if IsInRaid() then
		for i = 1, RAID_SIZE do
			local unit = "raid" .. i
			if UnitExists(unit) and not UnitIsUnit(unit, "player") then units[#units + 1] = unit end
		end
	elseif IsInGroup() then
		for i = 1, MAX_PARTY_MEMBERS or 4 do
			local unit = "party" .. i
			if UnitExists(unit) then units[#units + 1] = unit end
		end
	end
	return units
end

local function recheckAfter()
	return IsInRaid() and RAID_RECHECK or RECHECK
end

local function inParty(guid)
	for _, unit in ipairs(Talents.Units()) do
		if ns.Plain(UnitGUID(unit)) == guid then return true end
	end
	return false
end

---------------------------------------------------------------------------
-- The player's own talents
---------------------------------------------------------------------------

local function ownConfig()
	local id = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
	local info = C_SpecializationInfo
	if not id and info and info.GetActiveSpecGroup and info.GetCombatConfigIDForSpecGroup then
		id = info.GetCombatConfigIDForSpecGroup(info.GetActiveSpecGroup())
	end
	return id
end

local function readOwn()
	local guid = ns.Plain(UnitGUID("player"))
	if type(guid) ~= "string" then return end
	local ok, configID = pcall(ownConfig)
	configID = ok and ns.Plain(configID)
	if type(configID) ~= "number" then return end
	local entry = read(configID)
	if not entry then return end
	ns.db.seen[guid] = entry
	ns.Refresh()
end

-- The talent events come in bursts, and before the game has settled on the new talents.
local ownQueued = false
local function readOwnSoon()
	if ownQueued then return end
	ownQueued = true
	C_Timer.After(0.5, function()
		ownQueued = false
		readOwn()
	end)
end

---------------------------------------------------------------------------
-- Party members' talents
---------------------------------------------------------------------------

local function wanted()
	return ns.db.frames or ns.db.tooltip
end

-- Whether the player is looking at someone in the inspect window or their talents. A request of
-- ours would replace what those windows show, so they go first.
local askedUnit, askedSince -- the unit and time the inspect window first waited for an answer
local function playerInspecting()
	if InspectFrame then
		if InspectFrame:IsShown() then
			askedUnit, askedSince = nil, nil
			return true
		end
		-- The player just asked to inspect someone and the window opens when the answer comes.
		-- An answer that never comes doesn't hold us up for long.
		local unit = ns.Plain(InspectFrame.unit)
		if unit then
			if unit ~= askedUnit then askedUnit, askedSince = unit, GetTime() end
			if GetTime() - askedSince < TIMEOUT then return true end
		else
			askedUnit, askedSince = nil, nil
		end
	end
	local spells = PlayerSpellsFrame
	return spells and spells:IsShown() and spells.IsInspecting and spells:IsInspecting() and true or false
end

local function clearInspect()
	if ClearInspectPlayer and not playerInspecting() then ClearInspectPlayer() end
end

local function request(unit, guid, now, isParty)
	tried[guid] = now
	lastSent = now
	pending = { guid = guid, sent = now, party = isParty }
	note("asking for %s's talents", tostring(ns.Plain(UnitName(unit)) or unit))
	NotifyInspect(unit)
end

local function tick()
	ns.Refresh()
	if not wanted() or InCombatLockdown() or playerInspecting() then return end
	local now = GetTime()
	if pending then
		if now - pending.sent < TIMEOUT then return end
		note("no answer in %d seconds", TIMEOUT)
		whyNot[pending.guid] = "silent"
		pending = nil
		clearInspect()
	end
	if now - lastSent < GAP then return end
	local recheck = recheckAfter()
	for _, unit in ipairs(Talents.Units()) do
		local guid = ns.Plain(UnitGUID(unit))
		if type(guid) == "string" and UnitIsConnected(unit)
			and (not checked[guid] or now - checked[guid] >= recheck)
			and (not tried[guid] or now - tried[guid] >= RETRY) then
			if CanInspect(unit, false) then
				request(unit, guid, now, true)
				return
			end
			whyNot[guid] = "refused"
		end
	end
end

-- Why a member's talents haven't been read, in words, or nil when nothing went wrong yet.
function Talents.WhyNot(guid)
	if InCombatLockdown() then return "talents aren't read while you're in combat" end
	return WHY_NOT[whyNot[guid]]
end

---------------------------------------------------------------------------
-- Other players: whoever the mouse is on, and the target
---------------------------------------------------------------------------

local function othersWanted()
	return ns.db.tooltip and ns.db.others
end

local wantOther = {}      -- [unit ("mouseover" | "target")] = guid, so hovering doesn't clobber a queued target
local otherQueued = false -- whether a look at wantOther is on its way

local function pickWanted()
	for _, unit in ipairs({ "mouseover", "target" }) do
		local guid = wantOther[unit]
		if guid then
			if ns.Plain(UnitGUID(unit)) == guid then
				return unit, guid
			end
			wantOther[unit] = nil
		end
	end
end

local function tryOther()
	otherQueued = false
	if not othersWanted() or InCombatLockdown() then
		wipe(wantOther)
		return
	end
	local unit, guid = pickWanted()
	if not unit then return end
	local now = GetTime()
	local wait = 0
	if playerInspecting() then
		wait = 1
	elseif pending and now - pending.sent < TIMEOUT then
		wait = 0.5
	elseif now - lastSent < GAP then
		wait = GAP - (now - lastSent)
	end
	if wait > 0 then
		otherQueued = true
		C_Timer.After(wait + 0.05, tryOther)
		return
	end
	wantOther[unit] = nil
	if CanInspect(unit, false) then request(unit, guid, now, false) end
	if next(wantOther) and not otherQueued then
		otherQueued = true
		C_Timer.After(GAP + 0.05, tryOther)
	end
end

-- The mouse went onto a unit, or the target changed: a player whose talents aren't known, or
-- were read a while ago, gets asked about once the mouse has stayed a moment.
local function consider(unit)
	if not othersWanted() or InCombatLockdown() then return end
	if not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then return end
	local guid = ns.Plain(UnitGUID(unit))
	if type(guid) ~= "string" then return end
	local now = GetTime()
	if checked[guid] and now - checked[guid] < (inParty(guid) and recheckAfter() or OTHER_RECHECK) then return end
	if tried[guid] and now - tried[guid] < RETRY then return end
	wantOther[unit] = guid
	if not otherQueued then
		otherQueued = true
		C_Timer.After(HOVER_DELAY, tryOther)
	end
end

-- The game has a player's inspect data: ours to read whoever asked for it, when they're in the
-- party or other players' talents are wanted too.
local function onInspectReady(guid)
	guid = ns.Plain(guid)
	if type(guid) ~= "string" then return end
	local ours = pending and pending.guid == guid
	if ours then pending = nil end
	if not ours and not inParty(guid) and not othersWanted() then return end
	-- The answer can come without talents in it; then the game still holds the talents of whoever
	-- was inspected before, and those aren't this player's.
	if C_Traits.HasValidInspectData and not C_Traits.HasValidInspectData() then
		note("an answer came without talents in it")
		whyNot[guid] = "empty"
		if ours then clearInspect() end
		return
	end
	local entry, why = read(INSPECT_CONFIG)
	if not entry then
		note("couldn't read the answer: %s", tostring(why))
		whyNot[guid] = "unreadable"
		if ours then clearInspect() end
		return
	end
	if ours then clearInspect() end
	checked[guid] = GetTime()
	whyNot[guid] = nil
	ns.db.seen[guid] = entry
	local spec = Talents.SpecOf(guid)
	note("read talents: %s", spec and (spec.name .. " " .. spec.points) or "no points spent")
	ns.Refresh()
	ns.TooltipRead(guid)
end

-- Reads everyone's talents again as soon as they can be.
function Talents.Recheck()
	wipe(checked)
	wipe(tried)
	wipe(whyNot)
	readOwn()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local ticker

-- Looks at the party or raid only while there is one.
local function sync()
	local inGroup = IsInGroup()
	if inGroup and not ticker then
		ticker = C_Timer.NewTicker(TICK, tick)
	elseif not inGroup and ticker then
		ticker:Cancel()
		ticker = nil
		if pending and pending.party then pending = nil end
	end
	-- The party frames get their members on the same event; the icons follow right after.
	C_Timer.After(0.2, ns.Refresh)
end

-- Events that say the player's own talents changed. Not every one exists on every client.
local OWN_EVENTS = {
	"TRAIT_CONFIG_UPDATED", "ACTIVE_COMBAT_CONFIG_CHANGED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
}

function Talents.Start()
	local frame = CreateFrame("Frame")
	local own = {}
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("GROUP_ROSTER_UPDATE")
	frame:RegisterEvent("INSPECT_READY")
	frame:RegisterEvent("READY_CHECK")
	frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	for _, event in ipairs(OWN_EVENTS) do
		own[event] = pcall(frame.RegisterEvent, frame, event)
	end
	frame:SetScript("OnEvent", function(_, event, ...)
		if event == "INSPECT_READY" then
			onInspectReady(...)
		elseif event == "READY_CHECK" then
			wipe(checked)
		elseif event == "UPDATE_MOUSEOVER_UNIT" then
			consider("mouseover")
		elseif event == "PLAYER_TARGET_CHANGED" then
			consider("target")
		elseif own[event] then
			readOwnSoon()
		else
			sync()
			if event == "PLAYER_ENTERING_WORLD" then readOwnSoon() end
		end
	end)
	sync()
	readOwnSoon()
end
