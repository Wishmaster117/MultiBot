MultiBot.addHunter = function(pFrame, pCombat, pNormal)
	local tButton = pFrame.addButton("NonCombatAspect", 0, 0, "spell_nature_protectionformnature", MultiBot.tips.hunter.naspect.master)
	tButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["NonCombatAspect"])
	end
	
	local tFrame = pFrame.addFrame("NonCombatAspect", -2, 30)
	tFrame:Hide()
	
	tFrame.addButton("NonCombatNature", 0, 0, "spell_nature_protectionformnature", MultiBot.tips.hunter.naspect.rnature)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +rnature,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +rnature,?", "nc -rnature,?", pButton.getName())
		end
	end
	
	tFrame.addButton("NonCombatSpeed", 0, 26, "ability_mount_whitetiger", MultiBot.tips.hunter.naspect.bspeed)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bspeed,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bspeed,?", "nc -bspeed,?", pButton.getName())
		end
	end
	
	tFrame.addButton("NonCombatMana", 0, 52, "ability_hunter_aspectoftheviper", MultiBot.tips.hunter.naspect.bmana)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bmana,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	end
	
	tFrame.addButton("NonCombatDps", 0, 78, "ability_hunter_pet_dragonhawk", MultiBot.tips.hunter.naspect.bdps)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "NonCombatAspect", pButton.texture, "nc +bdps,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end
	
	-- STRATEGIES:NON-COMBAT-BUFF --
	
	if(MultiBot.isInside(pNormal, "rnature")) then
		tButton.setTexture("spell_nature_protectionformnature").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +rnature,?", "nc -rnature,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bspeed")) then
		tButton.setTexture("ability_mount_whitetiger").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bspeed,?", "nc -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bmana")) then
		tButton.setTexture("ability_hunter_aspectoftheviper").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bdps")) then
		tButton.setTexture("ability_hunter_pet_dragonhawk").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end
	
	-- COMABT-BUFF --
	
	local tButton = pFrame.addButton("CombatAspect", -30, 0, "spell_nature_protectionformnature", MultiBot.tips.hunter.caspect.master)
	tButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["CombatAspect"])
	end
	
	local tFrame = pFrame.addFrame("CombatAspect", -32, 30)
	tFrame:Hide()
	
	tFrame.addButton("CombatNature", 0, 0, "spell_nature_protectionformnature", MultiBot.tips.hunter.caspect.rnature)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +rnature,?", pButton.getName())
		pButton.getButton("CombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +rnature,?", "co -rnature,?", pButton.getName())
		end
	end
	
	tFrame.addButton("CombatSpeed", 0, 26, "ability_mount_whitetiger", MultiBot.tips.hunter.caspect.bspeed)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +bspeed,?", pButton.getName())
		pButton.getButton("NonCombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bspeed,?", "co -bspeed,?", pButton.getName())
		end
	end
	
	tFrame.addButton("CombatMana", 0, 52, "ability_hunter_aspectoftheviper", MultiBot.tips.hunter.caspect.bmana)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +bmana,?", pButton.getName())
		pButton.getButton("CombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bmana,?", "co -bmana,?", pButton.getName())
		end
	end
	
	tFrame.addButton("CombatDps", 0, 78, "ability_hunter_pet_dragonhawk", MultiBot.tips.hunter.caspect.bdps)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "CombatAspect", pButton.texture, "co +bdps,?", pButton.getName())
		pButton.getButton("CombatAspect").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bdps,?", "co -bdps,?", pButton.getName())
		end
	end
	
	-- STRATEGIES:COMABT-ASPECT --
	
	if(MultiBot.isInside(pCombat, "rnature")) then
		tButton.setTexture("spell_nature_protectionformnature").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +rnature,?", "co -rnature,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bspeed")) then
		tButton.setTexture("ability_mount_whitetiger").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bspeed,?", "co -bspeed,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bmana")) then
		tButton.setTexture("ability_hunter_aspectoftheviper").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bmana,?", "co -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pCombat, "bdps")) then
		tButton.setTexture("ability_hunter_pet_dragonhawk").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "co +bdps,?", "co -bdps,?", pButton.getName())
		end
	end
	
	-- DPS --
	
	pFrame.addButton("DpsControl", -60, 0, "ability_warrior_challange", MultiBot.tips.hunter.dps.master)
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end
	
	local tFrame = pFrame.addFrame("DpsControl", -62, 30)
	tFrame:Hide()
	
	tFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.tips.hunter.dps.dpsAssist).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end
	
	tFrame.addButton("DpsDebuff", 0, 26, "spell_holy_restoration", MultiBot.tips.hunter.dps.dpsDebuff).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +dps debuff,?", "co -dps debuff,?", pButton.getName())
	end
	
	tFrame.addButton("DpsAoe", 0, 52, "spell_holy_surgeoflight", MultiBot.tips.hunter.dps.dpsAoe).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end
	
	tFrame.addButton("Dps", 0, 78, "spell_holy_divinepurpose", MultiBot.tips.hunter.dps.dps).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +dps,?", "co -dps,?", pButton.getName())
	end
	
	-- ASSIST --
	
	pFrame.addButton("TankAssist", -90, 0, "ability_warrior_innerrage", MultiBot.tips.hunter.tankAssist).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end

	-- --------------------- --
	-- HUNTER : PET COMMANDS --
	-- --------------------- --
	
	-- Configuration of the 4 commands
	local petCmdList = {
		{"Name",   "pet name %s",    "inv_scroll_11",           MultiBot.tips.hunter.pet.name},
		{"Id",     "pet id %s",      "inv_scroll_14",           MultiBot.tips.hunter.pet.id},
		{"Family", "pet family %s",  "inv_misc_enggizmos_03",   MultiBot.tips.hunter.pet.family},
		{"Rename", "pet rename %s",  "inv_scroll_01",           MultiBot.tips.hunter.pet.rename},
	}
	
	-- Parent button
	local btnPetCmd = pFrame.addButton(
		"PetCmdSelect", -120, 0,
		"ability_druid_cower",
		MultiBot.tips.hunter.pet.master
	)
	local fPetCmd = pFrame.addFrame("PetCmdBar", -122, 30)
	fPetCmd:Hide()
	btnPetCmd.doLeft = function() MultiBot.ShowHideSwitch(fPetCmd) end
	
	-- PROMPT window (single field + OK)

	local PROMPT
	local function ShowPrompt(fmt, targetButton, title)
		if not PROMPT then
			PROMPT = CreateFrame("Frame", "MBHunterPrompt", UIParent)
			PROMPT:SetSize(260, 90)
			PROMPT:SetPoint("CENTER")
			PROMPT:SetBackdrop({
				bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
				tile=true, tileSize=16, edgeSize=16,
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
	
			-- EditBox
			local e = CreateFrame("EditBox", nil, PROMPT, "InputBoxTemplate")
			e:SetAutoFocus(true)
			e:SetSize(200, 20)
			e:SetTextColor(1,1,1)
			e:SetPoint("TOP", 0, -30)
			PROMPT.EditBox = e
			e:SetScript("OnEscapePressed", function(self) PROMPT:Hide() end)
	
			-- OK Button
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
		
		PROMPT.Title:SetText(title or MultiBot.info.hunterpeteditentervalue)
		PROMPT:Show()
		PROMPT.EditBox:SetText(MultiBot.info.hunterpetentersomething)
		PROMPT.EditBox:SetFocus()
	
		PROMPT.OkBtn:SetScript("OnClick", function()
			local text = PROMPT.EditBox:GetText()
			if text and text~="" then
				local cmd = fmt:format(text)
				SendChatMessage(cmd, "WHISPER", nil, targetButton:getName())
			end
			PROMPT:Hide()
		end)
	end
	
	-- Pet Name LIST window + search

	local SEARCH_FRAME
	local function EnsureSearchFrame()
	if SEARCH_FRAME then return end
	
	local f = CreateFrame("Frame", "MBHunterPetSearch", UIParent)
	SEARCH_FRAME = f
	
	-- title
	local title = f:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
	title:SetPoint("TOP",0,-10)
	title:SetText(MultiBot.info.hunterpetcreaturelist)
	
	f:SetSize(340,340)
	f:SetPoint("CENTER")
	f:SetBackdrop({
		bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
		tile=true, tileSize=16, edgeSize=16,
		insets={left=4, right=4, top=4, bottom=4}
	})
	f:SetBackdropColor(0,0,0,0.9)
	f:SetMovable(true); f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop" , f.StopMovingOrSizing)
	
	-- button close
	CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT",-5,-5)
	
	-- search frame
	local e = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
	e:SetAutoFocus(true)
	e:SetSize(200,20)
	e:SetPoint("TOP", title, "BOTTOM", 0, -8)
	f.EditBox = e
	
	-- 3D preview
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
		p:SetScript("OnDragStop",  p.StopMovingOrSizing)
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

	-- OPTI 17 LINES
	local ROW_H            = 18
	local VISIBLE_ROWS     = 17          -- Physical lines
	local OFFSET           = 0           -- Logical index of the 1st visible line
	local RESULTS          = {}
	
	-- ScrollFrame & content
	local sf = CreateFrame("ScrollFrame","MBHunterPetScroll",f,"UIPanelScrollFrameTemplate")
	sf:SetPoint("TOPLEFT",10,-60)
	sf:SetPoint("BOTTOMRIGHT",-30,10)
	local content = CreateFrame("Frame",nil,sf) ; content:SetSize(1,1)
	sf:SetScrollChild(content)
	
	-- Physical lines created only once
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
	
	-- Language utility
	local function localeField()
		local l = GetLocale():lower()
		if l=="frfr" then return "name_fr"
		elseif l=="dede" then return "name_de"
		elseif l=="eses" then return "name_es"
		elseif l=="esmx" then return "name_esmx"
		elseif l=="kokr" then return "name_ko"
		elseif l=="zhtw" then return "name_zhtw"
		elseif l=="zhcn" then return "name_zhcn"
		elseif l=="ruru" then return "name_ru"
		else return "name_en" end
	end
	
	-- Refreshes the 17 visible lines
	function f:RefreshRows()
	for i = 1, VISIBLE_ROWS do
		local idx  = i + OFFSET
		local data = RESULTS[idx]
		local row  = self.Rows[i]
		local LIST_W = 320
	
		row:ClearAllPoints()                                   -- We clear
		row:SetPoint("TOPLEFT", 0, -((i-1 + OFFSET) * ROW_H))  -- We replace
		row:SetWidth(LIST_W) 
	
		if data then
		row.text:SetText(
			string.format("|cffffd200%-24s|r |cff888888[%s]|r",
			data.name, MultiBot.PET_FAMILY[data.family] or "?"))
	
		row:SetScript("OnClick", function()
			SendChatMessage(("pet id %d"):format(data.id),
			"WHISPER", nil, f.TargetButton:getName())
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
	
	
	-- Virtual scroll
	sf:SetScript("OnVerticalScroll", function(_,delta)
		local newOffset = math.floor(sf:GetVerticalScroll()/ROW_H + 0.5)
		if newOffset ~= OFFSET then OFFSET = newOffset; f:RefreshRows() end
	end)
	
	-- Filtering / Sorting
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
	
	-- END OPTI 17 LINES
    end
	
	-- Family LIST window
	local FAMILY_FRAME
	local function ShowFamilyFrame(targetButton)
		if not FAMILY_FRAME then
			local ff = CreateFrame("Frame", "MBHunterPetFamily", UIParent)
			FAMILY_FRAME = ff
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
			ff:SetScript("OnDragStop",  ff.StopMovingOrSizing)

			local title = ff:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			title:SetPoint("TOP", 0, -10)
			title:SetText(MultiBot.info.hunterpetrandomfamily)
		
			local close = CreateFrame("Button", nil, ff, "UIPanelCloseButton")
			close:SetPoint("TOPRIGHT", -5, -5)
	
			local sf = CreateFrame("ScrollFrame", "MBHunterFamilyScroll", ff, "UIPanelScrollFrameTemplate")
			sf:SetPoint("TOPLEFT", 8, -40)
			sf:SetPoint("BOTTOMRIGHT", -28, 8)
			local LIST_W = 320                     -- Displayed width
			local content = CreateFrame("Frame", nil, sf)
			content:SetSize(LIST_W, 1)
			sf:SetScrollChild(content)
			ff.Content = content
			ff.Rows = {}
	
			local ROW_H = 18
			
			-- Prepare localization
			local loc  = GetLocale()                -- ex. "frFR"
			local L10N = MultiBot.PET_FAMILY_L10N   -- Translation table loaded elsewhere
					and MultiBot.PET_FAMILY_L10N[loc]
			
			local families = {}
			for fid, eng in pairs(MultiBot.PET_FAMILY) do
				local txt = (L10N and L10N[fid]) or eng   -- always text
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
					-- Keep the English name in the command
					local cmd = ("pet family %s"):format(data.eng)
					SendChatMessage(cmd, "WHISPER", nil, targetButton:getName())
					FAMILY_FRAME:Hide()
				end)
			end
		end
		FAMILY_FRAME:Show()
	end
	
	-- Creation of the 4 toolbar buttons
	for i,v in ipairs(petCmdList) do
		local label, fmt, icon, tip = unpack(v)
		local b = fPetCmd.addButton("Pet"..label, 0, (i-1)*26, icon, tip)
	
		b.doLeft = function(pButton)
			if label == "Rename" then
				ShowPrompt(fmt, pButton, MultiBot.info.hunterpetnewname)
				fPetCmd:Hide()
			elseif label == "Id" then
				ShowPrompt(fmt, pButton, MultiBot.info.hunterpetid)
				fPetCmd:Hide()
			elseif label == "Family" then
				ShowFamilyFrame(pButton)
				fPetCmd:Hide()
			else -- Name
				EnsureSearchFrame()
				local f = SEARCH_FRAME
				f.TargetButton = pButton
				f:Show()
				f.EditBox:SetText("")
				f.EditBox:SetFocus()
				f:Refresh()
				fPetCmd:Hide()
			end
		end
	end
	
	-- FIN PET COMMANDS
	
	-- STRATEGIES --
	
	if(MultiBot.isInside(pCombat, "dps,")) then pFrame.getButton("Dps").setEnable() end
	if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
	if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
	if(MultiBot.isInside(pCombat, "dps debuff")) then pFrame.getButton("DpsDebuff").setEnable() end
	if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
end