local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))

local PlayButtonSoundLocal = RemoteSignal.new("PlayButtonSoundLocal")

PlayButtonSoundLocal:LocalConnect(function(soundId, volume, playbackSpeed)
    -- Add validation and defaults
    if not soundId or soundId == "" then
        warn("[SoundHandler] Invalid soundId provided:", soundId)
        return
    end

    -- Ensure proper rbxassetid format
    if not string.find(soundId, "rbxassetid://") then
        soundId = "rbxassetid://" .. tostring(soundId)
    end

    volume = volume or 0.1
    playbackSpeed = playbackSpeed or 1.5

    print("[SoundHandler] Playing sound:", soundId, "Volume:", volume, "Speed:", playbackSpeed)  -- Debug

    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = volume
    sound.PlaybackSpeed = playbackSpeed
    sound.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Play and handle cleanup safely
    sound:Play()

    -- Use Connect instead of Wait to avoid blocking/errors
    sound.Ended:Connect(function()
        sound:Destroy()
    end)

    -- Fallback cleanup after reasonable time
    game:GetService("Debris"):AddItem(sound, 10)  -- Auto-cleanup after 10 seconds max
end)
