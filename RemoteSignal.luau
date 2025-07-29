-- RemoteSignal.lua
-- Simple wrapper for RemoteEvent as a Signal-like API (crosses server/client)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

function RemoteSignal.new(name)
	-- Find or create the RemoteEvent with the given name
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end

	local self = setmetatable({}, RemoteSignal)
	self._event = event
	return self
end

function RemoteSignal:Fire(...)
	if game:GetService("RunService"):IsServer() then
		-- On server, fire to all players (broadcast)
		self._event:FireAllClients(...)
	else
		-- On client, fire to server
		self._event:FireServer(...)
	end
end

function RemoteSignal:FireTo(player, ...)
	-- Server-only: fire to a specific player
	if game:GetService("RunService"):IsServer() then
		self._event:FireClient(player, ...)
	end
end

function RemoteSignal:Connect(func)
	if game:GetService("RunService"):IsServer() then
		return self._event.OnServerEvent:Connect(func)
	else
		return self._event.OnClientEvent:Connect(func)
	end
end

function RemoteSignal:Wait()
	if game:GetService("RunService"):IsServer() then
		return self._event.OnServerEvent:Wait()
	else
		return self._event.OnClientEvent:Wait()
	end
end

return RemoteSignal
