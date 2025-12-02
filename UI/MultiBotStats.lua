MultiBot.addStats = function(pFrame, pIndex, pX, pY, pSize, pWidth, pHeight)
	local tFrame = pFrame.addFrame(pIndex, pX, pY, pSize, pWidth, pHeight)
	local tAddon = tFrame.addFrame("Addon", -2, 46, 48)
	tAddon.addTexture("Interface\\AddOns\\MultiBot\\Icons\\xp_progress_99_percent.blp")
	tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Stats.blp")
	tFrame:Hide()
	
	tFrame.addText("Name", "", "TOPLEFT", 54, -11, 11)
	tFrame.addText("Values", "", "TOPLEFT", 54, -27, 11)
	tAddon.addText("Percent", "", "CENTER", 0, 0, 11)
	tFrame.addText("Level", "", "CENTER", 85.25, 5, 11)
	
	tFrame.setProgress = function(frame, pProgress)
		local addonFrame = frame.frames["Addon"]

		addonFrame.texture:Hide()

		if pProgress >= 99 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_99_percent.blp"
			)
		elseif pProgress >= 90 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_90_percent.blp"
			)
		elseif pProgress >= 81 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_81_percent.blp"
			)
		elseif pProgress >= 72 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_72_percent.blp"
			)
		elseif pProgress >= 63 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_63_percent.blp"
			)
		elseif pProgress >= 54 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_54_percent.blp"
			)
		elseif pProgress >= 45 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_45_percent.blp"
			)
		elseif pProgress >= 36 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_36_percent.blp"
			)
		elseif pProgress >= 27 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_27_percent.blp"
			)
		elseif pProgress >= 18 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_18_percent.blp"
			)
		elseif pProgress >= 9 then
			addonFrame.setTexture(
				"Interface\\AddOns\\MultiBot\\Icons\\xp_progress_9_percent.blp"
			)
		end

		return pProgress
	end
	
	tFrame.setStats = function(pName, pLevel, pStats, oPlayer)
		local statsFrame = MultiBot.stats.frames[MultiBot.toUnit(pName)]
		local addonFrame = statsFrame.frames["Addon"]
		local tChina = GetLocale() == "zhCN"

		if oPlayer ~= nil and oPlayer == true then
			local tStats = MultiBot.doSplit(pStats, ", ")
			local tMana = tonumber(tStats[5])
			local tXP = tonumber(tStats[4])

			statsFrame.texts["Name"]:SetText(pName)
			statsFrame.texts["Level"]:SetText(pLevel)
			statsFrame.texts["Values"]:SetText("Player")

			if pLevel == 80 then
				addonFrame.texts["Percent"]:SetText(
					statsFrame.setProgress(statsFrame, tMana)
					.. "%\n"
					.. MultiBot.info.shorts.mp
				)
			else
				addonFrame.texts["Percent"]:SetText(
					statsFrame.setProgress(statsFrame, tXP)
					.. "%\n"
					.. MultiBot.info.shorts.xp
				)
			end

			statsFrame:Show()
			return
		end

		local tStats = MultiBot.doSplit(pStats, ", ")
		local tMoney = "|cffffdd55" .. tStats[1] .. "|r, "
		local tBag = MultiBot.IF(
			tChina,
			MultiBot.doReplace(tStats[2], "Bag", MultiBot.info.shorts.bag),
			tStats[2]
		)

		statsFrame.texts["Name"]:SetText(pName)
		statsFrame.texts["Level"]:SetText(pLevel)
		statsFrame.texts["Values"]:SetText(tMoney .. tBag)

		if pLevel == 80 then
			local durabilityString = MultiBot.doSplit(tStats[3], "|")[2]
			local tDur = MultiBot.doSplit(string.sub(durabilityString, 10), " ")
			local tQuality = tonumber(string.sub(tDur[1], 1, string.len(tDur[1]) - 1))
			local tRepair = tonumber(string.sub(tDur[2], 2, string.len(tDur[2]) - 1))

			if tQuality == 0 and tRepair == 0 then
				tQuality = 100
			end

			addonFrame.texts["Percent"]:SetText(
				statsFrame.setProgress(statsFrame, tQuality)
				.. "%\n"
				.. MultiBot.info.shorts.dur
			)
		else
			local xpString = MultiBot.doSplit(tStats[4], "|")[2]
			local tXP = tonumber(string.sub(xpString, 10))

			addonFrame.texts["Percent"]:SetText(
				statsFrame.setProgress(statsFrame, tXP)
				.. "%\n"
				.. MultiBot.info.shorts.xp
			)
		end

		statsFrame:Show()
		return
	end
end