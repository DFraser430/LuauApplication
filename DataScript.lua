-- I didn't comment the areas where I repeat myself in the script because I didn't think that would be nescessary

local Players = game:GetService("Players")
local PlayerDataStore = game:GetService("DataStoreService"):GetDataStore("PlayerData")
local LeaderboardRollsData = game:GetService("DataStoreService"):GetOrderedDataStore("LeaderboardData")
local AuraDataStore = game:GetService("DataStoreService"):GetDataStore("AuraDataStore")
local ItemDataStore = game:GetService("DataStoreService"):GetDataStore("ItemDataStore")
local PurchasesDataStore = game:GetService("DataStoreService"):GetDataStore("PurchasesDataStore")
local SettingsDataStore = game:GetService("DataStoreService"):GetDataStore("SettingsDataStore")
local CraftingDataStore = game:GetService("DataStoreService"):GetDataStore("PlayerCraftingDataStore")
local BadgesDataStore = game:GetService("DataStoreService"):GetDataStore("BadgesDataStore")
local AuraModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("AuraModule"))
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents")
local AntiCheatDetector = require(game:GetService("ReplicatedStorage"):WaitForChild("AntiCheat"):WaitForChild("Detector")).SetUp()
local AuraList = game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("AuraList")
local GlobalFunctions = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("_GFunctions"))
local Crafting = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CraftingModule"))
local RequestEvent = Remotes:WaitForChild("RequestData")
local RequestModuleEvent = Remotes:WaitForChild("RequestModuleData")
local GearsModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GearModule")) -- Defining the variables I will use later
local Developers = {
	"BreifBoos1",
	"Iceyy"
}
local DEFAULT_SETTINGS = { -- Default settings values
	{Name = "AutoEquipNumber", DefaultValue = "-1", Type = "NumberValue"},
	{Name = "NotificationsEnabled", DefaultValue = "true", Type = "BoolValue"},
	{Name = "MusicVolume", DefaultValue = "1", Type = "NumberValue"}
}
local DEFAULT_PLAYER_STATS = { -- Same thing as default settings but player's stats
	{Name = "QuickRollOn", DefaultValue = false, Type = "BoolValue"}
}
local BadgesConfig = require(script:WaitForChild("BadgesConfig"))

for i, v in pairs(GlobalFunctions) do
	_G[i] = v
end

local function SetAttributes(Plr) -- Setting all attributes for the player using one function
	Plr:SetAttribute("InCutscene", false)
	Plr:SetAttribute("AutoRoll", false)
	Plr:SetAttribute("InLoadingScreen", true)
end

local function SetUpCraftingData(Player) -- Uses the Crafting module to set up the data (load the layout) then load saved data if any
	Crafting.SetUpData(Player)
	Crafting.Load(Player, CraftingDataStore)
end

