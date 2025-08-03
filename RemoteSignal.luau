-- RemoteSignal.lua
-- Simple wrapper for RemoteEvent as a Signal-like API (crosses server/client)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_FOLDER_NAME = "RemoteSignals"
local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
if not remoteFolder then
    remoteFolder = Instance.new("Folder")
    remoteFolder.Name = REMOTE_FOLDER_NAME
    remoteFolder.Parent = ReplicatedStorage
end

local RemoteSignal = {}
RemoteSignal.__index = RemoteSignal

function RemoteSignal.new(name)
	-- Find or create the RemoteEvent with the given name
	local event = remoteFolder:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remoteFolder
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
