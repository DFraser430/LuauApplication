local Crafting = {}
local CraftingModule = script:WaitForChild("CraftingData")
Crafting.__index = Crafting

function Crafting.SetUpData(Player)	
	local CraftingData = CraftingModule:Clone()
	CraftingData.Parent = Player
end

function Crafting.Save(Player, DataStore)
	local CraftingData = require(Player:WaitForChild("CraftingData"))
	if not CraftingData then return end

	local SavedIngredients = CraftingData.CraftingTable or {}
	local SavedCraftedItems = CraftingData.CraftedItems or {}

	local Success, Err = pcall(function()
		DataStore:SetAsync(Player.UserId, { CraftingTable = SavedIngredients, CraftedItems = SavedCraftedItems })
	end)

	if Success then
		print("Saved "..Player.Name.."'s crafting data")
	else
		warn(Player.Name.." crafting data error: "..tostring(Err))
	end
end

function Crafting.Load(Player, DataStore)
	local Success, Data = pcall(function()
		return DataStore:GetAsync(Player.UserId)
	end)
	
	if Success and Data then
		local CraftingData = require(Player:WaitForChild("CraftingData"))
		
		if require(CraftingModule) ~= CraftingData then
			for i, v in pairs(require(CraftingModule)) do
				if CraftingData[i] then
					print("Player has " .. i)
				else
					print("Player doesnt have " .. i)
					CraftingData[i] = require(CraftingModule[i])
				end
				
				for index, var in pairs(v) do
					for i1, v1 in pairs(CraftingData.CraftingTable[index]) do
						if not Data.CraftingTable[index][i1] then
							Data.CraftingTable[index] = CraftingData.CraftingTable[index]
						end
					end
				end
			end
		end
	
		CraftingData.CraftingTable = Data.CraftingTable or {}
		CraftingData.CraftedItems = Data.CraftedItems or {}

		print("Loaded crafting data for "..Player.Name)
	else
		warn("Error loading crafting data for "..Player.Name.." setting up...")
		Crafting.SetUpData(Player)
	end
end


function Crafting.Wipe(Player, DataStore)
	local Success, Data = pcall(function()
		return DataStore:GetAsync(Player.UserId)
	end)

	if Data and Success then
		for i, v in pairs(Data.CraftedItems) do
			table.remove(Data, i)
		end
		
		for i, v in pairs(Data.CraftingTable) do
			table.remove(Data, i)
		end
	end
end

return Crafting