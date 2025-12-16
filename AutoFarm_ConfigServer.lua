-- file: ServerScriptService/AutoFarm_ConfigServer.lua
-- Creates remotes and persists AutoFarm UI config in DataStore.
-- NOTE: DataStore works only in published games. In Studio, enable:
-- Game Settings -> Security -> "Enable Studio Access to API Services"

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local DataStoreService = game:GetService('DataStoreService')

local DS_NAME = 'AutoFarmUI_Config_v2'
local store = DataStoreService:GetDataStore(DS_NAME)

local RF_NAME = 'AutoFarmConfigRF'
local RE_NAME = 'AutoFarmConfigRE'

local rf = ReplicatedStorage:FindFirstChild(RF_NAME)
if not rf then
  rf = Instance.new('RemoteFunction')
  rf.Name = RF_NAME
  rf.Parent = ReplicatedStorage
end

local re = ReplicatedStorage:FindFirstChild(RE_NAME)
if not re then
  re = Instance.new('RemoteEvent')
  re.Name = RE_NAME
  re.Parent = ReplicatedStorage
end

-- in-memory cache
local cache = {}         -- [userId] = configTable
local dirty = {}         -- [userId] = true/false
local saveTokens = {}    -- [userId] = int token

local function shallowCopy(t)
  local o = {}
  for k,v in pairs(t) do o[k] = v end
  return o
end

local function sanitizePayload(payload)
  if type(payload) ~= 'table' then return nil end

  local out = { v = 2, cfg = {}, ui = {} }
  local cfg = (type(payload.cfg) == 'table') and payload.cfg or {}
  local ui  = (type(payload.ui) == 'table') and payload.ui or {}

  local function keepBool(k)
    if type(cfg[k]) == 'boolean' then out.cfg[k] = cfg[k] end
  end
  local function keepNum(k, minv, maxv)
    if type(cfg[k]) == 'number' then
      local v = cfg[k]
      if minv then v = math.max(minv, v) end
      if maxv then v = math.min(maxv, v) end
      out.cfg[k] = v
    end
  end
  local function keepStr(k, allowed)
    if type(cfg[k]) == 'string' then
      if not allowed then
        out.cfg[k] = cfg[k]
      else
        for _, s in ipairs(allowed) do
          if cfg[k] == s then out.cfg[k] = cfg[k] break end
        end
      end
    end
  end

  -- CFG whitelist
  keepBool('BossOnly')
  keepBool('SmoothMove')
  keepBool('AutoAttack')
  keepBool('AutoHakiV')
  keepBool('AutoSwitchFruitR')
  keepBool('AutoMeditate')
  keepBool('AggroSweep')

  keepNum('Radius', 20, 20000)
  keepNum('FollowDist', 1, 60)
  keepNum('HeightOffset', -50, 200)

  keepNum('RetargetTick', 0.03, 2)
  keepNum('BlacklistSeconds', 1, 60)
  keepNum('TargetMaxLockSeconds', 5, 300)

  keepNum('SweepGridSize', 40, 500)
  keepNum('SweepMaxPoints', 1, 30)
  keepNum('SweepDwell', 0.02, 3)
  keepNum('SweepHeight', 0, 30)
  keepNum('SweepInterval', 1, 180)

  keepNum('AttackCD', 0, 1)
  keepNum('HakiCD', 0, 60)
  keepNum('SwitchFruitCD', 0, 60)

  keepStr('AttackMode', { 'TOOL', 'REMOTE', 'UI' })
  keepNum('AttackRange', 1, 200)

  keepNum('HealMinPercent', 0, 99)
  keepNum('HealMaxPercent', 1, 100)

  -- SafeCFrame {x,y,z}
  if type(cfg.SafeCFrame) == 'table' then
    local x,y,z = tonumber(cfg.SafeCFrame.x), tonumber(cfg.SafeCFrame.y), tonumber(cfg.SafeCFrame.z)
    if x and y and z and math.abs(x) <= 1e7 and math.abs(y) <= 1e7 and math.abs(z) <= 1e7 and y > -2000 and y < 200000 then
      out.cfg.SafeCFrame = { x = x, y = y, z = z }
    end
  end

  -- UI whitelist
  if type(ui.pos) == 'table' then
    local xs, xo = tonumber(ui.pos.xScale), tonumber(ui.pos.xOffset)
    local ys, yo = tonumber(ui.pos.yScale), tonumber(ui.pos.yOffset)
    if xs and xo and ys and yo then
      -- bounds to prevent off-screen abuse (still allow a lot)
      xo = math.clamp(xo, -5000, 5000)
      yo = math.clamp(yo, -5000, 5000)
      xs = math.clamp(xs, -2, 2)
      ys = math.clamp(ys, -2, 2)
      out.ui.pos = { xScale = xs, xOffset = xo, yScale = ys, yOffset = yo }
    end
  end

  if type(ui.visible) == 'boolean' then out.ui.visible = ui.visible end
  if type(ui.minimized) == 'boolean' then out.ui.minimized = ui.minimized end
  if type(ui.dragLocked) == 'boolean' then out.ui.dragLocked = ui.dragLocked end

  return out
end

local function saveUser(userId)
  local data = cache[userId]
  if not data then return end

  local ok, err = pcall(function()
    store:SetAsync(tostring(userId), data)
  end)

  if not ok then
    warn('[AutoFarmConfigServer] Save failed for', userId, err)
  end
end

local function scheduleSave(userId, delaySec)
  delaySec = delaySec or 8
  saveTokens[userId] = (saveTokens[userId] or 0) + 1
  local token = saveTokens[userId]
  task.delay(delaySec, function()
    if saveTokens[userId] ~= token then return end
    if dirty[userId] then
      dirty[userId] = nil
      saveUser(userId)
    end
  end)
end

Players.PlayerAdded:Connect(function(plr)
  local userId = plr.UserId
  local ok, data = pcall(function()
    return store:GetAsync(tostring(userId))
  end)
  if ok and type(data) == 'table' then
    cache[userId] = data
  else
    cache[userId] = { v = 2, cfg = {}, ui = {} }
  end
end)

Players.PlayerRemoving:Connect(function(plr)
  local userId = plr.UserId
  if dirty[userId] then
    dirty[userId] = nil
    saveUser(userId)
  end
  cache[userId] = nil
  saveTokens[userId] = nil
end)

game:BindToClose(function()
  for userId, _ in pairs(cache) do
    saveUser(userId)
  end
end)

rf.OnServerInvoke = function(plr)
  local userId = plr.UserId
  return cache[userId] or { v = 2, cfg = {}, ui = {} }
end

re.OnServerEvent:Connect(function(plr, payload)
  local userId = plr.UserId
  local clean = sanitizePayload(payload)
  if not clean then return end
  cache[userId] = clean
  dirty[userId] = true
  scheduleSave(userId, 8)
end)
