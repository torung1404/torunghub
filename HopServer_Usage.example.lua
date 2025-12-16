-- =========================================================
-- file: StarterPlayerScripts/HopServer_Usage.example.lua
-- (file hop của bạn chỉ cần gọi cái này để hop mà giữ config)
-- =========================================================
--[[
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")
local bf = pg:WaitForChild("ToRungHubTransport")

local placeId = game.PlaceId
local jobId = "PASTE_JOB_ID_HERE"

-- Cách 1: để UI tự teleport (đã pack config)
bf:Invoke("Teleport", placeId, jobId)

-- Cách 2: nếu hop script của bạn tự teleport:
local td = bf:Invoke("GetTeleportData")
TeleportService:TeleportToPlaceInstance(placeId, jobId, plr, td)
]]
