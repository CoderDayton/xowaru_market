--[[
    DailyRewardClient.luau
    Handles UI rendering, animations, and local state management for daily rewards.
    Uses server data but responds instantly through local prediction.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local RemoteSignal = require(ReplicatedStorage:WaitForChild("RemoteSignal"))
local UIController = require(ReplicatedStorage:WaitForChild("UIController"))
local SoundHandler = require(ReplicatedStorage:WaitForChild("SoundHandler"))
local UIAnimator = require(ReplicatedStorage:WaitForChild("Shared").UIAnimator)
local StyleGuide = require(ReplicatedStorage:WaitForChild("Shared").StyleGuide)
local SoftShadow = require(ReplicatedStorage:WaitForChild("Utils").SoftShadow)
local AFKPointConfig = require(ReplicatedStorage:WaitForChild("AFKSystem").AFKPointConfig)
