MultiBot = CreateFrame("Frame", nil, UIParent)

-- GM core --
MultiBot.GM = MultiBot.GM or false

function MultiBot.ApplyGMVisibility() end

function MultiBot.SetGM(isGM)
  isGM = not not isGM
  if MultiBot.GM ~= isGM then
    MultiBot.GM = isGM
    if MultiBot.ApplyGMVisibility then MultiBot.ApplyGMVisibility() end
  end
end
-- end GM core --

-- UI helper: promote a frame to the foreground without breaking tooltips
function MultiBot.PromoteFrame(f, strata)
  if not f or not f.SetFrameStrata then return end
  -- Add a default fallback kept at "DIALOG" to avoid regressions and it's safer
  local level = strata or (MultiBotGlobalSave and MultiBotGlobalSave["Strata.Level"]) or "HIGH"
  f:SetFrameStrata(level)
  if f.SetToplevel then f:SetToplevel(true) end
  if f.HookScript then
    f:HookScript("OnShow", function(self) if self.Raise then self:Raise() end end)
  end
end

function MultiBot.ApplyGlobalStrata()
  local level = (MultiBotGlobalSave and MultiBotGlobalSave["Strata.Level"]) or nil
  if not MultiBot.frames then return end
  --for name, frm in pairs(MultiBot.frames) do
    for _, frm in pairs(MultiBot.frames) do
    if type(frm) == "table" and frm.SetFrameStrata then
      MultiBot.PromoteFrame(frm, level)
    end
  end
end

-- Account level detection (multi-locale, no hardcoding in handler) --
-- Set your GM threshold here (>= value means GM). ONLY set it once.
MultiBot.GM_THRESHOLD = 3

-- DEBUG (set to true temporarily if you want to see what gets parsed)
MultiBot.DEBUG_GM = false

-- Multi-language patterns that capture the level number.
-- We anchor to "account level" but allow anything between it and the number (e.g. "is: ").
MultiBot._acctlvl_patterns = {
  -- EN (covers "Your account level is: 3")
  "[Aa]ccount%W*[Ll]evel.-(%d+)",
  -- FR
  "[Nn]iveau%W*de%W*compte.-(%d+)",
  -- ES
  "[Nn]ivel%W*de%W*cuenta.-(%d+)",
  -- DE (Accountstufe/Kontostufe)
  "[Aa]ccount%W*[Ss]tufe.-(%d+)",
  "[Kk]onto%W*[Ss]tufe.-(%d+)",
  -- RU
  "Уровень%W*аккаунта.-(%d+)",
  -- ZH
  "账号%W*等级.-(%d+)",
  "帳號%W*等級.-(%d+)",
  -- KO
  "계정%W*등급.-(%d+)",
}

-- Fallbacks:
--  1) number after ':' near the end ("...: 3")
--  2) last number in a short line (avoid collisions)
local function _acctlvl_fallbacks(msg)
  local n = tonumber(string.match(msg, "[:：]%s*(%d+)%s*$"))
  if n then return n end
  if #msg <= 60 then
    local last = nil
    for d in string.gmatch(msg, "(%d+)") do last = d end
    if last then return tonumber(last) end
  end
  return nil
end

function MultiBot.ParseAccountLevel(msg)
  if type(msg) ~= "string" then return nil end

  -- Explicit fast-path for the common EN string:
  local capEN = msg:match("[Yy]our%W*[Aa]ccount%W*[Ll]evel%W*is%W*:%s*(%d+)")
  if capEN then return tonumber(capEN) end

  -- Try known patterns
  for _, pat in ipairs(MultiBot._acctlvl_patterns) do
    local cap = msg:match(pat)
    if cap then
      local n = tonumber(cap)
      if n then return n end
    end
  end

  -- Fallbacks
  return _acctlvl_fallbacks(msg)
end

function MultiBot.GM_DetectFromSystem(msg)
  local lvl = MultiBot.ParseAccountLevel(msg)
  MultiBot.LastAccountLevel = lvl

  if MultiBot.DEBUG_GM and DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage(
      ("[GMDetect] msg='%s' -> lvl=%s, thr=%d"):format(
        tostring(msg),
        tostring(lvl),
        MultiBot.GM_THRESHOLD
      )
    )
  end

  if lvl ~= nil then
    MultiBot.SetGM(lvl >= (MultiBot.GM_THRESHOLD or 2))
    if MultiBot.DEBUG_GM and DEFAULT_CHAT_FRAME then
      DEFAULT_CHAT_FRAME:AddMessage(("[GMDetect] GM=%s"):format(tostring(MultiBot.GM)))
    end
    --if MultiBot.RaidPool then MultiBot.RaidPool("player") end
    if MultiBot.RaidPool then
      -- petit helper timer si absent
      C_Timer_After = C_Timer_After or function(sec, func)
        local f, t = CreateFrame("Frame"), 0
        f:SetScript("OnUpdate", function(_, dt)
          t = t + dt
          if t >= sec then f:SetScript("OnUpdate", nil); func() end
        end)
      end
      C_Timer_After(0.2, function() MultiBot.RaidPool("player") end)
    end
    return true
  end
  return false
end

-- end account level detection --

MultiBot:RegisterEvent("ADDON_LOADED")
MultiBot:RegisterEvent("WORLD_MAP_UPDATE")
MultiBot:RegisterEvent("PLAYER_ENTERING_WORLD")
MultiBot:RegisterEvent("PLAYER_TARGET_CHANGED")
MultiBot:RegisterEvent("PLAYER_LOGOUT")
MultiBot:RegisterEvent("CHAT_MSG_WHISPER")
MultiBot:RegisterEvent("CHAT_MSG_SYSTEM")
MultiBot:RegisterEvent("CHAT_MSG_ADDON")
MultiBot:RegisterEvent("CHAT_MSG_LOOT")
MultiBot:RegisterEvent("QUEST_COMPLETE")
MultiBot:RegisterEvent("QUEST_LOG_UPDATE")
MultiBot:RegisterEvent("TRADE_CLOSED")
-- GLYPHES --
MultiBot:RegisterEvent("INSPECT_READY")

-- QUESTS --
MultiBot:RegisterEvent("CHAT_MSG_PARTY")
MultiBot:RegisterEvent("CHAT_MSG_RAID")

MultiBot:SetPoint("BOTTOMRIGHT", 0, 0)
MultiBot:SetSize(1, 1)
MultiBot:Show()

-- ============================================================================
-- SANITY : reconstruire l'index 'players' à partir des boutons existants
-- ============================================================================
function MultiBot.RebuildPlayersIndexFromButtons()
  if not (MultiBot.frames and MultiBot.frames["MultiBar"]
          and MultiBot.frames["MultiBar"].frames
          and MultiBot.frames["MultiBar"].frames["Units"]) then
    return
  end
  local units = MultiBot.frames["MultiBar"].frames["Units"]
  local buttons = units.buttons or {}
  MultiBot.index.players = {}
  MultiBot.index.classes.players = {}
  for name, btn in pairs(buttons) do
    if btn and (btn.roster == "players" or btn.roster == nil) then
      table.insert(MultiBot.index.players, name)
      local cls = (btn.class and MultiBot.toClass(btn.class)) or "UNKNOWN"
      MultiBot.index.classes.players[cls] = MultiBot.index.classes.players[cls] or {}
      table.insert(MultiBot.index.classes.players[cls], name)
    end
  end
end

-- MultiBotSave = {}
-- MultiBotGlobalSave = {}
MultiBotSave = MultiBotSave or {}
MultiBotGlobalSave = MultiBotGlobalSave or {}
MultiBot.data = {}
MultiBot.index = {}
MultiBot.index.classes = {}
MultiBot.index.classes.actives = {}
MultiBot.index.classes.players = {}
MultiBot.index.classes.members = {}
MultiBot.index.classes.friends = {}
-- Per-character favorites
MultiBot.index.classes.favorites = {}
MultiBot.index.actives = {}
MultiBot.index.players = {}
MultiBot.index.members = {}
MultiBot.index.friends = {}
MultiBot.index.raidus = {}
MultiBot.index.favorites = {}
MultiBot.spells = {}
MultiBot.frames = {}
MultiBot.units = {}
MultiBot.tips = {}
MultiBot.tips.spec = MultiBot.tips.spec or {}
MultiBotSave.Minimap = MultiBotSave.Minimap or {}

MultiBot.auto = {}
MultiBot.auto.sort = false
MultiBot.auto.stats = false
MultiBot.auto.talent = false
MultiBot.auto.invite = false
MultiBot.auto.release = false
--MultiBot.auto.language = true

-- =========================
-- DEBUG helpers (trace chat)
-- =========================
MultiBot.debug = false
local function MB_tostring(v)
  if type(v) == "table" then
    local ok, s = pcall(function() return tostring(v) end)
    if ok then return s else return "<table>" end
  end
  return tostring(v)
