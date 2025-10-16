--~~| [ EXAMPLES ] |~~--

--[[

/giveaura BreifBoos1 Common 1 -- Gives BreifBoos1 a single Common aura
/removeaura BreifBoos1 Common -- Removes all Commons from BreifBoos1's Inventory
/changebiome Snowy -- Changes the server biome to snowy
/setrank BreifBoos1 Developer -- Gives the player the Developer rank and access to its commands

--]]

local Players = game:GetService("Players")

local function CheckPlayerRank(Player, Rank)
	local PlayerRank = Player:GetAttribute("Rank")
	
	if Rank == "Tester" then
		if PlayerRank == "Admin" or PlayerRank == "Developer" or PlayerRank == "Tester" then
			return true
		end
	end	
	
	if Rank == "Admin" then
		if PlayerRank == "Admin" or PlayerRank == "Developer" then
			return true
		else
			return false
		end
	end	
	
	if Rank == "Developer" then
		if PlayerRank == "Developer" then
			return true
		else
			return false
		end
	end	
end

local Commands = {
	["giveaura"] = function(Player, Chat)
		if CheckPlayerRank(Player, "Admin") then
			local FormattedCommand = Chat:sub(2)

			if FormattedCommand:match("giveaura") then
				local Target = FormattedCommand:sub(10)
				local Seperator = string.find(Target, " ")

				if Seperator then
					Target = Target:sub(1, Seperator - 1)
				end

				if Players:FindFirstChild(Target) then
					local AuraFolder = Players:FindFirstChild(Target):WaitForChild("AuraFolder")
					local AuraString = FormattedCommand:sub(Seperator + #Target)
					local Aura = AuraString:sub(1, (string.find(AuraString, " ")) - 1)
					local Amount = tonumber(AuraString:sub(string.find(AuraString, " ") + 1))

					if typeof(Amount) ~= "number" then
						warn("Error: Amount must be number, not " .. typeof(Amount))
						return
					end

					if game:GetService("ReplicatedStorage"):WaitForChild("Auras"):FindFirstChild(Aura) then
						if not AuraFolder:FindFirstChild(Aura) then
							local AuraInstance = Instance.new("NumberValue")
							AuraInstance.Parent = AuraFolder
							AuraInstance.Name = Aura
							AuraInstance.Value = Amount
						else
							AuraFolder:FindFirstChild(Aura).Value += Amount
						end
					else
						warn("Error: Aura not found: " .. Aura)
						return
					end
				else
					warn("Error: Player not found: " .. Target)
					return
				end
			end
		else
			warn("Rank too low for command. Current Rank: " .. Player:GetAttribute("Rank") .. " | Needed Rank: Admin")
		end
	end,
	
	["removeaura"] = function(Player, Chat)
		if CheckPlayerRank(Player, "Admin") then
			local FormattedCommand = Chat:sub(2)

			if FormattedCommand:match("removeaura") then
				local Target = FormattedCommand:sub(12)
				local Seperator = string.find(Target, " ")

				if Seperator then
					Target = Target:sub(1, Seperator - 1)
				end

				if Players:FindFirstChild(Target) then
					local AuraFolder = Players:FindFirstChild(Target):WaitForChild("AuraFolder")
					local AuraString = FormattedCommand:sub(Seperator + #Target)
					local Aura = AuraString:sub(3, #AuraString)

					if game:GetService("ReplicatedStorage"):WaitForChild("Auras"):FindFirstChild(Aura) then
						if not AuraFolder:FindFirstChild(Aura) then
							warn("Error: Player does not have aura: " .. Aura)
						else
							AuraFolder:FindFirstChild(Aura):Destroy()
						end
					else
						warn("Error: Aura not found: " .. Aura)
						return
					end
				else
					warn("Error: Player not found: " .. Target)
					return
				end
			end
		else
			warn("Rank too low for command. Current Rank: " .. Player:GetAttribute("Rank") .. " | Needed Rank: Admin")
		end
	end,
	
	["changebiome"] = function(Player, Chat)
		if CheckPlayerRank(Player, "Tester") then
			local Biome = Chat:sub(14)
			local ServerConfig = game:GetService("ServerStorage"):WaitForChild("ServerSettings")
			local Biomes = {
				["Default"] = true,
				["Snowy"] = true,
				["???"] = true,
				["Dev"] = true
			}

			if not Biomes[Biome] then
				warn("Invalid Biome: " .. Biome)
				return
			end

			ServerConfig:SetAttribute("CurrentBiome", Biome)
		end
	end,
	
	["setrank"] = function(Player, Chat)
		if CheckPlayerRank(Player, "Developer") then
			local Player = Chat:sub(10)
			local Seperator = string.find(Player, " ")
			local FormattedPlayerString = Player:sub(1, (Seperator - 1))
			local NewRank = Chat:sub(#FormattedPlayerString + 10)
			
			if Players:FindFirstChild(FormattedPlayerString) then
				Players:FindFirstChild(FormattedPlayerString):SetAttribute("Rank", NewRank)
			else
				warn("Player not found: " .. FormattedPlayerString)
			end
		else
			warn("Rank too low for command. Current Rank: " .. Player:GetAttribute("Rank") .. " | Needed Rank: Developer")
		end
	end,
}

return Commands