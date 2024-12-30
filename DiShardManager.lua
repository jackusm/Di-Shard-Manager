local _, AddOn = ...
local Settings = {}
Settings.DefaultSettings = {
	["maxShardsToKeep"] = 10,
	["maxShardBagSlots"] = 0,
}
Settings.Options = {}
AddOn.Settings = Settings

-- Settings Handlers
function AddOn.AddOptionsCategory(name)
	local category, layout = _G.Settings.RegisterVerticalLayoutCategory(name)
	_G.Settings.RegisterAddOnCategory(category)
	return category
end
function AddOn.OnSettingChanged(_, setting, value)
	local variable = setting:GetVariable()
	Settings.Options[variable] = value
end

-- Settings Initialization
Settings.Interface = {
	GeneralPanel = AddOn.AddOptionsCategory("DiShardManager"),
}
function Settings.Setup()
	do
		local variable = "maxShardsToKeep"
		local name = "Maximum Shards"
		local tooltip = "The maximum number of shards to keep."
		local defaultValue = Settings.DefaultSettings[variable]
		local currentValue = Settings.Options[variable]
		local minValue = 0
		local maxValue = 50
		local step = 1

		local setting = _G.Settings.RegisterAddOnSetting(
			Settings.Interface.GeneralPanel,
			variable,
			variable,
			Settings.Options,
			type(defaultValue),
			name,
			defaultValue
		)
		local options = _G.Settings.CreateSliderOptions(minValue, maxValue, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
		_G.Settings.SetValue(variable, currentValue)
		_G.Settings.CreateSlider(Settings.Interface.GeneralPanel, setting, options, tooltip)
		_G.Settings.SetOnValueChangedCallback(variable, AddOn.OnSettingChanged)
	end
end

local function FindSoulBagSlots()
	local shardCapacity = 0
	for i = 1, NUM_BAG_SLOTS do
		local name, link, rarity, level, minLevel, type, subType = GetItemInfo(C_Container.GetBagName(i))

		if subType == "Soul Bag" then
			shardCapacity = shardCapacity + C_Container.GetContainerNumSlots(i)
			print("Soul Bag found: " .. shardCapacity)
		end
	end
	Settings.DefaultSettings.maxShardBagSlots = shardCapacity
	return shardCapacity
end

-- Function to delete excess Soul Shards
local function DeleteExcessSoulShards()
	local maxToKeep = Settings.Options["maxShardsToKeep"]
	local shardCapacity = FindSoulBagSlots()
	if shardCapacity > 0 then
		maxToKeep = shardCapacity
	end

	local totalShards = 0
	local shardLocations = {}

	-- First pass: Count total Soul Shards and store their locations
	for bag = 0, 4 do
		for slot = 1, C_Container.GetContainerNumSlots(bag) do
			local item = C_Container.GetContainerItemLink(bag, slot)
			if item and item:find("Soul Shard") then
				totalShards = totalShards + 1
				table.insert(shardLocations, { bag = bag, slot = slot })
			end
		end
	end

	-- Calculate number of shards to delete
	local excessShards = totalShards - maxToKeep

	-- Function to delete a single shard, used recursively
	local function DeleteNextShard(index)
		if index > excessShards then
			return
		end

		local location = shardLocations[index]
		if location then
			C_Container.PickupContainerItem(location.bag, location.slot)
			DeleteCursorItem()
		end

		-- C_Timer.After(0.5, function() DeleteNextShard(index + 1) end)
	end

	-- Start the deletion process
	if totalShards > maxToKeep then
		DeleteNextShard(1)
	end
end

-- Register the slash command
SLASH_DISHARDMANAGER1 = "/dism"
SlashCmdList["DISHARDMANAGER"] = function(msg)
	local command, value = strsplit(" ", msg)

	if msg == "delete" then
		DeleteExcessSoulShards()
	elseif msg == "settings" then
		_G.SettingsPanel:Open()
		_G.SettingsPanel:SelectCategory(Settings.Interface.GeneralPanel, true)
	elseif command == "max" then
		local num = tonumber(value)
		if num and num >= 0 then
			Settings.Options["maxShardsToKeep"] = num
		end
	else
		print("Usage: /dism [delete|settings]")
	end
end

-- Event Handlers
function AddOn:ADDON_LOADED(addon)
	if not addon == "DiShardManager" then
		return
	end

	AddOn.eventFrame:UnregisterEvent("ADDON_LOADED")

	Settings.Options = _G["DiShardManager_Settings"] or Settings.DefaultSettings
	Settings.Setup()
end
function AddOn:PLAYER_LOGOUT(addon)
	_G["DiShardManager_Settings"] = Settings.Options
end

-- Register Events
AddOn.eventFrame = CreateFrame("Frame", nil, UIParent)
AddOn.eventFrame:SetScript("OnEvent", function(self, event, ...)
	if AddOn[event] then
		AddOn[event](AddOn, ...)
	end
end)
AddOn.eventFrame:RegisterEvent("ADDON_LOADED")
AddOn.eventFrame:RegisterEvent("PLAYER_LOGOUT")
