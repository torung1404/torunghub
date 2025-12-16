--// =========================================================
--// File: ReplicatedStorage/ToRungHub/HPProbe.lua
--// =========================================================
--!strict

local Players = game:GetService("Players")

local HPProbe = {}

export type HPInfo = {
	health: number,
	maxHealth: number,
	percent: number,
}

local function getHumanoid(player: Player): Humanoid?
	local c = player.Character
	if not c then
		return nil
	end
	return c:FindFirstChildOfClass("Humanoid")
end

function HPProbe.Get(player: Player): HPInfo?
	local hum = getHumanoid(player)
	if not hum then
		return nil
	end
	local maxH = hum.MaxHealth
	if maxH <= 0 then
		return {
			health = hum.Health,
			maxHealth = hum.MaxHealth,
			percent = 0,
		}
	end
	local pct = math.clamp(hum.Health / maxH, 0, 1)
	return {
		health = hum.Health,
		maxHealth = maxH,
		percent = pct,
	}
end

return HPProbe
