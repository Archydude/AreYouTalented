-- Are You Talented?
-- Shows each party member's talent spec on the party frames: the talent tree they put the most
-- points in. WoW Forever only: there a class has one talent tree with three groups (a warrior's
-- Arms, Fury and Protection), and the group with the most points is what players call the spec.
--
-- Files, in load order (see the .toc):
--   Core.lua      namespace, saved settings, slash command
--   Talents.lua   reading talents: the player's own, and party members' by inspecting them
--   Badges.lua    the spec icon on the party frames
--   Tooltip.lua   the spec line on player tooltips
--   Options.lua   Esc > Options > AddOns > Are You Talented?

local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.TITLE = "Are You Talented?"
ns.PREFIX = "|cff33ff99Are You Talented?|r "

function ns.Print(text)
	DEFAULT_CHAT_FRAME:AddMessage(ns.PREFIX .. text)
end

-- A value the addon can read: nil for the game's hidden ("secret") values, which can't be compared.
function ns.Plain(value)
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end

---------------------------------------------------------------------------
-- Saved settings
---------------------------------------------------------------------------

ns.DEFAULTS = {
	frames = true,     -- the spec icon on the party frames
	side = "right",    -- which side of a party frame the icon goes on: "right" | "left"
	size = 22,         -- the icon's size
	tooltip = true,    -- a spec line on player tooltips
	others = true,     -- also read players outside the party: whoever the mouse is on, and the target
	seen = {},         -- [player GUID] = { tree = trait tree ID, spent = { [group ID] = points }, at = time() }
}

-- How long a player's talents are remembered after they were last read, so party members who are
-- offline, or not read again yet after a reload or a login, still show their spec.
local KEEP_SECONDS = 3 * 24 * 60 * 60
-- The most players remembered. With players outside the party read too, a busy city adds many.
local KEEP_PLAYERS = 2000

local function validSeen(entry, now)
	return type(entry) == "table" and type(entry.tree) == "number" and type(entry.spent) == "table"
		and type(entry.at) == "number" and now - entry.at <= KEEP_SECONDS
end

local function load()
	local saved = type(AreYouTalentedDB) == "table" and AreYouTalentedDB or {}
	AreYouTalentedDB = saved
	for key, value in pairs(ns.DEFAULTS) do
		if type(saved[key]) ~= type(value) then
			saved[key] = type(value) == "table" and {} or value
		end
	end
	for key in pairs(saved) do
		if ns.DEFAULTS[key] == nil then saved[key] = nil end
	end
	if saved.side ~= "left" then saved.side = "right" end
	local now = time()
	local kept = {}
	for guid, entry in pairs(saved.seen) do
		if type(guid) ~= "string" or not validSeen(entry, now) then
			saved.seen[guid] = nil
		else
			kept[#kept + 1] = guid
		end
	end
	-- Over the limit: the ones read longest ago go.
	if #kept > KEEP_PLAYERS then
		table.sort(kept, function(a, b) return saved.seen[a].at > saved.seen[b].at end)
		for i = KEEP_PLAYERS + 1, #kept do saved.seen[kept[i]] = nil end
	end
	ns.db = saved
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
	if name ~= ADDON_NAME then return end
	self:UnregisterEvent("ADDON_LOADED")
	load()
	ns.CreateOptions()
	ns.Talents.Start()
end)

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------

local function help()
	ns.Print("commands:")
	print("  /ayt - options")
	print("  /ayt list - your party's specs, in chat")
	print("  /ayt refresh - read everyone's talents again now")
	print("  /ayt debug - say in chat what is read and when, to track down a problem; again to stop")
end

-- One chat line per party member, the player first.
local function list()
	local units = ns.Talents.Units(true)
	ns.Print(#units > 1 and "your party:" or "you:")
	for _, unit in ipairs(units) do
		local name = ns.Plain(UnitName(unit)) or unit
		local spec = ns.Talents.SpecOf(ns.Plain(UnitGUID(unit)))
		local text
		if spec then
			text = ("%s (%s)"):format(spec.name, spec.points)
		elseif spec == false then
			text = "no talent points spent"
		elseif UnitIsConnected(unit) then
			text = "not read yet"
		else
			text = "offline"
		end
		print(("  %s: %s"):format(name, text))
	end
end

SLASH_AREYOUTALENTED1 = "/ayt"
SLASH_AREYOUTALENTED2 = "/areyoutalented"
SlashCmdList.AREYOUTALENTED = function(msg)
	local command = strtrim(msg or ""):lower()
	if command == "" then
		ns.OpenOptions()
	elseif command == "list" then
		list()
	elseif command == "refresh" then
		ns.Talents.Recheck()
		ns.Print("reading your party's talents again.")
	elseif command == "debug" then
		ns.debug = not ns.debug
		ns.Print(ns.debug and "saying what is read, until you type /ayt debug again or reload." or "no longer saying what is read.")
		if ns.debug then ns.Talents.Recheck() end
	else
		help()
	end
end
