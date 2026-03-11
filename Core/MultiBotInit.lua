-- Minimap config is resolved through MultiBot.GetMinimapConfig().

local MB_INVENTORY_LABEL = INVENTORY_TOOLTIP or BAGSLOT or "Inventory"
local MB_PAGE_DEFAULT = string.format("%d/%d", 0, 0)
local MB_TAB_TITLE_DEFAULT = UNKNOWN or ""

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

--  UI ATTACK
function MultiBot.BuildAttackUI(tLeft)

  -- 1. Table
  local ATTACK_BUTTONS = {
    { name="Attack",  icon="Interface\\AddOns\\MultiBot\\Icons\\attack.blp",         cmd="do attack my target",        tip="attack" },
    { name="Ranged",  icon="Interface\\AddOns\\MultiBot\\Icons\\attack_ranged.blp",  cmd="@ranged do attack my target",tip="ranged" },
    { name="Melee",   icon="Interface\\AddOns\\MultiBot\\Icons\\attack_melee.blp",   cmd="@melee do attack my target", tip="melee"  },
    { name="Healer",  icon="Interface\\AddOns\\MultiBot\\Icons\\attack_healer.blp",  cmd="@healer do attack my target",tip="healer" },
    { name="Dps",     icon="Interface\\AddOns\\MultiBot\\Icons\\attack_dps.blp",     cmd="@dps do attack my target",   tip="dps"    },
    { name="Tank",    icon="Interface\\AddOns\\MultiBot\\Icons\\attack_tank.blp",    cmd="@tank do attack my target",  tip="tank"   },
  }

  -- 2. Helper
  local function AddAttackButton(frame, info, index, cellH)
    local btn = frame.addButton(info.name,
                                0,                          -- x
                                (index-1)*cellH,            -- y
                                info.icon,
                                MultiBot.L("tips.attack." .. info.tip))

    -- Left Click shoot the command only if target exist
    btn.doLeft  = function()
      if MultiBot.isTarget() then
        MultiBot.ActionToGroup(info.cmd)
      end
    end

    -- Right click : select as default
    btn.doRight = function(b)
      MultiBot.SelectToGroupButtonWithTarget(b.parent.parent, "Attack", b.texture, info.cmd)
    end
  end

  -- 3. Main Button
  local mainBtn = tLeft.addButton("Attack", -136, 0,
                                  "Interface\\AddOns\\MultiBot\\Icons\\attack.blp",
                                  MultiBot.L("tips.attack.master"))

  mainBtn.doLeft  = function() if MultiBot.isTarget() then MultiBot.ActionToGroup("do attack my target") end end
  mainBtn.doRight = function(b) MultiBot.ShowHideSwitch(b.parent.frames["Attack"]) end

  -- 4. Internal Frame with Buttons
  local tAttack = tLeft.addFrame("Attack", -138, 34)
  tAttack:Hide()

  local CELL_H = 30
  for idx, data in ipairs(ATTACK_BUTTONS) do
    AddAttackButton(tAttack, data, idx, CELL_H)
  end
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

--  UI FLEE --
function MultiBot.BuildFleeUI(tLeft)

  -- 1. Table
  local FLEE_BUTTONS = {
    -- label          icon                                                            cmd / taget          tip-key (MultiBot.L("tips.flee." .. <key>))
    { name="Flee",    icon="Interface\\AddOns\\MultiBot\\Icons\\flee.blp",            cmd="flee",          tip="flee",     scope="group"  },
    { name="Ranged",  icon="Interface\\AddOns\\MultiBot\\Icons\\flee_ranged.blp",     cmd="@ranged flee",  tip="ranged",   scope="group"  },
    { name="Melee",   icon="Interface\\AddOns\\MultiBot\\Icons\\flee_melee.blp",      cmd="@melee flee",   tip="melee",    scope="group"  },
    { name="Healer",  icon="Interface\\AddOns\\MultiBot\\Icons\\flee_healer.blp",     cmd="@healer flee",  tip="healer",   scope="group"  },
    { name="Dps",     icon="Interface\\AddOns\\MultiBot\\Icons\\flee_dps.blp",        cmd="@dps flee",     tip="dps",      scope="group"  },
    { name="Tank",    icon="Interface\\AddOns\\MultiBot\\Icons\\flee_tank.blp",       cmd="@tank flee",    tip="tank",     scope="group"  },
    { name="Target",  icon="Interface\\AddOns\\MultiBot\\Icons\\flee_target.blp",     cmd="flee",          tip="target",   scope="target" },
  }

  -- 2. Helper to create vertival buttons
  local function AddFleeButton(frame, info, index, cellH)
    local btn = frame.addButton(info.name,
                                0,                           -- x
                                (index-1)*cellH,             -- y
                                info.icon,
                                MultiBot.L("tips.flee." .. info.tip))

    if info.scope == "target" then
      -- Left click action, right click action
      btn.doLeft  = function() MultiBot.ActionToTarget(info.cmd) end
      btn.doRight = function(b) MultiBot.SelectToTargetButton(b.parent.parent,"Flee",b.texture,info.cmd) end
    else
      -- scope group/role
      btn.doLeft  = function() MultiBot.ActionToGroup(info.cmd) end
      btn.doRight = function(b) MultiBot.SelectToGroupButton(b.parent.parent,"Flee",b.texture,info.cmd) end
    end
  end

  -- 3. Maint Button
  local mainBtn = tLeft.addButton("Flee", -34, 0,
                                  "Interface\\AddOns\\MultiBot\\Icons\\flee.blp",
                                  MultiBot.L("tips.flee.master"))

  mainBtn.doLeft  = function() MultiBot.ActionToGroup("flee") end
  mainBtn.doRight = function(b) MultiBot.ShowHideSwitch(b.parent.frames["Flee"]) end

  -- 4. Internal Frame + vertical buttons
  local tFlee = tLeft.addFrame("Flee", -36, 34)
  tFlee:Hide()

  local CELL_H = 30   -- space between buttons
  for idx, data in ipairs(FLEE_BUTTONS) do
    AddFleeButton(tFlee, data, idx, CELL_H)
  end
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
  local COLS     = 1     -- One column
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
tLeft.addButton("Beast", -0, 0, "ability_mount_swiftredwindrider", MultiBot.L("tips.beast.master")).doHide()
.doLeft = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Beast"])
end

local tBeast = tLeft.addFrame("Beast", -2, 34)
tBeast:Hide()

tBeast.addButton("Release", 0, 0, "spell_nature_spiritwolf", MultiBot.L("tips.beast.release"))
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 2641")
end

tBeast.addButton("Revive", 0, 30, "ability_hunter_beastsoothe", MultiBot.L("tips.beast.revive"))
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 982")
end

tBeast.addButton("Heal", 0, 60, "ability_hunter_mendpet", MultiBot.L("tips.beast.heal"))
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 48990")
end

tBeast.addButton("Feed", 0, 90, "ability_hunter_beasttraining", MultiBot.L("tips.beast.feed"))
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 6991")
end

tBeast.addButton("Call", 0, 120, "ability_hunter_beastcall", MultiBot.L("tips.beast.call"))
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 883")
end

