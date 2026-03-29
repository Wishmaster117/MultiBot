MultiBot.MB_PAGE_DEFAULT = string.format("%d/%d", 0, 0)

-- Minimap config and button logic moved to UI/MultiBotMinimap.lua.

-- MULTIBAR --
local tMultiBar = MultiBot.addFrame("MultiBar", -322, 144, 36)
MultiBot.PromoteFrame(tMultiBar)
tMultiBar:SetMovable(true)
-- Évite les micro-dépassements avec certains UI scale qui finissent par décaler Y
tMultiBar:SetClampedToScreen(true)

-- LEFT --
local tLeft = tMultiBar.addFrame("Left", -76, 2, 32)
MultiBot.PromoteFrame(tLeft)

if MultiBot.InitializeLeftCoreUI then
	MultiBot.InitializeLeftCoreUI(tLeft)
end

--  We call it when tLeft are ready
MultiBot.BuildAttackUI(tLeft)

--  We call it when tLeft are ready
MultiBot.BuildFleeUI(tLeft)

-- We call it, when tLeft are ready
if MultiBot.BuildFormationUI then
	MultiBot.BuildFormationUI(tLeft)
elseif MultiBot.dprint then
	MultiBot.dprint("INIT", "BuildFormationUI missing at init time")
end

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