local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))

local SoundHandler = {}

local soundConfigs = {
	ButtonSound = {
		id = "rbxassetid://14382276423",
		volume = 0.06,
		playbackSpeed = 1.1
	},
    ClickSound = {
        id = "rbxassetid://1673280232",
        volume = 0.03,
        playbackSpeed = 1.0
    },
}

local preloadedSounds = {}

for name, config in pairs(soundConfigs) do
	local soundId = config.id
	if not string.find(soundId, "rbxassetid://") then
		soundId = "rbxassetid://" .. tostring(soundId)
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = config.volume
	sound.PlaybackSpeed = config.playbackSpeed
	sound.Parent = SoundService  -- Preload in SoundService

	preloadedSounds[name] = sound
end

function SoundHandler.PlaySound(name, overrideVolume, overridePlaybackSpeed)
	local config = soundConfigs[name]
	if not config then
		warn("[SoundHandler] Sound name not found:", name)
		return
	end

	local soundId = config.id
	local volume = overrideVolume or config.volume
	local playbackSpeed = overridePlaybackSpeed or config.playbackSpeed

	local sound
	if preloadedSounds[name] then
		sound = preloadedSounds[name]:Clone()  -- Clone preloaded for efficiency
	else
		warn("[SoundHandler] Preloaded sound not available for:", name)  -- Shouldn't happen if preloaded
		sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume
		sound.PlaybackSpeed = playbackSpeed
	end

	sound.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	Debris:AddItem(sound, 10)  -- Auto-cleanup after 10 seconds max
end

local PlaySoundLocal = RemoteSignal.new("PlaySoundLocal")
PlaySoundLocal:LocalConnect(function(name, overrideVolume, overridePlaybackSpeed)
	SoundHandler.PlaySound(name, overrideVolume, overridePlaybackSpeed)
end)

return SoundHandler