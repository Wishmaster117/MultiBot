local SPELLBOOK_PAGE_SIZE = 18

local function getSpellBookUI()
	return MultiBot.SpellBookUISettings or {}
end

MultiBot.getSpellID = function(pInfo)
	if(type(pInfo) ~= "string" or pInfo == "") then
		return 0
	end

	local tInfo = MultiBot.doSplit(pInfo, "|")
	local tLinkInfo = tInfo and tInfo[3]
	if(type(tLinkInfo) ~= "string") then
		return 0
	end

	if(string.sub(tLinkInfo, 1, 6) ~= "Hspell") then
		return 0
	end

	local tSpellId = string.match(tLinkInfo, "Hspell:(%d+)")
	if(not tSpellId) then
		return 0
	end

	return tonumber(tSpellId) or 0
end

MultiBot.addSpell = function(pInfo, pName)
	local tID = MultiBot.getSpellID(pInfo)
	if(tID == 0) then return end

	local tName, tRank, tIcon = GetSpellInfo(tID)
	local tLink = GetSpellLink(tID)

	if(tName == nil) then tName = "" end
	if(tRank == nil) then tRank = "" end
	if(tIcon == nil) then tIcon = "inv_misc_questionmark" end
	if(tLink == nil) then tLink = tName end

	local tSpell = { tID, tName, tRank, tIcon, tLink }

	table.insert(MultiBot.spellbook.spells, tSpell)
	MultiBot.spellbook.index = MultiBot.spellbook.index + 1

	if(MultiBot.spells[pName] == nil) then MultiBot.spells[pName] = {} end
	if(MultiBot.spells[pName][tID] == nil) then MultiBot.spells[pName][tID] = true end

	if(MultiBot.spellbook.index < (SPELLBOOK_PAGE_SIZE + 1)) then
		MultiBot.setSpell(MultiBot.spellbook.index, tSpell, pName)
	end
end

MultiBot.beginSpellbookCollection = function(pName)
	local tOverlay = MultiBot.spellbook.frames["Overlay"]
	local tSpellbook = MultiBot.spellbook
    local tWindowTitle = MultiBot.doReplace(MultiBot.L("info.spellbook"), "NAME", pName)

	for key in pairs(tSpellbook.spells) do tSpellbook.spells[key] = nil end
	if(tSpellbook.setTitle) then tSpellbook:setTitle(tWindowTitle) end
	tSpellbook.name = pName
	tSpellbook.index = 0
	tSpellbook.from = 1
	tSpellbook.to = SPELLBOOK_PAGE_SIZE
	tSpellbook.now = 1
	tSpellbook.max = 1

	for i = 1, SPELLBOOK_PAGE_SIZE do
		MultiBot.setSpell(i, nil, pName)
	end
end

MultiBot.finishSpellbookCollection = function()
	local tOverlay = MultiBot.spellbook.frames["Overlay"]
	local tSpellbook = MultiBot.spellbook

	tSpellbook.now = 1
	tSpellbook.max = math.max(1, math.ceil((tSpellbook.index or 0) / SPELLBOOK_PAGE_SIZE))
	tOverlay.setText("Pages", "|cff" .. (getSpellBookUI().PAGE_TEXT_COLOR_HEX or "ffffff") .. tSpellbook.now .. "/" .. tSpellbook.max .. "|r")
	if(tSpellbook.now == tSpellbook.max) then tOverlay.buttons[">"].doHide() else tOverlay.buttons[">"].doShow() end
	tOverlay.buttons["<"].doHide()
	tSpellbook:Show()
end

MultiBot.isSpellbookHeaderLine = function(pLine)
	if(type(pLine) ~= "string") then
		return false
	end

	return MultiBot.isInside(pLine, SPELLBOOK, "Spells", "法术", "Магия")
end

MultiBot.isSpellbookFooterLine = function(pLine)
	if(type(pLine) ~= "string") then
		return false
	end

	local tBag = MultiBot.L("info.shorts.bag") or "Bag"
	local tDur = MultiBot.L("info.shorts.dur") or "Dur"
	local tXP = MultiBot.L("info.shorts.xp") or "XP"

	return MultiBot.isInside(pLine, tBag, tDur, tXP, "Bag,", "Dur", "XP", "背包", "耐久度", "经验值")
end

MultiBot.setSpell = function(pIndex, pSpell, pName)
	local tIndex = MultiBot.IF(pIndex < 10, "0", "") .. pIndex
	local tOverlay = MultiBot.spellbook.frames["Overlay"]

	if(pSpell ~= nil) then
		tOverlay.setButton("S" .. tIndex, pSpell[4], pSpell[5])
		tOverlay.setText("R" .. tIndex, "|cff" .. (getSpellBookUI().RANK_TEXT_COLOR_HEX or "ffcc00") .. pSpell[3] .. "|r")
		tOverlay.buttons["S" .. tIndex].spell = pSpell[1]
		tOverlay.buttons["C" .. tIndex].spell = pSpell[1]
		tOverlay.buttons["S" .. tIndex].doShow()
		tOverlay.buttons["C" .. tIndex].doShow()
		tOverlay.texts["R" .. tIndex]:Show()
		tOverlay.buttons["C" .. tIndex]:SetChecked(MultiBot.spells[pName][pSpell[1]])
		tOverlay.buttons["C" .. tIndex].doClick = function(pButton)
			local tName = pButton.getName()
			local tAction = ""
			MultiBot.spells[tName][pButton.spell] = MultiBot.IF(MultiBot.spells[tName][pButton.spell], false, true)
			pButton:SetChecked(MultiBot.spells[tName][pButton.spell])
			for id, state in pairs(MultiBot.spells[tName]) do
				if(state == false) then tAction = tAction .. MultiBot.IF(tAction == "", "ss +", ", +") .. id end
			end
			MultiBot.ActionToTarget(MultiBot.IF(tAction == "", "ss -" .. pButton.spell, tAction), tName)
		end
	else
		tOverlay.buttons["S" .. tIndex].spell = 0
		tOverlay.buttons["C" .. tIndex].spell = 0
		tOverlay.buttons["S" .. tIndex].doHide()
		tOverlay.buttons["C" .. tIndex].doHide()
		tOverlay.texts["T" .. tIndex]:Hide()
		tOverlay.texts["R" .. tIndex]:Hide()
	end
end