-- Define default settings
local defaultSettings = {
    maxShardsToKeep = 10
}

-- Create a table to hold the settings
local settings = {}

-- Function to initialize settings
local function InitializeSettings()
    settings.maxShardsToKeep = defaultSettings.maxShardsToKeep
    local savedSettings = GetAddOnMetadata("DiShardManager", "SavedVars")
    if savedSettings then
        settings.maxShardsToKeep = savedSettings.maxShardsToKeep or defaultSettings.maxShardsToKeep
    end
end

-- Function to save settings
local function SaveSettings()
    local savedSettings = {}
    savedSettings.maxShardsToKeep = settings.maxShardsToKeep
    SetAddOnMetadata("DiShardManager", "SavedVars", savedSettings)
end

-- Function to delete excess Soul Shards
local function DeleteExcessSoulShards()
    local maxToKeep = settings.maxShardsToKeep
    local totalShards = 0
    local shardLocations = {}

    -- First pass: Count total Soul Shards and store their locations
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemLink(bag, slot)
            if item and item:find("Soul Shard") then
                totalShards = totalShards + 1
                table.insert(shardLocations, {bag = bag, slot = slot})
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

-- Function to create the settings panel
local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "DiShardManagerOptionsPanel", UIParent)
    panel.name = "DiShardManager"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("DiShardManager Settings")

    local maxShardsSlider = CreateFrame("Slider", "DiShardManagerMaxShardsSlider", panel, "OptionsSliderTemplate")
    maxShardsSlider:SetPoint("TOPLEFT", 16, -60)
    maxShardsSlider:SetMinMaxValues(1, 100)
    maxShardsSlider:SetValueStep(1)
    maxShardsSlider:SetValue(settings.maxShardsToKeep)
    maxShardsSlider:SetObeyStepOnDrag(true)
    _G[maxShardsSlider:GetName() .. "Low"]:SetText("1")
    _G[maxShardsSlider:GetName() .. "High"]:SetText("100")

    local maxShardsText = _G[maxShardsSlider:GetName() .. "Text"]
    maxShardsText:SetText("Max Shards to Keep: " .. settings.maxShardsToKeep)

    maxShardsSlider:SetScript("OnValueChanged", function(self, value)
        settings.maxShardsToKeep = math.floor(value)
        maxShardsText:SetText("Max Shards to Keep: " .. settings.maxShardsToKeep)
    end)

    InterfaceOptions_AddCategory(panel)
end

-- Function to handle slash commands
local function SlashCommandHandler(msg)
    if msg == "delete" then
        DeleteExcessSoulShards()
    elseif msg == "settings" then
        InterfaceOptionsFrame_OpenToCategory("DiShardManager")
    else
        print("Usage: /dism [delete|settings]")
    end
end

-- Register the slash command
SLASH_DISHARDMANAGER1 = "/dism"
SlashCmdList["DISHARDMANAGER"] = SlashCommandHandler

-- Initialize settings and create UI elements
InitializeSettings()
CreateOptionsPanel()
