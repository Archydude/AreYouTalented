-- Are You Talented?: the spec on player tooltips
-- Adds a line like "Talents   Fury (5/41/5)" to the tooltip of a player whose talents were read:
-- party members, the player, and other players the mouse was on or who were targeted.

local _, ns = ...

local lineFor  -- the player whose Talents line the tooltip has now, or nil
local lineText -- the spec text shown on that line, so a respec updates it

local function specText(guid)
	local spec = ns.Talents.SpecOf(guid)
	return spec and ("%s (%s)"):format(spec.name, spec.points) or nil
end

local function addLine(tooltip, guid)
	local text = specText(guid)
	if not text then return false end
	tooltip:AddDoubleLine("Talents", text, 1, 0.82, 0, 1, 1, 1)
	lineFor, lineText = guid, text
	return true
end

local function onUnit(tooltip, data)
	if tooltip ~= GameTooltip then return end
	lineFor, lineText = nil, nil
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
-- or with an older spec before a respec, it updates now so the mouse doesn't have to leave.
function ns.TooltipRead(guid)
	if not ns.db.tooltip or shownPlayer() ~= guid then return end
	if lineFor == guid then
		local text = specText(guid)
		if text and text ~= lineText then
			if GameTooltip.RefreshData then
				GameTooltip:RefreshData()
			elseif GameTooltip.NumLines then
				for i = 1, GameTooltip:NumLines() do
					local left = _G["GameTooltipTextLeft" .. i]
					local right = _G["GameTooltipTextRight" .. i]
					if left and right and left:GetText() == "Talents" then
						right:SetText(text)
						lineText = text
						GameTooltip:Show()
						break
					end
				end
			end
		end
		return
	end
	if addLine(GameTooltip, guid) then GameTooltip:Show() end
end
