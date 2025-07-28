local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local courtyard = Workspace:WaitForChild("Courtyard")
local PodiumFolder = courtyard:WaitForChild("Podiums")

local animatedParts = {}

local ITEMS_TO_ANIMATE = {
    ["GoldFloatingCrown"] = {
        spin = true,
        spinAxis = "Y",      -- "X", "Y", or "Z"
        spinSpeed = 20,      -- degrees per second
        float = true,
        floatAmplitude = 0.6,
        floatSpeed = 1.2,
    },
    ["Fedora of the Darkest Night"] = {
        spin = true,
        spinAxis = "Y",      -- "X", "Y", or "Z"
        spinSpeed = 20,      -- degrees per second
        float = true,
        floatAmplitude = 0.6,
        floatSpeed = 1.2,
	},
	["Accessory (Bloodvein Horns)"] = {
		spin = true,
		spinAxis = "Y",      -- "X", "Y", or "Z"
		spinSpeed = 20,      -- degrees per second
		float = true,
		floatAmplitude = 0.6,
		floatSpeed = 1.2,
	},
    -- Add more items with custom settings
}

local function addParticles(part)
    if part:FindFirstChild("PodiumParticles") then return end
    local config = ITEMS_TO_ANIMATE[part.Name]
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "PodiumParticles"
    emitter.Texture = "rbxassetid://258128463"
    emitter.Rate = 6
    emitter.Lifetime = NumberRange.new(0.8, 1.2)
    emitter.Size = NumberSequence.new(0.3)
    emitter.Speed = NumberRange.new(0.7, 1.1)
    emitter.LightEmission = 0.7
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.2),
        NumberSequenceKeypoint.new(1,1)
    })
    emitter.Color = config and config.particleColor or ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(255, 255, 255))
    emitter.Parent = part
end

local function tryInsertPart(obj)
    local itemOptions = ITEMS_TO_ANIMATE[obj.Name]
    if itemOptions then
        local part = nil
        if obj:IsA("Accessory") then
            part = obj:FindFirstChild("Handle")
        elseif obj:IsA("Model") and obj.PrimaryPart then
            part = obj.PrimaryPart
        elseif obj:IsA("MeshPart") or obj:IsA("Part") or obj:IsA("UnionOperation") then
            part = obj
        end
        if part and not animatedParts[part] then
            -- Apply initial settings
            if itemOptions.glow then
                part.Material = Enum.Material.Neon
                part.Reflectance = 0.15
            end
            if itemOptions.particles then
                addParticles(part)
            end
            animatedParts[part] = {
                part = part,
                basePosition = part.Position,
                baseOrientation = part.Orientation,
                options = itemOptions,
                baseColor = part.Color,
            }
            print("Added for animation:", part:GetFullName())
            return
        end
    end
    for _, child in ipairs(obj:GetChildren()) do
        tryInsertPart(child)
    end
end

-- Periodic scan for streaming/delayed parts
task.spawn(function()
    while true do
        for _, podium in ipairs(PodiumFolder:GetChildren()) do
            tryInsertPart(podium)
        end
        task.wait(1)
    end
end)

-- Animation loop
RunService.Heartbeat:Connect(function(dt)
    local t = tick()
    for _, data in pairs(animatedParts) do
        if data.part and data.part.Parent then
            local opts = data.options
            -- FLOAT
            local newPos = data.basePosition
            if opts.float then
                local floatY = math.sin(t * (opts.floatSpeed or 1.2)) * (opts.floatAmplitude or 0.6)
                newPos = data.basePosition + Vector3.new(0, floatY, 0)
            end
            data.part.Position = newPos

            -- SPIN (Orientation)
            if opts.spin then
                local spinAxis = string.upper(opts.spinAxis or "Y")
                local ori = data.part.Orientation
                local spinInc = (opts.spinSpeed or 36) * dt
                if spinAxis == "X" then
                    ori = Vector3.new((ori.X + spinInc) % 360, ori.Y, ori.Z)
                elseif spinAxis == "Z" then
                    ori = Vector3.new(ori.X, ori.Y, (ori.Z + spinInc) % 360)
                else -- Default Y
                    ori = Vector3.new(ori.X, (ori.Y + spinInc) % 360, ori.Z)
                end
                data.part.Orientation = ori
            end

            -- COLOR CYCLE
            if opts.colorCycle then
                local hue = (t * (opts.colorCycleSpeed or 0.2)) % 1
                local rgb = Color3.fromHSV(hue, 0.7, 1)
                data.part.Color = rgb
            else
                data.part.Color = data.baseColor
            end
        end
    end
end)