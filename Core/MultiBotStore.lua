-- MultiBotStore.lua
MultiBot = MultiBot or {}
MultiBot.Store = MultiBot.Store or {}

local Store = MultiBot.Store

local function normalizeMigrationEntries(migrations)
  if type(migrations) ~= "table" then
    return
  end

  for key, value in pairs(migrations) do
    if type(value) ~= "number" then
      migrations[key] = nil
    end
  end
end

local function getLegacyRoot(createIfMissing)
  local legacy = _G.MultiBotDB
  if type(legacy) == "table" then
    return legacy
  end
  if not createIfMissing then
    return nil
  end
  legacy = {}
  _G.MultiBotDB = legacy
  return legacy
end

function Store.GetProfileStore()
  if MultiBot.db and type(MultiBot.db.profile) == "table" then
    return MultiBot.db.profile
  end
  return getLegacyRoot(false)
end

function Store.EnsureProfileStore()
  if MultiBot.db and type(MultiBot.db.profile) == "table" then
    return MultiBot.db.profile
  end
  return getLegacyRoot(true)
end

function Store.GetUIStore()
  local profile = Store.GetProfileStore()
  if type(profile) ~= "table" then
    return nil
  end
  if type(profile.ui) ~= "table" then
    return nil
  end
  return profile.ui
end

function Store.EnsureUIStore()
  local profile = Store.EnsureProfileStore()
  profile.ui = profile.ui or {}
  return profile.ui
end

function Store.GetUIChildStore(childKey)
  if type(childKey) ~= "string" or childKey == "" then
    return nil
  end

  local ui = Store.GetUIStore()
  if type(ui) ~= "table" then
    return nil
  end

  local child = ui[childKey]
  if type(child) ~= "table" then
    return nil
  end

  return child
end

function Store.EnsureUIChildStore(childKey)
  if type(childKey) ~= "string" or childKey == "" then
    return nil
  end

  local ui = Store.EnsureUIStore()
  ui[childKey] = ui[childKey] or {}
  return ui[childKey]
end

function Store.GetUIValue(key)
  if type(key) ~= "string" or key == "" then
    return nil
  end

  local ui = Store.GetUIStore()
  if type(ui) ~= "table" then
    return nil
  end

  return ui[key]
end

function Store.SetUIValue(key, value)
  if type(key) ~= "string" or key == "" then
    return nil
  end

  local ui = Store.EnsureUIStore()
  ui[key] = value
  return value
end

function Store.GetMigrationStore()
  local profile = Store.GetProfileStore()
  if type(profile) ~= "table" then
    return nil
  end

  local migrations = profile.migrations
  if type(migrations) ~= "table" then
    return nil
  end

  normalizeMigrationEntries(migrations)
  return migrations
end

function Store.EnsureMigrationStore()
  local profile = Store.EnsureProfileStore()
  profile.migrations = profile.migrations or {}
  normalizeMigrationEntries(profile.migrations)
  return profile.migrations
end

function Store.GetFavoritesStore()
  local profile = Store.GetProfileStore()
  if type(profile) ~= "table" then
    return nil
  end

  if type(profile.favorites) ~= "table" then
    return nil
  end

  return profile.favorites
end

function Store.EnsureFavoritesStore()
  local profile = Store.EnsureProfileStore()
  profile.favorites = profile.favorites or {}
  return profile.favorites
end

function Store.IsValidGlobalBotRosterEntry(value)
  if type(value) ~= "string" then
    return false
  end

  return value:match("^[^,]+,%[[^%]]+%],[^,]*,%d+/%d+/%d+,[^,]+,%-?%d+,%-?%d+$") ~= nil
end

function Store.SanitizeGlobalBotStore(store)
  if type(store) ~= "table" then
    return
  end

  for botName, value in pairs(store) do
    if type(botName) ~= "string" or not Store.IsValidGlobalBotRosterEntry(value) then
      store[botName] = nil
    end
  end
end

function Store.GetBotsStore()
  local profile = Store.GetProfileStore()
  if type(profile) ~= "table" then
    return nil
  end

  if type(profile.bots) ~= "table" then
    return nil
  end

  return profile.bots
end

function Store.EnsureBotsStore()
  local profile = Store.EnsureProfileStore()
  profile.bots = profile.bots or {}
  return profile.bots
end

function Store.GetMainBarStore()
  local ui = Store.GetUIStore()
  if type(ui) ~= "table" then
    return nil
  end
  if type(ui.mainBar) ~= "table" then
    return nil
  end
  return ui.mainBar
end

function Store.EnsureMainBarStore()
  local ui = Store.EnsureUIStore()
  ui.mainBar = ui.mainBar or {}
  return ui.mainBar
end

function Store.NormalizeMainBarSettings(mainBar, defaults)
  if type(mainBar) ~= "table" then
    return
  end

  if type(mainBar.moveLocked) ~= "boolean" then
    mainBar.moveLocked = defaults.moveLocked
  end
  if type(mainBar.disableAutoCollapse) ~= "boolean" then
    mainBar.disableAutoCollapse = defaults.disableAutoCollapse
  end
  if type(mainBar.autoHideEnabled) ~= "boolean" then
    mainBar.autoHideEnabled = defaults.autoHideEnabled
  end
  if type(mainBar.autoHideDelay) ~= "number" or mainBar.autoHideDelay <= 0 then
    mainBar.autoHideDelay = defaults.autoHideDelay
  end
end