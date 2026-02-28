-- MultiBotConfig.lua
-- print("MultiBotConfig.lua loaded")
MultiBot = MultiBot or {}

local aceDB = LibStub and LibStub("AceDB-3.0", true)

-- Original values (seconds): kept unchanged.
local DEFAULTS = {
  stats  = 45,
  talent = 3,
  invite = 5,
  sort   = 1,
}

local THROTTLE_DEFAULTS = {
  rate = 5,
  burst = 8,
}

local DB_DEFAULTS = {
  profile = {
    timers = {
      stats  = DEFAULTS.stats,
      talent = DEFAULTS.talent,
      invite = DEFAULTS.invite,
      sort   = DEFAULTS.sort,
    },
    throttle = {
      rate = THROTTLE_DEFAULTS.rate,
      burst = THROTTLE_DEFAULTS.burst,
    },
  },
}

local function getLegacyTimerValue(name)
  return MultiBotDB and MultiBotDB.timers and MultiBotDB.timers[name]
end

local function getLegacyThrottleValue(name)
  return MultiBotDB and MultiBotDB.throttle and MultiBotDB.throttle[name]
end

local function migrateLegacyConfigIntoProfile(profile)
  if type(profile) ~= "table" then return end

  profile.timers = profile.timers or {}
  for key, defaultValue in pairs(DEFAULTS) do
    local legacyValue = getLegacyTimerValue(key)
    if type(legacyValue) == "number" and legacyValue > 0 then
      profile.timers[key] = legacyValue
    elseif type(profile.timers[key]) ~= "number" or profile.timers[key] <= 0 then
      profile.timers[key] = defaultValue
    end
  end

  profile.throttle = profile.throttle or {}
  for key, defaultValue in pairs(THROTTLE_DEFAULTS) do
    local legacyValue = getLegacyThrottleValue(key)
    if type(legacyValue) == "number" and legacyValue > 0 then
      profile.throttle[key] = legacyValue
    elseif type(profile.throttle[key]) ~= "number" or profile.throttle[key] <= 0 then
      profile.throttle[key] = defaultValue
    end
  end
end

local function getConfigStore()
  if MultiBot.db and MultiBot.db.profile then
    return MultiBot.db.profile
  end

  MultiBotDB = MultiBotDB or {}
  return MultiBotDB
end

function MultiBot.Config_InitDB()
  if MultiBot.db or not aceDB then
    return
  end

  MultiBotDB = MultiBotDB or {}
  local db = aceDB:New("MultiBotDB", DB_DEFAULTS, true)
  if not db or not db.profile then
    return
  end

  migrateLegacyConfigIntoProfile(db.profile)
  MultiBot.db = db
end

-- Ensure SavedVariables keys exist.
function MultiBot.Config_Ensure()
  MultiBot.Config_InitDB()

  local config = getConfigStore()

  config.timers = config.timers or {}
  for key, defaultValue in pairs(DEFAULTS) do
    if type(config.timers[key]) ~= "number" or config.timers[key] <= 0 then
      config.timers[key] = defaultValue
    end
  end

  config.throttle = config.throttle or {}
  if type(config.throttle.rate) ~= "number" or config.throttle.rate <= 0 then
    config.throttle.rate = THROTTLE_DEFAULTS.rate
  end
  if type(config.throttle.burst) ~= "number" or config.throttle.burst <= 0 then
    config.throttle.burst = THROTTLE_DEFAULTS.burst
  end
end

-- Copy saved values into runtime timers.
function MultiBot.ApplyTimersToRuntime()
  if not (MultiBot and MultiBot.timer) then return end
  local config = getConfigStore()
  for key, value in pairs(config.timers or {}) do
    MultiBot.timer[key] = MultiBot.timer[key] or { elapsed = 0, interval = value }
    MultiBot.timer[key].interval = value
  end
end

-- Read
function MultiBot.GetTimer(name)
  if MultiBotDB and MultiBotDB.timers then
    return MultiBotDB.timers[name]
  end
  return DEFAULTS[name]
end

-- Reset elapsed counters (one or all)
function MultiBot.ApplyTimerChanges(name)
  if not (MultiBot and MultiBot.timer) then return end
  local function resetOne(timerName)
    if MultiBot.timer[timerName] and type(MultiBot.timer[timerName].elapsed) == "number" then
      MultiBot.timer[timerName].elapsed = 0
    end
  end
  if name then
    resetOne(name)
  else
    resetOne("stats"); resetOne("talent"); resetOne("invite"); resetOne("sort")
  end
end

-- Write + clamp + immediate apply
function MultiBot.SetTimer(name, value)
  if type(value) ~= "number" then return end
  if value < 0.1 then value = 0.1 end
  if value > 600 then value = 600 end

  local config = getConfigStore()
  config.timers = config.timers or {}
  config.timers[name] = value

  if MultiBot and MultiBot.timer and MultiBot.timer[name] then
    MultiBot.timer[name].interval = value
  end
  MultiBot.ApplyTimerChanges(name)
end

-- Throttle: read
function MultiBot.GetThrottleRate()
  local config = getConfigStore()
  return (config and config.throttle and config.throttle.rate) or THROTTLE_DEFAULTS.rate
end

function MultiBot.GetThrottleBurst()
  local config = getConfigStore()
  return (config and config.throttle and config.throttle.burst) or THROTTLE_DEFAULTS.burst
end

-- Throttle: write + immediate apply
function MultiBot.SetThrottleRate(value)
  if type(value) ~= "number" then return end
  if value < 1 then value = 1 end
  if value > 50 then value = 50 end

  local config = getConfigStore()
  config.throttle = config.throttle or {}
  config.throttle.rate = value

  if MultiBot._ThrottleStats then
    MultiBot._ThrottleStats(config.throttle.rate, MultiBot.GetThrottleBurst())
  end
end

function MultiBot.SetThrottleBurst(value)
  if type(value) ~= "number" then return end
  if value < 1 then value = 1 end
  if value > 100 then value = 100 end

  local config = getConfigStore()
  config.throttle = config.throttle or {}
  config.throttle.burst = value

  if MultiBot._ThrottleStats then
    MultiBot._ThrottleStats(MultiBot.GetThrottleRate(), config.throttle.burst)
  end
end
