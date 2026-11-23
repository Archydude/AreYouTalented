-- Are You Talented?: options
-- Esc > Options > AddOns > Are You Talented?.

local _, ns = ...

local category

-- The game doesn't let addons open its settings during combat, so a request then waits for the fight to end.
local openAfterCombat = false
local combatWatch = CreateFrame("Frame")
combatWatch:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	openAfterCombat = false
	ns.OpenOptions()
end)

function ns.OpenOptions()
	if not category then return end
	if InCombatLockdown() then
		if not openAfterCombat then
			openAfterCombat = true
			combatWatch:RegisterEvent("PLAYER_REGEN_ENABLED")
			ns.Print("the options open when you leave combat.")
		end
		return
	end
	Settings.OpenToCategory(category:GetID())
end

local MIN_SIZE, MAX_SIZE = 12, 40

function ns.CreateOptions()
	local layout
	category, layout = Settings.RegisterVerticalLayoutCategory(ns.TITLE)
	local VarType = Settings.VarType or { Boolean = "boolean", String = "string", Number = "number" }

	local function setting(key, varType, name)
		local s = Settings.RegisterAddOnSetting(category, "AREYOUTALENTED_" .. key:upper(), key, ns.db, varType, name,
			ns.DEFAULTS[key])
		s:SetValueChangedCallback(function() ns.Refresh() end)
		return s
	end

	-- Like Settings.CreateCheckbox / CreateDropdown / CreateSlider, but on our own row templates
	-- (see Options.xml). On Blizzard's templates, a row that drew one of our settings is later
	-- reused for Blizzard's own, which then can't call protected functions: its Discord
	-- dropdown and button get blocked (ADDON_ACTION_FORBIDDEN on IsUserOAuthed).
	local function control(kind, s, options, tooltip)
		layout:AddInitializer(Settings.CreateControlInitializer("AreYouTalentedSettings" .. kind .. "Template", s,
			options, tooltip))
	end

	local function checkbox(key, name, tooltip)
		control("Checkbox", setting(key, VarType.Boolean, name), nil, tooltip)
	end

	local function dropdown(key, name, choices, tooltip)
		local function getOptions()
			local container = Settings.CreateControlTextContainer()
			for _, choice in ipairs(choices) do container:Add(choice[1], choice[2]) end
			return container:GetData()
		end
		control("Dropdown", setting(key, VarType.String, name), getOptions, tooltip)
	end

	checkbox("frames", "Show specs on party frames",
		"Put an icon of each party member's spec on their party frame: the talent tree they put the most points in. "
			.. "A grey question mark means their talents haven't been read yet; that happens within a few seconds, once you're out of combat.")
	checkbox("name", "Spec name next to the icon",
		"Write the spec's name next to the icon, like \"Fury\". Raid-style party frames have no room for it and show the icon only.")
	checkbox("points", "Talent points next to the icon",
		"Write the points in each talent tree next to the icon, like \"5/41/5\". Raid-style party frames show the icon only.")
	dropdown("side", "Icon side", {
		{ "right", "Right of the party frame" },
		{ "left", "Left of the party frame" },
	}, "Which side of a party frame the icon goes on. On raid-style party frames it's always inside the frame, at its right edge.")
	local sizeOptions = Settings.CreateSliderOptions(MIN_SIZE, MAX_SIZE, 1)
	sizeOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
		return tostring(math.floor(value + 0.5))
	end)
	control("Slider", setting("size", VarType.Number, "Icon size"), sizeOptions,
		"How big the icon is. Raid-style party frames shrink it to fit inside the frame.")
	checkbox("tooltip", "Show specs on player tooltips",
		"Add a line like \"Talents: Fury (5/41/5)\" to the tooltip of a player whose talents were read: your party members, and you.")

	Settings.RegisterAddOnCategory(category)
end
