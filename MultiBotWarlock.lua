
MultiBot.addWarlock = function(pFrame, pCombat, pNormal)
	local tButton = pFrame.addButton("Buff", 0, 0, "spell_shadow_lifedrain02", MultiBot.tips.warlock.buff.master)
	tButton.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.parent.frames["Buff"])
	end
	
	local tFrame = pFrame.addFrame("Buff", -2, 30)
	tFrame:Hide()
	
	tFrame.addButton("BuffHealth", 0, 0, "spell_shadow_lifedrain02", MultiBot.tips.warlock.buff.bhealth)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bhealth,?", pButton.getName())
		pButton.getButton("Buff").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bhealth,?", "nc -bhealth,?", pButton.getName())
		end
	end
	
	tFrame.addButton("BuffMana", 0, 26, "spell_shadow_siphonmana", MultiBot.tips.warlock.buff.bmana)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bmana,?", pButton.getName())
		pButton.getButton("Buff").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	end
	
	tFrame.addButton("BuffDps", 0, 52, "spell_shadow_haunting", MultiBot.tips.warlock.buff.bdps)
	.doLeft = function(pButton)
		MultiBot.SelectToTarget(pButton.get(), "Buff", pButton.texture, "nc +bdps,?", pButton.getName())
		pButton.getButton("Buff").doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end
	
	-- STRATEGIES:BUFF --
	
	if(MultiBot.isInside(pNormal, "bhealth")) then
		tButton.setTexture("spell_shadow_lifedrain02").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bhealth,?", "nc -bhealth,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bmana")) then
		tButton.setTexture("spell_shadow_siphonmana").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bmana,?", "nc -bmana,?", pButton.getName())
		end
	elseif(MultiBot.isInside(pNormal, "bdps")) then
		tButton.setTexture("spell_shadow_haunting").setEnable().doRight = function(pButton)
			MultiBot.OnOffActionToTarget(pButton, "nc +bdps,?", "nc -bdps,?", pButton.getName())
		end
	end
	
	-- DPS --
	
	pFrame.addButton("DpsControl", -30, 0, "ability_warrior_challange", MultiBot.tips.warlock.dps.master)
	.doLeft = function(pButton)
		MultiBot.ShowHideSwitch(pButton.getFrame("DpsControl"))
	end
	
	local tFrame = pFrame.addFrame("DpsControl", -32, 30)
	tFrame:Hide()
	
	tFrame.addButton("DpsAssist", 0, 0, "spell_holy_heroism", MultiBot.tips.warlock.dps.dpsAssist).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps assist,?", "co -dps assist,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end
	
	tFrame.addButton("DpsDebuff", 0, 26, "spell_holy_restoration", MultiBot.tips.warlock.dps.dpsDebuff).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "co +dps debuff,?", "co -dps debuff,?", pButton.getName())
	end
	
	tFrame.addButton("DpsAoe", 0, 52, "spell_holy_surgeoflight", MultiBot.tips.warlock.dps.dpsAoe).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps aoe,?", "co -dps aoe,?", pButton.getName())) then
			pButton.getButton("TankAssist").setDisable()
			pButton.getButton("DpsAssist").setDisable()
		end
	end
	
	tFrame.addButton("Dps", 0, 78, "spell_holy_divinepurpose", MultiBot.tips.warlock.dps.dps).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +dps,?", "co -dps,?", pButton.getName())) then
			pButton.getButton("Tank").setDisable()
		end
	end

    -- META MELEE (Démonologie) --
    local btnMeta = tFrame.addButton(
      "MetaMelee", 0, 104, "Spell_Shadow_DemonForm",
      (MultiBot.tips.warlock.dps and MultiBot.tips.warlock.dps.metamelee)
    )
    btnMeta.setDisable()
    
    btnMeta.doLeft = function(pButton)
      MultiBot.OnOffActionToTarget(pButton, "co +meta melee,?", "co -meta melee,?", pButton.getName())
    end
    	
		-- ASSIST --
	
	pFrame.addButton("TankAssist", -60, 0, "ability_warrior_innerrage", MultiBot.tips.warlock.tankAssist).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank assist,?", "co -tank assist,?", pButton.getName())) then
			pButton.getButton("DpsAssist").setDisable()
			pButton.getButton("DpsAoe").setDisable()
		end
	end
	
	-- TANK --
	
	pFrame.addButton("Tank", -90, 0, "ability_warrior_shieldmastery", MultiBot.tips.warlock.tank).setDisable()
	.doLeft = function(pButton)
		if(MultiBot.OnOffActionToTarget(pButton, "co +tank,?", "co -tank,?", pButton.getName())) then
			pButton.getButton("Dps").setDisable()
		end
	end

	-- CURSES --
	
	local btnCurses = pFrame.addButton("CursesSelect", -120, 0,
					"ability_warlock_avoidance",
					MultiBot.tips.warlock.curses.master)
	
	local fCurses   = pFrame.addFrame("Curses", -122, 30)
	fCurses:Hide()
	fCurses.activeCurse = nil          -- memorize active label
	
	btnCurses.doLeft = function() MultiBot.ShowHideSwitch(fCurses) end
	
	local curseList = {
		{"Agony",      "curse of agony",        "Spell_Shadow_CurseOfSargeras"},
		{"Elements",   "curse of elements",     "Spell_Shadow_ChillTouch"},
		{"Exhaustion", "curse of exhaustion",   "Spell_Shadow_GrimWard"},
		{"Doom",       "curse of doom",         "Spell_Shadow_AuraOfDarkness"},
		{"Weakness",   "curse of weakness",     "Spell_Shadow_CurseOfMannoroth"},
		{"Tongues",    "curse of tongues",      "Spell_Shadow_CurseOfTounges"},
	}
	
	-- Generate 6 sub-buttons
	for i,v in ipairs(curseList) do
		local label, cmd, icon = unpack(v)
		local b = fCurses.addButton("Curse"..label, 0, (i-1)*26, icon,
				MultiBot.tips.warlock.curses[label:lower()])
	
		--   CLICK  --
		b.doLeft = function(pButton)
			-- 1) debug + whisper
			--[[DEFAULT_CHAT_FRAME:AddMessage(
				("[MB DEBUG] > %s : co +%s"):format(pButton.getName(), cmd), 0.9,0.9,0.2)]]--
			SendChatMessage("co +"..cmd, "WHISPER", nil, pButton.getName())
	
			-- 2) visual aspect
			for _,child in pairs(fCurses.buttons) do
				if child.icon then child.icon:SetDesaturated(0) end
			end
			pButton.icon:SetDesaturated(1)
			fCurses.activeCurse = label          -- we store here
	
			fCurses:Hide()
		end
	end
	
	-- mark active button when the menu is open
	fCurses:SetScript("OnShow", function(self)
		if self.activeCurse then
			local btn = self.getButton and self:getButton("Curse"..self.activeCurse) or nil
			if btn and btn.icon then btn.icon:SetDesaturated(1) end
		end
	end)
	-- END CURSES --

	-- STONES (Spellstone / Firestone) --
	
	local btnStones = pFrame.addButton("StonesSelect", -150, 0,
						"inv_misc_orb_05",
						MultiBot.tips.warlock.stones.master)
	
	local fStones = pFrame.addFrame("Stones", -152, 30)
	fStones:Hide()
	fStones.activeStone = nil -- nil = aucune pierre activée
	
	btnStones.doLeft = function()
		MultiBot.ShowHideSwitch(fStones)
	end
	
	-- Handles buttons
	local stoneButtons = {}
	
	local stoneList = {
		{"Spellstone", "spellstone", "inv_misc_gem_amethyst_02"},
		{"Firestone",  "firestone",  "inv_ammo_firetar"},
	}
	
	-- Helper : (dé)saturer les icônes
	local function UpdateStoneIcons(active)
		for label, b in pairs(stoneButtons) do
			if b.icon then
				-- Active  => icône colorée (SetDesaturated(false))
				-- Inactive => grisée (SetDesaturated(true))
				b.icon:SetDesaturated(label ~= active)
			end
		end
		-- Bouton principal : grisé si aucune pierre active
		if btnStones.icon then
			btnStones.icon:SetDesaturated(active == nil)
		end
	end
	
	-- Mise à jour d'état : active -> inactive ; inactive -> active
	local function ToggleStone(pButton, label, cmd)
		if fStones.activeStone == label then
			-- La pierre est déjà active on la désactive
			SendChatMessage("nc -" .. cmd, "WHISPER", nil, pButton.getName())
			fStones.activeStone = nil
		else
			-- Nouvelle activation ► on active celle-ci et désactive l'autre le cas échéant
			if fStones.activeStone then
				local oldLabel = fStones.activeStone
				local oldCmd   = (oldLabel == "Spellstone") and "spellstone" or "firestone"
				SendChatMessage("nc -" .. oldCmd, "WHISPER", nil, pButton.getName())
			end
			SendChatMessage("nc +" .. cmd, "WHISPER", nil, pButton.getName())
			fStones.activeStone = label
		end
		UpdateStoneIcons(fStones.activeStone)
		fStones:Hide()
	end
	
	-- Création des boutons Spellstone / Firestone
	for i, v in ipairs(stoneList) do
		local label, cmd, icon = unpack(v)
		local b = fStones.addButton("Stone" .. label, 0, (i - 1) * 26, icon,
									MultiBot.tips.warlock.stones[label:lower()])
		stoneButtons[label] = b
	
		-- LEFT Click => toggle (activation / désactivation)
		b.doLeft = function(pButton)
			ToggleStone(pButton, label, cmd)
		end
	
		-- RIGHT Click identique au gauche (usage facultatif)
		b.doRight = b.doLeft
	end
	
	-- État par défaut : les deux pierres sont inactives icônes grisées
	-- On vérifie quand même si une commande est déjà active (reconnexion)
	for _, v in ipairs(stoneList) do
		local label, cmd = v[1], v[2]
		if MultiBot.isInside(pNormal, cmd) then
			fStones.activeStone = label
			break
		end
	end
	UpdateStoneIcons(fStones.activeStone)
	
	-- Réactualise les icônes à chaque affichage du menu
	fStones:SetScript("OnShow", function(self)
		UpdateStoneIcons(self.activeStone)
	end)
	
	-- FIN STONES --
 
	-- SOULSTONES (Stratégies de pose) --
	
	local btnSoulstones = pFrame.addButton("SoulstonesSelect", -180, 0,
							"inv_misc_orb_04",
							MultiBot.tips.warlock.soulstones.masterbutton)
	
	local fSoul = pFrame.addFrame("Soulstones", -182, 30)
	fSoul:Hide()
	
	local ssButtons, ssActive = {}, {}
	local ssList = {
		{"Self",   "ss self",   "Spell_shadow_Shadowform"},
		{"Master", "ss master", "Achievement_WorldEvent_LittleHelper"},
		{"Tank",   "ss tank",   "ability_warrior_defensivestance"},
		{"Healer", "ss healer", "INV_Elemental_Primal_life"},
	}
	
	local function UpdateSSIcons()
		local any = false
		for label, b in pairs(ssButtons) do
			local ok = ssActive[label] == true
			if ok then any = true end
			if b.icon then b.icon:SetDesaturated(not ok) end
		end
		if btnSoulstones.icon then
			btnSoulstones.icon:SetDesaturated(not any)
		end
	end
	
	btnSoulstones.doLeft = function()  MultiBot.ShowHideSwitch(fSoul)  end
	
	local function ToggleSS(pButton, label, cmd)
		if ssActive[label] then
			SendChatMessage("nc -"..cmd, "WHISPER", nil, pButton.getName())
			ssActive[label] = false
		else
			SendChatMessage("nc +"..cmd, "WHISPER", nil, pButton.getName())
			ssActive[label] = true
		end
		UpdateSSIcons() ; fSoul:Hide()
	end
	
	for i,v in ipairs(ssList) do
		local label, cmd, icon = unpack(v)
		local b = fSoul.addButton("SS" .. label, 0, (i - 1) * 26, icon,
								MultiBot.tips.warlock.soulstones[label:lower()] or label)
	
		ssButtons[label] = b
		b.doLeft = function(pButton)  ToggleSS(pButton, label, cmd)  end
	end
	
	-- état initial (reconnexion)
	for _,v in ipairs(ssList) do
		if MultiBot.isInside(pNormal, v[2]) then ssActive[v[1]] = true end
	end
	UpdateSSIcons()
	
	fSoul:SetScript("OnShow", function()  UpdateSSIcons()  end)
	
	-- FIN SOULSTONES --

	-- PETS --
	
	-- 1) Parent button: one notch to the left of “Stones” 
	local btnPets = pFrame.addButton(
		"PetsSelect", -210, 0,
		"ability_druid_forceofnature",       -- icon
		MultiBot.tips.warlock.pets.master
	)
	
	-- 2) Drop-down subframe
	local fPets = pFrame.addFrame("Pets", -212, 30)
	fPets:Hide()
	fPets.activePet = nil          -- stores the active daemon
	btnPets.doLeft = function()  MultiBot.ShowHideSwitch(fPets)  end
	
	-- 3) Table of the five pets
	local petList = {
		{"Imp",       "imp",       "spell_shadow_summonimp"},
		{"Voidwalker","voidwalker","spell_shadow_summonvoidwalker"},
		{"Succubus",  "succubus",  "spell_shadow_summonsuccubus"},
		{"Felhunter", "felhunter", "spell_shadow_summonfelhunter"},
		{"Felguard",  "felguard",  "spell_shadow_summonfelguard"},
	}
	
	-- Handles of sub-buttons stored here
	local petButtons = {}
	
	-- Helper: updates icon desaturation
	local function UpdatePetIcons(active)
		for label, b in pairs(petButtons) do
			if b.icon then
				b.icon:SetDesaturated(label == active and 1 or 0)
			end
		end
	end

	-- 4) Creating sub-buttons
	for i, v in ipairs(petList) do
		local label, cmd, icon = unpack(v)
		local b = fPets.addButton("Pet"..label, 0, (i-1)*26, icon,
								MultiBot.tips.warlock.pets[label:lower()])
		petButtons[label] = b   -- stores the handle
	
		--  LEFT CLICK => ACTIVATE the daemon (nc +pet)
		b.doLeft = function(pButton)
			--[[DEFAULT_CHAT_FRAME:AddMessage(
				("[MB DEBUG] > %s : nc +%s"):format(pButton.getName(), cmd),
				0.9, 0.9, 0.2)]]--
	
			SendChatMessage("nc +"..cmd, "WHISPER", nil, pButton.getName())
	
			fPets.activePet = label
			UpdatePetIcons(label)
			fPets:Hide()
		end
	
		--  RIGHT CLICK  →  DISABLE the daemon (nc -pet)
		--  (Requires a modification to the PlayerBot module to function)
		
		b.doRight = function(pButton)
			--[[DEFAULT_CHAT_FRAME:AddMessage(
				("[MB DEBUG] > %s : nc -%s"):format(pButton.getName(), cmd),
				0.9, 0.5, 0.5)]]--
	
			SendChatMessage("nc -" .. cmd, "WHISPER", nil, pButton.getName())
	
			if fPets.activePet == label then
				fPets.activePet = nil
			end
			UpdatePetIcons(fPets.activePet)
			fPets:Hide()
		end
	end

	-- 5) At login: gray out the already active daemon (present in pNormal)
	for _, v in ipairs(petList) do
		local label, cmd = v[1], v[2]
		if MultiBot.isInside(pNormal, cmd) then
			fPets.activePet = label
			break
		end
	end
	UpdatePetIcons(fPets.activePet)
	
	-- 6) Each time the menu is opened: reflects the current status
	fPets:SetScript("OnShow", function(self)
		UpdatePetIcons(self.activePet)
	end)
	
	-- FIN PETS --
	
	-- STRATEGIES --
    if(MultiBot.isInside(pCombat, "dps")) then pFrame.getButton("Dps").setEnable() end
    if(MultiBot.isInside(pCombat, "dps aoe")) then pFrame.getButton("DpsAoe").setEnable() end
    if(MultiBot.isInside(pCombat, "dps debuff")) then pFrame.getButton("DpsDebuff").setEnable() end
    if(MultiBot.isInside(pCombat, "dps assist")) then pFrame.getButton("DpsAssist").setEnable() end
    if(MultiBot.isInside(pCombat, "tank assist")) then pFrame.getButton("TankAssist").setEnable() end
    if(MultiBot.isInside(pCombat, "tank")) then pFrame.getButton("Tank").setEnable() end
    if(MultiBot.isInside(pCombat, "meta melee")) then pFrame.getButton("MetaMelee").setEnable() end

end