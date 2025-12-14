-- Init des préférences minimap
MultiBotSave = MultiBotSave or {}
MultiBotSave.Minimap = MultiBotSave.Minimap or {}

-- =====================================================================
--  MINIMAP BUTTON (simple, sans LibDBIcon)
-- =====================================================================
do
  local BTN_NAME = "MultiBot_MinimapButton"
  local RADIUS   = 80  -- rayon d’ancrage au bord de la minimap

  local function deg2rad(d) return d * math.pi / 180 end

  local function UpdatePosition(self, angle)
    angle = angle or (MultiBotSave.Minimap and MultiBotSave.Minimap.angle) or 220
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
    MultiBotSave.Minimap = MultiBotSave.Minimap or {}
    MultiBotSave.Minimap.angle = angle
    UpdatePosition(self, angle)
  end

  function MultiBot.Minimap_Create()
    if _G[BTN_NAME] then
      MultiBot.Minimap_Refresh()
      return _G[BTN_NAME]
    end
    -- Respecter l’éventuel “hide”
    MultiBotSave.Minimap = MultiBotSave.Minimap or {}
    if MultiBotSave.Minimap.hide then return nil end

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
      GameTooltip:AddLine(MultiBot.info.butttitle, 1, 1, 1)
      GameTooltip:AddLine(MultiBot.info.buttontoggle, 0.9, 0.9, 0.9)
      GameTooltip:AddLine(MultiBot.info.buttonoptions, 0.9, 0.9, 0.9)
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
          -- fallback local si jamais les slash ne sont pas dispo
          local function affect(k, f)
            return k ~= "ShamanQuick" and k ~= "HunterQuick"
          end
          if MultiBot.state then
            for k, frm in pairs(MultiBot.frames or {}) do
              if affect(k, frm) then frm:Hide() end
            end
            MultiBot.state = false
          else
            for k, frm in pairs(MultiBot.frames or {}) do
              if affect(k, frm) then frm:Show() end
            end
            MultiBot.state = true
          end
          MultiBotSave["UIVisible"] = MultiBot.state and true or false
        end
      end
    end)

    UpdatePosition(b)
    b:Show()
    MultiBot.MinimapButton = b
    return b
  end

  function MultiBot.Minimap_Refresh()
    -- Toujours disposer d’une table SV valide ici
    MultiBotSave = MultiBotSave or {}
    MultiBotSave.Minimap = MultiBotSave.Minimap or {}

    local b = _G[BTN_NAME] or MultiBot.MinimapButton
    if MultiBotSave.Minimap and MultiBotSave.Minimap.hide then
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
--tMultiBar:SetMovable(true)
tMultiBar:SetMovable(true)
-- Évite les micro-dépassements avec certains UI scale qui finissent par décaler Y
tMultiBar:SetClampedToScreen(true)

-- LEFT --

local tLeft = tMultiBar.addFrame("Left", -76, 2, 32)
MultiBot.PromoteFrame(tLeft)

-- TANKER --

tLeft.addButton("Tanker", -170, 0, "ability_warrior_shieldbash", MultiBot.tips.tanker.master)
.doLeft = function(pButton)
	if(MultiBot.isTarget()) then MultiBot.ActionToGroup("@tank do attack my target") end
end

--  UI ATTACK REFORGED --
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
                                MultiBot.tips.attack[info.tip])

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
                                  MultiBot.tips.attack.master)

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

local tButton = tLeft.addButton("Mode", -102, 0, "Interface\\AddOns\\MultiBot\\Icons\\mode_passive.blp", MultiBot.tips.mode.master).setDisable()
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

tMode.addButton("Passive", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\mode_passive.blp", MultiBot.tips.mode.passive)
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

tMode.addButton("Grind", 0, 30, "Interface\\AddOns\\MultiBot\\Icons\\mode_grind.blp", MultiBot.tips.mode.grind)
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

tLeft.addButton("Stay", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.tips.stallow.stay)
.doLeft = function(pButton)
	if(MultiBot.ActionToGroup("stay")) then
		pButton.parent.buttons["Follow"].doShow()
		pButton.parent.buttons["ExpandFollow"].setDisable()
		pButton.parent.buttons["ExpandStay"].setEnable()
		pButton.doHide()
	end
end

tLeft.addButton("Follow", -68, 0, "Interface\\AddOns\\MultiBot\\Icons\\command_stay.blp", MultiBot.tips.stallow.follow).doHide()
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

-- FLEE --

--[[local tButton = tLeft.addButton("Flee", -34, 0, "Interface\\AddOns\\MultiBot\\Icons\\flee.blp", MultiBot.tips.flee.master)
tButton.doRight = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Flee"])
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToGroup("flee")
end

local tFlee = tLeft.addFrame("Flee", -36, 34)
tFlee:Hide()

local tButton = tFlee.addButton("Flee", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\flee.blp", MultiBot.tips.flee.flee)
tButton.doRight = function(pButton)
	MultiBot.SelectToGroupButton(pButton.parent.parent, "Flee", pButton.texture, "flee")
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToGroup("flee")
end

local tButton = tFlee.addButton("Ranged", 0, 30, "Interface\\AddOns\\MultiBot\\Icons\\flee_ranged.blp", MultiBot.tips.flee.ranged)
tButton.doRight = function(pButton)
	MultiBot.SelectToGroupButton(pButton.parent.parent, "Flee", pButton.texture, "@ranged flee")
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToGroup("@ranged flee")
end

local tButton = tFlee.addButton("Melee", 0, 60, "Interface\\AddOns\\MultiBot\\Icons\\flee_melee.blp", MultiBot.tips.flee.melee)
tButton.doRight = function(pButton)
	MultiBot.SelectToGroupButton(pButton.parent.parent, "Flee", pButton.texture, "@melee flee")
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToGroup("@melee flee")
end

local tButton = tFlee.addButton("Healer", 0, 90, "Interface\\AddOns\\MultiBot\\Icons\\flee_healer.blp", MultiBot.tips.flee.healer)
tButton.doRight = function(pButton)
	MultiBot.SelectToGroupButton(pButton.parent.parent, "Flee", pButton.texture, "@healer flee")
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToGroup("@healer flee")
end

local tButton = tFlee.addButton("Dps", 0, 120, "Interface\\AddOns\\MultiBot\\Icons\\flee_dps.blp", MultiBot.tips.flee.dps)
tButton.doRight = function(pButton)
	MultiBot.SelectToGroupButton(pButton.parent.parent, "Flee", pButton.texture, "@dps flee")
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToGroup("@dps flee")
end

local tButton = tFlee.addButton("Tank", 0, 150, "Interface\\AddOns\\MultiBot\\Icons\\flee_tank.blp", MultiBot.tips.flee.tank)
tButton.doRight = function(pButton)
	MultiBot.SelectToGroupButton(pButton.parent.parent, "Flee", pButton.texture, "@tank flee")
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToGroup("@tank flee")
end

local tButton = tFlee.addButton("Target", 0, 180, "Interface\\AddOns\\MultiBot\\Icons\\flee_target.blp", MultiBot.tips.flee.target)
tButton.doRight = function(pButton)
	MultiBot.SelectToTargetButton(pButton.parent.parent, "Flee", pButton.texture, "flee")
end
tButton.doLeft = function(pButton)
	MultiBot.ActionToTarget("flee")
end]]--

--  UI FLEE REFORGED --
function MultiBot.BuildFleeUI(tLeft)

  -- 1. Table
  local FLEE_BUTTONS = {
    -- label          icon                                                            cmd / taget          tip-key (MultiBot.tips.flee.<key>)
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
                                MultiBot.tips.flee[info.tip])

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
                                  MultiBot.tips.flee.master)

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

--  UI FORMATION REFORGED --

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
                    MultiBot.tips.format[string.lower(info.name)])
      .doLeft = function(btn)
        MultiBot.SelectToGroup(btn.parent.parent, "Format", btn.texture, info.cmd)
      end
  end

  -- Main Button --
  local fBtn = tLeft.addButton("Format", 0, 0,
                               "Interface\\AddOns\\MultiBot\\Icons\\formation_near.blp",
                               MultiBot.tips.format.master)

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

tLeft.addButton("Beast", -0, 0, "ability_mount_swiftredwindrider", MultiBot.tips.beast.master).doHide()
.doLeft = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Beast"])
end

local tBeast = tLeft.addFrame("Beast", -2, 34)
tBeast:Hide()

tBeast.addButton("Release", 0, 0, "spell_nature_spiritwolf", MultiBot.tips.beast.release)
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 2641")
end

tBeast.addButton("Revive", 0, 30, "ability_hunter_beastsoothe", MultiBot.tips.beast.revive)
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 982")
end

tBeast.addButton("Heal", 0, 60, "ability_hunter_mendpet", MultiBot.tips.beast.heal)
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 48990")
end

tBeast.addButton("Feed", 0, 90, "ability_hunter_beasttraining", MultiBot.tips.beast.feed)
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 6991")
end

tBeast.addButton("Call", 0, 120, "ability_hunter_beastcall", MultiBot.tips.beast.call)
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("cast 883")
end

--  CREATOR refactored --
local GENDER_BUTTONS = {
  { label = "Male",     gender = "male",    icon = "Interface\\Icons\\INV_Misc_Toy_02",        tip = MultiBot.tips.creator.gendermale      },
  { label = "Femelle",  gender = "female",  icon = "Interface\\Icons\\INV_Misc_Toy_04",        tip = MultiBot.tips.creator.genderfemale    },
  { label = "Aléatoire",gender = nil,       icon = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", tip = MultiBot.tips.creator.genderrandom    },
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
                                   MultiBot.tips.creator[string.lower(info.name)])

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
tLeft.addButton("Creator", -0, 0, "inv_helmet_145a", MultiBot.tips.creator.master)
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
tCreator.addButton("Inspect", 0, 300, "Interface\\AddOns\\MultiBot\\Icons\\filter_none.blp", MultiBot.tips.creator.inspect)
  .doLeft = function()
    if UnitExists("target") and UnitIsPlayer("target") then
      InspectUnit("target")
    else
      SendChatMessage(MultiBot.tips.creator.notarget, "SAY")
    end
  end

-- Button Init
local tButton = tCreator.addButton("Init", 0, 330, "inv_misc_enggizmos_27", MultiBot.tips.creator.init)

tButton.doRight = function()
  local function Iterate(unitPrefix, num)
    for i = 1, num do
      local name = UnitName(unitPrefix .. i)
      if name and name ~= UnitName("player") then
        if MultiBot.isRoster("players", name) then
          SendChatMessage(MultiBot.doReplace(MultiBot.info.player, "NAME", name), "SAY")
        elseif MultiBot.isRoster("members", name) then
          SendChatMessage(MultiBot.doReplace(MultiBot.info.member, "NAME", name), "SAY")
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
    SendChatMessage(MultiBot.info.group, "SAY")
  end
end

tButton.doLeft = function()
  if UnitExists("target") and UnitIsPlayer("target") then
    local name = UnitName("target")
    if MultiBot.isRoster("players", name) then
      SendChatMessage(MultiBot.info.players, "SAY")
    elseif MultiBot.isRoster("members", name) then
      SendChatMessage(MultiBot.info.members, "SAY")
    else
      MultiBot.InitAuto(name)
    end
  else
    SendChatMessage(MultiBot.info.target, "SAY")
  end
end

-- UNITS --

local tButton = tMultiBar.addButton("Units", -38, 0, "inv_scroll_04", MultiBot.tips.units.master)
tButton.roster = "players"
tButton.filter = "none"

tButton.doRight = function(pButton)
--[[	-- MEMBERBOTS --

	for i = 1, 50 do
		local tName, tRank, tIndex, tLevel, tClass = GetGuildRosterInfo(i)
		-- Ensure that the Counter is not bigger than the Amount of Members in Guildlist
		if(tName ~= nil and tLevel ~= nil and tClass ~= nil and tName ~= UnitName("player")) then
			local tMember = MultiBot.addMember(tClass, tLevel, tName)

			if(tMember.state == false)
			then tMember.setDisable()
			else tMember.setEnable()
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
		else
			break
		end
	end

	-- FRIENDBOTS --

	for i = 1, 50 do
		local tName, tLevel, tClass = GetFriendInfo(i)
		-- Ensure that the Counter is not bigger than the Amount of Members in Friendlist
		if(tName ~= nil and tLevel ~= nil and tClass ~= nil and tName ~= UnitName("player")) then
			local tFriend = MultiBot.addFriend(tClass, tLevel, tName)

			if(tFriend.state == false)
			then tFriend.setDisable()
			else tFriend.setEnable()
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
		else
			break
		end
	end

	pButton.doLeft(pButton, pButton.roster, pButton.filter)]]--

  -- Always refresh guild/friend rosters so their indexes stay in sync
  if(type(GuildRoster) == "function") then GuildRoster() end
  if(type(ShowFriends) == "function") then ShowFriends() end

  -- Reset indexes before rebuilding them
  MultiBot.index.members = {}
  MultiBot.index.classes.members = {}
  MultiBot.index.friends = {}
  MultiBot.index.classes.friends = {}

  -- MEMBERBOTS --
  local tMaxMembers = type(GetNumGuildMembers) == "function" and GetNumGuildMembers() or 50
  for i = 1, tMaxMembers do
    local tName, _, _, tLevel, tClass = GetGuildRosterInfo(i)
    if(tName ~= nil and tLevel ~= nil and tClass ~= nil and tName ~= UnitName("player")) then
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
    elseif(tName == nil) then
      break
    end
  end

  -- FRIENDBOTS --
  local tMaxFriends = type(GetNumFriends) == "function" and GetNumFriends() or 50
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
    elseif(tName == nil) then
      break
    end
  end

  -- Roster requiring server feedback (players/actives/favorites)
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

	--[[if(pButton.filter ~= "none")
	then tTable = MultiBot.index.classes[pButton.roster][pButton.filter]
	else tTable = MultiBot.index[pButton.roster]
	MultiBot.dprint("Units.tTable.size", tTable and table.getn(tTable) or 0) -- DEBUG
	end]]--

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
--	-- Fin Construction de la table source selon roster/filtre
--
--	local tButton = nil
--	local tFrame = nil
--	local tIndex = 0
--
--	if(tTable ~= nil)
--	then pButton.limit = table.getn(tTable)
--	else pButton.limit = 0
--	end
--
--	pButton.from = 1
--	pButton.to = 10
--
--	for i = 1, pButton.limit do
--		tIndex = (i - 1)%10 + 1
--		tFrame = tUnits.frames[tTable[i]]
--		tButton = tUnits.buttons[tTable[i]]
--		tButton.setPoint(0, (tUnits.size + 2) * (tIndex - 1))
--		if(tFrame ~=nil) then tFrame.setPoint(-34, (tUnits.size + 2) * (tIndex - 1) + 2) end
--
--		if(pButton.from <= i and pButton.to >= i) then
--			if(tFrame ~= nil and tButton.state) then tFrame:Show() end
--			tButton:Show()
--		end
--	end
--
--	if(pButton.limit < pButton.to)
--	then tUnits.frames["Control"].setPoint(-2, (tUnits.size + 2) * pButton.limit)
--	else tUnits.frames["Control"].setPoint(-2, (tUnits.size + 2) * pButton.to)
--	end

        -- Fin Construction de la table source selon roster/filtre

        local tButton = nil
        local tFrame = nil
        local tIndex = 0

        --
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
                                        MultiBot.tips.units.alliance)  -- ou units.horde si tu ajoutes le tooltip
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
                                     MultiBot.tips.units.filter)

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
                                  MultiBot.tips.units[string.lower(info.key)])

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
                                     MultiBot.tips.units.roster)

 --[[ -- Left Click = toggle sub frame  |  Right Click = select “Players”
  rootBtn.doLeft  = function(b) MultiBot.ShowHideSwitch(b.parent.frames.Roster) end
  rootBtn.doRight = function(b)
    local unitsBtn = MultiBot.frames.MultiBar.buttons.Units
    MultiBot.Select(b.parent, "Roster",
                    "Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp")
					MultiBot.dprint("Click Roster>Players") -- DEBUG
    unitsBtn.doLeft(unitsBtn, "players")
  end]]--

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
                                  tex, MultiBot.tips.units[cfg.tip])

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
  --local btn = tControl.buttons and tControl.buttons["Roster"]
  --if btn and btn.doRight then btn.doRight(btn) end
  local unitsBtn = MultiBot.frames
                 and MultiBot.frames.MultiBar
                 and MultiBot.frames.MultiBar.buttons
                 and MultiBot.frames.MultiBar.buttons.Units

  if unitsBtn and tControl and tControl.buttons and tControl.buttons.Roster then
    --MultiBot.Select(tControl, "Roster")
    local rosterBtn = tControl.buttons.Roster
    local tex = (rosterBtn and rosterBtn.texture) or "Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp"
    MultiBot.Select(tControl, "Roster", tex)
    unitsBtn.doLeft(unitsBtn, "players")
  end