Players.PlayerAdded:Connect(function(Player) -- Player joined
	SetAttributes(Player) -- Calling functions defined earlier
	SetUpCraftingData(Player)
	
	local Character = Player.Character or Player.CharacterAdded:Wait() -- Define player's character 
	
	local AuraListClone = AuraList:Clone() -- Clones a module that stores the auras the player can roll onto the player
	AuraListClone.Parent = Player
	
	local DataModuleClone = script:WaitForChild("PlayerData"):Clone() -- Data module layout set up
	DataModuleClone.Parent = Player
	
	local EquippedAura = Instance.new("StringValue", Player) -- Create the data layout and then load the data onto instances
	EquippedAura.Name = "EquippedAura"
	
	local RollSpeed = Instance.new("NumberValue", Player)
	RollSpeed.Name = "RollCooldown"
	RollSpeed.Value = 2
	
	local PlayerStats = Instance.new("Folder", Player)
	PlayerStats.Name = "PlayerStats"
	
	local leaderstats = Instance.new("Folder", Player)
	leaderstats.Name = "leaderstats"
	
	for stat, value in pairs(DEFAULT_PLAYER_STATS) do
		local StatsInst = Instance.new(value.Type)
		StatsInst.Name = value.Name
		StatsInst.Value = value.DefaultValue
		StatsInst.Parent = PlayerStats
	end
	
	local EquippedGear = Instance.new("StringValue", Player)
	EquippedGear.Name = "EquippedGear"
	
	local AuraFolder = Instance.new("Folder", Player)
	AuraFolder.Name = "AuraFolder"
	
	local SettingsFolder = Instance.new("Folder", Player)
	SettingsFolder.Name = "SettingsFolder"
	
	if #SettingsFolder:GetChildren() == 0 then -- Check if the settingsfolder has any children (if not default settings are applied)
		local SettingInstance
		
		for setting, value in pairs(DEFAULT_SETTINGS) do
			SettingInstance = Instance.new(value.Type)
			SettingInstance.Name = value.Name
			SettingInstance.Value = value.DefaultValue
			SettingInstance.Parent = SettingsFolder
		end
	end
	
	local ItemFolder = Instance.new("Folder", Player)
	ItemFolder.Name = "ItemFolder"
	
	local GearFolder = Instance.new("Folder", Player)
	GearFolder.Name = "GearFolder"

	local Purchases = Instance.new("Folder", Player)
	Purchases.Name = "Purchases"
	
	local BuffsFolder = Instance.new("Folder", Player)
	BuffsFolder.Name = "BuffsFolder"
	
	local Badges = Instance.new("Folder", Player)
	Badges.Name = "Badges"
	
	for _, v in pairs(BadgesConfig) do -- Load every badge in the BadgesConfig module into the Badges folder in the player
		local Badge = Instance.new("BoolValue")
		Badge.Name = v
		Badge.Value = false
		Badge.Parent = Badges
		
		if Badge.Name == "Grandmaster" then -- Special case for badge "Grandmaster"
			local Place = Instance.new("NumberValue")
			Place.Name = "Place"
			Place.Parent = Badge
		end
	end
	
	local Coins = Instance.new("NumberValue", Player)
	Coins.Name = "Coins"
	Coins.Value = 0
	
	local FirstTimeJoining = Instance.new("BoolValue", Player)
	FirstTimeJoining.Name = "FirstTimeJoining"
	FirstTimeJoining.Value = true
	
	local Rolls = Instance.new("NumberValue", leaderstats)
	Rolls.Name = "Rolls"
	Rolls.Value = 0
	
	local MaxAuras = Instance.new("NumberValue", Player)
	MaxAuras.Name = "MaxAuras"
	MaxAuras.Value = 6
	
	local TotalAuras = Instance.new("NumberValue", Player)
	TotalAuras.Name = "TotalAuras"
	TotalAuras.Value = 0
	
	local Luck = Instance.new("NumberValue", Player)
	Luck.Name = "Luck"
	Luck.Value = 1
	
	local Success, Data = pcall(function() -- Get saved data from datastores
		return PlayerDataStore:GetAsync(Player.UserId)
	end)
	
	local AuraSuccess, AuraData = pcall(function()
		return AuraDataStore:GetAsync(Player.UserId)
	end)
	
	local SettingsSuccess, SettingsData = pcall(function()
		return SettingsDataStore:GetAsync(Player.UserId)
	end)
	
	local PurchasesSuccess, PurchaseData = pcall(function()
		return PurchasesDataStore:GetAsync(Player.UserId)
	end)
	
	local Items, ItemData = pcall(function()
		return ItemDataStore:GetAsync(Player.UserId)
	end)
	
	local BadgesSaved, BadgesData = pcall(function()
		return BadgesDataStore:GetAsync(Player.UserId)
	end)
	
	for i, v in pairs(BadgesData) do -- Load the saved value (true or false) onto the badges
		if Player:WaitForChild("Badges"):FindFirstChild(v.Badge) then
			Player:WaitForChild("Badges"):FindFirstChild(v.Badge).Value = v.Value
		end
	end
	
	if not ItemData then
		warn("Couldn't fetch item data for "..Player.Name)
	elseif Items and ItemData then -- Load items into the player's ItemFolder with the saved name and value
		for itemIndex, item in pairs(ItemData) do
			local ItemInstance
			ItemInstance = Instance.new("NumberValue", ItemFolder)
			ItemInstance.Name = item.ItemName
			ItemInstance.Value = item.ItemAmount
		end
	end
	
	if not PurchaseData then
		warn("Couldn't find purchase data for "..Player.Name)
	elseif PurchasesSuccess and PurchaseData then -- Same thing as before with the items but this time with saved purchases
		for i, v in pairs(PurchaseData) do
			local PurchaseInstanace
			PurchaseInstanace = Instance.new("StringValue", Player:WaitForChild("Purchases"))
			PurchaseInstanace.Name = v
		end
	end
	
	if not SettingsData then
		warn("Setting data not loaded")
	elseif SettingsData and SettingsSuccess then
		for settingsIndex, settingsValue in pairs(SettingsData) do
			if SettingsFolder:FindFirstChild(settingsValue.Name) then
				SettingsFolder:FindFirstChild(settingsValue.Name).Value = settingsValue.Value
			end
		end
	end
	
	if not AuraData then
		warn("Aura data not loaded")
	elseif AuraData and AuraSuccess then -- auraValue is saved as a table, so we use indexes [1], [2] to determine the saved name and value
		for auraIndex, auraValue in pairs(AuraData) do
			local AuraInstance
			AuraInstance = Instance.new("NumberValue", Player:WaitForChild("AuraFolder"))
			AuraInstance.Name = auraValue[1]
			AuraInstance.Value = auraValue[2]
		end
	end
	
	if not Data then
		warn("Data not found for "..Player.Name)
	elseif Success and Data then -- Find the last equipped aura data for the specific player
		if Data.EquippedAuraValue and Data.EquippedAuraValue ~= "" then -- If there is a value found and it isn't a blank string we continue with the logic
			if Player:WaitForChild("AuraFolder"):FindFirstChild(Data.EquippedAuraValue) and Player:WaitForChild("AuraFolder"):FindFirstChild(Data.EquippedAuraValue).Value > 0 then -- Checking if the player owns the aura in the designated folder and also if they have more than 0 of that specific aura
				Player:WaitForChild("EquippedAura").Value = Data.EquippedAuraValue -- Load the saved value onto the player's EquippedAura value
				AuraModule.EquipAuraToCharacter(Character, Data.EquippedAuraValue) -- Use the EquipAuraToCharacter function from the module to equip the saved aura onto the player when they join
			end
		else
			warn("Failed to load LAST_EQUIPPED_AURA") -- If the condition is false
		end
		
		if Data.Coins and Data.Coins ~= "" then
			Player:WaitForChild("Coins").Value = Data.Coins -- Load the last saved amount of coins from the data
		else
			warn("Failed to load PLAYER_COINS")
		end
		
		if Data.Rolls and Data.Rolls ~= "" then
			Player:WaitForChild("leaderstats"):WaitForChild("Rolls").Value = Data.Rolls
		else
			warn("Failed to load PLAYER_ROLLS")
		end
		
		if Data.Gear and Data.Gear ~= "" then
			Player:WaitForChild("EquippedGear").Value = Data.Gear -- Load the last equipped gear onto the player's EquippedGear value directly
			GearsModule.EquipGear(Data.Gear, Player) -- Use the module to equip the last saved gear onto the player
		else
			warn("Failed to load PLAYER_EQUIPPED_GEAR")
		end
		
		if Data.MaxAuras and Data.MaxAuras ~= 6 then -- 6 is the default value so there's no point loading it
			Player:WaitForChild("MaxAuras").Value = Data.MaxAuras
		else
			warn("Failed to load PLAYER_MAX_AURAS")
		end
		
		if Data.TotalAuras and Data.TotalAuras ~= 0 then
			Player:WaitForChild("TotalAuras").Value = Data.TotalAuras
		else
			warn("Failed to load PLAYER_TOTAL_AURAS")
		end
		
		if not Data.FirstTimeJoin then
			Player:WaitForChild("FirstTimeJoining").Value = Data.FirstTimeJoin
		else
			warn("Failed to load PLAYER_FIRSTTIME_JOIN")
		end
	end
	
	--AntiCheatDetector:CheckPlayer(Player)
	GlobalFunctions.LogPlayer(Player) -- Use the GlobalFunctions module to log the player
end)

