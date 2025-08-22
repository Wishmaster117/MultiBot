-- MultiBotConfig.lua
-- print("MultiBotConfig.lua loaded")
MultiBot = MultiBot or {}

-- Valeurs d'origine (en secondes) : gardées à l'identique
local DEFAULTS = {
  stats  = 45, -- ping "stats"
  talent = 3,  -- application auto des talents
  invite = 5,  -- boucle d'invitations
  sort   = 1,  -- tri/rafraîchissement
}

local THROTTLE_DEFAULTS = { 
  rate = 5, 
  burst = 8 
}

-- Assure l'existence de la SavedVariables et des clés
function MultiBot.Config_Ensure()
  MultiBotDB = MultiBotDB or {}

  -- Timers
  MultiBotDB.timers = MultiBotDB.timers or {}
  for k, v in pairs(DEFAULTS) do
    if type(MultiBotDB.timers[k]) ~= "number" or MultiBotDB.timers[k] <= 0 then
      MultiBotDB.timers[k] = v
    end
  end

  -- Throttle (DB)
  MultiBotDB.throttle = MultiBotDB.throttle or {}
  if type(MultiBotDB.throttle.rate) ~= "number" or MultiBotDB.throttle.rate <= 0 then
    MultiBotDB.throttle.rate = THROTTLE_DEFAULTS.rate
  end
  if type(MultiBotDB.throttle.burst) ~= "number" or MultiBotDB.throttle.burst <= 0 then
    MultiBotDB.throttle.burst = THROTTLE_DEFAULTS.burst
  end
end

-- Recopie les valeurs sauvegardées vers les timers runtime
function MultiBot.ApplyTimersToRuntime()
  if not (MultiBot and MultiBot.timer) then return end
  for k, v in pairs(MultiBotDB.timers or {}) do
    MultiBot.timer[k] = MultiBot.timer[k] or { elapsed = 0, interval = v }
    MultiBot.timer[k].interval = v
  end
end

-- Lecture
function MultiBot.GetTimer(name)
  if MultiBotDB and MultiBotDB.timers then
    return MultiBotDB.timers[name]
  end
  return DEFAULTS[name]
end

-- Réinitialise les compteurs elapsed (un ou tous)
function MultiBot.ApplyTimerChanges(name)
  if not (MultiBot and MultiBot.timer) then return end
  local function resetOne(n)
    if MultiBot.timer[n] and type(MultiBot.timer[n].elapsed) == "number" then
      MultiBot.timer[n].elapsed = 0
    end
  end
  if name then
    resetOne(name)
  else
    resetOne("stats"); resetOne("talent"); resetOne("invite"); resetOne("sort")
  end
end

-- Écriture + clamp + application immédiate
function MultiBot.SetTimer(name, value)
  if not (MultiBotDB and MultiBotDB.timers) then return end
  if type(value) ~= "number" then return end
  if value < 0.1 then value = 0.1 end
  if value > 600 then value = 600 end
  MultiBotDB.timers[name] = value

  -- Applique au runtime si présent
  if MultiBot and MultiBot.timer and MultiBot.timer[name] then
    MultiBot.timer[name].interval = value
  end
  MultiBot.ApplyTimerChanges(name) -- remet elapsed=0 pour ce timer
end

-- Throttle: lecture
function MultiBot.GetThrottleRate()  return (MultiBotDB and MultiBotDB.throttle and MultiBotDB.throttle.rate)  or 5 end
function MultiBot.GetThrottleBurst() return (MultiBotDB and MultiBotDB.throttle and MultiBotDB.throttle.burst) or 8 end

-- Throttle: écriture + application immédiate
function MultiBot.SetThrottleRate(v)
  if type(v) ~= "number" then return end
  if v < 1 then v = 1 end
  if v > 50 then v = 50 end
  MultiBotDB.throttle = MultiBotDB.throttle or {}
  MultiBotDB.throttle.rate = v
  if MultiBot._ThrottleStats then MultiBot._ThrottleStats(MultiBotDB.throttle.rate, MultiBot.GetThrottleBurst()) end
end

function MultiBot.SetThrottleBurst(v)
  if type(v) ~= "number" then return end
  if v < 1 then v = 1 end
  if v > 100 then v = 100 end
  MultiBotDB.throttle = MultiBotDB.throttle or {}
  MultiBotDB.throttle.burst = v
  if MultiBot._ThrottleStats then MultiBot._ThrottleStats(MultiBot.GetThrottleRate(), MultiBotDB.throttle.burst) end
end
