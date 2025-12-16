local Adapters = {}

local warnOnce = {}
local function warn_once(key, msg)
	if warnOnce[key] then return end
	warnOnce[key] = true
	warn("[ToRungHub] " .. msg)
end

local function get_char(player)
	return player.Character
end

local function get_humanoid(model)
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

local function get_model_root(model)
	if not model then return nil end
	if model.PrimaryPart then return model.PrimaryPart end
	return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
end

-- === HAKI ===
function Adapters.SetHaki(player, enabled)
	local char = get_char(player)
	if not char then return false end

	-- Default: attribute only (safe). Replace with your own buff/effect logic if needed.
	char:SetAttribute("HakiOn", enabled == true)
	return true
end

function Adapters.IsHakiOn(player)
	local char = get_char(player)
	return char and char:GetAttribute("HakiOn") == true
end

-- === FRUIT ===
function Adapters.SwitchFruit(player, fruits)
	local char = get_char(player)
	if not char then return false end

	local list = fruits
	if type(list) ~= "table" or #list == 0 then
		warn_once("fruit_list_missing", "No fruits configured; set Defaults.Fruits or pass list.")
		return false
	end

	-- Round-robin by attribute index
	local idx = tonumber(char:GetAttribute("FruitIndex")) or 0
	idx = (idx % #list) + 1

	char:SetAttribute("FruitIndex", idx)
	char:SetAttribute("FruitName", tostring(list[idx]))
	return true
end

-- === ATTACK ===
local function damage_mob(mobModel, amount, hpAttrName)
	if not mobModel then return false end

	-- Custom HP attribute support
	if hpAttrName and mobModel:GetAttribute(hpAttrName) ~= nil then
		local hp = tonumber(mobModel:GetAttribute(hpAttrName)) or 0
		if hp <= 0 then return false end
		local newHp = math.max(0, hp - amount)
		mobModel:SetAttribute(hpAttrName, newHp)
		return true
	end

	-- Humanoid fallback
	local hum = get_humanoid(mobModel)
	if hum and hum.Health > 0 then
		hum:TakeDamage(amount)
		return true
	end

	return false
end

function Adapters.Attack(player, mobModel, baseDamage, hpAttrName, hakiMultiplier)
	local char = get_char(player)
	if not (char and mobModel) then return false end

	local dmg = tonumber(baseDamage) or 1
	if Adapters.IsHakiOn(player) and tonumber(hakiMultiplier) then
		dmg = math.floor(dmg * hakiMultiplier + 0.5)
	end

	return damage_mob(mobModel, dmg, hpAttrName)
end

-- === MOVE ===
function Adapters.MoveToward(player, targetPos)
	local char = get_char(player)
	if not char then return false end

	local hum = get_humanoid(char)
	if not hum then return false end

	hum:MoveTo(targetPos)
	return true
end

function Adapters.GetCharRoot(player)
	local char = get_char(player)
	return get_model_root(char)
end

function Adapters.GetMobRoot(mobModel)
	return get_model_root(mobModel)
end

return Adapters
