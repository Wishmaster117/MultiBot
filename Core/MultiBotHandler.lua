-- TIMER --

function MultiBot.HandleOnUpdate(pElapsed)
	if(MultiBot.auto.invite) then MultiBot.timer.invite.elapsed = MultiBot.timer.invite.elapsed + pElapsed end
	if(MultiBot.auto.talent) then MultiBot.timer.talent.elapsed = MultiBot.timer.talent.elapsed + pElapsed end
	if(MultiBot.auto.stats) then MultiBot.timer.stats.elapsed = MultiBot.timer.stats.elapsed + pElapsed end
	if(MultiBot.auto.sort) then MultiBot.timer.sort.elapsed = MultiBot.timer.sort.elapsed + pElapsed end

	if(MultiBot.auto.stats and MultiBot.timer.stats.elapsed >= MultiBot.timer.stats.interval) then
		for i = 1, GetNumPartyMembers() do SendChatMessage("stats", "WHISPER", nil, UnitName("party" .. i)) end
		MultiBot.timer.stats.elapsed = 0
	end

	if(MultiBot.auto.talent and MultiBot.timer.talent.elapsed >= MultiBot.timer.talent.interval) then
		MultiBot.talent.setTalents()
		MultiBot.timer.talent.elapsed = 0
		MultiBot.auto.talent = false
	end

	if(MultiBot.auto.invite and MultiBot.timer.invite.elapsed >= MultiBot.timer.invite.interval) then
		local tTable = MultiBot.index[MultiBot.timer.invite.roster]

		if(MultiBot.timer.invite.needs == 0 or MultiBot.timer.invite.index > #tTable) then
			if(MultiBot.timer.invite.roster == "raidus") then
				MultiBot.timer.sort.elapsed = 0
				MultiBot.timer.sort.index = 1
				MultiBot.timer.sort.needs = 0
				MultiBot.auto.sort = true
			end

			MultiBot.timer.invite.elapsed = 0
			MultiBot.timer.invite.roster = ""
			MultiBot.timer.invite.index = 1
			MultiBot.timer.invite.needs = 0
			MultiBot.auto.invite = false
			return
		end

		if(MultiBot.isMember(tTable[MultiBot.timer.invite.index]) == false) then
			SendChatMessage(MultiBot.doReplace(MultiBot.info.inviting, "NAME", tTable[MultiBot.timer.invite.index]), "SAY")
			SendChatMessage(".playerbot bot add " .. tTable[MultiBot.timer.invite.index], "SAY")
			MultiBot.timer.invite.needs = MultiBot.timer.invite.needs - 1
		end

		MultiBot.timer.invite.index = MultiBot.timer.invite.index + 1
		MultiBot.timer.invite.elapsed = 0
	end

	if(MultiBot.auto.sort and MultiBot.timer.sort.elapsed >= MultiBot.timer.sort.interval) then
		MultiBot.timer.sort.index = MultiBot.raidus.doRaidSort(MultiBot.timer.sort.index)

		if(MultiBot.timer.sort.index == nil) then
			MultiBot.timer.sort.index = MultiBot.raidus.doRaidSortCheck()
		end

		if(MultiBot.timer.sort.index == nil) then
			SendChatMessage("Ready for Raid now.", "SAY")
			MultiBot.timer.sort.elapsed = 0
			MultiBot.timer.sort.index = 1
			MultiBot.timer.sort.needs = 0
			MultiBot.auto.sort = false
			return
		end

		MultiBot.timer.sort.elapsed = 0
	end
end

MultiBot:SetScript("OnUpdate", function(_, pElapsed)
	MultiBot.DispatchUpdate(pElapsed)
 end)

-- HANDLER --

local POINT_FRAME_BINDINGS = {
	{ saveKey = "MultiBarPoint", getFrame = function() return MultiBot.frames and MultiBot.frames["MultiBar"] end },
	{ saveKey = "InventoryPoint", getFrame = function() return MultiBot.inventory end },
	{ saveKey = "SpellbookPoint", getFrame = function() return MultiBot.spellbook end },
	{ saveKey = "ItemusPoint", getFrame = function() return MultiBot.itemus end },
	{ saveKey = "IconosPoint", getFrame = function() return MultiBot.iconos end },
	{ saveKey = "StatsPoint", getFrame = function() return MultiBot.stats end },
	{ saveKey = "RewardPoint", getFrame = function() return MultiBot.reward end },
	{ saveKey = "TalentPoint", getFrame = function() return MultiBot.talent end },
}

local PORTAL_MEMORY_BINDINGS = {
	{ saveKey = "MemoryGem1", color = "Red" },
	{ saveKey = "MemoryGem2", color = "Green" },
	{ saveKey = "MemoryGem3", color = "Blue" },
}

local function getPortalButton(color)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local masters = multiBar and multiBar.frames and multiBar.frames["Masters"]
	local portal = masters and masters.frames and masters.frames["Portal"]
	return portal and portal.buttons and portal.buttons[color]
end

local function saveBoundFramePoints()
	for _, binding in ipairs(POINT_FRAME_BINDINGS) do
		local frame = binding.getFrame and binding.getFrame()
		if frame then
			local tX, tY = MultiBot.toPoint(frame)
			MultiBotSave[binding.saveKey] = tX .. ", " .. tY
		end
	end
end

local function restoreBoundFramePoints()
	for _, binding in ipairs(POINT_FRAME_BINDINGS) do
		local pointValue = MultiBotSave[binding.saveKey]
		local frame = binding.getFrame and binding.getFrame()
		if pointValue ~= nil and frame and frame.setPoint then
			local tPoint = MultiBot.doSplit(pointValue, ", ")
			frame.setPoint(tonumber(tPoint[1]), tonumber(tPoint[2]))
		end
	end
end

local function savePortalMemory()
	for _, binding in ipairs(PORTAL_MEMORY_BINDINGS) do
		local portalButton = getPortalButton(binding.color)
		if portalButton then
			MultiBotSave[binding.saveKey] = MultiBot.SavePortal(portalButton)
		end
	end
end

local function restorePortalMemory()
	for _, binding in ipairs(PORTAL_MEMORY_BINDINGS) do
		local memory = MultiBotSave[binding.saveKey]
		if memory ~= nil then
			local portalButton = getPortalButton(binding.color)
			if portalButton then
				MultiBot.LoadPortal(portalButton, memory)
			end
		end
	end
end

local ATTACK_BUTTON_BINDINGS = {
	attack = "Attack",
	attack_ranged = "Ranged",
	attack_melee = "Melee",
	attack_healer = "Healer",
	attack_dps = "Dps",
	attack_tank = "Tank",
}

local FLEE_BUTTON_BINDINGS = {
	flee = "Flee",
	flee_ranged = "Ranged",
	flee_melee = "Melee",
	flee_healer = "Healer",
	flee_dps = "Dps",
	flee_tank = "Tank",
	flee_target = "Target",
}

local function getMultiBarButton(sectionName, frameName, buttonName)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local section = multiBar and multiBar.frames and multiBar.frames[sectionName]
	local frame = section and section.frames and section.frames[frameName]
	return frame and frame.buttons and frame.buttons[buttonName]
end

local function getMainBarButton(buttonName)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local main = multiBar and multiBar.frames and multiBar.frames["Main"]
	return main and main.buttons and main.buttons[buttonName]
end

local function getMastersBarButton(buttonName)
	local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
	local masters = multiBar and multiBar.frames and multiBar.frames["Masters"]
	return masters and masters.buttons and masters.buttons[buttonName]
end

local function restoreRightClickMode(saveKey, frameName, buttonBindings)
	local savedMode = MultiBotSave[saveKey]
	if savedMode == nil then return end

	local buttonName = buttonBindings[savedMode]
	if not buttonName then return end

	local button = getMultiBarButton("Left", frameName, buttonName)
	if button and button.doRight then
		button.doRight(button)
	end
end

local function restoreBinaryLeftToggle(saveKey, getButton)
	local savedState = MultiBotSave[saveKey]
	if savedState == nil then return end

	local button = getButton()
	if not button then return end

	if savedState == "true" then
		if button.setDisable then button.setDisable() end
	else
		if button.setEnable then button.setEnable() end
	end

	if button.doLeft then
		button.doLeft(button)
	end
end

local function restoreEnableOnlyLeftToggle(saveKey, getButton, onEnabled)
	if MultiBotSave[saveKey] ~= "true" then return end

	local button = getButton()
	if not button then return end

	if onEnabled then
		onEnabled(button)
	end

	if button.setDisable then
		button.setDisable()
	end

	if button.doLeft then
		button.doLeft(button)
	end
end

local function restoreMainBarSavedStates()
	restoreRightClickMode("AttackButton", "Attack", ATTACK_BUTTON_BINDINGS)
	restoreRightClickMode("FleeButton", "Flee", FLEE_BUTTON_BINDINGS)

	restoreBinaryLeftToggle("AutoRelease", function()
		return getMainBarButton("Release")
	end)
	restoreBinaryLeftToggle("NecroNet", function()
		return getMastersBarButton("NecroNet")
	end)
	restoreBinaryLeftToggle("Reward", function()
		return getMainBarButton("Reward")
	end)

	restoreEnableOnlyLeftToggle("Masters", function()
		return getMainBarButton("Masters")
	end, function()
		MultiBot.GM = true
	end)
	restoreEnableOnlyLeftToggle("Creator", function()
		return getMainBarButton("Creator")
	end)
	restoreEnableOnlyLeftToggle("Beast", function()
		return getMainBarButton("Beast")
	end)
	restoreEnableOnlyLeftToggle("Expand", function()
		return getMainBarButton("Expand")
	end)
	restoreEnableOnlyLeftToggle("RTSC", function()
		return getMainBarButton("RTSC")
	end, function()
		if MultiBot.frames and MultiBot.frames["MultiBar"] then
			MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y - 34)
		end
	end)