end)

-- UNITS:BROWSE --

local tButton = tControl.addButton("Invite", 0, 60, "Interface\\AddOns\\MultiBot\\Icons\\invite.blp", MultiBot.tips.units.invite).setEnable()
tButton.doRight = function(pButton)
    if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then return end
    MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
    MultiBot.timer.invite.needs  = table.getn(MultiBot.index[MultiBot.timer.invite.roster])
    MultiBot.timer.invite.index  = 1
    MultiBot.auto.invite = true
    SendChatMessage(MultiBot.info.starting, "SAY")
end

tButton.doLeft = function(pButton)
	if(pButton.state) then MultiBot.ShowHideSwitch(pButton.parent.frames["Invite"]) end
end

local tInvite = tControl.addFrame("Invite", -30, 62)
tInvite:Hide()

tInvite.addButton("Party+5", 0, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_party_5.blp", MultiBot.tips.units.inviteParty5)
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.info.wait, "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = MultiBot.IF(tRaid > 0, 5 - tRaid, MultiBot.IF(tParty > 0, 4 - tParty, 4))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.info.starting, "SAY")
end

tInvite.addButton("Raid+10", 56, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_10.blp", MultiBot.tips.units.inviteRaid10)
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.info.wait, "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = 10 - MultiBot.IF(tRaid > 0, tRaid, MultiBot.IF(tParty > 0, tParty + 1, 1))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.info.starting, "SAY")
end

tInvite.addButton("Raid+25", 82, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_25.blp", MultiBot.tips.units.inviteRaid25)
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.info.wait, "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = 25 - MultiBot.IF(tRaid > 0, tRaid, MultiBot.IF(tParty > 0, tParty + 1, 1))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.info.starting, "SAY")
end

tInvite.addButton("Raid+40", 108, 0, "Interface\\AddOns\\MultiBot\\Icons\\invite_raid_40.blp", MultiBot.tips.units.inviteRaid40)
.doLeft = function(pButton)
	if(MultiBot.auto.invite) then return SendChatMessage(MultiBot.info.wait, "SAY") end
	local tRaid = GetNumRaidMembers()
	local tParty = GetNumPartyMembers()
	MultiBot.timer.invite.roster = MultiBot.frames["MultiBar"].buttons["Units"].roster
	MultiBot.timer.invite.needs = 40 - MultiBot.IF(tRaid > 0, tRaid, MultiBot.IF(tParty > 0, tParty + 1, 1))
	MultiBot.timer.invite.index = 1
	MultiBot.auto.invite = true
	pButton.parent:Hide()
	SendChatMessage(MultiBot.info.starting, "SAY")
end

--tControl.addButton("Browse", 0, 90, "Interface\\AddOns\\MultiBot\\Icons\\browse.blp", MultiBot.tips.units.browse)
--.doLeft = function(pButton)
--	local tMaster = MultiBot.frames["MultiBar"].buttons["Units"]
--	local tFrom = tMaster.from + 10
--	local tTo = tMaster.to + 10
--
--	if(tMaster.filter ~= "none")
--	then tTable = MultiBot.index.classes[tMaster.roster][tMaster.filter]
--	else tTable = MultiBot.index[tMaster.roster]
--	end
--
--	local tUnits = tMaster.parent.frames["Units"]
--	local tButton = nil
--	local tFrame = nil
--	local tIndex = 0
--
--	if(tFrom > tMaster.limit) then
--		tFrom = 1
--		tTo = 10
--	end
--
--	if(tTo > tMaster.limit) then
--		tTo = tMaster.limit
--	end
--
--	for i = 1, tMaster.limit do
--		tFrame = tUnits.frames[tTable[i]]
--		tButton = tUnits.buttons[tTable[i]]
--
--		--[[if(tMaster.from <= i and tMaster.to >= i) then
--			if(tFrame ~= nil) then tFrame:Hide() end
--			tButton:Hide()
--		end]]--
--        if (tMaster.from <= i and tMaster.to >= i) then
--            if (tFrame ~= nil) then tFrame:Hide() end
--            if (tButton ~= nil) then tButton:Hide() end
--        end
--
--		if(tFrom <= i and tTo >= i) then
--			--if(tFrame ~= nil and tButton.state) then tFrame:Show() end 
--			--tButton:Show()
--            -- Afficher uniquement si le bouton existe
--            if (tButton ~= nil) then
--				tIndex = tIndex + 1
--                -- Montrer le frame si présent et si le bouton est actif
--                if (tFrame ~= nil and tButton.state) then
--                    tFrame:Show()
--                end
--                tButton:Show()
--            end
--		end
--	end
--
--	tMaster.from = tFrom
--	tMaster.to = tTo
--
--	tUnits.frames["Control"].setPoint(-2, (tUnits.size + 2) * tIndex)
--end

-- Fonction Browse corrigée
tControl.addButton("Browse", 0, 90, "Interface\\AddOns\\MultiBot\\Icons\\browse.blp", MultiBot.tips.units.browse)
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

local tButton = tMultiBar.addButton("Main", 0, 0, "inv_gizmo_02", MultiBot.tips.main.master)
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

tMain.addButton("Coords", 0, 0, "inv_gizmo_03", MultiBot.tips.main.coords)
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

tMain.addButton("Masters", 0, 34, "mail_gmicon", MultiBot.tips.main.masters).setDisable()
.doLeft = function(pButton)
	if(MultiBot.GM == false) then return SendChatMessage(MultiBot.info.rights, "SAY") end
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

tMain.addButton("RTSC", 0, 68, "ability_hunter_markedfordeath", MultiBot.tips.main.rtsc).setDisable()
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

tMain.addButton("Raidus", 0, 102, "inv_misc_head_dragon_01", MultiBot.tips.main.raidus).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.raidus.setRaidus()
		MultiBot.raidus:Show()
	else
		MultiBot.raidus:Hide()
	end
end

tMain.addButton("Creator", 0, 136, "inv_helmet_145a", MultiBot.tips.main.creator).setDisable()
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

tMain.addButton("Beast", 0, 170, "ability_mount_swiftredwindrider", MultiBot.tips.main.beast).setDisable()
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

tMain.addButton("Expand", 0, 204, "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp", MultiBot.tips.main.expand).setDisable()
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

tMain.addButton("Release", 0, 238, "achievement_bg_xkills_avgraveyard", MultiBot.tips.main.release).setDisable()
.doLeft = function(pButton)
	if(MultiBot.OnOffSwitch(pButton)) then
		MultiBot.auto.release = true
	else
		MultiBot.auto.release = false
	end
end

tMain.addButton("Stats", 0, 272, "inv_scroll_08", MultiBot.tips.main.stats).setDisable()
.doLeft = function(pButton)
	if(GetNumRaidMembers() > 0) then return SendChatMessage(MultiBot.info.stats, "SAY") end
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

local tButton = tMain.addButton("Reward", 0, 306, "Interface\\AddOns\\MultiBot\\Icons\\reward.blp", MultiBot.tips.main.reward).setDisable()
tButton.doRight = function(pButton)
	if(table.getn(MultiBot.reward.rewards) > 0 and table.getn(MultiBot.reward.units) > 0) then MultiBot.reward:Show() end
end
tButton.doLeft = function(pButton)
	MultiBot.reward.state = MultiBot.OnOffSwitch(pButton)
end

tMain.addButton("Reset", 0, 340, "inv_misc_tournaments_symbol_gnome", MultiBot.tips.main.reset)
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("reset botAI")
end

tMain.addButton("Actions", 0, 374, "inv_helmet_02", MultiBot.tips.main.action)
.doLeft = function(pButton)
	MultiBot.ActionToTargetOrGroup("reset")
end

-- [AJOUT] Bouton Options (ouvre/ferme le panneau des sliders)
local tBtnOptions = tMain.addButton("Options", 0, 404, "inv_misc_gear_02", MultiBot.tips.main.options)
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
                                      MultiBot.tips.game.master)
  mainBtn:doHide()                                      -- masqué par défaut

  mainBtn.doLeft  = function(b) MultiBot.ShowHideSwitch(b.parent.frames["Masters"]) end
  mainBtn.doRight = function()  MultiBot.doSlash("/MultiBot", "")                   end

  -- 2. Frame "Masters" : contain the buttons
  local tMasters = tMultiBar.addFrame("Masters", 36, 38)
  tMasters:Hide()

  -- 3. Button NecroNet (toggle)
  local necroBtn = tMasters.addButton("NecroNet", 0, 0,
                                      "achievement_bg_xkills_avgraveyard",
                                      MultiBot.tips.game.necronet)
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
                                       MultiBot.tips.game.portal)
  local tPortal   = tMasters.addFrame("Portal", 30, 36) ; tPortal:Hide()

  portalBtn.doLeft = function() MultiBot.ShowHideSwitch(tPortal) end

  -- Helper for portal
  local function AddMemoryGem(label, x, icon, tipKey)
    local gem = tPortal.addButton(label, x, 0, icon,
                                  MultiBot.doReplace(MultiBot.tips.game.memory,
                                                      "ABOUT", MultiBot.info.location))
    gem:setDisable()
    gem.goMap, gem.goX, gem.goY, gem.goZ = "",0,0,0

    -- Right click to update/delete
    gem.doRight = function(b)
      if not b.state then
        return SendChatMessage(MultiBot.info.itlocation, "SAY")
      end
      b.tip = MultiBot.doReplace(MultiBot.tips.game.memory, "ABOUT",
                                 MultiBot.info.location)
      b:setDisable()
    end

    -- Left click to Save or teleport
    gem.doLeft = function(b)
      local player = MultiBot.getBot(UnitName("player"))
      player.waitFor = player.waitFor or ""

      if player.waitFor ~= "" then
        return SendChatMessage(MultiBot.info.saving, "SAY")
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
               MultiBot.tips.game.memory)
  AddMemoryGem("Green", 30, "inv_jewelcrafting_gem_13",
               MultiBot.tips.game.memory)
  AddMemoryGem("Blue",  60, "inv_jewelcrafting_gem_17",
               MultiBot.tips.game.memory)

  -- 5. Shortcuts for : Itemus / Iconos / Summon / Appear
  local UTIL_BUTTONS = {
    { label="Itemus", y= 68, icon="inv_box_01",        tip=MultiBot.tips.game.itemus,
      click=function()
        if MultiBot.ShowHideSwitch(MultiBot.itemus) then
          MultiBot.itemus.addItems()
        end
      end },

    { label="Iconos", y=102, icon="inv_mask_01",       tip=MultiBot.tips.game.iconos,
      click=function()
        if MultiBot.ShowHideSwitch(MultiBot.iconos) then
          MultiBot.iconos.addIcons()
        end
      end },

    { label="Summon", y=136, icon="spell_holy_prayerofspirit", tip=MultiBot.tips.game.summon,
      click=function() MultiBot.doDotWithTarget(".summon") end },

    { label="Appear", y=170, icon="spell_holy_divinespirit",   tip=MultiBot.tips.game.appear,
      click=function() MultiBot.doDotWithTarget(".appear") end },
  }

  for _, b in ipairs(UTIL_BUTTONS) do
    tMasters.addButton(b.label, 0, b.y, b.icon, b.tip).doLeft = b.click
  end

  -- 6. DelSV Button
  StaticPopupDialogs["MULTIBOT_DELETE_SV"] = {
      text         = MultiBot.tips.game.delsvwarning,
      button1      = YES,
      button2      = NO,
      OnAccept     = function()
          if wipe then wipe(MultiBotGlobalSave)
          else          for k in pairs(MultiBotGlobalSave) do MultiBotGlobalSave[k]=nil end end
          ReloadUI()
      end,
      timeout      = 0,   whileDead=true, hideOnEscape=true,
  }

  tMasters.addButton("DelSV", 0, 204, "ability_golemstormbolt",
                     MultiBot.tips.game.delsv, "ActionButtonTemplate")
    .doLeft = function() StaticPopup_Show("MULTIBOT_DELETE_SV") end
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

-- HIDDEN TOOLTIP TO CATCH LOC --
local LocalizeQuestTooltip = CreateFrame("GameTooltip", "MB_LocalizeQuestTooltip", UIParent, "GameTooltipTemplate")
LocalizeQuestTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetLocalizedQuestName(questID)
    LocalizeQuestTooltip:ClearLines()
    -- construit une hyperlink quest:<ID>
    LocalizeQuestTooltip:SetHyperlink("quest:"..questID)
    -- lit la première ligne du tooltip
    local textObj = _G["MB_LocalizeQuestTooltipTextLeft1"]
    return (textObj and textObj:GetText()) or tostring(questID)
end
-- END HIDDEN TOOLTIP --

-- MAIN BUTTON --
local tButton = tRight.addButton("Quests Menu", 0, 0,
                                 "achievement_quests_completed_06",
                                 MultiBot.tips.quests.main)
local tQuestMenu = tRight.addFrame("QuestMenu", -2, 64)
tQuestMenu:Hide()
tButton.doLeft  = function(p) MultiBot.ShowHideSwitch(p.parent.frames["QuestMenu"]) end
tButton.doRight = tButton.doLeft
-- END MAIN BUTTON --

-- BUTTON Accept * --
tQuestMenu.addButton("AcceptAll", 0, 30,
                     "inv_misc_note_02", MultiBot.tips.quests.accept)
.doLeft = function() MultiBot.ActionToGroup("accept *") end
-- END BUTTON Accept * --

-- POP-UP Frame for Quests --
local tQuests = CreateFrame("Frame", "MB_QuestPopup", UIParent)
tQuests:SetSize(370, 460)
tQuests:SetPoint("CENTER")
tQuests:SetFrameStrata("DIALOG")
tQuests:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true, tileSize = 32, edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
tQuests:EnableMouse(true)
tQuests:SetMovable(true)
tQuests:RegisterForDrag("LeftButton")
tQuests:SetScript("OnDragStart", tQuests.StartMoving)
tQuests:SetScript("OnDragStop",  tQuests.StopMovingOrSizing)
tQuests:Hide()

-- bouton X
local close = CreateFrame("Button", nil, tQuests, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", -2, -2)

-- barre de titre
local title = tQuests:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -10)
title:SetText("Quêtes du personnage")

-- ScrollFrame + ScrollBar
local scrollFrame = CreateFrame("ScrollFrame", "MB_QuestScroll", tQuests, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 14, -38)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 14)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetWidth(1)              -- largeur auto
scrollFrame:SetScrollChild(content)
-- END POP-UP Frame for “Quests” --

-- BUTTON Quests --
local tListBtn = tQuestMenu.addButton("Quests", 0, -30,
                                      "inv_misc_book_07", MultiBot.tips.quests.master)
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
local tBotPopup = CreateFrame("Frame", "MB_BotQuestPopup", UIParent)
tBotPopup:SetSize(360, 400)
tBotPopup:SetPoint("CENTER")
tBotPopup:SetFrameStrata("DIALOG")
tBotPopup:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true, tileSize = 32, edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
tBotPopup:EnableMouse(true)
tBotPopup:SetMovable(true)
tBotPopup:RegisterForDrag("LeftButton")
tBotPopup:SetScript("OnDragStart", tBotPopup.StartMoving)
tBotPopup:SetScript("OnDragStop",  tBotPopup.StopMovingOrSizing)
tBotPopup:Hide()

local closeBtn = CreateFrame("Button", nil, tBotPopup, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -2, -2)

local header = tBotPopup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
header:SetPoint("TOP", 0, -10)
header:SetText(MultiBot.tips.quests.incomplist)

local scroll = CreateFrame("ScrollFrame", "MB_BotQuestScroll", tBotPopup, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 14, -38)
scroll:SetPoint("BOTTOMRIGHT", -30, 14)

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
        botLine:SetText(MultiBot.tips.quests.botsword.. table.concat(data.bots, ", "))

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
    MultiBot.tips.quests.incompleted)