--  CREATOR --
local GENDER_BUTTONS = {
  { label = "Male",     gender = "male",    icon = "Interface\\Icons\\INV_Misc_Toy_02",        tip = MultiBot.L("tips.creator.gendermale")      },
  { label = "Femelle",  gender = "female",  icon = "Interface\\Icons\\INV_Misc_Toy_04",        tip = MultiBot.L("tips.creator.genderfemale")    },
  { label = "Aléatoire",gender = nil,       icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", tip = MultiBot.L("tips.creator.genderrandom")    },
}

local CLASS_BUTTONS = {
  { name = "Warrior",     y =   0, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_warrior.blp",     cmd = "warrior"     },
  { name = "Warlock",     y =  30, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_warlock.blp",     cmd = "warlock"     },
  { name = "Shaman",      y =  60, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_shaman.blp",      cmd = "shaman"      },
  { name = "Rogue",       y =  90, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_rogue.blp",       cmd = "rogue"       },
  { name = "Priest",      y = 120, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_priest.blp",      cmd = "priest"      },
  { name = "Paladin",     y = 150, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_paladin.blp",     cmd = "paladin"     },
  { name = "Mage",        y = 180, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_mage.blp",        cmd = "mage"        },
  { name = "Hunter",      y = 210, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_hunter.blp",      cmd = "hunter"      },
  { name = "Druid",       y = 240, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_druid.blp",       cmd = "druid"       },
  { name = "DeathKnight", y = 270, icon = "Interface\\AddOns\\MultiBot\\Icons\\addclass_deathknight.blp", cmd = "dk"          }
}

local function AddClassButton(frame, info)
  -- 1. Main class button
  local classBtn = frame.addButton(info.name, 0, info.y, info.icon,
                                   MultiBot.L("tips.creator." .. string.lower(info.name)))

  -- 2. Sub buttons (Male / Female / Random)
  classBtn.genderButtons = {}
  local xOffset = 30
  local step    = 30

  for idx, g in ipairs(GENDER_BUTTONS) do
    local gBtn = frame.addButton(g.label,
                                 xOffset + (idx-1)*step,
                                 info.y,
                                 g.icon,
                                 g.tip)

    gBtn:Hide()                         -- hided at start

    gBtn.doLeft = function()
      MultiBot.AddClassToTarget(info.cmd, g.gender)   -- Send command
    end

    table.insert(classBtn.genderButtons, gBtn)
  end

  -- 3. When we click in class button => toggle the 3 gender buttons
  classBtn.doLeft = function(btn)
    local show = not btn.genderButtons[1]:IsShown()

    -- Hide those of the other class to keep display clean
    for _, other in ipairs(frame.buttons or {}) do
      if other ~= btn and other.genderButtons then
        for _, b in ipairs(other.genderButtons) do b:Hide() end
      end
    end

    -- Display / hide buttons from the clicked class
    for _, b in ipairs(btn.genderButtons) do
      if show then b:Show() else b:Hide() end
    end
  end

  -- We keep main buttons for the global toggle
  frame.buttons = frame.buttons or {}
  table.insert(frame.buttons, classBtn)
end

--  Creator
tLeft.addButton("Creator", -0, 0, "inv_helmet_145a", MultiBot.L("tips.creator.master"))
  .doLeft = function(btn)
    MultiBot.ShowHideSwitch(btn.parent.frames["Creator"])
    MultiBot.frames["MultiBar"].frames["Units"]:Hide()
  end

local tCreator = tLeft.addFrame("Creator", -2, 34)
tCreator:Hide()
-- hook OnHide to clos sub buttons
tCreator:HookScript("OnHide", function(self)
  -- self.buttons content all main buttons
  if self.buttons then
    for _, btn in ipairs(self.buttons) do
      if btn.genderButtons then
        for _, gBtn in ipairs(btn.genderButtons) do gBtn:Hide() end
      end
    end
  end
end)

for _, data in ipairs(CLASS_BUTTONS) do
  AddClassButton(tCreator, data)
end

--  Inspect
tCreator.addButton("Inspect", 0, 300, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", MultiBot.L("tips.creator.inspect"))
  .doLeft = function()
    if UnitExists("target") and UnitIsPlayer("target") then
      InspectUnit("target")
    else
      SendChatMessage(MultiBot.L("tips.creator.notarget"), "SAY")
    end
  end

-- Button Init
local tButton = tCreator.addButton("Init", 0, 330, "inv_misc_enggizmos_27", MultiBot.L("tips.creator.init"))

tButton.doRight = function()
  local function Iterate(unitPrefix, num)
    for i = 1, num do
      local name = UnitName(unitPrefix .. i)
      if name and name ~= UnitName("player") then
        if MultiBot.isRoster("players", name) then
          SendChatMessage(MultiBot.doReplace(MultiBot.L("info.player"), "NAME", name), "SAY")
        elseif MultiBot.isRoster("members", name) then
          SendChatMessage(MultiBot.doReplace(MultiBot.L("info.member"), "NAME", name), "SAY")
        else
          MultiBot.InitAuto(name)
        end
      end
    end
  end

  if IsInRaid() then
    Iterate("raid", GetNumGroupMembers())
  elseif IsInGroup() then
    Iterate("party", GetNumSubgroupMembers())
  else
    SendChatMessage(MultiBot.L("info.group"), "SAY")
  end
end

tButton.doLeft = function()
  if UnitExists("target") and UnitIsPlayer("target") then
    local name = UnitName("target")
    if MultiBot.isRoster("players", name) then
      SendChatMessage(MultiBot.L("info.players"), "SAY")
    elseif MultiBot.isRoster("members", name) then
      SendChatMessage(MultiBot.L("info.members"), "SAY")
    else
      MultiBot.InitAuto(name)
    end
  else
    SendChatMessage(MultiBot.L("info.target"), "SAY")
  end
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

    -- Filet de sécurité : si on veut 'players' mais l'index est vide, reconstruit ou redemande la liste
    if oRoster == "players" or pButton.roster == "players" then
      if not (MultiBot.index.players and table.getn(MultiBot.index.players) > 0) then
        if MultiBot.RebuildPlayersIndexFromButtons then MultiBot.RebuildPlayersIndexFromButtons() end
        if not (MultiBot.index.players and table.getn(MultiBot.index.players) > 0) then
          -- toujours vide : on (re)demande la liste une fois
          SendChatMessage(".playerbot bot list", "SAY")
        end
      end
    end

    -- Construction de la table source selon roster/filtre
    if pButton.roster == "players" then
      -- On fusionne players ∪ actives pour que les bots déjà groupés apparaissent aussi
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
    MultiBot.dprint("Units.tTable.size", tTable and table.getn(tTable) or 0) -- DEBUG
        -- Fin Construction de la table source selon roster/filtre

        local tButton = nil
        local tFrame = nil
        local tIndex = 0

        -- Certains favoris peuvent être chargés avant que leurs boutons ne soient créés
        -- (par exemple juste après un login, avant le retour de `.playerbot bot list`).
        -- On filtre donc la liste à afficher pour ne conserver que les entrées disposant
        -- d'un bouton, afin d'éviter les erreurs Lua tout en laissant la vue se remplir
        -- dès que les données arrivent.
        --
        local tDisplay = {}
        if tTable ~= nil then
          for i = 1, table.getn(tTable) do
            local name = tTable[i]
            if name ~= nil and tUnits.buttons[name] ~= nil then
              table.insert(tDisplay, name)
            else
              MultiBot.dprint("Units.skip", name or "<nil>", "(bouton manquant)")
            end
          end
        end

        pButton.limit = table.getn(tDisplay)

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

-- UNITS:FILTER REFACTORED --
function MultiBot.BuildFilterUI(tControl)
  -- 1. Main button
  local rootBtn = tControl.addButton("Filter", 0, 0,
                                     "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp",
                                     MultiBot.L("tips.units.filter"))

  -- Left CLick : Show/mask sub frame Right Click : reset filter
  rootBtn.doLeft  = function(b) MultiBot.ShowHideSwitch(b.parent.frames["Filter"]) end
  rootBtn.doRight = function(b)
    local unitsBtn = MultiBot.frames.MultiBar.buttons.Units
    MultiBot.Select(b.parent, "Filter",
                    "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp")
    unitsBtn.doLeft(unitsBtn, nil, "none")
  end

  -- 2. Frame + Data Table
  local tFilter = tControl.addFrame("Filter", -30, 2) ; tFilter:Hide()

  local FILTERS = {
    { key="DeathKnight", icon="filter_deathknight" },
    { key="Druid",       icon="filter_druid"       },
    { key="Hunter",      icon="filter_hunter"      },
    { key="Mage",        icon="filter_mage"        },
    { key="Paladin",     icon="filter_paladin"     },
    { key="Priest",      icon="filter_priest"      },
    { key="Rogue",       icon="filter_rogue"       },
    { key="Shaman",      icon="filter_shaman"      },
    { key="Warlock",     icon="filter_warlock"     },
    { key="Warrior",     icon="filter_warrior"     },
    { key="none",        icon="filter_none"        },   -- « None » = reset
  }

  -- 3. Helper : create class filter button
  local function AddFilterButton(info, idx)
    local x = -26 * (idx - 1)                 -- même pas : -26, -52, …
    local texture = "Interface\\AddOns\\MultiBot\\Icons\\" .. info.icon .. ".blp"

    local btn = tFilter.addButton(info.key, x, 0, texture,
                                  MultiBot.L("tips.units." .. string.lower(info.key)))

    btn.doLeft = function(b)
      local unitsBtn = MultiBot.frames.MultiBar.buttons.Units
      MultiBot.Select(b.parent.parent, "Filter", b.texture)
      unitsBtn.doLeft(unitsBtn, nil, info.key)
    end
  end

  -- 4. Loop
  for i, data in ipairs(FILTERS) do
    AddFilterButton(data, i)
  end
end

--  We call the function after tControl creation
MultiBot.BuildFilterUI(tControl)

-- UNITS:ROSTER REFACTORED --
function MultiBot.BuildRosterUI(tControl)

  -- 1. Main Button
  local rootBtn = tControl.addButton("Roster", 0, 30,
                                     --"Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp",
									 "Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp",
                                     MultiBot.L("tips.units.roster"))

  -- Left Click = ouvre le menu, Right Click vas sur “Actives”
  rootBtn.doLeft = function(b)
    MultiBot.ShowHideSwitch(b.parent.frames.Roster)
  end

  -- Clic droit : aller directement sur "favorites"
  rootBtn.doRight = function(b)
    local unitsBtn = MultiBot.frames.MultiBar.buttons.Units
    MultiBot.Select(b.parent, "Roster",
      "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1")
    unitsBtn.doLeft(unitsBtn, "favorites")
  end

  -- 2. Frame and Config Table
  local tRoster = tControl.addFrame("Roster", -30, 32) ; tRoster:Hide()

  local ROSTER_MODES = {
    -- key          icon                   Button        tooltip-key
    { id="friends", icon="roster_friends", invite=true,  tip="friends" },
    { id="members", icon="roster_members", invite=true,  tip="members" },
    { id="players", icon="roster_players", invite=true,  tip="players" },
    { id="actives", icon="roster_actives", invite=false, tip="actives" },
    -- Favorites (per-character)
    { id="favorites", texture="Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1", invite=false, tip="favorites" },
  }

  -- 3. Helper bouton Roster
  local function AddRosterButton(cfg, idx)
    local x = -26 * (idx-1)
    -- local tex = "Interface\\AddOns\\MultiBot\\Icons\\" .. cfg.icon .. ".blp"
    -- Allow either an addon icon name (cfg.icon) or a direct texture path (cfg.texture)
    local tex = cfg.texture or ("Interface\\AddOns\\MultiBot\\Icons\\" .. cfg.icon .. ".blp")

    local btn = tRoster.addButton(cfg.id:gsub("^%l", string.upper), x, 0,
                                  tex, MultiBot.L("tips.units." .. cfg.tip))

    btn.doLeft = function(b)
      local unitsBtn = MultiBot.frames.MultiBar.buttons.Units
      MultiBot.Select(b.parent.parent, "Roster", b.texture)

      if cfg.invite then
        b.parent.parent.buttons.Invite.setEnable()
      else
        b.parent.parent.buttons.Invite.setDisable()
      end
      b.parent.parent.frames.Invite:Hide()

      unitsBtn.doLeft(unitsBtn, cfg.id)
    end
  end

  -- 4. Loop
  for i, cfg in ipairs(ROSTER_MODES) do
    AddRosterButton(cfg, i)
  end
end

--  Function call
MultiBot.BuildRosterUI(tControl)

-- Icic on choisit quelle roster sera affiché par défaut: "players, actives etc....)
TimerAfter(0.05, function()
  local unitsBtn = MultiBot.frames
                 and MultiBot.frames.MultiBar
                 and MultiBot.frames.MultiBar.buttons
                 and MultiBot.frames.MultiBar.buttons.Units

  if unitsBtn and tControl and tControl.buttons and tControl.buttons.Roster then
    local rosterBtn = tControl.buttons.Roster
    local tex = (rosterBtn and rosterBtn.texture) or "Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp"
    MultiBot.Select(tControl, "Roster", tex)
    unitsBtn.doLeft(unitsBtn, "players")
  end
end)

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
-- Bouton principal sous PvP Stats qui ouvre un sous-menu de commandes globales.
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

-- Sous-menu vertical qui s'ouvre au-dessus du bouton principal
local tAllBotsMenu = tControl.addFrame("AllBotsCommandsMenu", -30, 92, 32, 64)
tAllBotsMenu:Hide()

-- Bouton : Maintenance pour tous les bots
tAllBotsMenu.addButton("MaintenanceAllBots", 0, 34,
	"achievement_halloween_smiley_01",
	MultiBot.L("tips.allbots.maintenanceallbots"))
.doLeft = function(pButton)
	if MultiBot.MaintenanceAllBots then
		MultiBot.MaintenanceAllBots()
	end
end

-- Bouton : vendre tous les objets gris pour tous les bots (s *)
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
    MultiBot.timer.invite.needs  = table.getn(MultiBot.index[MultiBot.timer.invite.roster])
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
local tButton = tMultiBar.addButton("Main", 0, 0, "inv_gizmo_02", MultiBot.L("tips.main.master"))
tButton:RegisterForDrag("RightButton")
tButton:SetScript("OnDragStart", function()
	MultiBot.frames["MultiBar"]:StartMoving()
end)
tButton:SetScript("OnDragStop", function()
	MultiBot.frames["MultiBar"]:StopMovingOrSizing()
end)
tButton.doLeft = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Main"])
end

local tMain = tMultiBar.addFrame("Main", -2, 38)
tMain:Hide()

tMain.addButton("Coords", 0, 0, "inv_gizmo_03", MultiBot.L("tips.main.coords"))
.doLeft = function(pButton)
	MultiBot.frames["MultiBar"].setPoint(-262, 144)
	MultiBot.inventory.setPoint(-700, -144)
	MultiBot.spellbook.setPoint(-802, 302)
	MultiBot.talent.setPoint(-104, -276)
	MultiBot.reward.setPoint(-754,  238)
	MultiBot.itemus.setPoint(-860, -144)
	MultiBot.iconos.setPoint(-860, -144)
	MultiBot.stats.setPoint(-60, 560)
end

tMain.addButton("Masters", 0, 34, "mail_gmicon", MultiBot.L("tips.main.masters")).setDisable()
.doLeft = function(pButton)
	if(MultiBot.GM == false) then return SendChatMessage(MultiBot.L("info.rights"), "SAY") end
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.doRepos("Right", 38)
		MultiBot.frames["MultiBar"].frames["Masters"]:Hide()
		MultiBot.frames["MultiBar"].buttons["Masters"]:Show()
	else
		MultiBot.doRepos("Right", -38)
		MultiBot.frames["MultiBar"].frames["Masters"]:Hide()
		MultiBot.frames["MultiBar"].buttons["Masters"]:Hide()
	end
end

tMain.addButton("RTSC", 0, 68, "ability_hunter_markedfordeath", MultiBot.L("tips.main.rtsc")).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y + 34)
		MultiBot.frames["MultiBar"].frames["RTSC"]:Show()
		MultiBot.ActionToGroup("rtsc")
	else
		MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y - 34)
		MultiBot.frames["MultiBar"].frames["RTSC"]:Hide()
		MultiBot.ActionToGroup("rtsc reset")
	end
end

tMain.addButton("Raidus", 0, 102, "inv_misc_head_dragon_01", MultiBot.L("tips.main.raidus")).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.raidus.setRaidus()
		MultiBot.raidus:Show()
	else
		MultiBot.raidus:Hide()
	end
end

tMain.addButton("Creator", 0, 136, "inv_helmet_145a", MultiBot.L("tips.main.creator")).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.doRepos("Tanker", -34)
		MultiBot.doRepos("Attack", -34)
		MultiBot.doRepos("Mode", -34)
		MultiBot.doRepos("Stay", -34)
		MultiBot.doRepos("Follow", -34)
		MultiBot.doRepos("ExpandStay", -34)
		MultiBot.doRepos("ExpandFollow", -34)
		MultiBot.doRepos("Flee", -34)
		MultiBot.doRepos("Format", -34)
		MultiBot.doRepos("Beast", -34)
		MultiBot.frames["MultiBar"].frames["Left"].frames["Creator"]:Hide()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Creator"]:Show()
	else
		MultiBot.doRepos("Tanker", 34)
		MultiBot.doRepos("Attack", 34)
		MultiBot.doRepos("Mode", 34)
		MultiBot.doRepos("Stay", 34)
		MultiBot.doRepos("Follow", 34)
		MultiBot.doRepos("ExpandStay", 34)
		MultiBot.doRepos("ExpandFollow", 34)
		MultiBot.doRepos("Flee", 34)
		MultiBot.doRepos("Format", 34)
		MultiBot.doRepos("Beast", 34)
		MultiBot.frames["MultiBar"].frames["Left"].frames["Creator"]:Hide()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Creator"]:Hide()
	end
end

tMain.addButton("Beast", 0, 170, "ability_mount_swiftredwindrider", MultiBot.L("tips.main.beast")).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.doRepos("Tanker", -34)
		MultiBot.doRepos("Attack", -34)
		MultiBot.doRepos("Mode", -34)
		MultiBot.doRepos("Stay", -34)
		MultiBot.doRepos("Follow", -34)
		MultiBot.doRepos("ExpandStay", -34)
		MultiBot.doRepos("ExpandFollow", -34)
		MultiBot.doRepos("Flee", -34)
		MultiBot.doRepos("Format", -34)
		MultiBot.frames["MultiBar"].frames["Left"].frames["Beast"]:Hide()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Beast"]:Show()
	else
		MultiBot.doRepos("Tanker", 34)
		MultiBot.doRepos("Attack", 34)
		MultiBot.doRepos("Mode", 34)
		MultiBot.doRepos("Stay", 34)
		MultiBot.doRepos("Follow", 34)
		MultiBot.doRepos("ExpandStay", 34)
		MultiBot.doRepos("ExpandFollow", 34)
		MultiBot.doRepos("Flee", 34)
		MultiBot.doRepos("Format", 34)
		MultiBot.frames["MultiBar"].frames["Left"].frames["Beast"]:Hide()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Beast"]:Hide()
	end
end

tMain.addButton("Expand", 0, 204, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.L("tips.main.expand")).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.doRepos("Tanker", -34)
		MultiBot.doRepos("Attack", -34)
		MultiBot.doRepos("Mode", -34)
		MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandFollow"]:Show()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandStay"]:Show()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Follow"]:Hide()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Stay"]:Hide()
	else
		MultiBot.doRepos("Tanker", 34)
		MultiBot.doRepos("Attack", 34)
		MultiBot.doRepos("Mode", 34)
		MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandFollow"]:Hide()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["ExpandStay"]:Hide()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Follow"]:Show()
		MultiBot.frames["MultiBar"].frames["Left"].buttons["Stay"]:Show()
	end
end

tMain.addButton("Release", 0, 238, "achievement_bg_xkills_avgraveyard", MultiBot.L("tips.main.release")).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.auto.release = true
	else
		MultiBot.auto.release = false
	end
end

tMain.addButton("Stats", 0, 272, "inv_scroll_08", MultiBot.L("tips.main.stats")).setDisable()
.doLeft = function(pButton)
	if(GetNumRaidMembers() > 0) then return SendChatMessage(MultiBot.L("info.stats"), "SAY") end
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.auto.stats = true
		for i = 1, GetNumPartyMembers() do SendChatMessage("stats", "WHISPER", nil, UnitName("party" .. i)) end
		MultiBot.stats:Show()
	else
		MultiBot.auto.stats = false
		for key, value in pairs(MultiBot.stats.frames) do value:Hide() end
		MultiBot.stats:Hide()
	end
end

local tButton = tMain.addButton("Reward", 0, 306, "Interface\\AddOns\\MultiBot\\Icons\\reward.blp", MultiBot.L("tips.main.reward")).setDisable()
tButton.doRight = function(pButton)
	if(table.getn(MultiBot.reward.rewards) > 0 and table.getn(MultiBot.reward.units) > 0) then MultiBot.reward:Show() end
end
tButton.doLeft = function(pButton)
	MultiBot.reward.state = MultiBot.OnOffSwitch(pButton)
end

tMain.addButton("Reset", 0, 340, "inv_misc_tournaments_symbol_gnome", MultiBot.L("tips.main.reset"))
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("reset botAI")
end

tMain.addButton("Actions", 0, 374, "inv_helmet_02", MultiBot.L("tips.main.action"))
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("reset")
end

-- [AJOUT] Bouton Options (ouvre/ferme le panneau des sliders)
local tBtnOptions = tMain.addButton("Options", 0, 404, "inv_misc_gear_02", MultiBot.L("tips.main.options"))
tBtnOptions._active = false

-- Grisé par défaut (alpha 0.4 + désaturation)
do
  local f = tBtnOptions.frame or tBtnOptions
  if f and f.SetAlpha then f:SetAlpha(0.4) end
  if f and f.GetRegions then
    local tex = f:GetRegions()
    if tex and tex.SetDesaturated then tex:SetDesaturated(true) end
  end
end

tBtnOptions.doLeft = function(pButton)
  -- Toggle panneau d'options
  local opened = false
  if MultiBot.ToggleOptionsPanel then
    opened = MultiBot.ToggleOptionsPanel()
  end

  pButton._active = opened

  -- Visuel : dégrise si ouvert, re-grise si fermé
  local f = pButton.frame or pButton
  if f and f.SetAlpha then f:SetAlpha(opened and 1.0 or 0.4) end
  if f and f.GetRegions then
    local tex = f:GetRegions()
    if tex and tex.SetDesaturated then tex:SetDesaturated(not opened) end
  end
end

--  GAMEMASTER REFORGED --
function MultiBot.BuildGmUI(tMultiBar)
  -- 1. Main Button in Multibar
  local mainBtn = tMultiBar.addButton("Masters", 38, 0, "mail_gmicon",
                                      MultiBot.L("tips.game.master"))
  mainBtn:doHide()                                      -- masqué par défaut

  mainBtn.doLeft  = function(b) MultiBot.ShowHideSwitch(b.parent.frames["Masters"]) end
  mainBtn.doRight = function()  MultiBot.doSlash("/MultiBot", "")                   end

  -- 2. Frame "Masters" : contain the buttons
  local tMasters = tMultiBar.addFrame("Masters", 36, 38)
  tMasters:Hide()

  -- 3. Button NecroNet (toggle)
  local necroBtn = tMasters.addButton("NecroNet", 0, 0,
                                      "achievement_bg_xkills_avgraveyard",
                                      MultiBot.L("tips.game.necronet"))
  necroBtn:setDisable()

  necroBtn.doLeft = function(b)
    if b.state then          -- ON/OFF
      MultiBot.necronet.state = false
      for _, v in pairs(MultiBot.necronet.buttons) do v:Hide() end
      b:setDisable()
    else                     -- OFF/ON
      MultiBot.necronet.cont = 0
      MultiBot.necronet.area = 0
      MultiBot.necronet.zone = 0
      MultiBot.necronet.state = true
      b:setEnable()
    end
  end

  -- 4. Sub-Frame "Portal" (Red / Green / Blue “memory”)
  local portalBtn = tMasters.addButton("Portal", 0, 34, "inv_box_02",
                                        MultiBot.L("tips.game.portal"))
  local tPortal   = tMasters.addFrame("Portal", 30, 36) ; tPortal:Hide()

  portalBtn.doLeft = function() MultiBot.ShowHideSwitch(tPortal) end

  -- Helper for portal
  local function AddMemoryGem(label, x, icon, tipKey)
    local gem = tPortal.addButton(label, x, 0, icon,
                                  MultiBot.doReplace(MultiBot.L("tips.game.memory"),
                                                      "ABOUT", MultiBot.L("info.location")))
    gem:setDisable()
    gem.goMap, gem.goX, gem.goY, gem.goZ = "",0,0,0

    -- Right click to update/delete
    gem.doRight = function(b)
      if not b.state then
        return SendChatMessage(MultiBot.L("info.itlocation"), "SAY")
      end
       b.tip = MultiBot.doReplace(MultiBot.L("tips.game.memory"), "ABOUT",
                                 MultiBot.L("info.location"))
      b:setDisable()
    end

    -- Left click to Save or teleport
    gem.doLeft = function(b)
      local player = MultiBot.getBot(UnitName("player"))
      player.waitFor = player.waitFor or ""

      if player.waitFor ~= "" then
        return SendChatMessage(MultiBot.L("info.saving"), "SAY")
      end

      if b.state then
        return SendChatMessage(".go xyz " ..
                               b.goX .. " " .. b.goY .. " " .. b.goZ ..
                               " " .. b.goMap, "SAY")
      end

      player.memory  = b
      player.waitFor = "COORDS"
      SendChatMessage(".gps", "SAY")
    end
  end

  -- Adding the 3 gems
  AddMemoryGem("Red",   0,  "inv_jewelcrafting_gem_16",
               MultiBot.L("tips.game.memory"))
  AddMemoryGem("Green", 30, "inv_jewelcrafting_gem_13",
               MultiBot.L("tips.game.memory"))
  AddMemoryGem("Blue",  60, "inv_jewelcrafting_gem_17",
               MultiBot.L("tips.game.memory"))

  -- 5. Shortcuts for : Itemus / Iconos / Summon / Appear
  local UTIL_BUTTONS = {
    { label="Itemus", y= 68, icon="inv_box_01",        tip=MultiBot.L("tips.game.itemus"),
      click=function()
        if MultiBot.ShowHideSwitch(MultiBot.itemus) then
          MultiBot.itemus.addItems()
        end
      end },

    { label="Iconos", y=102, icon="inv_mask_01",       tip=MultiBot.L("tips.game.iconos"),
      click=function()
        if MultiBot.ShowHideSwitch(MultiBot.iconos) then
          MultiBot.iconos.addIcons()
        end
      end },

    { label="Summon", y=136, icon="spell_holy_prayerofspirit", tip=MultiBot.L("tips.game.summon"),
      click=function() MultiBot.doDotWithTarget(".summon") end },

    { label="Appear", y=170, icon="spell_holy_divinespirit",   tip=MultiBot.L("tips.game.appear"),
      click=function() MultiBot.doDotWithTarget(".appear") end },
  }

  for _, b in ipairs(UTIL_BUTTONS) do
    tMasters.addButton(b.label, 0, b.y, b.icon, b.tip).doLeft = b.click
  end

  -- 6. DelSV Button
  StaticPopupDialogs["MULTIBOT_DELETE_SV"] = {
      text         = MultiBot.L("tips.game.delsvwarning"),
      button1      = YES,
      button2      = NO,
      OnAccept     = function()
          if MultiBot.ClearGlobalBotStore then
            MultiBot.ClearGlobalBotStore()
          elseif wipe then
            wipe(MultiBotGlobalSave)
          else
            for k in pairs(MultiBotGlobalSave) do MultiBotGlobalSave[k]=nil end
          end
          ReloadUI()
      end,
      timeout      = 0,   whileDead=true, hideOnEscape=true,
  }

  function MultiBot.ShowDeleteSVPrompt()
    if MultiBot.GM == false then
      SendChatMessage(MultiBot.L("info.rights"), "SAY")
      return
    end
    StaticPopup_Show("MULTIBOT_DELETE_SV")
  end

  tMasters.addButton("DelSV", 0, 204, "ability_golemstormbolt",
                     MultiBot.L("tips.game.delsv"), "ActionButtonTemplate")
    .doLeft = function() MultiBot.ShowDeleteSVPrompt() end

  MultiBot.RegisterCommandAliases("MULTIBOTDELSV", function()
    if MultiBot.ShowDeleteSVPrompt then
      MultiBot.ShowDeleteSVPrompt()
    end
  end, { "mbdelsv" })
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

-- HIDDEN TOOLTIP HELPERS --
local function ensureHiddenTooltip(name, parent)
    local tooltip = _G[name]
    if not tooltip then
        tooltip = CreateFrame("GameTooltip", name, parent or UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
    end

    return tooltip
end

local LocalizeQuestTooltip = ensureHiddenTooltip("MB_LocalizeQuestTooltip", UIParent)

local function GetLocalizedQuestName(questID)
    LocalizeQuestTooltip:ClearLines()
    -- builds hyperlink quest:<ID>
    LocalizeQuestTooltip:SetHyperlink("quest:"..questID)
    -- reads first tooltip line
    local textObj = _G["MB_LocalizeQuestTooltipTextLeft1"]
    return (textObj and textObj:GetText()) or tostring(questID)
end
-- END HIDDEN TOOLTIP --

local function getUniversalPromptAceGUI()
    if type(LibStub) ~= "table" then
        return nil
    end

    local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
    if ok and type(aceGUI) == "table" and type(aceGUI.Create) == "function" then
        return aceGUI
    end

    return nil
end

MultiBot.GetAceGUI = MultiBot.GetAceGUI or getUniversalPromptAceGUI

local function resolveAceGUI(missingDepMessage)
    local aceGUI = (MultiBot.GetAceGUI and MultiBot.GetAceGUI()) or (getUniversalPromptAceGUI and getUniversalPromptAceGUI())
    if not aceGUI and missingDepMessage then
        UIErrorsFrame:AddMessage(missingDepMessage, 1, 0.2, 0.2, 1)
    end

    return aceGUI
end

local function setAceWindowCloseToHide(window)
    if window and window.SetCallback then
        window:SetCallback("OnClose", function(widget)
            widget:Hide()
        end)
    end
end

local _aceEscapeIndex = 0
local function registerAceWindowEscapeClose(window, namePrefix)
    if not window or not window.frame or type(UISpecialFrames) ~= "table" then
        return
    end

    if window.__mbEscapeName then
        return
    end

    _aceEscapeIndex = _aceEscapeIndex + 1
    local safePrefix = tostring(namePrefix or "Popup"):gsub("[^%w_]", "")
    local frameName = string.format("MultiBotAce%s_%d", safePrefix, _aceEscapeIndex)

    window.__mbEscapeName = frameName
    _G[frameName] = window.frame

    for _, existing in ipairs(UISpecialFrames) do
        if existing == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function getUiProfileStore()
    local profile = MultiBot.db and MultiBot.db.profile
    if not profile then
        return nil
    end

    profile.ui = profile.ui or {}
    return profile.ui
end

local function bindAceWindowPosition(window, persistenceKey)
    if not window or not window.frame or not persistenceKey then
        return
    end

    local uiStore = getUiProfileStore()
    if not uiStore then
        return
    end

    uiStore.popupPositions = uiStore.popupPositions or {}
    local positions = uiStore.popupPositions
    local saved = positions[persistenceKey]
    if saved and saved.point then
        window.frame:ClearAllPoints()
        window.frame:SetPoint(saved.point, UIParent, saved.point, saved.x or 0, saved.y or 0)
    end

    if window.__mbPositionHooked then
        return
    end

    window.__mbPositionHooked = true
    window.frame:HookScript("OnDragStop", function(frame)
        local point, _, _, x, y = frame:GetPoint(1)
        if point then
            positions[persistenceKey] = { point = point, x = x or 0, y = y or 0 }
        end
    end)
end

local function createAceQuestPopupHost(title, width, height, missingDepMessage, persistenceKey)
    local aceGUI = resolveAceGUI(missingDepMessage or "AceGUI-3.0 is required")
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(title or "")
    window:SetWidth(width)
    window:SetHeight(height)
    window:EnableResize(false)
    window:SetLayout("Fill")
    window.frame:SetFrameStrata("DIALOG")
    setAceWindowCloseToHide(window)
    registerAceWindowEscapeClose(window, "QuestHost")
    bindAceWindowPosition(window, persistenceKey)
    window:Hide()

    local host = CreateFrame("Frame", nil, window.content)
    host:SetAllPoints(window.content)
    host.window = window

    host.Show = function(self)
        self.window:Show()
    end

    host.Hide = function(self)
        self.window:Hide()
    end

    host.IsShown = function(self)
        return self.window and self.window.frame and self.window.frame:IsShown()
    end

    return host
end

-- MAIN BUTTON --
local tButton = tRight.addButton("Quests Menu", 0, 0,
                                 "achievement_quests_completed_06",
                                 MultiBot.L("tips.quests.main"))
local tQuestMenu = tRight.addFrame("QuestMenu", -2, 64)
tQuestMenu:Hide()
tButton.doLeft  = function(p) MultiBot.ShowHideSwitch(p.parent.frames["QuestMenu"]) end
tButton.doRight = tButton.doLeft
-- END MAIN BUTTON --

-- BUTTON Accept * --
tQuestMenu.addButton("AcceptAll", 0, 30,
                     "inv_misc_note_02", MultiBot.L("tips.quests.accept"))
.doLeft = function() MultiBot.ActionToGroup("accept *") end
-- END BUTTON Accept * --

-- POP-UP Frame for Quests --
local tQuests = createAceQuestPopupHost(QUEST_LOG, 390, 470, "AceGUI-3.0 is required for MB_QuestPopup", "quest_popup")
assert(tQuests, "AceGUI-3.0 is required for MB_QuestPopup")

-- ScrollFrame + ScrollBar
local scrollFrame = CreateFrame("ScrollFrame", "MB_QuestScroll", tQuests, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -8)
scrollFrame:SetPoint("BOTTOMRIGHT", -26, 8)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetWidth(1)              -- largeur auto
scrollFrame:SetScrollChild(content)
-- END POP-UP Frame for “Quests” --

-- BUTTON Quests --
local tListBtn = tQuestMenu.addButton("Quests", 0, -30,
                                      "inv_misc_book_07", MultiBot.L("tips.quests.master"))
-- requis par MultiBotHandler
tRight.buttons["Quests"] = tListBtn

-- helpers
local function ClearContent()
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
end

local function MemberNamesOnQuest(questIndex)
    local names = {}
    if GetNumRaidMembers() > 0 then
        for n = 1, 40 do
            local unit = "raid"..n
            if UnitExists(unit) and IsUnitOnQuest(questIndex, unit) then
                local name = UnitName(unit)          -- ← récupère juste le nom
                if name then table.insert(names, name) end
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for n = 1, 4 do
            local unit = "party"..n
            if UnitExists(unit) and IsUnitOnQuest(questIndex, unit) then
                local name = UnitName(unit)
                if name then table.insert(names, name) end
            end
        end
    end
    return names
end

-- CLIC DROIT : génère et rafraichit la liste
tListBtn.doRight = function()
    ClearContent()

    local entries = GetNumQuestLogEntries()
    local lineHeight, y = 24, -4

    for i = 1, entries do
        local link  = GetQuestLink(i)
        local questID = tonumber(link and link:match("|Hquest:(%d+):"))
        local title, level, _, header, collapsed = GetQuestLogTitle(i)

        if collapsed == nil then                               -- entrée réelle
            local line = CreateFrame("Frame", nil, content)
            line:SetSize(300, lineHeight)
            line:SetPoint("TOPLEFT", 0, y)

            -- icône
            local icon = line:CreateTexture(nil, "ARTWORK")
            icon:SetTexture("Interface\\Icons\\inv_misc_note_01")
            icon:SetSize(20, 20)
            icon:SetPoint("LEFT")

            -- lien de quête en SimpleHTML
            local html = CreateFrame("SimpleHTML", nil, line)
            html:SetSize(260, 20)
            html:SetPoint("LEFT", 24, 0)
            html:SetFontObject("GameFontNormal")
            html:SetText(link:gsub("%[", "|cff00ff00["):gsub("%]", "]|r"))
            html:SetHyperlinksEnabled(true)

            -- Tooltip
            html:SetScript("OnHyperlinkEnter", function(self, linkData, fullLink)
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:SetHyperlink(fullLink)

                -- Ajoute les objectifs de la quête
                local numObj = GetNumQuestLeaderBoards(i)
                if numObj and numObj > 0 then
                    for k = 1, numObj do
                        local txtObj, objType, finished = GetQuestLogLeaderBoard(k, i)
                        if txtObj then
                            local r, g, b = finished and 0.5 or 1, finished and 0.5 or 1, finished and 0.5 or 1
                            GameTooltip:AddLine("• "..txtObj, r, g, b)
                        end
                    end
                end

                -- Liste des membres/bots sur la quête
                local members = MemberNamesOnQuest(i)
                if #members > 0 then
                    GameTooltip:AddLine(" ", 1, 1, 1)
                    GameTooltip:AddLine("Groupe :", 0.8, 0.8, 0.8)
                    for _, n in ipairs(members) do GameTooltip:AddLine("- "..n) end
                end

                GameTooltip:Show()
            end)
            html:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

            -- CLIC SUR LE LIEN DE LA QUETE
            html:SetScript("OnHyperlinkClick", function(self, linkData, link, button)
                if link:match("|Hquest:") then
                    local questIDClicked = tonumber(link:match("|Hquest:(%d+):"))
                    -- Retrouver l'index de la quête dans le journal
                    for idx = 1, GetNumQuestLogEntries() do
                        local qLink = GetQuestLink(idx)
                        if qLink and tonumber(qLink:match("|Hquest:(%d+):")) == questIDClicked then
                            SelectQuestLogEntry(idx)
                            if button == "RightButton" then
                                if GetNumRaidMembers() > 0 then
                                    SendChatMessage("drop "..qLink, "RAID")
                                elseif GetNumPartyMembers() > 0 then
                                    SendChatMessage("drop "..qLink, "PARTY")
                                end
                                SetAbandonQuest()
                                AbandonQuest()
                            else
                                QuestLogPushQuest()
                            end
                            break
                        end
                    end
                end
            end)

            y = y - lineHeight
        end
    end
    content:SetHeight(-y + 4)   -- hauteur totale des lignes
    scrollFrame:SetVerticalScroll(0)  -- remonter en haut
end

-- CLIC GAUCHE : show/hide la fenêtre
tListBtn.doLeft = function()
    if tQuests:IsShown() then
        tQuests:Hide()
    else
        tQuests:Show()
        tListBtn.doRight()
    end
end

-- END BUTTON QUESTS --

-- BUTTON QUESTS INCOMPLETED with sub buttons --
-- Table de stockage
MultiBot.BotQuestsIncompleted = {}  -- [botName] = { [questID]=questName, ... }

-- Popup Liste des quêtes du bot
local tBotPopup = createAceQuestPopupHost(MultiBot.L("tips.quests.incomplist"), 380, 420, "AceGUI-3.0 is required for MB_BotQuestPopup", "bot_quest_popup")
assert(tBotPopup, "AceGUI-3.0 is required for MB_BotQuestPopup")

local scroll = CreateFrame("ScrollFrame", "MB_BotQuestScroll", tBotPopup, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 10, -8)
scroll:SetPoint("BOTTOMRIGHT", -26, 8)

local contentBot = CreateFrame("Frame", nil, scroll)
contentBot:SetWidth(1)
scroll:SetScrollChild(contentBot)

MultiBot.tBotPopup = tBotPopup

local function ClearBotContent()
    for _, child in ipairs({ contentBot:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
end

-- AJOUT ON VIDE TOUT
tBotPopup:SetScript("OnHide", function()
    MultiBot.BotQuestsIncompleted = {}
    ClearBotContent()
end)
-- Fin de l’ajout

local function BuildBotQuestList(botName)
    ClearBotContent()
    local quests = MultiBot.BotQuestsIncompleted[botName] or {}
    local y = -4
    for id, name in pairs(quests) do
        local line = CreateFrame("Frame", nil, contentBot)
        line:SetSize(300, 24)
        line:SetPoint("TOPLEFT", 0, y)

        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20,20)
        icon:SetPoint("LEFT")

        local locName = GetLocalizedQuestName(id) or name
        local link = ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(id, locName)
        local html = CreateFrame("SimpleHTML", nil, line)
        html:SetSize(260, 20)
        html:SetPoint("LEFT", 24, 0)
        html:SetFontObject("GameFontNormal")
        html:SetText(link)
        html:SetHyperlinksEnabled(true)
        html:SetScript("OnHyperlinkEnter", function(self, linkData, link)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end)
        html:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

        y = y - 24
    end
    contentBot:SetHeight(-y + 4)
    scroll:SetVerticalScroll(0)
end

MultiBot.BuildBotQuestList = BuildBotQuestList

-- Reconstruit la popup en mode GROUP on agrège toutes les quêtes
local function BuildAggregatedQuestList()
    ClearBotContent()

    -- Construit la table id { name = ..., bots = { … } }
    local questMap = {}
    for botName, quests in pairs(MultiBot.BotQuestsIncompleted) do
        for id, name in pairs(quests) do
            local locName = GetLocalizedQuestName(id) or name
            if not questMap[id] then
                questMap[id] = { name = locName, bots = {} }
            end
            table.insert(questMap[id].bots, botName)
        end
    end

    -- 2Affiche chaque quête puis la ligne des bots
    local y = -4
    for id, data in pairs(questMap) do
        -- ligne quête
        local lineQ = CreateFrame("Frame", nil, contentBot)
        lineQ:SetSize(300, 24)
        lineQ:SetPoint("TOPLEFT", 0, y)

        -- icône
        local icon = lineQ:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20,20)
        icon:SetPoint("LEFT")

        -- lien cliquable
        local link = ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(id, data.name)
        local htmlQ = CreateFrame("SimpleHTML", nil, lineQ)
        htmlQ:SetSize(260, 20)
        htmlQ:SetPoint("LEFT", 24, 0)
        htmlQ:SetFontObject("GameFontNormal")
        htmlQ:SetText(link)
        htmlQ:SetHyperlinksEnabled(true)
        htmlQ:SetScript("OnHyperlinkEnter", function(self, linkData, link)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end)
        htmlQ:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

        y = y - 24

        -- ligne bots
        local lineB = CreateFrame("Frame", nil, contentBot)
        lineB:SetSize(300, 16)
        lineB:SetPoint("TOPLEFT", 0, y)

        local botLine = lineB:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        botLine:SetPoint("LEFT", 24, 0)
        botLine:SetText(MultiBot.L("tips.quests.botsword") .. table.concat(data.bots, ", "))

        y = y - 16
    end

    contentBot:SetHeight(-y + 4)
    scroll:SetVerticalScroll(0)
end

-- Expose la fonction pour l’appeler depuis le handler
MultiBot.BuildAggregatedQuestList = BuildAggregatedQuestList

-- Bouton principal + deux sous-boutons pour choisir /p ou /w
local btnIncomp = tQuestMenu.addButton("BotQuestsIncomp", 0, 90,
    "Interface\\Icons\\INV_Misc_Bag_22",
    MultiBot.L("tips.quests.incompleted"))

local btnGroup = tQuestMenu.addButton("BotQuestsIncompGroup", 31, 90,
                                        "Interface\\Icons\\INV_Crate_08",
                                        MultiBot.L("tips.quests.sendpartyraid"))
btnGroup:doHide()

local btnWhisper = tQuestMenu.addButton("BotQuestsIncompWhisper", 61, 90,
                                          "Interface\\Icons\\INV_Crate_08",
                                          MultiBot.L("tips.quests.sendwhisp"))
btnWhisper:doHide()

local function SendIncomp(method)

MultiBot._awaitingQuestsAll = false
	MultiBot._lastIncMode = method
    if method == "WHISPER" then
        local bot = UnitName("target")
        if not bot or not UnitIsPlayer("target") then
            UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.questcomperror"), 1, 0.2, 0.2, 1)
            return
        end
        -- reset juste pour ce bot
        MultiBot.BotQuestsIncompleted[bot] = {}
        -- envoi en whisper ciblé
        MultiBot.ActionToTarget("quests incompleted", bot)
        -- popup + liste pour ce bot
        tBotPopup:Show()
        ClearBotContent()
        MultiBot.TimerAfter(0.5, function() BuildBotQuestList(bot) end)
    else
        -- reset global
        MultiBot.BotQuestsIncompleted = {}
        MultiBot.ActionToGroup("quests incompleted")
        -- popup
        tBotPopup:Show()
        ClearBotContent()
    end
end

btnIncomp.doLeft = function()
    if btnGroup:IsShown() then
        btnGroup:doHide()
        btnWhisper:doHide()
    else
        btnGroup:doShow()
        btnWhisper:doShow()
    end
end

btnGroup.doLeft   = function() SendIncomp("GROUP")   end
btnWhisper.doLeft = function() SendIncomp("WHISPER") end

-- Expose pour le handler
tRight.buttons["BotQuestsIncomp"]        = btnIncomp
tRight.buttons["BotQuestsIncompGroup"]   = btnGroup
tRight.buttons["BotQuestsIncompWhisper"] = btnWhisper
-- END BUTTON quests incompleted --


-- BUTTON  COMPLETEDQUESTS --
-- Table de stockage pour les quêtes terminées du bot
MultiBot.BotQuestsCompleted = {}  -- [botName] = { [questID]=questName, ... }

-- 2) Pop-up Liste des quêtes terminées du bot
local tBotCompPopup = createAceQuestPopupHost(MultiBot.L("tips.quests.complist"), 380, 420, "AceGUI-3.0 is required for MB_BotQuestCompPopup", "bot_quest_comp_popup")
assert(tBotCompPopup, "AceGUI-3.0 is required for MB_BotQuestCompPopup")

local scroll2 = CreateFrame("ScrollFrame", "MB_BotQuestCompScroll", tBotCompPopup, "UIPanelScrollFrameTemplate")
scroll2:SetPoint("TOPLEFT", 10, -8)
scroll2:SetPoint("BOTTOMRIGHT", -26, 8)

local contentComp = CreateFrame("Frame", nil, scroll2)
contentComp:SetWidth(1)
scroll2:SetScrollChild(contentComp)

MultiBot.tBotCompPopup = tBotCompPopup

local function ClearCompContent()
    for _, child in ipairs({ contentComp:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
end

-- AJOUT ON VIDE TOUT
tBotCompPopup:SetScript("OnHide", function()
    MultiBot.BotQuestsCompleted = {}
    ClearCompContent()
end)
-- Fin de l’ajout

-- Build pour un seul bot
local function BuildBotCompletedList(botName)
    ClearCompContent()
    local quests = MultiBot.BotQuestsCompleted[botName] or {}
    local y = -4
    for id, name in pairs(quests) do
        local line = CreateFrame("Frame", nil, contentComp)
        line:SetSize(300, 24)
        line:SetPoint("TOPLEFT", 0, y)

        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20,20)
        icon:SetPoint("LEFT")

        local locName = GetLocalizedQuestName(id) or name
        local link = ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(id, locName)
        local html = CreateFrame("SimpleHTML", nil, line)
        html:SetSize(260, 20)
        html:SetPoint("LEFT", 24, 0)
        html:SetFontObject("GameFontNormal")
        html:SetText(link)
        html:SetHyperlinksEnabled(true)
        html:SetScript("OnHyperlinkEnter", function(self, linkData, link)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end)
        html:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

        y = y - 24
    end
    contentComp:SetHeight(-y + 4)
    scroll2:SetVerticalScroll(0)
end
MultiBot.BuildBotCompletedList = BuildBotCompletedList

-- Build agrégé pour le groupe
local function BuildAggregatedCompletedList()
    ClearCompContent()

    -- On agrège les quêtes terminées de tous les bots
    local questMap = {}
    for botName, quests in pairs(MultiBot.BotQuestsCompleted) do
        for id, name in pairs(quests) do
            local locName = GetLocalizedQuestName(id) or name
            if not questMap[id] then
                questMap[id] = { name = locName, bots = {} }
            end
            table.insert(questMap[id].bots, botName)
        end
    end

    -- On affiche
    local y = -4
    for id, data in pairs(questMap) do
        -- ligne quête
        local lineQ = CreateFrame("Frame", nil, contentComp)
        lineQ:SetSize(300, 24)
        lineQ:SetPoint("TOPLEFT", 0, y)

        local icon = lineQ:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT")

        local link = ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(id, data.name)
        local htmlQ = CreateFrame("SimpleHTML", nil, lineQ)
        htmlQ:SetSize(260, 20)
        htmlQ:SetPoint("LEFT", 24, 0)
        htmlQ:SetFontObject("GameFontNormal")
        htmlQ:SetText(link)
        htmlQ:SetHyperlinksEnabled(true)
        htmlQ:SetScript("OnHyperlinkEnter", function(self, linkData, link)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end)
        htmlQ:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

        y = y - 24

        -- ligne bots
        local lineB = CreateFrame("Frame", nil, contentComp)
        lineB:SetSize(300, 16)
        lineB:SetPoint("TOPLEFT", 0, y)

        local botLine = lineB:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        botLine:SetPoint("LEFT", 24, 0)
        botLine:SetText(MultiBot.L("tips.quests.botsword") .. table.concat(data.bots, ", "))

        y = y - 16
    end

    contentComp:SetHeight(-y + 4)
    scroll2:SetVerticalScroll(0)
end

-- expose la fonction pour le handler
MultiBot.BuildAggregatedCompletedList = BuildAggregatedCompletedList

-- Les boutons
local btnComp = tQuestMenu.addButton("BotQuestsComp", 0, 60,
    "Interface\\Icons\\INV_Misc_Bag_20",
   MultiBot.L("tips.quests.completed"))

local btnCompGroup = tQuestMenu.addButton("BotQuestsCompGroup", 31, 60,
    "Interface\\Icons\\INV_Crate_09",
    MultiBot.L("tips.quests.sendpartyraid"))
btnCompGroup:doHide()

local btnCompWhisper = tQuestMenu.addButton("BotQuestsCompWhisper", 61, 60,
    "Interface\\Icons\\INV_Crate_09",
    MultiBot.L("tips.quests.sendwhisp"))
btnCompWhisper:doHide()

local function SendComp(method)
MultiBot._awaitingQuestsAll = false
    MultiBot._lastCompMode = method
    if method == "WHISPER" then
        local bot = UnitName("target")
        if not bot or not UnitIsPlayer("target") then
			UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.questcomperror"), 1, 0.2, 0.2, 1)
            return
        end
        MultiBot.BotQuestsCompleted[bot] = {}
        MultiBot.ActionToTarget("quests completed", bot)
        tBotCompPopup:Show()
        ClearCompContent()
        MultiBot.TimerAfter(0.5, function()
            MultiBot.BuildBotCompletedList(bot)
        end)
    else
        -- GROUP
        MultiBot.BotQuestsCompleted = {}
        MultiBot.ActionToGroup("quests completed")
        tBotCompPopup:Show()
        ClearCompContent()
    end
end

btnComp.doLeft = function()
    if btnCompGroup:IsShown() then
        btnCompGroup:doHide()
        btnCompWhisper:doHide()
    else
        btnCompGroup:doShow()
        btnCompWhisper:doShow()
    end
end
btnCompGroup.doLeft   = function() SendComp("GROUP")   end
btnCompWhisper.doLeft = function() SendComp("WHISPER") end

-- Expose pour le handler
tRight.buttons["BotQuestsComp"]        = btnComp
tRight.buttons["BotQuestsCompGroup"]   = btnCompGroup
tRight.buttons["BotQuestsCompWhisper"] = btnCompWhisper
-- END BUTTON  COMPLETED QUESTS --

-- BUTTON TALK --
local btnTalk = tQuestMenu.addButton("BotQuestsTalk", 0, 0,
    "Interface\\Icons\\ability_hunter_pet_devilsaur",
    MultiBot.L("tips.quests.talk"))

btnTalk.doLeft = function()
    if not UnitExists("target") or UnitIsPlayer("target") then -- On vérifie qu'on cible bien un PNJ
        UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.talkerror"), 1, 0.2, 0.2, 1)
        return
    end
    MultiBot.ActionToGroup("talk") -- Envoie "talk" à tout le groupe ou raid
end

tRight.buttons["BotQuestsTalk"] = btnTalk
-- END BUTTON TALK --

-- BUTTON QUESTS ALL --

-- POPUP Quests All
local tBotAllPopup = createAceQuestPopupHost(MultiBot.L("tips.quests.alllist"), 420, 460, "AceGUI-3.0 is required for MB_BotQuestAllPopup", "bot_quest_all_popup")
assert(tBotAllPopup, "AceGUI-3.0 is required for MB_BotQuestAllPopup")

-- On expose immédiatement pour qu'il existe dans SendAll
MultiBot.tBotAllPopup = tBotAllPopup

-- ScrollFrame
local scrollAll = CreateFrame("ScrollFrame", "MB_BotQuestAllScroll", tBotAllPopup, "UIPanelScrollFrameTemplate")
scrollAll:SetPoint("TOPLEFT", 10, -8)
scrollAll:SetPoint("BOTTOMRIGHT", -26, 8)

local contentAll = CreateFrame("Frame", nil, scrollAll)
contentAll:SetWidth(1)
scrollAll:SetScrollChild(contentAll)
tBotAllPopup.content = contentAll

function MultiBot.ClearAllContent()
    -- 1) Frames (boutons, lignes, etc.)
    for _, child in ipairs({ contentAll:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    -- 2) Regions (FontStrings, Textures) – les headers sont ici
    for _, region in ipairs({ contentAll:GetRegions() }) do
        region:Hide()                        -- on la masque
        if region:GetObjectType() == "FontString" then
            region:SetText("")               -- on vide le texte pour éviter les résidus
        elseif region:GetObjectType() == "Texture" then
            region:SetTexture(nil)           -- on efface la texture éventuelle
        end
    end

    if contentAll.text then
        contentAll.text:SetText("")
    end
end

-- AJOUT ON VIDE TOUT
tBotAllPopup:SetScript("OnHide", function()
    MultiBot.BotQuestsAll         = {}
    MultiBot.BotQuestsCompleted   = {}
    MultiBot.BotQuestsIncompleted = {}
    MultiBot.ClearAllContent()
end)
-- Fin de l’ajout

-- Build pour un seul bot
function MultiBot.BuildBotAllList(botName)
    MultiBot.ClearAllContent()
	local contentAll = MultiBot.tBotAllPopup.content
    local quests = MultiBot.BotQuestsAll[botName] or {}
    local y = -4
    for _, link in ipairs(quests) do
        local questID = tonumber(link:match("|Hquest:(%d+):"))
        local locName = questID and GetLocalizedQuestName(questID) or link
        local displayLink = link:gsub("%[[^%]]+%]", "|cff00ff00["..locName.."]|r")

        local line = CreateFrame("Frame", nil, contentAll)
        line:SetSize(360, 20)
        line:SetPoint("TOPLEFT", 0, y)

        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20,20)
        icon:SetPoint("LEFT", 0, 0)

        local html = CreateFrame("SimpleHTML", nil, line)
        html:SetSize(320, 20); html:SetPoint("LEFT", 24, 0)
        html:SetFontObject("GameFontNormal"); html:SetText(displayLink)
        html:SetHyperlinksEnabled(true)
        html:SetScript("OnHyperlinkEnter", function(self, _, link)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(link)
            GameTooltip:Show()
        end)
        html:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)

        y = y - 22
    end
    contentAll:SetHeight(-y + 4)
    scrollAll:SetVerticalScroll(0)
end

-- version agrégée pour le groupe
local function BuildAggregatedAllList()
    MultiBot.ClearAllContent()
    local contentAll = MultiBot.tBotAllPopup.content
    local y = -4

    -- Regroupement comme avant...
    local complete = {}
    for bot, quests in pairs(MultiBot.BotQuestsCompleted or {}) do
        for id, name in pairs(quests or {}) do
            id = tonumber(id)
            if not complete[id] then complete[id] = { name = name, bots = {} } end
            table.insert(complete[id].bots, bot)
        end
    end

    local incomplete = {}
    for bot, quests in pairs(MultiBot.BotQuestsIncompleted or {}) do
        for id, name in pairs(quests or {}) do
            id = tonumber(id)
            if not incomplete[id] then incomplete[id] = { name = name, bots = {} } end
            table.insert(incomplete[id].bots, bot)
        end
    end

    -- === Header Quêtes complètes ===
    local header = contentAll:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 0, y)
    header:SetText(MultiBot.L("tips.quests.compheader"))
    y = y - 28

    -- Affiche toutes les quêtes complètes
    for id, data in pairs(complete) do
        local line = CreateFrame("Frame", nil, contentAll)
        line:SetSize(360, 20)
        line:SetPoint("TOPLEFT", 0, y)
        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20,20); icon:SetPoint("LEFT")
        -- local link = ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(id, data.name)
		local locName = GetLocalizedQuestName(id)
        local link = ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(id, locName)
        local html = CreateFrame("SimpleHTML", nil, line)
        html:SetSize(320, 20); html:SetPoint("LEFT", 24, 0)
        html:SetFontObject("GameFontNormal"); html:SetText(link)
        html:SetHyperlinksEnabled(true)
        html:SetScript("OnHyperlinkEnter", function(self, _, l)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(l); GameTooltip:Show()
        end)
        html:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
        y = y - 20

        local botsLine = contentAll:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        botsLine:SetPoint("TOPLEFT", 24, y)
        botsLine:SetText(MultiBot.L("tips.quests.botsword") .. table.concat(data.bots, ", "))
        y = y - 16
    end

    y = y - 10

    -- === Header Quêtes incomplètes ===
    local header2 = contentAll:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header2:SetPoint("TOPLEFT", 0, y)
    header2:SetText(MultiBot.L("tips.quests.incompheader"))
    y = y - 28

    -- Affiche toutes les quêtes incomplètes
    for id, data in pairs(incomplete) do
        local line = CreateFrame("Frame", nil, contentAll)
        line:SetSize(360, 20)
        line:SetPoint("TOPLEFT", 0, y)
        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20,20); icon:SetPoint("LEFT")
		local locName = GetLocalizedQuestName(id)
        local link = ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(id, locName)
        local html = CreateFrame("SimpleHTML", nil, line)
        html:SetSize(320, 20); html:SetPoint("LEFT", 24, 0)
        html:SetFontObject("GameFontNormal"); html:SetText(link)
        html:SetHyperlinksEnabled(true)
        html:SetScript("OnHyperlinkEnter", function(self, _, l)
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(l); GameTooltip:Show()
        end)
        html:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
        y = y - 20

        local botsLine = contentAll:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        botsLine:SetPoint("TOPLEFT", 24, y)
        botsLine:SetText(MultiBot.L("tips.quests.botsword") .. table.concat(data.bots, ", "))
        y = y - 16
    end

    contentAll:SetHeight(-y + 4)
    scrollAll:SetVerticalScroll(0)
end


MultiBot.BuildAggregatedAllList = BuildAggregatedAllList


-- BOUTONS All
local btnAll = tQuestMenu.addButton("BotQuestsAll", 0, 120,
    "Interface\\Icons\\INV_Misc_Book_09",
    MultiBot.L("tips.quests.allcompleted"))

local btnAllGroup = tQuestMenu.addButton("BotQuestsAllGroup", 31, 120,
    "Interface\\Icons\\INV_Misc_Book_09",
    MultiBot.L("tips.quests.sendpartyraid"))
btnAllGroup:doHide()

local btnAllWhisper = tQuestMenu.addButton("BotQuestsAllWhisper", 61, 120,
    "Interface\\Icons\\INV_Misc_Book_09",
    MultiBot.L("tips.quests.sendwhisp"))
btnAllWhisper:doHide()

function SendAll(method)
    MultiBot._lastAllMode = method
    MultiBot._awaitingQuestsAll = true
    MultiBot._blockOtherQuests = true
    MultiBot.BotQuestsAll = {}
    MultiBot._awaitingQuestsAllBots = {}

    if method == "GROUP" then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party"..i)
            if name then MultiBot._awaitingQuestsAllBots[name] = false end
        end
        MultiBot.ActionToGroup("quests all")
    elseif method == "WHISPER" then
        local bot = UnitName("target")
        if not bot or not UnitIsPlayer("target") then
            UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.questcomperror"), 1, 0.2, 0.2, 1)
            MultiBot._awaitingQuestsAll = false
            MultiBot._blockOtherQuests = false
            return
        end
        MultiBot._awaitingQuestsAllBots[bot] = false
        MultiBot.ActionToTarget("quests all", bot)
    end

    MultiBot.tBotAllPopup:Show()
    MultiBot.ClearAllContent()
    local f = MultiBot.tBotAllPopup.content
    f.text = f.text or f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    f.text:SetPoint("TOPLEFT", 8, -8)
    f.text:SetText(LOADING)
end

btnAll.doLeft = function()
    if btnAllGroup:IsShown() then
        btnAllGroup:doHide()
        btnAllWhisper:doHide()
	else
	    btnAllGroup:doShow()
		btnAllWhisper:doShow()
	end
end

btnAllGroup.doLeft   = function() SendAll("GROUP")   end
btnAllWhisper.doLeft = function() SendAll("WHISPER") end

tRight.buttons["BotQuestsAll"]        = btnAll
tRight.buttons["BotQuestsAllGroup"]   = btnAllGroup
tRight.buttons["BotQuestsAllWhisper"] = btnAllWhisper
-- END BUTTON QUESTS ALL --

-- BUTTONS USE GOB AND LOS --
-- GAME OBJECT POPUP/COPY HELPERS --
local function getGameObjectEntries(bot)
    local entries = MultiBot.LastGameObjectSearch and MultiBot.LastGameObjectSearch[bot]
    if type(entries) ~= "table" then
        return nil
    end

    return entries
end

local function collectSortedGameObjectBots()
    local bots = {}
    for bot in pairs(MultiBot.LastGameObjectSearch or {}) do
        local entries = getGameObjectEntries(bot)
        if entries and #entries > 0 then
            table.insert(bots, bot)
        end
    end
    table.sort(bots)
    return bots
end

local function isDashedSectionHeader(text)
    return type(text) == "string" and text:find("^%s*%-+%s*.-%s*%-+%s*$") ~= nil
end

local function clearFrameChildren(frame)
    if not frame or not frame.GetNumChildren or not frame.GetChildren then
        return
    end

    local childCount = frame:GetNumChildren() or 0
    for i = childCount, 1, -1 do
        local child = select(i, frame:GetChildren())
        if child then
            child:Hide()
            child:SetParent(nil)
        end
    end
end

local function buildGameObjectCopyText(bots)
    local lines = {}

    for _, bot in ipairs(bots) do
        local entries = getGameObjectEntries(bot) or {}
        table.insert(lines, ("Bot: %s"):format(bot))

        for _, entry in ipairs(entries) do
            table.insert(lines, entry)
        end

        table.insert(lines, "")
    end

    if #lines == 0 then
        return MultiBot.L("tips.quests.gobnosearchdata")
    end

    return table.concat(lines, "\n")
end

local function applyDialogBackdrop(frame)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true, tileSize = 32, edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetFrameStrata("DIALOG")
end

local function createPopupCloseButton(parent)
    local close = CreateFrame("Button", nil, parent, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    return close
end

local getUniversalPromptAceGUI

local function ensureGameObjectPopupFrame()
    if MultiBot.GameObjPopup then
        return MultiBot.GameObjPopup
    end

    local aceGUI = resolveAceGUI("AceGUI-3.0 is required for MB_GameObjPopup")
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(MultiBot.L("tips.quests.gobsfound"))
    window:SetWidth(420)
    window:SetHeight(380)
    window:EnableResize(false)
    window:SetLayout("Flow")
    window.frame:SetFrameStrata("DIALOG")
    setAceWindowCloseToHide(window)
    registerAceWindowEscapeClose(window, "GameObjPopup")
    bindAceWindowPosition(window, "gameobject_popup")

    local scroll = aceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetHeight(300)
    scroll:SetLayout("List")
    window:AddChild(scroll)

    local copyBtn = aceGUI:Create("Button")
    copyBtn:SetText(MultiBot.L("tips.quests.gobselectall"))
    copyBtn:SetWidth(150)
    copyBtn:SetCallback("OnClick", function()
        MultiBot.ShowGameObjectCopyBox()
    end)
    window:AddChild(copyBtn)

    MultiBot.GameObjPopup = {
        window = window,
        scroll = scroll,
        copyBtn = copyBtn,
    }

    return MultiBot.GameObjPopup
end

local function ensureGameObjectCopyBoxFrame()
    if MultiBot.GameObjCopyBox then
        return MultiBot.GameObjCopyBox
    end

    local aceGUI = resolveAceGUI("AceGUI-3.0 is required for MB_GameObjCopyBox")
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(MultiBot.L("tips.quests.gobctrlctocopy"))
    window:SetWidth(420)
    window:SetHeight(300)
    window:EnableResize(false)
    window:SetLayout("Fill")
    window.frame:SetFrameStrata("DIALOG")
    setAceWindowCloseToHide(window)
    registerAceWindowEscapeClose(window, "GameObjCopy")
    bindAceWindowPosition(window, "gameobject_copy")

    local editor = aceGUI:Create("MultiLineEditBox")
    editor:SetLabel("")
    editor:SetNumLines(14)
    editor:DisableButton(true)
    window:AddChild(editor)

    MultiBot.GameObjCopyBox = {
        window = window,
        editor = editor,
    }

    return MultiBot.GameObjCopyBox
end

function MultiBot.ShowGameObjectPopup()

    local popup = ensureGameObjectPopupFrame()
    if not popup then
        return
    end

    if popup.window:IsShown() then
        popup.window:Hide()
    end

    -- Clear previous popup lines.
    popup.scroll:ReleaseChildren()

    -- Render captured lines grouped by bot
    local aceGUI = resolveAceGUI("AceGUI-3.0 is required for MB_GameObjPopup")
    if not aceGUI then
        return
    end

    local bots = collectSortedGameObjectBots()

    for _, bot in ipairs(bots) do
        local lines = getGameObjectEntries(bot) or {}
        local botLine = aceGUI:Create("Label")
        botLine:SetFullWidth(true)
        botLine:SetText("Bot: |cff80ff80" .. bot .. "|r")
        popup.scroll:AddChild(botLine)

        for _, txt in ipairs(lines) do
            local line = aceGUI:Create("Label")
            line:SetFullWidth(true)
            local isSectionHeader = isDashedSectionHeader(txt)
            if isSectionHeader then
                line:SetText("|cffffff66" .. txt .. "|r")
            else
                line:SetText("   " .. txt)
            end
            popup.scroll:AddChild(line)
        end

        local spacer = aceGUI:Create("Label")
        spacer:SetFullWidth(true)
        spacer:SetText(" ")
        popup.scroll:AddChild(spacer)
    end

    if #bots == 0 then
        local noData = aceGUI:Create("Label")
        noData:SetFullWidth(true)
        noData:SetText(MultiBot.L("tips.quests.gobnosearchdata"))
        popup.scroll:AddChild(noData)
    end

    popup.window:Show()
end

function MultiBot.ShowGameObjectCopyBox()
    -- Close main popup if already visible
    if MultiBot.GameObjPopup and MultiBot.GameObjPopup.window and MultiBot.GameObjPopup.window:IsShown() then
        MultiBot.GameObjPopup.window:Hide()
    end

    local box = ensureGameObjectCopyBoxFrame()
    if not box then
        return
    end

    -- Build copy text from sorted game-object entries.
    local bots = collectSortedGameObjectBots()
    local text = buildGameObjectCopyText(bots)

    box.editor:SetText(text)
    box.window:Show()

    local editBox = box.editor and box.editor.editBox
    if editBox and editBox.SetFocus then
        editBox:SetFocus()
    end
    if editBox and editBox.HighlightText then
        editBox:HighlightText()
    end
end
		
local PROMPT
local PROMPT_WINDOW_WIDTH = 280
local PROMPT_WINDOW_HEIGHT = 108
local PROMPT_OK_BUTTON_WIDTH = 100

function ShowPrompt(title, onOk, defaultText)
    local aceGUI = resolveAceGUI("AceGUI-3.0 is required for MBUniversalPrompt")
    if not aceGUI then
        return
    end

    if not PROMPT then
        local window = aceGUI:Create("Window")
        if not window then
            return
        end

        window:SetTitle(title or "Enter Value")
        window:SetWidth(PROMPT_WINDOW_WIDTH)
        window:SetHeight(PROMPT_WINDOW_HEIGHT)
        window:EnableResize(false)
        window:SetLayout("Flow")
        window.frame:SetFrameStrata("DIALOG")
        setAceWindowCloseToHide(window)
        registerAceWindowEscapeClose(window, "UniversalPrompt")
        bindAceWindowPosition(window, "universal_prompt")

        local edit = aceGUI:Create("EditBox")
        edit:SetLabel("")
        edit:SetFullWidth(true)
        window:AddChild(edit)

        local okButton = aceGUI:Create("Button")
        okButton:SetText(OKAY)
        okButton:SetWidth(PROMPT_OK_BUTTON_WIDTH)
        window:AddChild(okButton)

        PROMPT = {
            window = window,
            edit = edit,
            okButton = okButton,
        }
    end

    PROMPT.window:SetTitle(title or "Enter Value")
    PROMPT.window:Show()
    PROMPT.edit:SetText(defaultText or "")
    local promptEditBox = PROMPT.edit and PROMPT.edit.editbox
    if promptEditBox and promptEditBox.SetFocus then
        promptEditBox:SetFocus()
    end

    PROMPT.okButton:SetCallback("OnClick", function()
        local text = PROMPT.edit:GetText()
        if text and text ~= "" then
            onOk(text)
        else
            UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.gobsnameerror"), 1, 0.2, 0.2, 1)
            return
        end

        PROMPT.window:Hide()
    end)
    PROMPT.edit:SetCallback("OnEnterPressed", function()
        local button = PROMPT.okButton and PROMPT.okButton.button
        if button and button.Click then
            button:Click()
        end
    end)
end

-- BOUTON PRINCIPAL "Use Game Object"
-- Boutons "Use Game Object"
local btnGob = tQuestMenu.addButton("BotUseGOB", 0, 150,
    "Interface\\Icons\\inv_misc_spyglass_01", MultiBot.L("tips.quests.gobsmaster"))

local btnGobName = tQuestMenu.addButton("BotUseGOBName", 31, 150,
    "Interface\\Icons\\inv_misc_note_05", MultiBot.L("tips.quests.gobenter"))
btnGobName:doHide()

local btnGobSearch = tQuestMenu.addButton("BotUseGOBSearch", 61, 150,
    "Interface\\Icons\\inv_misc_spyglass_02", MultiBot.L("tips.quests.gobsearch"))
btnGobSearch:doHide()

btnGob.doLeft = function()
    if btnGobName:IsShown() then
        btnGobName:doHide()
        btnGobSearch:doHide()
    else
        btnGobName:doShow()
        btnGobSearch:doShow()
    end
end

-- Sous-bouton : prompt pour le nom du GOB
btnGobName.doLeft = function()
    ShowPrompt(
        MultiBot.L("tips.quests.gobpromptname"),
        function(gobName)
            gobName = gobName:gsub("^%s+", ""):gsub("%s+$", "")
            if gobName == "" then
                UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.goberrorname") , 1, 0.2, 0.2, 1)
                return
            end
            local bot = UnitName("target")
            if not bot or not UnitIsPlayer("target") then
                UIErrorsFrame:AddMessage(MultiBot.L("tips.quests.gobselectboterror"), 1, 0.2, 0.2, 1)
                return
            end
            SendChatMessage("u " .. gobName, "WHISPER", nil, bot)
        end
    )
end

-- Sous-bouton envoi la commande "los" à tout le groupe
btnGobSearch.doLeft = function()
    MultiBot.ActionToGroup("los")
end

-- Register dans le handler MultiBot si besoin
tRight.buttons["BotUseGOB"]      = btnGob
tRight.buttons["BotUseGOBName"]  = btnGobName
tRight.buttons["BotUseGOBSearch"]= btnGobSearch
-- END NEW QUESTS --

-- GROUP ACTIONS --
-- Main button that opens a submenu for group commands.
local btnGroupActions = tRight.addButton("GroupActions", 34, 0,
	"Spell_unused2",
	MultiBot.L("tips.group.group"))

btnGroupActions.doLeft = function(pButton)
	local menu = tRight.frames and tRight.frames["GroupActionsMenu"]
	if not menu then
		return
	end

	if menu:IsShown() then
		menu:Hide()
	else
		menu:Show()
	end
end

-- Submenu: drink/release/revive
local tGroupActionsMenu = tRight.addFrame("GroupActionsMenu", 34, 34, 32, 96)
tGroupActionsMenu:Hide()

-- DRINK --

tGroupActionsMenu.addButton("Drink", 0, 0, "inv_drink_24_sealwhey", MultiBot.L("tips.drink.group"))
.doLeft = function(pButton)
	MultiBot.ActionToGroup("drink")
end

-- RELEASE --

tGroupActionsMenu.addButton("Release", 0, 34, "achievement_bg_xkills_avgraveyard", MultiBot.L("tips.release.group"))
.doLeft = function(pButton)
	MultiBot.ActionToGroup("release")
end

-- REVIVE --

tGroupActionsMenu.addButton("Revive", 0, 68, "spell_holy_guardianspirit", MultiBot.L("tips.revive.group"))
.doLeft = function(pButton)
	MultiBot.ActionToGroup("revive")
end

-- SUMALL --

tRight.addButton("Summon", 68, 0, "ability_hunter_beastcall", MultiBot.L("tips.summon.group"))
.doLeft = function(pButton)
	MultiBot.ActionToGroup("summon")
end

-- INVENTORY --

MultiBot.inventory = MultiBot.newFrame(MultiBot, -700, -144, 32, 442, 884)
MultiBot.inventory.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Inventory.blp")
MultiBot.inventory.addText("Title", MB_INVENTORY_LABEL, "CENTER", -58, 429, 12)
MultiBot.inventory.action = "s"
MultiBot.inventory:SetMovable(true)
MultiBot.inventory:Hide()

MultiBot.inventory.movButton("Move", -406, 849, 34, MultiBot.L("tips.move.inventory"))

MultiBot.inventory.wowButton("X", -126, 862, 15, 18, 13)
.doLeft = function(pButton)
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tButton = tUnits.frames[MultiBot.inventory.name].buttons["Inventory"]
	tButton.doLeft(tButton)
end

MultiBot.inventory.addButton("Sell", -94, 806, "inv_misc_coin_16", MultiBot.L("tips.inventory.sell")).setEnable()
.doLeft = function(pButton)
	if(pButton.state) then
		MultiBot.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		MultiBot.inventory.action = "s"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

-- Bouton vendre tous les objets gris (s *)
MultiBot.inventory.addButton("SellGrey", -94, 768, "inv_misc_coin_03", MultiBot.L("tips.inventory.sellgrey"))
.doLeft = function(pButton)
    if not MultiBot.isTarget() then
        return
    end
		CancelTrade()
		MultiBot.inventory.action = ""
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		SendChatMessage("s *", "WHISPER", nil, pButton.getName())
    if MultiBot.RefreshInventory then
        MultiBot.RefreshInventory(0.5)
    end
end

-- Bouton vendre tous les objets vendables (s vendor)
MultiBot.inventory.addButton("SellVendor", -94, 731, "inv_misc_coin_04", MultiBot.L("tips.inventory.sellvendor"))
.doLeft = function(pButton)
    if not MultiBot.isTarget() then
        return
    end
        CancelTrade()
		MultiBot.inventory.action = ""
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		SendChatMessage("s vendor", "WHISPER", nil, pButton.getName())
		if MultiBot.RefreshInventory then
			MultiBot.RefreshInventory()
		end
end

MultiBot.inventory.addButton("Equip", -94, 694, "inv_helmet_22", MultiBot.L("tips.inventory.equip")).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		MultiBot.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		MultiBot.inventory.action = "e"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

MultiBot.inventory.addButton("Use", -94, 657, "inv_gauntlets_25", MultiBot.L("tips.inventory.use")).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		MultiBot.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		MultiBot.inventory.action = "u"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.setEnable()
	end
end

MultiBot.inventory.addButton("Trade", -94, 620, "achievement_reputation_01", MultiBot.L("tips.inventory.trade")).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		MultiBot.inventory.action = ""
		pButton.setDisable()
		CancelTrade()
	else
		InitiateTrade(pButton.getName())
		MultiBot.inventory.action = "give"
		pButton.getButton("Destroy").setDisable()
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

MultiBot.inventory.addButton("Destroy", -94, 583, "inv_hammer_15", MultiBot.L("tips.inventory.drop")).setDisable()
.doLeft = function(pButton)
	if(pButton.state) then
		MultiBot.inventory.action = ""
		pButton.setDisable()
	else
		CancelTrade()
		MultiBot.inventory.action = "destroy"
		pButton.getButton("Equip").setDisable()
		pButton.getButton("Trade").setDisable()
		pButton.getButton("Sell").setDisable()
		pButton.getButton("Use").setDisable()
		pButton.setEnable()
	end
end

MultiBot.inventory.addButton("Open", -94, 322.5, "inv_misc_gift_05", MultiBot.L("tips.inventory.open"))
.doLeft = function(pButton)
	SendChatMessage("open items", "WHISPER", nil, pButton.getName())
end

local tFrame = MultiBot.inventory.addFrame("Items", -397, 807, 32)
tFrame:Show()

-- STATS --

MultiBot.stats = MultiBot.newFrame(MultiBot, -60, 560, 32)
MultiBot.stats:SetMovable(true)
MultiBot.stats:Hide()

MultiBot.stats.movButton("Move", 0, -80, 160, MultiBot.L("tips.move.stats"))

MultiBot.addStats(MultiBot.stats, "party1", 0,    0, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party2", 0,  -60, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party3", 0, -120, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party4", 0, -180, 32, 192, 96)

-- ITEMUS REFACTOR AND IMPROVMENT --

MultiBot.itemus = MultiBot.newFrame(MultiBot, -860, -144, 32, 442, 884)
MultiBot.itemus.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Inventory.blp")
MultiBot.itemus.addText("Title", "Itemus", "CENTER", -57, 429, 13)
MultiBot.itemus.addText("Pages", MB_PAGE_DEFAULT, "CENTER", -57, 409, 13)
MultiBot.itemus.name  = UnitName("Player")
MultiBot.itemus.index = {}
MultiBot.itemus.color = "cff9d9d9d"
MultiBot.itemus.level = "L10"
MultiBot.itemus.rare  = "R00"
MultiBot.itemus.slot  = "S00"
MultiBot.itemus.type  = "PC"
MultiBot.itemus.max   = 1
MultiBot.itemus.now   = 1
MultiBot.itemus:SetMovable(true)
MultiBot.itemus:Hide()

-- Boutons: déplacer / pagination / fermer
MultiBot.itemus.movButton("Move", -407, 850, 32, MultiBot.L("tips.move.itemus"))

do
  local btnPrev = MultiBot.itemus.wowButton("<", -319, 841, 15, 18, 13)
  btnPrev.doHide()
  btnPrev.doLeft = function()
    MultiBot.itemus.now = MultiBot.itemus.now - 1
    MultiBot.itemus.addItems()
  end

  local btnNext = MultiBot.itemus.wowButton(">", -225, 841, 15, 18, 13)
  btnNext.doHide()
  btnNext.doLeft = function()
    MultiBot.itemus.now = MultiBot.itemus.now + 1
    MultiBot.itemus.addItems()
  end

  local btnClose = MultiBot.itemus.wowButton("X", -126, 862, 15, 18, 13)
  btnClose.doLeft = function()
    MultiBot.itemus:Hide()
  end
end

-- Frame des items (grille)
local tItemsFrame = MultiBot.itemus.addFrame("Items", -397, 807, 32)
tItemsFrame:Show()

-- ================= Outils communs (refactor) =================================
local function setFilterAndRefresh(kind, texture, kv)
  -- kind = "Level" | "Rare" | "Slot"
  MultiBot.Select(MultiBot.itemus, kind, texture)
  for k, v in pairs(kv) do MultiBot.itemus[k] = v end
  MultiBot.itemus.addItems(1)
end

-- ================= ITEMUS:LEVEL ==============================================
MultiBot.itemus.addButton("Level", -94, 806, "achievement_level_10", MultiBot.L("tips.itemus.level.master")).setEnable()
.doLeft = function(pButton)
  MultiBot.ShowHideSwitch(pButton.parent.frames["Level"])
end

do
  local frame = MultiBot.itemus.addFrame("Level", -61, 808, 28)
  frame:Hide()

  local levels = {
    { "L10", "achievement_level_10", MultiBot.L("tips.itemus.level.L10") },
    { "L20", "achievement_level_20", MultiBot.L("tips.itemus.level.L20") },
    { "L30", "achievement_level_30", MultiBot.L("tips.itemus.level.L30") },
    { "L40", "achievement_level_40", MultiBot.L("tips.itemus.level.L40") },
    { "L50", "achievement_level_50", MultiBot.L("tips.itemus.level.L50") },
    { "L60", "achievement_level_60", MultiBot.L("tips.itemus.level.L60") },
    { "L70", "achievement_level_70", MultiBot.L("tips.itemus.level.L70") },
    { "L80", "achievement_level_80", MultiBot.L("tips.itemus.level.L80") },
  }

  for i, def in ipairs(levels) do
    local id, icon, tip = def[1], def[2], def[3]
    frame.addButton(id, 30 * (i - 1), 0, icon, tip)
    .doLeft = function(pButton)
      setFilterAndRefresh("Level", pButton.texture, { level = id })
    end
  end
end

-- ================= ITEMUS:RARE ===============================================
MultiBot.itemus.addButton("Rare", -94, 768, "achievement_quests_completed_01", MultiBot.L("tips.itemus.rare.master"))
.doLeft = function(pButton)
  MultiBot.ShowHideSwitch(pButton.parent.frames["Rare"])
end

do
  local frame = MultiBot.itemus.addFrame("Rare", -61, 770)
  frame:Hide()

  local rares = {
    { "R00", "achievement_quests_completed_01", MultiBot.L("tips.itemus.rare.R00"), "cff9d9d9d" },
    { "R01", "achievement_quests_completed_02", MultiBot.L("tips.itemus.rare.R01"), "cffffffff" },
    { "R02", "achievement_quests_completed_03", MultiBot.L("tips.itemus.rare.R02"), "cff1eff00" },
    { "R03", "achievement_quests_completed_04", MultiBot.L("tips.itemus.rare.R03"), "cff0070dd" },
    { "R04", "achievement_quests_completed_05", MultiBot.L("tips.itemus.rare.R04"), "cffa335ee" },
    { "R05", "achievement_quests_completed_06", MultiBot.L("tips.itemus.rare.R05"), "cffff8000" },
    { "R06", "achievement_quests_completed_07", MultiBot.L("tips.itemus.rare.R06"), "cffff0000" },
    { "R07", "achievement_quests_completed_08", MultiBot.L("tips.itemus.rare.R07"), "cffe6cc80" },
  }

  for i, def in ipairs(rares) do
    local id, icon, tip, color = def[1], def[2], def[3], def[4]
    frame.addButton(id, 30 * (i - 1), 0, icon, tip)
    .doLeft = function(pButton)
      setFilterAndRefresh("Rare", pButton.texture, { rare = id, color = color })
    end
  end
end

-- ================= ITEMUS:SLOT ===============================================
MultiBot.itemus.addButton("Slot", -94, 731, "inv_drink_18", MultiBot.L("tips.itemus.slot.master"))
.doLeft = function(pButton)
  MultiBot.ShowHideSwitch(pButton.parent.frames["Slot"])
end

do
  local frame = MultiBot.itemus.addFrame("Slot", -61, 733)
  frame:Hide()

  -- Mise en table du layout original (y compris le correctif S27 qui posait S26 dans le code d'origine)
  local slots = {
    { "S00",   0,   0,  "inv_drink_18"                      , MultiBot.L("tips.itemus.slot.S00") },
    { "S01",  30,   0,  "inv_misc_desecrated_platehelm"     , MultiBot.L("tips.itemus.slot.S01") },
    { "S02",  60,   0,  "inv_jewelry_necklace_22"           , MultiBot.L("tips.itemus.slot.S02") },
    { "S03",  90,   0,  "inv_misc_desecrated_plateshoulder" , MultiBot.L("tips.itemus.slot.S03") },
    { "S04", 120,   0,  "inv_shirt_grey_01"                 , MultiBot.L("tips.itemus.slot.S04") },
    { "S05", 150,   0,  "inv_misc_desecrated_platechest"    , MultiBot.L("tips.itemus.slot.S05") },
    { "S06", 180,   0,  "inv_misc_desecrated_platebelt"     , MultiBot.L("tips.itemus.slot.S06") },
    { "S07", 210,   0,  "inv_misc_desecrated_platepants"    , MultiBot.L("tips.itemus.slot.S07") },
    { "S08",   0, -30,  "inv_misc_desecrated_plateboots"    , MultiBot.L("tips.itemus.slot.S08") },
    { "S09",  30, -30,  "inv_misc_desecrated_platebracer"   , MultiBot.L("tips.itemus.slot.S09") },
    { "S10",  60, -30,  "inv_misc_desecrated_plategloves"   , MultiBot.L("tips.itemus.slot.S10") },
    { "S11",  90, -30,  "inv_jewelry_ring_19"               , MultiBot.L("tips.itemus.slot.S11") },
    { "S12", 120, -30,  "inv_jewelry_ring_07"               , MultiBot.L("tips.itemus.slot.S12") },
    { "S13", 150, -30,  "inv_sword_23"                      , MultiBot.L("tips.itemus.slot.S13") },
    { "S14", 180, -30,  "inv_shield_04"                     , MultiBot.L("tips.itemus.slot.S14") },
    { "S15", 210, -30,  "inv_weapon_bow_05"                 , MultiBot.L("tips.itemus.slot.S15") },
    { "S16",   0, -60,  "inv_misc_cape_20"                  , MultiBot.L("tips.itemus.slot.S16") },
    { "S17",  30, -60,  "inv_axe_14"                        , MultiBot.L("tips.itemus.slot.S17") },
    { "S18",  60, -60,  "inv_misc_bag_07_black"             , MultiBot.L("tips.itemus.slot.S18") },
    { "S19",  90, -60,  "inv_shirt_guildtabard_01"          , MultiBot.L("tips.itemus.slot.S19") },
    { "S20", 120, -60,  "inv_misc_desecrated_clothchest"    , MultiBot.L("tips.itemus.slot.S20") },
    { "S21", 150, -60,  "inv_hammer_07"                     , MultiBot.L("tips.itemus.slot.S21") },
    { "S22", 180, -60,  "inv_sword_15"                      , MultiBot.L("tips.itemus.slot.S22") },
    { "S23", 210, -60,  "inv_misc_book_09"                  , MultiBot.L("tips.itemus.slot.S23") },
    { "S24",   0, -90,  "inv_misc_ammo_arrow_01"            , MultiBot.L("tips.itemus.slot.S24") },
    { "S25",  30, -90,  "inv_throwingknife_02"              , MultiBot.L("tips.itemus.slot.S25") },
    { "S26",  60, -90,  "inv_wand_07"                       , MultiBot.L("tips.itemus.slot.S26") },
    { "S27",  90, -90,  "inv_misc_quiver_07"                , MultiBot.L("tips.itemus.slot.S27") }, -- correctif
    { "S28", 120, -90,  "inv_relics_idolofrejuvenation"     , MultiBot.L("tips.itemus.slot.S28") },
  }

  for _, def in ipairs(slots) do
    local id, x, y, icon, tip = def[1], def[2], def[3], def[4], def[5]
    frame.addButton(id, x, y, icon, tip)
    .doLeft = function(pButton)
      setFilterAndRefresh("Slot", pButton.texture, { slot = id })
    end
  end
end

-- ================= ITEMUS:TYPE ===============================================
MultiBot.itemus.addButton("Type", -94, 694, "inv_misc_head_clockworkgnome_01", MultiBot.L("tips.itemus.type")).setDisable()
.doLeft = function(pButton)
  MultiBot.itemus.type = MultiBot.IF(MultiBot.OnOffSwitch(pButton), "NPC", "PC")
  MultiBot.itemus.addItems(1)
end

-- ICONOS REFACTOR --
MultiBot.iconos = MultiBot.newFrame(MultiBot, -860, -144, 32, 442, 884)
MultiBot.iconos.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Iconos.blp")
MultiBot.iconos.addText("Title", "Iconos", "CENTER", -57, 429, 13)
MultiBot.iconos.addText("Pages", MB_PAGE_DEFAULT, "CENTER", -57, 409, 13)
MultiBot.iconos.max = 1
MultiBot.iconos.now = 1
MultiBot.iconos:SetMovable(true)
MultiBot.iconos:Hide()

-- Bouton déplacer
MultiBot.iconos.movButton("Move", -407, 850, 32, MultiBot.L("tips.move.iconos"))

-- Bouton page précédente
local btnPrev = MultiBot.iconos.wowButton("<", -319, 841, 15, 18, 13)
btnPrev.doHide()
btnPrev.doLeft = function()
	MultiBot.iconos.now = MultiBot.iconos.now - 1
	MultiBot.iconos.addIcons()
end

-- Bouton page suivante
local btnNext = MultiBot.iconos.wowButton(">", -225, 841, 15, 18, 13)
btnNext.doHide()
btnNext.doLeft = function()
	MultiBot.iconos.now = MultiBot.iconos.now + 1
	MultiBot.iconos.addIcons()
end

-- Bouton fermer
local btnClose = MultiBot.iconos.wowButton("X", -126, 862, 15, 18, 13)
btnClose.doLeft = function()
	MultiBot.iconos:Hide()
end

-- Frame des icônes
local tFrame = MultiBot.iconos.addFrame("Icons", -397, 807, 32)
tFrame:Show()

-- SPELLBOOK --

MultiBot.spellbook = MultiBot.newFrame(MultiBot, -802, 302, 28, 336, 448)
MultiBot.spellbook.spells = {}
MultiBot.spellbook.icons = {}
MultiBot.spellbook.max = 1
MultiBot.spellbook.now = 1
MultiBot.spellbook:SetMovable(true)
MultiBot.spellbook:Hide()

for i = 1, GetNumMacroIcons() do MultiBot.spellbook.icons[GetMacroIconInfo(i)] = i end

local tFrame = MultiBot.spellbook.addFrame("Icon", -276, 392, 28, 50, 50)
tFrame.addTexture("Interface/Spellbook/Spellbook-Icon")
tFrame:SetFrameLevel(0)

local tFrame = MultiBot.spellbook.addFrame("TopLeft", -112, 224, 28, 224, 224)
tFrame.addTexture("Interface/ItemTextFrame/UI-ItemText-TopLeft")
tFrame:SetFrameLevel(1)

local tFrame = MultiBot.spellbook.addFrame("TopRight", -0, 224, 28, 112, 224)
tFrame.addTexture("Interface/Spellbook/UI-SpellbookPanel-TopRight")
tFrame:SetFrameLevel(2)

local tFrame = MultiBot.spellbook.addFrame("BottomLeft", -112, 0, 28, 224, 224)
tFrame.addTexture("Interface/ItemTextFrame/UI-ItemText-BotLeft")
tFrame:SetFrameLevel(3)

local tFrame = MultiBot.spellbook.addFrame("BottomRight", -0, 0, 28, 112, 224)
tFrame.addTexture("Interface/Spellbook/UI-SpellbookPanel-BotRight")
tFrame:SetFrameLevel(4)

local tOverlay = MultiBot.spellbook.addFrame("Overlay", -47, 81, 28, 258, 292)
tOverlay.addText("Title", SPELLBOOK, "CENTER", 14, 200, 13)
tOverlay.addText("Pages", MB_PAGE_DEFAULT, "CENTER", 14, 173, 13)
tOverlay:SetFrameLevel(5)

tOverlay.movButton("Move", -226, 310, 50, MultiBot.L("tips.move.spellbook"), MultiBot.spellbook)

tOverlay.wowButton("<", -159, 309, 15, 18, 13)
.doLeft = function(pButton)
	MultiBot.spellbook.to = MultiBot.spellbook.to - 16
	MultiBot.spellbook.now = MultiBot.spellbook.now - 1
	MultiBot.spellbook.from = MultiBot.spellbook.from - 16
	MultiBot.spellbook.frames["Overlay"].setText("Pages", MultiBot.spellbook.now .. "/" .. MultiBot.spellbook.max)
	MultiBot.spellbook.frames["Overlay"].buttons[">"].doShow()

	if(MultiBot.spellbook.now == 1) then pButton.doHide() end
	local tIndex = 1

	for i = MultiBot.spellbook.from, MultiBot.spellbook.to do
		MultiBot.setSpell(tIndex, MultiBot.spellbook.spells[i], pButton.getName())
		tIndex = tIndex + 1
	end
end

tOverlay.wowButton(">", -59, 309, 15, 18, 11)
.doLeft = function(pButton)
	MultiBot.spellbook.to = MultiBot.spellbook.to + 16
	MultiBot.spellbook.now = MultiBot.spellbook.now + 1
	MultiBot.spellbook.from = MultiBot.spellbook.from + 16
	MultiBot.spellbook.frames["Overlay"].setText("Pages", MultiBot.spellbook.now .. "/" .. MultiBot.spellbook.max)
	MultiBot.spellbook.frames["Overlay"].buttons["<"].doShow()

	if(MultiBot.spellbook.now == MultiBot.spellbook.max) then pButton.doHide() end
	local tIndex = 1

	for i = MultiBot.spellbook.from, MultiBot.spellbook.to do
		MultiBot.setSpell(tIndex, MultiBot.spellbook.spells[i], pButton.getName())
		tIndex = tIndex + 1
	end
end

tOverlay.wowButton("X", 16, 336, 15, 18, 11)
.doLeft = function(pButton)
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tButton = tUnits.frames[MultiBot.spellbook.name].buttons["Spellbook"]
	tButton.doLeft(tButton)
end

tOverlay.addText("R01", "|cff402000Rank|r", "TOPLEFT", 44, -16, 11)
tOverlay.addText("T01", "|cffffcc00Title|r", "TOPLEFT", 30, -2, 12)
local tButton = tOverlay.addButton("S01", -230, 264, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R02", "|cff402000Rank|r", "TOPLEFT", 172, -16, 11)
tOverlay.addText("T02", "|cffffcc00Title|r", "TOPLEFT", 159, -2, 12)
local tButton = tOverlay.addButton("S02", -101, 264, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R03", "|cff402000Rank|r", "TOPLEFT", 44, -52, 11)
tOverlay.addText("T03", "|cffffcc00Title|r", "TOPLEFT", 30, -38, 12)
local tButton = tOverlay.addButton("S03", -230, 228, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R04", "|cff402000Rank|r", "TOPLEFT", 172, -52, 11)
tOverlay.addText("T04", "|cffffcc00Title|r", "TOPLEFT", 159, -38, 12)
local tButton = tOverlay.addButton("S04", -101, 228, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R05", "|cff402000Rank|r", "TOPLEFT", 44, -88, 11)
tOverlay.addText("T05", "|cffffcc00Title|r", "TOPLEFT", 30, -74, 12)
local tButton = tOverlay.addButton("S05", -230, 192, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R06", "|cff402000Rank|r", "TOPLEFT", 172, -88, 11)
tOverlay.addText("T06", "|cffffcc00Title|r", "TOPLEFT", 159, -74, 12)
local tButton = tOverlay.addButton("S06", -101, 192, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R07", "|cff402000Rank|r", "TOPLEFT", 44, -124, 11)
tOverlay.addText("T07", "|cffffcc00Title|r", "TOPLEFT", 30, -110, 12)
local tButton = tOverlay.addButton("S07", -230, 156, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R08", "|cff402000Rank|r", "TOPLEFT", 172, -124, 11)
tOverlay.addText("T08", "|cffffcc00Title|r", "TOPLEFT", 159, -110, 12)
local tButton = tOverlay.addButton("S08", -101, 156, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R09", "|cff402000Rank|r", "TOPLEFT", 44, -160, 11)
tOverlay.addText("T09", "|cffffcc00Title|r", "TOPLEFT", 30, -146, 12)
local tButton = tOverlay.addButton("S09", -230, 120, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R10", "|cff402000Rank|r", "TOPLEFT", 172, -160, 11)
tOverlay.addText("T10", "|cffffcc00Title|r", "TOPLEFT", 159, -146, 12)
local tButton = tOverlay.addButton("S10", -101, 120, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R11", "|cff402000Rank|r", "TOPLEFT", 44, -196, 11)
tOverlay.addText("T11", "|cffffcc00Title|r", "TOPLEFT", 30, -182, 12)
local tButton = tOverlay.addButton("S11", -230, 84, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R12", "|cff402000Rank|r", "TOPLEFT", 172, -196, 11)
tOverlay.addText("T12", "|cffffcc00Title|r", "TOPLEFT", 159, -182, 12)
local tButton = tOverlay.addButton("S12", -101, 84, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R13", "|cff402000Rank|r", "TOPLEFT", 44, -232, 11)
tOverlay.addText("T13", "|cffffcc00Title|r", "TOPLEFT", 30, -218, 12)
local tButton = tOverlay.addButton("S13", -230, 48, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R14", "|cff402000Rank|r", "TOPLEFT", 172, -232, 11)
tOverlay.addText("T14", "|cffffcc00Title|r", "TOPLEFT", 159, -218, 12)
local tButton = tOverlay.addButton("S14", -101, 48, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R15", "|cff402000Rank|r", "TOPLEFT", 44, -268, 11)
tOverlay.addText("T15", "|cffffcc00Title|r", "TOPLEFT", 30, -254, 12)
local tButton = tOverlay.addButton("S15", -230, 12, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.addText("R16", "|cff402000Rank|r", "TOPLEFT", 172, -268, 11)
tOverlay.addText("T16", "|cffffcc00Title|r", "TOPLEFT", 159, -254, 12)
local tButton = tOverlay.addButton("S16", -101, 12, "inv_misc_questionmark", "Text")
tButton.doRight = function(pButton)
	MultiBot.SpellToMacro(MultiBot.spellbook.name, pButton.spell, pButton.texture)
end
tButton.doLeft = function(pButton)
	SendChatMessage("cast " .. pButton.spell, "WHISPER", nil, MultiBot.spellbook.name)
end

tOverlay.boxButton("C01", -214, 262, 16, true)
tOverlay.boxButton("C02",  -85, 262, 16, true)
tOverlay.boxButton("C03", -214, 226, 16, true)
tOverlay.boxButton("C04",  -85, 226, 16, true)
tOverlay.boxButton("C05", -214, 190, 16, true)
tOverlay.boxButton("C06",  -85, 190, 16, true)
tOverlay.boxButton("C07", -214, 154, 16, true)
tOverlay.boxButton("C08",  -85, 154, 16, true)
tOverlay.boxButton("C09", -214, 118, 16, true)
tOverlay.boxButton("C10",  -85, 118, 16, true)
tOverlay.boxButton("C11", -214,  82, 16, true)
tOverlay.boxButton("C12",  -85,  82, 16, true)
tOverlay.boxButton("C13", -214,  46, 16, true)
tOverlay.boxButton("C14",  -85,  46, 16, true)
tOverlay.boxButton("C15", -214,  10, 16, true)
tOverlay.boxButton("C16",  -85,  10, 16, true)

-- REWARD --

MultiBot.reward = MultiBot.newFrame(MultiBot, -754, 238, 28, 384, 512)
MultiBot.reward.rewards = {}
MultiBot.reward.units = {}
MultiBot.reward.from = 1
MultiBot.reward.max = 1
MultiBot.reward.now = 1
MultiBot.reward.to = 12
MultiBot.reward:SetMovable(true)
MultiBot.reward:Hide()

MultiBot.reward.doClose = function()
	local tOverlay = MultiBot.reward.frames["Overlay"]
	for key, value in pairs(MultiBot.reward.units) do if(value.rewarded == false) then return end end
	MultiBot.reward:Hide()
end

local tFrame = MultiBot.reward.addFrame("Icon", -313, 443, 28, 64, 64)
tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Reward.blp")
tFrame:SetFrameLevel(0)

local tFrame = MultiBot.reward.addFrame("TopLeft", -128, 256, 28, 256, 256)
tFrame.addTexture("Interface/ItemTextFrame/UI-ItemText-TopLeft")
tFrame:SetFrameLevel(1)

local tFrame = MultiBot.reward.addFrame("TopRight", -0, 256, 28, 128, 256)
tFrame.addTexture("Interface/Spellbook/UI-SpellbookPanel-TopRight")
tFrame:SetFrameLevel(2)

local tFrame = MultiBot.reward.addFrame("BottomLeft", -128, 0, 28, 256, 256)
tFrame.addTexture("Interface/ItemTextFrame/UI-ItemText-BotLeft")
tFrame:SetFrameLevel(3)

local tFrame = MultiBot.reward.addFrame("BottomRight", -0, 0, 28, 128, 256)
tFrame.addTexture("Interface/Spellbook/UI-SpellbookPanel-BotRight")
tFrame:SetFrameLevel(4)

local tOverlay = MultiBot.reward.addFrame("Overlay", -48, 97, 28, 310, 330)
tOverlay.addText("Title", MultiBot.L("info.reward"), "CENTER", 16, 226, 13)
tOverlay.addText("Pages", MB_PAGE_DEFAULT, "CENTER", 16, 196, 13)
tOverlay:SetFrameLevel(5)

tOverlay.movButton("Move", -270, 354, 50, MultiBot.L("tips.move.reward"), MultiBot.reward)

tOverlay.wowButton("<", -182, 351, 15, 18, 13)
.doLeft = function(pButton)
	local tOverlay = MultiBot.reward.frames["Overlay"]
	local tReward = MultiBot.reward

	tReward.to = tReward.to - 12
	tReward.now = tReward.now - 1
	tReward.from = tReward.from - 12
	tOverlay.setText("Pages", tReward.now .. "/" .. tReward.max)
	tOverlay.buttons[">"].doShow()

	if(tReward.now == 1) then pButton.doHide() end
	local tIndex = 1

	for i = tReward.from, tReward.to do
		MultiBot.setReward(tIndex, MultiBot.reward.units[i])
		tIndex = tIndex + 1
	end
end

tOverlay.wowButton(">", -82, 351, 15, 18, 11)
.doLeft = function(pButton)
	local tOverlay = MultiBot.reward.frames["Overlay"]
	local tReward = MultiBot.reward

	tReward.to = tReward.to + 12
	tReward.now = tReward.now + 1
	tReward.from = tReward.from + 12
	tOverlay.setText("Pages", tReward.now .. "/" .. tReward.max)
	tOverlay.buttons["<"].doShow()

	if(tReward.now == tReward.max) then pButton.doHide() end
	local tIndex = 1

	for i = tReward.from, tReward.to do
		MultiBot.setReward(tIndex, MultiBot.reward.units[i])
		tIndex = tIndex + 1
	end
end

tOverlay.wowButton("X", 13, 381, 17, 20, 11)
.doLeft = function(pButton)
	MultiBot.reward:Hide()
end

-- GROUP:U01 --

local tFrame = tOverlay.addFrame("U01", -156, 282, 23, 154, 48)
tFrame.addText("U01", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U02 --

local tFrame = tOverlay.addFrame("U02", 0, 282, 23, 154, 48)
tFrame.addText("U02", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U03 --

local tFrame = tOverlay.addFrame("U03", -156, 228, 23, 154, 48)
tFrame.addText("U03", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U04 --

local tFrame = tOverlay.addFrame("U04", 0, 228, 23, 154, 48)
tFrame.addText("U04", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U05 --

local tFrame = tOverlay.addFrame("U05", -156, 174, 23, 154, 48)
tFrame.addText("U05", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U06 --

local tFrame = tOverlay.addFrame("U06", 0, 174, 23, 154, 48)
tFrame.addText("U06", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U07 --

local tFrame = tOverlay.addFrame("U07", -156, 120, 23, 154, 48)
tFrame.addText("U07", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U08 --

local tFrame = tOverlay.addFrame("U08", 0, 120, 23, 154, 48)
tFrame.addText("U08", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U09 --

local tFrame = tOverlay.addFrame("U09", -156, 66, 23, 154, 48)
tFrame.addText("U09", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U10 --

local tFrame = tOverlay.addFrame("U10", 0, 66, 23, 154, 48)
tFrame.addText("U10", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U11 --

local tFrame = tOverlay.addFrame("U11", -156, 12, 23, 154, 48)
tFrame.addText("U11", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- GROUP:U12 --

local tFrame = tOverlay.addFrame("U12", 0, 12, 23, 154, 48)
tFrame.addText("U12", "|cffffcc00NAME - CLASS|r", "BOTTOMLEFT", 20, 28, 13)
tFrame.addButton("R1", -130, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R2", -104, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R3", -78, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R4", -52, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R5", -26, 0, "inv_misc_questionmark", "Text")
tFrame.addButton("R6", -0, 0, "inv_misc_questionmark", "Text")
tFrame.addFrame("Inspector", -137, 26, 16)
.addButton("Inspect", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", "Inspect")
.doLeft = function(pButton)
	InspectUnit(pButton.getName())
end

-- TALENT -- (TODO - Vérifiez qu'on ne mets pas deux fois la même glyphe dans les glyphes custom)

MultiBot.talent = MultiBot.newFrame(MultiBot, -104, -276, 28, 1024, 1024)
--MultiBot.talent.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent.blp")
MultiBot.talent.addText("Points", MultiBot.L("info.talent.Points"), "CENTER", -228, -8, 13)
MultiBot.talent.addText("Title", MultiBot.L("info.talent.Title"), "CENTER", -228, 491, 13)
MultiBot.talent:SetMovable(true)
MultiBot.talent:Hide()

MultiBot.talent.movButton("Move", -960, 960, 64, MultiBot.L("tips.move.talent"))

MultiBot.talent.tabTextures = MultiBot.talent.tabTextures or {}
MultiBot.TalentTabKeys = MultiBot.TalentTabKeys or { GLYPHS = "Tab6", CUSTOM_TALENTS = "Tab7", CUSTOM_GLYPHS = "Tab8", COPY = "Tab9", APPLY = "Tab10" }
MultiBot.TalentTabGroups = MultiBot.TalentTabGroups or {
    ALL = { "Tab1", "Tab2", "Tab3", "Tab4", "Tab5", "Tab6", "Tab7", "Tab8", "Tab9", "Tab10" },
    CHROME = { "Tab5", "Tab6", "Tab7", "Tab8", "Tab9", "Tab10" },
    BOTTOM = { "Tab5", "Tab6", "Tab7", "Tab8", "Tab9", "Tab10" },
    INACTIVE_DEFAULT = { "Tab6", "Tab7", "Tab8", "Tab9", "Tab10" },
    TALENT_TREES = { "Tab1", "Tab2", "Tab3" },
    GLYPH = "Tab4",
}
MultiBot.TalentTabDefaults = MultiBot.TalentTabDefaults or { ACTIVE = "Tab5", ACTIVE_LABEL = "Talents" }
MultiBot.TalentTabLabels = MultiBot.TalentTabLabels or { GLYPHS = "Glyphs", CUSTOM_TALENTS = "Custom Talents", CUSTOM_GLYPHS = "Custom Glyphs", COPY = MultiBot.L("info.talent.Copy"), APPLY = MultiBot.L("info.talent.Apply") }
MultiBot.TalentTabStates = MultiBot.TalentTabStates or { TALENTS = "talents", GLYPHS = "glyphs", CUSTOM_TALENTS = "custom_talents", CUSTOM_GLYPHS = "custom_glyphs" }
MultiBot.TalentTabOffsets = MultiBot.TalentTabOffsets or { TALENTS = -715, GLYPHS = -615, CUSTOM_TALENTS = -515, CUSTOM_GLYPHS = -415, COPY = -315, APPLY = -315 }
MultiBot.TalentTabLimits = MultiBot.TalentTabLimits or { TREE_COUNT = 3, GLYPH_SOCKET_COUNT = 6, SOCKET_REQUIREMENTS = { 15, 15, 30, 50, 70, 80 } }
MultiBot.TalentTabHost = MultiBot.TalentTabHost or {
    BUTTONS = {
        [MultiBot.TalentTabStates.TALENTS] = { key = MultiBot.TalentTabDefaults.ACTIVE, label = MultiBot.TalentTabDefaults.ACTIVE_LABEL },
        [MultiBot.TalentTabStates.GLYPHS] = { key = MultiBot.TalentTabKeys.GLYPHS, label = MultiBot.TalentTabLabels.GLYPHS },
        [MultiBot.TalentTabStates.CUSTOM_TALENTS] = { key = MultiBot.TalentTabKeys.CUSTOM_TALENTS, label = MultiBot.TalentTabLabels.CUSTOM_TALENTS },
        [MultiBot.TalentTabStates.CUSTOM_GLYPHS] = { key = MultiBot.TalentTabKeys.CUSTOM_GLYPHS, label = MultiBot.TalentTabLabels.CUSTOM_GLYPHS },
    },
    TITLE_KEYS = {
        [MultiBot.TalentTabStates.GLYPHS] = "info.glyphsglyphsfor",
        [MultiBot.TalentTabStates.CUSTOM_TALENTS] = "info.talentscustomtalentsfor",
        [MultiBot.TalentTabStates.CUSTOM_GLYPHS] = "info.glyphscustomglyphsfor",
    },
    TITLE_DEFAULT = "Talents & Glyphs",
    SIZE = {
        CANVAS_WIDTH = 1024,
        CANVAS_HEIGHT = 1024,
        WIDTH = 620,
        HEIGHT = 570,
    },
    OFFSETS = {
        -- Centralized Y-offset tuning for legacy tab chrome while native layout is not enabled.
        HOST_TUNE_X = 0,
        HOST_BASE_Y = 84,
        HOST_TUNE_Y = -369,
        LEGACY_BASE_Y = -35,
        LEGACY_TUNE_Y = -5,
    },
}
MultiBot.TalentTabColors = MultiBot.TalentTabColors or { ACTIVE = { 1, 0.82, 0, 1 }, INACTIVE = { 0.5, 0.5, 0.5, 1 } }
MultiBot.TalentGlyphHostFlags = MultiBot.TalentGlyphHostFlags or { useNativeLayout = false }
MultiBot.TalentGlyphRoadmap = MultiBot.TalentGlyphRoadmap or {
    current = "switch_to_native_ace_layout",
    phase1Completed = true,
    -- Phase 1: keep behavior, isolate host/chrome responsibilities.
    "extract_host_chrome_adapter",
    -- Phase 2: anchor tabs/widgets directly in Ace host without legacy canvas offsets.
    "switch_to_native_ace_layout",
    -- Phase 3: remove legacy canvas bridge once native layout is validated.
    "remove_legacy_canvas_bridge",
}

function MultiBot.talent.setBottomTabVisualState(tabKey, isActive, labelOverride)
    local tab = MultiBot.talent.tabTextures[tabKey]
    if not tab then
        return
    end

    local color = isActive and MultiBot.TalentTabColors.ACTIVE or MultiBot.TalentTabColors.INACTIVE
    tab.left:SetVertexColor(color[1], color[2], color[3], color[4])
    tab.mid:SetVertexColor(color[1], color[2], color[3], color[4])
    tab.right:SetVertexColor(color[1], color[2], color[3], color[4])

    if tab.btn and tab.btn.text then
        local label = labelOverride or tab.btn.label
        if label then
            local textColor = isActive and "|cffffcc00" or "|cffaaaaaa"
            tab.btn.text:SetText(textColor .. label .. "|r")
        end
    end
end

function MultiBot.talent.setBottomTabVisibility(frameKey, visible)
    local frame = MultiBot.talent.frames and MultiBot.talent.frames[frameKey]
    if not frame then
        return
    end

    if visible then
        frame:Show()
    else
        frame:Hide()
    end
end

function MultiBot.talent.setTalentContentVisibility(showTalentTrees)
    for _, tabKey in ipairs(MultiBot.TalentTabGroups.TALENT_TREES) do
        local frame = MultiBot.talent.frames and MultiBot.talent.frames[tabKey]
        if frame then
            if showTalentTrees then
                frame:Show()
            else
                frame:Hide()
            end
        end
    end

    local glyphFrame = MultiBot.talent.frames and MultiBot.talent.frames[MultiBot.TalentTabGroups.GLYPH]
    if glyphFrame then
        if showTalentTrees then
            glyphFrame:Hide()
        else
            glyphFrame:Show()
        end
    end
end

function MultiBot.talent.setCopyTabMode(visible, active)
    MultiBot.talent.setBottomTabVisibility(MultiBot.TalentTabKeys.COPY, visible)
    if visible then
        MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabKeys.COPY, active == true, MultiBot.TalentTabLabels.COPY)
    end
end

function MultiBot.talent.hideApplyTab()
    if MultiBot.talent.applyTabBtn then
        MultiBot.talent.applyTabBtn.doHide()
    end
end

function MultiBot.talent.setPointsVisibility(show)
    local pointsText = MultiBot.talent.texts and MultiBot.talent.texts["Points"]
    if not pointsText then
        return
    end

    if show then
        pointsText:Show()
    else
        pointsText:Hide()
    end
end

function MultiBot.talent.setTalentTitleByKey(localizationKey)
    MultiBot.talent.setText("Title", "|cffffff00" .. MultiBot.L(localizationKey) .. " |r" .. (MultiBot.talent.name or "?"))
end

function MultiBot.talent.getTalentTreeFrame(treeIndex)
    local key = MultiBot.TalentTabGroups.TALENT_TREES[treeIndex]
    return key and MultiBot.talent.frames and MultiBot.talent.frames[key]
end

function MultiBot.talent.getGlyphSocket(socketIndex)
    local glyphFrame = MultiBot.talent.frames and MultiBot.talent.frames[MultiBot.TalentTabGroups.GLYPH]
    return glyphFrame and glyphFrame.frames and glyphFrame.frames["Socket" .. socketIndex]
end

function MultiBot.talent.hasCustomTalentSelection()
    for i = 1, MultiBot.TalentTabLimits.TREE_COUNT do
        local tTab = MultiBot.talent.getTalentTreeFrame(i)
        local tButtons = tTab and tTab.buttons
        if tButtons then
            for j = 1, table.getn(tButtons) do
                if (tButtons[j].value or 0) > 0 then
                    return true
                end
            end
        end
    end
    return false
end

function MultiBot.talent.hasCustomGlyphSelection()
    for i = 1, MultiBot.TalentTabLimits.GLYPH_SOCKET_COUNT do
        local socket = MultiBot.talent.getGlyphSocket(i)
        if (socket and socket.item or 0) > 0 then
            return true
        end
    end

    return false
end

function MultiBot.talent.refreshApplyTabVisibility()
    if not MultiBot.talent.applyTabBtn then
        return
    end

    local isCustomTalents = MultiBot.talent and MultiBot.talent.__activeTab == MultiBot.TalentTabStates.CUSTOM_TALENTS
    local isCustomGlyphs = MultiBot.talent and MultiBot.talent.__activeTab == MultiBot.TalentTabStates.CUSTOM_GLYPHS

    local shouldShow = (isCustomTalents and MultiBot.talent.hasCustomTalentSelection())
        or (isCustomGlyphs and MultiBot.talent.hasCustomGlyphSelection())
    if shouldShow then
        MultiBot.talent.applyTabBtn.doShow()
        MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabKeys.APPLY, true, MultiBot.TalentTabLabels.APPLY)
    else
        MultiBot.talent.applyTabBtn.doHide()
    end
end

function MultiBot.talent.getLayoutSize()
    local size = MultiBot.TalentTabHost and MultiBot.TalentTabHost.SIZE or {}
    return {
        canvasWidth = size.CANVAS_WIDTH or 1024,
        canvasHeight = size.CANVAS_HEIGHT or 1024,
        hostWidth = size.WIDTH or 620,
        hostHeight = size.HEIGHT or 570,
    }
end

function MultiBot.talent.getHostDefaultDimensions()
    local size = MultiBot.talent.getLayoutSize()
    return size.hostWidth, size.hostHeight
end

function MultiBot.talent.getLegacyCanvasDimensions()
    local size = MultiBot.talent.getLayoutSize()
    return size.canvasWidth, size.canvasHeight
end

function MultiBot.talent.getHostFrame(hostFrame)
    if hostFrame then
        return hostFrame
    end

    if MultiBot.talentAceHost and MultiBot.talentAceHost.host then
        return MultiBot.talentAceHost.host
    end

    return nil
end

function MultiBot.talent.getHostDimensions(hostFrame)
    local host = MultiBot.talent.getHostFrame(hostFrame)
    if not host then
        return 0, 0
    end

    local width = 0
    local height = 0

    local okW, valueW = pcall(function()
        return host:GetWidth()
    end)
    if okW and valueW then
        width = valueW
    end

    local okH, valueH = pcall(function()
        return host:GetHeight()
    end)
    if okH and valueH then
        height = valueH
    end

    local defaultHostWidth, defaultHostHeight = MultiBot.talent.getHostDefaultDimensions()
    if width <= 0 then
        width = defaultHostWidth
    end

    if height <= 0 then
        height = defaultHostHeight
    end

    return width, height
end

function MultiBot.talent.getLegacyHostOffsets(hostFrame)
    local host = MultiBot.talent.getHostFrame(hostFrame)
    if not host then
        return 0, 0
    end

    local hostWidth, hostHeight = MultiBot.talent.getHostDimensions(host)
    local legacyCanvasWidth, legacyCanvasHeight = MultiBot.talent.getLegacyCanvasDimensions()
    local legacyXOffset = math.floor((legacyCanvasWidth - hostWidth) / 2)
    local legacyYOffset = math.floor((legacyCanvasHeight - hostHeight) / 2)
    return legacyXOffset, legacyYOffset
end

function MultiBot.talent.getBottomTabXOffset(xOffset, hostFrame)
    local offsets = MultiBot.TalentTabHost and MultiBot.TalentTabHost.OFFSETS or {}
    local tuneX = offsets.HOST_TUNE_X or 0

    local host = MultiBot.talent.getHostFrame(hostFrame)
    if not host then
        return xOffset + tuneX
    end

    local legacyXOffset = select(1, MultiBot.talent.getLegacyHostOffsets(host))
    return xOffset + legacyXOffset + tuneX
end

function MultiBot.talent.getBottomTabHostYOffset(hostFrame)
    local offsets = MultiBot.TalentTabHost and MultiBot.TalentTabHost.OFFSETS or {}
    local baseY = offsets.HOST_BASE_Y or 84
    local tuneY = offsets.HOST_TUNE_Y or -369

    local host = MultiBot.talent.getHostFrame(hostFrame)
    if not host then
        return baseY
    end

    local legacyYOffset = select(2, MultiBot.talent.getLegacyHostOffsets(host))
    return baseY + legacyYOffset + tuneY
end

function MultiBot.talent.getBottomTabLegacyYOffset(hostFrame)
    local offsets = MultiBot.TalentTabHost and MultiBot.TalentTabHost.OFFSETS or {}
    local baseY = offsets.LEGACY_BASE_Y or -35
    local tuneY = offsets.LEGACY_TUNE_Y or -5

    local host = MultiBot.talent.getHostFrame(hostFrame)
    if not host then
        return baseY
    end

    local legacyYOffset = select(2, MultiBot.talent.getLegacyHostOffsets(host))
    return baseY + legacyYOffset + tuneY
end

local function attachTalentGlyphFrameToHost(hostFrame)
    if not hostFrame or not MultiBot.talent then
        return
    end

    MultiBot.talent:SetParent(hostFrame)
    MultiBot.talent:ClearAllPoints()
    MultiBot.talent:SetPoint("TOPLEFT", hostFrame, "TOPLEFT", 0, 0)
end

local function detachTalentLegacyFrameContent(hostFrame)
    if not hostFrame or not MultiBot.talent or MultiBot.talent.__aceDetached then
        return
    end

    if MultiBot.talent.texture then
        MultiBot.talent.texture:Hide()
    end

    local moveButton = MultiBot.talent.buttons and MultiBot.talent.buttons["Move"]
    if moveButton then
        moveButton:Hide()
    end

    for _, frameName in ipairs(MultiBot.TalentTabGroups.ALL) do
        local child = MultiBot.talent.frames and MultiBot.talent.frames[frameName]
        if child and child.SetParent then
            child:SetParent(hostFrame)
        end
    end

    for _, textName in ipairs({ "Points" }) do
        local region = MultiBot.talent.texts and MultiBot.talent.texts[textName]
        if region and region.SetParent then
            region:SetParent(hostFrame)
        end
    end

    if MultiBot.talent.texts and MultiBot.talent.texts["Title"] then
        MultiBot.talent.texts["Title"]:Hide()
    end
    MultiBot.talent.__aceDetached = true
end

local function ensureTalentGlyphAceHost()
    if MultiBot.talentAceHost then
        return MultiBot.talentAceHost
    end

    local aceGUI = resolveAceGUI("AceGUI-3.0 is required for MB_TalentGlyphHost")
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(MultiBot.TalentTabHost.TITLE_DEFAULT)
    local hostDefaultWidth, hostDefaultHeight = MultiBot.talent.getHostDefaultDimensions()
    window:SetWidth(hostDefaultWidth)
    window:SetHeight(hostDefaultHeight)
    window:EnableResize(false)
    window:SetLayout("Fill")
    window.frame:SetFrameStrata("DIALOG")
    registerAceWindowEscapeClose(window, "TalentGlyphHost")
    bindAceWindowPosition(window, "talent_glyph_host")
    window:SetCallback("OnClose", function()
        if MultiBot.talent and MultiBot.talent.Hide then
            MultiBot.talent:Hide()
        else
            window:Hide()
        end
    end)

    local host = CreateFrame("Frame", nil, window.content)
    host:SetPoint("TOPLEFT", window.content, "TOPLEFT", 0, 0)
    host:SetPoint("TOPRIGHT", window.content, "TOPRIGHT", 0, 0)
    host:SetPoint("BOTTOM", window.content, "BOTTOM", 0, 0)
    if host.SetClipsChildren then
        host:SetClipsChildren(false)
    end

    local function showLegacyTalentTabChrome()
        local hostStrata = host:GetFrameStrata() or "DIALOG"
        local hostLevel = host:GetFrameLevel() or 0
        for _, frameName in ipairs(MultiBot.TalentTabGroups.CHROME) do
            local legacyTab = MultiBot.talent.frames and MultiBot.talent.frames[frameName]
            if legacyTab and legacyTab.SetPoint and legacyTab.ClearAllPoints then
                local owner = legacyTab:GetParent()
                legacyTab:ClearAllPoints()
                local xOffset = legacyTab.mbXOffset or 0
                legacyTab:SetPoint("BOTTOMRIGHT", owner, "BOTTOMRIGHT", MultiBot.talent.getBottomTabXOffset(xOffset, host), MultiBot.talent.getBottomTabHostYOffset(host))
                legacyTab:SetFrameStrata(hostStrata)
                legacyTab:SetFrameLevel(hostLevel + 2)
                if frameName ~= MultiBot.TalentTabKeys.APPLY then
                    legacyTab:Show()
                end
            end

            local buttonSet = legacyTab and legacyTab.buttons
            if buttonSet then
                for _, button in pairs(buttonSet) do
                    if button and button.Show and frameName ~= MultiBot.TalentTabKeys.APPLY then
                        button:Show()
                    end
                end
            end
        end

        MultiBot.talent.refreshApplyTabVisibility()
    end

    local function showTalentTabChrome()
        -- Native layout path is roadmap-only for now; keep legacy adapter until phase-2 migration.
        if MultiBot.TalentGlyphHostFlags and MultiBot.TalentGlyphHostFlags.useNativeLayout == true then
            showLegacyTalentTabChrome()
            return
        end

        showLegacyTalentTabChrome()
    end

    local function buildLegacyHostTabButtons()
        local buttons = {}
        for state, hostTab in pairs(MultiBot.TalentTabHost.BUTTONS) do
            local frame = MultiBot.talent.frames and MultiBot.talent.frames[hostTab.key]
            buttons[state] = frame and frame.buttons and frame.buttons[hostTab.label]
        end
        return buttons
    end

    host.mbLegacyTabButtons = buildLegacyHostTabButtons()

    local function getTalentHostTitle(value)
        local botName = MultiBot.talent and MultiBot.talent.name or "NAME"
        local titleKey = MultiBot.TalentTabHost.TITLE_KEYS[value]
        if titleKey then
            return MultiBot.L(titleKey) .. " " .. botName
        end

        return MultiBot.doReplace(MultiBot.L("info.talent.Title"), "NAME", botName)
    end

    local function activateLegacyTab(value)
        local button = host.mbLegacyTabButtons and host.mbLegacyTabButtons[value]
        if button and button.doLeft then
            button.doLeft(button)
        end

        showTalentTabChrome()
        if MultiBot.talent.texts and MultiBot.talent.texts["Title"] then
            MultiBot.talent.texts["Title"]:Hide()
        end		
        window:SetTitle(getTalentHostTitle(value) or MultiBot.TalentTabHost.TITLE_DEFAULT)
    end

    attachTalentGlyphFrameToHost(host)
    detachTalentLegacyFrameContent(host)
    showTalentTabChrome()
    activateLegacyTab(MultiBot.TalentTabStates.TALENTS)

    -- Keep Talents tab active by default.
    MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabDefaults.ACTIVE, true, MultiBot.TalentTabDefaults.ACTIVE_LABEL)

    -- Keep other tabs inactive by default.
    for _, key in ipairs(MultiBot.TalentTabGroups.INACTIVE_DEFAULT) do
        MultiBot.talent.setBottomTabVisualState(key, false)
    end

    MultiBot.talentAceHost = {
        window = window,
        host = host,
    }

    return MultiBot.talentAceHost
end

do
    local originalHide = MultiBot.talent.Hide
    local originalIsShown = MultiBot.talent.IsShown

    MultiBot.talent.Show = function(self)
        local host = ensureTalentGlyphAceHost()
        if host and host.host then
            attachTalentGlyphFrameToHost(host.host)
            detachTalentLegacyFrameContent(host.host)
        end
        if host and host.window then
            host.window:Show()
        end

        if originalHide then
            originalHide(self)
        end
        return self
    end

    MultiBot.talent.Hide = function(self)
        if MultiBot.talentAceHost and MultiBot.talentAceHost.window then
            MultiBot.talentAceHost.window:Hide()
        end

        if originalHide then
            return originalHide(self)
        end
        return self
    end

    MultiBot.talent.IsShown = function(self)
        if MultiBot.talentAceHost and MultiBot.talentAceHost.window and MultiBot.talentAceHost.window.frame then
            return MultiBot.talentAceHost.window.frame:IsShown()
        end

        if originalIsShown then
            return originalIsShown(self)
        end

        return false
    end
end

function MultiBot.talent.buildTalentApplyValues()
	local tValues = ""

	for i = 1, MultiBot.TalentTabLimits.TREE_COUNT do
		local tTab = MultiBot.talent.getTalentTreeFrame(i)
		for j = 1, table.getn(tTab.buttons) do
			tValues = tValues .. tTab.buttons[j].value
		end
		if(i < 3) then tValues = tValues .. "-" end
	end

	return tValues
end

function MultiBot.talent.applyCustomTalents()
	SendChatMessage("talents apply " .. MultiBot.talent.buildTalentApplyValues(), "WHISPER", nil, MultiBot.talent.name)
end

function MultiBot.talent.copyCustomTalentsToTarget()
	local tName = UnitName("target")
	if(tName == nil or tName == "Unknown Entity") then return SendChatMessage(MultiBot.L("info.target"), "SAY") end

	local _, tClass = UnitClass("target")
	if(MultiBot.talent.class ~= MultiBot.toClass(tClass)) then return SendChatMessage("The Classes do not match.", "SAY") end

	local tUnit = MultiBot.toUnit(MultiBot.talent.name)
	if(UnitLevel(tUnit) ~= UnitLevel("target")) then return SendChatMessage("The Levels do not match.", "SAY") end

	SendChatMessage("talents apply " .. MultiBot.talent.buildTalentApplyValues(), "WHISPER", nil, tName)
end

-- Tab1, Tab2, Tab3 dans des blocs do...end pour libérer les locals
do
    local tTab = MultiBot.talent.addFrame("Tab1", -830, 518, 28, 170, 408)
    tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
    tTab.addText("Title", MB_TAB_TITLE_DEFAULT, "CENTER", 0, 214, 13)
    tTab.arrows = {}
    tTab.value = 0
    tTab.id = 1
end

do
    local tTab = MultiBot.talent.addFrame("Tab2", -656, 518, 28, 170, 408)
    tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
    tTab.addText("Title", MB_TAB_TITLE_DEFAULT, "CENTER", 0, 214, 13)
    tTab.arrows = {}
    tTab.value = 0
    tTab.id = 2
end

do
    local tTab = MultiBot.talent.addFrame("Tab3", -482, 518, 28, 170, 408)
    tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
    tTab.addText("Title", MB_TAB_TITLE_DEFAULT, "CENTER", 0, 214, 13)
    tTab.arrows = {}
    tTab.value = 0
    tTab.id = 3
end

-- ACTUAL GLYPHES START --

-- Minimum level for each socket (in order 1→6) is centralized in TalentTabLimits.SOCKET_REQUIREMENTS.

local function ShowGlyphTooltip(self)
    local id = self.glyphID
    if not id then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    if GameTooltip:SetSpellByID(id) then
        return
    end

    GameTooltip:SetHyperlink("item:"..id..":0:0:0:0:0:0:0")
end

local function HideGlyphTooltip()
    GameTooltip:Hide()
end

function MultiBot.FillDefaultGlyphs()
    local botName = MultiBot.talent.name
    local unit    = MultiBot.toUnit(botName)
    if not unit then return end

    local rec = MultiBot.receivedGlyphs and MultiBot.receivedGlyphs[botName]
    if not rec then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MultiBot]|r Waiting for glyphs…")
        return
    end

    local _, classFile = UnitClass(unit)
    local classKey = (classFile == "DEATHKNIGHT" and "DeathKnight")
                   or (classFile:sub(1,1) .. classFile:sub(2):lower())
    local glyphDB = MultiBot.data.talent.glyphs[classKey] or {}

    for i, entry in ipairs(rec) do
        local id, typ = entry.id, entry.type
        local f = MultiBot.talent.getGlyphSocket(i)
        if f and f.frames then
            f.type, f.item = typ, id
            f.frames.Glow:Show()

            local raw = glyphDB[typ] and glyphDB[typ][id] or ""
            local _, runeIdx = strsplit(",%s*", raw)
            runeIdx = runeIdx or "1"
            local rFrame = f.frames.Rune
            if rFrame then
                rFrame:Hide()
                local runeTex = rFrame.texture or rFrame
                runeTex:SetTexture(MultiBot.SafeTexturePath("Interface\\Spellbook\\UI-Glyph-Rune"..runeIdx))
            end

            local tex = GetSpellTexture(id)
                     or select(10, GetItemInfo(id))
					 or "Interface\\AddOns\\MultiBot\\Textures\\UI-GlyphFrame-Glow.blp"
            local btn = f.frames.IconBtn
            if not btn then
                btn = CreateFrame("Button", nil, f)
                btn:SetAllPoints(f)
                btn:SetScript("OnEnter", ShowGlyphTooltip)
                btn:SetScript("OnLeave", HideGlyphTooltip)

                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", btn, "CENTER", -9, 8)

                local factor = (typ == "Major") and 0.64 or 0.66
                icon:SetSize(f:GetWidth() * factor, f:GetHeight() * factor)

                local crop = (typ == "Major") and 0.14 or 0.20
                icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)

                btn.icon = icon
                f.frames.IconBtn = btn
            end

            btn.glyphID = id
            btn.icon:SetTexture(MultiBot.SafeTexturePath(tex))
            btn:Show()

            local ov = f.frames.Overlay
            if ov and not ov.texture then
                ov.texture = ov:CreateTexture(nil, "BORDER")
                ov.texture:SetAllPoints(ov)
                local base = "Interface\\AddOns\\MultiBot\\Textures\\"
                ov.texture:SetTexture(
                    base .. (typ == "Major"
                            and "gliph_majeur_layout.blp"
                            or "gliph_mineur_layout.blp"))
            end
            if ov then ov:Show() end
        end
    end

    local names = {}
    for _, entry in ipairs(rec) do
        local n = select(1, GetItemInfo(entry.id))
              or GetSpellInfo(entry.id)
              or ("ID "..entry.id)
        table.insert(names,
            (entry.type=="Major" and "|cffffff00" or "|cff00ff00") .. n .. "|r")
    end
end

-- Tab4 dans un bloc do...end
do
    local tTab = MultiBot.talent.addFrame("Tab4", -513, 518, 28, 456, 430)
    tTab.addFrame("Glow", 0, 0, 28, 456, 430).setAlpha(0.5).doHide()
    tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Background-GlyphFrame.blp")
    tTab:Hide()
end

-- Legacy glyph apply button removed from UI; Apply tab is now the only entry point.
function MultiBot.talent.applyCustomGlyphs()
    local ids = {}
    for i = 1, MultiBot.TalentTabLimits.GLYPH_SOCKET_COUNT do
        local socket = MultiBot.talent.getGlyphSocket(i)
        ids[i] = (socket and socket.item) or 0
    end
    local payload = "glyph equip " .. table.concat(ids, " ")
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[DBG]|r " ..
        (MultiBot.talent.name or "?") .. " : " .. payload)
    SendChatMessage(payload, "WHISPER", nil, MultiBot.talent.name)
end


-- Define glyph sockets from a compact descriptor list to limit local declarations.
local glyphSocketDefinitions = {
    { name = "Socket1", x = -176.5, y = 310,   size = 102, glow = "Interface/Spellbook/UI-Glyph-Slot-Major.blp", runeX = -29, runeY = 29, runeSize = 44,  overlayX = -12, overlayY = 12, overlaySize = 96, socketType = "Major" },
    { name = "Socket2", x = -187,   y = 18.5,  size = 82,  glow = "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp", runeX = -25, runeY = 25, runeSize = 32,  overlayX = -9,  overlayY = 9,  overlaySize = 80, socketType = "Minor" },
    { name = "Socket3", x = -18.5,  y = 50.5,  size = 102, glow = "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp", runeX = -29, runeY = 29, runeSize = 44,  overlayX = -12, overlayY = 12, overlaySize = 96, socketType = "Major" },
    { name = "Socket4", x = -302.5, y = 218,   size = 82,  glow = "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp", runeX = -25, runeY = 25, runeSize = 32,  overlayX = -9,  overlayY = 9,  overlaySize = 80, socketType = "Minor" },
    { name = "Socket5", x = -72.5,  y = 218,   size = 82,  glow = "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp", runeX = -25, runeY = 25, runeSize = 32,  overlayX = -9,  overlayY = 9,  overlaySize = 80, socketType = "Minor" },
    { name = "Socket6", x = -336,   y = 50.5,  size = 102, glow = "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp", runeX = -29, runeY = 29, runeSize = 44,  overlayX = -12, overlayY = 12, overlaySize = 96, socketType = "Major" },
}

for _, def in ipairs(glyphSocketDefinitions) do
    local tGlyph = MultiBot.talent.frames[MultiBot.TalentTabGroups.GLYPH].addFrame(def.name, def.x, def.y, def.size)
    tGlyph.addFrame("Glow", 0, 0, def.size).setLevel(7).doHide().addTexture(def.glow)
    tGlyph.addFrame("Rune", def.runeX, def.runeY, def.runeSize).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
    tGlyph.frames = tGlyph.frames or {}
    tGlyph.type = def.socketType
    tGlyph.item = 0
    tGlyph.addFrame("Overlay", def.overlayX, def.overlayY, def.overlaySize).setLevel(9).doHide()
end

local function addTalentBottomTab(frameKey, buttonLabel, xOffset)
    local tabFrame = MultiBot.talent.addFrame(frameKey, xOffset, MultiBot.talent.getBottomTabLegacyYOffset(), 28, 96, 24)
    tabFrame.mbXOffset = xOffset
    tabFrame.buttons = tabFrame.buttons or {}

    local bgLeft = tabFrame:CreateTexture(nil, "BACKGROUND")
    bgLeft:SetTexture("Interface\\ChatFrame\\ChatFrameTab-BGLeft")
    bgLeft:SetTexCoord(0, 1, 1, 0)
    bgLeft:SetWidth(16)
    bgLeft:SetHeight(32)
    bgLeft:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 0, -4)

    local bgMid = tabFrame:CreateTexture(nil, "BACKGROUND")
    bgMid:SetTexture("Interface\\ChatFrame\\ChatFrameTab-BGMid")
    bgMid:SetTexCoord(0, 1, 1, 0)
    bgMid:SetHeight(32)
    bgMid:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 16, -4)
    bgMid:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -16, -4)

    local bgRight = tabFrame:CreateTexture(nil, "BACKGROUND")
    bgRight:SetTexture("Interface\\ChatFrame\\ChatFrameTab-BGRight")
    bgRight:SetTexCoord(0, 1, 1, 0)
    bgRight:SetWidth(16)
    bgRight:SetHeight(32)
    bgRight:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", 0, -4)

    tabFrame.texLeft  = bgLeft
    tabFrame.texMid   = bgMid
    tabFrame.texRight = bgRight

    local tabButton = CreateFrame("Button", "MBTab_"..frameKey, tabFrame)
    tabButton:SetPoint("BOTTOMLEFT", tabFrame, "BOTTOMLEFT", 0, -4)
    tabButton:SetSize(96, 32)
    tabButton:SetFrameLevel(tabFrame:GetFrameLevel() + 1)
    tabButton:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    tabButton:EnableMouse(true)
    tabButton.parent = tabFrame
    tabButton.state  = true

    tabButton.text = tabButton:CreateFontString(nil, "ARTWORK")
    tabButton.text:SetFont("Fonts\\ARIALN.ttf", 11, "OUTLINE")
    tabButton.text:SetPoint("CENTER", 0, 8)
    tabButton.text:SetText("|cffffcc00" .. buttonLabel .. "|r")

    tabButton.text:Show()

    tabButton.doHide = function()
        tabFrame:Hide()
        tabButton:Hide()
        if MultiBot.RequestClickBlockerUpdate then MultiBot.RequestClickBlockerUpdate(tabFrame) end
        return tabButton
    end

    tabButton.doShow = function()
        tabFrame:Show()
        tabButton:Show()
        if MultiBot.RequestClickBlockerUpdate then MultiBot.RequestClickBlockerUpdate(tabFrame) end
        return tabButton
    end

    tabButton:SetScript("OnLeave", function()
        tabButton.text:SetPoint("CENTER", 0, 8)
    end)

    MultiBot.talent.tabTextures[frameKey] = { left = bgLeft, mid = bgMid, right = bgRight, btn = tabButton }

    tabButton:SetScript("OnClick", function(_, mouseButton)
        tabButton.text:SetPoint("CENTER", -1, 7)

        for _, key in ipairs(MultiBot.TalentTabGroups.BOTTOM) do
            MultiBot.talent.setBottomTabVisualState(key, false)
        end

        MultiBot.talent.setBottomTabVisualState(frameKey, true, buttonLabel)

        if mouseButton == "RightButton" and tabButton.doRight then tabButton.doRight(tabButton) end
        if mouseButton == "LeftButton"  and tabButton.doLeft  then tabButton.doLeft(tabButton)  end
    end)

    tabButton.label = buttonLabel
    return tabButton
end

-- TAB TALENTS --
MultiBot.talent.talentsTabBtn = addTalentBottomTab(MultiBot.TalentTabDefaults.ACTIVE, MultiBot.TalentTabDefaults.ACTIVE_LABEL, MultiBot.TalentTabOffsets.TALENTS)
MultiBot.talent.talentsTabBtn.doLeft = function()
	if MultiBot.talent and MultiBot.talent.__activeTab == MultiBot.TalentTabStates.CUSTOM_TALENTS then
		MultiBot.talent.setTalents()
	end
	MultiBot.talent.__activeTab = MultiBot.TalentTabStates.TALENTS
    MultiBot.talent.setText("Title", MultiBot.doReplace(MultiBot.L("info.talent.Title"), "NAME", MultiBot.talent.name))
    MultiBot.talent.setPointsVisibility(true)
    MultiBot.talent.setTalentContentVisibility(true)
    MultiBot.talent.setCopyTabMode(true, true)
    MultiBot.talent.hideApplyTab()
end

-- TAB GLYPHS --
MultiBot.talent.glyphsTabBtn = addTalentBottomTab(MultiBot.TalentTabKeys.GLYPHS, MultiBot.TalentTabLabels.GLYPHS, MultiBot.TalentTabOffsets.GLYPHS)
MultiBot.talent.glyphsTabBtn.doLeft = function()
	MultiBot.talent.__activeTab = MultiBot.TalentTabStates.GLYPHS
    MultiBot.talent.setTalentTitleByKey("info.glyphsglyphsfor")
    MultiBot.talent.setPointsVisibility(false)
    MultiBot.talent.setTalentContentVisibility(false)
    MultiBot.talent.setCopyTabMode(false, false)
	MultiBot.awaitGlyphs = MultiBot.talent.name
	SendChatMessage("glyphs", "WHISPER", nil, MultiBot.talent.name)
	MultiBot.talent.hideApplyTab()
end

-- GLYPHES END --

MultiBot.talent.setGrid = function(pTab)
	pTab.grid = {}
	pTab.grid.icons = {}
	pTab.grid.icons.size = pTab.size + 8
	pTab.grid.icons.x = pTab.width / 2 + pTab.grid.icons.size * 2 + 4
	pTab.grid.icons.y = pTab.height / 2 + pTab.grid.icons.size * 5.5 + 4
	pTab.grid.arrows = {}
	pTab.grid.arrows.size = pTab.grid.icons.size + 8
	pTab.grid.arrows.x = pTab.width / 2 + pTab.grid.icons.size * 2 - 4
	pTab.grid.arrows.y = pTab.height / 2 + pTab.grid.icons.size * 5.5 - 4
	pTab.grid.values = {}
	pTab.grid.values.x = pTab.width / 2 + pTab.grid.icons.size * 2
	pTab.grid.values.y = pTab.height / 2 + pTab.grid.icons.size * 5.5
	return pTab
end

MultiBot.talent.addArrow = function(pTab, pID, pNeeds, piX, piY, pTexture)
	local tArrow = pTab.addFrame("Arrow" .. pID, piX * pTab.grid.icons.size - pTab.grid.arrows.x, pTab.grid.arrows.y - piY * pTab.grid.icons.size, pTab.grid.arrows.size)
	tArrow.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_Silver_" .. pTexture .. ".blp")
	tArrow.active = "Interface\\AddOns\\MultiBot\\Textures\\Talent_Gold_" .. pTexture .. ".blp"
	tArrow.needs = pNeeds
	tArrow:SetFrameLevel(7)
	return tArrow
end

MultiBot.talent.addTalent = function(pTab, pID, pNeeds, pValue, pMax, piX, piY, pTexture, pTips)
	local tTalent = pTab.addButton(pID, piX * pTab.grid.icons.size - pTab.grid.icons.x, pTab.grid.icons.y - piY * pTab.grid.icons.size, pTexture, pTips[pValue + 1])
    tTalent:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	tTalent.points = piY * 5 - 5
	tTalent.needs = pNeeds
	tTalent.value = pValue
	tTalent.tips = pTips
	tTalent.max = pMax
	tTalent.id = pID

	tTalent.doLeft = function(pButton)
		if(MultiBot.talent.points == 0) then return end

		local tButtons = pButton.parent.buttons
		local tValue = pButton.parent.frames[pButton.id]
		local tTab = pButton.parent

		if(pButton.state == false) then return end
		if(pButton.value == pButton.max) then return end
		if(pButton.needs > 0 and tButtons[pButton.needs].value == 0) then return end

		MultiBot.talent.points = MultiBot.talent.points - 1
		MultiBot.talent.setText("Points", MultiBot.L("info.talent.Points") .. MultiBot.talent.points)

		tTab.value = tTab.value + 1
		tTab.setText("Title", MultiBot.L("info.talent." .. pButton.getClass() .. tTab.id) .. " ("  .. tTab.value .. ")")

		pButton.value = pButton.value + 1
		pButton.tip = pButton.tips[pButton.value + 1]

		local tColor = MultiBot.IF(pButton.value < pButton.max, "|cff4db24d", "|cffffcc00")
		tValue.setText("Value", tColor .. pButton.value .. "/" .. pButton.max .. "|r")
		tValue:Show()

		for i = 1, table.getn(tButtons) do
			if(tButtons[i].points > tTab.value)
			then tButtons[i].setDisable()
			else
				if(tButtons[i].needs > 0)
				then if(tButtons[tButtons[i].needs].value > 0) then tButtons[i].setEnable() end
				else tButtons[i].setEnable()
				end
			end
		end

		MultiBot.talent.refreshApplyTabVisibility()
		MultiBot.talent.doState()
	end

	tTalent.doRight = function(pButton)
		if pButton.value == 0 then return end

		local tTab   = pButton.parent
		local tValue = tTab.frames[pButton.id]

		MultiBot.talent.points = MultiBot.talent.points + 1
		MultiBot.talent.setText("Points",
			MultiBot.L("info.talent.Points") .. MultiBot.talent.points)

		pButton.value = pButton.value - 1
		pButton.tip   = pButton.tips[pButton.value + 1]
		tTab.value    = tTab.value  - 1
		tTab.setText("Title",
			MultiBot.L("info.talent." .. pButton.getClass() .. tTab.id) ..
			" (" .. tTab.value .. ")")

		local c = (pButton.value == 0)      and "|cffffffff"
			or (pButton.value < pButton.max) and "|cff4db24d"
			or "|cffffcc00"
		tValue.setText("Value",
			c .. pButton.value .. "/" .. pButton.max .. "|r")
		if MultiBot.talent.points == 0 and pButton.value == 0 then
			tValue:Hide()
		else
			tValue:Show()
		end

		MultiBot.talent.doState()
		MultiBot.talent.refreshApplyTabVisibility()
	end
	tTalent:SetFrameLevel(8)
	return tTalent
end

MultiBot.talent.addValue = function(pTab, pID, piX, piY, pRank, pMax)
	local tColor = MultiBot.IF(pRank > 0, MultiBot.IF(pRank < pMax, "|cff4db24d", "|cffffcc00"), "|cffffffff")
	local tValue = pTab.addFrame(pID, piX * pTab.grid.icons.size - pTab.grid.values.x, pTab.grid.values.y - piY * pTab.grid.icons.size, 24, 18, 12)
	tValue.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_Black.blp")
	tValue.addText("Value", tColor .. pRank .. "/" .. pMax .. "|r", "CENTER", -0.5, 1, 10)
	if(MultiBot.talent.points == 0 and pRank == 0) then tValue:Hide() end
	tValue:SetFrameLevel(9)
	return tValue
end

MultiBot.talent.setTalents = function()
    local tClass = MultiBot.data.talent.talents[ MultiBot.talent.class ]
    if not tClass then
        print("|cffff0000[MultiBot] No build found for class "
              .. tostring(MultiBot.talent.class) .. "!|r")
        return
    end

    local tArrow = MultiBot.data.talent.arrows[ MultiBot.talent.class ]
    if not tArrow then
        print("|cffff0000[MultiBot] No arrow schem found for class "
              .. tostring(MultiBot.talent.class) .. "!|r")
        return
    end

	local activeGroup = GetActiveTalentGroup(true) or 1

    if not GetTalentInfo(1, 1, true) then
        TimerAfter(0.1, MultiBot.talent.setTalents)
        return
    end

    MultiBot.talent.points = tonumber(GetUnspentTalentPoints(true))
    MultiBot.talent.setText("Points",
       MultiBot.L("info.talent.Points") .. MultiBot.talent.points)
    MultiBot.talent.setText("Title",
        MultiBot.doReplace(MultiBot.L("info.talent.Title"), "NAME",
                           MultiBot.talent.name))

    for i = 1, MultiBot.TalentTabLimits.TREE_COUNT do
        local tMarker = MultiBot.talent.class .. i
        local tTab    = MultiBot.talent.setGrid(MultiBot.talent.getTalentTreeFrame(i))
        tTab.setTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_" ..
                        tMarker .. ".blp")
        tTab.value, tTab.id = 0, i

        for j = 1, #tArrow[i] do
            local tData = MultiBot.doSplit(tArrow[i][j], ", ")
            local tNeed = tonumber(tData[1])
            tTab.arrows[j] = MultiBot.talent.addArrow(
                                 tTab, j, tNeed, tData[2], tData[3], tData[4])
        end

        for j = 1, #tClass[i] do
            local link = GetTalentLink(i,j,true,nil,activeGroup)
            local tTale = MultiBot.doSplit(MultiBot.doSplit(link, "|")[3], ":")[2]
            local iName, iIcon, iTier, iColumn, iRank = GetTalentInfo(i, j, true, nil, activeGroup)

            if not iName then
                TimerAfter(0.1, MultiBot.talent.setTalents)
                return
            end

            local tData = MultiBot.doSplit(tClass[i][j], ", ")
            local tMax  = #tData - 4
            local tNeed = tonumber(tData[1])
            local tRank = tonumber(iRank)
            local tTips = {}

            tTab.value = tTab.value + tRank
            table.insert(tTips,
                "|cff4e96f7|Htalent:" .. tTale ..":-1|h[" .. iName .. "]|h|r")
            for k = 5, #tData do
                table.insert(tTips,
                    "|cff4e96f7|Htalent:" .. tTale ..":" .. (k - 5) ..
                    "|h[" .. iName .. "]|h|r")
            end

            MultiBot.talent.addTalent(
                tTab, j, tNeed, tRank, tMax,
                tData[2], tData[3], tData[4], tTips)
            MultiBot.talent.addValue(
                tTab, j, tData[2], tData[3], tRank, tMax)
        end

        tTab.setText("Title",
            MultiBot.L("info.talent." .. tMarker) .. " (" .. tTab.value .. ")")
    end

    MultiBot.talent.doState()
	MultiBot.talent:Show()
	MultiBot.auto.talent = false
end

MultiBot.talent.doState = function()
	for i = 1, MultiBot.TalentTabLimits.TREE_COUNT do
		local tTab = MultiBot.talent.getTalentTreeFrame(i)

		for j = 1, table.getn(tTab.buttons) do
			local tTalent = tTab.buttons[j]
			local tValue = tTab.frames[j]

			if(MultiBot.talent.points == 0) then
				if(tTalent.value == 0) then
					tTalent.setDisable(false)
					tValue:Hide()
				else
					tTalent.setEnable(false)
					tValue:Show()
				end
			else
				if(tTab.value < tTalent.points) then
					tTalent.setDisable(false)
					tValue:Hide()
				else
					tTalent.setEnable(false)
					tValue:Show()
				end
			end
		end

		for j = 1, table.getn(tTab.arrows) do
			if(tTab.buttons[tTab.arrows[j].needs].value > 0) then
				tTab.arrows[j].setTexture(tTab.arrows[j].active)
			end
		end
	end
end

MultiBot.talent.doClear = function()
	for i = 1, MultiBot.TalentTabLimits.TREE_COUNT do
		local tTab = MultiBot.talent.getTalentTreeFrame(i)
		for j = 1, table.getn(tTab.buttons) do tTab.buttons[j]:Hide() end
		for j = 1, table.getn(tTab.frames) do tTab.frames[j]:Hide() end
		for j = 1, table.getn(tTab.arrows) do tTab.arrows[j]:Hide() end
		table.wipe(tTab.buttons)
		table.wipe(tTab.frames)
		table.wipe(tTab.arrows)
		tTab.buttons = {}
		tTab.frames = {}
		tTab.arrows = {}
	end
end

--[[
Add a custom tab to talents windows to make custom builds (Tab7)
]]--

MultiBot.talent.customTalentsTabBtn = addTalentBottomTab(MultiBot.TalentTabKeys.CUSTOM_TALENTS, MultiBot.TalentTabLabels.CUSTOM_TALENTS, MultiBot.TalentTabOffsets.CUSTOM_TALENTS)

function MultiBot.talent.setTalentsCustom()
    if not GetTalentInfo(1, 1, true) then
        TimerAfter(0.05, MultiBot.talent.setTalentsCustom)
        return
    end
    MultiBot.talent.doClear()

    local tClass = MultiBot.data.talent.talents[ MultiBot.talent.class ]
    local tArrow = MultiBot.data.talent.arrows[  MultiBot.talent.class ]
    if not (tClass and tArrow) then
        print("|cffff0000[MultiBot] Class data missing for custom talents!|r")
        return
    end

    local unit  = MultiBot.toUnit(MultiBot.talent.name)
    local level = UnitLevel(unit) or 80
    MultiBot.talent.points = math.max(level - 9, 0)

    MultiBot.talent.setText("Points",   MultiBot.L("info.talent.Points") .. MultiBot.talent.points)
	MultiBot.talent.setTalentTitleByKey("info.talentscustomtalentsfor")

    for i = 1, MultiBot.TalentTabLimits.TREE_COUNT do
        local marker = MultiBot.talent.class .. i
        local pTab   = MultiBot.talent.setGrid(MultiBot.talent.getTalentTreeFrame(i))
        pTab.setTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_"..marker..".blp")
        pTab.value, pTab.id = 0, i

        for j = 1, #tArrow[i] do
            local d = MultiBot.doSplit(tArrow[i][j], ", ")
            local need = tonumber(d[1])
            pTab.arrows[j] = MultiBot.talent.addArrow(pTab, j, need, d[2], d[3], d[4])
        end

        for j = 1, #tClass[i] do
            local data = MultiBot.doSplit(tClass[i][j], ", ")
            local max  = #data - 4
            local need = tonumber(data[1])
            local tips = {}
            local link = GetTalentLink(i,j,true)
            local tale = MultiBot.doSplit(MultiBot.doSplit(link,"|")[3],":")[2]
            local name = GetTalentInfo(i, j, true)
            table.insert(tips, "|cff4e96f7|Htalent:"..tale..":-1|h["..name.."]|h|r")
            for k=5,#data do
                table.insert(tips, "|cff4e96f7|Htalent:"..tale..":"..(k-5) .."|h["..name.."]|h|r")
            end

            MultiBot.talent.addTalent(pTab, j, need, 0, max, data[2], data[3], data[4], tips)
            MultiBot.talent.addValue (pTab, j, data[2], data[3], 0, max)
        end

        pTab.setText("Title", MultiBot.L("info.talent." .. marker) .. " (0)")
    end

    MultiBot.talent.setPointsVisibility(true)
    MultiBot.talent.setTalentContentVisibility(true)
	MultiBot.talent.setCopyTabMode(false, false)
	MultiBot.talent.__activeTab = MultiBot.TalentTabStates.CUSTOM_TALENTS
	MultiBot.talent.refreshApplyTabVisibility()
    MultiBot.talent.doState()
    MultiBot.talent:Show()
end

MultiBot.talent.customTalentsTabBtn.doLeft = function()
    MultiBot.talent.setTalentsCustom()
end

-- END TAB CUSTOM TALENTS --

--[[
Add a new tab to use custom Glyphs (Tab8)
]]--

MultiBot.talent.customGlyphsTabBtn = addTalentBottomTab(MultiBot.TalentTabKeys.CUSTOM_GLYPHS, MultiBot.TalentTabLabels.CUSTOM_GLYPHS, MultiBot.TalentTabOffsets.CUSTOM_GLYPHS)

local function GetGlyphItemType(itemID)
    if not MultiBot.talent.glyphTip then
        MultiBot.talent.glyphTip = ensureHiddenTooltip("MBHiddenTip", UIParent)
    end
    MultiBot.talent.glyphTip:ClearLines()
    MultiBot.talent.glyphTip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
    for i = 2, MultiBot.talent.glyphTip:NumLines() do
        local line = _G[MultiBot.talent.glyphTip:GetName().."TextLeft"..i]
        local txt = (line and line:GetText() or ""):lower()
        if txt:find("major glyph") then return "Major" end
        if txt:find("minor glyph") then return "Minor" end
    end
    return nil
end

function MultiBot.BuildGlyphClassTable()
    if MultiBot.__glyphClass then return end
    if not MultiBot.data or not MultiBot.data.talent or not MultiBot.data.talent.glyphs then return end
    MultiBot.__glyphClass = {}
    for clsKey, data in pairs(MultiBot.data.talent.glyphs) do
        for id in pairs(data.Major or {}) do
            MultiBot.__glyphClass[id] = clsKey
        end
        for id in pairs(data.Minor or {}) do
            MultiBot.__glyphClass[id] = clsKey
        end
    end
end

local function ClearGlyphSocket(socketFrame)
    socketFrame.item = 0

    if socketFrame.frames.Rune  then socketFrame.frames.Rune:Hide()  end
    if socketFrame.frames.IconBtn then
        local btn = socketFrame.frames.IconBtn
        if btn.icon then btn.icon:SetTexture(nil) end
        if btn.bg   then btn.bg:Show()            end
        btn.glyphID = nil
        btn:Show()
    end

	MultiBot.talent.refreshApplyTabVisibility()
end

local function EnsureGlyphIconButtonBackground(btn, socketType, parent)
    if btn.bg then return end
    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints(parent)
    local texSlot = (socketType == "Minor") and
                    "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp" or
                    "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp"
    btn.bg:SetTexture(MultiBot.SafeTexturePath(texSlot))
end

local function CG_OnReceiveDrag(self)
    local typ, itemID = GetCursorInfo()
    if typ ~= "item" then return end

    if MultiBot.BuildGlyphClassTable then
        MultiBot.BuildGlyphClassTable()
    end
    local socket = self:GetParent()

	local botUnit = MultiBot.toUnit(MultiBot.talent.name)
	local lvl     = UnitLevel(botUnit or "player")
	local idx = socket:GetID()
	if idx == 0 then
	    idx = tonumber(socket:GetName():match("Socket(%d+)"))
	end
	if lvl < MultiBot.TalentTabLimits.SOCKET_REQUIREMENTS[idx] then
	    UIErrorsFrame:AddMessage(MultiBot.L("info.glyphssocketnotunlocked"),1,0.3,0.3,1)
	    return
	end

    local unit   = MultiBot.toUnit(MultiBot.talent.name)
    local _, cf  = UnitClass(unit or "player")
    local classKey = (cf == "DEATHKNIGHT") and "DeathKnight" or (cf:sub(1,1)..cf:sub(2):lower())
    local gDB = (MultiBot.data.talent.glyphs or {})[classKey] or {}

    local glyphClass = MultiBot.__glyphClass and MultiBot.__glyphClass[itemID]
    if glyphClass and glyphClass ~= classKey then
        UIErrorsFrame:AddMessage(MultiBot.L("info.glyphswrongclass"), 1,0.3,0.3,1)
        return
    end

    local gType, info
    if gDB.Major and gDB.Major[itemID] then
        gType, info = "Major", gDB.Major[itemID]
    elseif gDB.Minor and gDB.Minor[itemID] then
        gType, info = "Minor", gDB.Minor[itemID]
    else
        gType = GetGlyphItemType(itemID)
        if not gType then
            UIErrorsFrame:AddMessage(MultiBot.L("info.glyphsunknowglyph"),1,0.3,0.3,1)
            return
        end
    end

    if gType ~= (socket.type or "Major") then
         UIErrorsFrame:AddMessage(MultiBot.L("info.glyphsglyphtype") .. gType .. " : " .. MultiBot.L("info.glyphsglyphsocket"), 1, 0.3, 0.3, 1)
        return
    end

    if info then
        local reqLvl = tonumber((strsplit(",%s*", info)))
        if reqLvl and reqLvl > lvl then
            UIErrorsFrame:AddMessage(MultiBot.L("info.glyphsleveltoolow"),1,0.3,0.3,1)
            return
        end
    end

    if socket.frames.Glow    then socket.frames.Glow:Show()    end
    if socket.frames.Overlay then socket.frames.Overlay:Show() end
    if self.bg then self.bg:Hide() end

    local runeIdx = info and select(2, strsplit(",%s*", info)) or "1"
    local r = socket.frames.Rune
    if r then
        (r.texture or r):SetTexture(MultiBot.SafeTexturePath("Interface\\Spellbook\\UI-Glyph-Rune-"..runeIdx))
        r:Show()
    end
	local tex = select(10, GetItemInfo(itemID)) or GetSpellTexture(itemID) or "Interface\\AddOns\\MultiBot\\Textures\\UI-GlyphFrame-Glow.blp"
    self.icon:SetTexture(MultiBot.SafeTexturePath(tex))
    self.glyphID = itemID
    socket.item = itemID
	ClearCursor()
	MultiBot.talent.refreshApplyTabVisibility()
end

function MultiBot.talent.showCustomGlyphs()
	MultiBot.talent.__activeTab = MultiBot.TalentTabStates.CUSTOM_GLYPHS
    MultiBot.talent.setPointsVisibility(false)
    MultiBot.talent.setTalentContentVisibility(false)

    for i = 1, MultiBot.TalentTabLimits.GLYPH_SOCKET_COUNT do
        local s = MultiBot.talent.getGlyphSocket(i)
        if s then
            s:SetID(i)
            local botUnit = MultiBot.toUnit(MultiBot.talent.name)
            local lvl = UnitLevel(botUnit or "player")
            local unlocked = lvl >= MultiBot.TalentTabLimits.SOCKET_REQUIREMENTS[i]
            local ov = s.frames.Overlay
            if ov and not ov.texture then
                ov.texture = ov:CreateTexture(nil, "BORDER")
                ov.texture:SetAllPoints(ov)
                local base = "Interface\\AddOns\\MultiBot\\Textures\\"
                ov.texture:SetTexture(base .. (s.type == "Major" and "gliph_majeur_layout.blp" or "gliph_mineur_layout.blp"))
            end

            if not unlocked then
                if s.frames.Glow then s.frames.Glow:Hide() end
                if s.frames.Overlay then s.frames.Overlay:Hide() end
                if s.frames.Rune then s.frames.Rune:Hide() end
                if s.frames.IconBtn then s.frames.IconBtn:Hide() end
                s.locked = true
            else
                s.locked = false

                if s.frames.Glow then s.frames.Glow:Show() end
                if s.frames.Overlay then s.frames.Overlay:Show() end
                if s.frames.Rune then s.frames.Rune:Hide() end

                local btn = s.frames.IconBtn
                if not btn then
                    btn = CreateFrame("Button", nil, s)
                    btn:SetAllPoints(s)
                    EnsureGlyphIconButtonBackground(btn, s.type, s)
                    local ic = btn:CreateTexture(nil, "ARTWORK")
                    ic:SetPoint("CENTER", btn, "CENTER", -9, 8)
                    ic:SetSize(s:GetWidth() * 0.66, s:GetHeight() * 0.66)
                    ic:SetTexCoord(0.15, 0.85, 0.15, 0.85)
                    btn.icon = ic
                    s.frames.IconBtn = btn
                end

                EnsureGlyphIconButtonBackground(btn, s.type, s)

                btn.bg:Show()
                btn.icon:SetTexture(nil)
                btn.icon:Show()
                btn.glyphID = nil

                btn:RegisterForDrag("LeftButton")
                btn:RegisterForClicks("LeftButtonUp")
                btn:SetScript("OnEnter", ShowGlyphTooltip)
                btn:SetScript("OnLeave", HideGlyphTooltip)
                btn:SetScript("OnReceiveDrag", CG_OnReceiveDrag)
                btn:SetScript("OnClick", CG_OnReceiveDrag)
                btn:SetScript("OnMouseUp", function(self, button)
                    if button == "RightButton" then
                        ClearGlyphSocket(self:GetParent())
                    end
                end)
                s.item = 0
            end
        end
    end

    MultiBot.talent.setCopyTabMode(false, false)
    MultiBot.talent.refreshApplyTabVisibility()
    MultiBot.talent.setTalentTitleByKey("info.glyphscustomglyphsfor")
end

MultiBot.talent.customGlyphsTabBtn.doLeft = MultiBot.talent.showCustomGlyphs
-- END TAB CUSTOM GLYPHS --

--[[
Tab9: Copy — replaces the old copy button
]]--

MultiBot.talent.copyTabBtn = addTalentBottomTab(MultiBot.TalentTabKeys.COPY, MultiBot.TalentTabLabels.COPY, MultiBot.TalentTabOffsets.COPY)
MultiBot.talent.copyTabBtn.doLeft = function()
    MultiBot.talent.copyCustomTalentsToTarget()

    -- Text pulse animation
    local btn = MultiBot.talent.tabTextures[MultiBot.TalentTabKeys.COPY] and MultiBot.talent.tabTextures[MultiBot.TalentTabKeys.COPY].btn
    if btn and btn.text then
        local flashes = 0
        local function pulse()
            if flashes >= 6 then
                btn.text:SetText("|cffaaaaaa Copy|r")
                return
            end
            if flashes % 2 == 0 then
                btn.text:SetText("|cffffffff Copy|r")
            else
                btn.text:SetText("|cffff4444 Copy|r")
            end
            flashes = flashes + 1
            TimerAfter(0.15, pulse)
        end
        pulse()
    end

    -- Restore default active tab visual state.
    MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabDefaults.ACTIVE, true, MultiBot.TalentTabDefaults.ACTIVE_LABEL)
    MultiBot.talent.setBottomTabVisualState(MultiBot.TalentTabKeys.COPY, false, MultiBot.TalentTabLabels.COPY)
end

MultiBot.talent.applyTabBtn = addTalentBottomTab(MultiBot.TalentTabKeys.APPLY, MultiBot.TalentTabLabels.APPLY, MultiBot.TalentTabOffsets.APPLY)
MultiBot.talent.applyTabBtn.doHide()
MultiBot.talent.applyTabBtn.doLeft = function()
    if MultiBot.talent and MultiBot.talent.__activeTab == MultiBot.TalentTabStates.CUSTOM_TALENTS then
        if MultiBot.talent.hasCustomTalentSelection() then
            MultiBot.talent.applyCustomTalents()
        end
    elseif MultiBot.talent and MultiBot.talent.__activeTab == MultiBot.TalentTabStates.CUSTOM_GLYPHS then
        if MultiBot.talent.hasCustomGlyphSelection() then
            MultiBot.talent.applyCustomGlyphs()
        end
    end
    MultiBot.talent.refreshApplyTabVisibility()
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

-- HUNTER PETS MENU --
if not MultiBot.InitHunterQuick then
  function MultiBot.InitHunterQuick()
    local MBH = MultiBot.HunterQuick or {}
    MultiBot.HunterQuick = MBH

    MBH.frame = MultiBot.addFrame("HunterQuick", -820, 300, 36, 36*8, 36*4)
	MultiBot.PromoteFrame(MultiBot.HunterQuick.frame)
    MBH.frame:SetMovable(true)
    MBH.frame:EnableMouse(true)
    MBH.frame:RegisterForDrag("RightButton")
    MBH.frame:SetScript("OnDragStart", MBH.frame.StartMoving)
    -- MBH.frame:SetScript("OnDragStop" , MBH.frame.StopMovingOrSizing)
    MBH.frame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      local p, _, rp, x, y = self:GetPoint()
      if MultiBot.SetQuickFramePosition then
        MultiBot.SetQuickFramePosition("HunterQuick", p, rp, x, y)
      end
    end)
    MBH.frame:Hide()

    function MBH:RestorePosition()
      local st = MultiBot.GetQuickFramePosition and MultiBot.GetQuickFramePosition("HunterQuick")
      if not st then return end
      local f = self.frame
      if not f then return end

      if f.ClearAllPoints and f.SetPoint then
        f:ClearAllPoints()
        f:SetPoint(st.point or "CENTER", UIParent, st.relPoint or "CENTER", st.x or 0, st.y or 0)
      elseif f.setPoint then
        -- fallback si votre wrapper n’expose que setPoint()
        f:setPoint(st.point or "CENTER", st.relPoint or "CENTER", st.x or 0, st.y or 0)
      end
    end

    function MBH:ResolveUnitToken(name)
      if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
          local u = "raid"..i
          if UnitName(u) == name then return u, ("raidpet"..i) end
        end
      end
      for i = 1, GetNumPartyMembers() do
        local u = "party"..i
        if UnitName(u) == name then return u, ("partypet"..i) end
      end
      if UnitName("player") == name then return "player", "pet" end
      return nil, nil
    end

    function MBH:UpdatePetPresence(row)
      local unit, petUnit = self:ResolveUnitToken(row.owner)
      row.unit, row.petUnit = unit, petUnit
      local hasPet = petUnit and UnitExists(petUnit) and not UnitIsDead(petUnit)
      if hasPet then
        if row.modesBtn and row.modesBtn.setEnable then row.modesBtn.setEnable() end
      else
        if row.modesBtn and row.modesBtn.setDisable then row.modesBtn.setDisable() end
        if row.modesStrip and row.modesStrip:IsShown() then row.modesStrip:Hide() end
      end
    end

    function MBH:UpdateAllPetPresence()
      for _, r in pairs(self.entries or {}) do
        if r.owner then self:UpdatePetPresence(r) end
      end
    end

	function MBH:GetSavedStance(name)
      if MultiBot.GetHunterPetStance then
        return MultiBot.GetHunterPetStance(name)
      end
      return nil
    end

	function MBH:SetSavedStance(name, stance)
      if MultiBot.SetHunterPetStance then
        MultiBot.SetHunterPetStance(name, stance)
      end
    end

	function MBH:ApplyStanceVisual(row, stance)
      row.stanceButtons = row.stanceButtons or {}
      for _, btn in pairs(row.stanceButtons) do
        if btn and btn.setDisable then btn.setDisable(true) end
      end
      if stance and row.stanceButtons[stance] and row.stanceButtons[stance].setEnable then
        row.stanceButtons[stance].setEnable(true)
      end
      row.ActiveStance = stance
    end

    MBH.entries, MBH.COL_GAP = {}, 40

    local function SanitizeName(n)
      return (tostring(n):gsub("[^%w_]", "_"))
    end

    function MBH:BuildForHunter(hName)
      local san = SanitizeName(hName)
      local row = self.frame.addFrame("HunterQuickRow_"..san, -36*7, 0, 36, 36*8, 36*3)
      row.owner = hName

      row.mainBtn = row.addButton("HunterQuickMain_"..san, 0, 0,
          "Interface\\AddOns\\MultiBot\\Icons\\class_hunter.blp",
          MultiBot.L("tips.hunter.ownbutton"):format(hName))
      row.mainBtn:SetFrameStrata("HIGH")
      row.mainBtn:RegisterForDrag("RightButton")
      row.mainBtn:SetScript("OnDragStart", function() self.frame:StartMoving() end)
      row.mainBtn:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        local p, _, rp, x, y = self.frame:GetPoint()
        if MultiBot.SetQuickFramePosition then
          MultiBot.SetQuickFramePosition("HunterQuick", p, rp, x, y)
        end
      end)

      row.vmenu = row.addFrame("HunterQuickMenu_"..san, 0, 0, 36, 36, 36*3)
      row.vmenu:Hide()
       row.modesBtn = row.vmenu.addButton("HunterModesBtn_"..san, 0, 36, "ability_hunter_beasttaming", MultiBot.L("tips.hunter.pet.stances"))
      row.utilsBtn = row.vmenu.addButton("HunterUtilsBtn_"..san, 0, 72, "trade_engineering", MultiBot.L("tips.hunter.pet.master"))

      row.modesStrip = row.addFrame("HunterQuickModesStrip_"..san, 0, 0, 36, 36*7, 36)
      row.utilsStrip = row.addFrame("HunterQuickUtilsStrip_"..san, 0, 0, 36, 36*5, 36)
      row.modesStrip:ClearAllPoints()
      row.modesStrip:SetPoint("BOTTOMLEFT", row.modesBtn, "BOTTOMRIGHT", 0, 0)
      row.modesStrip:SetWidth(36*7); row.modesStrip:SetHeight(36)
      row.utilsStrip:ClearAllPoints()
      row.utilsStrip:SetPoint("BOTTOMLEFT", row.utilsBtn, "BOTTOMRIGHT", 0, 0)
      row.utilsStrip:SetWidth(36*5); row.utilsStrip:SetHeight(36)
      row.modesStrip:EnableMouse(false); row.utilsStrip:EnableMouse(false)
      row.modesStrip:Hide(); row.utilsStrip:Hide()

      MBH:UpdatePetPresence(row)

      row.mainBtn.doLeft = function()
	  MBH:CloseAllExcept(row)
        if row.vmenu:IsShown() then
          row.vmenu:Hide()
          row.modesStrip:Hide()
          row.utilsStrip:Hide()
        else
          row.vmenu:Show()
        end
      end

      local labels_and_tips = {
        { key="aggressive", tip=MultiBot.L("tips.hunter.pet.aggressive") },
        { key="passive"   , tip=MultiBot.L("tips.hunter.pet.passive")   },
        { key="defensive" , tip=MultiBot.L("tips.hunter.pet.defensive") },
        { key="stance"    , tip=MultiBot.L("tips.hunter.pet.curstance") },
        { key="attack"    , tip=MultiBot.L("tips.hunter.pet.attack") },
        { key="follow"    , tip=MultiBot.L("tips.hunter.pet.follow") },
        { key="stay"      , tip=MultiBot.L("tips.hunter.pet.stay") },
      }
      local PET_MODE_ICONS = {
        aggressive = "ability_Racial_BloodRage",
        passive    = "Spell_Nature_Sleep",
        defensive  = "Ability_Defend",
        stance     = "Temp",
        attack     = "Ability_GhoulFrenzy",
        follow     = "ability_tracking",
        stay       = "Spell_Nature_TimeStop",
      }

      row.stanceButtons = {}
      for i, def in ipairs(labels_and_tips) do
        local px = -36 * (7 - i)
        local tex = PET_MODE_ICONS[def.key] or "inv_misc_questionmark"
        local b = row.modesStrip.addButton("HunterQuickMode_"..san.."_"..i, px, 0, tex, def.tip)
        if def.key == "aggressive" or def.key == "passive" or def.key == "defensive" then
          row.stanceButtons[def.key] = b
          if b.setDisable then b.setDisable(true) end
          b.doLeft = function()
            SendChatMessage("pet "..def.key, "WHISPER", nil, hName)
            MBH:ApplyStanceVisual(row, def.key)
            MBH:SetSavedStance(hName, def.key)
          end
        else
          b.doLeft = function()
            SendChatMessage("pet "..def.key, "WHISPER", nil, hName)
          end
        end
      end

	  MBH:ApplyStanceVisual(row, MBH:GetSavedStance(hName))

      row.modesBtn.doLeft = function()
        MBH:CloseAllExcept(row)
        if row.modesStrip:IsShown() then
          row.modesStrip:Hide()
        else
          row.modesStrip:Show()
          row.utilsStrip:Hide()
		  MBH:ApplyStanceVisual(row, row.ActiveStance)
        end
      end

      local petCmdList = {
        {"Name",    "tame name %s",    "inv_scroll_11",            MultiBot.L("tips.hunter.pet.name")},
        {"Id",      "tame id %s",      "inv_scroll_14",            MultiBot.L("tips.hunter.pet.id")},
        {"Family",  "tame family %s",  "inv_misc_enggizmos_03",    MultiBot.L("tips.hunter.pet.family")},
        {"Rename",  "tame rename %s",  "inv_scroll_01",            MultiBot.L("tips.hunter.pet.rename")},
        {"Abandon", "tame abandon",    "spell_nature_spiritwolf",  MultiBot.L("tips.hunter.pet.abandon")},
      }
      for i, v in ipairs(petCmdList) do
        local label, fmt, icon, tip = v[1], v[2], v[3], v[4]
        local px = -36 * (5 - i)
        local ub = row.utilsStrip.addButton("HunterQuickUtil_"..san.."_"..i, px, 0, icon, tip)
        ub.doLeft = function()
          if label == "Rename" then
            MBH:ShowPrompt(fmt, hName, MultiBot.L("info.hunterpetnewname"))
            row.utilsStrip:Hide()
          elseif label == "Id" then
            MBH:ShowPrompt(fmt, hName, MultiBot.L("info.hunterpetid"))
            row.utilsStrip:Hide()
          elseif label == "Family" then
            MBH:ShowFamilyFrame(hName)
            row.utilsStrip:Hide()
          elseif label == "Abandon" then
            SendChatMessage(fmt, "WHISPER", nil, hName)
            row.utilsStrip:Hide()
          else
            MBH:EnsureSearchFrame()
            local f = MBH.SEARCH_FRAME
            f.TargetName = hName
            f:Show()
            f.EditBox:SetText("")
            f.EditBox:SetFocus()
            f:Refresh()
            row.utilsStrip:Hide()
          end
        end
      end
      row.utilsBtn.doLeft = function()
	  MBH:CloseAllExcept(row)
        if row.utilsStrip:IsShown() then
          row.utilsStrip:Hide()
        else
          row.utilsStrip:Show()
          row.modesStrip:Hide()
        end
      end

      self.entries[hName] = row
    end

    function MBH:CollectHunterBots()
      local out = {}
      if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for i=1, GetNumRaidMembers() do
          local unit = "raid"..i
          local name = UnitName(unit)
          local _, cls = UnitClass(unit)
          if name and cls == "HUNTER" and (not MultiBot.IsBot or MultiBot.IsBot(name)) then
            table.insert(out, name)
          end
        end
      else
        if GetNumPartyMembers then
          for i=1, GetNumPartyMembers() do
            local unit = "party"..i
            local name = UnitName(unit)
            local _, cls = UnitClass(unit)
            if name and cls == "HUNTER" and (not MultiBot.IsBot or MultiBot.IsBot(name)) then
              table.insert(out, name)
            end
          end
        end
      end
      table.sort(out)
      return out
    end

    function MBH:Rebuild()
      local desired = self:CollectHunterBots()

	  for name, row in pairs(self.entries) do
        local found = false
        for _, n in ipairs(desired) do if n==name then found=true; break end end
        if not found then
          row:Hide()
          self.entries[name] = nil
        end
      end

      for _, name in ipairs(desired) do
        if not self.entries[name] then
          self:BuildForHunter(name)
        end
      end

      for idx, name in ipairs(desired) do
        local row = self.entries[name]
        if row then
          row:ClearAllPoints()
          row:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -36*7 + (idx-1)*self.COL_GAP, 0)
          row:Show()
        end
      end

      if #desired > 0 then self.frame:Show() else self.frame:Hide() end
      if self.RestorePosition then self:RestorePosition() end
    end

    function MBH:CloseAllExcept(keepRow)
      for _, r in pairs(self.entries) do
        if r ~= keepRow then
          if r.vmenu and r.vmenu:IsShown() then r.vmenu:Hide() end
          if r.modesStrip and r.modesStrip:IsShown() then r.modesStrip:Hide() end
          if r.utilsStrip and r.utilsStrip:IsShown() then r.utilsStrip:Hide() end
        end
      end
    end

    function MBH:FindHunter()
      if UnitExists("target") then
        local _, cls = UnitClass("target")
        if cls == "HUNTER" then
          local tn = UnitName("target")
          if tn and tn ~= "Unknown Entity" then return tn end
        end
      end
      local i = MultiBot.index and MultiBot.index.classes
      if i then
        local p = i.players and i.players["Hunter"]
        if p and #p > 0 then return p[1] end
        local m = i.members and i.members["Hunter"]
        if m and #m > 0 then return m[1] end
        local f = i.friends and i.friends["Hunter"]
        if f and #f > 0 then return f[1] end
      end
      return nil
    end

    function MBH:ShowPrompt(fmt, targetName, title)
      ShowPrompt(title or MultiBot.L("info.hunterpeteditentervalue"), function(text)
        if text and text ~= "" and targetName then
          local cmd = string.format(fmt, text)
          SendChatMessage(cmd, "WHISPER", nil, targetName)
        end
      end, MultiBot.L("info.hunterpetentersomething"))
    end

    function MBH:EnsureSearchFrame()
      if self.SEARCH_FRAME then return end
      local f = createAceQuestPopupHost(MultiBot.L("info.hunterpetcreaturelist"), 360, 360, "AceGUI-3.0 is required for MBHunterPetSearch", "hunter_pet_search")
      assert(f, "AceGUI-3.0 is required for MBHunterPetSearch")
      self.SEARCH_FRAME = f

      local e = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
      e:SetAutoFocus(true)
      e:SetSize(200,20)
      e:SetPoint("TOP", 0, -14)
      f.EditBox = e

      local PREVIEW_WIDTH, PREVIEW_HEIGHT = 180, 260
      local PREVIEW_MODEL_SCALE = 0.6
      local PREVIEW_FACING = -math.pi/12
      local CURRENT_ENTRY = nil

      local function GetPreviewFrame()
        if MBHunterPetPreview then return MBHunterPetPreview end
        local p = CreateFrame("PlayerModel","MBHunterPetPreview",UIParent)
        p:SetSize(PREVIEW_WIDTH, PREVIEW_HEIGHT)
        p:SetBackdrop({
          bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
          edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
          tile=true, tileSize=16, edgeSize=16,
          insets={left=4,right=4,top=4,bottom=4}})
        p:SetBackdropColor(0,0,0,0.85)
        p:SetFrameStrata("DIALOG")
        p:SetMovable(true); p:EnableMouse(true)
        p:RegisterForDrag("LeftButton")
        p:SetScript("OnDragStart", p.StartMoving)
        p:SetScript("OnDragStop" , p.StopMovingOrSizing)
        CreateFrame("Button",nil,p,"UIPanelCloseButton"):SetPoint("TOPRIGHT",-5,-5)
        -- Keep a stable default anchor; do not re-anchor on every preview click.
        p:ClearAllPoints()
        p:SetPoint("LEFT", UIParent, "CENTER", 180, 20)
        return p
      end

      local function HidePreviewFrame()
        if MBHunterPetPreview and MBHunterPetPreview:IsShown() then
          MBHunterPetPreview:Hide()
        end
        CURRENT_ENTRY = nil
      end

      if f.window and f.window.frame and f.window.frame.HookScript then
        f.window.frame:HookScript("OnHide", HidePreviewFrame)
      end

      local function LoadCreatureToPreview(entryId, displayId)
        local pv = GetPreviewFrame()
        if pv:IsShown() and CURRENT_ENTRY==entryId then pv:Hide(); CURRENT_ENTRY=nil; return end
        CURRENT_ENTRY = entryId

        pv:SetUnit("none")
        pv:ClearModel()
        pv:Show()
        pv:SetScript("OnUpdate", function(self)
          self:SetScript("OnUpdate",nil)
          self:SetModelScale(PREVIEW_MODEL_SCALE)
          self:SetFacing(PREVIEW_FACING)

          -- Prefer direct display ID to avoid cache-dependent creature preview resolution on 3.3.5 clients.
          local displayNum = tonumber(displayId)
          if displayNum and displayNum > 0 and type(self.SetDisplayInfo) == "function" then
            self:SetDisplayInfo(displayNum)
          else
            self:SetCreature(entryId)
          end
        end)
      end

      local ROW_H, VISIBLE_ROWS = 18, 17
      local OFFSET = 0
      local RESULTS = {}

      local sf = CreateFrame("ScrollFrame","MBHunterPetScroll",f,"UIPanelScrollFrameTemplate")
      sf:SetPoint("TOPLEFT",10,-42)
      sf:SetPoint("BOTTOMRIGHT",-30,10)
      local content = CreateFrame("Frame",nil,sf) ; content:SetSize(1,1)
      sf:SetScrollChild(content)

      f.Rows = {}
      for i = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, content)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row:SetHeight(ROW_H)
        row:SetWidth(content:GetWidth())
        row:SetPoint("TOPLEFT", 0, -(i-1)*ROW_H)

        row.text = row:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
        row.text:SetPoint("LEFT",2,0)

        local btn = CreateFrame("Button", nil, row)
        btn:SetSize(16,16)
        btn:SetPoint("RIGHT",-22,0)
        btn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
        btn:SetPushedTexture("Interface\\Buttons\\UI-PlusButton-DOWN")
        btn:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
        row.previewBtn = btn

        f.Rows[i] = row
      end

      local function localeField()
        local l = GetLocale():lower()
        if     l=="frfr" then return "name_fr"
        elseif l=="dede" then return "name_de"
        elseif l=="eses" then return "name_es"
        elseif l=="esmx" then return "name_esmx"
        elseif l=="kokr" then return "name_ko"
        elseif l=="zhtw" then return "name_zhtw"
        elseif l=="zhcn" then return "name_zhcn"
        elseif l=="ruru" then return "name_ru"
        else return "name_en" end
      end

      function f:RefreshRows()
        for i = 1, VISIBLE_ROWS do
          local idx  = i + OFFSET
          local data = RESULTS[idx]
          local row  = self.Rows[i]
          local LIST_W = 320

          row:ClearAllPoints()
          row:SetPoint("TOPLEFT", 0, -((i-1 + OFFSET) * ROW_H))
          row:SetWidth(LIST_W)

          if data then
            row.text:SetText(
              string.format("|cffffd200%-24s|r |cff888888[%s]|r",
              data.name, MultiBot.PET_FAMILY[data.family] or "?"))

            row:SetScript("OnClick", function()
              if f.TargetName then
                SendChatMessage(("tame id %d"):format(data.id), "WHISPER", nil, f.TargetName)
              end
              f:Hide()
            end)

            row.previewBtn:SetScript("OnClick", function()
              LoadCreatureToPreview(data.id, data.display)
            end)

            row:Show()
          else
            row:Hide()
          end
        end
      end

      sf:SetScript("OnVerticalScroll", function(_,delta)
        local newOffset = math.floor(sf:GetVerticalScroll()/ROW_H + 0.5)
        if newOffset ~= OFFSET then OFFSET = newOffset; f:RefreshRows() end
      end)

      function f:Refresh()
        wipe(RESULTS)
        local filter = (e:GetText() or ""):lower()
        local field  = localeField()

        for id,info in pairs(MultiBot.PET_DATA) do
          local name = info[field] or info.name_en
          if name:lower():find(filter,1,true) then
            RESULTS[#RESULTS+1] = {id=id,name=name,family=info.family,display=info.display}
          end
        end
        table.sort(RESULTS,function(a,b) return a.name<b.name end)

        content:SetHeight(#RESULTS * ROW_H)
        OFFSET = 0
        sf:SetVerticalScroll(0)
        f:RefreshRows()
      end
      e:SetScript("OnTextChanged", function() f:Refresh() end)
    end

    function MBH:ShowFamilyFrame(targetName)
      local ff = self.FAMILY_FRAME
      if not ff then
        ff = createAceQuestPopupHost(MultiBot.L("info.hunterpetrandomfamily"), 260, 340, "AceGUI-3.0 is required for MBHunterPetFamily", "hunter_pet_family")
        assert(ff, "AceGUI-3.0 is required for MBHunterPetFamily")
        self.FAMILY_FRAME = ff

        local sf = CreateFrame("ScrollFrame", "MBHunterFamilyScroll", ff, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 8, -10)
        sf:SetPoint("BOTTOMRIGHT", -28, 8)
        local LIST_W = 320
        local content = CreateFrame("Frame", nil, sf)
        content:SetSize(LIST_W, 1)
        sf:SetScrollChild(content)
        ff.Content = content
        ff.Rows = {}

        local ROW_H = 18

        local loc  = GetLocale()
        local L10N = MultiBot.PET_FAMILY_L10N and MultiBot.PET_FAMILY_L10N[loc]

        local families = {}
        for fid, eng in pairs(MultiBot.PET_FAMILY) do
          local txt = (L10N and L10N[fid]) or eng
          table.insert(families, {id=fid, eng=eng, txt=txt})
        end
        table.sort(families, function(a,b) return a.txt < b.txt end)

        for i,data in ipairs(families) do
          local row = CreateFrame("Button", nil, content)
          row:EnableMouse(true)
          row:SetHeight(ROW_H)
          row:SetPoint("TOPLEFT", 0, -(i-1)*ROW_H)
          row:SetWidth(content:GetWidth())

          row.text = row:CreateFontString(nil,"ARTWORK","GameFontNormalSmall")
          row.text:SetPoint("LEFT")
          row.text:SetText("|cffffd200"..data.txt.."|r")
          row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

          row:SetScript("OnClick", function()
            if targetName then
              local cmd = ("tame family %s"):format(data.eng) -- nom anglais dans la commande
              SendChatMessage(cmd, "WHISPER", nil, targetName)
            end
            ff:Hide()
          end)
        end
      end
      ff:Show()
    end

    if MultiBot.TimerAfter then
      MultiBot.TimerAfter(0.5, function()
        if MBH.Rebuild then MBH:Rebuild() end
        if MBH.UpdateAllPetPresence then MBH:UpdateAllPetPresence() end
      end)
    end

  end

  MultiBot.HunterQuick = MultiBot.HunterQuick or {}

  MultiBot.InitHunterQuick()

  if MultiBot.HunterQuick and MultiBot.HunterQuick.RestorePosition then
    MultiBot.HunterQuick:RestorePosition()
  end

end
-- End Hunter --

-- SHAMAN TOTEMS QUICK BAR --
if not MultiBot.InitShamanQuick then
  function MultiBot.InitShamanQuick()
    local MBS = MultiBot.ShamanQuick or {}
    MultiBot.ShamanQuick = MBS

    function MBS:CloseAllExcept(keepRow)
      for _, r in pairs(self.entries) do
        if r ~= keepRow then
          if r.vmenu    then r.vmenu:Hide()    end
          if r.earthGrp then r.earthGrp:Hide() end
          if r.fireGrp  then r.fireGrp:Hide()  end
          if r.waterGrp then r.waterGrp:Hide() end
          if r.airGrp   then r.airGrp:Hide()   end
          if r.Show and r.Hide then r:Hide() end
          r._expanded = false
        end
        if r == keepRow and r.Show then r:Show() end
      end
    end

    function MBS:ShowAllRows()
      for _, r in pairs(self.entries) do
        if r.Show then r:Show() end
      end
    end

    MBS.frame = MultiBot.addFrame("ShamanQuick", -420, 240, 36, 36*8, 36*4)
	MultiBot.PromoteFrame(MultiBot.ShamanQuick.frame)
    MBS.frame:SetMovable(true)
    MBS.frame:EnableMouse(true)
    MBS.frame:RegisterForDrag("RightButton")
    MBS.frame:SetScript("OnDragStart", MBS.frame.StartMoving)
    -- OnDragStop : stop + SAVE position
    MBS.frame:SetScript("OnDragStop" , function(self)
      self:StopMovingOrSizing()
      local p, _, rp, x, y = self:GetPoint()
      local _sp = _MB_GetOrCreateShamanPos()
      if MultiBot.SetQuickFramePosition then
        MultiBot.SetQuickFramePosition("ShamanQuick", p, rp, x, y)
      end
    end)

    -- Restaure la position sauvegardée
    function MBS:RestorePosition()
      local st = MultiBot.GetQuickFramePosition and MultiBot.GetQuickFramePosition("ShamanQuick")
      if not st then return end
      local f = self.frame
      if not f then return end
      if f.ClearAllPoints and f.SetPoint then
        f:ClearAllPoints()
        f:SetPoint(st.point or "CENTER", UIParent, st.relPoint or "CENTER", st.x or 0, st.y or 0)
      elseif f.setPoint then
        -- fallback si ton wrapper n’a que setPoint()
        f:setPoint(st.point or "CENTER", st.relPoint or "CENTER", st.x or 0, st.y or 0)
      end
    end
    MBS.frame:Hide()

    MBS.entries, MBS.COL_GAP = {}, 40
    MBS.count = 0

    local function SanitizeName(n) return (tostring(n):gsub("[^%w_]", "_")) end

    -- Helper : appliquer une icône sur un bouton du wrapper MultiBot
    local function SetBtnIcon(btn, iconPath)
      if not btn or not iconPath then return end
      -- Wrapper MultiBot, la plupart des boutons ont setTexture(...)
      if btn.setTexture then
        btn.setTexture(iconPath)
        btn._mb_iconPath = iconPath
        return
      end
      -- Bouton WoW “pur” : SetIcon / SetNormalTexture
      if btn.SetIcon then
        btn:SetIcon(iconPath)
        btn._mb_iconPath = iconPath
        return
      end
      if btn.SetNormalTexture then
        btn:SetNormalTexture(iconPath)
        btn._mb_iconPath = iconPath
        return
      end
      -- 3) Dernier repli : region texture stockée par le wrapper (btn.icon ou btn.texture)
      local tex = btn.icon or btn.texture
      if tex and tex.SetTexture then
        local safePath = MultiBot.SafeTexturePath(iconPath)
        tex:SetTexture(safePath)
        btn._mb_iconPath = safePath
        return
      end
    end

    -- Désaturation / grisage d'un bouton de totem
    local function SetGrey(btn, isGrey)
      if not btn then return end
      local tex = btn.icon or btn.texture
      if tex and tex.SetDesaturated then
        tex:SetDesaturated(isGrey and true or false)
      end
      if tex and tex.SetVertexColor then
        if isGrey then tex:SetVertexColor(0.5, 0.5, 0.5, 1) else tex:SetVertexColor(1, 1, 1, 1) end
      end
      if btn.setAlpha then
        btn.setAlpha(isGrey and 0.6 or 1.0)
      end
      btn._mb_grey = isGrey and true or false
    end

    -- Ajoute un toggle de totem et relie l'élément (earth/fire/water/air) + la row propriétaire
    local function AddTotemToggle(ownerRow, parentFrame, name, x, y, iconPath, label, spell, ownerName, elementKey)
      local b = parentFrame.addButton(name, x, y, iconPath, label)
      b._mb_key  = name
      b._mb_owner = ownerName
      b._mb_on    = false
      b._mb_icon  = iconPath
      b._mb_elem  = elementKey
      b._mb_row   = ownerRow
      -- indexe ce bouton dans la grille de l'élément pour la restauration
      ownerRow._gridBtns              = ownerRow._gridBtns or {}
      ownerRow._gridBtns[elementKey]  = ownerRow._gridBtns[elementKey] or {}
      table.insert(ownerRow._gridBtns[elementKey], b)
      -- helpers visuels grisage/dégrisage ciblant la vraie région d'icône
      local function _Grey(btn, on)
        if not btn then return end
        local tex = btn.icon or btn.texture
        if tex and tex.SetDesaturated then
          tex:SetDesaturated(on and true or false)
        end
        if tex and tex.SetVertexColor then
          if on then tex:SetVertexColor(0.5, 0.5, 0.5) else tex:SetVertexColor(1, 1, 1) end
        end
        if btn.setAlpha then btn.setAlpha(on and 0.6 or 1.0) end
      end
      b.doLeft = function()
        local who = b._mb_owner
        if not who then return end
        -- état par ligne/élément pour gérer l’exclusivité visuelle
        local row = b._mb_row
        local ek  = b._mb_elem
        row._selectedBtn = row._selectedBtn or {}
        if b._mb_on then
          MultiBot.ActionToTarget("co -" .. spell .. ",?", who)
          b._mb_on = false
          if row and ek and row._chosen and row._chosen[ek] == b._mb_icon then
            row._chosen[ek] = nil
            local btn = (row._elemBtns and row._elemBtns[ek]) or nil
            local def = (row._defaults and row._defaults[ek]) or nil
            if btn and def then SetBtnIcon(btn, def) end
            -- dégrise le bouton si c'était le sélectionné
            if row._selectedBtn[ek] == b then
              _Grey(b, false)
              row._selectedBtn[ek] = nil
            end
            -- Clear saved choice for this bot/element.
            if MultiBot.ClearShamanTotemChoice then
              MultiBot.ClearShamanTotemChoice(who, ek)
            end
          end
          -- Dégrise le bouton (retour visuel) + nettoie la sélection exclusive
          SetGrey(b, false)
          if row._selectedBtn[ek] == b then
            row._selectedBtn[ek] = nil
          end
        else
          MultiBot.ActionToTarget("co +" .. spell .. ",?", who)
          b._mb_on = true
          if row and ek then
            row._chosen = row._chosen or {}
            row._chosen[ek] = b._mb_icon
            local btn = (row._elemBtns and row._elemBtns[ek]) or nil
            if btn then SetBtnIcon(btn, b._mb_icon) end
            -- Exclusivité visuelle : dégrise l'ancien, grise ce bouton
            local prev = row._selectedBtn[ek]
            if prev and prev ~= b then SetGrey(prev, false) end
            SetGrey(b, true)
            row._selectedBtn[ek] = b
            -- dé-grise l'ancien sélectionné dans ce même élément, grise le nouveau
            local prev = row._selectedBtn[ek]
            if prev and prev ~= b then _Grey(prev, false) end
            _Grey(b, true)
            row._selectedBtn[ek] = b
            -- Persist selected totem for this bot/element.
            if MultiBot.SetShamanTotemChoice then
              MultiBot.SetShamanTotemChoice(who, ek, b._mb_icon)
            end
          end
          -- Grise le bouton sélectionné
          local tex = b.icon or b.texture
          if tex and tex.SetDesaturated then
            tex:SetDesaturated(true)
          elseif b.setAlpha then
            b.setAlpha(0.6)
          end
        end
      end
      return b
    end

    function MBS:BuildForShaman(sName)
      local san = SanitizeName(sName)
      self.count = self.count + 1
      local xoff = -36*7 + (self.count-1) * self.COL_GAP

      local row = self.frame.addFrame("ShamanQuickRow_"..san, xoff, 0, 36, 36*8, 36*3)
      row.owner = sName
      self.entries[san] = row
      row._expanded = false

      -- Initialisations centralisées, disponibles pour tout le build
      row._elemBtns = {}      -- boutons d’élément (earth/fire/water/air)
      row._defaults = {       -- icônes par défaut des éléments
        earth = "spell_nature_earthbindtotem",
        fire  = "spell_fire_searingtotem",
        water = "spell_nature_manaregentotem",
        air   = "spell_nature_windfury",
      }
      row._chosen = { earth=nil, fire=nil, water=nil, air=nil } -- totems choisis courants

      local shamanOwnButtonLabel = MultiBot.L("tips.shaman.ownbutton")
      if type(shamanOwnButtonLabel) ~= "string" or shamanOwnButtonLabel == "" or shamanOwnButtonLabel == "tips.shaman.ownbutton" then
        shamanOwnButtonLabel = "Shaman: %s"
      end

      row.mainBtn = row.addButton("ShamanQuickMain_"..san, 0, 0,
        "Interface\\AddOns\\MultiBot\\Icons\\class_shaman.blp",
        shamanOwnButtonLabel:format(sName))
      row.mainBtn:SetFrameStrata("HIGH")
      row.mainBtn:RegisterForDrag("RightButton")
      row.mainBtn:SetScript("OnDragStart", function() self.frame:StartMoving() end)
      -- Stop et save position quand on lâche le drag depuis le main bouton
      row.mainBtn:SetScript("OnDragStop" , function()
        self.frame:StopMovingOrSizing()
        local p, _, rp, x, y = self.frame:GetPoint()
        if MultiBot.SetQuickFramePosition then
          MultiBot.SetQuickFramePosition("ShamanQuick", p, rp, x, y)
        end
      end)

      row.mainBtn.doLeft = function()
        local svc = MultiBot.ShamanQuick
        if not row._expanded then
          -- Ouvre ce shaman et cache tous les autres
          if svc and svc.CloseAllExcept then svc:CloseAllExcept(row) end
          if row.vmenu then row.vmenu:Show() end
          row._expanded = true
        else
          -- Ferme ce shaman et ré-affiche tous les autres
          if row.vmenu then row.vmenu:Hide() end
          if row.earthGrp then row.earthGrp:Hide() end
          if row.fireGrp  then row.fireGrp:Hide()  end
          if row.waterGrp then row.waterGrp:Hide() end
          if row.airGrp   then row.airGrp:Hide()   end
          if svc and svc.ShowAllRows then svc:ShowAllRows() end
          row._expanded = false
        end
      end

      row.vmenu = row.addFrame("ShamanQuickMenu_"..san, 0, 0, 36, 36, 36*4)
      row.vmenu:Hide()

      local function ToggleGroup(groupFrame)
        if groupFrame:IsShown() then groupFrame:Hide() else groupFrame:Show() end
      end

      -- Earth --
      row.earthBtn = row.vmenu.addButton("ShamanEarthBtn_"..san, 0, 36, row._defaults.earth,
        MultiBot.L("tips.shaman.ctotem.earthtot"))
      row.earthBtn._mb_key = "ShamanEarthBtn_"..san
	  row.earthGrp = row.addFrame("ShamanEarthGrp_"..san, 40, 0, 36, 36, 36*5); row.earthGrp:Hide()
      row.earthBtn.doLeft = function() ToggleGroup(row.earthGrp) end
	  row._elemBtns.earth = row.earthBtn

      AddTotemToggle(row, row.earthGrp, "StrengthOfEarth_"..san, 0, 0, "spell_nature_earthbindtotem",
        MultiBot.L("tips.shaman.ctotem.stoe"),   "strength of earth", sName, "earth")
      AddTotemToggle(row, row.earthGrp, "Stoneskin_"..san, 0,  36, "spell_nature_stoneskintotem",
        MultiBot.L("tips.shaman.ctotem.stoskin"),       "stoneskin", sName, "earth")
      AddTotemToggle(row, row.earthGrp, "Tremor_"..san, 0,  72, "spell_nature_tremortotem",
        MultiBot.L("tips.shaman.ctotem.tremor"), "tremor", sName, "earth")
      AddTotemToggle(row, row.earthGrp, "Earthbind_"..san, 0, 108, "spell_nature_strengthofearthtotem02",
        MultiBot.L("tips.shaman.ctotem.eabind"), "earthbind",         sName, "earth")

      -- Fire --
      row.fireBtn = row.vmenu.addButton("ShamanFireBtn_"..san, 0, 72, row._defaults.fire,
        MultiBot.L("tips.shaman.ctotem.firetot"))
      row.fireBtn._mb_key = "ShamanFireBtn_"..san
	  row.fireGrp = row.addFrame("ShamanFireGrp_"..san, 80, 0, 36, 36, 36*5); row.fireGrp:Hide()
      row.fireBtn.doLeft = function() ToggleGroup(row.fireGrp) end
	  row._elemBtns.fire = row.fireBtn

      AddTotemToggle(row, row.fireGrp, "Searing_"..san, 0, 0, "spell_fire_searingtotem",
        MultiBot.L("tips.shaman.ctotem.searing"),  "searing", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "Magma_"..san, 0,  36, "spell_fire_moltenblood",
        MultiBot.L("tips.shaman.ctotem.magma"),    "magma", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "Flametongue_"..san, 0,  72, "spell_nature_guardianward",
        MultiBot.L("tips.shaman.ctotem.fltong"),   "flametongue", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "Wrath_"..san, 0, 108, "spell_fire_totemofwrath",
        MultiBot.L("tips.shaman.ctotem.towrath"),  "wrath", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "FrostResist_"..san, 0, 144, "spell_frost_frostward",
        MultiBot.L("tips.shaman.ctotem.frostres"), "frost resistance", sName, "fire")

      -- Water --
      row.waterBtn = row.vmenu.addButton("ShamanWaterBtn_"..san, 0, 108, row._defaults.water,
        MultiBot.L("tips.shaman.ctotem.watertot"))
      row.waterBtn._mb_key = "ShamanWaterBtn_"..san
	  row.waterGrp = row.addFrame("ShamanWaterGrp_"..san, 120, 0, 36, 36, 36*4); row.waterGrp:Hide()
      row.waterBtn.doLeft = function() ToggleGroup(row.waterGrp) end
	  row._elemBtns.water = row.waterBtn

      AddTotemToggle(row, row.waterGrp, "HealingStream_"..san, 0, 0, "spell_nature_healingwavelesser",
        MultiBot.L("tips.shaman.ctotem.healstream"), "healing stream", sName, "water")
      AddTotemToggle(row, row.waterGrp, "ManaSpring_"..san, 0, 36, "spell_nature_manaregentotem",
        MultiBot.L("tips.shaman.ctotem.manasprin"), "mana spring", sName, "water")
      AddTotemToggle(row, row.waterGrp, "Cleansing_"..san, 0, 72, "spell_nature_nullifydisease",
        MultiBot.L("tips.shaman.ctotem.cleansing"), "cleansing", sName, "water")
      AddTotemToggle(row, row.waterGrp, "FireResistW_"..san, 0, 108, "spell_fire_firearmor",
        MultiBot.L("tips.shaman.ctotem.fireres"), "fire resistance", sName, "water")

      -- Air --
      row.airBtn = row.vmenu.addButton("ShamanAirBtn_"..san, 0, 144, row._defaults.air,
        MultiBot.L("tips.shaman.ctotem.airtot"))
      row.airBtn._mb_key = "ShamanAirBtn_"..san
	  row.airGrp = row.addFrame("ShamanAirGrp_"..san, 160, 0, 36, 36, 36*4); row.airGrp:Hide()
      row.airBtn.doLeft = function() ToggleGroup(row.airGrp) end
	  row._elemBtns.air = row.airBtn

      AddTotemToggle(row, row.airGrp, "WrathOfAir_"..san, 0, 0, "spell_nature_slowingtotem",
        MultiBot.L("tips.shaman.ctotem.wrhatair"), "wrath of air", sName, "air")
      AddTotemToggle(row, row.airGrp, "Windfury_"..san, 0, 36, "spell_nature_windfury",
        MultiBot.L("tips.shaman.ctotem.windfury"), "windfury", sName, "air")
      AddTotemToggle(row, row.airGrp, "NatureResist_"..san, 0, 72, "spell_nature_natureresistancetotem",
        MultiBot.L("tips.shaman.ctotem.natres"), "nature resistance", sName, "air")
      AddTotemToggle(row, row.airGrp, "Grounding_"..san, 0, 108, "spell_nature_groundingtotem",
        MultiBot.L("tips.shaman.ctotem.grounding"), "grounding", sName, "air")

      -- Restauration depuis SavedVariables (icône et grisé exclusif)
      do
        local saved = MultiBot.GetShamanTotemsForBot and MultiBot.GetShamanTotemsForBot(sName)
        if saved then
          for ek, icon in pairs(saved) do
            if icon and row._elemBtns[ek] then
              -- remet l'icône choisie sur le bouton principal de l'élément
              SetBtnIcon(row._elemBtns[ek], icon)
              row._chosen[ek] = icon
              -- retrouve le bouton de la grille correspondant et le grise
              if row._gridBtns and row._gridBtns[ek] then
                for _, tb in ipairs(row._gridBtns[ek]) do
                  if tb._mb_icon == icon then
                    SetGrey(tb, true)
                    row._selectedBtn = row._selectedBtn or {}
                    row._selectedBtn[ek] = tb
                    break
                  end
                end
              end
            end
          end
        end
      end

      return row
    end

    function MBS:Clear()
      self.entries = {}
      self.count = 0
      self.frame:Hide()
    end

    function MBS:AddOrUpdate(shamanName)
      local san = SanitizeName(shamanName)
      if not self.entries[san] then
        self:BuildForShaman(shamanName)
      end
      self.frame:Show()
    end

    function MBS:RefreshFromGroup()

      self:Clear()

      local function ConsiderUnit(unit)
        if not UnitExists(unit) then return end
        local name = GetUnitName(unit, true)
        local _, classTag = UnitClass(unit)
        if classTag == "SHAMAN" then
          if not MultiBot.IsBot or MultiBot.IsBot(name) then
            self:AddOrUpdate(name)
          end
        end
      end

      if IsInRaid() then
        for i=1, GetNumGroupMembers() do ConsiderUnit("raid"..i) end
      else
        ConsiderUnit("player")
        for i=1, GetNumSubgroupMembers() do ConsiderUnit("party"..i) end
      end

      if self.count == 0 then self.frame:Hide() end
	  if self.RestorePosition then self:RestorePosition() end
    end
  end
end

MultiBot.InitShamanQuick()

-- Première restauration juste après l'init (au cas où la barre soit déjà visible)
if MultiBot.ShamanQuick and MultiBot.ShamanQuick.RestorePosition then
  MultiBot.ShamanQuick:RestorePosition()
end

if MultiBot.TimerAfter then
  MultiBot.TimerAfter(0.5, function()
    if MultiBot and MultiBot.ShamanQuick and MultiBot.ShamanQuick.RefreshFromGroup then
      MultiBot.ShamanQuick:RefreshFromGroup()
    end
  end)
end

-- Minimap bootstrap is handled by OnEnable via LIFECYCLE_ENABLE_STEPS.

-- FINISH --

MultiBot.state = true
print("MultiBot")