end

function MultiBot.HandleMultiBotEvent(event, ...)
	local arg1, arg2 = ...
	if(event == "PLAYER_LOGOUT") then
		saveBoundFramePoints()
		savePortalMemory()

		local tValue = MultiBot.doSplit(MultiBot.frames["MultiBar"].frames["Left"].buttons["Attack"].texture, "\\")[5]
		tValue = string.sub(tValue, 1, string.len(tValue) - 4)
		MultiBotSave["AttackButton"] = tValue

		tValue = MultiBot.doSplit(MultiBot.frames["MultiBar"].frames["Left"].buttons["Flee"].texture, "\\")[5]
		tValue = string.sub(tValue, 1, string.len(tValue) - 4)
		MultiBotSave["FleeButton"] = tValue

		MultiBotSave["AutoRelease"] = MultiBot.IF(MultiBot.auto.release, "true", "false")
		MultiBotSave["NecroNet"] = MultiBot.IF(MultiBot.necronet.state, "true", "false")
		MultiBotSave["Reward"] = MultiBot.IF(MultiBot.reward.state, "true", "false")

		MultiBotSave["Masters"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Masters"].state, "true", "false")
		MultiBotSave["Creator"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Creator"].state, "true", "false")
		MultiBotSave["Beast"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Beast"].state, "true", "false")
		MultiBotSave["Expand"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["Expand"].state, "true", "false")
		MultiBotSave["RTSC"] = MultiBot.IF(MultiBot.frames["MultiBar"].frames["Main"].buttons["RTSC"].state, "true", "false")

		return
	end

	-- ADDON:LOADED --

    if(event == "ADDON_LOADED" and arg1 == "MultiBot") then

		restoreBoundFramePoints()

	        -- Restore MultiBot bar visibility from saved state (default visible).
	        if MultiBot.ToggleMainUIVisibility then
	          MultiBot.ToggleMainUIVisibility(MultiBotSave["UIVisible"] ~= false)
	        end

		restorePortalMemory()

		restoreMainBarSavedStates()

        if MultiBotGlobalSave and MultiBotGlobalSave["Strata.Level"] ~= nil then
          if MultiBot.ApplyGlobalStrata then
            MultiBot.ApplyGlobalStrata()
          else
            -- minimal fallback if the function does not exist
            if MultiBot.frames and MultiBot.frames["MultiBar"] then
              MultiBot.PromoteFrame(MultiBot.frames["MultiBar"], MultiBotGlobalSave["Strata.Level"])
            end
          end
        end

		return
	end

	-- PLAYER:ENTERING --

    if(event == "PLAYER_ENTERING_WORLD") then
	MultiBot.dprint("EVT", "PLAYER_ENTERING_WORLD") -- DEBUG
        SendChatMessage(".account", "SAY")
        if(MultiBot.init == nil) then
            MultiBot.init = true
            if type(TimerAfter) == "function" then
                TimerAfter(0.5, function()
					MultiBot.dprint("SEND", ".playerbot bot list"); SendChatMessage(".playerbot bot list", "SAY")--Debug
                end)
            else
                SendChatMessage(".playerbot bot list", "SAY")
            end
            return
        end
        return
    end

	-- CHAT:SYSTEM --
	if(event == "CHAT_MSG_SYSTEM") then
	MultiBot.dprint("SYS", arg1) -- DEBUG

		-- Détection générique du niveau de compte (toutes langues prises en charge via patrons)
        do
          local msg = arg1
          if MultiBot.GM_DetectFromSystem and type(msg) == "string" then
            MultiBot.GM_DetectFromSystem(msg)
          end
        end

		if(MultiBot.isInside(arg1, "Possible strategies")) then
			local tStrategies = MultiBot.doSplit(arg1, ", ")
			SendChatMessage("=== STRATEGIES ===", "SAY")
			for i = 1, #tStrategies do SendChatMessage(i .. " : " .. tStrategies[i], "SAY") end
			return
		end

		if(MultiBot.isInside(arg1, "Whisper any of")) then
			local tCommands = MultiBot.doSplit(arg1, ", ")
			SendChatMessage("=== WHISPER-COMMANDS ===", "SAY")
			for i = 1, #tCommands do SendChatMessage(i .. " : " .. tCommands[i], "SAY") end
			return
		end

		if(MultiBot.auto.release == true) then
			if(MultiBot.isInside(arg1, "已经死亡")) then
				SendChatMessage("release", "WHISPER", nil, MultiBot.doReplace(arg1, "已经死亡。", ""))
				return
			end

			if(MultiBot.isInside(arg1, "ist tot", "has dies", "has died")) then
				SendChatMessage("release", "WHISPER", nil, MultiBot.doSplit(arg1, " ")[1])
				return
			end
		end

        -- Anti-dup: ignore the same "Bot roster:" line repeated in a short window
        do
          local text = (type(arg1) == "string") and arg1 or ""
          local roster = text:match("^%s*[Bb]ot%W+[Rr]oster:%s*(.+)$")
          if roster then
            MultiBot._lastRosterMsg = MultiBot._lastRosterMsg or { txt = nil, t = 0 }
            local now = (type(GetTime) == "function") and GetTime() or 0
            if MultiBot._lastRosterMsg.txt == roster and (now - MultiBot._lastRosterMsg.t) < 1.0 then
              return
            end
            MultiBot._lastRosterMsg.txt = roster
            MultiBot._lastRosterMsg.t   = now
          end
        end

		if(string.sub(arg1, 1, 12) == "Bot roster: ") then
			MultiBot.dprint("SYS", "Bot roster received") -- DEBUG
			MultiBot.dprint("UIready",
              (MultiBot.frames and MultiBot.frames["MultiBar"] and MultiBot.frames["MultiBar"].frames and MultiBot.frames["MultiBar"].frames["Units"]) and true or false) -- DEBUG
            -- ------------------------------------------------------------
            -- SECURITY : wait to MultiBar construction
            -- ------------------------------------------------------------
            if not (MultiBot.frames and MultiBot.frames["MultiBar"]
                    and MultiBot.frames["MultiBar"].frames
                    and MultiBot.frames["MultiBar"].frames["Units"]) then
                -- UI pas encore prête : on re-propulse le même event vers NOTRE OnEvent
                local saved_msg = arg1

                local function ReDispatchRoster()
                    local onEvent = MultiBot:GetScript("OnEvent")
                    if onEvent then
                        -- Sauvegarde/restaure les globals d’événement
                        local _event, _arg1 = event, arg1
                        event, arg1 = "CHAT_MSG_SYSTEM", saved_msg
                        onEvent()
                        event, arg1 = _event, _arg1
                    end
                end

                if type(TimerAfter) == "function" then
                    TimerAfter(0.2, ReDispatchRoster)
                else
                    local df = CreateFrame("Frame")
                    df.t = 0
                    df:SetScript("OnUpdate", function(self, elapsed)
                        self.t = self.t + elapsed
                        if self.t > 0.2 then
                            self:SetScript("OnUpdate", nil)
                            ReDispatchRoster()
                        end
                    end)
                end
                return
            end

			local _, tClass, _, _, _, tName = GetPlayerInfoByGUID(UnitGUID("player"))
			tClass = MultiBot.toClass(tClass)

			local tPlayer = MultiBot.addSelf(tClass, tName).setDisable()
			tPlayer.class = tClass
			tPlayer.name = tName

			tPlayer.doLeft = function(pButton)
				SendChatMessage(".playerbot bot self", "SAY")
				MultiBot.OnOffSwitch(pButton)
			end

			-- On reste sur le format historique : "Bot roster: +Name Class, -Name Class, ..."
			local tTable = MultiBot.doSplit(string.sub(arg1, 13), ", ")
			MultiBot.dprint("ROSTER_PARSE_COUNT", #tTable) -- DEBUG

			for key, value in pairs(tTable) do
				if value == "" then break end

				local tBot = MultiBot.doSplit(value, " ")
				local rawNameToken  = tBot[1]
				local rawClassToken = tBot[2]

				if rawNameToken and rawClassToken then
					local botName  = string.sub(rawNameToken, 2) -- enlève le signe +/-
					local botClass = MultiBot.toClass(rawClassToken)

					-- Filtre de sécurité :
					--  - pas de nom vide
					--  - pas de classe inconnue => on évite les boutons Unknown
					if botName ~= "" and botClass and botClass ~= "Unknown" then
						local botButton = MultiBot.addPlayer(botClass, botName).setDisable()

						botButton.doRight = function(pButton)
							if pButton.state == false then return end
							SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
							if pButton.parent.frames[pButton.name] ~= nil then
								pButton.parent.frames[pButton.name]:Hide()
							end
							pButton.setDisable()
						end

						botButton.doLeft = function(pButton)
							if pButton.state then
								if pButton.parent.frames[pButton.name] ~= nil then
									MultiBot.ShowHideSwitch(pButton.parent.frames[pButton.name])
								end
							else
								SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
								pButton.setEnable()
							end
						end
					else
						MultiBot.dprint("ROSTER_SKIP_BAD_ENTRY",
							tostring(value),
							"name=", botName or "<nil>",
							"class=", rawClassToken or "<nil>",
							"canon=", botClass or "<nil>")
					end
				else
					MultiBot.dprint("ROSTER_SKIP_MALFORMED", tostring(value))
				end
			end

			MultiBot.dprint("INDEX_PLAYERS_SIZE", #(MultiBot.index.players or {})) -- DEBUG
			do local n=0; for _ in pairs(MultiBot.index.classes.players or {}) do n=n+1 end; MultiBot.dprint("INDEX_CLASSES_PLAYERS_KEYS", n) end -- DEBUG

        -- La liste des players est prête : on met l’index Favoris à jour
        if MultiBot.UpdateFavoritesIndex then MultiBot.UpdateFavoritesIndex() end

        -- UI REFRESH (INCONDITIONNEL) :
        -- Rafraîchit la vue en réutilisant le roster courant (players/favorites/actives/…)
        -- pour ne pas écraser le choix de l’utilisateur.
        do
          local unitsBtn = MultiBot.frames
                          and MultiBot.frames["MultiBar"]
                          and MultiBot.frames["MultiBar"].buttons
                          and MultiBot.frames["MultiBar"].buttons["Units"]
          if unitsBtn and unitsBtn.doLeft then
            local roster = unitsBtn.roster or "players"
            unitsBtn.doLeft(unitsBtn, roster, unitsBtn.filter)
          end
        end
        -- Retry différé : couvre le cas où l’UI n’est pas encore prête (timing au login)
        if type(TimerAfter) == "function" then
          TimerAfter(0.05, function()
            local unitsBtn = MultiBot.frames
                            and MultiBot.frames["MultiBar"]
                            and MultiBot.frames["MultiBar"].buttons
                            and MultiBot.frames["MultiBar"].buttons["Units"]
            if unitsBtn and unitsBtn.doLeft then
              local roster = unitsBtn.roster or "players"
              unitsBtn.doLeft(unitsBtn, roster, unitsBtn.filter)
            end
          end)
        end

			-- MEMBERBOTS --
			local tGuildCount = 0
			if type(GetNumGuildMembers) == "function" then
				tGuildCount = select(1, GetNumGuildMembers()) or 0
			end
			local memberLoopMax = (tGuildCount > 0) and tGuildCount or 50

			for i = 1, memberLoopMax do
				local memberName, _, _, memberLevel, memberClass = GetGuildRosterInfo(i)

				-- Ensure that the Counter is not bigger than the Amount of Members in Guildlist
				if(memberName ~= nil and memberLevel ~= nil and memberClass ~= nil and memberName ~= UnitName("player")) then
					local tMember = MultiBot.addMember(memberClass, memberLevel, memberName).setDisable()

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
			local tFriendCount = 0
			if type(GetNumFriends) == "function" then
				tFriendCount = GetNumFriends() or 0
			end
			local friendLoopMax = (tFriendCount > 0) and tFriendCount or 50

			for i = 1, friendLoopMax do
				local friendName, friendLevel, friendClass = GetFriendInfo(i)

				-- Ensure that the Counter is not bigger than the Amount of Members in Friendlist
				if(friendName ~= nil and friendLevel ~= nil and friendClass ~= nil and friendName ~= UnitName("player")) then
					local tFriend = MultiBot.addFriend(friendClass, friendLevel, friendName).setDisable()

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

			-- REFRESH:RAID --

			if(GetNumRaidMembers() > 4) then
				for i = 1, GetNumRaidMembers() do
					--local tName = UnitName("raid" .. i)
					--SendChatMessage(".playerbot bot add " .. tName, "SAY")
					local raidName = UnitName("raid" .. i)
					SendChatMessage(".playerbot bot add " .. raidName, "SAY")
				end

				return
			end

			-- REFRESH:GROUP --

			if(GetNumPartyMembers() > 0) then
				for i = 1, GetNumPartyMembers() do
					local partyName = UnitName("party" .. i)
					SendChatMessage(".playerbot bot add " .. partyName, "SAY")
				end

				return
			end

			return
		end

		if(MultiBot.isInside(arg1, "player already logged in")) then
			local tName = string.sub(arg1, 6, string.find(arg1, " ", 6) - 1)
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end

            if(MultiBot.isMember(tName)) then
               -- On ne redemande plus les stratégies ici pour éviter les doublons.
               -- Le flux normal via le WHISPER "Hello" s'en chargera.
               tButton.waitFor = "CO"
               tButton.setEnable()
               return
            end

			if(GetNumPartyMembers() == 4) then ConvertToRaid() end
			MultiBot.doSlash("/invite", tName)
			return
		end

		if(MultiBot.isInside(arg1, "remove: ")) then
			local tName = string.sub(arg1, 9, string.find(arg1, " ", 9) - 1)
			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].frames[tName]
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end

			if(MultiBot.isInside(arg1, "not your bot")) then
				SendChatMessage("leave", "WHISPER", nil, tName)
			end

			MultiBot.doRemove(MultiBot.index.classes.actives[tButton.class], tButton.name)
			MultiBot.doRemove(MultiBot.index.actives, tButton.name)

			if(tFrame ~= nil) then tFrame:Hide() end
			tButton.setDisable()
			return
		end

		if(arg1 == "Enable player botAI") then
			local tName = UnitName("player")
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			tButton.waitFor = "CO"
			SendChatMessage("co ?", "WHISPER", nil, tName)
			tButton.setEnable()
			return
		end

		if(arg1 == "Disable player botAI") then
			local tName = UnitName("player")
			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].frames[tName]
			local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			if(tButton == nil) then return end
			if(tFrame ~= nil) then tFrame:Hide() end
			tButton.setDisable()
			return
		end

		if(MultiBot.isInside(arg1, "Zone:", "zone:")) then
			local tPlayer = MultiBot.getBot(UnitName("player"))
			if(tPlayer.waitFor ~= "COORDS") then return end

			local tLocation = MultiBot.doSplit(arg1, " ")
			local tZone = string.sub(tLocation[6], 2, string.len(tLocation[6]) - 1)
			local tMap = string.sub(tLocation[3], 2, string.len(tLocation[3]) - 1)
			local tTip = MultiBot.doReplace(MultiBot.doReplace(MultiBot.info.teleport, "MAP", tMap), "ZONE", tZone)

			tPlayer.memory.goMap = tLocation[2]
			tPlayer.memory.tip = MultiBot.doReplace(MultiBot.tips.game.memory, "ABOUT", tTip)
			return
		end

		if(MultiBot.isInside(arg1, "X:") and MultiBot.isInside(arg1, "Y:")) then
			local tPlayer = MultiBot.getBot(UnitName("player"))
			if(tPlayer.waitFor ~= "COORDS") then return end

			local tCoords = MultiBot.doSplit(arg1, " ")
			tPlayer.memory.goX = tCoords[2]
			tPlayer.memory.goY = tCoords[4]
			tPlayer.memory.goZ = tCoords[6]
			tPlayer.memory.setEnable()
			tPlayer.waitFor = ""
			return
		end
	end

    -- ADDED FOR QUESTS --
	-- INITI TABLES & FLAGS
	MultiBot.BotQuestsIncompleted        = MultiBot.BotQuestsIncompleted        or {}
	MultiBot.BotQuestsCompleted          = MultiBot.BotQuestsCompleted          or {}
	MultiBot.BotQuestsAll                = MultiBot.BotQuestsAll                or {}
	MultiBot._awaitingQuestsIncompleted  = MultiBot._awaitingQuestsIncompleted  or {}
	MultiBot._awaitingQuestsCompleted    = MultiBot._awaitingQuestsCompleted    or {}
	MultiBot.LastGameObjectSearch        = MultiBot.LastGameObjectSearch        or {}
	MultiBot._GameObjCaptureInProgress   = MultiBot._GameObjCaptureInProgress   or {}
	MultiBot._questAllBuffer             = MultiBot._questAllBuffer             or {}

	local function FillQuestTable(tbl, author, msg)
		MultiBot[tbl] = MultiBot[tbl] or {}
		MultiBot[tbl][author] = MultiBot[tbl][author] or {}
		for link in msg:gmatch("|Hquest:[^|]+|h%[[^%]]+%]|h") do
			local id   = tonumber(link:match("|Hquest:(%d+):"))
			local name = link:match("%[([^%]]+)%]")
			if id and name then
				MultiBot[tbl][author][id] = name
			end
		end
	end

	-- Function read whisps for Incomp and comp quests
	local function HandleQuestResponse(rawMsg, author)

		if MultiBot._awaitingQuestsAll or MultiBot._blockOtherQuests then
			print("SKIP HandleQuestResponse (awaitingQuestsAll)")
			return
		end

		-- GUARD : if message are not for quests we skip
		local hasKeyword = rawMsg:find("quest") or rawMsg:find("Summary")
		local awaiting   = MultiBot._awaitingQuestsIncompleted[author]
					or MultiBot._awaitingQuestsCompleted[author]
		if not hasKeyword and not awaiting then
			return
		end

		-- Incomp Quests
		if rawMsg:find("Incompleted quests") then
			MultiBot.BotQuestsIncompleted[author]       = {}  -- reset pour ce bot
			MultiBot._awaitingQuestsIncompleted[author] = true
			return
		end

		-- COLLECT Incompleted
		if MultiBot._awaitingQuestsIncompleted[author] then
			FillQuestTable("BotQuestsIncompleted", author, rawMsg)
			if rawMsg:find("Summary") then
				MultiBot._awaitingQuestsIncompleted[author] = nil

				if MultiBot.tBotPopup and not MultiBot.tBotPopup:IsShown() then
					MultiBot.tBotPopup:Show()
				end
				MultiBot.TimerAfter(0.1, function()
					if MultiBot._lastIncMode == "GROUP" then
						MultiBot.BuildAggregatedQuestList()
					else
						MultiBot.BuildBotQuestList(author)
					end
				end)
			end
			return
		end

		-- Comp Quests
		if rawMsg:find("Completed quests") then
			MultiBot.BotQuestsCompleted[author]       = {}  -- reset pour ce bot
			MultiBot._awaitingQuestsCompleted[author] = true
			return
		end

		-- COLLECT Completed
		if MultiBot._awaitingQuestsCompleted[author] then
			FillQuestTable("BotQuestsCompleted", author, rawMsg)
			if rawMsg:find("Summary") then
				MultiBot._awaitingQuestsCompleted[author] = nil

				if MultiBot.tBotCompPopup and not MultiBot.tBotCompPopup:IsShown() then
					MultiBot.tBotCompPopup:Show()
				end
				MultiBot.TimerAfter(0.1, function()
					if MultiBot._lastCompMode == "GROUP" then
						MultiBot.BuildAggregatedCompletedList()
					else
						MultiBot.BuildBotCompletedList(author)
					end
				end)
			end
			return
		end
	end

	-- Function for QuestsAll
	function HandleQuestsAllResponse(rawMsg, author)
		MultiBot._questAllBuffer[author] = MultiBot._questAllBuffer[author] or {}
		table.insert(MultiBot._questAllBuffer[author], rawMsg)

		if rawMsg:find("Summary") then
			-- Concatène toutes les lignes reçues
			local allLines = table.concat(MultiBot._questAllBuffer[author], "\n")
			-- print("==== PARSE DU BUFFER POUR", author)
			-- print(allLines)

			MultiBot.BotQuestsAll[author] = {}
			MultiBot.BotQuestsCompleted[author] = {}
			MultiBot.BotQuestsIncompleted[author] = {}

			local mode = nil
			for line in allLines:gmatch("[^\n]+") do
				-- print("Line:", line)
				if line:find("Incompleted quests") then
					mode = "incomplete"
					-- print(">> MODE incompleted <<")
				elseif line:find("Completed quests") then
					mode = "complete"
					-- print(">> MODE completed <<")
				elseif line:find("Summary") then
					-- print(">> MODE nil (summary reached)")
					mode = nil
				else
					local id = tonumber(line:match("|Hquest:(%d+):"))
					local name = line:match("%[([^%]]+)%]")
					-- print("Parsing quest line: id=", id, " name=", name, " mode=", mode)
					if id and name then
						table.insert(MultiBot.BotQuestsAll[author], line)
						if mode == "incomplete" then
							-- print("Insert in BotQuestsIncompleted:", author, id, name)
							MultiBot.BotQuestsIncompleted[author][id] = name
						elseif mode == "complete" then
							-- print("Insert in BotQuestsCompleted:", author, id, name)
							MultiBot.BotQuestsCompleted[author][id] = name
						end
					end
				end
			end

			-- On marque comme répondu
			if MultiBot._awaitingQuestsAllBots then
				MultiBot._awaitingQuestsAllBots[author] = true
			end

			-- Vide le buffer
			MultiBot._questAllBuffer[author] = nil

			-- Vérifie si tous les bots ont répondu
			local allOk = true
			for name, ok in pairs(MultiBot._awaitingQuestsAllBots or {}) do
				-- print("Waiting bots:", name, ok)
				if not ok then allOk = false break end
			end

			if allOk then
				-- print("Tous les bots ont répondu, on affiche la popup triée !")
				MultiBot._awaitingQuestsAll = false
				MultiBot._blockOtherQuests = false
				MultiBot._awaitingQuestsAllBots = nil
				if MultiBot.tBotAllPopup and MultiBot.BuildAggregatedAllList then
					MultiBot.tBotAllPopup:Show()
					MultiBot.BuildAggregatedAllList()
				end
			else
				print("Still not finished...")
			end
		end
	end
    -- END ADD FOR QUESTS --

	-- GOB CAPTURE --
	function MultiBot.HandleGameObjectWhisper(rawMsg, author) -- Fonction to read GOB in chat
		local header = "--- Game objects ---"
		if rawMsg:find(header, 1, true) then -- Capture Detection
			MultiBot.LastGameObjectSearch[author] = {}
			MultiBot._GameObjCaptureInProgress[author] = true
			return true
		end

		if MultiBot._GameObjCaptureInProgress[author] then -- check if still in capture mod
			if rawMsg:find("^%s*-+%s*[%w%s]+%-+$") or rawMsg == "" then
				MultiBot._GameObjCaptureInProgress[author] = nil
				MultiBot.ShowGameObjectPopup()
				return true
			end
			table.insert(MultiBot.LastGameObjectSearch[author], rawMsg)
			return true
		end

		return false
	end
	-- FIN GOB CAPTURE

	-- CHAT:WHISPER --
	if(event == "CHAT_MSG_WHISPER") then

		-- Glyphs start
		local rawMsg, author = arg1, arg2

		if MultiBot._awaitingQuestsAll then -- QuestsAll
			HandleQuestsAllResponse(rawMsg, author)
			return
		end

		HandleQuestResponse(rawMsg, author) -- Incomp and Comp Quests

		if MultiBot.HandleGameObjectWhisper(rawMsg, author) then -- Use GOB
			return
		end

		if MultiBot.awaitGlyphs and author == MultiBot.awaitGlyphs then
			-- On ne traite que les réponses commençant par "Glyphs:" ou "No glyphs"
			if not rawMsg:match("^[Gg]lyphs:") and not rawMsg:match("^[Nn]o glyphs") then
				DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[ERROR]|r Ignored non-glyphs msg")
				return
			end

			-- On extrait tout ce qui suit "Glyphs:"
			local rest = rawMsg:match("^[Gg]lyphs:%s*(.*)") or ""
			local ids = {}

			if rest:lower():match("^no glyphs") then
				-- pas de glyphe → on met 6 zéros
				for i = 1, 6 do ids[i] = 0 end
			else
				-- on récupère directement chaque ID depuis les liens cliquables
				for id in rest:gmatch("|Hitem:(%d+):") do
					table.insert(ids, tonumber(id))
				end
				-- on complète si moins de 6
				for i = #ids + 1, 6 do
					ids[i] = 0
				end
			end

			-- On stocke cette liste pour le rafraîchissement
			MultiBot.receivedGlyphs = MultiBot.receivedGlyphs or {}
			MultiBot.receivedGlyphs[author] = {}

			-- Détermination du type Major/Minor et remplissage
			local unit = MultiBot.toUnit(author)
			local _, cf = UnitClass(unit or "player")
			local classKey = (cf == "DEATHKNIGHT")
							and "DeathKnight"
							or cf:sub(1,1)..cf:sub(2):lower()
			local glyphDB = MultiBot.data.talent.glyphs[classKey] or {}

			-- Mappage des sockets
			local map = { 1, 2, 5, 6, 4, 3 }
			for idx, id in ipairs(ids) do
				local sock = map[idx]                    -- n° de socket cible
				local typ  = (glyphDB.Major and glyphDB.Major[id]) and "Major" or "Minor"
				MultiBot.receivedGlyphs[author][sock] = { id = id, type = typ }
			end

			-- Si l'onglet Glyphes est ouvert, on force son rafraîchissement
			local tab4 = MultiBot.talent.frames["Tab4"]
			if tab4 and tab4:IsShown() then
				--[[DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[DBG]|r Refresh FillDefaultGlyphs")]]--
				MultiBot.FillDefaultGlyphs()
			end

			MultiBot.awaitGlyphs = nil
			return
		end
		-- END GLYPHES --

		if(MultiBot.auto.release == true) then
			-- Graveyard not ready to talk Bot in the chinese Version --
			if(arg1 == "在墓地见我") then
				MultiBot.frames["MultiBar"].frames["Units"].buttons[arg2].waitFor = "你好"
				return
			end

			if(arg1 == "Meet me at the graveyard") then
				SendChatMessage("summon", "WHISPER", nil, arg2)
				return
			end
		end

		if(MultiBot.isInside(arg1, "StatsOfPlayer")) then
			local tUnit = MultiBot.toUnit(arg2)
			MultiBot.stats.frames[tUnit].setStats(arg2, UnitLevel(tUnit), arg1, true)
		end

		if(arg1 == "stats" and arg2 ~= UnitName("player")) then
			local tXP = math.floor(100.0 / UnitXPMax("player") * UnitXP("player"))
			local tMana = math.floor(100.0 / UnitManaMax("player") * UnitMana("player"))
			SendChatMessage("StatsOfPlayer " .. tXP .. " " .. tMana, "WHISPER", nil, arg2)
		end

		-- REQUIREMENT --

		local tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[arg2]

		if(MultiBot.auto.release == true) then
			-- Graveyard ready to talk Bot in the chinese Version --
			if(tButton ~= nil and tButton.waitFor == "你好" and arg1 == "你好") then
				SendChatMessage("summon", "WHISPER", nil, arg2)
				tButton.waitFor = ""
				return
			end
		end

		if(MultiBot.isInside(arg1, "Hello", "你好") and tButton == nil) then
            local tUnit = MultiBot.toUnit(arg2)
            if not (tUnit and UnitExists(tUnit)) then
               -- Bot is still not in party/raid we stop
               return
            end

            local _, tClass = UnitClass(tUnit)
            local tLevel    = UnitLevel(tUnit)

			tButton = MultiBot.addActive(tClass, tLevel, arg2).setDisable()

			tButton.doRight = function(pButton)
				SendChatMessage(".playerbot bot remove " .. pButton.name, "SAY")
				if(pButton.parent.frames[pButton.name] ~= nil) then pButton.parent.frames[pButton.name]:Hide() end
				pButton.setDisable()
			end

			tButton.doLeft = function(pButton)
				if(pButton.state) then
					if(pButton.parent.frames[pButton.name] ~= nil) then MultiBot.ShowHideSwitch(pButton.parent.frames[pButton.name]) end
				else
					SendChatMessage(".playerbot bot add " .. pButton.name, "SAY")
					pButton.setEnable()
				end
			end
		elseif(tButton == nil) then return end

		if(MultiBot.isInside(arg1, "Hello", "你好") and tButton.class == "Unknown" and tButton.roster == "friends") then
			local tName = ""
			local tLevel = ""
			local tClass = ""

			--for i = 1, 50 do
			local tFriendScanCount = 0
			if type(GetNumFriends) == "function" then
				tFriendScanCount = GetNumFriends() or 0
			end
			local friendScanMax = (tFriendScanCount > 0) and tFriendScanCount or 50

			for i = 1, friendScanMax do
				tName, tLevel, tClass = GetFriendInfo(i)
				if(tName == arg2) then break end
				if(tName == nil) then break end
			end

			tClass = MultiBot.toClass(tClass)
			local tTable = MultiBot.index.classes[tButton.roster][tButton.class]
			local tIndex = 0

			for i = 1, #tTable do
				if(tTable[i] == arg2) then
					tIndex = i
					break
				end
			end

			if(tIndex > 0) then
				if(MultiBot.index.classes[tButton.roster][tClass] == nil) then MultiBot.index.classes[tButton.roster][tClass] = {} end
				table.remove(MultiBot.index.classes[tButton.roster][tButton.class], tIndex)
				table.insert(MultiBot.index.classes[tButton.roster][tClass], tName)
			end

			tButton.setTexture("Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tClass) .. ".blp")
			tButton.tip = MultiBot.toTip(tClass, tLevel, tName)
			tButton.class = tClass
		end

		if(MultiBot.isInside(arg1, "Hello", "你好")) then
			tButton.waitFor = "CO"
			SendChatMessage("co ?", "WHISPER", nil, arg2)
			return
		end

		if(MultiBot.isInside(arg1, "Goodbye", "再见")) then
			return
		end

		if(MultiBot.isInside(arg1, "reset to default") and tButton.waitFor == "CO") then
			SendChatMessage("co ,?", "WHISPER", nil, arg2)
			return
		end

		if(MultiBot.isInside(arg1, "reset to default") and tButton.waitFor == "NC") then
			SendChatMessage("nc ,?", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "DETAIL" and MultiBot.isInside(arg1, "playing with")) then
			tButton.waitFor = ""
			MultiBot.RaidPool(arg2, arg1)
			return
		end

		if(tButton.waitFor == "IGNORE" and MultiBot.isInside(arg1, "Ignored ")) then
			if(MultiBot.spells[arg2] == nil) then MultiBot.spells[arg2] = {} end
			tButton.waitFor = "DETAIL"

			local tIgnores = MultiBot.doSplit(arg1, ": ")[2]

			if(tIgnores ~= nil) then
				local tSpells = MultiBot.doSplit(tIgnores, ", ")

				for k,v in pairs(tSpells) do
					local tSpell = MultiBot.doSplit(v, "|")[3]
					if(tSpell ~= nil) then MultiBot.spells[arg2][MultiBot.doSplit(tSpell, ":")[2]] = false end
				end
			end

			SendChatMessage("who", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "NC" and MultiBot.isInside(arg1, "Strategies: ")) then
			tButton.waitFor = "IGNORE"
			tButton.normal = string.sub(arg1, 13)

			local tFrame = MultiBot.frames["MultiBar"].frames["Units"].addFrame(arg2, tButton.x - tButton.size - 2, tButton.y + 2)
			tFrame.class = tButton.class
			tFrame.name = tButton.name

			MultiBot["add" .. tButton.class](tFrame, tButton.combat, tButton.normal)
			MultiBot.addEvery(tFrame, tButton.combat, tButton.normal)

			if(MultiBot.index.classes.actives[tButton.class] == nil) then MultiBot.index.classes.actives[tButton.class] = {} end
			if(MultiBot.isActive(tButton.name) == false) then
				table.insert(MultiBot.index.classes.actives[tButton.class], tButton.name)
				table.insert(MultiBot.index.actives, tButton.name)
			end

			tButton.setEnable()
			SendChatMessage("ss ?", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "CO" and MultiBot.isInside(arg1, "Strategies: ")) then
			tButton.waitFor = "NC"
			tButton.combat = string.sub(arg1, 13)
			SendChatMessage("nc ?", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor ~= "ITEM" and tButton.waitFor ~= "SPELL" and MultiBot.auto.stats and MultiBot.isInside(arg1, "Bag")) then
			local tUnit = MultiBot.toUnit(arg2)
			if(MultiBot.stats.frames[tUnit] == nil) then MultiBot.addStats(MultiBot.stats, "party1", 0, 0, 32, 192, 96) end
			MultiBot.stats.frames[tUnit].setStats(arg2, UnitLevel(tUnit), arg1)
			return
		end

		-- Inventory --

		if(tButton.waitFor == "INVENTORY" and MultiBot.isInside(arg1, "Inventory", "背包")) then
			local tItems = MultiBot.inventory.frames["Items"]
			for key, value in pairs(tItems.buttons) do value:Hide() end
			for key in pairs(tItems.buttons) do tItems.buttons[key] = nil end
			MultiBot.inventory.setText("Title", MultiBot.doReplace(MultiBot.info.inventory, "NAME", arg2))
			MultiBot.inventory.name = arg2
			tItems.index = 0
			tButton.waitFor = "ITEM"
			SendChatMessage("stats", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "ITEM" and (MultiBot.beInside(arg1, "Bag,", "Dur") or MultiBot.beInside(arg1, "背包", "耐久度"))) then
			MultiBot.inventory:Show()
			tButton.waitFor = ""
			InspectUnit(arg2)
			return
		end

		if(tButton.waitFor == "ITEM") then
			if(string.sub(arg1, 1, 3) == "---") then return end
			MultiBot.addItem(MultiBot.inventory.frames["Items"], arg1)
			return
		end

		-- Spellbook --

		if(tButton.waitFor == "SPELLBOOK" and MultiBot.isInside(arg1, "Spells")) then
			local tOverlay = MultiBot.spellbook.frames["Overlay"]
			local tSpellbook = MultiBot.spellbook
			for key in pairs(tSpellbook.spells) do tSpellbook.spells[key] = nil end
			tOverlay.setText("Title", MultiBot.doReplace(MultiBot.info.spellbook, "NAME", arg2))
			tSpellbook.name = arg2
			tSpellbook.index = 0
			tSpellbook.from = 1
			tSpellbook.to = 16
			tButton.waitFor = "SPELL"
			SendChatMessage("stats", "WHISPER", nil, arg2)
			return
		end

		if(tButton.waitFor == "SPELL" and MultiBot.isInside(arg1, "Bag,", "Dur", "XP", "背包", "耐久度", "经验值")) then
			local tOverlay = MultiBot.spellbook.frames["Overlay"]
			local tSpellbook = MultiBot.spellbook
			tSpellbook.now = 1
			tSpellbook.max = math.ceil(tSpellbook.index / 16)
			tOverlay.setText("Pages", "|cffffffff" .. tSpellbook.now .. "/" .. tSpellbook.max .. "|r")
			if(tSpellbook.now == tSpellbook.max) then tOverlay.buttons[">"].doHide() else tOverlay.buttons[">"].doShow() end
			tOverlay.buttons["<"].doHide()
			tSpellbook:Show()
			tButton.waitFor = ""
			InspectUnit(arg2)
			return
		end

		if(tButton.waitFor == "SPELL") then
			MultiBot.addSpell(arg1, arg2)
			return
		end

		-- EQUIPPING --

		if(MultiBot.inventory:IsVisible()) then
			if(MultiBot.isInside(arg1, "装备", "使用", "吃", "喝", "盛宴", "摧毁")) then
				tButton.waitFor = "INVENTORY"
				SendChatMessage("items", "WHISPER", nil, tButton.name)
				return
			end

			if(MultiBot.isInside(string.lower(arg1), "equipping", "using", "eating", "drinking", "feasting", "destroyed")) then
				tButton.waitFor = "INVENTORY"
				SendChatMessage("items", "WHISPER", nil, tButton.name)
				return
			end

			if(MultiBot.inventory:IsVisible() and MultiBot.isInside(string.lower(arg1), "opened")) then
				tButton.waitFor = "LOOT"
				return
			end
		end

		return
	end

	if(event == "CHAT_MSG_LOOT") then
		if(MultiBot.inventory:IsVisible()) then
			local tButton = nil

			if(MultiBot.isInside(arg1, "获得了物品")) then
				local tName = MultiBot.doReplace(MultiBot.doSplit(arg1, ":")[1], "获得了物品", "")
				tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			end

			if(MultiBot.isInside(string.lower(arg1), "beute", "receives")) then
				local tName = MultiBot.doSplit(arg1, " ")[1]
				tButton = MultiBot.frames["MultiBar"].frames["Units"].buttons[tName]
			end

			if(tButton ~= nil and tButton.waitFor == "LOOT" and tButton ~= nil) then
				tButton.waitFor = "INVENTORY"
				SendChatMessage("items", "WHISPER", nil, tButton.name)
				return
			end
		end

		return
	end

	if(event == "TRADE_CLOSED") then
		if MultiBot.inventory and MultiBot.inventory:IsVisible() and MultiBot.RefreshInventory then
			MultiBot.RefreshInventory()
			return
		end

		return
	end

	-- QUEST:COMPLETE --

	if(event == "QUEST_COMPLETE") then
		if(MultiBot.reward.state) then
			MultiBot.setRewards()
			return
		end

		return
	end

	-- QUEST:CHANGED --

	if(event == "QUEST_LOG_UPDATE") then
		local tButton = MultiBot.frames["MultiBar"].frames["Right"].buttons["Quests"]
		tButton.doRight(tButton)
		return
	end

	-- WORLD:MAP --

	if(event == "WORLD_MAP_UPDATE") then
		if(MultiBot.necronet.state == false) then return end

		local tCont = GetCurrentMapContinent()
		local tArea = GetCurrentMapAreaID()

		-- Recalculate Necronet button positions when map size changes
		if MultiBot.Necronet_RecalcButtons then MultiBot.Necronet_RecalcButtons() end

		if(MultiBot.necronet.cont ~= tCont or MultiBot.necronet.area ~= tArea) then
			for key, value in pairs(MultiBot.necronet.buttons) do value:Hide() end

			MultiBot.necronet.cont = tCont
			MultiBot.necronet.area = tArea

			local tTable = MultiBot.necronet.index[tCont]
			if(tTable ~= nil) then tTable = tTable[tArea] end
			if(tTable ~= nil) then for key, value in pairs(tTable) do value:Show() end end
		end

		return
	end
end

MultiBot:SetScript("OnEvent", function(_, eventName, ...)
	MultiBot.DispatchEvent(eventName, ...)
end)

local function ToggleMultiBotUI()
	if MultiBot.ToggleMainUIVisibility then
		MultiBot.ToggleMainUIVisibility()
	end
end

local function FakeGMCommand(msg)
  local n = tonumber(msg or "") or 0
  MultiBot.GM_DetectFromSystem(("Account level: %d"):format(n))
  DEFAULT_CHAT_FRAME:AddMessage(("GM now: %s (lvl=%d, threshold=%d)"):format(tostring(MultiBot.GM), n, MultiBot.GM_THRESHOLD))
end

local function ClassCommand(msg)
  local canon = MultiBot.NormalizeClass(msg)
  if canon then
    DEFAULT_CHAT_FRAME:AddMessage(("Input='%s' -> Canon='%s' | Display='%s'"):format(
      tostring(msg), canon, MultiBot.GetClassDisplay(canon) or "?"))
  else
    DEFAULT_CHAT_FRAME:AddMessage(("Input='%s' -> (no match)"):format(tostring(msg)))
  end
end

-- /mbclasstest -> batterie de cas utiles (aliases + localisés FR si le client est frFR)
local function ClassTestCommand()
  local samples = {
    "dk","death knight","DeathKnight",
    "lock","warlock",
    "pala","paladin",
    "sham","shaman",
    "mage","priest","warrior","rogue","druid","hunter",
  }
  for _, s in ipairs(samples) do
    DEFAULT_CHAT_FRAME:AddMessage(("[MB] '%s' -> %s"):format(s, tostring(MultiBot.toClass(s))))
  end
end

local COMMAND_DEFINITIONS = {
  { "MULTIBOT", ToggleMultiBotUI, { "multibot", "mbot", "mb" } },
  { "MBFAKEGM", FakeGMCommand, { "mbfakegm" } },
  { "MBCLASS", ClassCommand, { "mbclass" } },
  { "MBCLASSTEST", ClassTestCommand, { "mbclasstest" } },
}

for _, def in ipairs(COMMAND_DEFINITIONS) do
  MultiBot.RegisterCommandAliases(def[1], def[2], def[3])
end