local btnGroup = tQuestMenu.addButton("BotQuestsIncompGroup", 31, 90,
                                        "Interface\\Icons\\INV_Crate_08",
                                        MultiBot.tips.quests.sendpartyraid)
btnGroup:doHide()

local btnWhisper = tQuestMenu.addButton("BotQuestsIncompWhisper", 61, 90,
                                          "Interface\\Icons\\INV_Crate_08",
                                          MultiBot.tips.quests.sendwhisp)
btnWhisper:doHide()

local function SendIncomp(method)

MultiBot._awaitingQuestsAll = false
	MultiBot._lastIncMode = method
    if method == "WHISPER" then
        local bot = UnitName("target")
        if not bot or not UnitIsPlayer("target") then
            UIErrorsFrame:AddMessage(MultiBot.tips.quests.questcomperror, 1, 0.2, 0.2, 1)
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
local tBotCompPopup = CreateFrame("Frame", "MB_BotQuestCompPopup", UIParent)
tBotCompPopup:SetSize(360, 400)
tBotCompPopup:SetPoint("CENTER")
tBotCompPopup:SetFrameStrata("DIALOG")
tBotCompPopup:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true, tileSize = 32, edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
tBotCompPopup:EnableMouse(true)
tBotCompPopup:SetMovable(true)
tBotCompPopup:RegisterForDrag("LeftButton")
tBotCompPopup:SetScript("OnDragStart", tBotCompPopup.StartMoving)
tBotCompPopup:SetScript("OnDragStop",  tBotCompPopup.StopMovingOrSizing)
tBotCompPopup:Hide()

local closeBtn2 = CreateFrame("Button", nil, tBotCompPopup, "UIPanelCloseButton")
closeBtn2:SetPoint("TOPRIGHT", -2, -2)

local header2 = tBotCompPopup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
header2:SetPoint("TOP", 0, -10)
header2:SetText(MultiBot.tips.quests.complist)

local scroll2 = CreateFrame("ScrollFrame", "MB_BotQuestCompScroll", tBotCompPopup, "UIPanelScrollFrameTemplate")
scroll2:SetPoint("TOPLEFT", 14, -38)
scroll2:SetPoint("BOTTOMRIGHT", -30, 14)

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
        botLine:SetText(MultiBot.tips.quests.botsword .. table.concat(data.bots, ", "))

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
    MultiBot.tips.quests.completed)

local btnCompGroup = tQuestMenu.addButton("BotQuestsCompGroup", 31, 60,
    "Interface\\Icons\\INV_Crate_09",
    MultiBot.tips.quests.sendpartyraid)
btnCompGroup:doHide()

local btnCompWhisper = tQuestMenu.addButton("BotQuestsCompWhisper", 61, 60,
    "Interface\\Icons\\INV_Crate_09",
    MultiBot.tips.quests.sendwhisp)
btnCompWhisper:doHide()

local function SendComp(method)
MultiBot._awaitingQuestsAll = false
    MultiBot._lastCompMode = method
    if method == "WHISPER" then
        local bot = UnitName("target")
        if not bot or not UnitIsPlayer("target") then
			UIErrorsFrame:AddMessage(MultiBot.tips.quests.questcomperror, 1, 0.2, 0.2, 1)
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
    MultiBot.tips.quests.talk)

btnTalk.doLeft = function()
    if not UnitExists("target") or UnitIsPlayer("target") then -- On vérifie qu'on cible bien un PNJ
        UIErrorsFrame:AddMessage(MultiBot.tips.quests.talkerror, 1, 0.2, 0.2, 1)
        return
    end
    MultiBot.ActionToGroup("talk") -- Envoie "talk" à tout le groupe ou raid
end

tRight.buttons["BotQuestsTalk"] = btnTalk
-- END BUTTON TALK --

-- BUTTON QUESTS ALL --

