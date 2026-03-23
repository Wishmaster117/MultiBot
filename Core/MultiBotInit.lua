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
-- UNITS ROOT --
if MultiBot.InitializeUnitsRootUI then
	MultiBot.InitializeUnitsRootUI(tMultiBar)
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
if MultiBot.InitializeRTSCUI then
	MultiBot.InitializeRTSCUI(tMultiBar)
end

-- FINISH --

MultiBot.state = true
print("MultiBot")