end
function MultiBot.dprint(...)
  if not MultiBot.debug then return end
  local parts = {}
  for i=1,select("#", ...) do
    parts[#parts+1] = MB_tostring(select(i, ...))
  end
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff7f00[MultiBot]|r ".. table.concat(parts, " "))
  else
    print("[MultiBot] ".. table.concat(parts, " "))
  end
end


-- ============================================================================
-- FAVORITES (per-character)
-- ============================================================================
function MultiBot.EnsureFavorites()
  MultiBotSave = MultiBotSave or {}
  MultiBotSave.Favorites = MultiBotSave.Favorites or {}
end

function MultiBot.IsFavorite(name)
  return MultiBotSave and MultiBotSave.Favorites and MultiBotSave.Favorites[name] == true
end

function MultiBot.UpdateFavoritesIndex()
  MultiBot.index.favorites = {}
  MultiBot.index.classes.favorites = {}
  for name, _ in pairs(MultiBotSave.Favorites or {}) do
    table.insert(MultiBot.index.favorites, name)
    local cls = nil
    -- 1) si le bouton d’unité existe déjà, on prend sa classe
    local units = nil
    if MultiBot.frames and MultiBot.frames["MultiBar"]
       and MultiBot.frames["MultiBar"].frames
       and MultiBot.frames["MultiBar"].frames["Units"]
    then
      units = MultiBot.frames["MultiBar"].frames["Units"]
    end
    local buttons = units and units.buttons or nil
    if buttons and buttons[name] and buttons[name].class then
      cls = buttons[name].class
    else
      -- 2) sinon on essaie via l’index players (après parsing bot list)
      local byClass = MultiBot.index and MultiBot.index.classes and MultiBot.index.classes.players
      if byClass then
        for c, arr in pairs(byClass) do
          for i = 1, (arr and #arr or 0) do
            if arr[i] == name then cls = c break end
          end
          if cls then break end
        end
      end
    end
    cls = cls or "UNKNOWN"
    MultiBot.index.classes.favorites[cls] = MultiBot.index.classes.favorites[cls] or {}
    table.insert(MultiBot.index.classes.favorites[cls], name)
  end
end

function MultiBot.SetFavorite(name, isFav)
  MultiBot.EnsureFavorites()
  if isFav then MultiBotSave.Favorites[name] = true
           else MultiBotSave.Favorites[name] = nil
  end
  MultiBot.UpdateFavoritesIndex()
end

function MultiBot.ToggleFavorite(name)
  MultiBot.SetFavorite(name, not MultiBot.IsFavorite(name))
end

MultiBot.timer = {}
MultiBot.timer.sort = {}
MultiBot.timer.sort.elapsed = 0
MultiBot.timer.sort.interval = 1
MultiBot.timer.stats = {}
MultiBot.timer.stats.elapsed = 0
MultiBot.timer.stats.interval = 45
MultiBot.timer.talent = {}
MultiBot.timer.talent.elapsed = 0
MultiBot.timer.talent.interval = 3
MultiBot.timer.invite = {}
MultiBot.timer.invite.elapsed = 0
MultiBot.timer.invite.interval = 5

-- CLASSES --

--[[MultiBot.data.classes = {}
MultiBot.data.classes.input = {
[1] = "DeathKnight",
[2] = "Druid",
[3] = "Hunter",
[4] = "Mage",
[5] = "Paladin",
[6] = "Priest",
[7] = "Rogue",
[8] = "Shaman",
[9] = "Warlock",
[10] = "Warrior"
}

MultiBot.data.classes.output = {
[1] = "DeathKnight",
[2] = "Druid",
[3] = "Hunter",
[4] = "Mage",
[5] = "Paladin",
[6] = "Priest",
[7] = "Rogue",
[8] = "Shaman",
[9] = "Warlock",
[10] = "Warrior"
}]]--

-- CLASSES (canonical + backward-compat)
MultiBot.CLASSES_CANON = {
  "DeathKnight","Druid","Hunter","Mage","Paladin",
  "Priest","Rogue","Shaman","Warlock","Warrior"
}

MultiBot.data = MultiBot.data or {}
MultiBot.data.classes = MultiBot.data.classes or {}

local function _mb_copy(a)
  local r = {}
  for i,v in ipairs(a) do r[i] = v end
  return r
end

-- Back-compat: si du code existant lit encore ces tables, on lui fournit la même liste.
-- (On copie pour éviter les mutations involontaires.)
MultiBot.data.classes.input  = MultiBot.data.classes.input  or _mb_copy(MultiBot.CLASSES_CANON)
MultiBot.data.classes.output = MultiBot.data.classes.output or _mb_copy(MultiBot.CLASSES_CANON)

-- Construction des maps
function MultiBot.BuildClassMaps()
  if MultiBot._classMapsBuilt then return end
  MultiBot._classMapsBuilt = true

  local male   = _G.LOCALIZED_CLASS_NAMES_MALE   or {}
  local female = _G.LOCALIZED_CLASS_NAMES_FEMALE or {}
  local upper = {
    DeathKnight="DEATHKNIGHT", Druid="DRUID", Hunter="HUNTER", Mage="MAGE",
    Paladin="PALADIN", Priest="PRIEST", Rogue="ROGUE", Shaman="SHAMAN",
    Warlock="WARLOCK", Warrior="WARRIOR",
  }

  MultiBot.CLASS_ALIAS = {}

  local function add(alias, canon)
    if alias and alias ~= "" then
      MultiBot.CLASS_ALIAS[string.lower(alias)] = canon
    end
  end

  for _, canon in ipairs(MultiBot.CLASSES_CANON) do
    local token = upper[canon]
    -- variantes évidentes
    add(canon, canon)             -- "DeathKnight"
    add(token, canon)             -- "DEATHKNIGHT"
    add(string.lower(canon), canon)
    add(string.lower(token), canon)

    -- noms localisés (homme/femme) si dispo
    add(male[token],   canon)
    add(female[token], canon)

    -- alias fréquents libres
    if canon == "DeathKnight" then
      add("death knight", canon); add("dk", canon)
    elseif canon == "Warlock" then
      add("lock", canon)
    elseif canon == "Paladin" then
      add("pala", canon)
    elseif canon == "Shaman" then
      add("sham", canon)
    end
  end

  -- alias par locale
  local loc = GetLocale and GetLocale() or "enUS"
  MultiBot.CLASS_EXTRA_ALIASES = MultiBot.CLASS_EXTRA_ALIASES or {
    frFR = { ["chevalier de la mort"]="DeathKnight", ["cdm"]="DeathKnight", ["prêtre"]="Priest" },
    deDE = { ["todesritter"]="DeathKnight" },
    esES = { ["caballero de la muerte"]="DeathKnight" },
    ruRU = { ["рыцарь смерти"]="DeathKnight" },
    zhCN = { ["死亡骑士"]="DeathKnight" },
    zhTW = { ["死亡騎士"]="DeathKnight" },
    koKR = { ["죽음의 기사"]="DeathKnight" },
  }
  local extra = MultiBot.CLASS_EXTRA_ALIASES[loc]
  if extra then
    for alias, canon in pairs(extra) do add(alias, canon) end
  end
end

-- Retourne le canon "DeathKnight"/"Mage"/... à partir d’un texte libre (toutes langues)
function MultiBot.NormalizeClass(text)
  if not text then return nil end
  MultiBot.BuildClassMaps()
  local key = string.lower((tostring(text):gsub("%s+", " ")))
  return MultiBot.CLASS_ALIAS[key]
end

-- Texte à afficher pour une classe canon (localisé si possible)
function MultiBot.GetClassDisplay(canon)
  if not canon then return nil end
  local upper = {
    DeathKnight="DEATHKNIGHT", Druid="DRUID", Hunter="HUNTER", Mage="MAGE",
    Paladin="PALADIN", Priest="PRIEST", Rogue="ROGUE", Shaman="SHAMAN",
    Warlock="WARLOCK", Warrior="WARRIOR",
  }
  local token = upper[canon]
  local male = _G.LOCALIZED_CLASS_NAMES_MALE or {}
  return male[token] or canon
end
-- end CLASS DETECTION --

--  Compatibility API for refactored
if not IsInRaid then
  -- Client 3.3.5 compatibility
  function IsInRaid()
    return GetNumRaidMembers() > 0
  end
end

if not IsInGroup then
  function IsInGroup()              -- Define if it's a raid or party
    return IsInRaid() or GetNumPartyMembers() > 0
  end
end

if not GetNumGroupMembers then
  -- Wrath : "raid" only
  function GetNumGroupMembers()
    return GetNumRaidMembers()
  end
end

if not GetNumSubgroupMembers then
  -- Number of members in party (without player) in Wrath
  function GetNumSubgroupMembers()
    return GetNumPartyMembers()
  end
end

--  AddClassToTarget Wrapper
-- Usage : MultiBot.AddClassToTarget("warlock"        ) -- Random
--         MultiBot.AddClassToTarget("warlock","male" ) -- Male
--         MultiBot.AddClassToTarget("warlock","female") -- Female
MultiBot.AddClassToTarget = function(classCmd, gender)
  if not classCmd then return end             -- secure that
  local msg = ".playerbot bot addclass " .. classCmd
  if gender then                                 -- male / female / 0 / 1
	msg = msg .. " " .. gender
	print("[DBG] Message de sortie :" ,msg)
  end
  SendChatMessage(msg, "SAY")
end

-- Init Wrapper
function MultiBot.InitAuto(name)
  SendChatMessage(".playerbot bot init=auto " .. name, "SAY")
end

-- INFO --

MultiBot.info = {}
MultiBot.info.shorts = {}

-- ITEMS
MultiBot.info.itemdestroyalert =
"Do you REALLY want to destroy this item?\n%s";

MultiBot.info.keydestroyalert =
"I will not sell Keys.";

MultiBot.info.itemsellalert =
"I cant sell this Item.";

-- MINIMAP BUTTON
MultiBot.info.butttitle =
"|cffffd100MultiBot|r"

MultiBot.info.buttontoggle =
"|cff00ff00Left-click: toggle UI|r";

MultiBot.info.buttonoptions =
"|cffff0000Right-click: options|r";

MultiBot.info.buttonoptionshide =
"Hide minimap button";

MultiBot.info.buttonoptionshidetooltip =
"Hide or show the MultiBot minimap button.\n(Left-click: toggle UI, Right-click: open options)";

-- GLYPHS
MultiBot.info.glyphssocketnotunlocked =
"This socket is not yet unlocked.";

MultiBot.info.glyphswrongclass =
"This glyph is not for the bot's class.";

MultiBot.info.glyphsunknowglyph =
"Unable to identify this glyph.";

MultiBot.info.glyphsglyphtype =
"Glyphe type ";

MultiBot.info.glyphsglyphsocket =
"wrong socket.";

MultiBot.info.glyphsleveltoolow =
"Level too low for this glyph.";

MultiBot.info.glyphscustomglyphsfor =
"Custom Glyphs for";

MultiBot.info.glyphsglyphsfor =
"Glyphs for";

MultiBot.info.talentscustomtalentsfor =
"Custom Talents for";

-- Hunter

MultiBot.info.hunterpeteditentervalue =
"Enter value";

MultiBot.info.hunterpetcreaturelist =
"Pets List by Name";

MultiBot.info.hunterpetnewname =
"New pet name";

MultiBot.info.hunterpetid =
"Pet ID";

MultiBot.info.hunterpetentersomething =
"Enter Something here...";

MultiBot.info.hunterpetrandomfamily =
"Random by Family";

-- end Hunter

MultiBot.info.command =
"Command not found.";

MultiBot.info.target =
"I dont have a Target.";

MultiBot.info.classes =
"The Classes do not match.";

MultiBot.info.levels =
"The Levels do not match.";

MultiBot.info.spell =
"I couldnt identify the Spell.";

MultiBot.info.macro =
"I have already the maximum of private Macros.";

MultiBot.info.neither =
"I neither have a Target nor am I in a Raid or Party.";

MultiBot.info.group =
"I neither in a Raid nor in a Party.";

MultiBot.info.inviting =
"Inviting NAME to the Group.";

MultiBot.info.combat =
"Asked NAME for Combat-Strategies.";

MultiBot.info.teleport =
"will teleport you to 'MAP - ZONE'";

MultiBot.info.normal =
"Asked NAME for Non-Combat-Strategies.";

MultiBot.info.inventory =
"Inventory of NAME";

MultiBot.info.spellbook =
"Spellbook of NAME";

MultiBot.info.player =
"I wont Auto-Initialize 'NAME' from the Playerbot-Roster.";

MultiBot.info.member =
"I wont Auto-Initialize 'NAME' from the Guild-Roster.";

MultiBot.info.players =
"I wont Auto-Initialize anyone from the Playerbot-Roster.";

MultiBot.info.members =
"I wont Auto-Initialize anyone from the Guild-Roster.";

MultiBot.info.wait =
"I already invite Members, please wait until I am done.";

MultiBot.info.starting =
"Starting to invite Members.";

MultiBot.info.stats =
"Auto-Stats is for Party's not for a Raid's.";

MultiBot.info.location =
"has no Location stored inside.";

MultiBot.info.itlocation =
"It has no Location stored inside.";

MultiBot.info.saving =
"I am still in the process of saving my position.";

MultiBot.info.action =
"I need to select a Action.";

MultiBot.info.combination =
"There are no Items for this Combination.";

--MultiBot.info.language =
--"I need to activate the Language-Selector first.";

MultiBot.info.rights =
"I have not the GameMaster-Rights.";

MultiBot.info.reward =
"Select the Rewards";

MultiBot.info.nothing =
"Nothing is saved in this Slot.";

MultiBot.info.shorts.bag =
"Bag";

MultiBot.info.shorts.dur =
"Dur";

MultiBot.info.shorts.xp =
"XP";

MultiBot.info.shorts.mp =
"MP";

-- INFO:TALENT --

MultiBot.info.talent = {}

MultiBot.info.talent.Level =
"His Level lower than 10.";

MultiBot.info.talent.OutOfRange =
"The Bot is out of Range.";

MultiBot.info.talent.Apply =
"Apply";

MultiBot.info.talent.Copy =
"Copy";

MultiBot.info.talent.Title =
"Talents from NAME";

MultiBot.info.talent.Points =
"|cffffcc00Unspent Talents: |r";

MultiBot.info.talent.DeathKnight1 =
"|cffffcc00Blood|r";

MultiBot.info.talent.DeathKnight2 =
"|cffffcc00Frost|r";

MultiBot.info.talent.DeathKnight3 =
"|cffffcc00Unholy|r";

MultiBot.info.talent.Druid1 =
"|cffffcc00Balance|r";

MultiBot.info.talent.Druid2 =
"|cffffcc00Feral Combat|r";

MultiBot.info.talent.Druid3 =
"|cffffcc00Restoration|r";

MultiBot.info.talent.Hunter1 =
"|cffffcc00Beast Mastery|r";

MultiBot.info.talent.Hunter2 =
"|cffffcc00Marksmanship|r";

MultiBot.info.talent.Hunter3 =
"|cffffcc00Survival|r";

MultiBot.info.talent.Mage1 =
"|cffffcc00Arcane|r";

MultiBot.info.talent.Mage2 =
"|cffffcc00Fire|r";

MultiBot.info.talent.Mage3 =
"|cffffcc00Frost|r";

MultiBot.info.talent.Paladin1 =
"|cffffcc00Holy|r";

MultiBot.info.talent.Paladin2 =
"|cffffcc00Protection|r";

MultiBot.info.talent.Paladin3 =
"|cffffcc00Retribution|r";

MultiBot.info.talent.Priest1 =
"|cffffcc00Discipline|r";

MultiBot.info.talent.Priest2 =
"|cffffcc00Holy|r";

MultiBot.info.talent.Priest3 =
"|cffffcc00Shadow|r";

MultiBot.info.talent.Rogue1 =
"|cffffcc00Assassination|r";

MultiBot.info.talent.Rogue2 =
"|cffffcc00Combat|r";

MultiBot.info.talent.Rogue3 =
"|cffffcc00Subtlety|r";

MultiBot.info.talent.Shaman1 =
"|cffffcc00Elemental|r";

MultiBot.info.talent.Shaman2 =
"|cffffcc00Enhancement|r";

MultiBot.info.talent.Shaman3 =
"|cffffcc00Restoration|r";

MultiBot.info.talent.Warlock1 =
"|cffffcc00Affliction|r";

MultiBot.info.talent.Warlock2 =
"|cffffcc00Demonology|r";

MultiBot.info.talent.Warlock3 =
"|cffffcc00Destruction|r";

MultiBot.info.talent.Warrior1 =
"|cffffcc00Arms|r";

MultiBot.info.talent.Warrior2 =
"|cffffcc00Fury|r";

MultiBot.info.talent.Warrior3 =
"|cffffcc00Protection|r";

-- MOVE --

MultiBot.tips.move = {}
MultiBot.tips.move.inventory =
"Right-Click to drag and move the Inventory";

MultiBot.tips.move.stats =
"Right-Click to drag and move Auto-Stats";

MultiBot.tips.move.itemus =
"Right-Click to drag and move Itemus";

MultiBot.tips.move.iconos =
"Right-Click to drag and move Iconos";

MultiBot.tips.move.spellbook =
"Right-Click to drag and move the Spellbook";

MultiBot.tips.move.reward =
"Right-Click to drag and move the Reward-Selector";

MultiBot.tips.move.talent =
"Right-Click to drag and move the Talents";

MultiBot.tips.move.raidus =
"Right-Click to drag and move the Raidus";

-- TANKER --

MultiBot.tips.tanker = {}
MultiBot.tips.tanker.master =
"Tank-Attack\n|cffffffff"..
"With this Button the Tanks starting to attack your target.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Tank-Attack|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- ATTACK --

MultiBot.tips.attack = {}
MultiBot.tips.attack.master =
"Attack-Control\n|cffffffff"..
"With this Control you can give the Command to attack.\n"..
"Right-Click the Options to define a new default Action.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute the default Action|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.attack.attack =
"Attack\n|cffffffff"..
"With this Command the hole Raid or Party starting to attack your target.|r\n\n"..
"|cffff0000Left-Click to execute Attack|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.attack.ranged =
"Ranged-Attack\n|cffffffff"..
"With this Command the Ranged-Fighters starting to attack your target.|r\n\n"..
"|cffff0000Left-Click to execute Ranged-Attack|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.attack.melee =
"Melee-Attack\n|cffffffff"..
"With this Command the Melee-Fighters starting to attack your target.|r\n\n"..
"|cffff0000Left-Click to execute Melee-Attack|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.attack.healer =
"Healer-Attack\n|cffffffff"..
"With this Command the Healers starting to attack your target.|r\n\n"..
"|cffff0000Left-Click to execute Healer-Attack|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.attack.dps =
"DPS-Attack\n|cffffffff"..
"With this Command the DPS starting to attack your target.|r\n\n"..
"|cffff0000Left-Click to execute DPS-Attack|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.attack.tank =
"Tank-Attack\n|cffffffff"..
"With this Command the Tanks starting to attack your target.|r\n\n"..
"|cffff0000Left-Click to execute Tank-Attack|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

-- MODE --

MultiBot.tips.mode = {}
MultiBot.tips.mode.master =
"Mode-Control\n|cffffffff"..
"This Control allows you to switch a Combat-Mode on and off.\n"..
"Left-Click the Options to select another Combat-Mode.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to switch the Combat-Mode|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.mode.passive =
"Passive-Mode\n|cffffffff"..
"In the Passive-Mode, your Bots wont attack any Opponent.\n"..
"This Mode is useful to keep the Tank from running into the Opponents during a pull.\n"..
"The Stay-Command cancels Passive-Mode, in combination Stay should be commanded first.\n"..
"The Follow-Command cancels Passive-Mode, in combination Follow should be commanded first.|r\n\n"..
"|cffff0000Left-Click to select and activate Passive-Mode|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.mode.grind =
"Grind-Mode\n|cffffffff"..
"In the Grind-Mode, your Bots attack Opponent independently.\n"..
"This Mode is usefull to level up your Bots.|r\n\n"..
"|cffff0000Left-Click to selet and activate Grind-Mode|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- STAY|FOLLOW --

MultiBot.tips.stallow = {}
MultiBot.tips.stallow.stay =
"Stay|Follow\n|cffffffff"..
"With this Button you can give right now the Command to Stay.\n"..
"This Command cancels the Passive-Mode, in combination Stay should be commanded first.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Stay|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.stallow.follow =
"Stay|Follow\n|cffffffff"..
"With this Button you can give right now the Command to Follow.\n"..
"This Command cancels the Passive-Mode, in combination Follow should be commanded first.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Follow|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.expand = {}
MultiBot.tips.expand.stay =
"Stay\n|cffffffff"..
"With this Button you can give right now the Command to Stay.\n"..
"This Command cancels the Passive-Mode, in combination Stay should be commanded first.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Stay|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.expand.follow =
"Follow\n|cffffffff"..
"With this Button you can give right now the Command to Follow.\n"..
"This Command cancels the Passive-Mode, in combination Follow should be commanded first.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Follow|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- FLEE --

MultiBot.tips.flee = {}
MultiBot.tips.flee.master =
"Flee-Control\n|cffffffff"..
"With this Control you can give the Command to flee.\n"..
"Right-Click the Options to define a new default Action.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute the default Action|r\n"..
"|cff999999(Execution-Order: 'Target', Raid, Party)|r\n\n"..
"|cffff0000Right-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.flee.flee =
"Flee\n|cffffffff"..
"With this Command the hole Raid or Party starting to flee.|r\n\n"..
"|cffff0000Left-Click to execute Flee|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.flee.ranged =
"Ranged-Flee\n|cffffffff"..
"With this Command the Ranged-Fighters starting to flee.|r\n\n"..
"|cffff0000Left-Click to execute Ranged-Flee|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.flee.melee =
"Melee-Flee\n|cffffffff"..
"With this Command the Melee-Fighters starting to flee.|r\n\n"..
"|cffff0000Left-Click to execute Melee-Flee|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.flee.healer =
"Healer-Flee\n|cffffffff"..
"With this Command the Healers starting to flee.|r\n\n"..
"|cffff0000Left-Click to execute Healer-Flee|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.flee.dps =
"DPS-Flee\n|cffffffff"..
"With this Command the DPS starting to flee.|r\n\n"..
"|cffff0000Left-Click to execute DPS-Flee|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.flee.tank =
"Tank-Flee\n|cffffffff"..
"With this Command the Tanks starting to flee.|r\n\n"..
"|cffff0000Left-Click to execute Tank-Flee|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.flee.target =
"Target-Flee\n|cffffffff"..
"With this Command the Target starting to flee.|r\n\n"..
"|cffff0000Left-Click to execute Target-Flee|r\n"..
"|cff999999(Execution-Order: Target)|r\n\n"..
"|cffff0000Right-Click to define as default Action|r\n"..
"|cff999999(Execution-Order: System)|r";

-- FORMATION --

MultiBot.tips.format = {}
MultiBot.tips.format.master =
"Formation-Control\n|cffffffff"..
"This Control allows you to change the Formation of your Bots.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to ask for the current Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.arrow =
"Arrow-Formation\n|cffffffff"..
"The Bots line up in an arrow formation.\n"..
"The Bots line of sight is in your direction.\n\n"..
"1. Line are Tanks\n"..
"2. Line are Melee-Fighters\n"..
"3. Line are Ranged-Fighters\n"..
"4. Line are Healers|r\n\n"..
"|cffff0000Left-Click to select the Arrow-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.queue =
"Queue-Formation\n|cffffffff"..
"The Bots line up in an defensive formation.\n"..
"The Bots line of sight is in your direction.|r\n\n"..
"|cffff0000Left-Click to select the Queue-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.near =
"Near-Formation\n|cffffffff"..
"The Bots line up near by.\n"..
"The Bots line of sight is in your direction.|r\n\n"..
"|cffff0000Left-Click to select the Near-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.melee =
"Melee-Formation\n|cffffffff"..
"The Bots line up for melee fights.\n"..
"The Bots line of sight is in your direction.|r\n\n"..
"|cffff0000Left-Click to select the Melee-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.line =
"Line-Formation\n|cffffffff"..
"The Bots line up on the left and right side in a parallel line.\n"..
"The Bots line of sight is in your direction.|r\n\n"..
"|cffff0000Left-Click to select the Line-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.circle =
"Circle-Formation\n|cffffffff"..
"The Bots line up in a circle around you.\n"..
"The Bots line of sight is directed outwards.|r\n\n"..
"|cffff0000Left-Click to select the Circle-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.chaos =
"Chaos-Formation\n|cffffffff"..
"Each Bot follows you by its own.\n"..
"They line up everywhere they wont.\n"..
"The line of sight could be every direction.|r\n\n"..
"|cffff0000Left-Click to select the Chaos-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.format.shield =
"Shield-Formation\n|cffffffff"..
"The Bots line up in the front, on the left and right side.\n"..
"The Bots line of sight is in your direction.|r\n\n"..
"|cffff0000Left-Click to select the Shield-Formation|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- BEASTMASTER --

MultiBot.tips.beast = {}
MultiBot.tips.beast.master =
"Beastmaster-Control\n|cffffffff"..
"This Control is for the Mod-NPC-Beastmaster of the Azerothcore.\n"..
"Mod-NPC-Beastmaster allows every Character to have a Pet like Hunters.\n"..
"Your Charaters can learn the nessasary Spells from White Fang.\n"..
"White Fang must be placed into the World by the GameMaster.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.beast.release =
"Release the Beast\n|cffffffff"..
"This Command will release the Beast.|r\n\n"..
"|cffff0000Left-Click to release the Beast|r\n"..
"|cff999999(Execution-Order: Target, Raid, Party)|r";

MultiBot.tips.beast.revive =
"Revive the Beast\n|cffffffff"..
"This Command will revive the Beast.|r\n\n"..
"|cffff0000Left-Click to revive the Beast|r\n"..
"|cff999999(Execution-Order: Target, Raid, Party)|r";

MultiBot.tips.beast.heal =
"Heal the Beast\n|cffffffff"..
"This Command will heal the Beast.|r\n\n"..
"|cffff0000Left-Click to heal the Beast|r\n"..
"|cff999999(Execution-Order: Target, Raid, Party)|r";

MultiBot.tips.beast.feed =
"Feed the Beast\n|cffffffff"..
"This Command will feed the Beast.|r\n\n"..
"|cffff0000Left-Click to feed the Beast|r\n"..
"|cff999999(Execution-Order: Target, Raid, Party)|r";

MultiBot.tips.beast.call =
"Call the Beast\n|cffffffff"..
"This Command will call the Beast.|r\n\n"..
"|cffff0000Left-Click to call the Beast|r\n"..
"|cff999999(Execution-Order: Target, Raid, Party)|r";

-- CREATOR --

MultiBot.tips.creator = {}
MultiBot.tips.creator.master =
"Creator-Control\n|cffffffff"..
"With this Control you can create Bots by Class.\n"..
"The default Limit is 40 Bots per Account.\n"..
"There is no command to delete them after use.\n"..
"So invite them to your Friendlist for reuse.\n"..
"The Execution-Order shows the Receiver for Commands.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.warrior =
"Create-Warrior\n|cffffffff"..
"This Button will create a Bot as Warrior.|r\n\n"..
"|cffff0000Left-Click to choose your Warrior gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.warlock =
"Create-Warlock\n|cffffffff"..
"This Button will create a Bot as Warlock.|r\n\n"..
"|cffff0000Left-Click to choose your Warlock gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.shaman =
"Create-Shaman\n|cffffffff"..
"This Button will create a Bot as Shaman.|r\n\n"..
"|cffff0000Left-Click to choose your Shaman gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.rogue =
"Create-Rogue\n|cffffffff"..
"This Button will create a Bot as Rogue.|r\n\n"..
"|cffff0000Left-Click to choose your Rogue gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.priest =
"Create-Priest\n|cffffffff"..
"This Button will create a Bot as Priest.|r\n\n"..
"|cffff0000Left-Click to choose your Priest gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.paladin =
"Create-Paladin\n|cffffffff"..
"This Button will create a Bot as Paladin.|r\n\n"..
"|cffff0000Left-Click to choose your Paladin gender|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.mage =
"Create-Mage\n|cffffffff"..
"This Button will create a Bot as Mage.|r\n\n"..
"|cffff0000Left-Click to choose your Mage gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.hunter =
"Create-Hunter\n|cffffffff"..
"This Button will create a Bot as Hunter.|r\n\n"..
"|cffff0000Left-Click to choose your Hunter gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.druid =
"Create-Druid\n|cffffffff"..
"This Button will create a Bot as Druid.|r\n\n"..
"|cffff0000Left-Click to choose your Druid gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.deathknight =
"Create-DeathKnight\n|cffffffff"..
"This Button will create a Bot as DeathKnight.|r\n\n"..
"|cffff0000Left-Click to choose your DeathKnight gender.|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.notarget =
"I dont have a Target.";

MultiBot.tips.creator.gendermale =
"Creates a male companion.\n|cffffffff"..
"Strong, bold, and always ready for battle... or ale.|r\n\n"..
"|cffff0000Left-Click to Create|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.genderfemale =
"Creates a female companion.\n|cffffffff"..
"Graceful, fierce, and not to be underestimated.|r\n\n"..
"|cffff0000Left-Click to Create|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.genderrandom =
"Creates a bot with a random gender.\n|cffffffff"..
"The winds of fate shall decide!|r\n\n"..
"|cffff0000Left-Click to Create|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.creator.inspect =
"Inspect-Target\n|cffffffff"..
"This Button will open the Inspect-Window of your Target.|r\n\n"..
"|cffff0000Left-Click to open Inspect-Window|r\n"..
"|cff999999(Execution-Order: Target)|r";

MultiBot.tips.creator.init =
"Auto-Initialize\n|cffffffff"..
"Use this Button to Auto-Initialize your Target, Raid or Party.\n"..
"There are 2 Limitations, because the Equipment will be overwritten:\n"..
"- it wont work with anyone on the Playerbot-Roster.\n"..
"- it wont work with anyone on the Guild-Roster.|r\n\n"..
"|cffff0000Left-Click to Auto-Initialize your Target|r\n"..
"|cff999999(Execution-Order: Target)|r\n\n"..
"|cffff0000Right-Click to Auto-Initialize your Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- INIT --
MultiBot.tips.unit = {}
MultiBot.tips.unit.selfbot =
"Selfbot\n"..
"|cffffffffThis Button switches the Selfbot-Mode on and off.|r\n\n"..
"|cffff0000Left-Click to execute Selfbot|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.unit.button =
"|cffffffff\n"..
"This Button adds or removes NAME to or from your Group.\n"..
"MultiBot will ask Playerbot about the Combat- and Non-Combat-Strategies.\n"..
"The Strategies can be configured with the Buttonbars on the left and right side.\n"..
"The Buttonbars will appear after adding the Bot.|r\n\n"..
"|cffff0000Left-Click to add NAME|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to remove NAME|r\n"..
"|cff999999(Execution-Order: System)|r";

-- UNITS --

MultiBot.tips.units = {}
MultiBot.tips.units.master =
"Unit-Control\n|cffffffff"..
"In this Control you will find the Playerbots.\n"..
"Each Button stands for one of your Characters, Guild-Members or Friends.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to show or hide the Units|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to refresh the Roster|r\n"..
"|cff999999(Execution-Order: System)|r";

-- UNITS:FILTER --

MultiBot.tips.units.filter =
"Class-Filter\n|cffffffff"..
"With the Class-Filter you can filter the Units by Classes.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to reset the Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.deathknight =
"Class-Filter\n|cffffffff"..
"Filters the Units for Death Knights.|r\n\n"..
"|cffff0000Left-Click to filter for Death Knights|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.druid =
"Class-Filter\n|cffffffff"..
"Filters the Units for Druids.|r\n\n"..
"|cffff0000Left-Click to filter for Druids|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.hunter =
"Class-Filter\n|cffffffff"..
"Filters the Units for Hunters.|r\n\n"..
"|cffff0000Left-Click to filter for Hunters|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.mage =
"Class-Filter\n|cffffffff"..
"Filters the Units for Mages.|r\n\n"..
"|cffff0000Left-Click to filter for Mages|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.paladin =
"Class-Filter\n|cffffffff"..
"Filters the Units for Paladins.|r\n\n"..
"|cffff0000Left-Click to filter for Paladins|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.priest =
"Class-Filter\n|cffffffff"..
"Filters the Units for Priests.|r\n\n"..
"|cffff0000Left-Click to filter for Priests|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.rogue =
"Class-Filter\n|cffffffff"..
"Filters the Units for Rogues.|r\n\n"..
"|cffff0000Left-Click to filter for Rogues|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.shaman =
"Class-Filter\n|cffffffff"..
"Filters the Units for Shamans.|r\n\n"..
"|cffff0000Left-Click to filter for Shamans|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.warlock =
"Class-Filter\n|cffffffff"..
"Filters the Units for Warlocks.|r\n\n"..
"|cffff0000Left-Click to filter for Warlocks|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.warrior =
"Class-Filter\n|cffffffff"..
"Filters the Units for Warriors.|r\n\n"..
"|cffff0000Left-Click to filter for Warriors|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.none =
"Class-Filter\n|cffffffff"..
"Removes the Class-Filter from the Units.|r\n\n"..
"|cffff0000Left-Click to remove the Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

-- UNITS:ROSTER --

MultiBot.tips.units.roster =
"Roster-Filter\n|cffffffff"..
"With the Roster-Filter you can switch between differned Rosters.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cffff0000Right-Click to switch to Active Roster|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.actives =
"Roster-Filter\n|cffffffff"..
"Shows the Active-Roster.|r\n\n"..
"|cffff0000Left-Click to select Active-Roster|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.players =
"Roster-Filter\n|cffffffff"..
"Shows the Playerbot-Roster.\n"..
"Normaly your Characters and Others which stayed in your Group.|r\n\n"..
"|cffff0000Left-Click to select Playerbot-Roster|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.members =
"Roster-Filter\n|cffffffff"..
"Shows the Guild-Roster.\n"..
"The Guild-Roster does not show your Characters.|r\n\n"..
"|cffff0000Left-Click to select Guild-Roster|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.friends =
"Roster-Filter\n|cffffffff"..
"Shows the Friend-Roster.\n"..
"The Friend-Roster does not show your Characters or Guild-Members.|r\n\n"..
"|cffff0000Left-Click to select Friend-Roster|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.favorites =
"Roster Filter\n|cffffffff"..
"Show only the Bots you marked as Favorites.|r\n\n"..
"|cffff0000Left-click to activate|r\n"..
"|cff999999(Executed by: System)|r";

-- UNITS PVP Stats
MultiBot.tips.units.pvpstatsmaster =
"PvP Stats\n|cffffffff"..
"Send PvP Stats command to...|r\n\n"..
"|cffff0000Left-click to open menu|r\n"..
"|cff999999(Executed by: System)|r";

MultiBot.tips.units.pvpstatstobot =
"Send To Bot";

MultiBot.tips.units.pvpstatstoparty =
"Send To Party";

MultiBot.tips.units.pvpstatstoraid =
"Send To Raid";

-- UNITS:BROWSE --

MultiBot.tips.units.browse =
"Browse\n|cffffffff"..
"With this Button you can browse through the Rosters.\n"..
"It will be hidden if the Roster has less then 11 Units.|r\n\n"..
"|cffff0000Left-Click to browse the Roster|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.invite =
"Invite-Control\n|cffffffff"..
"With this Control you can automaticaly fill up your Group.\n"..
"The left Button is for 'Party-Invite', the right Buttons are for 'Raid-Invite'.\n"..
"Additionally a Right-Click on this Button will add or remove all Bots at once.\n"..
"Means, if you are not in a Group all Bots will be added else they are removed.|r\n\n"..
"|cffff0000Left-Click to show or hide the Control|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to add or remove all Bots|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.inviteParty5 =
"Party of Five\n|cffffffff"..
"With this Button you can fill up your Party.\n"..
"This Feature takes the Units form the selected Roster ignoring the Class-Filter.\n"..
"It stops at the End of the Roster or until the Group reached 5 Members.|r\n\n"..
"|cffff0000Left-Click to invite Party-Members|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.inviteRaid10 =
"Raid of Ten\n|cffffffff"..
"With this Button you can fill up your Raid.\n"..
"This Feature takes the Units form the selected Roster ignoring the Class-Filter.\n"..
"It stops at the End of the Roster or until the Group reached 10 Members.|r\n\n"..
"|cffff0000Left-Click to invite Raid-Members|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.inviteRaid25 =
"Raid of Twenty-Five\n|cffffffff"..
"With this Button you can fill up your Raid.\n"..
"This Feature takes the Units form the selected Roster ignoring the Class-Filter.\n"..
"It stops at the End of the Roster or until the Group reached 25 Members.|r\n\n"..
"|cffff0000Left-Click to invite Raid-Members|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.units.inviteRaid40 =
"Raid of Forty\n|cffffffff"..
"With this Button you can fill up your Raid.\n"..
"This Feature takes the Units form the selected Roster ignoring the Class-Filter.\n"..
"It stops at the End of the Roster or until the Group reached 40 Members.|r\n\n"..
"|cffff0000Left-Click to invite Raid-Members|r\n"..
"|cff999999(Execution-Order: System)|r";

-- UNITS:ALL --

MultiBot.tips.units.alliance =
"Alliance\n|cffffffff"..
"With this Button you can bring all you Group-Members online or offline.\n"..
"Maybe MultiBot wont be able to react fast enough and will not show all Botbars.\n\n"..
"|cffff0000Left-Click to bring all Group-Members online|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to bring all Group-Members offline|r\n"..
"|cff999999(Execution-Order: System)|r";

-- SLIDERS INTERFACE --
MultiBot.tips.sliders = {}

MultiBot.tips.sliders.throttleinstalled =
"MultiBot throttle installed";

MultiBot.tips.sliders.frametitle =
"MultiBot — Options";

MultiBot.tips.sliders.actionsinter =
"Automatic action intervals";

MultiBot.tips.sliders.statsinter =
"Stats ping interval";

MultiBot.tips.sliders.talentsinter =
"Auto talents interval";

MultiBot.tips.sliders.invitsinter =
"Invitation loop interval";

MultiBot.tips.sliders.sortinter =
"Sorting/refresh interval";

MultiBot.tips.sliders.messpersec =
"Messages per second";

MultiBot.tips.sliders.maxburst =
"Maximum burst";

MultiBot.tips.sliders.rstbutn =
"Reset";

-- MAIN --
MultiBot.tips.main = {}
MultiBot.tips.main.lang = {}

MultiBot.tips.main.master =
"Main-Control\n|cffffffff"..
"In this Control you will find the Auto-Switches and Reset-Commands.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to drag and move MultiBot|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.options =
"Options-Switch\n|cffffffff"..
"Opens the MultiBot settings panel with sliders for action intervals.\n"..
"(Stats / Talents / Invite / Sort) and chat throttling (Messages per second / Burst).\n"..
"Settings are saved per character.|r\n\n"..
"|cffff0000Left-Click to open or close the options panel|r\n"..
"|cff999999(Execution-Order: Interface)|r";

MultiBot.tips.main.coords =
"Reset-Coords\n|cffffffff"..
"Reset the Coordinates of the Features:\n"..
"MultiBar, Inventory, Spellbook, Itemus, Iconos and Reward-Selector|r\n\n"..
"|cffff0000Left-Click to reset Coordinates|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.masters =
"GameMaster-Switch\n|cffffffff"..
"This Switch will enable or disable the GameMaster-Control.\n"..
"You will need GameMaster-Rights to enable the GameMaster-Control|r\n\n"..
"|cffff0000Left-Click to enable or disable the GameMaster-Control|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.rtsc =
"RTSC-Switch\n|cffffffff"..
"This Switch will enable or disable the RTSC-Control.|r\n\n"..
"|cffff0000Left-Click to enable or disable the RTSC-Control|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.raidus =
"Raidus-Switch\n|cffffffff"..
"This Switch will open or close the Raid-Composer.|r\n\n"..
"|cffff0000Left-Click to open or close the Raid-Composer|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.creator =
"Creator-Switch\n|cffffffff"..
"This Switch will enable or disable the Creator-Control.|r\n\n"..
"|cffff0000Left-Click to enable or disable the Creator-Control|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.beast =
"Beastmaster-Switch\n|cffffffff"..
"This Switch will enable or disable the Beastmaster-Control.\n"..
"The Beastmaster-Control is for the Mod-NPC-Beastmaster of the Azerothcore.\n"..
"Mod-NPC-Beastmaster allows every Character to have a Pet like Hunters.\n"..
"Your Charaters can learn the nessasary Spells from White Fang.\n"..
"White Fang must be placed into the World by the GameMaster.|r\n\n"..
"|cffff0000Left-Click to enable or disable the Beastmaster-Control|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.expand =
"Expand-Switch\n|cffffffff"..
"This Switch will expand or reduce the Stay-Follow-Control.\n"..
"|cffff0000Left-Click to expand or reduce the Stay-Follow-Control|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.release =
"Auto-Release\n|cffffffff"..
"This Feature detects the Death of Bots.\n"..
"Dead Bots are automatically released and summoned.\n"..
"This will revive the bots within seconds.|r\n\n"..
"|cffff0000Left-Click to enable or disable Auto-Release|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.stats =
"Auto-Stats\n|cffffffff"..
"This Feature visualizes the Values of Stats-Command.\n"..
"The Stats-Values are updated every 45 Seconds.|r\n\n"..
"|cffff0000Left-Click to enable or disable Auto-Stats|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.reward =
"Reward-Selector\n|cffffffff"..
"This Feature visualizes the Selection of Rewards.\n"..
"My Advice is to select the Reward for your Character first.\n"..
"Then you wont have any Problems using the Inspect-Buttons.|r\n\n"..
"Important:\n"..
"Once your Character has completed the Quest, the Bots must also complete the Quest.\n"..
"So dont cancel the Reward-Selector after your Character has his Reward.\n\n"..
"|cffffffffMod-Playerbot-Configuration:\n"..
"- (must) AiPlayerbot.AutoPickReward = no\n"..
"- (recommanded) AiPlayerbot.SyncQuestWithPlayer = 1|r\n\n"..
"|cffff0000Left-Click to enable or disable Reward-Selector|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to open Reward-Selector|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.main.reset =
"Reset-Bots\n|cffffffff"..
"This Button will reset the Artificial-Intelligence of your Bots.|r\n\n"..
"|cffff0000Left-Click to reset the Artificial-Intelligence|r\n"..
"|cff999999(Execution-Order: Target, Raid, Party)|r";

MultiBot.tips.main.action =
"Reset-Action\n|cffffffff"..
"This Button will reset the current Action of your Bots.|r\n\n"..
"|cffff0000Left-Click to reset the Action|r\n"..
"|cff999999(Execution-Order: Target, Raid, Party)|r";

-- GAMEMASTER --

MultiBot.tips.game = {}
MultiBot.tips.game.master =
"GameMaster-Control\n|cffffffff"..
"In this Control you will find useful GameMaster-Commands.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to close MultiBot|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.game.necronet =
"Necro-Network\n|cffffffff"..
"This Button enables or disables the Necro-Network.\n"..
"If Necro-Network is active you will find Graveyard-Buttons on the World-Map.\n"..
"With each Graveyard-Button you could Teleport yourself to the corresponding Graveyard.\n"..
"You need GameMaster-Rights zo use these Buttons.|r\n\n"..
"|cffff0000Left-Click to enable or disable the Necro-Network|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.game.portal =
"Memory-Portal\n|cffffffff"..
"In this Box you will find the Memory-Gems.\n"..
"Use the Memory-Gems to store your current Location.\n"..
"You can teleport yourself to stored Locations by using the Memory-Gems.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to show or hide the Soulgems|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.game.memory =
"Memory-Gem\n|cffffffff"..
"This Memory-Gem ABOUT.\n"..
"You need GameMaster-Rights to use this Button.|r\n\n"..
"|cffff0000Left-Click to store or teleport to the Location|r\n"..
"|cff999999(Execution-Order: Yourself)|r\n\n"..
"|cffff0000Right-Click to forget the Location|r\n"..
"|cff999999(Execution-Order: Yourself)|r";

MultiBot.tips.game.itemus =
"Itemus\n|cffffffff"..
"You will find every Item in the Box of the GamerMaster.\n"..
"Just target the Player or Bot, left click the Item and the wish come true.\n"..
"Important, not every Item can be generated, so you must try to find out.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to open or close the Itemus|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.game.iconos =
"Iconos\n|cffffffff"..
"You will find every Icon and his Path in this Tool.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to open or close the Iconos|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.game.summon =
"Summon\n|cffffffff"..
"Summons a targeted Player or Bot to your Position.\n"..
"You need GameMaster-Rights to use this Button.|r\n\n"..
"|cffff0000Left-Click to summon your Target|r\n"..
"|cff999999(Execution-Order: Target)|r";

MultiBot.tips.game.appear =
"Appear\n|cffffffff"..
"You will appear at the Position of the targeted Player or Bot.\n"..
"You need GameMaster-Rights to use this Button.|r\n\n"..
"|cffff0000Left-Click to appear at your Target|r\n"..
"|cff999999(Execution-Order: Target)|r";

MultiBot.tips.game.delsvwarning =
"|cffff4444WARNING|r : you are about to delete ALL MultiBot saved variables.\n"..
"This action is irreversible.\n\nDo you want to continue?";

MultiBot.tips.game.delsv =
"Delete Saved Variables\n|cffffffff"..
"This button will permanently erase all data from the MultiBot SavedVariables file (MultiBot.lua).\n"..
"This action cannot be undone. Use with caution!|r\n\n"..
"|cffff0000Left-Click to Delete|r\n"..
"|cff999999(Executed at System Level)|r";

-- QUESTS --

MultiBot.tips.quests = {}
MultiBot.tips.quests.master =
"Quest-Control\n|cffffffff"..
"This Control shows the current List of Quests.\n"..
"Left-Click the Pages to share the Quest with your bots.\n"..
"Right-Click the Pages to abandon your and your Bots Quest.\n"..
"The Execution-Order shows the Receiver for Commands.|r\n\n"..
"|cffff0000Left-Click to show or hide the Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to refresh the Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.quests.accept =
"Quest-Accpet\n|cffffffff"..
"This Button orders Bots to take every Quest of the targeted NPC.\n\n"..
"|cffff0000Left-Click to take every Quest|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.quests.main =
"Open Quests Menu\n|cffffffff"..
"This Button open the quests menu.\n\n"..
"|cffff0000Left-Click to open|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.quests.talk =
"Talk to NPC\n|cffffffff"..
"This button tells the bots to talk to the selected NPC in order to take or return a quest.\n\n"..
"|cffff0000Left-Click to order|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.quests.talkerror =
"Please select an NPC to talk to.";

MultiBot.tips.quests.questcomperror =
"Please target a bot to ask its quests.";

MultiBot.tips.quests.sendwhisp =
"Ask to the bot";

MultiBot.tips.quests.sendpartyraid =
"Ask to Group or Raid.";

MultiBot.tips.quests.completed =
"Completed Quests\n|cffffffff"..
"This button allows you to ask a bot or all bots for the list of completed quests.\n\n"..
"|cffff0000Left-Click to open submenu|r\n"..
"|cff999999(Execution-Order: Raid, Party, bot)|r";

MultiBot.tips.quests.incompleted =
"Incomplete Quests\n|cffffffff"..
"This button allows you to ask a bot or all bots for the list of incomplete quests.\n\n"..
"|cffff0000Left-Click to open submenu|r\n"..
"|cff999999(Execution-Order: Raid, Party, bot)|r";

MultiBot.tips.quests.allcompleted =
"All Quests\n|cffffffff"..
"This button allows you to ask a bot or all bots for the list of All Quests.\n\n"..
"|cffff0000Left-Click to open submenu|r\n"..
"|cff999999(Execution-Order: Raid, Party, bot)|r";

MultiBot.tips.quests.incomplist =
"Current quests from the bot(s)";

MultiBot.tips.quests.complist =
"List of completed quests of the bot(s)";

MultiBot.tips.quests.alllist =
"All quests of the bot(s)";

MultiBot.tips.quests.compheader =
"** Complete Quests **";

MultiBot.tips.quests.incompheader =
"** Incomplete Quests **";

MultiBot.tips.quests.botsword =
"Bots : ";

-- USE GOBs --
MultiBot.tips.quests.gobsmaster =
"Use GoBs Menu\n|cffffffff"..
"This button open the use Game Objects Menu.|r\n\n"..
"|cffff0000Left-Click to Open|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.quests.gobenter =
"Use Game Object\n|cffffffff"..
"This button opent a prompt to enter Game Object Name.\n\n"..
"|cffff0000Left-Click to open prompt|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.quests.gobsearch =
"Search for Game Object\n|cffffffff"..
"This button opent a frame that shows Game Object that bots can use.\n\n"..
"|cffff0000Left-Click to open frame|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.quests.goberrorname =
"Please enter a valid Game Object Name.";

MultiBot.tips.quests.gobselectboterror =
"Please select the bot to send the command to.";

MultiBot.tips.quests.gobsnameerror =
"Please enter a name.";

MultiBot.tips.quests.gobctrlctocopy =
"CTRL + C To Copy";

MultiBot.tips.quests.gobselectall =
"Select All";

MultiBot.tips.quests.gobsfound =
"Game Objects Found";

MultiBot.tips.quests.gobpromptname =
"Game Object Name";

-- DRINK --

MultiBot.tips.drink = {}
MultiBot.tips.drink.group =
"Group-Drink\n|cffffffff"..
"With this Button you order the Group to drink.\n"..
"The Execution-Order shows the Receiver for Commands.|r\n\n"..
"|cffff0000Left-Click to execute Group-Drink|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- RELEASE --

MultiBot.tips.release = {}
MultiBot.tips.release.group =
"Group-Release\n|cffffffff"..
"With this Button the dead Bots will release there Ghosts to the next Graveyard.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Group-Release|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- REVIVE --

MultiBot.tips.revive = {}
MultiBot.tips.revive.group =
"Group-Revive\n|cffffffff"..
"With this Button the Ghost-Bots will revive on the next Graveyard.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Group-Revive|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- SUMALL --

MultiBot.tips.summon = {}
MultiBot.tips.summon.group =
"Group-Summon\n|cffffffff"..
"With this Button you summon the Group to your Position.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to execute Group-Summon|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- ALL BOTS COMMANDS --

MultiBot.tips.allbots = {}
	MultiBot.tips.allbots.sellallvendor = "Sell all vendorable Grey items (ALL BOTS)|cffffffff\n"
		.. "All your bots (those listed in the Units panel) will sell all items\n"
		.. "that can safely be sold to your current vendor target.\n"
		.. "Protected items (keys, Hearthstone, etc.) are never sold.|r\n\n"
		.. "|cffff0000Affects every bot listed in the Units panel.|r\n"
		.. "|cff999999(Executed by: each Bot)|r"

    MultiBot.tips.allbots.commandsallbots = "Allows you to send commands to all Bots|cffffffff\n"
            .. "All your bots (those listed in the Units panel) will execute the command\n\n"
            .. "|cffff0000Affects every bot listed in the Units panel.|r\n"
            .. "|cff999999(Executed by: each Bot)|r"

	MultiBot.tips.allbots.maintenanceallbots = "Maintenance (ALL BOTS)|cffffffff\n"
		.. "All your bots (those listed in the Units panel) will run the 'maintenance' command.\n"
		.. "Use this when you want every bot to perform its full maintenance routine at once.|r\n\n"
		.. "|cffff0000Affects every bot listed in the Units panel.|r\n"
		.. "|cff999999(Executed by: each Bot)|r"

-- INVENTORY --

MultiBot.tips.inventory = {}
MultiBot.tips.inventory.sell =
"Sell-Items|cffffffff\n"..
"It enables the Sell-Mode of the Inventory.\n"..
"You must have a Merchent as Target.\n"..
"For security Resons your Bot will not sell:\n"..
"- every Item with 'Key' in its Name\n"..
"- the Hearthstone|r\n\n"..
"|cffff0000Left-Click to sell a Item|r\n"..
"|cff999999(Execution-Order: Bot)|r";

	MultiBot.tips.inventory.sellgrey = "Sell * (grey items)|cffffffff\n"
		.. "The Bot sells all poor-quality (grey) items to the selected vendor.\n"
		.. "Make sure you have the vendor selected and that the Bot is in range.|r\n\n"
		.. "|cffff0000Only affects the Bot whose inventory is open.|r\n"
		.. "|cff999999(Executed by: Bot)|r"

	MultiBot.tips.inventory.sellvendor = "Sell vendorable items|cffffffff\n"
		.. "The Bot sells all items that can safely be sold to the selected vendor.\n"
		.. "Protected items (keys, Hearthstone, etc.) are never sold.|r\n\n"
		.. "|cffff0000Only affects the Bot whose inventory is open.|r\n"
		.. "|cff999999(Executed by: Bot)|r"

MultiBot.tips.inventory.equip =
"Equip-Items|cffffffff\n"..
"It enables the Equip-Mode of the Inventory.|r\n\n"..
"|cffff0000Left-Click to equip a Item|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.inventory.use =
"Use-Items|cffffffff\n"..
"It enables the Use-Mode of the Inventory.|r\n\n"..
"|cffff0000Left-Click to use a Item|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.inventory.trade =
"Trade-Items|cffffffff\n"..
"It enables the Trade-Mode of the Inventory.\n"..
"The Inspect-Frame must be closed manually.\n"..
"There is no LUA-Command for this.|r\n\n"..
"|cffff0000Left-Click to trade a Item|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.inventory.drop =
"Drop-Items|cffffffff\n"..
"It enables the Drop-Mode of the Inventory.\n"..
"For security Resons your Bot will not drop:\n"..
"- every Item with a Quality of Epic or higher\n"..
"- every Item with 'Key' in its Name\n"..
"- the Hearthstone|r\n\n"..
"|cffff0000Left-Click to drop a Item|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.inventory.open =
"Open-Items|cffffffff\n"..
"This Button will open every first findable Loot-Bag in your Inventory.\n"..
"The Content will be put automatically into the Inventory.|r\n\n"..
"|cffff0000Left-Click to open a Loot-Bag|r\n"..
"|cff999999(Execution-Order: Bot)|r";

-- ITEMUS:LEVEL --

MultiBot.tips.itemus = {}
MultiBot.tips.itemus.level = {}
MultiBot.tips.itemus.level.master =
"Level-Filter|cffffffff\n"..
"Filters the Items by Level in a range of 10.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L10 =
"Level 0 to 10|cffffffff\n"..
"Shows the Items with a required Level between 0 and 10.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L20 =
"Level 11 to 20|cffffffff\n"..
"Shows the Items with a required Level between 11 and 20.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L30 =
"Level 21 to 30|cffffffff\n"..
"Shows the Items with a required Level between 21 and 30.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L40 =
"Level 31 to 40|cffffffff\n"..
"Shows the Items with a required Level between 31 and 40.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L50 =
"Level 41 to 50|cffffffff\n"..
"Shows the Items with a required Level between 41 and 50.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L60 =
"Level 51 to 60|cffffffff\n"..
"Shows the Items with a required Level between 51 and 60.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L70 =
"Level 61 to 70|cffffffff\n"..
"Shows the Items with a required Level between 61 and 70.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.level.L80 =
"Level 71 to 80|cffffffff\n"..
"Shows the Items with a required Level between 71 and 80.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

-- ITEMUS:RARE --

MultiBot.tips.itemus.rare = {}
MultiBot.tips.itemus.rare.master =
"Quality-Filter|cffffffff\n"..
"Filters the Items by Quality.\n"..
"This Filter is additive to the Level-Filter.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R00 =
"Poor-Quality|cffffffff\n"..
"Shows the Items with a Poor-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R01 =
"Common-Quality|cffffffff\n"..
"Shows the Items with a Common-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R02 =
"Non-Common-Quality|cffffffff\n"..
"Shows the Items with a Non-Common-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R03 =
"Rare-Quality|cffffffff\n"..
"Shows the Items with a Rare-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R04 =
"Epic-Quality|cffffffff\n"..
"Shows the Items with a Epic-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R05 =
"Legendary-Quality|cffffffff\n"..
"Shows the Items with a Legendary-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R06 =
"Artifact-Quality|cffffffff\n"..
"Shows the Items with a Artifact-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.rare.R07 =
"Heirlooms-Quality|cffffffff\n"..
"Shows the Items with a Heirlooms-Quality.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

-- ITEMUS:SLOT --

MultiBot.tips.itemus.slot = {}
MultiBot.tips.itemus.slot.master =
"Slot-Filter|cffffffff\n"..
"Filters the Items by Slot.\n"..
"This Filter is additive to the Level- and Quality-Filter.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S00 =
"Non-Equipable|cffffffff\n"..
"Shows the Items which are not equipable.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S01 =
"Head-Slot|cffffffff\n"..
"Shows the Items for the Head-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S02 =
"Neck-Slot|cffffffff\n"..
"Shows the Items for the Neck-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S03 =
"Shoulder-Slot|cffffffff\n"..
"Shows the Items for the Shoulder-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S04 =
"Shirt-Slot|cffffffff\n"..
"Shows the Items for the Shirt-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S05 =
"Chest-Slot|cffffffff\n"..
"Shows the Items for the Chest-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S06 =
"Waist-Slot|cffffffff\n"..
"Shows the Items for the Waist-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S07 =
"Legs-Slot|cffffffff\n"..
"Shows the Items for the Legs-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S08 =
"Feets-Slot|cffffffff\n"..
"Shows the Items for the Feets-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S09 =
"Wrists-Slot|cffffffff\n"..
"Shows the Items for the Wrists-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S10 =
"Hands-Slot|cffffffff\n"..
"Shows the Items for the Hands-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S11 =
"Finger-Slot|cffffffff\n"..
"Shows the Items for the Finger-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S12 =
"Trinket-Slot|cffffffff\n"..
"Shows the Items for the Trinket-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S13 =
"One-Hand-Weapon-Slot|cffffffff\n"..
"Shows the Items for the One-Hand-Weapon-Slot.\n"..
"Notice that this Item could be used as Main- and Off-Hand-Weapons.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S14 =
"Shield-Slot|cffffffff\n"..
"Shows the Items for the Shield-Slot.\n"..
"Notice that this Slot is the same as Off-Hand-Weapons.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S15 =
"Ranged-Slot|cffffffff\n"..
"Shows the Items for the Ranged-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S16 =
"Back-Slot|cffffffff\n"..
"Shows the Items for the Back-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S17 =
"Two-Hand-Weapon-Slot|cffffffff\n"..
"Shows the Items for the Two-Hand-Weapon-Slot.\n"..
"Notice that this Slot is the same as Main-Hand-Weapons.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S18 =
"Bag-Slot|cffffffff\n"..
"Shows the Items for the Bag-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S19 =
"Tabard-Slot|cffffffff\n"..
"Shows the Items for the Tabard-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S20 =
"Robe-Slot|cffffffff\n"..
"Shows the Items for the Robe-Slot.\n"..
"Notice that this Slot is the same as for Chests.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S21 =
"Main-Hand-Weapons-Slot|cffffffff\n"..
"Shows the Items for the Main-Hand-Weapons-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S22 =
"Off-Hand-Weapons-Slot|cffffffff\n"..
"Shows the Items for the Off-Hand-Weapons-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S23 =
"Off-Hand-Items-Slot|cffffffff\n"..
"Shows the Items for the Off-Hand-Items-Slot.\n"..
"Notice that this Slot is the same as Off-Hand-Weapons.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S24 =
"Ammo-Slot|cffffffff\n"..
"Shows the Items for the Ammo-Slot.\n"..
"Notice that this Slot is the same as Ranged-Right.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S25 =
"Throw-Slot|cffffffff\n"..
"Shows the Items for the Throw-Slot.\n"..
"Notice that this Slot is the same as Ranged.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S26 =
"Ranged-Right-Slot|cffffffff\n"..
"Shows the Items for the Ranged-Right-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S27 =
"Quiver-Slot|cffffffff\n"..
"Shows the Items for the Quiver-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.itemus.slot.S28 =
"Relic-Slot|cffffffff\n"..
"Shows the Items for the Relic-Slot.|r\n\n"..
"|cffff0000Left-Click to set Filter|r\n"..
"|cff999999(Execution-Order: System)|r";

-- ITEMUS:TYPE --

MultiBot.tips.itemus.type =
"Type-Filter|cffffffff\n"..
"With this Filter you can switch between Player-Character and Non-Player-Character Items.\n"..
"This Filter is additive to the Level-, Quality- and Slot-Filter.|r\n\n"..
"|cffff0000Left-Click to enable or disable NPC-Stuff|r\n"..
"|cff999999(Execution-Order: System)|r";

-- DEATHKNIGHT --

MultiBot.tips.deathknight = {}
MultiBot.tips.deathknight.dps = {}
MultiBot.tips.deathknight.presence = {}

MultiBot.tips.deathknight.presence.master =
"Presence-Control|cffffffff\n"..
"This Control allows you to select, enable or disable the default Precence.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Presence.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.presence.unholy =
"Unholy-Presence|cffffffff\n"..
"It enables the Unholy-Presence.|r\n\n"..
"|cffff0000Left-Click to enable Unholy-Presence|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.presence.frost =
"Frost-Presence|cffffffff\n"..
"It enables the Frost-Presence.|r\n\n"..
"|cffff0000Left-Click to enable Frost-Presence|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.presence.blood =
"Blood-Presence|cffffffff\n"..
"It enables the Blood-Presence.|r\n\n"..
"|cffff0000Left-Click to enable Blood-Presence|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.dps.frostAoe =
"FROST-AOE|cffffffff\n"..
"Enables the Frost AOE strategy.\n"..
"Frost-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these strategies can be active.|r\n\n"..
"|cffff0000Left-Click to enable or disable Frost-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.dps.unholyAoe =
"UNHOLY-AOE|cffffffff\n"..
"Enables the Unholy AOE strategy.\n"..
"Unholy-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these strategies can be active.|r\n\n"..
"|cffff0000Left-Click to enable or disable Unholy-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.deathknight.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- DRUID --

MultiBot.tips.druid = {}
MultiBot.tips.druid.dps = {}
MultiBot.tips.druid.playbook = {}

MultiBot.tips.druid.heal =
"Heal|cffffffff\n"..
"It makes the Druid to the Healer of the Group.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Heal|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.buff =
"Buff|cffffffff\n"..
"It allows the Druid to Buff the Group.|r\n\n"..
"|cffff0000Left-Click to enable or disable Buff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.playbook.master =
"Playbook|cffffffff\n"..
"In the Playbook you will find the Strategies typical for the Class.|r\n\n"..
"|cffff0000Left-Click to show or hide Playbook|r\n"..
"|cf9999999(Execution-Order: System)|r";

MultiBot.tips.druid.playbook.casterDebuff =
"Caster-Debuff|cffffffff\n"..
"Allows the Caster to use Debuff-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Caster-Debuff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.playbook.casterAoe =
"Caster-AOE|cffffffff\n"..
"Allows the Caster to use AOE-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Caster-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.playbook.caster =
"Caster|cffffffff\n"..
"The Caster corresponds to a Ranged-Fighter.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Caster|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.playbook.catAoe =
"Cat-AOE|cffffffff\n"..
"Allows the Cat to use AOE-Attacks during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Cat-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.playbook.cat =
"Cat|cffffffff\n"..
"The Cat corresponds to a Melee-Fighter.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Cat|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.playbook.bear =
"Bear|cffffffff\n"..
"The Bear corresponds to a Tank.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Bear|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.playbook.melee =
"Melee|cffffffff\n"..
"Enable the Melee strategy.\n"..
"Stay in melee range and prefer physical attacks.\n"..
"Mutually exclusive with Caster and Heal.|r\n\n"..
"|cffff0000Left-Click to enable or disable Melee|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.dps.healerdps =
"Healer DPS|cffffffff\n"..
"Enable the hybrid Healer-DPS strategy.\n"..
"Deal damage by default and heal when needed.\n"..
"Mutually exclusive with Heal and OffHeal.|r\n\n"..
"|cffff0000Left-Click to enable or disable Healer-DPS|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.dps.dpsDebuff =
"DPS-Debuff|cffffffff\n"..
"It enables the Debuff-Strategies.\n"..
"The Druid can only Debuff as Caster.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Debuff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"The Druid can only AOE as Cat or Caster.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.dps.dps =
"DPS|cffffffff\n"..
"It enables the DPS-Strategies.\n"..
"The Druid can only use DPS-Strategies as Cat.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.dps.offheal =
"OffHeal|cffffffff\n"..
"This disable dps mode and enable offheal, \n"..
"The bots will now focus damage but heal when necessary.\n"..
"Only for feral duid.|r\n\n"..
"|cffff0000Left-Click to enable or disable OffHeal|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.druid.tank =
"Tank|cffffffff\n"..
"It enables the Tank-Strategies.\n"..
"The Druid can only Tank as Bear.\n"..
"Bear, Cat, Caster and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- HUNTER --

MultiBot.tips.hunter = {}
MultiBot.tips.hunter.dps = {}
MultiBot.tips.hunter.naspect = {}
MultiBot.tips.hunter.caspect = {}
MultiBot.tips.hunter.pet = {}

MultiBot.tips.hunter.pet.master =
"Pet Commands|cffffffff\n"..
"Opens a bar with multiple pet summoning options.|r\n\n"..
"|cffff0000Left-Click to show options|r\n"..
"|cff999999(Execution Order: System)|r";

MultiBot.tips.hunter.pet.name =
"Summon a pet by |cff00ff00its name|r\n"..
"|cffffffffOpen a list of available pets and click a name to summon.|r\n\n"..
"|cffff0000Left-Click to open the list|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.hunter.pet.id =
"Summon a pet by |cff00ff00DB ID|r\n"..
"|cffffffffUse a creature's database ID to summon it directly.|r\n\n"..
"|cffff0000Left-Click to enter an ID|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.hunter.pet.family =
"Summon random pet by |cff00ff00FAMILY|r\n"..
"|cffffffffChoose a pet family to summon a random pet from that type.|r\n\n"..
"|cffff0000Left-Click to select a family|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.hunter.pet.rename =
"Rename your current pet\n"..
"|cffffffffOpens a prompt to set a new name for your active pet.|r\n\n"..
"|cffff0000Left-Click to rename|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.hunter.pet.abandon =
"Dismiss current pet\n"..
"|cffffffffWith this command you can dismiss your pet.|r\n\n"..
"|cffff0000Left-Click to dismiss|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.hunter.ownbutton =
"Hunter: %s\n"..
"|cffffffffThis button open Hunter pet's Menu.|r\n\n"..
"|cffff0000Left-Click to open/close|r\n"..
"|cffff0000Right-Click to drag|r\n"..
"|cff999999(Execution Order: System)|r";

MultiBot.tips.hunter.pet.stances =
"Pets Stances\n"..
"|cffffffffOpen pets stances menu.|r\n\n"..
"|cffff0000Left-Click to open/close|r\n"..
"|cff999999(Execution Order: System)|r";

MultiBot.tips.hunter.pet.aggressive =
"Aggresive";

MultiBot.tips.hunter.pet.passive =
"Passive";

MultiBot.tips.hunter.pet.defensive =
"Defensive";

MultiBot.tips.hunter.pet.curstance =
"Current pet stance ?";

MultiBot.tips.hunter.pet.attack =
"Attack";

MultiBot.tips.hunter.pet.follow =
"Follow";

MultiBot.tips.hunter.pet.stay =
"Stay";

MultiBot.tips.hunter.naspect.master =
"Non-Combat-Buff|cffffffff\n"..
"This Control allows you to select, enable or disable the default Non-Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Buff.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.naspect.rnature =
"Resist-Nature-Buff|cffffffff\n"..
"It enables the Resist-Nature-Buff as Non-Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Resist-Nature-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.naspect.bspeed =
"Speed-Buff|cffffffff\n"..
"It enables the Speed-Buff as Non-Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Speed-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.naspect.bmana =
"Mana-Buff|cffffffff\n"..
"It enables the Mana-Buff as Non-Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Mana-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.naspect.bdps =
"DPS-Buff|cffffffff\n"..
"It enables the DPS-Buff as Non-Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable DPS-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.caspect.master =
"Combat-Buff|cffffffff\n"..
"This Control allows you to select, enable or disable the default Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Buff.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.caspect.rnature =
"Resist-Nature-Buff|cffffffff\n"..
"It enables the Resist-Nature-Buff as Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Resist-Nature-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.caspect.bspeed =
"Speed-Buff|cffffffff\n"..
"It enables the Speed-Buff as Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Speed-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.caspect.bmana =
"Mana-Buff|cffffffff\n"..
"It enables the Mana-Buff as Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Mana-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.caspect.bdps =
"DPS-Buff|cffffffff\n"..
"It enables the DPS-Buff as Combat-Buff.|r\n\n"..
"|cffff0000Left-Click to enable DPS-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.dps.dpsDebuff =
"DPS-Debuff|cffffffff\n"..
"It enables the Debuff-Strategies.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Debuff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.dps.dps =
"DPS|cffffffff\n"..
"It enables the DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.trapweave =
"Trap Weave|cffffffff\n"..
"Enables melee trap weaving: the Hunter briefly moves in to place traps when safe.\n"..
"Works with any DPS mode; not mutually exclusive with Assist/Tank-Assist.|r\n\n"..
"|cffff0000Left-Click to enable or disable Trap Weave|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.hunter.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- MAGE --

MultiBot.tips.mage = {}
MultiBot.tips.mage.dps = {}
MultiBot.tips.mage.buff = {}
MultiBot.tips.mage.playbook = {}

MultiBot.tips.mage.buff.master =
"Buff-Control|cffffffff\n"..
"This Control allows you to select, enable or disable the default Buff.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Buff.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.buff.bmana =
"Mana-Buff|cffffffff\n"..
"It enables the Mana-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Mana-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.buff.bdps =
"DPS-Buff|cffffffff\n"..
"It enables the DPS-Buff.|r\n\n"..
"|cffff0000Left-Click to enable DPS-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.master =
"Playbook|cffffffff\n"..
"In the Playbook you will find the Strategies typical for the Class.|r\n\n"..
"|cffff0000Left-Click to show or hide Playbook|r\n"..
"|cf9999999(Execution-Order: System)|r";

MultiBot.tips.mage.playbook.arcaneAoe =
"Arcane-AOE|cffffffff\n"..
"Allows the Mage to use Arcane-AOE-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Arcane-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.arcane =
"Arcane-Magic|cffffffff\n"..
"Allows the Mage to use Arcane-Magic during the Combat.\n"..
"Arcane-, Frost- and Fire-Magic are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Arcane-Magic|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.frostAoe =
"Frost-AOE|cffffffff\n"..
"Allows the Mage to use Frost-AOE-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Arcane-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.frost =
"Frost-Magic|cffffffff\n"..
"Allows the Mage to use Frost-Magic during the Combat.\n"..
"Arcane-, Frost- and Fire-Magic are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Frost-Magic|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.fireAoe =
"Fire-AOE|cffffffff\n"..
"Allows the Mage to use Fire-AOE-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Fire-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.fire =
"Fire-Magic|cffffffff\n"..
"Allows the Mage to use Fire-Magic during the Combat.\n"..
"Arcane-, Frost- and Fire-Magic are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Fire-Magic|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.frostfireAoe =
"Frostfire AOE|cffffffff\n"..
"Enables the Frostfire + AOE combat strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these can be active.|r\n\n"..
"|cffff0000Left-Click to enable or disable Frostfire AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.frostfire =
"Frostfire|cffffffff\n"..
"Enables the Frostfire single-target combat strategy.\n"..
"Arcane, Frost, Fire and Frostfire are mutually exclusive.\n"..
"Only one spec can be active.|r\n\n"..
"|cffff0000Left-Click to enable or disable Frostfire|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.playbook.firestarter =
"Firestarter|cffffffff\n"..
"Enables the \"Firestarter\" tactic for Fire gameplay (opener/instant casts).\n"..
"Can be combined with your current spec and AOE settings.|r\n\n"..
"|cffff0000Left-Click to enable or disable Firestarter|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.mage.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- PALADIN --

MultiBot.tips.paladin = {}
MultiBot.tips.paladin.dps = {}
MultiBot.tips.paladin.seal = {}
MultiBot.tips.paladin.naura = {}
MultiBot.tips.paladin.caura = {}

MultiBot.tips.paladin.heal =
"Heal|cffffffff\n"..
"It allows the Paladin to use Heal-Spells.\n"..
"Tank, DPS and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Heal|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.seal.master =
"Blessing-Control|cffffffff\n"..
"This Control allows you to select, enable or disable the default Blessing.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Blessing.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.seal.bhealth =
"Health-Blessing|cffffffff\n"..
"It enables the Health-Blessing.|r\n\n"..
"|cffff0000Left-Click to enable Health-Blessing|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.seal.bmana =
"Mana-Blessing|cffffffff\n"..
"It enables the Mana-Blessing.|r\n\n"..
"|cffff0000Left-Click to enable Mana-Blessing|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.seal.bstats =
"Stats-Blessing|cffffffff\n"..
"It enables the Stats-Blessing.|r\n\n"..
"|cffff0000Left-Click to enable Stats-Blessing|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.seal.bdps =
"DPS-Blessing|cffffffff\n"..
"It enables the DPS-Blessing.|r\n\n"..
"|cffff0000Left-Click to enable DPS-Blessing|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.master =
"Non-Combat-Aura|cffffffff\n"..
"This Control allows you to select, enable or disable the default Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Aura.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.bspeed =
"Speed-Aura|cffffffff\n"..
"It enables the Speed-Aura as Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Speed-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.rfire =
"Fire-Resist-Aura|cffffffff\n"..
"It enables the Fire-Resist-Aura as Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Fire-Resist-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.rfrost =
"Frost-Resist-Aura|cffffffff\n"..
"It enables the Frost-Resist-Aura as Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Frost-Resist-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.rshadow =
"Shadow-Resist-Aura|cffffffff\n"..
"It enables the Shadow-Resist-Aura as Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Shadow-Resist-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.baoe =
"Damage-Aura|cffffffff\n"..
"It enables the Damage-Aura as Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Damage-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.barmor =
"Armor-Aura|cffffffff\n"..
"It enables the Armor-Aura as Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Armor-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.naura.bcast =
"Concentration-Aura|cffffffff\n"..
"It enables the Concentration-Aura as Non-Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Armor-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.master =
"Combat-Aura|cffffffff\n"..
"This Control allows you to select, enable or disable the default Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Aura.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.bspeed =
"Speed-Aura|cffffffff\n"..
"It enables the Speed-Aura as Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Speed-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.rfire =
"Fire-Resist-Aura|cffffffff\n"..
"It enables the Fire-Resist-Aura as Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Fire-Resist-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.rfrost =
"Frost-Resist-Aura|cffffffff\n"..
"It enables the Frost-Resist-Aura as Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Frost-Resist-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.rshadow =
"Shadow-Resist-Aura|cffffffff\n"..
"It enables the Shadow-Resist-Aura as Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Shadow-Resist-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.baoe =
"Damage-Aura|cffffffff\n"..
"It enables the Damage-Aura as Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Damage-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.barmor =
"Armor-Aura|cffffffff\n"..
"It enables the Armor-Aura as Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Armor-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.caura.bcast =
"Concentration-Aura|cffffffff\n"..
"It enables the Concentration-Aura as Combat-Aura.|r\n\n"..
"|cffff0000Left-Click to enable Concentration-Aura|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.dps.dps =
"DPS|cffffffff\n"..
"It enables the DPS-Strategies.\n"..
"Tank, DPS and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.dps.offheal =
"OffHeal|cffffffff\n"..
"This disable dps mode and enable offheal, \n"..
"The bots will now focus damage but heal when necessary.\n"..
"Only for feral duid.|r\n\n"..
"|cffff0000Left-Click to enable or disable OffHeal|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.dps.healerdps =
"HealerDps|cffffffff\n"..
"Allows the healer to deal damage when it's safe.\n"..
"The bot keeps healing as the top priority and weaves DPS during low incoming damage.\n"..
"Recommended for healer builds (e.g., Holy Paladin).|r\n\n"..
"|cffff0000Left-Click to enable or disable HealerDps|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.paladin.tank =
"Tank|cffffffff\n"..
"It enables the Tank-Strategies.\n"..
"Tank, DPS and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- PRIEST --

MultiBot.tips.priest = {}
MultiBot.tips.priest.dps = {}
MultiBot.tips.priest.playbook = {}

MultiBot.tips.priest.heal =
"Heal|cffffffff\n"..
"It makes the Priest to the Healer of the Group.\n"..
"Shadow and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Heal|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.buff =
"Buff|cffffffff\n"..
"It allows the Priest to Buff the Group.|r\n\n"..
"|cffff0000Left-Click to enable or disable Buff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.playbook.master =
"Playbook|cffffffff\n"..
"In the Playbook you will find the Strategies typical for the Class.|r\n\n"..
"|cffff0000Left-Click to show or hide Playbook|r\n"..
"|cf9999999(Execution-Order: System)|r";

MultiBot.tips.priest.playbook.shadowDebuff =
"Shadow-Debuff|cffffffff\n"..
"Allows the Priest to use Shadow-Debuff-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Shadow-Debuff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.playbook.shadowAoe =
"Shadow-AOE|cffffffff\n"..
"Allows the Priest to use Shadow-AOE-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Shadow-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.playbook.shadow =
"Shadow|cffffffff\n"..
"Allows the Priest to use Shadow-Spells during the Combat.\n"..
"Shadow and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Shadow|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.playbook.holyheal =
"Holy Heal|cffffffff\n"..
"Switches the playbook to Holy (Heal).\n"..
"Holy Heal, Shadow and Holy DPS are mutually exclusive.\n"..
"Only one of these playbooks can be active.|r\n\n"..
"|cffff0000Left-Click to enable or disable Holy Heal|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.playbook.holydps =
"Holy DPS|cffffffff\n"..
"Switches the playbook to Holy (DPS).\n"..
"Holy DPS, Shadow and Holy Heal are mutually exclusive.\n"..
"Only one of these playbooks can be active.|r\n\n"..
"|cffff0000Left-Click to enable or disable Holy DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.playbook.rshadow =
"Shadow Resistance|cffffffff\n"..
"Turns on the Shadow-Resistance strategy.\n"..
"This option is not a playbook and can be combined with other playbooks.|r\n\n"..
"|cffff0000Left-Click to enable or disable Shadow Resistance|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies for Healers.\n"..
"DPS-AOE, DPS-Assist ('Healer-DPS') and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.dps.dpsDebuff =
"DPS-Debuff|cffffffff\n"..
"It enables the Debuff-Strategies.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Debuff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist ('Healer-DPS') and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.dps.dps =
"DPS|cffffffff\n"..
"It enables the DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.priest.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist ('Healer-DPS') and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- ROGUE --

MultiBot.tips.rogue = {}
MultiBot.tips.rogue.dps = {}

MultiBot.tips.rogue.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.rogue.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.rogue.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.rogue.dps.dps =
"DPS|cffffffff\n"..
"It enables the DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.rogue.dps.stealth =
"Stealth|cffffffff\n"..
"Keeps the Rogue stealthed whenever possible and favors stealth openers.\n"..
"Compatible with DPS modes. For in-combat behavior,\n"..
"use |cffffd200Stealthed (combat)|cffffffff.|r\n\n"..
"|cffff0000Left-Click to enable/disable Stealth|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.rogue.dps.stealthed =
"Stealthed (combat)|cffffffff\n"..
"Favors fighting while stealthed; approaches in stealth.\n"..
"Uses stealth openers and may pause DPS to re-stealth.\n"..
"‘Stealthed (combat)’ and DPS/DPS-AOE/DPS-Assist are mutually exclusive.\n"..
"Only one strategy can be active.|r\n\n"..
"|cffff0000Left-Click to enable/disable|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.rogue.dps.boost =
"Boost|cffffffff\n"..
"Enables use of offensive cooldowns according to the rotation.\n"..
"Works with DPS/DPS-AOE/DPS-Assist and Tank-Assist; not exclusive.|r\n\n"..
"|cffff0000Left-Click to enable/disable Boost|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.rogue.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- SHAMAN --

MultiBot.tips.shaman = {}
MultiBot.tips.shaman.dps = {}
MultiBot.tips.shaman.ntotem = {}
MultiBot.tips.shaman.ctotem = {}
MultiBot.tips.shaman.playbook = {}

MultiBot.tips.shaman.heal =
"Heal|cffffffff\n"..
"It makes the Shaman to the Healer of the Group.\n"..
"Caster, Melee and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Heal|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.totemsmove =
"Right-Click to drag and move the TotemBar";

MultiBot.tips.shaman.ctotem.stoe =
"Strength of Earth\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.stoskin =
"stoneskin\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.tremor =
"Tremor\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.eabind =
"Earthbind\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.searing =
"Searing\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.magma =
"Magma\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.fltong =
"Flametongue\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.towrath =
"Totem of Wrath\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.frostres =
"Frost Resistance\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.healstream =
"Healing Stream\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.manasprin =
"Mana Spring\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.cleansing =
"Cleansing\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.fireres =
"Fire Resistance\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.wrhatair =
"Wrath of Air\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.windfury =
"Windfury\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.natres =
"Nature Resistance\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.grounding =
"Grounding\n\n"..
"|cffff0000Left-Click to select or remove this Totem|r\n";

MultiBot.tips.shaman.ctotem.earthtot =
"Earth Totems";

MultiBot.tips.shaman.ctotem.firetot =
"Fire Totems";

MultiBot.tips.shaman.ctotem.watertot =
"Water Totems";

MultiBot.tips.shaman.ctotem.airtot =
"Air Totems";

MultiBot.tips.shaman.ntotem.master =
"Non-Combat-Totem|cffffffff\n"..
"This Control allows you to select, enable or disable the default Non-Combat-Totem.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Totem.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.ntotem.bmana =
"Mana-Totem|cffffffff\n"..
"It enables the Mana-Totem as Non-Combat-Totem.|r\n\n"..
"|cffff0000Left-Click to enable Mana-Totem|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.ntotem.bdps =
"DPS-Totem|cffffffff\n"..
"It enables the DPS-Totem as Non-Combat-Totem.|r\n\n"..
"|cffff0000Left-Click to enable DPS-Totem|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.ctotem.master =
"Combat-Totem|cffffffff\n"..
"This Control allows you to select, enable or disable the default Combat-Totem.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Totem.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.ctotem.bmana =
"Mana-Totem|cffffffff\n"..
"It enables the Mana-Totem as Combat-Totem.|r\n\n"..
"|cffff0000Left-Click to enable Mana-Totem|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.ctotem.bdps =
"DPS-Totem|cffffffff\n"..
"It enables the DPS-Totem as Combat-Totem.|r\n\n"..
"|cffff0000Left-Click to enable DPS-Totem|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.playbook.master =
"Playbook|cffffffff\n"..
"In the Playbook you will find the Strategies typical for the Class.|r\n\n"..
"|cffff0000Left-Click to show or hide Playbook|r\n"..
"|cf9999999(Execution-Order: System)|r";

MultiBot.tips.shaman.playbook.totems =
"Totems|cffffffff\n"..
"Allows the Shaman to use Totems during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Totems|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.playbook.casterAoe =
"Caster-AOE|cffffffff\n"..
"Allows the Shaman to use AOE-Spells during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Caster-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.playbook.caster =
"Caster|cffffffff\n"..
"Allows the Shaman to use Spells during the Combat.\n"..
"Caster, Melee and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Caster|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.playbook.meleeAoe =
"Melee-AOE|cffffffff\n"..
"Allows the Shaman to use Melee-AOE-Attacks during the Combat.|r\n\n"..
"|cffff0000Left-Click to enable or disable Melee-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.playbook.melee =
"Melee|cffffffff\n"..
"Allows the Shaman to use Melee-Attacks during the Combat.\n"..
"Caster, Melee and Heal are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Melee|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.playbook.cure =
"Cure|cffffffff\n"..
"It enables the Cure-Strategy.\n"..
"The bot will remove poisons, curses and diseases when possible.|r\n\n"..
"|cffff0000Left-Click to enable or disable Cure|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.dps.healerdps =
"Healer-DPS|cffffffff\n"..
"It enables the Healer-DPS-Strategy.\n"..
"The healer will contribute damage while still focusing on healing.\n"..
"Healer-DPS, DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Healer-DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.shaman.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- WARLOCK --

MultiBot.tips.warlock = {}
MultiBot.tips.warlock.dps = {}
MultiBot.tips.warlock.buff = {}

-- NEW
MultiBot.tips.warlock.curses = {}
MultiBot.tips.warlock.stones = {}
MultiBot.tips.warlock.soulstones = {}
MultiBot.tips.warlock.pets = {}

MultiBot.tips.warlock.stones.master =
"Weapon Stone Select|cffffffff\n"..
"Choose which weapon stone the bot will apply.|r\n\n"..
"|cffff0000Left-click to open menu|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.stones.spellstone =
"Spellstone|cffffffff\n"..
"Apply Spellstone (non-combat strategy)|r\n\n"..
"|cffff0000Left-click to Apply|r\n"..
"|cffff0000Left-click again to Remove|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.stones.firestone =
"Firestone|cffffffff\n"..
"Apply Firestone (non-combat strategy)|r\n\n"..
"|cffff0000Left-click to Apply|r\n"..
"|cffff0000Left-click again to Remove|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.soulstones.masterbutton =
"NC SoulStone Menu|cffffffff\n"..
"Specify which bot should receive the SoulStone.|r\n\n"..
"|cffff0000Left-click to open menu|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.soulstones.self =
"Self|cffffffff\n"..
"The bot will apply the SoulStone to itself (non-combat strategy)|r\n\n"..
"|cffff0000Left-click to Activate|r\n"..
"|cffff0000Left-click again to Deactivate|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.soulstones.master =
"Master|cffffffff\n"..
"The bot will apply the SoulStone to you (non-combat strategy)|r\n\n"..
"|cffff0000Left-click to Activate|r\n"..
"|cffff0000Left-click again to Deactivate|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.soulstones.tank =
"Tank|cffffffff\n"..
"The bot will apply the SoulStone to the Tank (non-combat strategy)|r\n\n"..
"|cffff0000Left-click to Activate|r\n"..
"|cffff0000Left-click again to Deactivate|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.soulstones.healer =
"Healer|cffffffff\n"..
"The bot will apply the SoulStone to the Healer (non-combat strategy)|r\n\n"..
"|cffff0000Left-click to Activate|r\n"..
"|cffff0000Left-click again to Deactivate|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.pets.master =
"Pet Select|cffffffff\n"..
"Choose which demon the bot should summon.|r\n\n"..
"|cffff0000Left-click to Apply|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.pets.imp =
"Imp|cffffffff\n"..
"Summon Imp|r\n\n"..
"|cffff0000Left-click to Summon|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.pets.voidwalker =
"Voidwalker|cffffffff\n"..
"Summon Voidwalker|r\n\n"..
"|cffff0000Left-click to Summon|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.pets.succubus =
"Succubus|cffffffff\n"..
"Summon Succubus|r\n\n"..
"|cffff0000Left-click to Summon|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.pets.felhunter =
"Felhunter|cffffffff\n"..
"Summon Felhunter|r\n\n"..
"|cffff0000Left-click to Summon|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.pets.felguard =
"Felguard|cffffffff\n"..
"Summon Felguard|r\n\n"..
"|cffff0000Left-click to Summon|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.curses.master =
"Curse Select|cffffffff\n"..
"This Control allows you to select, a curse to apply.|r\n\n"..
"|cffff0000Left-click to open the curse menu\n"..
"and choose which curse the bot will apply.\n"..
"The currently active curse is shown greyed-out.|r\n"..
"|cff999999(Execution Order: Bot)|r";

MultiBot.tips.warlock.curses.agony =
"Curse of Agony|cffffffff|r\n\n"..
"|cffff0000Left-Click to apply this curse.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.curses.elements =
"Curse of the Elements|cffffffff|r\n\n"..
"|cffff0000Left-Click to apply this curse.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.curses.exhaustion =
"Curse of Exhaustion|cffffffff|r\n\n"..
"|cffff0000Left-Click to apply this curse.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.curses.doom =
"Curse of Doom|cffffffff|r\n\n"..
"|cffff0000Left-Click to apply this curse.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.curses.weakness =
"Curse of Weakness|cffffffff|r\n\n"..
"|cffff0000Left-Click to apply this curse.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.curses.tongues =
"Curse of Tongues|cffffffff|r\n\n"..
"|cffff0000Left-Click to apply this curse.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.buff.master =
"Buff|cffffffff\n"..
"This Control allows you to select, enable or disable the default Buff.|r\n\n"..
"|cffff0000Left-Click to show or hide Options|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable or disable the default Buff.|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.buff.bhealth =
"Health-Buff|cffffffff\n"..
"It enables the Health-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Health-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.buff.bmana =
"Mana-Buff|cffffffff\n"..
"It enables the Mana-Buff.|r\n\n"..
"|cffff0000Left-Click to enable Mana-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.buff.bdps =
"DPS-Buff|cffffffff\n"..
"It enables the DPS-Buff.|r\n\n"..
"|cffff0000Left-Click to enable DPS-Buff|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.dps.dpsDebuff =
"DPS-Debuff|cffffffff\n"..
"It enables the DPS-Debuff-Strategies.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Debuff|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.dps.dps =
"DPS|cffffffff\n"..
"It enables the DPS-Strategies.\n"..
"DPS and Tank are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.dps.metamelee =
"Meta Melee|cffffffff\n"..
"Enables the Warlock 'meta melee' combat strategy.\n"..
"When Metamorphosis and Immolation Aura are active\n"..
"the bot will move to melee range and behave accordingly.\n"..
"This toggle has no effect without Metamorphosis/Immolation Aura\n"..
"and it is independent of DPS/Tank-Assist toggles.|r\n\n"..
"|cffff0000Left-Click to enable or disable Meta Melee|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warlock.tank =
"Tank|cffffffff\n"..
"It enables the Tank-Strategies.\n"..
"DPS and Tank are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- WARRIOR --

MultiBot.tips.warrior = {}
MultiBot.tips.warrior.dps = {}

MultiBot.tips.warrior.dps.master =
"DPS-Control|cffffffff\n"..
"In the DPS-Control you will find the general DPS-Strategies.|r\n\n"..
"|cffff0000Left-Click to show or hide DPS-Control|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warrior.dps.dpsAssist =
"DPS-Assist|cffffffff\n"..
"It enables the DPS-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warrior.dps.dpsAoe =
"DPS-AOE|cffffffff\n"..
"It enables the DPS-AOE-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable DPS-AOE|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warrior.tankAssist =
"Tank-Assist|cffffffff\n"..
"It enables the Tank-Assist-Strategies.\n"..
"DPS-AOE, DPS-Assist and Tank-Assist are mutually exclusive.\n"..
"Only one of these Strategies can be activated.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank-Assist|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

MultiBot.tips.warrior.tank =
"Tank|cffffffff\n"..
"It enables the Tank-Strategies.|r\n\n"..
"|cffff0000Left-Click to enable or disable Tank|r\n"..
"|cf9999999(Execution-Order: Bot)|r";

-- EVERY --

MultiBot.tips.every = {}

MultiBot.tips.every.misc =
"Miscellaneous|cffffffff\n"..
"Opens the menu of miscellaneous actions.\n"..
"Includes: Wipe, Autogear, etc.|r\n\n"..
"|cffff0000Left-click to toggle this menu|r\n"..
"|cff999999(Execution order: System)|r"

--[[MultiBot.tips.every.pvp =
"Send PvP command to bot|cffffffff\n"..
"Display pvp bots informations.|r\n\n"..
"|cffff0000Left-click to send command|r\n"..
"|cff999999(Execution order: Bot)|r";--]]

MultiBot.tips.every.pvptitle =
"MultiBot PvP Panel";

MultiBot.tips.every.pvpcustom =
"Custom PVP Datas";

MultiBot.tips.every.pvptotal =
"Total";

MultiBot.tips.every.pvparenapoints =
"Arena Points";

MultiBot.tips.every.pvparenamode =
"Mode";

MultiBot.tips.every.pvparenanoteam =
"Team: No team";

MultiBot.tips.every.pvparenanoteamrank =
"Team Rank: -";

MultiBot.tips.every.pvparenadata =
"PvP Datas ";

-- Favorites
MultiBot.tips.every.favorite =
"Favorite|cffffffff\n"..
"Add or remove this Bot from your Favorites (saved per character).|r\n\n"..
"|cffff0000Left-click to toggle|r\n"..
"|cff999999(Executed by: System)|r";

MultiBot.tips.every.autogear =
"AutoGear|cffffffff\n"..
"Automatically equips this Bot based on\n"..
"your AutoGear limits (quality / GearScore).|r\n\n"..
"|cffff0000Left-click to start AutoGear|r\n"..
"|cff999999(Execution order: Bot)|r";

MultiBot.tips.every.autogearpopup =
"Launch Autogear on %s ?";

MultiBot.tips.every.maintenance =
"Maintenance|cffffffff\n"..
"Enable bot to learn all available spells and skills, \n"..
"supplement consumables, enchant gear, and repair.|r\n\n"..
"|cffff0000Left-click to start Maintenance|r\n"..
"|cff999999(Execution order: Bot)|r";

MultiBot.tips.every.summon =
"Summon|cffffffff\n"..
"Summons this Bot to your Position.|r\n\n"..
"|cffff0000Left-Click to summons the Bot|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.uninvite =
"Uninvite|cffffffff\n"..
"Dismiss this Bot from your Group.|r\n\n"..
"|cffff0000Left-Click to dismiss the Bot|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.invite =
"Invite|cffffffff\n"..
"Invites this Bot to your Group.|r\n\n"..
"|cffff0000Left-Click to invite the Bot|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.food =
"Food|cffffffff\n"..
"It enables or disables the Food-Strategies.|r\n\n"..
"|cffff0000Left-Click to allow Food|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.loot =
"Loot|cffffffff\n"..
"It enables or disables the Loot-Strategies.|r\n\n"..
"|cffff0000Left-Click to allow Loot|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.gather =
"Gather|cffffffff\n"..
"It enables or disables the Gather-Strategies.|r\n\n"..
"|cffff0000Left-Click to allow Gather|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.inventory =
"Inventory|cffffffff\n"..
"It opens or closes the Inventory of this Bot.|r\n\n"..
"|cffff0000Left-Click to open or close the Inventory|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.spellbook =
"Spellbook|cffffffff\n"..
"It opens or closes the Spellbook of this Bot.\n"..
"Left-Click the Spell to cast it immediately.\n"..
"Right-Click the Spell to pickup a Macro for your Hotbars.|r\n\n"..
"|cffff0000Left-Click to open or close the Spellbook|r\n"..
"|cff999999(Execution-Order: Bot)|r";

MultiBot.tips.every.talent =
"Talent|cffffffff\n"..
"It opens or closes the Talents of this Bot.\n"..
"It opens with a time delay while the system loads the talent values.|r\n\n"..
"|cffff0000Left-Click to open or close the Talents|r\n"..
"|cff999999(Execution-Order: Bot)|r";

-- WIPE COMMAND --

MultiBot.tips.every.wipe =
"Wipe|cffffffff\n"..
"Fully resets the bot by killing it and resurrecting it,\n"..
"useful to clear its state (position, health, mana, etc.).|r\n\n"..
"|cffff0000Left-click: sends the wipe command to the selected bot|r\n"..
"|cff999999(Execution order: Bot)|r";

 -- SET TALENTS --

MultiBot.tips.every.settalent =
"Set Talents|cffffffff\n"..
"Displays a menu of available specializations (PvE/PvP) for the selected bot.\n"..
"Secondary specialization unlocks at level 40.|r\n\n"..
"|cffff0000Left-click to toggle the bot's talent template selector|r\n"..
"|cff999999(Execution order: Bot)|r"

-- DeathKnight
MultiBot.tips.spec.dkbloodpve =
  "Blood – PvE|cffffffff\n"..
  "Focused on self-healing and survivability in PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.dkbloodpvp =
  "Blood – PvP|cffffffff\n"..
  "Ideal for flag control and durability in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.dkbfrostpve =
  "Frost – PvE|cffffffff\n"..
  "Optimized for burst damage and slows in PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.dkbfrostpvp =
  "Frost – PvP|cffffffff\n"..
  "High burst and crowd control for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.dkunhopve =
  "Unholy – PvE|cffffffff\n"..
  "Strong AoE and pet synergy in PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.dkunhopvp =
  "Unholy – PvP|cffffffff\n"..
  "Persistent DOT pressure in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.dkdoublepve =
  "Double Template – PvE|cffffffff\n"..
  "Quickly test two builds in PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";


-- Druid
MultiBot.tips.spec.druidbalpve =
  "Balance – PvE|cffffffff\n"..
  "Eclipse bursts and magic damage optimized for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.druidbalpvp =
  "Balance – PvP|cffffffff\n"..
  "Starfall and roots for PvP crowd control.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.druidcatpve =
  "Feral (Cat) – PvE|cffffffff\n"..
  "Hybrid melee DPS for raid contributions.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.druidcatpvp =
  "Feral (Cat) – PvP|cffffffff\n"..
  "Bleeds and burst for PvP skirmishes.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.druidbearpve =
  "Feral (Bear) – PvE|cffffffff\n"..
  "Primary raid tank with high survivability.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.druidrestopve =
  "Restoration – PvE|cffffffff\n"..
  "Powerful HoTs for raid healing.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.druidrestopvp =
  "Restoration – PvP|cffffffff\n"..
  "Shields and CC to survive in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";


-- Hunter
MultiBot.tips.spec.huntbmpve =
  "Beast Mastery – PvE|cffffffff\n"..
  "Pet-focused damage and utility in PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.huntbmpvp =
  "Beast Mastery – PvP|cffffffff\n"..
  "Burst and CC immunity via your pet in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.huntmarkpve =
  "Marksmanship – PvE|cffffffff\n"..
  "High single-target burst with precision shots.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.huntmarkpvp =
  "Marksmanship – PvP|cffffffff\n"..
  "Burst damage and traps for PvP control.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.huntsurvpve =
  "Survival – PvE|cffffffff\n"..
  "Utility and DoTs in PvE encounters.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.huntsurvpvp =
  "Survival – PvP|cffffffff\n"..
  "Traps and crowd control for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";


-- Mage
MultiBot.tips.spec.magearcapve =
  "Arcane – PvE|cffffffff\n"..
  "Mana management and burst spells for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.magearcapvp =
  "Arcane – PvP|cffffffff\n"..
  "Mobility and shields for PvP skirmishes.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.magefirepve =
  "Fire – PvE|cffffffff\n"..
  "Ignites and AoE flame bursts for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.magefirepvp =
  "Fire – PvP|cffffffff\n"..
  "Scorch and crowd control for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.magefrostfirepve =
  "Frostfire – PvE|cffffffff\n"..
  "Combines fire and frost for unique burst.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.magefrostpve =
  "Frost – PvE|cffffffff\n"..
  "Fingers of Frost and slows for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.magefrostpvp =
  "Frost – PvP|cffffffff\n"..
  "Shatter combos and roots for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";


-- Paladin
MultiBot.tips.spec.paladinholypve =
  "Holy – PvE|cffffffff\n"..
  "Powerful raid healing.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.paladinholypvp =
  "Holy – PvP|cffffffff\n"..
  "Bubble and dispels for PvP survival.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.paladinprotpve =
  "Protection – PvE|cffffffff\n"..
  "Main raid tanking.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.paladinprotpvp =
  "Protection – PvP|cffffffff\n"..
  "Flag carrying and durability in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.paladinretpve =
  "Retribution – PvE|cffffffff\n"..
  "Offensive burst and support.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.paladinretpvp =
  "Retribution – PvP|cffffffff\n"..
  "Control and burst in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";


-- Priest
MultiBot.tips.spec.priestdiscipve =
  "Discipline – PvE|cffffffff\n"..
  "Absorbs and shields for raid support.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"..
  "|cffff0000Right-click to set as secondary spec|r\n"..
  "|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.priestdiscipvp =
  "Discipline – PvP|cffffffff\n"..
  "Burst healing and Penances for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.priestholypve =
  "Holy – PvE|cffffffff\n"..
  "Sanctuary and CoH for raid healing.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.priestholypvp =
  "Holy – PvP|cffffffff\n"..
  "Guardian Spirit and burst heal in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.priestshadowpve =
  "Shadow – PvE|cffffffff\n"..
  "DOT pressure and Insanity for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.priestshadowpvp =
  "Shadow – PvP|cffffffff\n"..
  "Silence and pressure in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";


-- Rogue
MultiBot.tips.spec.rogassapve =
  "Assassination – PvE|cffffffff\n"..
  "Poisons and DOTs for sustained DPS.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.rogassapvp =
  "Assassination – PvP|cffffffff\n"..
  "Vendetta and burst for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.rogcombatpve =
  "Combat – PvE|cffffffff\n"..
  "Cleave and energy for sustained DPS.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.rogcombatpvp =
  "Combat – PvP|cffffffff\n"..
  "Extended burst for PvP skirmishes.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.rogsubtipve =
  "Subtlety – PvE|cffffffff\n"..
  "Backstab and energy for intense DPS.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.rogsubtipvp =
  "Subtlety – PvP|cffffffff\n"..
  "Shadowdance and control for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";


-- Shaman
MultiBot.tips.spec.shamanelempve =
  "Elemental – PvE|cffffffff\n"..
  "Lava Burst and Maelstrom optimized for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.shamanelempvp =
  "Elemental – PvP|cffffffff\n"..
  "Burst and knockbacks for PvP skirmishes.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.shamanenhpve =
  "Enhancement – PvE|cffffffff\n"..
  "Dual-wield and Maelstrom for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.shamanenhpvp =
  "Enhancement – PvP|cffffffff\n"..
  "Wolves and burst damage for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.shamanrestopve =
  "Restoration – PvE|cffffffff\n"..
  "Chain Heal and raid support in PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.shamanrestopvp =
  "Restoration – PvP|cffffffff\n"..
  "Earth Shield and survival in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";


-- Warlock
MultiBot.tips.spec.warlockafflipve =
  "Affliction – PvE|cffffffff\n"..
  "Long-duration DOTs for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warlockafflipvp =
  "Affliction – PvP|cffffffff\n"..
  "Constant pressure DOTs in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warlockdemonopve =
  "Demonology – PvE|cffffffff\n"..
  "Metamorphosis and pets for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warlockdemonopvp =
  "Demonology – PvP|cffffffff\n"..
  "Felguard and burst for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warlockdestrupve =
  "Destruction – PvE|cffffffff\n"..
  "Chaos Bolt and heavy burst in PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warlockdestrupvp =
  "Destruction – PvP|cffffffff\n"..
  "Burst and fear control for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";


-- Warrior
MultiBot.tips.spec.warriorarmspve =
  "Arms – PvE|cffffffff\n"..
  "Execute and burst for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warriorarmspvp =
  "Arms – PvP|cffffffff\n"..
  "Mortal Strike and control for PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warriorfurypve =
  "Fury – PvE|cffffffff\n"..
  "Whirlwind and rage for sustained DPS.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warriorfurypvp =
  "Fury – PvP|cffffffff\n"..
  "Sustain and self-healing in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warriorprotecpve =
  "Protection – PvE|cffffffff\n"..
  "Tanking and toughness for PvE.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

MultiBot.tips.spec.warriorprotecpvp =
  "Protection – PvP|cffffffff\n"..
  "Control and resilience in PvP.\n"..
  "Secondary spec unlocked at level 40.|r\n\n"..
  "|cffff0000Left-click to set as primary spec|r\n"
  .."|cffff0000Right-click to set as secondary spec|r\n"
  .."|cff999999(Execution order: Bot)|r";

-- RTSC --

MultiBot.tips.rtsc = {}
MultiBot.tips.rtsc.master =
"RTSC-Control\n|cffffffff"..
"With this Control you can define Locations and send Bots there.\n"..
"The Execution-Order shows the Receiver for Commandos.|r\n\n"..
"|cffff0000Left-Click to cast the AEDM-Spell|r\n"..
"|cff999999(Execution-Order: System)|r\n\n"..
"|cffff0000Right-Click to enable RTSC-Strategy|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.rtsc.macro =
"Location-Storage\n|cffffffff"..
"This Button allows you to save a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to save a Location|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.spot =
"Location-Storage\n|cffffffff"..
"Left-Click to send the Bots to the saved Location.\n"..
"Right-Click to remove the saved Location.|r\n\n"..
"|cffff0000Left-Click to send the Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to remove the Location|r\n"..
"|cff999999(Execution-Order: System)|r";

MultiBot.tips.rtsc.group1 =
"Group-Selector\n|cffffffff"..
"This Button selects the 1st Group and sends it to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the 1st Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the 1st Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.group2 =
"Group-Selector\n|cffffffff"..
"This Button selects the 2nd Group and sends it to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the 2nd Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the 2nd Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.group3 =
"Group-Selector\n|cffffffff"..
"This Button selects the 3rd Group and sends it to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the 3rd Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the 3rd Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.group4 =
"Group-Selector\n|cffffffff"..
"This Button selects the 4th Group and sends it to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the 4th Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the 4th Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.group5 =
"Group-Selector\n|cffffffff"..
"This Button selects the 5th Group and sends it to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the 5th Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the 5th Group|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.tank =
"Tank-Selector\n|cffffffff"..
"This Button selects the Tank-Bots and sends them to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the Tank-Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the Tank-Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.dps =
"DPS-Selector\n|cffffffff"..
"This Button selects the DPS-Bots and sends them to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the DPS-Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the DPS-Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.healer =
"Healer-Selector\n|cffffffff"..
"This Button selects the Healer-Bots and sends them to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the Healer-Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the Healer-Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.melee =
"Melee-Selector\n|cffffffff"..
"This Button selects the Melee-Fighters and sends them to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the Melee-Fighters|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the Melee-Fighters|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.ranged =
"Ranged-Selector\n|cffffffff"..
"This Button selects the Ranged-Fighters and sends them to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send the Ranged-Fighters|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select the Ranged-Fighters|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.meleedps =
"Melee DPS\n|cffffffff"..
"Only Melee DPS bots will execute the action.\n"..
"|cffff0000Left-click to send|r\n"..
"|cff999999(Executed by: Raid, Party)|r\n\n"..
"|cffff0000Right-click to select|r\n"..
"|cff999999(Executed by: Raid, Party)|r";

MultiBot.tips.rtsc.rangeddps =
"Ranged DPS\n|cffffffff"..
"Only Ranged DPS bots will execute the action.\n"..
"|cffff0000Left-click to send|r\n"..
"|cff999999(Executed by: Raid, Party)|r\n\n"..
"|cffff0000Right-click to select|r\n"..
"|cff999999(Executed by: Raid, Party)|r";

MultiBot.tips.rtsc.all =
"All-Selector\n|cffffffff"..
"This Button selects the all Bots and sends them to a Location.\n"..
"Left-Click and then use the AEDM-Spell to mark a Location.|r\n\n"..
"|cffff0000Left-Click to send all Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to select all Bots|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

MultiBot.tips.rtsc.browse =
"Browse-Selector\n|cffffffff"..
"This Button switches throu the differend Selectorbars.|r\n\n"..
"|cffff0000Left-Click to switch the Selectorbar|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r\n\n"..
"|cffff0000Right-Click to cancel the Selection|r\n"..
"|cff999999(Execution-Order: Raid, Party)|r";

-- Raidus
MultiBot.tips.raidus = {}

MultiBot.tips.raidus.score =
"|cffffff00Sort Bots by Score|r";

MultiBot.tips.raidus.level =
"|cffffff00Sort Bots by Level|r";

MultiBot.tips.raidus.class =
"|cffffff00Sort Bots by Class|r";

MultiBot.tips.raidus.autobalance =
"|cffffff00Auto-Balance Raid|r\n|cffffffff"..
"Automatically arranges bots into raid groups for a more balanced setup.|r\n"..
"|cffff0000Left-Click:|r |cffffffffBalance by score (overall raid power).|r\n"..
"|cffff0000Right-Click:|r |cffffffffAdvanced Tank / Heal / DPS balance per group.|r\n\n"..
"|cff999999Uses selected bots from the MultiBot list, or all bots if none are selected.|r";

MultiBot.GM = false