-- POPUP Quests All
local tBotAllPopup = CreateFrame("Frame", "MB_BotQuestAllPopup", UIParent)
tBotAllPopup:SetSize(400, 440)
tBotAllPopup:SetPoint("CENTER")
tBotAllPopup:SetFrameStrata("DIALOG")
tBotAllPopup:SetBackdrop({
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true, tileSize = 32, edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
tBotAllPopup:EnableMouse(true)
tBotAllPopup:SetMovable(true)
tBotAllPopup:RegisterForDrag("LeftButton")
tBotAllPopup:SetScript("OnDragStart", tBotAllPopup.StartMoving)
tBotAllPopup:SetScript("OnDragStop",  tBotAllPopup.StopMovingOrSizing)
tBotAllPopup:Hide()

-- On expose immédiatement pour qu'il existe dans SendAll
MultiBot.tBotAllPopup = tBotAllPopup

-- bouton X
local closeBtnAll = CreateFrame("Button", nil, tBotAllPopup, "UIPanelCloseButton")
closeBtnAll:SetPoint("TOPRIGHT", -2, -2)

local headerAll = tBotAllPopup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
headerAll:SetPoint("TOP", 0, -10)
headerAll:SetText(MultiBot.tips.quests.alllist)

-- ScrollFrame
local scrollAll = CreateFrame("ScrollFrame", "MB_BotQuestAllScroll", tBotAllPopup, "UIPanelScrollFrameTemplate")
scrollAll:SetPoint("TOPLEFT", 12, -38)
scrollAll:SetPoint("BOTTOMRIGHT", -30, 14)

local contentAll = CreateFrame("Frame", nil, scrollAll)
contentAll:SetWidth(1)
scrollAll:SetScrollChild(contentAll)
tBotAllPopup.content = contentAll

-- Helper pour vider le contenu
-- function MultiBot.ClearAllContent()
--     for _, child in ipairs({ contentAll:GetChildren() }) do
--         child:Hide()
--         child:SetParent(nil)
--     end
--     if contentAll.text then contentAll.text:SetText("") end
-- end

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
    header:SetText(MultiBot.tips.quests.compheader)
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
        botsLine:SetText(MultiBot.tips.quests.botsword .. table.concat(data.bots, ", "))
        y = y - 16
    end

    y = y - 10

    -- === Header Quêtes incomplètes ===
    local header2 = contentAll:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    header2:SetPoint("TOPLEFT", 0, y)
    header2:SetText(MultiBot.tips.quests.incompheader)
    y = y - 28

    -- Affiche toutes les quêtes incomplètes
    for id, data in pairs(incomplete) do
        local line = CreateFrame("Frame", nil, contentAll)
        line:SetSize(360, 20)
        line:SetPoint("TOPLEFT", 0, y)
        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture("Interface\\Icons\\inv_misc_note_02")
        icon:SetSize(20,20); icon:SetPoint("LEFT")
        -- local link = ("|cffffff00|Hquest:%s:0|h[%s]|h|r"):format(id, data.name)
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
        botsLine:SetText(MultiBot.tips.quests.botsword .. table.concat(data.bots, ", "))
        y = y - 16
    end

    contentAll:SetHeight(-y + 4)
    scrollAll:SetVerticalScroll(0)
end


MultiBot.BuildAggregatedAllList = BuildAggregatedAllList


-- BOUTONS All
local btnAll = tQuestMenu.addButton("BotQuestsAll", 0, 120,
    "Interface\\Icons\\INV_Misc_Book_09",
    MultiBot.tips.quests.allcompleted)

local btnAllGroup = tQuestMenu.addButton("BotQuestsAllGroup", 31, 120,
    "Interface\\Icons\\INV_Misc_Book_09",
    MultiBot.tips.quests.sendpartyraid)
btnAllGroup:doHide()

local btnAllWhisper = tQuestMenu.addButton("BotQuestsAllWhisper", 61, 120,
    "Interface\\Icons\\INV_Misc_Book_09",
    MultiBot.tips.quests.sendwhisp)
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
            UIErrorsFrame:AddMessage(MultiBot.tips.quests.questcomperror, 1, 0.2, 0.2, 1)
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
    f.text:SetText("Loading…")
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
function MultiBot.ShowGameObjectPopup()

    if MultiBot.GameObjPopup and MultiBot.GameObjPopup:IsShown() then
        MultiBot.GameObjPopup:Hide()
    end

    -- Crée la popup
    if not MultiBot.GameObjPopup then
        local popup = CreateFrame("Frame", "MB_GameObjPopup", UIParent)
        popup:SetSize(340, 340)
        popup:SetPoint("CENTER")
        popup:SetFrameStrata("DIALOG")
        popup:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 32, edgeSize = 16,
            insets   = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        popup:EnableMouse(true)
        popup:SetMovable(true)
        popup:RegisterForDrag("LeftButton")
        popup:SetScript("OnDragStart", popup.StartMoving)
        popup:SetScript("OnDragStop",  popup.StopMovingOrSizing)
        local close = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        local title = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText(MultiBot.tips.quests.gobsfound)
        -- ScrollFrame
        local scrollFrame = CreateFrame("ScrollFrame", "MB_GameObjScroll", popup, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 14, -38)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 14)
        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetWidth(1)
        scrollFrame:SetScrollChild(content)
        popup.content = content
        MultiBot.GameObjPopup = popup
        MultiBot.GameObjPopup.scrollFrame = scrollFrame

		  -- Bouton "Tout copier"
	    if not popup.copyBtn then
		  local copyBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
		      copyBtn:SetSize(120, 20)
		      copyBtn:SetPoint("BOTTOMRIGHT", -40, 12)
		      copyBtn:SetText(MultiBot.tips.quests.gobselectall)
		      popup.copyBtn = copyBtn
		      copyBtn:SetScript("OnClick", function()
			  MultiBot.ShowGameObjectCopyBox()
		  end)
	   end
	end

    -- Nettoie le contenu
    local content = MultiBot.GameObjPopup.content
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end

    -- Affiche la liste pour chaque bot auteur
    local y = -4
    for bot, lines in pairs(MultiBot.LastGameObjectSearch) do
        -- Titre bot
        local botLine = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        botLine:SetPoint("TOPLEFT", 8, y)
        botLine:SetText("Bot: |cff80ff80"..bot.."|r")
        y = y - 18
        -- Chaque ligne du résultat
        for _, txt in ipairs(lines) do
            local l = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            l:SetPoint("TOPLEFT", 24, y)
            l:SetText(txt)
            y = y - 16
        end
        y = y - 8
    end
    content:SetHeight(-y + 4)
    MultiBot.GameObjPopup.scrollFrame:SetVerticalScroll(0)
    MultiBot.GameObjPopup:Show()
end

function MultiBot.ShowGameObjectCopyBox()
		-- Ferme la popup GameObj principale si elle est ouverte
		if MultiBot.GameObjPopup and MultiBot.GameObjPopup:IsShown() then
			MultiBot.GameObjPopup:Hide()
		end

		if not MultiBot.GameObjCopyBox then
        local box = CreateFrame("Frame", "MB_GameObjCopyBox", UIParent)
        box:SetSize(380, 240)
        box:SetPoint("CENTER")
        box:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 32, edgeSize = 16,
            insets   = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        box:SetFrameStrata("DIALOG")
        local close = CreateFrame("Button", nil, box, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() box:Hide() end)

        local label = box:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        label:SetPoint("TOP", 0, -10)
        label:SetText(MultiBot.tips.quests.gobctrlctocopy)

        -- EditBox multi-ligne
        local edit = CreateFrame("EditBox", nil, box)
        edit:SetFontObject("ChatFontNormal")
        edit:SetWidth(340)
        edit:SetHeight(180)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(true)
        edit:EnableMouse(true)
        edit:SetPoint("TOP", 0, -40)
        edit:SetScript("OnEscapePressed", function(self) box:Hide() end)
        edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        box.edit = edit
        MultiBot.GameObjCopyBox = box
    end

    -- Génère le texte à copier
    local text = ""
    for bot, lines in pairs(MultiBot.LastGameObjectSearch) do
        text = text .. ("Bot: %s\n"):format(bot)
        for _, l in ipairs(lines) do
            text = text .. l .. "\n"
        end
        text = text .. "\n"
    end
    MultiBot.GameObjCopyBox.edit:SetText(text)
    MultiBot.GameObjCopyBox.edit:HighlightText()
    MultiBot.GameObjCopyBox:Show()
end

local PROMPT
function ShowPrompt(title, onOk, defaultText)
    if not PROMPT then
        PROMPT = CreateFrame("Frame", "MBUniversalPrompt", UIParent)
        PROMPT:SetSize(260, 90)
        PROMPT:SetPoint("CENTER")
        PROMPT:SetBackdrop({
            bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileSize=32, edgeSize=16,
            insets={left=4, right=4, top=4, bottom=4}
        })
        PROMPT:SetBackdropColor(0,0,0,0.9)
        PROMPT:SetFrameStrata("DIALOG")
        PROMPT:SetMovable(true)
        PROMPT:EnableMouse(true)
        PROMPT:RegisterForDrag("LeftButton")
        PROMPT:SetScript("OnDragStart", PROMPT.StartMoving)
        PROMPT:SetScript("OnDragStop",  PROMPT.StopMovingOrSizing)

        local btnClose = CreateFrame("Button", nil, PROMPT, "UIPanelCloseButton")
        btnClose:SetPoint("TOPRIGHT", -5, -5)
        btnClose:SetScript("OnClick", function() PROMPT:Hide() end)

        local e = CreateFrame("EditBox", nil, PROMPT, "InputBoxTemplate")
        e:SetAutoFocus(true)
        e:SetSize(200, 20)
        e:SetTextColor(1,1,1)
        e:SetPoint("TOP", 0, -30)
        PROMPT.EditBox = e
        e:SetScript("OnEscapePressed", function(self) PROMPT:Hide() end)

        local ok = CreateFrame("Button", nil, PROMPT, "UIPanelButtonTemplate")
        ok:SetSize(60, 20)
        ok:SetPoint("BOTTOM", 0, 10)
        ok:SetText("OK")
        PROMPT.OkBtn = ok
    end

    if not PROMPT.Title then
        PROMPT.Title = PROMPT:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        PROMPT.Title:SetPoint("TOP", 0, -10)
    end

    PROMPT.Title:SetText(title or "Enter Value")
    PROMPT:Show()
    PROMPT.EditBox:SetText(defaultText or "")
    PROMPT.EditBox:SetFocus()

    PROMPT.OkBtn:SetScript("OnClick", function()
        local text = PROMPT.EditBox:GetText()
        if text and text~="" then
            onOk(text)
        else
            UIErrorsFrame:AddMessage(MultiBot.tips.quests.gobsnameerror, 1, 0.2, 0.2, 1)
            return
        end
        PROMPT:Hide()
    end)
    PROMPT.EditBox:SetScript("OnEnterPressed", function(self)
        PROMPT.OkBtn:Click()
    end)
end

-- BOUTON PRINCIPAL "Use Game Object"
-- Boutons "Use Game Object"
local btnGob = tQuestMenu.addButton("BotUseGOB", 0, 150,
    "Interface\\Icons\\inv_misc_spyglass_01", MultiBot.tips.quests.gobsmaster)

local btnGobName = tQuestMenu.addButton("BotUseGOBName", 31, 150,
    "Interface\\Icons\\inv_misc_note_05", MultiBot.tips.quests.gobenter)
btnGobName:doHide()

local btnGobSearch = tQuestMenu.addButton("BotUseGOBSearch", 61, 150,
    "Interface\\Icons\\inv_misc_spyglass_02", MultiBot.tips.quests.gobsearch)
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
        MultiBot.tips.quests.gobpromptname,
        function(gobName)
            gobName = gobName:gsub("^%s+", ""):gsub("%s+$", "")
            if gobName == "" then
                UIErrorsFrame:AddMessage(MultiBot.tips.quests.goberrorname , 1, 0.2, 0.2, 1)
                return
            end
            local bot = UnitName("target")
            if not bot or not UnitIsPlayer("target") then
                UIErrorsFrame:AddMessage(MultiBot.tips.quests.gobselectboterror, 1, 0.2, 0.2, 1)
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

-- DRINK --

tRight.addButton("Drink", 34, 0, "inv_drink_24_sealwhey", MultiBot.tips.drink.group)
.doLeft = function(pButton)
	MultiBot.ActionToGroup("drink")
end

-- RELEASE --

tRight.addButton("Release", 68, 0, "achievement_bg_xkills_avgraveyard", MultiBot.tips.release.group)
.doLeft = function(pButton)
	MultiBot.ActionToGroup("release")
end

-- REVIVE --

tRight.addButton("Revive", 102, 0, "spell_holy_guardianspirit", MultiBot.tips.revive.group)
.doLeft = function(pButton)
	MultiBot.ActionToGroup("revive")
end

-- SUMALL --

tRight.addButton("Summon", 136, 0, "ability_hunter_beastcall", MultiBot.tips.summon.group)
.doLeft = function(pButton)
	MultiBot.ActionToGroup("summon")
end

-- INVENTORY --

MultiBot.inventory = MultiBot.newFrame(MultiBot, -700, -144, 32, 442, 884)
MultiBot.inventory.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Inventory.blp")
MultiBot.inventory.addText("Title", "Inventory", "CENTER", -58, 429, 12)
MultiBot.inventory.action = "s"
MultiBot.inventory:SetMovable(true)
MultiBot.inventory:Hide()

MultiBot.inventory.movButton("Move", -406, 849, 34, MultiBot.tips.move.inventory)

MultiBot.inventory.wowButton("X", -126, 862, 15, 18, 13)
.doLeft = function(pButton)
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tButton = tUnits.frames[MultiBot.inventory.name].buttons["Inventory"]
	tButton.doLeft(tButton)
end

MultiBot.inventory.addButton("Sell", -94, 806, "inv_misc_coin_16", MultiBot.tips.inventory.sell).setEnable()
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
MultiBot.inventory.addButton("SellGrey", -94, 768, "inv_misc_coin_03", MultiBot.tips.inventory.sellgrey)
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
MultiBot.inventory.addButton("SellVendor", -94, 731, "inv_misc_coin_04", MultiBot.tips.inventory.sellvendor)
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

MultiBot.inventory.addButton("Equip", -94, 694, "inv_helmet_22", MultiBot.tips.inventory.equip).setDisable()
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

MultiBot.inventory.addButton("Use", -94, 657, "inv_gauntlets_25", MultiBot.tips.inventory.use).setDisable()
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

MultiBot.inventory.addButton("Trade", -94, 620, "achievement_reputation_01", MultiBot.tips.inventory.trade).setDisable()
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

MultiBot.inventory.addButton("Destroy", -94, 583, "inv_hammer_15", MultiBot.tips.inventory.drop).setDisable()
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

MultiBot.inventory.addButton("Open", -94, 322.5, "inv_misc_gift_05", MultiBot.tips.inventory.open)
.doLeft = function(pButton)
	SendChatMessage("open items", "WHISPER", nil, pButton.getName())
end

local tFrame = MultiBot.inventory.addFrame("Items", -397, 807, 32)
tFrame:Show()

-- STATS --

MultiBot.stats = MultiBot.newFrame(MultiBot, -60, 560, 32)
MultiBot.stats:SetMovable(true)
MultiBot.stats:Hide()

MultiBot.stats.movButton("Move", 0, -80, 160, MultiBot.tips.move.stats)

MultiBot.addStats(MultiBot.stats, "party1", 0,    0, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party2", 0,  -60, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party3", 0, -120, 32, 192, 96)
MultiBot.addStats(MultiBot.stats, "party4", 0, -180, 32, 192, 96)

-- ITEMUS REFACTOR AND IMPROVMENT --

MultiBot.itemus = MultiBot.newFrame(MultiBot, -860, -144, 32, 442, 884)
MultiBot.itemus.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Inventory.blp")
MultiBot.itemus.addText("Title", "Itemus", "CENTER", -57, 429, 13)
MultiBot.itemus.addText("Pages", "0/0", "CENTER", -57, 409, 13)
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

-- ====== POPUP de quantité + Don à la cible (NOUVEAU) =========================
-- Utilisation : on ouvre le popup avec StaticPopup_Show("MULTIBOT_GIVE_ITEMUS", <itemId>, nil, { itemId=<id> })
-- Le destinataire est **la cible actuelle** (UnitName("target")). Si aucune cible joueur -> message d'erreur et annulation.
--[[StaticPopupDialogs["MULTIBOT_GIVE_ITEMUS"] = {
  text = "Donner l'objet ID %s à la cible sélectionnée.\n\nQuantité :",
  button1 = "OK",
  button2 = "Annuler",
  hasEditBox = true,
  editBoxWidth = 80,
  OnShow = function(self)
    self.editBox:SetAutoFocus(true)
    self.editBox:SetText("1")
    self.editBox:HighlightText()
  end,
  OnAccept = function(self, data)
    local count = tonumber(self.editBox:GetText()) or 1
    if count < 1 then count = 1 end

    -- Résolution de la cible : on exige un joueur ciblé (ton bot sélectionné).
    local targetName = UnitIsPlayer("target") and UnitName("target") or nil
    if not targetName then
      if MultiBot.Print then
        MultiBot.Print("|cffff4444Aucune cible joueur. Sélectionne le bot puis réessaie.|r")
      else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Aucune cible joueur. Sélectionne le bot puis réessaie.|r")
      end
      return
    end

    local itemId = data and data.itemId or nil
    if not itemId then
      if MultiBot.Print then
        MultiBot.Print("|cffff4444Item ID introuvable.|r")
      end
      return
    end

    -- Commande GM côté AzerothCore (comme demandé) : ".add <itemId> <count> <playerName>"
    -- Si ton core exige une autre forme (.additem, etc.), ajuste ici la chaîne :
    local cmd = string.format(".add %s %d %s", tostring(itemId), count, targetName)
    SendChatMessage(cmd, "SAY")
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}
-- Helper : attache au bouton d’un item l’ouverture du popup
function MultiBot.itemus.attachGiveOnClick(btn, itemId)
  btn.itemId = itemId
  btn.doLeft = function(pButton)
    StaticPopup_Show("MULTIBOT_GIVE_ITEMUS", tostring(pButton.itemId), nil, { itemId = pButton.itemId })
  end
end--]]
-- ============================================================================

-- Boutons: déplacer / pagination / fermer
MultiBot.itemus.movButton("Move", -407, 850, 32, MultiBot.tips.move.itemus)

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
MultiBot.itemus.addButton("Level", -94, 806, "achievement_level_10", MultiBot.tips.itemus.level.master).setEnable()
.doLeft = function(pButton)
  MultiBot.ShowHideSwitch(pButton.parent.frames["Level"])
end

do
  local frame = MultiBot.itemus.addFrame("Level", -61, 808, 28)
  frame:Hide()

  local levels = {
    { "L10", "achievement_level_10", MultiBot.tips.itemus.level.L10 },
    { "L20", "achievement_level_20", MultiBot.tips.itemus.level.L20 },
    { "L30", "achievement_level_30", MultiBot.tips.itemus.level.L30 },
    { "L40", "achievement_level_40", MultiBot.tips.itemus.level.L40 },
    { "L50", "achievement_level_50", MultiBot.tips.itemus.level.L50 },
    { "L60", "achievement_level_60", MultiBot.tips.itemus.level.L60 },
    { "L70", "achievement_level_70", MultiBot.tips.itemus.level.L70 },
    { "L80", "achievement_level_80", MultiBot.tips.itemus.level.L80 },
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
MultiBot.itemus.addButton("Rare", -94, 768, "achievement_quests_completed_01", MultiBot.tips.itemus.rare.master)
.doLeft = function(pButton)
  MultiBot.ShowHideSwitch(pButton.parent.frames["Rare"])
end

do
  local frame = MultiBot.itemus.addFrame("Rare", -61, 770)
  frame:Hide()

  local rares = {
    { "R00", "achievement_quests_completed_01", MultiBot.tips.itemus.rare.R00, "cff9d9d9d" },
    { "R01", "achievement_quests_completed_02", MultiBot.tips.itemus.rare.R01, "cffffffff" },
    { "R02", "achievement_quests_completed_03", MultiBot.tips.itemus.rare.R02, "cff1eff00" },
    { "R03", "achievement_quests_completed_04", MultiBot.tips.itemus.rare.R03, "cff0070dd" },
    { "R04", "achievement_quests_completed_05", MultiBot.tips.itemus.rare.R04, "cffa335ee" },
    { "R05", "achievement_quests_completed_06", MultiBot.tips.itemus.rare.R05, "cffff8000" },
    { "R06", "achievement_quests_completed_07", MultiBot.tips.itemus.rare.R06, "cffff0000" },
    { "R07", "achievement_quests_completed_08", MultiBot.tips.itemus.rare.R07, "cffe6cc80" },
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
MultiBot.itemus.addButton("Slot", -94, 731, "inv_drink_18", MultiBot.tips.itemus.slot.master)
.doLeft = function(pButton)
  MultiBot.ShowHideSwitch(pButton.parent.frames["Slot"])
end

do
  local frame = MultiBot.itemus.addFrame("Slot", -61, 733)
  frame:Hide()

  -- Mise en table du layout original (y compris le correctif S27 qui posait S26 dans le code d'origine)
  local slots = {
    { "S00",   0,   0,  "inv_drink_18"                      , MultiBot.tips.itemus.slot.S00 },
    { "S01",  30,   0,  "inv_misc_desecrated_platehelm"     , MultiBot.tips.itemus.slot.S01 },
    { "S02",  60,   0,  "inv_jewelry_necklace_22"           , MultiBot.tips.itemus.slot.S02 },
    { "S03",  90,   0,  "inv_misc_desecrated_plateshoulder" , MultiBot.tips.itemus.slot.S03 },
    { "S04", 120,   0,  "inv_shirt_grey_01"                 , MultiBot.tips.itemus.slot.S04 },
    { "S05", 150,   0,  "inv_misc_desecrated_platechest"    , MultiBot.tips.itemus.slot.S05 },
    { "S06", 180,   0,  "inv_misc_desecrated_platebelt"     , MultiBot.tips.itemus.slot.S06 },
    { "S07", 210,   0,  "inv_misc_desecrated_platepants"    , MultiBot.tips.itemus.slot.S07 },
    { "S08",   0, -30,  "inv_misc_desecrated_plateboots"    , MultiBot.tips.itemus.slot.S08 },
    { "S09",  30, -30,  "inv_misc_desecrated_platebracer"   , MultiBot.tips.itemus.slot.S09 },
    { "S10",  60, -30,  "inv_misc_desecrated_plategloves"   , MultiBot.tips.itemus.slot.S10 },
    { "S11",  90, -30,  "inv_jewelry_ring_19"               , MultiBot.tips.itemus.slot.S11 },
    { "S12", 120, -30,  "inv_jewelry_ring_07"               , MultiBot.tips.itemus.slot.S12 },
    { "S13", 150, -30,  "inv_sword_23"                      , MultiBot.tips.itemus.slot.S13 },
    { "S14", 180, -30,  "inv_shield_04"                     , MultiBot.tips.itemus.slot.S14 },
    { "S15", 210, -30,  "inv_weapon_bow_05"                 , MultiBot.tips.itemus.slot.S15 },
    { "S16",   0, -60,  "inv_misc_cape_20"                  , MultiBot.tips.itemus.slot.S16 },
    { "S17",  30, -60,  "inv_axe_14"                        , MultiBot.tips.itemus.slot.S17 },
    { "S18",  60, -60,  "inv_misc_bag_07_black"             , MultiBot.tips.itemus.slot.S18 },
    { "S19",  90, -60,  "inv_shirt_guildtabard_01"          , MultiBot.tips.itemus.slot.S19 },
    { "S20", 120, -60,  "inv_misc_desecrated_clothchest"    , MultiBot.tips.itemus.slot.S20 },
    { "S21", 150, -60,  "inv_hammer_07"                     , MultiBot.tips.itemus.slot.S21 },
    { "S22", 180, -60,  "inv_sword_15"                      , MultiBot.tips.itemus.slot.S22 },
    { "S23", 210, -60,  "inv_misc_book_09"                  , MultiBot.tips.itemus.slot.S23 },
    { "S24",   0, -90,  "inv_misc_ammo_arrow_01"            , MultiBot.tips.itemus.slot.S24 },
    { "S25",  30, -90,  "inv_throwingknife_02"              , MultiBot.tips.itemus.slot.S25 },
    { "S26",  60, -90,  "inv_wand_07"                       , MultiBot.tips.itemus.slot.S26 },
    { "S27",  90, -90,  "inv_misc_quiver_07"                , MultiBot.tips.itemus.slot.S27 }, -- correctif
    { "S28", 120, -90,  "inv_relics_idolofrejuvenation"     , MultiBot.tips.itemus.slot.S28 },
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
MultiBot.itemus.addButton("Type", -94, 694, "inv_misc_head_clockworkgnome_01", MultiBot.tips.itemus.type).setDisable()
.doLeft = function(pButton)
  MultiBot.itemus.type = MultiBot.IF(MultiBot.OnOffSwitch(pButton), "NPC", "PC")
  MultiBot.itemus.addItems(1)
end

--[[
-- ITEMUS --

MultiBot.itemus = MultiBot.newFrame(MultiBot, -860, -144, 32, 442, 884)
MultiBot.itemus.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Inventory.blp")
MultiBot.itemus.addText("Title", "Itemus", "CENTER", -57, 429, 13)
MultiBot.itemus.addText("Pages", "0/0", "CENTER", -57, 409, 13)
MultiBot.itemus.name = UnitName("Player")
MultiBot.itemus.index = {}
MultiBot.itemus.color = "cff9d9d9d"
MultiBot.itemus.level = "L10"
MultiBot.itemus.rare = "R00"
MultiBot.itemus.slot = "S00"
MultiBot.itemus.type = "PC"
MultiBot.itemus.max = 1
MultiBot.itemus.now = 1
MultiBot.itemus:SetMovable(true)
MultiBot.itemus:Hide()

MultiBot.itemus.movButton("Move", -407, 850, 32, MultiBot.tips.move.itemus)

MultiBot.itemus.wowButton("<", -319, 841, 15, 18, 13).doHide()
.doLeft = function(pButton)
	MultiBot.itemus.now = MultiBot.itemus.now - 1
	MultiBot.itemus.addItems()
end

MultiBot.itemus.wowButton(">", -225, 841, 15, 18, 13).doHide()
.doLeft = function(pButton)
	MultiBot.itemus.now = MultiBot.itemus.now + 1
	MultiBot.itemus.addItems()
end

MultiBot.itemus.wowButton("X", -126, 862, 15, 18, 13)
.doLeft = function(pButton)
	MultiBot.itemus:Hide()
end

local tFrame = MultiBot.itemus.addFrame("Items", -397, 807, 32)
tFrame:Show()

-- ITEMUS:LEVEL --

MultiBot.itemus.addButton("Level", -94, 806, "achievement_level_10", MultiBot.tips.itemus.level.master).setEnable()
.doLeft = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Level"])
end

local tFrame = MultiBot.itemus.addFrame("Level", -61, 808, 28)
tFrame:Hide()

tFrame.addButton("L10", 0, 0, "achievement_level_10", MultiBot.tips.itemus.level.L10)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L10"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("L20", 30, 0, "achievement_level_20", MultiBot.tips.itemus.level.L20)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L20"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("L30", 60, 0, "achievement_level_30", MultiBot.tips.itemus.level.L30)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L30"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("L40", 90, 0, "achievement_level_40", MultiBot.tips.itemus.level.L40)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L40"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("L50", 120, 0, "achievement_level_50", MultiBot.tips.itemus.level.L50)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L50"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("L60", 150, 0, "achievement_level_60", MultiBot.tips.itemus.level.L60)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L60"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("L70", 180, 0, "achievement_level_70", MultiBot.tips.itemus.level.L70)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L70"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("L80", 210, 0, "achievement_level_80", MultiBot.tips.itemus.level.L80)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Level", pButton.texture)
	MultiBot.itemus.level = "L80"
	MultiBot.itemus.addItems(1)
end

-- ITEMUS:RARE --

MultiBot.itemus.addButton("Rare", -94, 768, "achievement_quests_completed_01", MultiBot.tips.itemus.rare.master)
.doLeft = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Rare"])
end

local tFrame = MultiBot.itemus.addFrame("Rare", -61, 770)
tFrame:Hide()

tFrame.addButton("R00", 0, 0, "achievement_quests_completed_01", MultiBot.tips.itemus.rare.R00)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cff9d9d9d"
	MultiBot.itemus.rare = "R00"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("R01", 30, 0, "achievement_quests_completed_02", MultiBot.tips.itemus.rare.R01)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cffffffff"
	MultiBot.itemus.rare = "R01"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("R02", 60, 0, "achievement_quests_completed_03", MultiBot.tips.itemus.rare.R02)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cff1eff00"
	MultiBot.itemus.rare = "R02"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("R03", 90, 0, "achievement_quests_completed_04", MultiBot.tips.itemus.rare.R03)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cff0070dd"
	MultiBot.itemus.rare = "R03"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("R04", 120, 0, "achievement_quests_completed_05", MultiBot.tips.itemus.rare.R04)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cffa335ee"
	MultiBot.itemus.rare = "R04"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("R05", 150, 0, "achievement_quests_completed_06", MultiBot.tips.itemus.rare.R05)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cffff8000"
	MultiBot.itemus.rare = "R05"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("R06", 180, 0, "achievement_quests_completed_07", MultiBot.tips.itemus.rare.R06)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cffff0000"
	MultiBot.itemus.rare = "R06"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("R07", 210, 0, "achievement_quests_completed_08", MultiBot.tips.itemus.rare.R07)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Rare", pButton.texture)
	MultiBot.itemus.color = "cffe6cc80"
	MultiBot.itemus.rare = "R07"
	MultiBot.itemus.addItems(1)
end

-- ITEMUS:SLOT --

MultiBot.itemus.addButton("Slot", -94, 731, "inv_drink_18", MultiBot.tips.itemus.slot.master)
.doLeft = function(pButton)
	MultiBot.ShowHideSwitch(pButton.parent.frames["Slot"])
end

local tFrame = MultiBot.itemus.addFrame("Slot", -61, 733)
tFrame:Hide()

tFrame.addButton("S00", 0, 0, "inv_drink_18", MultiBot.tips.itemus.slot.S00)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S00"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S01", 30, 0, "inv_misc_desecrated_platehelm", MultiBot.tips.itemus.slot.S01)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S01"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S02", 60, 0, "inv_jewelry_necklace_22", MultiBot.tips.itemus.slot.S02)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S02"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S03", 90, 0, "inv_misc_desecrated_plateshoulder", MultiBot.tips.itemus.slot.S03)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S03"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S04", 120, 0, "inv_shirt_grey_01", MultiBot.tips.itemus.slot.S04)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S04"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S05", 150, 0, "inv_misc_desecrated_platechest", MultiBot.tips.itemus.slot.S05)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S05"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S06", 180, 0, "inv_misc_desecrated_platebelt", MultiBot.tips.itemus.slot.S06)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S06"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S07", 210, 0, "inv_misc_desecrated_platepants", MultiBot.tips.itemus.slot.S07)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S07"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S08", 0, -30, "inv_misc_desecrated_plateboots", MultiBot.tips.itemus.slot.S08)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S08"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S09", 30, -30, "inv_misc_desecrated_platebracer", MultiBot.tips.itemus.slot.S09)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S09"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S10", 60, -30, "inv_misc_desecrated_plategloves", MultiBot.tips.itemus.slot.S10)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S10"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S11", 90, -30, "inv_jewelry_ring_19", MultiBot.tips.itemus.slot.S11)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S11"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S12", 120, -30, "inv_jewelry_ring_07", MultiBot.tips.itemus.slot.S12)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S12"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S13", 150, -30, "inv_sword_23", MultiBot.tips.itemus.slot.S13)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S13"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S14", 180, -30, "inv_shield_04", MultiBot.tips.itemus.slot.S14)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S14"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S15", 210, -30, "inv_weapon_bow_05", MultiBot.tips.itemus.slot.S15)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S15"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S16", 0, -60, "inv_misc_cape_20", MultiBot.tips.itemus.slot.S16)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S16"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S17", 30, -60, "inv_axe_14", MultiBot.tips.itemus.slot.S17)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S17"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S18", 60, -60, "inv_misc_bag_07_black", MultiBot.tips.itemus.slot.S18)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S18"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S19", 90, -60, "inv_shirt_guildtabard_01", MultiBot.tips.itemus.slot.S19)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S19"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S20", 120, -60, "inv_misc_desecrated_clothchest", MultiBot.tips.itemus.slot.S20)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S20"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S21", 150, -60, "inv_hammer_07", MultiBot.tips.itemus.slot.S21)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S21"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S22", 180, -60, "inv_sword_15", MultiBot.tips.itemus.slot.S22)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S22"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S23", 210, -60, "inv_misc_book_09", MultiBot.tips.itemus.slot.S23)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S23"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S24", 0, -90, "inv_misc_ammo_arrow_01", MultiBot.tips.itemus.slot.S24)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S24"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S25", 30, -90, "inv_throwingknife_02", MultiBot.tips.itemus.slot.S25)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S25"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S26", 60, -90, "inv_wand_07", MultiBot.tips.itemus.slot.S26)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S26"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S27", 90, -90, "inv_misc_quiver_07", MultiBot.tips.itemus.slot.S27)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S26"
	MultiBot.itemus.addItems(1)
