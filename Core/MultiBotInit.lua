-- Minimap config is resolved through MultiBot.GetMinimapConfig().

--local MB_INVENTORY_LABEL = INVENTORY_TOOLTIP or BAGSLOT or "Inventory"
-- local MB_PAGE_DEFAULT = string.format("%d/%d", 0, 0)
MultiBot.MB_PAGE_DEFAULT = string.format("%d/%d", 0, 0)
--local MB_TAB_TITLE_DEFAULT = UNKNOWN or ""

-- =====================================================================
--  MINIMAP BUTTON
-- =====================================================================
do
  local BTN_NAME = "MultiBot_MinimapButton"
  local RADIUS   = 80  -- rayon d’ancrage au bord de la minimap

  local function deg2rad(d) return d * math.pi / 180 end

  local function UpdatePosition(self, angle)
    local minimap = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil
    angle = angle or (minimap and minimap.angle) or 220
    if not Minimap or not Minimap:GetCenter() then return end
    local mx, my = Minimap:GetCenter()
    local sx, sy = GetScreenWidth(), GetScreenHeight()
    if not mx or not my or not sx or not sy then return end
    local r = RADIUS * (Minimap:GetEffectiveScale() / UIParent:GetEffectiveScale())
    local x = math.cos(deg2rad(angle)) * r
    local y = math.sin(deg2rad(angle)) * r
    self:ClearAllPoints()
    self:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end

  local function SaveAngleFromCursor(self)
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale  = UIParent:GetEffectiveScale()
    cx, cy = cx/scale, cy/scale
    local dx, dy = cx - mx, cy - my
    local angle  = math.deg(math.atan2(dy, dx))
    if angle < 0 then angle = angle + 360 end
    if MultiBot.SetMinimapConfig then
      MultiBot.SetMinimapConfig("angle", angle)
    end
    UpdatePosition(self, angle)
  end

  function MultiBot.Minimap_Create()
    if _G[BTN_NAME] then
      MultiBot.Minimap_Refresh()
      return _G[BTN_NAME]
    end
    -- Respecter l’éventuel “hide”
    local minimap = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil
    if minimap and minimap.hide then return nil end

    local b = CreateFrame("Button", BTN_NAME, Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:SetMovable(true)
    b:SetClampedToScreen(true)
    b:RegisterForDrag("LeftButton")
    b:RegisterForClicks("AnyUp")

    -- Anneau/bord standard de la minimap
    local overlay = b:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetSize(56, 56)
    overlay:SetPoint("TOPLEFT")

    -- Icône (prends un pictogramme existant du pack)
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\browse.blp")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    b.icon = icon

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    hl:SetBlendMode("ADD")
    hl:SetAllPoints(b)

    b:SetScript("OnDragStart", function(self)
      self:SetScript("OnUpdate", SaveAngleFromCursor)
    end)
    b:SetScript("OnDragStop", function(self)
      self:SetScript("OnUpdate", nil)
      SaveAngleFromCursor(self)
    end)

    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT")
      GameTooltip:ClearLines()
      GameTooltip:AddLine(MultiBot.L("info.butttitle"), 1, 1, 1)
      GameTooltip:AddLine(MultiBot.L("info.buttontoggle"), 0.9, 0.9, 0.9)
      GameTooltip:AddLine(MultiBot.L("info.buttonoptions"), 0.9, 0.9, 0.9)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    b:SetScript("OnClick", function(self, btn)
      if btn == "RightButton" then
        if MultiBot.ToggleOptionsPanel then
          MultiBot.ToggleOptionsPanel()
        elseif InterfaceOptionsFrame_OpenToCategory and MultiBot.BuildOptionsPanel then
          MultiBot.BuildOptionsPanel()
          InterfaceOptionsFrame_OpenToCategory("MultiBot")
          InterfaceOptionsFrame_OpenToCategory("MultiBot")
        end
      else
        -- Clic gauche: même effet que /mb
        if SlashCmdList and SlashCmdList["MULTIBOT"] then
          SlashCmdList["MULTIBOT"]()
        else
          -- Fallback local if slash commands are unavailable.
          if MultiBot.ToggleMainUIVisibility then
            MultiBot.ToggleMainUIVisibility()
          end
        end
      end
    end)

    UpdatePosition(b)
    b:Show()
    MultiBot.MinimapButton = b
    return b
  end

  function MultiBot.Minimap_Refresh()
    local minimap = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or nil

    local b = _G[BTN_NAME] or MultiBot.MinimapButton
    if minimap and minimap.hide then
      if b then b:Hide() end
      return
    end
    if not b then b = MultiBot.Minimap_Create() end
    if b then
      UpdatePosition(b)
      b:Show()
    end
  end
end

-- ------------------------------------------------------------------
--  Helper universel : TimerAfter
-- ------------------------------------------------------------------
if not TimerAfter then
    function TimerAfter(delay, callback)
        if C_Timer and C_Timer.After then
            return C_Timer.After(delay, callback)
        end
        local f = CreateFrame("Frame")
        f.elapsed = 0
        f:SetScript("OnUpdate", function(self, dt)
            self.elapsed = self.elapsed + dt
            if self.elapsed >= delay then
                self:SetScript("OnUpdate", nil)
                if callback then pcall(callback) end
            end
        end)
    end
    -- rendez-la accessible ailleurs
    MultiBot    = _G.MultiBot or {}
    MultiBot.TimerAfter = TimerAfter
end

-- MULTIBAR --
local tMultiBar = MultiBot.addFrame("MultiBar", -322, 144, 36)
MultiBot.PromoteFrame(tMultiBar)
tMultiBar:SetMovable(true)
-- Évite les micro-dépassements avec certains UI scale qui finissent par décaler Y
tMultiBar:SetClampedToScreen(true)

-- LEFT --
local tLeft = tMultiBar.addFrame("Left", -76, 2, 32)
MultiBot.PromoteFrame(tLeft)

-- TANKER --
tLeft.addButton("Tanker", -170, 0, "ability_warrior_shieldbash", MultiBot.L("tips.tanker.master"))
.doLeft = function(pButton)
	if(MultiBot.isTarget()) then MultiBot.ActionToGroup("@tank do attack my target") end
end

--  We call it when tLeft are ready
MultiBot.BuildAttackUI(tLeft)

-- MODE --
local tButton = tLeft.addButton("Mode", -102, 0, "Interface\\AddOns\\MultiBot\\Icons\\mode_passive.blp", MultiBot.L("tips.mode.master")).setDisable()
tButton.doRight = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Mode"])
end
tButton.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.ActionToGroup("co +passive,?")
	else
		MultiBot.ActionToGroup("co -passive,?")
	end
end

local tMode = tLeft.addFrame("Mode", -104, 34)
tMode:Hide()

tMode.addButton("Passive", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\mode_passive.blp", MultiBot.L("tips.mode.passive"))
.doLeft = function(pButton)
	if(MultiBot.SelectToGroup(pButton.parent.parent, "Mode", pButton.texture, "co +passive,?")) then
		pButton.parent.parent.buttons["Mode"].setEnable().doLeft = function(pButton)
			if(MultiBot.OnOffSwitch(pButton)) then
				MultiBot.ActionToGroup("co +passive,?")
			else
				MultiBot.ActionToGroup("co -passive,?")
			end
		end
	end
end

tMode.addButton("Grind", 0, 30, "Interface\\AddOns\\MultiBot\\Icons\\mode_grind.blp", MultiBot.L("tips.mode.grind"))
.doLeft = function(pButton)
	if(MultiBot.SelectToGroup(pButton.parent.parent, "Mode", pButton.texture, "grind")) then
		pButton.parent.parent.buttons["Mode"].setEnable().doLeft = function(pButton)
			if(MultiBot.OnOffSwitch(pButton)) then
				MultiBot.ActionToGroup("grind")
			else
				MultiBot.ActionToGroup("follow")
			end
		end
	end
end

-- STAY|FOLLOW --
tLeft.addButton("Stay", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.L("tips.stallow.stay"))
.doLeft = function(pButton)
	if(MultiBot.ActionToGroup("stay")) then
		pButton.parent.buttons["Follow"].doShow()
		pButton.parent.buttons["ExpandFollow"].setDisable()
		pButton.parent.buttons["ExpandStay"].setEnable()
		pButton.doHide()
	end
end

tLeft.addButton("Follow", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.L("tips.stallow.follow")).doHide()
.doLeft = function(pButton)
	if(MultiBot.ActionToGroup("follow")) then
		pButton.parent.buttons["Stay"].doShow()
		pButton.parent.buttons["ExpandFollow"].setEnable()
		pButton.parent.buttons["ExpandStay"].setDisable()
		pButton.doHide()
	end
end

tLeft.addButton("ExpandStay", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.tips.expand.stay).doHide().setDisable()
.doLeft = function(pButton)
	MultiBot.ActionToGroup("stay")
	pButton.parent.buttons["ExpandFollow"].setDisable()
	pButton.setEnable()
end

tLeft.addButton("ExpandFollow", -102, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.tips.expand.follow).doHide()
.doLeft = function(pButton)
	MultiBot.ActionToGroup("follow")
	pButton.parent.buttons["ExpandStay"].setDisable()
	pButton.setEnable()
end

--  We call it when tLeft are ready
MultiBot.BuildFleeUI(tLeft)

--  UI FORMATION --
function MultiBot.BuildFormationUI(tLeft)
  -- 1. Formation Table
  local FORMATION_BUTTONS = {
    { name = "Arrow",  icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_arrow.blp",  cmd = "formation arrow"  },
    { name = "Queue",  icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_queue.blp",  cmd = "formation queue"  },
    { name = "Near",   icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_near.blp",   cmd = "formation near"   },
    { name = "Melee",  icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_melee.blp",  cmd = "formation melee"  },
    { name = "Line",   icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_line.blp",   cmd = "formation line"   },
    { name = "Circle", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_circle.blp", cmd = "formation circle" },
    { name = "Chaos",  icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_chaos.blp",  cmd = "formation chaos"  },
    { name = "Shield", icon = "Interface\\AddOns\\MultiBot\\Icons\\formation_shield.blp", cmd = "formation shield" },
  }

  local function AddFormationButton(frame, info, col, row, cellW, cellH)
    frame.addButton(info.name,
                    (col-1)*cellW,
                    (row-1)*cellH,
                    info.icon,
                    MultiBot.L("tips.format." .. string.lower(info.name)))
      .doLeft = function(btn)
        MultiBot.SelectToGroup(btn.parent.parent, "Format", btn.texture, info.cmd)
      end
  end

  -- Main Button --
  local fBtn = tLeft.addButton("Format", 0, 0,
                               "Interface\\AddOns\\MultiBot\\Icons\\formation_near.blp",
                               MultiBot.L("tips.format.master"))

  fBtn.doLeft  = function(btn)  MultiBot.ShowHideSwitch(btn.parent.frames["Format"]) end
  fBtn.doRight = function()     MultiBot.ActionToGroup("formation")                 end

  -- Internal Frame --
  local tFormat = tLeft.addFrame("Format", -2, 34)
  tFormat:Hide()

  -- Grid 1 × N (columns) --
  --local COLS     = 1     -- One column
  local CELL_W   = 40    -- wide (useless here but we keep the arg.)
  local CELL_H   = 30    -- high/vertival spacing

  for idx, data in ipairs(FORMATION_BUTTONS) do
  local col = 1                                    -- toujours 1
  local row = idx                                   -- 1,2,3…
  AddFormationButton(tFormat, data, col, row, CELL_W, CELL_H)
  end
end

-- We call it, when tLeft are ready
MultiBot.BuildFormationUI(tLeft)

-- BEASTMASTER --
if MultiBot.InitializeBeastUI then
	MultiBot.InitializeBeastUI(tLeft)
end

--  CREATOR --
if MultiBot.InitializeCreatorUI then
	MultiBot.InitializeCreatorUI(tLeft)
end

-- UNITS --
local tButton = tMultiBar.addButton("Units", -38, 0, "inv_scroll_04", MultiBot.L("tips.units.master"))
tButton.roster = "players"
tButton.filter = "none"

tButton.doRight = function(pButton)
  local isGuildRetry = pButton._guildRosterRetrying == true
  pButton._guildRosterRetrying = false
  local retryCount = tonumber(pButton._guildRosterRetryCount) or 0
  if not isGuildRetry then
    retryCount = 0
  end
  local needGuildRetry = false

  -- Always refresh guild/friend rosters so their indexes stay in sync
  local prevShowOffline = nil
  if type(GetGuildRosterShowOffline) == "function" and type(SetGuildRosterShowOffline) == "function" then
    prevShowOffline = GetGuildRosterShowOffline()
    if prevShowOffline == false then
      SetGuildRosterShowOffline(true)
    end
  end

  if(type(GuildRoster) == "function") then GuildRoster() end
  if(type(ShowFriends) == "function") then ShowFriends() end

  -- Reset indexes before rebuilding them
  MultiBot.index.members = {}
  MultiBot.index.classes.members = {}
  MultiBot.index.friends = {}
  MultiBot.index.classes.friends = {}

  -- MEMBERBOTS --
  local inGuild = false
  if type(IsInGuild) == "function" then
    inGuild = IsInGuild()
  elseif type(GetGuildInfo) == "function" then
    inGuild = (GetGuildInfo("player") ~= nil)
  end

  local tMaxMembers = 0
  if type(GetNumGuildMembers) == "function" then
    tMaxMembers = select(1, GetNumGuildMembers()) or 0
  end
  tMaxMembers = tonumber(tMaxMembers) or 0
  if tMaxMembers <= 0 then
    tMaxMembers = 50
    if inGuild then
      needGuildRetry = true
    end
  end

  local guildCount = 0
  for i = 1, tMaxMembers do
    local tName, _, _, tLevel, tClass = GetGuildRosterInfo(i)
    if(tName ~= nil and tLevel ~= nil and tClass ~= nil and tName ~= UnitName("player")) then
      guildCount = guildCount + 1
      local tMember = MultiBot.addMember(tClass, tLevel, tName)
      if(tMember.state == false) then
        tMember.setDisable()
      else
        tMember.setEnable()
      end

      tMember.doRight = function(pButton)
        if(pButton.state == false) then return end
        SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
        if(pButton.parent.frames[pButton.name] ~= nil) then pButton.parent.frames[pButton.name]:Hide() end
        pButton.setDisable()
      end

      tMember.doLeft = function(pButton)
        if(pButton.state) then
          if(pButton.parent.frames[pButton.name] ~= nil) then MultiBot.ShowHideSwitch(pButton.parent.frames[pButton.name]) end
        else
          SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
          pButton.setEnable()
        end
      end
    elseif(tName == nil or tLevel == nil or tClass == nil) then
      if inGuild and i < tMaxMembers then
        needGuildRetry = true
      end
      break
    end
  end

  if prevShowOffline == false and type(SetGuildRosterShowOffline) == "function" then
    SetGuildRosterShowOffline(false)
  end

  if not isGuildRetry and inGuild and tMaxMembers == 50 and guildCount == 50 then
    needGuildRetry = true
  end

  if (not isGuildRetry) and needGuildRetry and type(TimerAfter) == "function" and retryCount < 6 then
    pButton._guildRosterRetryCount = retryCount + 1
    pButton._guildRosterRetrying = true
    TimerAfter(0.25, function()
      if pButton and pButton.doRight then
        pButton.doRight(pButton)
      end
    end)
  else
    pButton._guildRosterRetryCount = 0
  end

  -- FRIENDBOTS --
  local tMaxFriends = 0
  if type(GetNumFriends) == "function" then
    tMaxFriends = GetNumFriends() or 0
  end
  tMaxFriends = tonumber(tMaxFriends) or 0
  if tMaxFriends <= 0 then
    tMaxFriends = 50
  end
  for i = 1, tMaxFriends do
    local tName, tLevel, tClass = GetFriendInfo(i)
    if(tName ~= nil and tLevel ~= nil and tClass ~= nil and tName ~= UnitName("player")) then
      local tFriend = MultiBot.addFriend(tClass, tLevel, tName)
      if(tFriend.state == false) then
        tFriend.setDisable()
      else
        tFriend.setEnable()
      end

      tFriend.doRight = function(pButton)
        if(pButton.state == false) then return end
        SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
        if(pButton.parent.frames[pButton.name] ~= nil) then pButton.parent.frames[pButton.name]:Hide() end
        pButton.setDisable()
      end

      tFriend.doLeft = function(pButton)
        if(pButton.state) then
          if(pButton.parent.frames[pButton.name] ~= nil) then MultiBot.ShowHideSwitch(pButton.parent.frames[pButton.name]) end
        else
          SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
          pButton.setEnable()
        end
      end
    --elseif(tName == nil) then
      --break
    elseif(tName == nil or tLevel == nil or tClass == nil) then
      needGuildRetry = true
    end
  end

  -- Roster requiring server feedback (players/actives/favorites)
    if not isGuildRetry then
  local tRoster = pButton.roster or "players"
  if(tRoster == "players" or tRoster == "actives" or tRoster == "favorites") then
    SendChatMessage(".playerbot bot list", "SAY")
    if(tRoster == "favorites" and MultiBot.UpdateFavoritesIndex ~= nil) then
      MultiBot.UpdateFavoritesIndex()
    end
  end
  -- Pour les bots déjà groupés : relance un cycle "co ?" afin qu'ils renvoient leurs stratégies
  local function RefreshStrategiesFor(name)
    if not name or name == UnitName("player") then return end

    local rosters = { "actives", "players", "members", "friends", "favorites" }
    local isBot = false
    local hasAnyRoster = false

    if MultiBot.isRoster and MultiBot.index then
      for i = 1, #rosters do
        local rosterName = rosters[i]
        local list = MultiBot.index[rosterName]
        if list and next(list) ~= nil then
          hasAnyRoster = true
        end
        if list and MultiBot.isRoster(rosterName, name) then
          isBot = true
          break
        end
      end
    end

    if not isBot then
      -- Si aucun index n'est encore alimenté (ex: au login), on tente quand même la requête
      if hasAnyRoster then return end
    end

    local unitsFrame = MultiBot.frames
                      and MultiBot.frames["MultiBar"]
                      and MultiBot.frames["MultiBar"].frames
                      and MultiBot.frames["MultiBar"].frames["Units"]
    local btn = unitsFrame and unitsFrame.buttons and unitsFrame.buttons[name]
    if btn then btn.waitFor = "CO" end

    SendChatMessage("co ?", "WHISPER", nil, name)
  end

  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do
      RefreshStrategiesFor(UnitName("raid" .. i))
    end
  elseif IsInGroup() then
    for i = 1, GetNumSubgroupMembers() do
      RefreshStrategiesFor(UnitName("party" .. i))
    end
  end

    end

  pButton.doLeft(pButton, pButton.roster, pButton.filter)

  if type(TimerAfter) == "function" then
    TimerAfter(0.25, function()
      local btn = MultiBot.frames
                  and MultiBot.frames["MultiBar"]
                  and MultiBot.frames["MultiBar"].buttons
                  and MultiBot.frames["MultiBar"].buttons["Units"]
      if btn and btn.doLeft then
        btn.doLeft(btn, btn.roster, btn.filter)
      end
    end)
  end
end

tButton.doLeft = function(pButton, oRoster, oFilter)
	MultiBot.dprint("Units.doLeft", "roster=", oRoster or pButton.roster, "filter=", oFilter or pButton.filter)-- DEBUG

	local tUnits = pButton.parent.frames["Units"]
	local tTable = nil

	for key, value in pairs(tUnits.buttons) do value:Hide() end
	for key, value in pairs(tUnits.frames) do value:Hide() end
	tUnits.frames["Alliance"]:Show()
	tUnits.frames["Control"]:Show()

	if(oRoster == nil and oFilter == nil) then MultiBot.ShowHideSwitch(tUnits)
	elseif(oRoster ~= nil) then pButton.roster = oRoster
	elseif(oFilter ~= nil) then pButton.filter = oFilter
	end

    -- Safety net: if roster is 'players' but index is empty, rebuild or request the list.
    if oRoster == "players" or pButton.roster == "players" then
      if not (MultiBot.index.players and #MultiBot.index.players > 0) then
        if MultiBot.RebuildPlayersIndexFromButtons then MultiBot.RebuildPlayersIndexFromButtons() end
        if not (MultiBot.index.players and #MultiBot.index.players > 0) then
          -- Still empty: request the list once.
          SendChatMessage(".playerbot bot list", "SAY")
        end
      end
    end

    -- Build the source table according to roster/filter.
    if pButton.roster == "players" then
      -- Merge players ∪ actives so already grouped bots also appear.
      local function merge_lists(a, b)
        local res, seen = {}, {}
        if a then for i=1,#a do local n=a[i]; if n and not seen[n] then seen[n]=true; table.insert(res, n) end end end
        if b then for i=1,#b do local n=b[i]; if n and not seen[n] then seen[n]=true; table.insert(res, n) end end end
        return res
      end
      if pButton.filter ~= "none" then
        local byClassPlayers = MultiBot.index.classes.players[pButton.filter]
        local byClassActives = MultiBot.index.classes.actives[pButton.filter]
        tTable = merge_lists(byClassPlayers, byClassActives)
      else
        tTable = merge_lists(MultiBot.index.players, MultiBot.index.actives)
      end
    else
      if pButton.filter ~= "none" then
        tTable = MultiBot.index.classes[pButton.roster][pButton.filter]
      else
        tTable = MultiBot.index[pButton.roster]
      end
    end
    MultiBot.dprint("Units.tTable.size", tTable and #tTable or 0) -- DEBUG
        -- End of source table build according to roster/filter.

        local tButton = nil
        local tFrame = nil
        local tIndex = 0

        -- Some favorites may load before their buttons are created
        -- (for example right after login, before `.playerbot bot list` returns).
        -- Filter the list to display only entries with an existing button
        -- to avoid Lua errors while still allowing the view to fill in
        -- as soon as data arrives.
        --
        local tDisplay = {}
        if tTable ~= nil then
          for i = 1, #tTable do
            local name = tTable[i]
            if name ~= nil and tUnits.buttons[name] ~= nil then
              table.insert(tDisplay, name)
            else
              MultiBot.dprint("Units.skip", name or "<nil>", "(missing button)")
            end
          end
        end

        pButton.limit = #tDisplay

        pButton.from = 1
        pButton.to = 10

        for i = 1, pButton.limit do
                tIndex = (i - 1)%10 + 1
                local unitName = tDisplay[i]
                tFrame = tUnits.frames[unitName]
                tButton = tUnits.buttons[unitName]
                if(tButton ~= nil) then tButton.setPoint(0, (tUnits.size + 2) * (tIndex - 1)) end
                if(tFrame ~=nil) then tFrame.setPoint(-34, (tUnits.size + 2) * (tIndex - 1) + 2) end

                if(pButton.from <= i and pButton.to >= i) then
                        if(tFrame ~= nil and tButton ~= nil and tButton.state) then tFrame:Show() end
                        if(tButton ~= nil) then tButton:Show() end
                end
        end

        if(pButton.limit < pButton.to)
        then tUnits.frames["Control"].setPoint(-2, (tUnits.size + 2) * pButton.limit)
        else tUnits.frames["Control"].setPoint(-2, (tUnits.size + 2) * pButton.to)
        end

	if(pButton.limit < 11)
	then tUnits.frames["Control"].buttons["Browse"]:Hide()
	else tUnits.frames["Control"].buttons["Browse"]:Show()
	end
end

local tUnits = tMultiBar.addFrame("Units", -40, 72)
tUnits:Hide()

-- UNITS: ALLIANCE / HORDE  --
local tAlliance = tUnits.addFrame("Alliance", 0, -34, 32)
tAlliance:Show()

-- 1.  Determinate player faction
local faction = UnitFactionGroup("player")      -- "Alliance" ou "Horde"

-- 2.  Associate faction -> Banner
local FACTION_BANNERS = {
  Alliance = "inv_misc_tournaments_banner_human",
  Horde    = "inv_misc_tournaments_banner_orc",
}

-- 3.  Fallback
local bannerIcon = FACTION_BANNERS[faction] or "inv_misc_tournaments_banner_human"

-- 4.  Creating button
local btnAlliance = tAlliance.addButton("FactionBanner", 0, 0, bannerIcon,
                                        MultiBot.L("tips.units.alliance"))  -- ou units.horde si tu ajoutes le tooltip
btnAlliance:doShow()

-- Callbacks
btnAlliance.doRight = function() SendChatMessage(".playerbot bot remove *", "SAY") end
btnAlliance.doLeft  = function() SendChatMessage(".playerbot bot add *",    "SAY") end

-- UNITS:CONTROL --
local tControl = tUnits.addFrame("Control", -2, 0)
tControl:Show()

--  We call the function after tControl creation
MultiBot.BuildFilterUI(tControl)

--  Function call
MultiBot.BuildRosterUI(tControl)

-- UNITS:BROWSE --

-- PVP STATS --
local btnPvpStats = tControl.addButton("PvPStats", 0, 60, "Ability_Parry", MultiBot.L("tips.units.pvpstatsmaster")).setEnable()

local btnPvpWhisper = tControl.addButton("PvPStatsWhisper", 31, 60, "inv_Mask_04", MultiBot.L("tips.units.pvpstatstobot"))
local btnPvpParty   = tControl.addButton("PvPStatsParty",   61, 60, "achievement_reputation_08", MultiBot.L("tips.units.pvpstatstoparty"))
local btnPvpRaid    = tControl.addButton("PvPStatsRaid",    91, 60, "achievement_pvp_o_10",  MultiBot.L("tips.units.pvpstatstoraid"))
btnPvpWhisper:doHide()
btnPvpParty:doHide()
btnPvpRaid:doHide()

local function MB_ShowPvpFrame()
  if MultiBotPVPFrame and MultiBotPVPFrame.Show then
    MultiBotPVPFrame:Show()
  end
end

btnPvpStats.doLeft = function()
  if btnPvpWhisper:IsShown() then
    btnPvpWhisper:doHide()
    btnPvpParty:doHide()
    btnPvpRaid:doHide()
  else
    btnPvpWhisper:doShow()
    btnPvpParty:doShow()
    btnPvpRaid:doShow()
  end
end

btnPvpWhisper.doLeft = function()
  local bot = UnitName("target")
  if not bot or not UnitIsPlayer("target") then
    UIErrorsFrame:AddMessage("Sélectionne un bot (cible) d'abord.", 1, 0.2, 0.2, 1)
    return
  end
  SendChatMessage("pvp stats", "WHISPER", nil, bot)
  MB_ShowPvpFrame()
end

btnPvpParty.doLeft = function()
  if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
    UIErrorsFrame:AddMessage("Tu n'es pas en groupe.", 1, 0.2, 0.2, 1)
    return
  end
  SendChatMessage("pvp stats", "PARTY")
  MB_ShowPvpFrame()
end

btnPvpRaid.doLeft = function()
  if GetNumRaidMembers() == 0 then
    UIErrorsFrame:AddMessage("Tu n'es pas en raid.", 1, 0.2, 0.2, 1)
    return
  end
  SendChatMessage("pvp stats", "RAID")
  MB_ShowPvpFrame()
end

-- COMMANDS FOR ALL BOTS --
-- Main button under PvP Stats that opens a global commands submenu.
local btnAllBots = tControl.addButton("AllBotsCommands", 0, 90,
	"Temp",
	MultiBot.L("tips.allbots.commandsallbots"))

btnAllBots.doLeft = function(pButton)
	local menu = tControl.frames and tControl.frames["AllBotsCommandsMenu"]
	if not menu then
		return
	end

	if menu:IsShown() then
		menu:Hide()
	else
		menu:Show()
	end
end

-- Vertical submenu displayed above the main button.
local tAllBotsMenu = tControl.addFrame("AllBotsCommandsMenu", -30, 92, 32, 64)
tAllBotsMenu:Hide()

-- Button: maintenance for all bots.
tAllBotsMenu.addButton("MaintenanceAllBots", 0, 34,
	"achievement_halloween_smiley_01",
	MultiBot.L("tips.allbots.maintenanceallbots"))
.doLeft = function(pButton)
	if MultiBot.MaintenanceAllBots then
		MultiBot.MaintenanceAllBots()
	end
end

-- Button: sell all gray items for all bots (s *).
tAllBotsMenu.addButton("SellAllBotsGrey", 0, 0,
	"inv_misc_coin_18",
	MultiBot.L("tips.allbots.sellallvendor"))
.doLeft = function(pButton)
	if MultiBot.SellAllBots then
		MultiBot.SellAllBots("s *")
	end
end

local tButton = tControl.addButton("Invite", 0, 120, "Interface\\AddOns\\MultiBot\\Icons\\invite.blp", MultiBot.L("tips.units.invite")).setEnable()
tButton.doRight = function(pButton)
    if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then return end
    MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
    MultiBot.timer.invite.needs  = #MultiBot.index[MultiBot.timer.invite.roster]
    MultiBot.timer.invite.index  = 1
    MultiBot.auto.invite = true
    SendChatMessage(MultiBot.L("info.starting"), "SAY")
end

tButton.doLeft = function(pButton)
	if(pButton.state) then MultiBot.ShowHideSwitch(pButton.parent.frames["Invite"]) end
end

local tInvite = tControl.addFrame("Invite", -30, 122)
tInvite:Hide()

tInvite.addButton("Party+5", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_party_5.blp", MultiBot.L("tips.units.inviteParty5"))
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.L("info.wait"), "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = MultiBot.IF(tRaid > 0, 5 - tRaid, MultiBot.IF(tParty > 0, 4 - tParty, 4))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.L("info.starting"), "SAY")
end

tInvite.addButton("Raid+10", 56, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_10.blp", MultiBot.L("tips.units.inviteRaid10"))
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.L("info.wait"), "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = 10 - MultiBot.IF(tRaid > 0, tRaid, MultiBot.IF(tParty > 0, tParty + 1, 1))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.L("info.starting"), "SAY")
end

tInvite.addButton("Raid+25", 82, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_25.blp", MultiBot.L("tips.units.inviteRaid25"))
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.L("info.wait"), "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = 25 - MultiBot.IF(tRaid > 0, tRaid, MultiBot.IF(tParty > 0, tParty + 1, 1))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.L("info.starting"), "SAY")
end

tInvite.addButton("Raid+40", 108, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_40.blp", MultiBot.L("tips.units.inviteRaid40"))
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.L("info.wait"), "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = 40 - MultiBot.IF(tRaid > 0, tRaid, MultiBot.IF(tParty > 0, tParty + 1, 1))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.L("info.starting"), "SAY")
end

tControl.addButton("Browse", 0, 150, "Interface\\AddOns\\MultiBot\\Icons\\browse.blp", MultiBot.L("tips.units.browse"))
.doLeft = function(pButton)
  local tMaster = MultiBot.frames.MultiBar.buttons.Units
  local tUnits  = tMaster.parent.frames.Units

  -- Recalcule la table source EXACTEMENT comme dans Units.doLeft
  local function merge_lists(a, b)
    local res, seen = {}, {}
    if a then for i = 1, #a do local n = a[i]; if n and not seen[n] then seen[n] = true; table.insert(res, n) end end end
    if b then for i = 1, #b do local n = b[i]; if n and not seen[n] then seen[n] = true; table.insert(res, n) end end end
    return res
  end

  local tTable
  if tMaster.roster == "players" then
    if tMaster.filter ~= "none" then
      local byClassPlayers = MultiBot.index.classes.players[tMaster.filter]
      local byClassActives = MultiBot.index.classes.actives[tMaster.filter]
      tTable = merge_lists(byClassPlayers, byClassActives)
    else
      tTable = merge_lists(MultiBot.index.players, MultiBot.index.actives)
    end
  else
    if tMaster.filter ~= "none" then
      tTable = MultiBot.index.classes[tMaster.roster][tMaster.filter]
    else
      tTable = MultiBot.index[tMaster.roster]
    end
  end

  local total    = tTable and #tTable or 0
  if total == 0 then return end

  -- Calcule la page suivante (10 par page), avec wrap
  local pageSize = 10
  local from     = (tMaster.to or pageSize) + 1
  local to       = from + pageSize - 1
  if from > total then
    from, to = 1, math.min(pageSize, total)
  end
  if to > total then to = total end

  -- Cache l’ancienne page en étant tolérant aux boutons/frames manquants
  for i = tMaster.from or 1, tMaster.to or 0 do
    local name  = tTable[i]
    local btn   = name and tUnits.buttons[name]
    local frame = name and tUnits.frames[name]
    if frame then frame:Hide() end
    if btn   then btn:Hide()   end
  end

  -- Affiche la nouvelle page et re-positionne proprement
  local idx = 0
  for i = from, to do
    local name  = tTable[i]
    local btn   = name and tUnits.buttons[name]
    local frame = name and tUnits.frames[name]
    if btn then
      idx = idx + 1
      btn.setPoint(0, (tUnits.size + 2) * (idx - 1))
      if frame then frame.setPoint(-34, (tUnits.size + 2) * (idx - 1) + 2) end
      if frame and btn.state then frame:Show() end
      btn:Show()
    end
  end

  tMaster.from, tMaster.to = from, to
  tUnits.frames.Control.setPoint(-2, (tUnits.size + 2) * idx)
end

-- MAIN --
if MultiBot.InitializeMainUI then
	MultiBot.InitializeMainUI(tMultiBar)
end

--  Calling the function
MultiBot.BuildGmUI(tMultiBar)

-- RIGHT --
local tRight = tMultiBar.addFrame("Right", 34, 2, 32)
MultiBot.PromoteFrame(tRight)

-- QUESTS MENU --
-- flags par défaut
MultiBot._lastIncMode  = "WHISPER"
MultiBot._lastCompMode = "WHISPER"
MultiBot._lastAllMode       = "WHISPER"
MultiBot._awaitingQuestsAll = false
MultiBot._buildingAllQuests = false
MultiBot._blockOtherQuests = false
-- MultiBot.BotQuestsAll       = MultiBot.BotQuestsAll or {}

-- QUESTS / GAMEOBJECTS UI --
if MultiBot.InitializeQuestsMenu then
    MultiBot.InitializeQuestsMenu(tRight)
end
-- END QUESTS / GAMEOBJECTS UI --

-- GROUP ACTIONS --
if MultiBot.InitializeGroupActionsUI then
	MultiBot.InitializeGroupActionsUI(tRight)
end

-- INVENTORY --

MultiBot.InitializeInventoryFrame()

-- STATS --

MultiBot.stats = MultiBot.newFrame(MultiBot, -60, 560, 32)
MultiBot.stats:SetMovable(true)
MultiBot.stats:Hide()

MultiBot.stats.movButton("Move", 0, -80, 160, MultiBot.L("tips.move.stats"))

MultiBot.addStats(MultiBot.stats, "party1", 0,    0, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party2", 0,  -60, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party3", 0, -120, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party4", 0, -180, 32, 192, 96)

-- ITEMUS ACE3 --
MultiBot.InitializeItemusFrame()

-- ICONOS ACE3 --
MultiBot.InitializeIconosFrame()

-- SPELLBOOK --

MultiBot.InitializeSpellBookFrame()

-- REWARD --
if MultiBot.InitializeRewardFrame then
	MultiBot.InitializeRewardFrame()
end

-- TALENT AND GLYPHS FRAME --

if MultiBot.InitializeTalentFrameModule then
    MultiBot.InitializeTalentFrameModule()
end

-- RTSC --

local tRTSC = tMultiBar.addFrame("RTSC", -2, -34, 32).doHide()

local tButton = tRTSC.addButton("RTSC", 0, 0, "ability_hunter_markedfordeath", MultiBot.L("tips.rtsc.master"), "SecureActionButtonTemplate").addMacro("type1", "/cast aedm")
tButton.doRight = function(pButton)
	MultiBot.ActionToGroup("co +rtsc,+guard,?")
	MultiBot.ActionToGroup("nc +rtsc,+guard,?")
end
tButton.doLeft = function(pButton)
	local tFrame = pButton.parent.frames["Selector"]
	tFrame.doReset(tFrame)
end

-- RTSC:STORAGE --

local tSelector = tRTSC.addFrame("Selector", 0, 2, 28)
tSelector.selector = ""

-- Exécute l'action sur la sélection => Modifié pour La PR (commit 78116fe)
tSelector.doExecute = function(pButton, pAction)
    if (pButton.parent.selector == "") then
        return MultiBot.ActionToGroup(pAction)
    end

    local selected = MultiBot.doSplit(pButton.parent.selector, " ")
    local others, groupIdx = {}, {}

    -- Séparer @groupN des autres tags (@tank/@melee/@rangeddps, etc.)
    for _, tag in ipairs(selected) do
        local n = string.match(tag, "^@group(%d+)$")
        if n then table.insert(groupIdx, tonumber(n)) else table.insert(others, tag) end
    end

    -- Envoyer pour les autres tags comme avant
    for _, tag in ipairs(others) do
        MultiBot.ActionToGroup(tag .. " " .. pAction)
        if pButton.parent.buttons[tag] then pButton.parent.buttons[tag].setDisable() end
    end

    -- Compresser @group en liste/plage : @group1-3,5
    if #groupIdx > 0 then
        table.sort(groupIdx)
        local parts, i = {}, 1
        while i <= #groupIdx do
            local a, j = groupIdx[i], i
            while j+1 <= #groupIdx and groupIdx[j+1] == groupIdx[j]+1 do j = j + 1 end
            local b = groupIdx[j]
            table.insert(parts, (a == b) and tostring(a) or (tostring(a).."-"..tostring(b)))
            i = j + 1
        end
        local prefix = "@group" .. table.concat(parts, ",")
        MultiBot.ActionToGroup(prefix .. " " .. pAction)
        for _, n in ipairs(groupIdx) do
            local key = "@group" .. tostring(n)
            if pButton.parent.buttons[key] then pButton.parent.buttons[key].setDisable() end
        end
    end

    pButton.parent.selector = ""
end

-- Ajoute un tag à la sélection
tSelector.doSelect = function(pButton, pSelector)
	if (pButton.parent.selector == "") then
		pButton.parent.selector = pSelector
	else
		pButton.parent.selector = pButton.parent.selector .. " " .. pSelector
	end
end

-- Réinitialise la sélection + désactive les boutons associés
tSelector.doReset = function(pFrame)
	if (pFrame.selector == "") then return end
	local tGroups = MultiBot.doSplit(pFrame.selector, " ")
	for _, tag in ipairs(tGroups) do
		pFrame.buttons[tag].setDisable()
	end
	pFrame.selector = ""
end

-- MACRO/RTSC pour un index donné
local function createStoragePair(n, x)
	local macroName = "MACRO" .. n
	local rtscName  = "RTSC"  .. n
	local icon      = "achievement_bg_winwsg_3-0"

	-- Bouton MACROn (visible et disabled au départ)
	tSelector
		.addButton(macroName, x, 0, icon, MultiBot.L("tips.rtsc.macro"), "SecureActionButtonTemplate")
		.addMacro("type1", "/cast aedm")
		.setDisable()
		.doLeft = function(pButton)
			MultiBot.ActionToGroup("rtsc save " .. n)
			pButton.parent.buttons[rtscName].doShow()
			pButton.doHide()
		end

	-- Bouton RTSCn (caché au départ)
	local tButton = tSelector
		.addButton(rtscName, x, 0, icon, MultiBot.L("tips.rtsc.spot"), "SecureActionButtonTemplate")
		.doHide()

	tButton.doRight = function(pButton)
		MultiBot.ActionToGroup("rtsc unsave " .. n)
		pButton.parent.buttons[macroName].doShow()
		pButton.doHide()
	end

	tButton.doLeft = function(pButton)
		pButton.parent.doExecute(pButton, "rtsc go " .. n)
	end
end

-- Recréation des paires 9 à 1
for n = 9, 1, -1 do
	local x = -304 + 30 * n
	createStoragePair(n, x)
end

-- RTSC:SELECTOR --

-- Création d'un bouton RTSC standard (@groupX, @tank/@dps/@healer/@melee/@ranged)
local function createRTSCButton(tSelector, tag, x, icon, tip, hidden, disabled)
    local b = tSelector
        .addButton(tag, x, 0, icon, tip, "SecureActionButtonTemplate")
        .addMacro("type1", "/cast aedm")

    if hidden   then b.doHide()     end
    if disabled then b.setDisable() end

    b.doRight = function(pButton)
        MultiBot.ActionToGroup(tag .. " rtsc select")
        pButton.parent.doSelect(pButton, tag)
        pButton.setEnable()
    end

    b.doLeft = function(pButton)
        MultiBot.ActionToGroup(tag .. " rtsc select")
        pButton.parent.doReset(pButton.parent)
    end

    return b
end

-- Boutons groupes (cachés et désactivés au départ)
local groupButtons = {
    { "@group1",  30, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group1.blp", MultiBot.L("tips.rtsc.group1"),  true,  true },
    { "@group2",  60, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group2.blp", MultiBot.L("tips.rtsc.group2"),  true,  true },
    { "@group3",  90, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group3.blp", MultiBot.L("tips.rtsc.group3"),  true,  true },
    { "@group4", 120, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group4.blp", MultiBot.L("tips.rtsc.group4"),  true,  true },
    { "@group5", 150, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group5.blp", MultiBot.L("tips.rtsc.group5"),  true,  true },
}

-- Boutons rôles (visibles + désactivés au départ)
local roleButtons = {
    { "@tank",   30, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_tank.blp",   MultiBot.L("tips.rtsc.tank"),   false, true },
    { "@dps",    60, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_dps.blp",    MultiBot.L("tips.rtsc.dps"),    false, true },
    { "@healer", 90, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_healer.blp", MultiBot.L("tips.rtsc.healer"), false, true },
    { "@melee", 120, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_melee.blp",  MultiBot.L("tips.rtsc.melee"),  false, true },
    { "@ranged",150, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_ranged.blp", MultiBot.L("tips.rtsc.ranged"), false, true },
    { "@meleedps",  180, "Interface\\AddOns\\MultiBot\\Icons\\attack_melee.blp", MultiBot.L("tips.rtsc.meleedps"),  false, true },
    { "@rangeddps", 210, "Interface\\AddOns\\MultiBot\\Icons\\attack_range.blp", MultiBot.L("tips.rtsc.rangeddps"), false, true },
}

-- Création des boutons groupes
for _, def in ipairs(groupButtons) do
    createRTSCButton(tSelector, def[1], def[2], def[3], def[4], def[5], def[6])
end

-- Création des boutons rôles
for _, def in ipairs(roleButtons) do
    createRTSCButton(tSelector, def[1], def[2], def[3], def[4], def[5], def[6])
end

-- Bouton "@all"
do
    local tButton = tSelector
        .addButton("@all", 240, 0, "Interface\\AddOns\\MultiBot\\Icons\\rtsc.blp", MultiBot.L("tips.rtsc.all"), "SecureActionButtonTemplate")
        .addMacro("type1", "/cast aedm")

    tButton.doRight = function(pButton)
        MultiBot.ActionToGroup("rtsc select")
        pButton.parent.doReset(pButton.parent)
    end

    tButton.doLeft = function(pButton)
        MultiBot.ActionToGroup("rtsc select")
        pButton.parent.doReset(pButton.parent)
    end
end

-- Bouton Browse (toggle groupes <-> rôles)
do
    local tButton = tSelector.addButton("Browse", 270, 0, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_browse.blp", MultiBot.L("tips.rtsc.browse"))

    tButton.doRight = function(pButton)
        MultiBot.ActionToGroup("rtsc cancel")
        pButton.parent.doReset(pButton.parent)
    end

    tButton.doLeft = function(pButton)
        local tFrame = pButton.parent

        -- Listes pour éviter la répétition
        local roles  = { "@dps", "@tank", "@melee", "@healer", "@ranged" }
        local groups = { "@group1", "@group2", "@group3", "@group4", "@group5" }

        if (pButton.state) then
            -- affichage des rôles
            for _, tag in ipairs(roles)  do tFrame.buttons[tag].doShow() end
            for _, tag in ipairs(groups) do tFrame.buttons[tag].doHide() end
            pButton.state = false
        else
            -- affichage des groupes, on masque les rôles
            for _, tag in ipairs(roles)  do tFrame.buttons[tag].doHide() end
            for _, tag in ipairs(groups) do tFrame.buttons[tag].doShow() end
            pButton.state = true
        end
    end
end

-- HUNTER QUICK FRAME MOVED TO UI\MultiBotHunterQuickFrame.lua --

-- SHAMAN QUICK FRAME MOVED TO UI\MultiBotShamanQuickFrame.lua --

-- FINISH --

MultiBot.state = true
print("MultiBot")