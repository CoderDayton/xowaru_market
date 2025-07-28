local LeaderboardData = require(script.Parent:WaitForChild("LeaderboardData"))

game.ReplicatedStorage.PurchaseMade.OnServerEvent:Connect(function(player, itemName, price)
	LeaderboardData.RecordPurchase(player.UserId, player.Name, itemName, price)
end)