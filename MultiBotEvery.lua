MultiBot.addEvery = function(pFrame, pCombat, pNormal)

	pFrame.addButton("Autogear", 64, 0, "inv_misc_enggizmos_30", MultiBot.tips.every.autogear)
	.doLeft = function(pButton)
		-- Un simple whisper « autogear » au bot concerné
		SendChatMessage("autogear", "WHISPER", nil, pButton.getName())
	end
	
	pFrame.addButton("Summon", 94, 0, "ability_hunter_beastcall", MultiBot.tips.every.summon)
	.doLeft = function(pButton)
		MultiBot.ActionToTarget("summon", pButton.getName())
	end
	
	pFrame.addButton("Uninvite", 124, 0, "inv_misc_grouplooking", MultiBot.tips.every.uninvite).doShow()
	.doLeft = function(pButton)
		MultiBot.doSlash("/uninvite", pButton.getName())
		pButton.getButton("Invite").doShow()
		pButton.doHide()
	end
	
	pFrame.addButton("Invite", 124, 0, "inv_misc_groupneedmore", MultiBot.tips.every.invite).doHide()
	.doLeft = function(pButton)
		MultiBot.doSlash("/invite", pButton.getName())
		pButton.getButton("Uninvite").doShow()
		pButton.doHide()
	end
	
	pFrame.addButton("Food", 154, 0, "inv_drink_24_sealwhey", MultiBot.tips.every.food).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "nc +food,?", "nc -food,?", pButton.getName())
	end
	
	pFrame.addButton("Loot", 184, 0, "inv_misc_coin_16", MultiBot.tips.every.loot).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "nc +loot,?", "nc -loot,?", pButton.getName())
	end
	
	pFrame.addButton("Gather", 214, 0, "trade_mining", MultiBot.tips.every.gather).setDisable()
	.doLeft = function(pButton)
		MultiBot.OnOffActionToTarget(pButton, "nc +gather,?", "nc -gather,?", pButton.getName())
	end
	
	-- Selfbot is not allowed to use these Tools --
	if(pFrame.getName() == UnitName("player")) then return end
	
	pFrame.addButton("Inventory", 244, 0, "inv_misc_bag_08", MultiBot.tips.every.inventory).setDisable()
	.doLeft = function(pButton)
		if(pButton.state) then
			MultiBot.inventory:Hide()
			pButton.setDisable()
		else
			local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
			for key, value in pairs(MultiBot.index.actives) do 
				if(tUnits.buttons[value].name ~= UnitName("player")) then
					tUnits.frames[value].getButton("Inventory").setDisable()
				end
			end
			
			pButton.setEnable()
			MultiBot.inventory.name = pButton.getName()
			tUnits.buttons[MultiBot.inventory.name].waitFor = "INVENTORY"
			SendChatMessage("items", "WHISPER", nil, pButton.getName())
		end
	end
	
	pFrame.addButton("Spellbook", 274, 0, "inv_misc_book_09", MultiBot.tips.every.spellbook).setDisable()
	.doLeft = function(pButton)
		if(pButton.state) then
			MultiBot.spellbook:Hide()
			pButton.setDisable()
		else
			local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
			for key, value in pairs(MultiBot.index.actives) do
				if(tUnits.buttons[value].name ~= UnitName("player")) then
					tUnits.frames[value].getButton("Spellbook").setDisable()
				end
			end
			
			pButton.setEnable()
			MultiBot.spellbook.name = pButton.getName()
			tUnits.buttons[MultiBot.spellbook.name].waitFor = "SPELLBOOK"
			SendChatMessage("spells", "WHISPER", nil, pButton.getName())
		end
	end
	
	pFrame.addButton("Talent", 304, 0, "ability_marksmanship", MultiBot.tips.every.talent).setDisable()
	.doLeft = function(pButton)
		if(pButton.state) then
			pButton.setDisable()
			MultiBot.talent:Hide()
		elseif(UnitLevel(MultiBot.toUnit(pButton.getName())) < 10) then
			SendChatMessage(MultiBot.info.talent.Level, "SAY")
		elseif(CheckInteractDistance(MultiBot.toUnit(pButton.getName()), 1) == nil) then
			SendChatMessage(MultiBot.info.talent.OutOfRange, "SAY")
		else
			MultiBot.talent:Hide()
			MultiBot.talent.doClear()
			
			local tUnits = MultiBot.frames["MultiBar"].frames["Units"]
			for key, value in pairs(MultiBot.index.actives) do
				if(tUnits.buttons[value].name ~= UnitName("player")) then
					tUnits.frames[value].getButton("Talent").setDisable()
				end
			end
			
			InspectUnit(MultiBot.toUnit(pButton.getName()))
			pButton.setEnable()
			
			MultiBot.talent.name = pButton.getName()
			MultiBot.talent.class = pButton.getClass()
			MultiBot.auto.talent = true
		end
	end
	
	-- WIPE COMMAND --
	
	local btnWipe = pFrame
	.addButton("Wipe", 334, 0, "Spell_Holy_GuardianSpirit", MultiBot.tips.every.wipe)
	.setDisable()
	btnWipe.doLeft = function(self)
	MultiBot.ActionToTarget("wipe", self:getName())
	end
	
	-- SET TALENTS --

	local btn = pFrame
	.addButton("SetTalents", 364, 0, "inv_sword_22", MultiBot.tips.every.settalent)
	btn:setEnable()
	
	btn.doLeft = function(self)
	MultiBot.spec:RequestList(self:getName(), self)
	end
	
	btn.doRight = function(self)
	MultiBot.spec:HideDropdown()
	end
	
-- STRATEGIES --
	
	if(MultiBot.isInside(pNormal, "food")) then pFrame.getButton("Food").setEnable() end
	if(MultiBot.isInside(pNormal, "loot")) then pFrame.getButton("Loot").setEnable() end
	if(MultiBot.isInside(pNormal, "gather")) then pFrame.getButton("Gather").setEnable() end
end