end

tFrame.addButton("S28", 120, -90, "inv_relics_idolofrejuvenation", MultiBot.tips.itemus.slot.S28)
.doLeft = function(pButton)
	MultiBot.Select(MultiBot.itemus, "Slot", pButton.texture)
	MultiBot.itemus.slot = "S28"
	MultiBot.itemus.addItems(1)
end

-- ITEMUS:TYPE --

MultiBot.itemus.addButton("Type", -94, 694, "inv_misc_head_clockworkgnome_01", MultiBot.tips.itemus.type).setDisable()
.doLeft = function(pButton)
	MultiBot.itemus.type = MultiBot.IF(MultiBot.OnOffSwitch(pButton), "NPC", "PC")
	MultiBot.itemus.addItems(1)
end]]--

-- ICONOS --

--[[MultiBot.iconos = MultiBot.newFrame(MultiBot, -860, -144, 32, 442, 884)
MultiBot.iconos.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Iconos.blp")
MultiBot.iconos.addText("Title", "Iconos", "CENTER", -57, 429, 13)
MultiBot.iconos.addText("Pages", "0/0", "CENTER", -57, 409, 13)
MultiBot.iconos.max = 1
MultiBot.iconos.now = 1
MultiBot.iconos:SetMovable(true)
MultiBot.iconos:Hide()

MultiBot.iconos.movButton("Move", -407, 850, 32, MultiBot.tips.move.iconos)

MultiBot.iconos.wowButton("<", -319, 841, 15, 18, 13).doHide()
.doLeft = function(pButton)
	MultiBot.iconos.now = MultiBot.iconos.now - 1
	MultiBot.iconos.addIcons()
end

MultiBot.iconos.wowButton(">", -225, 841, 15, 18, 13).doHide()
.doLeft = function(pButton)
	MultiBot.iconos.now = MultiBot.iconos.now + 1
	MultiBot.iconos.addIcons()
end

MultiBot.iconos.wowButton("X", -126, 862, 15, 18, 13)
.doLeft = function(pButton)
	MultiBot.iconos:Hide()
end

local tFrame = MultiBot.iconos.addFrame("Icons", -397, 807, 32)
tFrame:Show()]]--

-- ICONOS REFACTOR --
MultiBot.iconos = MultiBot.newFrame(MultiBot, -860, -144, 32, 442, 884)
MultiBot.iconos.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Iconos.blp")
MultiBot.iconos.addText("Title", "Iconos", "CENTER", -57, 429, 13)
MultiBot.iconos.addText("Pages", "0/0", "CENTER", -57, 409, 13)
MultiBot.iconos.max = 1
MultiBot.iconos.now = 1
MultiBot.iconos:SetMovable(true)
MultiBot.iconos:Hide()

-- Bouton déplacer
MultiBot.iconos.movButton("Move", -407, 850, 32, MultiBot.tips.move.iconos)

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
tOverlay.addText("Title", "Spellbook", "CENTER", 14, 200, 13)
tOverlay.addText("Pages", "0/0", "CENTER", 14, 173, 13)
tOverlay:SetFrameLevel(5)

tOverlay.movButton("Move", -226, 310, 50, MultiBot.tips.move.spellbook, MultiBot.spellbook)

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
tOverlay.addText("Title", MultiBot.info.reward, "CENTER", 16, 226, 13)
tOverlay.addText("Pages", "0/0", "CENTER", 16, 196, 13)
tOverlay:SetFrameLevel(5)

tOverlay.movButton("Move", -270, 354, 50, MultiBot.tips.move.reward, MultiBot.reward)

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

-- TALENT --

MultiBot.talent = MultiBot.newFrame(MultiBot, -104, -276, 28, 1024, 1024)
MultiBot.talent.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent.blp")
MultiBot.talent.addText("Points", MultiBot.info.talent["Points"], "CENTER", -228, -8, 13)
MultiBot.talent.addText("Title", MultiBot.info.talent["Title"], "CENTER", -228, 491, 13)
MultiBot.talent:SetMovable(true)
MultiBot.talent:Hide()

MultiBot.talent.movButton("Move", -960, 960, 64, MultiBot.tips.move.talent)

MultiBot.talent.wowButton(MultiBot.info.talent.Apply, -474, 966, 100, 20, 12).doHide()
.doLeft = function(pButton)
	local tValues = ""

	for i = 1, 3 do
		local tTab = MultiBot.talent.frames["Tab" .. i]

		for j = 1, table.getn(tTab.buttons) do
			tValues = tValues .. tTab.buttons[j].value
		end

		if(i < 3) then tValues = tValues .. "-" end
	end

	SendChatMessage("talents apply " ..tValues, "WHISPER", nil, MultiBot.talent.name)
	pButton.doHide()
end

local tApply = MultiBot.talent.buttons[ MultiBot.info.talent.Apply ]

MultiBot.talent.wowButton(MultiBot.info.talent.Copy, -854, 966, 100, 20, 12)
local copyBtn = MultiBot.talent.buttons[MultiBot.info.talent.Copy]

copyBtn.doLeft = function(pButton)
	local tName = UnitName("target")
	if(tName == nil or tName == "Unknown Entity") then return SendChatMessage(MultiBot.info.target, "SAY") end

	local tLocClass, tClass = UnitClass("target")
	if(MultiBot.talent.class ~= MultiBot.toClass(tClass)) then return SendChatMessage("The Classes do not match.", "SAY") end

	local tUnit = MultiBot.toUnit(MultiBot.talent.name)
	if(UnitLevel(tUnit) ~= UnitLevel("target")) then return SendChatMessage("The Levels do not match.", "SAY") end

	local tValues = ""

	for i = 1, 3 do
		local tTab = MultiBot.talent.frames["Tab" .. i]

		for j = 1, table.getn(tTab.buttons) do
			tValues = tValues .. tTab.buttons[j].value
		end

		if(i < 3) then tValues = tValues .. "-" end
	end

	SendChatMessage("talents apply " ..tValues, "WHISPER", nil, tName)
end

MultiBot.talent.wowButton("X", -470, 992, 17, 20, 13)
.doLeft = function(pButton)
	local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
	local tButton = tUnits.frames[MultiBot.talent.name].buttons["Talent"]
	tButton.doLeft(tButton)
end

local tTab = MultiBot.talent.addFrame("Tab1", -830, 518, 28, 170, 408)
tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
tTab.addText("Title", "Title", "CENTER", 0, 214, 13)
tTab.arrows = {}
tTab.value = 0
tTab.id = 1

local tTab = MultiBot.talent.addFrame("Tab2", -656, 518, 28, 170, 408)
tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
tTab.addText("Title", "Title", "CENTER", 0, 214, 13)
tTab.arrows = {}
tTab.value = 0
tTab.id = 2

local tTab = MultiBot.talent.addFrame("Tab3", -482, 518, 28, 170, 408)
tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\White.blp")
tTab.addText("Title", "Title", "CENTER", 0, 214, 13)
tTab.arrows = {}
tTab.value = 0
tTab.id = 3

-- ACTUAL GLYPHES START --

-- Minimum level for each Socket (in order 1→6)
local socketReq = { 15, 15, 30, 50, 70, 80 }

local function ShowGlyphTooltip(self)
    local id = self.glyphID
    if not id then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    -- 1) try like a spell
    if GameTooltip:SetSpellByID(id) then
        return
    end

    -- 2) try like a item
    GameTooltip:SetHyperlink("item:"..id..":0:0:0:0:0:0:0")
end

local function HideGlyphTooltip()
    GameTooltip:Hide()
end

function MultiBot.FillDefaultGlyphs()
    local botName = MultiBot.talent.name
    local unit    = MultiBot.toUnit(botName)
    if not unit then return end

    -- rec is the table received from the handler, in the following format
    -- { [1]={id=…,type=…}, …, [6]={…} }
    local rec = MultiBot.receivedGlyphs and MultiBot.receivedGlyphs[botName]
    if not rec then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[MultiBot]|r Waiting for glyphs…")
        return
    end

    -- Derive the class key to access glyphDB
    local _, classFile = UnitClass(unit)
    local classKey = (classFile == "DEATHKNIGHT" and "DeathKnight")
                   or (classFile:sub(1,1) .. classFile:sub(2):lower())
    local glyphDB = MultiBot.data.talent.glyphs[classKey] or {}

    -- Loop through each slot i = 1..6
    for i, entry in ipairs(rec) do
        local id, typ = entry.id, entry.type
        local f = MultiBot.talent.frames["Tab4"].frames["Socket"..i]
        if f and f.frames then
            -- 1) Glow
            f.type, f.item = typ, id
            f.frames.Glow:Show()

            -- 2) Rune
            local raw = glyphDB[typ] and glyphDB[typ][id] or ""
            local _, runeIdx = strsplit(",%s*", raw)
            runeIdx = runeIdx or "1"
            local rFrame = f.frames.Rune
            if rFrame then
                rFrame:Hide()
                local runeTex = rFrame.texture or rFrame
                runeTex:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune"..runeIdx)
            end

            -- 3) Icon + Tooltip
            local tex = GetSpellTexture(id)
                     or select(10, GetItemInfo(id))
                     -- or "Interface\\Icons\\INV_Misc_QuestionMark"
					 or "Interface\\AddOns\\MultiBot\\Textures\\UI-GlyphFrame-Glow.blp"
            local btn = f.frames.IconBtn
            if not btn then
                btn = CreateFrame("Button", nil, f)
                btn:SetAllPoints(f)
                btn:SetScript("OnEnter", ShowGlyphTooltip)
                btn:SetScript("OnLeave", HideGlyphTooltip)

                -- Creating the texture
                local icon = btn:CreateTexture(nil, "ARTWORK")
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", btn, "CENTER", -9, 8)

                -- resizing
                local factor = (typ == "Major") and 0.64 or 0.66
                icon:SetSize(f:GetWidth() * factor, f:GetHeight() * factor)

                -- croping
                local crop = (typ == "Major") and 0.14 or 0.20
                icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)

                btn.icon = icon
                f.frames.IconBtn = btn
            end

            -- Update icon
            btn.glyphID = id
            btn.icon:SetTexture(tex)
            btn:Show()

            -- Overlay circle
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

    -- Chat display (optional)
    local names = {}
    for _, entry in ipairs(rec) do
        local n = select(1, GetItemInfo(entry.id))   -- name of object (glyphe)
              or GetSpellInfo(entry.id)              -- fallback if no objecy
              or ("ID "..entry.id)
        table.insert(names,
            (entry.type=="Major" and "|cffffff00" or "|cff00ff00") .. n .. "|r")
    end
    --[[DEFAULT_CHAT_FRAME:AddMessage(
        "|cff66ccff[MultiBot]|r Glyphs for "..botName.." : "..table.concat(names, ", "))]]--
end

-- Add a custom background to the Glyphs Frame (tTab)
local tTab = MultiBot.talent.addFrame("Tab4", -513, 518, 28, 456, 430) -- offset x, offset y, strata level, widht, height
tTab.addFrame("Glow", 0, 0, 28, 456, 430).setAlpha(0.5).doHide()-- .addTexture("Interface/Spellbook/Talent_Glyphs_Glow.blp")
tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Background-GlyphFrame.blp")
tTab:Hide()

local parentTab4 = MultiBot.talent.frames["Tab4"]   -- alias