Players.PlayerRemoving:Connect(function(player) -- Player is leaving the game
	Crafting.Save(player, CraftingDataStore) -- Save the player's crafting data through the crafting module
	local BadgesData = {} -- Blank table to add values to
	
	for _, badge in pairs(player:WaitForChild("Badges"):GetChildren()) do -- Loop through the player's badges folder (I used the _ instead of i because I didn't need the index)
		table.insert(BadgesData, { Badge = badge.Name, Value = badge.Value }) -- Insert another table inside the previous BadgesData in the format {Badge = (name of the badge), Value = (value of the badge)}
	end
	
	local BadgesSaved, SavedBadgesData = pcall(function() -- pcall just in case something fails
		return BadgesDataStore:SetAsync(player.UserId, BadgesData) -- Set the player's badge data
	end)

	local AuraTotal = 0 -- Using 0 because we will add to the aura total later
	
	for _, Aura in pairs(player:WaitForChild("AuraFolder"):GetChildren()) do -- Loop through the player's AuraFolder (Same as before)
		AuraTotal += Aura.Value -- Add the found aura's value onto the AuraTotal variable
	end
	
	local DataTable = { -- Default data table
		EquippedAuraValue = player:WaitForChild("EquippedAura").Value or "",
		Coins = player:WaitForChild("Coins").Value or 0,
		Rolls = player:WaitForChild("Rolls").Value or 0,
		Gear = player:WaitForChild("EquippedGear").Value or "",
		MaxAuras = player:WaitForChild("MaxAuras").Value or 6,
		TotalAuras = AuraTotal or 0,
		FirstTimeJoin = false
	}
	
	local AuraTable = {} -- All these tables are just placeholders for when we add values to them
	local SettingsTable = {}
	local Purchases = {}
	local Items = {}
	
	for _, aura in pairs(player:WaitForChild("AuraFolder"):GetChildren()) do -- Loop through AuraFolder
		table.insert(AuraTable, { aura.Name, aura.Value }) -- Add the aura's name and value to the AuraTable
	end
	
	for _, purchase in pairs(player:WaitForChild("Purchases"):GetChildren()) do -- Loop through purchases folder
		table.insert(Purchases, purchase.Name) -- Add the purchase's name to the table
	end
	
	for _, setting in pairs(player:WaitForChild("SettingsFolder"):GetChildren()) do -- Loop through the SettingsFolder
		table.insert(SettingsTable, { Name = setting.Name, Value = setting.Value }) -- Add the setting's name and value
	end
	
	for _, item in pairs(player:WaitForChild("ItemFolder"):GetChildren()) do -- Loop through the player's ItemFolder
		if item:IsA("NumberValue") then -- Check if the value found is a NumberValue (We don't want to save anything else)
			table.insert(Items, { ItemName = item.Name, ItemAmount = item.Value }) -- Add the item's name and amount (value)
		end
	end
	
	local SettingsSaved, SettingsData = pcall(function() -- Save Data for each datastore using pcalls with the tables that we just added values to
		return SettingsDataStore:SetAsync(player.UserId, SettingsTable)
	end)

	local AurasSaved, Data = pcall(function()
		return AuraDataStore:SetAsync(player.UserId, AuraTable)
	end)
	
	local PurchasesSaved, SavedPurchaseData = pcall(function()
		return PurchasesDataStore:SetAsync(player.UserId, Purchases)
	end)
	
	local ItemsSaved, ItemsData = pcall(function()
		return ItemDataStore:SetAsync(player.UserId, Items)
	end)
	
	local Success, Saved = pcall(function()
		return PlayerDataStore:SetAsync(player.UserId, DataTable)
	end)
	
	if Success and Saved then -- Make sure that each pcall went through smoothly without error (otherwise it will show in the output)
		print("Player data successfully saved for "..player.Name)
	else
		warn("Failed to save data for "..player.Name)
	end
	
	if AurasSaved and Data then
		print("Aura data successfully saved for "..player.Name)
	else
		warn("Failed to save aura data for "..player.Name)
	end
	
	if SettingsSaved and SettingsData then
		print("Settings data successfully saved for "..player.Name)
	else
		warn("Failed to save settings data for "..player.Name)
	end
	
	if PurchasesSaved and SavedPurchaseData then
		print("Purchases successfully saved for "..player.Name)
	else
		warn("Failed to save purchase data for "..player.Name)
	end
	
	if ItemsSaved and ItemsData then
		print("Items successfully saved for "..player.Name)
	else
		warn("Failed to save items data for "..player.Name)
	end
end)

RequestEvent.OnServerInvoke = function(Player, DataStoreName) -- Client requests data
	if DataStoreName then -- DataStoreName is a nescessary parameter
		local DataStore = game:GetService("DataStoreService"):GetDataStore(DataStoreName) -- Find the DataStore using DataStoreService

		if DataStore then -- If it exists then continue
			return DataStore:GetAsync(Player.UserId) -- Return the specific player's data from the DataStore
		end
	end
end

RequestModuleEvent.OnServerInvoke = function(Player, ModuleName) -- Client requesting a module inside the player
	if ModuleName and Player:FindFirstChild(ModuleName) then -- Check if both the ModuleName is passed and it is inside the Player
		return require(Player:WaitForChild(ModuleName)) -- Return the module as a table using require()
	end
end

Remotes:WaitForChild("Roll").OnServerEvent:Connect(function(player) -- When any player rolls
	LeaderboardRollsData:SetAsync(player.UserId, player:WaitForChild("leaderstats"):WaitForChild("Rolls").Value) -- Save the player's rolls inside the leaderboard
end)