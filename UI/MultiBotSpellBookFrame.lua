function MultiBot.InitializeSpellBookFrame()

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


end