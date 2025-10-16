local DataPages = {}
local HttpService = game:GetService("HttpService")
DataPages.__index = DataPages

function DataPages.GetTopPlayers(DataStore, PlayersToGet, StartIndex)
	local Success, Data = pcall(function()
		return DataStore:GetSortedAsync(true, PlayersToGet, StartIndex)
	end)

	if Success then
		local Pages = Data:GetCurrentPage()

		local playerTable = {}

		for _, Entry in ipairs(Pages) do
			local playerName = Entry.key
			local score = Entry.value
			table.insert(playerTable, {Player = playerName, Score = score})
		end

		return playerTable
	else
		warn("Error fetching data: " .. Data)
		return nil
	end
end

function DataPages.GetTopRolls(DataStore, PlayersToGet, StartIndex)
	local Success, Data = pcall(function()
		return DataStore:GetSortedAsync(true, PlayersToGet, StartIndex)
	end)

	if Success then
		local Pages = Data:GetCurrentPage()

		local playerTable = {}

		for _, Entry in ipairs(Pages) do
			local playerName = Entry.key
			local rolls = Entry.value
			table.insert(playerTable, {Player = playerName, Rolls = rolls})
		end

		return playerTable
	else
		warn("Error fetching data: " .. Data)
		return nil
	end
end

return DataPages