-- Bouton “Apply Glyphs” – créé **une seule fois** :
gApply = parentTab4.wowButton("Apply Glyphs", 0, 0, 100, 20, 12)
gApply:ClearAllPoints()
gApply:SetPoint("TOPRIGHT", parentTab4, "TOPRIGHT", -20, -20)
gApply:SetFrameLevel(parentTab4:GetFrameLevel() + 10)
gApply:Hide()          -- invisible till no modif
gApply:SetScript("OnClick", function()
    local ids = {}
    for i = 1, 6 do
        ids[i] = parentTab4.frames["Socket"..i].item or 0
    end
    local payload = "glyph equip " .. table.concat(ids, " ")
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[DBG]|r " ..
        (MultiBot.talent.name or "?") .. " : " .. payload)
    SendChatMessage(payload, "WHISPER", nil, MultiBot.talent.name)
    gApply:Hide()
end)

-- GLYPH:SOCKET1 --

-- Level 15
local tGlyph = tTab.addFrame("Socket1", -176.5, 310, 102) -- 1st socket at the top: Major (offset x, offset y, frame size)
tGlyph.addFrame("Glow",   0,  0, 102).setLevel(7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Slot-Major.blp")
tGlyph.addFrame("Rune", -29, 29,  44).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Major"
tGlyph.item = 0

tGlyph.addFrame("Overlay", -12, 12, 96).setLevel(9).doHide()

-- GLYPH:SOCKET2 --

-- Level 15
local tGlyph = tTab.addFrame("Socket2", -187, 18.5, 82) -- Minor socket at the very bottom: Minor
tGlyph.addFrame("Glow",   0,  0, 82).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp")
tGlyph.addFrame("Rune", -25, 25, 32).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Minor"

tGlyph.addFrame("Overlay", -9, 9, 80).setLevel(9).doHide()

-- GLYPH:SOCKET3 --

-- Level 30
local tGlyph = tTab.addFrame("Socket3", -18.5, 50.5, 102) -- Bottom-right socket: Major
tGlyph.addFrame("Glow",   0,  0, 102).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Major.blp")
tGlyph.addFrame("Rune", -29, 29,  44).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Major"

tGlyph.addFrame("Overlay", -12, 12, 96) .setLevel(9).doHide()

-- GLYPH:SOCKET4 --

-- Level 50
local tGlyph = tTab.addFrame("Socket4", -302.5, 218, 82) -- Top-left socket: Minor
tGlyph.addFrame("Glow",   0,  0, 82).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp")
tGlyph.addFrame("Rune", -25, 25, 32).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Minor"

tGlyph.addFrame("Overlay", -9, 9, 80).setLevel(9).doHide()

-- GLYPH:SOCKET5 --

-- Level 70
local tGlyph = tTab.addFrame("Socket5", -72.5, 218, 82) -- Top-right socket: Minor
tGlyph.addFrame("Glow",   0,  0, 82).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp")
tGlyph.addFrame("Rune", -25, 25, 32).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Minor"

tGlyph.addFrame("Overlay", -9, 9, 80).setLevel(9).doHide()

-- GLYPH:SOCKET6 --

-- Level 80
local tGlyph = tTab.addFrame("Socket6", -336, 50.5, 102) -- Bottom-left socket: Major
tGlyph.addFrame("Glow",   0,  0, 102).setLevel(7).doHide().addTexture("Interface\\Spellbook\\UI-Glyph-Slot-Major.blp")
tGlyph.addFrame("Rune", -29, 29,  44).setLevel(8).setAlpha(0.7).doHide().addTexture("Interface/Spellbook/UI-Glyph-Rune-1")
tGlyph.frames = tGlyph.frames or {}
tGlyph.type = "Major"

tGlyph.addFrame("Overlay", -12, 12, 96) .setLevel(9).doHide()

-- TAB TALENTS --
local tTab = MultiBot.talent.addFrame("Tab5", -900, 461, 28, 96, 24)
tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_Tab.blp")
tTab.wowButton("Talents", -2, 6, 92, 17, 11)
.doLeft = function(pButton)
	if gApply then gApply:Hide() end
    -- Update UI
    MultiBot.talent.setText("Title", MultiBot.doReplace(MultiBot.info.talent.Title, "NAME", MultiBot.talent.name))
    MultiBot.talent.texts["Points"]:Show()
    MultiBot.talent.frames["Tab1"]:Show()
    MultiBot.talent.frames["Tab2"]:Show()
    MultiBot.talent.frames["Tab3"]:Show()
    MultiBot.talent.frames["Tab4"]:Hide()
	copyBtn:doShow()
end

-- TAB GLYPHS --
local tTab = MultiBot.talent.addFrame("Tab6", -800, 461, 28, 96, 24)
tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_Tab.blp")
tTab.wowButton("Glyphs", -2, 6, 92, 17, 11)

.doLeft = function(pButton)
	if gApply then gApply:Hide() end
    -- UI
    MultiBot.talent.setText("Title", "|cffffff00" .. MultiBot.info.glyphsglyphsfor .. " |r" .. (MultiBot.talent.name or "?"))
    MultiBot.talent.texts["Points"]:Hide()
    MultiBot.talent.frames["Tab1"]:Hide()
    MultiBot.talent.frames["Tab2"]:Hide()
    MultiBot.talent.frames["Tab3"]:Hide()
    MultiBot.talent.frames["Tab4"]:Show()
	copyBtn:doHide()
    local botName = MultiBot.talent.name
    MultiBot.awaitGlyphs = botName
    SendChatMessage("glyphs", "WHISPER", nil, botName)
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
    tTalent:RegisterForClicks("LeftButtonUp", "RightButtonUp") 	-- Added for custom talents accept right and left click
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
		MultiBot.talent.setText("Points", MultiBot.info.talent["Points"] .. MultiBot.talent.points)

		tTab.value = tTab.value + 1
		tTab.setText("Title", MultiBot.info.talent[pButton.getClass() .. tTab.id] .. " ("  .. tTab.value .. ")")

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

		MultiBot.talent.buttons[MultiBot.info.talent.Apply].doShow()
		MultiBot.talent.doState()
	end

	-- Add right click to remove custom Points
	-- Right click : –1 point
	tTalent.doRight = function(pButton)
		if pButton.value == 0 then return end          -- Nothing to remove

		local tTab   = pButton.parent                  -- Tab (tree)
		local tValue = tTab.frames[pButton.id]         -- Text 1/5

		-- Restore the global point
		MultiBot.talent.points = MultiBot.talent.points + 1
		MultiBot.talent.setText("Points",
			MultiBot.info.talent["Points"] .. MultiBot.talent.points)

		-- -- Update this talent + the tab
		pButton.value = pButton.value - 1
		pButton.tip   = pButton.tips[pButton.value + 1]
		tTab.value    = tTab.value  - 1
		-- Updates the title at the top of the tree
		tTab.setText("Title",
			MultiBot.info.talent[pButton.getClass() .. tTab.id] ..
			" (" .. tTab.value .. ")")

		-- Color based on rank
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

		-- -- Re-evaluate the state of all buttons/arrows
		MultiBot.talent.doState()

		-- -- Re-display the "Apply" button (modified build)
		MultiBot.talent.buttons[MultiBot.info.talent.Apply].doShow()
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
    -- 1) Check datas
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

    -- No talents loaded yet ? we retry in 0,1 s
    if not GetTalentInfo(1, 1, true) then
        TimerAfter(0.1, MultiBot.talent.setTalents)
        return
    end

    -- 2) Frame update
    MultiBot.talent.points = tonumber(GetUnspentTalentPoints(true))
    MultiBot.talent.setText("Points",
        MultiBot.info.talent["Points"] .. MultiBot.talent.points)
    MultiBot.talent.setText("Title",
        MultiBot.doReplace(MultiBot.info.talent["Title"], "NAME",
                           MultiBot.talent.name))

    for i = 1, 3 do
        local tMarker = MultiBot.talent.class .. i
        local tTab    = MultiBot.talent.setGrid(
                            MultiBot.talent.frames["Tab" .. i])
        tTab.setTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_" ..
                        tMarker .. ".blp")
        tTab.value, tTab.id = 0, i

        -- arrows
        for j = 1, #tArrow[i] do
            local tData = MultiBot.doSplit(tArrow[i][j], ", ")
            local tNeed = tonumber(tData[1])
            tTab.arrows[j] = MultiBot.talent.addArrow(
                                 tTab, j, tNeed, tData[2], tData[3], tData[4])
        end

        -- talents
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
            MultiBot.info.talent[tMarker] .. " (" .. tTab.value .. ")")
    end

    -- 3) Final display
    MultiBot.talent.doState()
	MultiBot.talent:Show()
	MultiBot.auto.talent = false
end

MultiBot.talent.doState = function()
	for i = 1, 3 do
		local tTab = MultiBot.talent.frames["Tab" .. i]

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
	for i = 1, 3 do
		local tTab = MultiBot.talent.frames["Tab" .. i]
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

local tTab = MultiBot.talent.addFrame("Tab7", -700, 461, 28, 96, 24)
tTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_Tab.blp")
local tBtn = tTab.wowButton("Custom Talents", -2, 6, 92, 17, 11)

-- 1) FONCTION to INITIALIZE CUSTOM TAB
function MultiBot.talent.setTalentsCustom()
    -- Protection if data from Talents still not.
    if not GetTalentInfo(1, 1, true) then
        TimerAfter(0.05, MultiBot.talent.setTalentsCustom)
        return
    end
    -- 0) visual Reset
    MultiBot.talent.doClear()
    MultiBot.talent.custom = true

    -- 1) Load existing datas class/arrows
    local tClass = MultiBot.data.talent.talents[ MultiBot.talent.class ]
    local tArrow = MultiBot.data.talent.arrows[  MultiBot.talent.class ]
    if not (tClass and tArrow) then
        print("|cffff0000[MultiBot] Class data missing for custom talents!|r")
        return
    end

    -- 2) Available points (level - 9)
    local unit  = MultiBot.toUnit(MultiBot.talent.name)
    local level = UnitLevel(unit) or 80
    MultiBot.talent.points = math.max(level - 9, 0)

    MultiBot.talent.setText("Points",   MultiBot.info.talent["Points"] .. MultiBot.talent.points)
	MultiBot.talent.setText("Title", "|cffffff00" .. MultiBot.info.talentscustomtalentsfor .. " |r" .. (MultiBot.talent.name or "?"))

    -- 3) Construction of the 3 empty trees
    for i = 1, 3 do
        local marker = MultiBot.talent.class .. i
        local pTab   = MultiBot.talent.setGrid( MultiBot.talent.frames["Tab"..i] )
        pTab.setTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_"..marker..".blp")
        pTab.value, pTab.id = 0, i

        -- arrows/requireds
        for j = 1, #tArrow[i] do
            local d = MultiBot.doSplit(tArrow[i][j], ", ")
            local need = tonumber(d[1])
            pTab.arrows[j] = MultiBot.talent.addArrow(pTab, j, need, d[2], d[3], d[4])
        end

        -- talents (rank 0 everywhere)
        for j = 1, #tClass[i] do
            local data = MultiBot.doSplit(tClass[i][j], ", ")
            local max  = #data - 4
            local need = tonumber(data[1])
            local tips = {}
            local link = GetTalentLink(i,j,true)
            local tale = MultiBot.doSplit(MultiBot.doSplit(link,"|")[3],":")[2]
            local name, icon = GetTalentInfo(i, j, true)
            table.insert(tips, "|cff4e96f7|Htalent:"..tale..":-1|h["..name.."]|h|r")
            for k=5,#data do
                table.insert(tips, "|cff4e96f7|Htalent:"..tale..":"..(k-5) .."|h["..name.."]|h|r")
            end

            MultiBot.talent.addTalent(pTab, j, need, 0, max, data[2], data[3], data[4], tips)
            MultiBot.talent.addValue (pTab, j, data[2], data[3], 0, max)
        end

        pTab.setText("Title", MultiBot.info.talent[marker] .. " (0)")
    end

    -- 4) Ajustement final + affichage
    MultiBot.talent.texts["Points"]:Show()
    MultiBot.talent.frames["Tab1"]:Show()
    MultiBot.talent.frames["Tab2"]:Show()
    MultiBot.talent.frames["Tab3"]:Show()
    MultiBot.talent.frames["Tab4"]:Hide()   -- glyphs
	if gApply then gApply:Hide() end
	copyBtn:doHide()
    MultiBot.talent.doState()
    MultiBot.talent:Show()
end

-- CALLBACK OF BUTTON (CUSTOM TAB)
tBtn.doLeft = function(btn)
    MultiBot.talent.setTalentsCustom()
end

-- RETURN FROM CUSTOM TO TALENTS
local tabTalentsBtn = MultiBot.talent.frames["Tab5"]
                     and MultiBot.talent.frames["Tab5"].buttons
                     and MultiBot.talent.frames["Tab5"].buttons["Talents"]
if tabTalentsBtn then
    local oldTalentsClick = tabTalentsBtn.doLeft
    tabTalentsBtn.doLeft = function(btn)
        if MultiBot.talent.custom then
            MultiBot.talent.custom = false
            MultiBot.talent.setTalents()   -- Rebuild the actual spec tree
            if oldTalentsClick then
                oldTalentsClick(btn)
            end
        else
            if oldTalentsClick then oldTalentsClick(btn) end
        end
    end
end

-- END TAB CUSTOM TAMENTS --

--[[
Add a new tab to use custom Glyphs (Tab8)
]]--

local gTab = MultiBot.talent.addFrame("Tab8", -600, 461, 28, 96, 24)
gTab.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Talent_Tab.blp")
local gBtn = gTab.wowButton("Custom Glyphs", -2, 6, 92, 17, 11)

-- 1) Cache for tooltips
local glyphTip

-- 2) Detect Major / Minor glyph via tooltip
local function GetGlyphItemType(itemID)
    if not glyphTip then
        glyphTip = CreateFrame("GameTooltip","MBHiddenTip",nil,"GameTooltipTemplate")
        glyphTip:SetOwner(UIParent,"ANCHOR_NONE")
    end
    glyphTip:ClearLines()
    glyphTip:SetHyperlink("item:"..itemID..":0:0:0:0:0:0:0")
    for i = 2, glyphTip:NumLines() do
        local line = _G[glyphTip:GetName().."TextLeft"..i]
        local txt = (line and line:GetText() or ""):lower()
        if txt:find("major glyph") then return "Major" end
        if txt:find("minor glyph") then return "Minor" end
    end
    return nil
end

-- 3) Build the itemID→classKey table once
local function BuildGlyphClassTable()
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

-- Preloading during ADDON_LOADED
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, name)
    if name == "MultiBot" then
        BuildGlyphClassTable()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Send true if a least a glyph socket are filled
local function HasPendingGlyph()
    for i = 1, 6 do
        if parentTab4.frames["Socket"..i].item ~= 0 then
            return true
        end
    end
    return false
end

-- 4) Oups i drag the wrong glyph
local function ClearGlyphSocket(socketFrame)
    socketFrame.item = 0          -- plus d’ID enregistré

    -- partie visuelle
    if socketFrame.frames.Rune  then socketFrame.frames.Rune:Hide()  end
    if socketFrame.frames.IconBtn then
        local btn = socketFrame.frames.IconBtn
        if btn.icon then btn.icon:SetTexture(nil) end
        if btn.bg   then btn.bg:Show()            end
        btn.glyphID = nil
        btn:Show()          -- on laisse le bouton visible pour un futur drop
    end

    if gApply then
	   if HasPendingGlyph() then
	      gApply:Show()
	   else
	      gApply:Hide()
	    end
	end
end

-- 5) Shared drag/click handler
local function CG_OnReceiveDrag(self)
    local typ, itemID = GetCursorInfo()
    if typ ~= "item" then return end

    BuildGlyphClassTable()
    local socket = self:GetParent()

	-- Reject drop if required level is not reached
local botUnit = MultiBot.toUnit(MultiBot.talent.name)
local lvl     = UnitLevel(botUnit or "player")

local idx = socket:GetID()

if idx == 0 then
    idx = tonumber(socket:GetName():match("Socket(%d+)"))
end
if lvl < socketReq[idx] then
    UIErrorsFrame:AddMessage(MultiBot.info.glyphssocketnotunlocked,1,0.3,0.3,1)
    return
