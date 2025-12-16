-- file: ServerScriptService/ToRungHub/ToRungHub_AutoFarmServer.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defaults = require(ReplicatedStorage:WaitForChild("ToRungHub"):WaitForChild("Shared"):WaitForChild("ToRungHub_Defaults"))
local Adapters = require(script.Parent:WaitForChild("ToRungHub_Adapters"))

local function ensure_folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function ensure_remote_event(parent, name)
	local re = parent:FindFirstChild(name)
	if not re then
		re = Instance.new("RemoteEvent")
		re.Name = name
		re.Parent = parent
	end
	return re
end

local root = ensure_folder(ReplicatedStorage, "ToRungHub")
ensure_folder(root, "Shared")

local autoFarmRE = ensure_remote_event(root, "AutoFarmRE")

local states = {} -- [player] = state

local function shallow_copy(t)
	local o = {}
	for k, v in pairs(t) do o[k] = v end
	return o
end

local function clamp_num(v, minv, maxv)
	v = tonumber(v)
	if not v then return nil end
	if minv then v = math.max(minv, v) end
	if maxv then v = math.min(maxv, v) end
	return v
end

local function find_monster_roots()
	local roots = {}
	for _, folderName in ipairs(Defaults.MonsterFolderNames) do
		local f = workspace:FindFirstChild(folderName)
		if f then table.insert(roots, f) end
	end
	return roots
end

local function is_alive_mob(mob, hpAttrName)
	if not mob or not mob.Parent then return false end

	local hpAttr = hpAttrName and mob:GetAttribute(hpAttrName)
	if hpAttr ~= nil then
		local hp = tonumber(hpAttr) or 0
		return hp > 0
	end

	local hum = mob:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function is_boss(mob)
	if mob:GetAttribute(Defaults.BossTagAttribute) == true then
		return true
	end
	return false
end

local function get_candidates(state)
	local candidates = {}
	for _, rootFolder in ipairs(state._monsterRoots) do
		for _, child in ipairs(rootFolder:GetChildren()) do
			if child:IsA("Model") then
				if not state.BossOnly or is_boss(child) then
					if is_alive_mob(child, state.HPAttributeName) then
						table.insert(candidates, child)
					end
				end
			end
		end
	end
	return candidates
end

local function dist_sq(a, b)
	local d = a - b
	return d.X * d.X + d.Y * d.Y + d.Z * d.Z
end

local function retarget(player, state, now)
	local myRoot = Adapters.GetCharRoot(player)
	if not myRoot then return end

	local best, bestD = nil, (state.Radius * state.Radius) + 1
	local myPos = myRoot.Position

	for _, mob in ipairs(get_candidates(state)) do
		local mobRoot = Adapters.GetMobRoot(mob)
		if mobRoot then
			local d = dist_sq(myPos, mobRoot.Position)
			if d < bestD then
				bestD = d
				best = mob
			end
		end
	end

	state._target = best
	state._nextRetargetAt = now + state.RetargetTickSeconds
end

local function tick_player(player, state, now)
	if not state.Enabled then return end

	local charRoot = Adapters.GetCharRoot(player)
	if not charRoot then return end

	-- One-time timers since start/enabled
	if not state._startedAt then
		state._startedAt = now
		state._nextHakiAt = now + state.HakiDelaySeconds
		state._nextFruitAt = now + state.FruitIntervalSeconds
	end

	-- Haki after 20s
	if state._nextHakiAt and now >= state._nextHakiAt and not Adapters.IsHakiOn(player) then
		Adapters.SetHaki(player, true)
		state._nextHakiAt = nil
	end

	-- Fruit every 8s
	if state._nextFruitAt and now >= state._nextFruitAt then
		Adapters.SwitchFruit(player, state.Fruits)
		state._nextFruitAt = now + state.FruitIntervalSeconds
	end

	-- Retarget throttled
	if not state._nextRetargetAt or now >= state._nextRetargetAt then
		retarget(player, state, now)
	end

	local target = state._target
	if not target or not is_alive_mob(target, state.HPAttributeName) then
		state._target = nil
		return
	end

	local mobRoot = Adapters.GetMobRoot(target)
	if not mobRoot then
		state._target = nil
		return
	end

	local d = (charRoot.Position - mobRoot.Position).Magnitude

	-- Move throttled (no teleport)
	if d > state.AttackRange and (not state._nextMoveAt or now >= state._nextMoveAt) then
		Adapters.MoveToward(player, mobRoot.Position)
		state._nextMoveAt = now + state.MoveTickSeconds
	end

	-- Attack throttled
	if d <= state.AttackRange and (not state._nextAttackAt or now >= state._nextAttackAt) then
		Adapters.Attack(player, target, state.BaseDamagePerHit, state.HPAttributeName, state.HakiDamageMultiplier)
		state._nextAttackAt = now + state.AttackCooldownSeconds
	end
end

local function reset_runtime(state)
	state._startedAt = nil
	state._nextHakiAt = nil
	state._nextFruitAt = nil
	state._nextAttackAt = nil
	state._nextMoveAt = nil
	state._nextRetargetAt = nil
	state._target = nil
end

local function build_state()
	local s = shallow_copy(Defaults)
	s._monsterRoots = find_monster_roots()
	reset_runtime(s)
	return s
end

local function set_enabled(player, state, enabled)
	state.Enabled = enabled == true
	reset_runtime(state)
	if not state.Enabled then
		Adapters.SetHaki(player, false)
	end
end

autoFarmRE.OnServerEvent:Connect(function(player, payload)
	if type(payload) ~= "table" then return end
	local state = states[player]
	if not state then return end

	if payload.cmd == "set" then
		local key = tostring(payload.key or "")
		local val = payload.value

		if key == "Enabled" then
			set_enabled(player, state, val)
			return
		end

		if key == "BossOnly" then
			state.BossOnly = val == true
			state._nextRetargetAt = 0
			return
		end

		if key == "Radius" then
			local n = clamp_num(val, 30, 3000)
			if n then state.Radius = n end
			state._nextRetargetAt = 0
			return
		end

		if key == "AttackRange" then
			local n = clamp_num(val, 6, 200)
			if n then state.AttackRange = n end
			return
		end

		if key == "AttackCooldownSeconds" then
			local n = clamp_num(val, 0.05, 2)
			if n then state.AttackCooldownSeconds = n end
			return
		end

		-- Optional knobs (keep your requested defaults)
		if key == "HakiDelaySeconds" then
			local n = clamp_num(val, 0, 120)
			if n then state.HakiDelaySeconds = n end
			reset_runtime(state)
			return
		end

		if key == "FruitIntervalSeconds" then
			local n = clamp_num(val, 1, 120)
			if n then state.FruitIntervalSeconds = n end
			reset_runtime(state)
			return
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	local state = build_state()
	states[player] = state

	if Defaults.AutoStart then
		set_enabled(player, state, true)
	end

	task.spawn(function()
		while player.Parent do
			local now = os.clock()
			tick_player(player, state, now)
			task.wait(0.05) -- low CPU; real work is throttled inside
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)
