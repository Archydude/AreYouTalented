-- Are You Talented?: the spec on player tooltips
-- Adds a line like "Talents   Fury (5/41/5)" to the tooltip of a player whose talents were read:
-- party members, and the player.

local _, ns = ...

local function onUnit(tooltip, data)
	if tooltip ~= GameTooltip or not ns.db or not ns.db.tooltip then return end
	local guid = type(data) == "table" and ns.Plain(data.guid)
	if type(guid) ~= "string" then return end
	local spec = ns.Talents.SpecOf(guid)
	if not spec then return end
	tooltip:AddDoubleLine("Talents", ("%s (%s)"):format(spec.name, spec.points), 1, 0.82, 0, 1, 1, 1)
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, onUnit)
end