end

    local unit   = MultiBot.toUnit(MultiBot.talent.name)
    local _, cf  = UnitClass(unit or "player")
    local classKey = (cf == "DEATHKNIGHT") and "DeathKnight" or (cf:sub(1,1)..cf:sub(2):lower())
    local gDB = (MultiBot.data.talent.glyphs or {})[classKey] or {}

    local glyphClass = MultiBot.__glyphClass and MultiBot.__glyphClass[itemID]
    if glyphClass and glyphClass ~= classKey then
        UIErrorsFrame:AddMessage(MultiBot.info.glyphswrongclass, 1,0.3,0.3,1)
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
            UIErrorsFrame:AddMessage(MultiBot.info.glyphsunknowglyph,1,0.3,0.3,1)
            return
        end
    end

    if gType ~= (socket.type or "Major") then
        UIErrorsFrame:AddMessage(MultiBot.info.glyphsglyphtype .. gType .. " : " .. MultiBot.info.glyphsglyphsocket, 1, 0.3, 0.3, 1)
        return
    end

    if info then
        local reqLvl = tonumber((strsplit(",%s*", info)))
        if reqLvl and reqLvl > lvl then
            UIErrorsFrame:AddMessage(MultiBot.info.glyphsleveltoolow,1,0.3,0.3,1)
            return
        end
    end

    if socket.frames.Glow    then socket.frames.Glow:Show()    end
    if socket.frames.Overlay then socket.frames.Overlay:Show() end
    if self.bg then self.bg:Hide() end

    local runeIdx = info and select(2, strsplit(",%s*", info)) or "1"
    local r = socket.frames.Rune
    if r then
        (r.texture or r):SetTexture("Interface/Spellbook/UI-Glyph-Rune-"..runeIdx)
        r:Show()
    end
    -- local tex = select(10, GetItemInfo(itemID)) or GetSpellTexture(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark"
	local tex = select(10, GetItemInfo(itemID)) or GetSpellTexture(itemID) or "Interface\\AddOns\\MultiBot\\Textures\\UI-GlyphFrame-Glow.blp"
    self.icon:SetTexture(tex)
    self.glyphID = itemID
    socket.item = itemID
    ClearCursor()
    gApply:Show()
end

--[[-- 6) Create the Apply button
	gApply = MultiBot.talent.wowButton("Apply Glyphs", -474, 966, 100, 20, 12)
	gApply:Hide()  -- Always hidden until a modification is made
	gApply:SetScript("OnClick", function()
    -- 1) Collect the 6 IDs (0 if slot is empty)
    local ids = {}
    for i = 1, 6 do
        ids[i] = MultiBot.talent.frames["Tab4"].frames["Socket"..i].item or 0
    end

    -- 2) Local DEBUG message
    local payload = "glyph equip "..table.concat(ids, " ")
    DEFAULT_CHAT_FRAME:AddMessage(
        ("|cff66ccff[DBG]|r %s  :  %s")
        :format(MultiBot.talent.name or "?", payload)
    )

    -- 3) Send the new unique command to the bot
    SendChatMessage(payload, "WHISPER", nil, MultiBot.talent.name)

    -- 4) Hide the button again until the next modification
    gApply:Hide()
end)]]--

-- 7) Prepare Tab4 for custom mode
function MultiBot.talent.showCustomGlyphs()
    MultiBot.talent.texts["Points"]:Hide()
    for i=1,3 do MultiBot.talent.frames["Tab"..i]:Hide() end
    -- local parentTab4 = MultiBot.talent.frames["Tab4"]
    parentTab4:Show()

    for i=1,6 do
        local s = parentTab4.frames["Socket"..i]
        if s then
		    s:SetID(i) -- Add an ID to the socket
		    -- Check the bot's level
            local botUnit  = MultiBot.toUnit(MultiBot.talent.name)
			local lvl      = UnitLevel(botUnit or "player")
			local unlocked = lvl >= socketReq[i] -- Ajout pour test
			-- Ensure the Overlay already has its "empty circle" texture
			local ov = s.frames.Overlay
			if ov and not ov.texture then
				ov.texture = ov:CreateTexture(nil, "BORDER")
				ov.texture:SetAllPoints(ov)
				local base = "Interface\\AddOns\\MultiBot\\Textures\\"
				ov.texture:SetTexture(
					base .. (s.type == "Major"
							and "gliph_majeur_layout.blp"
							or  "gliph_mineur_layout.blp"))
			end

        -- If the slot is not yet available, hide everything
        if not unlocked then
            if s.frames.Glow    then s.frames.Glow:Hide()    end
            if s.frames.Overlay then s.frames.Overlay:Hide() end
            if s.frames.Rune    then s.frames.Rune:Hide()    end
            if s.frames.IconBtn then s.frames.IconBtn:Hide() end
            s.locked = true
        else
            s.locked = false

            if s.frames.Glow    then s.frames.Glow:Show()    end
            if s.frames.Overlay then s.frames.Overlay:Show() end
            if s.frames.Rune    then s.frames.Rune:Hide()    end

            local btn = s.frames.IconBtn
            if not btn then
                btn = CreateFrame("Button", nil, s)
                btn:SetAllPoints(s)
                btn.bg = btn:CreateTexture(nil, "BACKGROUND")
                btn.bg:SetAllPoints(s)
                local texSlot = (s.type == "Minor") and
                                 "Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp" or
                                 "Interface\\Spellbook\\UI-Glyph-Slot-Major.blp"
                btn.bg:SetTexture(texSlot)
                local ic = btn:CreateTexture(nil, "ARTWORK")
                ic:SetPoint("CENTER", btn, "CENTER", -9, 8)
                ic:SetSize(s:GetWidth()*0.66, s:GetHeight()*0.66)
                ic:SetTexCoord(0.15, 0.85, 0.15, 0.85)
                btn.icon = ic
                s.frames.IconBtn = btn
            end

			if not btn.bg then
				btn.bg = btn:CreateTexture(nil, "BACKGROUND")
				btn.bg:SetAllPoints(s)
				local texSlot = (s.type == "Minor") and
								"Interface\\Spellbook\\UI-Glyph-Slot-Minor.blp" or
								"Interface\\Spellbook\\UI-Glyph-Slot-Major.blp"
				btn.bg:SetTexture(texSlot)
			end

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
			-- Yesss i can remove the wrong glyph!
			btn:SetScript("OnMouseUp", function(self, button)
				if button == "RightButton" then
					ClearGlyphSocket(self:GetParent())
				end
			end)
            s.item = 0
        end
    end
end
    gApply:Hide()
	if copyBtn then copyBtn:doHide() end
	if tApply then tApply:Hide() end
    MultiBot.talent.setText("Title", "|cffffff00" .. MultiBot.info.glyphscustomglyphsfor .. " |r" .. (MultiBot.talent.name or "?"))
end

-- 8) Assignation du clic onglet
gBtn.doLeft = MultiBot.talent.showCustomGlyphs

-- EN TAB CUSTOM GLYPHS --

-- RTSC --

local tRTSC = tMultiBar.addFrame("RTSC", -2, -34, 32).doHide()

local tButton = tRTSC.addButton("RTSC", 0, 0, "ability_hunter_markedfordeath", MultiBot.tips.rtsc.master, "SecureActionButtonTemplate").addMacro("type1", "/cast aedm")
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

