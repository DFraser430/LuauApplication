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
local GearsModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("GearModule"))
local Developers = {
	"BreifBoos1",
	"Iceyy"
}
local DEFAULT_SETTINGS = {
	{Name = "AutoEquipNumber", DefaultValue = "-1", Type = "NumberValue"},
	{Name = "NotificationsEnabled", DefaultValue = "true", Type = "BoolValue"},
	{Name = "MusicVolume", DefaultValue = "1", Type = "NumberValue"}
}
local DEFAULT_PLAYER_STATS = {
	{Name = "QuickRollOn", DefaultValue = false, Type = "BoolValue"}
}
local BadgesConfig = require(script:WaitForChild("BadgesConfig"))

for i, v in pairs(GlobalFunctions) do
	_G[i] = v
end

local function SetAttributes(Plr)
	Plr:SetAttribute("InCutscene", false)
	Plr:SetAttribute("AutoRoll", false)
	Plr:SetAttribute("InLoadingScreen", true)
end

local function SetUpCraftingData(Player)
	Crafting.SetUpData(Player)
	Crafting.Load(Player, CraftingDataStore)
end

Players.PlayerAdded:Connect(function(Player)
	SetAttributes(Player)
	SetUpCraftingData(Player)
	
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	local AuraListClone = AuraList:Clone()
	AuraListClone.Parent = Player
	
	local DataModuleClone = script:WaitForChild("PlayerData"):Clone()
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
	
	if #SettingsFolder:GetChildren() == 0 then
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
	
	for _, v in pairs(BadgesConfig) do
		local Badge = Instance.new("BoolValue")
		Badge.Name = v
		Badge.Value = false
		Badge.Parent = Badges
		
		if Badge.Name == "Grandmaster" then
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
	
	for i, v in pairs(BadgesData) do
		if Player:WaitForChild("Badges"):FindFirstChild(v.Badge) then
			Player:WaitForChild("Badges"):FindFirstChild(v.Badge).Value = v.Value
		end
	end
	
	if not ItemData then
		warn("Couldn't fetch item data for "..Player.Name)
	elseif Items and ItemData then
		for itemIndex, item in pairs(ItemData) do
			local ItemInstance
			ItemInstance = Instance.new("NumberValue", ItemFolder)
			ItemInstance.Name = item.ItemName
			ItemInstance.Value = item.ItemAmount
		end
	end
	
	if not PurchaseData then
		warn("Couldn't find purchase data for "..Player.Name)
	elseif PurchasesSuccess and PurchaseData then
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
	elseif AuraData and AuraSuccess then
		for auraIndex, auraValue in pairs(AuraData) do
			local AuraInstance
			AuraInstance = Instance.new("NumberValue", Player:WaitForChild("AuraFolder"))
			AuraInstance.Name = auraValue[1]
			AuraInstance.Value = auraValue[2]
		end
	end
	
	if not Data then
		warn("Data not found for "..Player.Name)
	elseif Success and Data then
		if Data.EquippedAuraValue and Data.EquippedAuraValue ~= "" then
			if Player:WaitForChild("AuraFolder"):FindFirstChild(Data.EquippedAuraValue) and Player:WaitForChild("AuraFolder"):FindFirstChild(Data.EquippedAuraValue).Value > 0 then
				Player:WaitForChild("EquippedAura").Value = Data.EquippedAuraValue
				AuraModule.EquipAuraToCharacter(Character, Data.EquippedAuraValue)
			end
		else
			warn("Failed to load LAST_EQUIPPED_AURA")
		end
		
		if Data.Coins and Data.Coins ~= "" then
			Player:WaitForChild("Coins").Value = Data.Coins
		else
			warn("Failed to load PLAYER_COINS")
		end
		
		if Data.Rolls and Data.Rolls ~= "" then
			Player:WaitForChild("leaderstats"):WaitForChild("Rolls").Value = Data.Rolls
		else
			warn("Failed to load PLAYER_ROLLS")
		end
		
		if Data.Gear and Data.Gear ~= "" then
			Player:WaitForChild("EquippedGear").Value = Data.Gear
			GearsModule.EquipGear(Data.Gear, Player)
		else
			warn("Failed to load PLAYER_EQUIPPED_GEAR")
		end
		
		if Data.MaxAuras and Data.MaxAuras ~= 6 then
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
	GlobalFunctions.LogPlayer(Player)
end)

Players.PlayerRemoving:Connect(function(player)
	Crafting.Save(player, CraftingDataStore)
	local BadgesData = {}
	
	for _, badge in pairs(player:WaitForChild("Badges"):GetChildren()) do
		table.insert(BadgesData, { Badge = badge.Name, Value = badge.Value })
	end
	
	local BadgesSaved, SavedBadgesData = pcall(function()
		return BadgesDataStore:SetAsync(player.UserId, BadgesData)
	end)

	local AuraTotal = 0
	
	for _, Aura in pairs(player:WaitForChild("AuraFolder"):GetChildren()) do
		AuraTotal += Aura.Value
	end
	
	local DataTable = {
		EquippedAuraValue = player:WaitForChild("EquippedAura").Value or "",
		Coins = player:WaitForChild("Coins").Value or 0,
		Rolls = player:WaitForChild("Rolls").Value or 0,
		Gear = player:WaitForChild("EquippedGear").Value or "",
		MaxAuras = player:WaitForChild("MaxAuras").Value or 6,
		TotalAuras = AuraTotal or 0,
		FirstTimeJoin = false
	}
	
	local AuraTable = {}
	local SettingsTable = {}
	local Purchases = {}
	local Items = {}
	
	for _, aura in pairs(player:WaitForChild("AuraFolder"):GetChildren()) do
		table.insert(AuraTable, { aura.Name, aura.Value })
	end
	
	for _, purchase in pairs(player:WaitForChild("Purchases"):GetChildren()) do
		table.insert(Purchases, purchase.Name)
	end
	
	for _, setting in pairs(player:WaitForChild("SettingsFolder"):GetChildren()) do
		table.insert(SettingsTable, { Name = setting.Name, Value = setting.Value })
	end
	
	for _, item in pairs(player:WaitForChild("ItemFolder"):GetChildren()) do
		if item:IsA("NumberValue") then
			table.insert(Items, { ItemName = item.Name, ItemAmount = item.Value })
		end
	end
	
	local SettingsSaved, SettingsData = pcall(function() -- Save Data for each datastore
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
	
	if Success and Saved then -- Error checking
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
	if DataStoreName then
		local DataStore = game:GetService("DataStoreService"):GetDataStore(DataStoreName)

		return DataStore:GetAsync(Player.UserId)
	end
end

RequestModuleEvent.OnServerInvoke = function(Player, ModuleName) -- Client requesting a module inside the player
	if ModuleName and Player:FindFirstChild(ModuleName) then
		return require(Player:WaitForChild(ModuleName))
	end
end

Remotes:WaitForChild("Roll").OnServerEvent:Connect(function(player)
	LeaderboardRollsData:SetAsync(player.UserId, player:WaitForChild("leaderstats"):WaitForChild("Rolls").Value)
end)