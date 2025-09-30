MultiBot.addItem = function(pFrame, pInfo)
	local tInfo = MultiBot.doSplit(pInfo, "|")
	local tID = MultiBot.doSplit(tInfo[3], ":")[2]
	
	local tIcon = GetItemIcon(tID)
	local tName, tLink, tRare = GetItemInfo(tID)
	
	local tX = (pFrame.index%8) * 38
	local tY = math.floor(pFrame.index/8) * -37.1
	
	if(tName == nil) then tName = string.sub(tInfo[4], 3, string.len(tInfo[4]) - 1) end
	if(tLink == nil) then tLink = "|" .. tInfo[2] .. "|" .. tInfo[3] .. "|" .. tInfo[4] .. "|h|r" end
	if(tRare == nil) then tRare = 4 end -- for Security
	
	local tButton = pFrame.addButton(tName, tX, tY, tIcon, tLink)
	pFrame.catButton("Catecher", 270, -490, 308, 524)
	
	tButton.item = {}
	tButton.item.id = tID
	tButton.item.link = tLink
	tButton.item.name = tName
	tButton.item.info = pInfo
	tButton.item.rare = tRare
	
	tButton.doLeft = function(pButton)
		local tAction = MultiBot.inventory.action
		local tName = MultiBot.inventory.name
		
		if(tAction == "") then
			SendChatMessage(MultiBot.info.action, "SAY")
			return
		end
		
		if(tAction == "s" and MultiBot.isTarget()) then
			if(pButton.item.id == "6948") then return SendChatMessage(MultiBot.info.itemsellalert, "SAY") end
			--if(MultiBot.isInside(pButton.item.info, "key")) then return SendChatMessage("I will not sell Keys.", "SAY") end
			--if(MultiBot.isInside(pButton.item.info, "Key")) then return SendChatMessage("I will not sell Keys.", "SAY") end
			if(MultiBot.isInside(pButton.item.info or "", "%f[%a][Kk]ey%f[%A]")) then return SendChatMessage(MultiBot.info.keydestroyalert, "SAY") end
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			pButton:Hide()
			return
		end
		
		if(tAction == "e" or tAction == "u" or tAction == "give") then
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			return
		end
		
		--[[if(tAction == "destroy") then
			if(pButton.item.id == "6948") then return SendChatMessage("I cant drop this Item.", "SAY") end
			if(MultiBot.isInside(pButton.item.info, "key")) then return SendChatMessage("I will not drop Keys.", "SAY") end
			if(MultiBot.isInside(pButton.item.info, "Key")) then return SendChatMessage("I will not drop Keys.", "SAY") end
			if(pButton.item.rare > 3) then return SendChatMessage("I will not drop that good Items.", "SAY") end
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			pButton:Hide()
			return
		end]]--
		if(tAction == "destroy") then
			local needsConfirm = false
			if(pButton.item.id == "6948") then needsConfirm = true end -- Hearthstone
			--if(MultiBot.isInside(pButton.item.info, "key")) then needsConfirm = true end
			--if(MultiBot.isInside(pButton.item.info, "Key")) then needsConfirm = true end
			if(MultiBot.isInside(pButton.item.info, "%f[%a][Kk]ey%f[%A]")) then needsConfirm = true end
			if(pButton.item.rare > 3) then needsConfirm = true end -- Épique ou mieux
			if needsConfirm then
				if not StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] then
					StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] = {
						text = MultiBot.info.itemdestroyalert,
						button1 = OKAY,
						button2 = CANCEL,
						timeout = 0,
						whileDead = 1,
						hideOnEscape = 1,
						OnAccept = function(self, data)
							if not data or not data.button then return end
							SendChatMessage("destroy" .. " " .. data.button.tip, "WHISPER", nil, data.tName)
							data.button:Hide()
						end,
					}
				end
				local data = { button = pButton, tName = tName }
				StaticPopup_Show("MULTIBOT_CONFIRM_DESTROY", pButton.item.link, nil, data)
				return
			end
			-- Pas de confirmation requise
			SendChatMessage(tAction .. " " .. pButton.tip, "WHISPER", nil, tName)
			pButton:Hide()
			return
		end
	end
	
	if(string.sub(tInfo[6], 1, 2) == "rx") then
		tButton.setAmount(string.sub(MultiBot.doSplit(tInfo[6], " ")[1], 3))
	end
	
	pFrame.index = pFrame.index + 1
end