-- Exécute l'action sur la sélection
--[[tSelector.doExecute = function(pButton, pAction)
	if (pButton.parent.selector == "") then
		return MultiBot.ActionToGroup(pAction)
	end

	local tGroups = MultiBot.doSplit(pButton.parent.selector, " ")
	for _, tag in ipairs(tGroups) do
		MultiBot.ActionToGroup(tag .. " " .. pAction)
		pButton.parent.buttons[tag].setDisable()
	end

	pButton.parent.selector = ""
end]]--

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
		.addButton(macroName, x, 0, icon, MultiBot.tips.rtsc.macro, "SecureActionButtonTemplate")
		.addMacro("type1", "/cast aedm")
		.setDisable()
		.doLeft = function(pButton)
			MultiBot.ActionToGroup("rtsc save " .. n)
			pButton.parent.buttons[rtscName].doShow()
			pButton.doHide()
		end

	-- Bouton RTSCn (caché au départ)
	local tButton = tSelector
		.addButton(rtscName, x, 0, icon, MultiBot.tips.rtsc.spot, "SecureActionButtonTemplate")
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
    { "@group1",  30, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group1.blp", MultiBot.tips.rtsc.group1,  true,  true },
    { "@group2",  60, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group2.blp", MultiBot.tips.rtsc.group2,  true,  true },
    { "@group3",  90, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group3.blp", MultiBot.tips.rtsc.group3,  true,  true },
    { "@group4", 120, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group4.blp", MultiBot.tips.rtsc.group4,  true,  true },
    { "@group5", 150, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_group5.blp", MultiBot.tips.rtsc.group5,  true,  true },
}

-- Boutons rôles (visibles + désactivés au départ)
local roleButtons = {
    { "@tank",   30, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_tank.blp",   MultiBot.tips.rtsc.tank,   false, true },
    { "@dps",    60, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_dps.blp",    MultiBot.tips.rtsc.dps,    false, true },
    { "@healer", 90, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_healer.blp", MultiBot.tips.rtsc.healer, false, true },
    { "@melee", 120, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_melee.blp",  MultiBot.tips.rtsc.melee,  false, true },
    { "@ranged",150, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_ranged.blp", MultiBot.tips.rtsc.ranged, false, true },
    { "@meleedps",  180, "Interface\\AddOns\\MultiBot\\Icons\\attack_melee.blp", MultiBot.tips.rtsc.meleedps,  false, true },
    { "@rangeddps", 210, "Interface\\AddOns\\MultiBot\\Icons\\attack_range.blp", MultiBot.tips.rtsc.rangeddps, false, true },
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
        .addButton("@all", 240, 0, "Interface\\AddOns\\MultiBot\\Icons\\rtsc.blp", MultiBot.tips.rtsc.all, "SecureActionButtonTemplate")
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
    local tButton = tSelector.addButton("Browse", 270, 0, "Interface\\AddOns\\MultiBot\\Icons\\rtsc_browse.blp", MultiBot.tips.rtsc.browse)

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
	-- Espace de sauvegarde pour la position de la barre des chasseurs
    MultiBotSaved = MultiBotSaved or {}
    MultiBotSaved.pos = MultiBotSaved.pos or {}
    MultiBotSaved.pos.HunterQuick = MultiBotSaved.pos.HunterQuick or {}
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
      -- Assurer l'existence des SV
      MultiBotSaved = MultiBotSaved or {}
      MultiBotSaved.pos = MultiBotSaved.pos or {}
      MultiBotSaved.pos.HunterQuick = MultiBotSaved.pos.HunterQuick or {}
      -- Sauvegarde
      MultiBotSaved.pos.HunterQuick.frame = { point = p, relPoint = rp, x = x, y = y }
    end)
    MBH.frame:Hide()

    function MBH:RestorePosition()
      local st = MultiBotSaved.pos
                and MultiBotSaved.pos.HunterQuick
                and MultiBotSaved.pos.HunterQuick.frame
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

    function MBH:_ensureSaved()
      MultiBotSaved = MultiBotSaved or {}
      MultiBotSaved.hunterPetStance = MultiBotSaved.hunterPetStance or {}
    end

	function MBH:GetSavedStance(name)
      self:_ensureSaved()
      return MultiBotSaved.hunterPetStance[name]
    end

	function MBH:SetSavedStance(name, stance)
      self:_ensureSaved()
      MultiBotSaved.hunterPetStance[name] = stance
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
          MultiBot.tips.hunter.ownbutton:format(hName))
      row.mainBtn:SetFrameStrata("HIGH")
      row.mainBtn:RegisterForDrag("RightButton")
      row.mainBtn:SetScript("OnDragStart", function() self.frame:StartMoving() end)
      -- row.mainBtn:SetScript("OnDragStop" , function() self.frame:StopMovingOrSizing() end)
      row.mainBtn:SetScript("OnDragStop", function()
        self.frame:StopMovingOrSizing()
        local p, _, rp, x, y = self.frame:GetPoint()
        -- Assurer l'existence des SV
        MultiBotSaved = MultiBotSaved or {}
        MultiBotSaved.pos = MultiBotSaved.pos or {}
        MultiBotSaved.pos.HunterQuick = MultiBotSaved.pos.HunterQuick or {}
        -- Sauvegarde
        MultiBotSaved.pos.HunterQuick.frame = { point = p, relPoint = rp, x = x, y = y }
      end)

      row.vmenu = row.addFrame("HunterQuickMenu_"..san, 0, 0, 36, 36, 36*3)
      row.vmenu:Hide()
      row.modesBtn = row.vmenu.addButton("HunterModesBtn_"..san, 0, 36, "ability_hunter_beasttaming", MultiBot.tips.hunter.pet.stances)
      row.utilsBtn = row.vmenu.addButton("HunterUtilsBtn_"..san, 0, 72, "trade_engineering", MultiBot.tips.hunter.pet.master)

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
        { key="aggressive", tip=MultiBot.tips.hunter.pet.aggressive },
        { key="passive"   , tip=MultiBot.tips.hunter.pet.passive   },
        { key="defensive" , tip=MultiBot.tips.hunter.pet.defensive },
        { key="stance"    , tip=MultiBot.tips.hunter.pet.curstance },
        { key="attack"    , tip=MultiBot.tips.hunter.pet.attack },
        { key="follow"    , tip=MultiBot.tips.hunter.pet.follow },
        { key="stay"      , tip=MultiBot.tips.hunter.pet.stay },
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
        {"Name",    "tame name %s",    "inv_scroll_11",            MultiBot.tips.hunter.pet.name},
        {"Id",      "tame id %s",      "inv_scroll_14",            MultiBot.tips.hunter.pet.id},
        {"Family",  "tame family %s",  "inv_misc_enggizmos_03",    MultiBot.tips.hunter.pet.family},
        {"Rename",  "tame rename %s",  "inv_scroll_01",            MultiBot.tips.hunter.pet.rename},
        {"Abandon", "tame abandon",    "spell_nature_spiritwolf",  MultiBot.tips.hunter.pet.abandon},
      }
      for i, v in ipairs(petCmdList) do
        local label, fmt, icon, tip = v[1], v[2], v[3], v[4]
        local px = -36 * (5 - i)
        local ub = row.utilsStrip.addButton("HunterQuickUtil_"..san.."_"..i, px, 0, icon, tip)
        ub.doLeft = function()
          if label == "Rename" then
            MBH:ShowPrompt(fmt, hName, MultiBot.info.hunterpetnewname)
            row.utilsStrip:Hide()
          elseif label == "Id" then
            MBH:ShowPrompt(fmt, hName, MultiBot.info.hunterpetid)
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
          if name and cls=="HUNTER" and MultiBot.getBot and (MultiBot.getBot(name) ~= nil or MultiBot.getBot(unit) ~= nil) then
            table.insert(out, name)
          end
        end
      else
        if GetNumPartyMembers then
          for i=1, GetNumPartyMembers() do
            local unit = "party"..i
            local name = UnitName(unit)
            local _, cls = UnitClass(unit)
            if name and cls=="HUNTER" and MultiBot.getBot and (MultiBot.getBot(name) ~= nil or MultiBot.getBot(unit) ~= nil) then
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
      local P = self.PROMPT
      if not P then
        P = CreateFrame("Frame", "MBHunterPrompt", UIParent)
        self.PROMPT = P
        P:SetSize(260, 90)
        P:SetPoint("CENTER")
        P:SetBackdrop({
          bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
          edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
          tile=true, tileSize=16, edgeSize=16,
          insets={left=4,right=4,top=4,bottom=4}
        })
        P:SetBackdropColor(0,0,0,0.9)
        P:SetFrameStrata("DIALOG")
        P:SetMovable(true); P:EnableMouse(true)
        P:RegisterForDrag("LeftButton")
        P:SetScript("OnDragStart", P.StartMoving)
        P:SetScript("OnDragStop" , P.StopMovingOrSizing)
        local btnClose = CreateFrame("Button", nil, P, "UIPanelCloseButton")
        btnClose:SetPoint("TOPRIGHT", -5, -5)
        btnClose:SetScript("OnClick", function() P:Hide() end)
        local e = CreateFrame("EditBox", nil, P, "InputBoxTemplate")
        e:SetAutoFocus(true); e:SetSize(200,20); e:SetTextColor(1,1,1)
        e:SetPoint("TOP", 0, -30)
        e:SetScript("OnEscapePressed", function() P:Hide() end)
        P.EditBox = e
        local ok = CreateFrame("Button", nil, P, "UIPanelButtonTemplate")
        ok:SetSize(60,20); ok:SetPoint("BOTTOM",0,10); ok:SetText("OK")
        P.OkBtn = ok
        P.Title = P:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        P.Title:SetPoint("TOP", 0, -10)
      end
      P.Title:SetText(title or MultiBot.info.hunterpeteditentervalue)
      P:Show()
      P.EditBox:SetText(MultiBot.info.hunterpetentersomething)
      P.EditBox:SetFocus()
      P.OkBtn:SetScript("OnClick", function()
        local text = P.EditBox:GetText()
        if text and text~="" and targetName then
          local cmd = string.format(fmt, text)
          SendChatMessage(cmd, "WHISPER", nil, targetName)
        end
        P:Hide()
      end)
    end

    function MBH:EnsureSearchFrame()
      if self.SEARCH_FRAME then return end
      local f = CreateFrame("Frame", "MBHunterPetSearch", UIParent)
      self.SEARCH_FRAME = f

      local title = f:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
      title:SetPoint("TOP",0,-10)
      title:SetText(MultiBot.info.hunterpetcreaturelist)

      f:SetSize(340,340)
      f:SetPoint("CENTER")
      f:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=16,
        insets={left=4,right=4,top=4,bottom=4}
      })
      f:SetBackdropColor(0,0,0,0.9)
      f:SetMovable(true); f:EnableMouse(true)
      f:RegisterForDrag("LeftButton")
      f:SetScript("OnDragStart", f.StartMoving)
      f:SetScript("OnDragStop" , f.StopMovingOrSizing)
      CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT",-5,-5)

      local e = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
      e:SetAutoFocus(true)
      e:SetSize(200,20)
      e:SetPoint("TOP", title, "BOTTOM", 0, -8)
      f.EditBox = e

      local PREVIEW_WIDTH, PREVIEW_HEIGHT = 180, 260
      local BLANK_MODEL   = "Interface\\Buttons\\WHITE8x8"
      local PREVIEW_MODEL_SCALE = 0.6
      local PREVIEW_FACING = -math.pi/12
      local PREVIEW_X_OFFSET, PREVIEW_Y_OFFSET = 100, 20
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
        return p
      end

      local function LoadCreatureToPreview(entryId)
        local pv = GetPreviewFrame()
        if pv:IsShown() and CURRENT_ENTRY==entryId then pv:Hide(); CURRENT_ENTRY=nil; return end
        CURRENT_ENTRY = entryId
        local cx,cy = GetCursorPosition(); local scale = UIParent:GetEffectiveScale()
        pv:ClearAllPoints()
        pv:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",
          cx/scale+PREVIEW_X_OFFSET, cy/scale+PREVIEW_Y_OFFSET)
        pv:SetUnit("none"); pv:ClearModel(); pv:SetModel(BLANK_MODEL); pv:Show()
        pv:SetScript("OnUpdate", function(self)
          self:SetScript("OnUpdate",nil)
          self:SetModelScale(PREVIEW_MODEL_SCALE)
          self:SetFacing(PREVIEW_FACING)
          self:SetCreature(entryId)
        end)
      end

      local ROW_H, VISIBLE_ROWS = 18, 17
      local OFFSET = 0
      local RESULTS = {}

      local sf = CreateFrame("ScrollFrame","MBHunterPetScroll",f,"UIPanelScrollFrameTemplate")
      sf:SetPoint("TOPLEFT",10,-60)
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
              LoadCreatureToPreview(data.id)
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
        ff = CreateFrame("Frame", "MBHunterPetFamily", UIParent)
        self.FAMILY_FRAME = ff
        ff:SetSize(220, 300)
        ff:SetPoint("CENTER")
        ff:SetBackdrop({
          bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
          edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
          tile=true, tileSize=16, edgeSize=16,
          insets={left=4, right=4, top=4, bottom=4}
        })
        ff:SetBackdropColor(0,0,0,0.9)
        ff:EnableMouse(true); ff:SetMovable(true)
        ff:RegisterForDrag("LeftButton")
        ff:SetScript("OnDragStart", ff.StartMoving)
        ff:SetScript("OnDragStop" , ff.StopMovingOrSizing)

        local title = ff:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, -10)
        title:SetText(MultiBot.info.hunterpetrandomfamily)

        local close = CreateFrame("Button", nil, ff, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -5, -5)

        local sf = CreateFrame("ScrollFrame", "MBHunterFamilyScroll", ff, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 8, -40)
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

    function MBH:HasHunterInGroup()
      local _, cls = UnitClass("player")
      if cls == "HUNTER" then return true end
      if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
          local _, c = UnitClass("raid"..i)
          if c == "HUNTER" then return true end
        end
      else
        if GetNumPartyMembers then
          for i = 1, GetNumPartyMembers() do
            local _, c = UnitClass("party"..i)
            if c == "HUNTER" then return true end
          end
        end
      end
      return false
    end

    MBH.presenceFrame = CreateFrame("Frame")
    MBH.presenceFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    if MBH.presenceFrame.RegisterEvent then
      MBH.presenceFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
      MBH.presenceFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    end
    MBH.presenceFrame:SetScript("OnEvent", function()
      MBH:Rebuild()
    end)

    if MultiBot.TimerAfter then
      MultiBot.TimerAfter(0.5, function() MBH:Rebuild() end)
    end

  end

  MultiBot.HunterQuick = MultiBot.HunterQuick or {}

  MultiBot.InitHunterQuick()

  if MultiBot.HunterQuick and MultiBot.HunterQuick.RestorePosition then
    MultiBot.HunterQuick:RestorePosition()
  end

  if not MultiBot.HunterQuick.ev then
    local f = CreateFrame("Frame")
    MultiBot.HunterQuick.ev = f
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PARTY_MEMBERS_CHANGED")
    f:RegisterEvent("RAID_ROSTER_UPDATE")
    f:RegisterEvent("UNIT_PET")
    f:SetScript("OnEvent", function()
      local HQ = MultiBot and MultiBot.HunterQuick
      if HQ and HQ.UpdateAllPetPresence then HQ:UpdateAllPetPresence() end
    end)
  end
end
-- End Hunter --

-- SHAMAN TOTEMS QUICK BAR --
if not MultiBot.InitShamanQuick then
  function MultiBot.InitShamanQuick()
    -- SavedVariables
    MultiBotSaved = MultiBotSaved or {}
    MultiBotSaved.pos = MultiBotSaved.pos or {}
    MultiBotSaved.pos.ShamanQuick = MultiBotSaved.pos.ShamanQuick or {}
	MultiBotSaved.shamanTotems = MultiBotSaved.shamanTotems or {}

    -- Helper: garantit l'existence de MultiBotSaved.pos.ShamanQuick
    local function _MB_GetOrCreateShamanPos()
      MultiBotSaved = MultiBotSaved or {}
      MultiBotSaved.pos = MultiBotSaved.pos or {}
      MultiBotSaved.pos.ShamanQuick = MultiBotSaved.pos.ShamanQuick or {}
      return MultiBotSaved.pos.ShamanQuick
    end

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
      _sp.frame = { point=p, relPoint=rp, x=x, y=y }
    end)

    -- Restaure la position sauvegardée
    function MBS:RestorePosition()
      -- Récupère la sous-table et la frame sauvegardée
      local _sp = (_MB_GetOrCreateShamanPos and _MB_GetOrCreateShamanPos())
                  or (MultiBotSaved and MultiBotSaved.pos and MultiBotSaved.pos.ShamanQuick)
      local st = _sp and _sp.frame
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
        tex:SetTexture(iconPath)
        btn._mb_iconPath = iconPath
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
            -- Nettoie la sauvegarde pour cet élément
            if MultiBotSaved and MultiBotSaved.shamanTotems and MultiBotSaved.shamanTotems[who] then
              MultiBotSaved.shamanTotems[who][ek] = nil
            end
          end
          -- Dégrise le bouton (retour visuel) + nettoie la sélection exclusive
          SetGrey(b, false)
          if row._selectedBtn[ek] == b then
            row._selectedBtn[ek] = nil
          end
        else
          MultiBot.ActionToTarget("co +" .. spell .. ",?", who)
          b._mb_on = tru
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
            -- Persiste pour ce bot + élément
            MultiBotSaved.shamanTotems = MultiBotSaved.shamanTotems or {}
            local perBot = MultiBotSaved.shamanTotems[who] or {}
            perBot[ek] = b._mb_icon
            MultiBotSaved.shamanTotems[who] = perBot
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

      row.mainBtn = row.addButton("ShamanQuickMain_"..san, 0, 0,
        "Interface\\AddOns\\MultiBot\\Icons\\class_shaman.blp",
        (MultiBot.tips and MultiBot.tips.shaman and MultiBot.tips.shaman.ownbutton) and MultiBot.tips.shaman.ownbutton:format(sName) or ("Shaman: "..sName))
      row.mainBtn:SetFrameStrata("HIGH")
      row.mainBtn:RegisterForDrag("RightButton")
      row.mainBtn:SetScript("OnDragStart", function() self.frame:StartMoving() end)
      -- Stop et save position quand on lâche le drag depuis le main bouton
      row.mainBtn:SetScript("OnDragStop" , function()
        self.frame:StopMovingOrSizing()
        local p, _, rp, x, y = self.frame:GetPoint()
        local _sp = _MB_GetOrCreateShamanPos()
        _sp.frame = { point=p, relPoint=rp, x=x, y=y }
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
        MultiBot.tips.shaman.ctotem.earthtot)
      row.earthBtn._mb_key = "ShamanEarthBtn_"..san
	  row.earthGrp = row.addFrame("ShamanEarthGrp_"..san, 40, 0, 36, 36, 36*5); row.earthGrp:Hide()
      row.earthBtn.doLeft = function() ToggleGroup(row.earthGrp) end
	  row._elemBtns.earth = row.earthBtn

      AddTotemToggle(row, row.earthGrp, "StrengthOfEarth_"..san, 0, 0, "spell_nature_earthbindtotem",
        MultiBot.tips.shaman.ctotem.stoe,   "strength of earth", sName, "earth")
      AddTotemToggle(row, row.earthGrp, "Stoneskin_"..san, 0,  36, "spell_nature_stoneskintotem",
        MultiBot.tips.shaman.ctotem.stoskin,       "stoneskin", sName, "earth")
      AddTotemToggle(row, row.earthGrp, "Tremor_"..san, 0,  72, "spell_nature_tremortotem",
        MultiBot.tips.shaman.ctotem.tremor, "tremor", sName, "earth")
      AddTotemToggle(row, row.earthGrp, "Earthbind_"..san, 0, 108, "spell_nature_strengthofearthtotem02",
        MultiBot.tips.shaman.ctotem.eabind, "earthbind",         sName, "earth")

      -- Fire --
      row.fireBtn = row.vmenu.addButton("ShamanFireBtn_"..san, 0, 72, row._defaults.fire,
        MultiBot.tips.shaman.ctotem.firetot)
      row.fireBtn._mb_key = "ShamanFireBtn_"..san
	  row.fireGrp = row.addFrame("ShamanFireGrp_"..san, 80, 0, 36, 36, 36*5); row.fireGrp:Hide()
      row.fireBtn.doLeft = function() ToggleGroup(row.fireGrp) end
	  row._elemBtns.fire = row.fireBtn

      AddTotemToggle(row, row.fireGrp, "Searing_"..san, 0, 0, "spell_fire_searingtotem",
        MultiBot.tips.shaman.ctotem.searing,  "searing", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "Magma_"..san, 0,  36, "spell_fire_moltenblood",
        MultiBot.tips.shaman.ctotem.magma,    "magma", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "Flametongue_"..san, 0,  72, "spell_nature_guardianward",
        MultiBot.tips.shaman.ctotem.fltong,   "flametongue", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "Wrath_"..san, 0, 108, "spell_fire_totemofwrath",
        MultiBot.tips.shaman.ctotem.towrath,  "wrath", sName, "fire")
      AddTotemToggle(row, row.fireGrp, "FrostResist_"..san, 0, 144, "spell_frost_frostward",
        MultiBot.tips.shaman.ctotem.frostres, "frost resistance", sName, "fire")

      -- Water --
      row.waterBtn = row.vmenu.addButton("ShamanWaterBtn_"..san, 0, 108, row._defaults.water,
        MultiBot.tips.shaman.ctotem.watertot)
      row.waterBtn._mb_key = "ShamanWaterBtn_"..san
	  row.waterGrp = row.addFrame("ShamanWaterGrp_"..san, 120, 0, 36, 36, 36*4); row.waterGrp:Hide()
      row.waterBtn.doLeft = function() ToggleGroup(row.waterGrp) end
	  row._elemBtns.water = row.waterBtn

      AddTotemToggle(row, row.waterGrp, "HealingStream_"..san, 0, 0, "spell_nature_healingwavelesser",
        MultiBot.tips.shaman.ctotem.healstream, "healing stream", sName, "water")
      AddTotemToggle(row, row.waterGrp, "ManaSpring_"..san, 0, 36, "spell_nature_manaregentotem",
        MultiBot.tips.shaman.ctotem.manasprin, "mana spring", sName, "water")
      AddTotemToggle(row, row.waterGrp, "Cleansing_"..san, 0, 72, "spell_nature_nullifydisease",
        MultiBot.tips.shaman.ctotem.cleansing, "cleansing", sName, "water")
      AddTotemToggle(row, row.waterGrp, "FireResistW_"..san, 0, 108, "spell_fire_firearmor",
        MultiBot.tips.shaman.ctotem.fireres, "fire resistance", sName, "water")

      -- Air --
      row.airBtn = row.vmenu.addButton("ShamanAirBtn_"..san, 0, 144, row._defaults.air,
        MultiBot.tips.shaman.ctotem.airtot)
      row.airBtn._mb_key = "ShamanAirBtn_"..san
	  row.airGrp = row.addFrame("ShamanAirGrp_"..san, 160, 0, 36, 36, 36*4); row.airGrp:Hide()
      row.airBtn.doLeft = function() ToggleGroup(row.airGrp) end
	  row._elemBtns.air = row.airBtn

      AddTotemToggle(row, row.airGrp, "WrathOfAir_"..san, 0, 0, "spell_nature_slowingtotem",
        MultiBot.tips.shaman.ctotem.wrhatair, "wrath of air", sName, "air")
      AddTotemToggle(row, row.airGrp, "Windfury_"..san, 0, 36, "spell_nature_windfury",
        MultiBot.tips.shaman.ctotem.windfury, "windfury", sName, "air")
      AddTotemToggle(row, row.airGrp, "NatureResist_"..san, 0, 72, "spell_nature_natureresistancetotem",
        MultiBot.tips.shaman.ctotem.natres, "nature resistance", sName, "air")
      AddTotemToggle(row, row.airGrp, "Grounding_"..san, 0, 108, "spell_nature_groundingtotem",
        MultiBot.tips.shaman.ctotem.grounding, "grounding", sName, "air")

      -- Restauration depuis SavedVariables (icône et grisé exclusif)
      do
        local saved = MultiBotSaved and MultiBotSaved.shamanTotems and MultiBotSaved.shamanTotems[sName]
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

do
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("GROUP_ROSTER_UPDATE")
  f:RegisterEvent("PARTY_MEMBERS_CHANGED")
  f:SetScript("OnEvent", function()
    if MultiBot and MultiBot.ShamanQuick and MultiBot.ShamanQuick.RefreshFromGroup then
      MultiBot.ShamanQuick:RefreshFromGroup()
    end
  end)
end

-- Créer/Afficher (ou cacher) le bouton minimap APRÈS chargement complet
do
  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_LOGIN")
  ev:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN")
    -- SV garanties ici ; appliquer l’état mémorisé proprement
    if MultiBot and MultiBot.Minimap_Refresh then
      MultiBot.Minimap_Refresh()
    elseif MultiBot and MultiBot.Minimap_Create then
      -- Fallback hyper défensif si Refresh pas encore défini
      if not (MultiBotSave and MultiBotSave.Minimap and MultiBotSave.Minimap.hide) then
        MultiBot.Minimap_Create()
      --else
        -- hide=true => ne crée pas le bouton
      end
    end
  end)
end

-- FINISH --

MultiBot.state = true
print("MultiBot")