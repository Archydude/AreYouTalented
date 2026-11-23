-- Are You Talented?: the spec on player tooltips
-- Adds a line like "Talents   Fury (5/41/5)" to the tooltip of a player whose talents were read:
-- party members, the player, and other players the mouse was on or who were targeted.

local _, ns = ...

local lineFor -- the player whose Talents line the tooltip has now, or nil

local function addLine(tooltip, guid)
	local spec = ns.Talents.SpecOf(guid)
	if not spec then return false end
	tooltip:AddDoubleLine("Talents", ("%s (%s)"):format(spec.name, spec.points), 1, 0.82, 0, 1, 1, 1)
	lineFor = guid
	return true
end

local function onUnit(tooltip, data)
	if tooltip ~= GameTooltip then return end
	lineFor = nil
	if not ns.db or not ns.db.tooltip then return end
	local guid = type(data) == "table" and ns.Plain(data.guid)
	if type(guid) == "string" then addLine(tooltip, guid) end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onUnit)
end

-- The player the tooltip is showing now, or nil.
local function shownPlayer()
	if not GameTooltip:IsShown() or not GameTooltip.GetUnit then return end
	local ok, _, unit, guid = pcall(GameTooltip.GetUnit, GameTooltip)
	if not ok then return end
	guid = ns.Plain(guid)
	unit = ns.Plain(unit)
	if type(guid) ~= "string" and type(unit) == "string" then guid = ns.Plain(UnitGUID(unit)) end
	return type(guid) == "string" and guid or nil
end

-- A player's talents were just read. When the tooltip is showing that player without the line,
-- it gets the line now, so the mouse doesn't have to leave and come back.
function ns.TooltipRead(guid)
	if not ns.db.tooltip or lineFor == guid or shownPlayer() ~= guid then return end
	if addLine(GameTooltip, guid) then GameTooltip:Show() end
end
