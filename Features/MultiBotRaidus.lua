local MultiBotRaidusClassWeight = {
    DeathKnight = 1,
    Druid       = 2,
    Hunter      = 3,
    Mage        = 4,
    Paladin     = 5,
    Priest      = 6,
    Rogue       = 7,
    Shaman      = 8,
    Warlock     = 9,
    Warrior     = 10,
}

-- Rôle par défaut par classe (fallback si on ne peut pas lire les talents)
local MultiBotRaidusRoleDefaults = {
    DeathKnight = "TANK",
    Druid       = "HEAL",
    Hunter      = "DPS",
    Mage        = "DPS",
    Paladin     = "TANK",
    Priest      = "HEAL",
    Rogue       = "DPS",
    Shaman      = "HEAL",
    Warlock     = "DPS",
    Warrior     = "TANK",
}

-- Rôle par classe ET par arbre de talents dominant (index 1 / 2 / 3)
-- L’ordre des arbres est celui du client (1er onglet, 2ème, 3ème) et ne dépend pas de la langue.
local MultiBotRaidusRoleByTree = {
    Paladin     = { "HEAL", "TANK", "DPS" },        -- Sacré, Protection, Vindicte
    Warrior     = { "DPS",  "DPS",  "TANK" },       -- Armes, Fureur, Protection
    Druid       = { "DPS",  "TANK", "HEAL" },       -- Equilibre, Farouche, Restauration
    Priest      = { "HEAL", "HEAL", "DPS" },        -- Discipline, Sacré, Ombre
    Shaman      = { "DPS",  "DPS",  "HEAL" },       -- Élémentaire, Amélio, Restauration
    DeathKnight = { "TANK", "TANK", "DPS" },        -- Sang, Givre, Impie (approximation raid)
    Hunter      = { "DPS",  "DPS",  "DPS" },        -- Maîtrise des bêtes, Précision, Survie
    Rogue       = { "DPS",  "DPS",  "DPS" },        -- Assassinat, Combat, Finesse
    Mage        = { "DPS",  "DPS",  "DPS" },        -- Arcanes, Feu, Givre
    Warlock     = { "DPS",  "DPS",  "DPS" },        -- Affliction, Démonologie, Destruction
}

-- Détection de rôle indépendante de la langue :
--  On lit la répartition de talents "x/y/z"
--  On prend l'arbre dominant (1,2,3)
--  On mappe (classe, arbre) -> rôle TANK/HEAL/DPS
--  Fallback sur MultiBotRaidusRoleDefaults
local function MultiBotRaidusDetectRole(bot)
    if not bot then
        return "DPS"
    end

    -- Classe normalisée (MultiBot.toClass sait déjà gérer les noms de classes localisés)
    local class = MultiBot.toClass(bot.class)
    local talents = bot.talents or ""

    -- les talents doivent ressembler à par exemple "54/17/0"
    local t1, t2, t3 = talents:match("^(%d+)%/(%d+)%/(%d+)$")
    t1, t2, t3 = tonumber(t1), tonumber(t2), tonumber(t3)

    if t1 and t2 and t3 then
        local total = t1 + t2 + t3
        if total > 0 then
            local maxIndex = 1

            if t2 > t1 and t2 >= t3 then
                maxIndex = 2
            elseif t3 > t1 and t3 > t2 then
                maxIndex = 3
            end

            local byTree = MultiBotRaidusRoleByTree[class]
            if byTree and byTree[maxIndex] then
                return byTree[maxIndex]
            end
        end
    end

    -- Si on ne peut pas lire les talents ou que la classe n'est pas mappée on fallback
    local baseRole = MultiBotRaidusRoleDefaults[class]
    if baseRole then
        return baseRole
    end

    return "DPS"
end

-- Retourne true si le bot (par son nom) est dans ton groupe ou raid
local function MultiBotRaidusIsBotGrouped(name)
    if not name or name == "" then
        return false
    end

    local numRaid = GetNumRaidMembers()
    if numRaid and numRaid > 0 then
        for i = 1, numRaid do
            local raidName, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if raidName == name and online then
                return true
            end
        end
        return false
    end

    local numParty = GetNumPartyMembers()
    if numParty and numParty > 0 then
        for i = 1, numParty do
            local unit = "party" .. i
            local partyName = UnitName(unit)
            if partyName == name and UnitIsConnected(unit) then
                return true
            end
        end
    end

    return false
end

MultiBot.raidus = MultiBot.newFrame(MultiBot, -340, -126, 32, 884, 884)
MultiBot.raidus.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus.blp")
MultiBot.raidus:SetMovable(true)
MultiBot.raidus:Hide()

MultiBot.raidus.addFrame("Pool", -20, 360, 28, 160, 490)
MultiBot.raidus.addFrame("Btop", -35, 822, 24, 128, 32).addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus_Banner_Top.blp")
MultiBot.raidus.addFrame("Bbot", -35, 354, 24, 128, 32).addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus_Banner_Bottom.blp")
MultiBot.raidus.addFrame("Group8", -185, 364, 28, 160, 240)
MultiBot.raidus.addFrame("Group7", -350, 364, 28, 160, 240)
MultiBot.raidus.addFrame("Group6", -515, 364, 28, 160, 240)
MultiBot.raidus.addFrame("Group5", -680, 364, 28, 160, 240)
MultiBot.raidus.addFrame("Group4", -185, 604, 28, 160, 240)
MultiBot.raidus.addFrame("Group3", -350, 604, 28, 160, 240)
MultiBot.raidus.addFrame("Group2", -515, 604, 28, 160, 240)
MultiBot.raidus.addFrame("Group1", -680, 604, 28, 160, 240)
MultiBot.raidus.addText("RaidScore", "RaidScore: 0", "BOTTOMLEFT", 376, 364, 12)
MultiBot.raidus.save = ""
MultiBot.raidus.from = 1
MultiBot.raidus.to = 11
MultiBot.raidus.sortMode = "Score" -- "Score" | "Level" | "Class"

MultiBot.raidus.movButton("Move", -780, 790, 90, MultiBot.tips.move.raidus)

MultiBot.raidus.wowButton("x", -13, 841, 16, 20, 12)
.doLeft = function(pButton)
	local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Raidus"]
	tButton.doLeft(tButton)
end

MultiBot.raidus.wowButton("Load", -762, 360, 80, 20, 12)
.doLeft = function(pButton)
	local tPool = MultiBot.raidus.frames["Pool"]
	local tData = MultiBotSave["Raidus" .. MultiBot.raidus.save]

	if(tData == nil or tData == "") then
		SendChatMessage(MultiBot.info.nothing, "SAY");
	end

	local tLoad = MultiBot.doSplit(tData, ";")

	for i = 1, 8, 1 do
		local tGroup = MultiBot.doSplit(tLoad[i], ",")

		for j = 1, 5, 1 do
			local tDrop = MultiBot.raidus.frames["Group" .. i].frames["Slot" .. j]
			local tName = tGroup[j]

			if(tName ~= "-") then
				for tIndex, tDrag in pairs(tPool.frames) do
					if(tDrag.name ~= nil and tDrag.name == tName) then
						local tVisible = tDrag:IsVisible()
						local tParent = tDrag.parent
						local tHeight = tDrag.height
						local tWidth = tDrag.width
						local tSlot = tDrag.slot
						local tX = tDrag.x
						local tY = tDrag.y

						MultiBot.raidus.doDrop(tDrag, tDrop.parent, tDrop.x, tDrop.y, tDrop.width, tDrop.height, tDrop.slot)
						if(tDrop:IsVisible()) then tDrag:Show() else tDrag:Hide() end

						MultiBot.raidus.doDrop(tDrop, tParent, tX, tY, tWidth, tHeight, tSlot)
						if(tVisible) then tDrop:Show() else tDrop:Hide() end
					end
				end
			end
		end
	end
end

local function UpdateRaidusSlotButtonText(button)
	local label = "Slot"
	if MultiBot.raidus.save ~= "" then
		label = "Slot " .. MultiBot.raidus.save
	end
	button.text:SetText("|cffffcc00" .. label .. "|r")
end

local slotDropDown = CreateFrame("Frame", "MultiBotRaidusSlotDropDown", MultiBot.raidus, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(slotDropDown, 80)
UIDropDownMenu_Initialize(slotDropDown, function(self, level)
	for i = 1, 10 do
		local info = UIDropDownMenu_CreateInfo()
		info.text = tostring(i)
		info.value = tostring(i)
		info.func = function()
			MultiBot.raidus.save = tostring(i)
			UIDropDownMenu_SetSelectedValue(slotDropDown, tostring(i))
			UpdateRaidusSlotButtonText(MultiBot.raidus.buttons["Slot"])
			MultiBot.raidus.setRaidus()
		end
		UIDropDownMenu_AddButton(info, level)
	end
end)

local slotButton = MultiBot.raidus.wowButton("Slot", -682, 360, 80, 20, 12)
slotButton.tip = MultiBot.tips.raidus.slot
slotButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:SetText(self.tip or "", 1, 1, 1, true)
end)
slotButton:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)
slotButton.doLeft = function()
	if MultiBot.raidus.save ~= "" then
		UIDropDownMenu_SetSelectedValue(slotDropDown, MultiBot.raidus.save)
	end
	ToggleDropDownMenu(1, nil, slotDropDown, slotButton, 0, 0)
end
UpdateRaidusSlotButtonText(slotButton)

-- Contrôle du mode Tri, "Score / Level / Class"
local sortBaseX   = -300 -- position du bouton "Score", pour déplacer tout le groupe il faut modifier cette valeur
local sortY       = 360
local sortSpacing = 6    -- espace entre les boutons

local scoreWidth  = 60
local levelWidth  = 60
local classWidth  = 60

-- Bouton "Score"
local btnScore = MultiBot.raidus.wowButton("Score", sortBaseX, sortY, scoreWidth, 20, 12)
btnScore.setEnable()
btnScore:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.tips.raidus.score, 1, 1, 1, true)
end)
btnScore:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
btnScore.doLeft = function(pButton)
    pButton.parent.sortMode = "Score"

    pButton.setEnable()
    if pButton.parent.buttons["Level"] then
        pButton.parent.buttons["Level"].setDisable()
    end
    if pButton.parent.buttons["Class"] then
        pButton.parent.buttons["Class"].setDisable()
    end

    MultiBot.raidus.setRaidus()
end

-- Bouton "Level"
local btnLevel = MultiBot.raidus.wowButton(
    "Level",
    sortBaseX + scoreWidth + sortSpacing,
    sortY,
    levelWidth,
    20,
    12
)
btnLevel.setDisable()
btnLevel:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.tips.raidus.level, 1, 1, 1, true)
end)
btnLevel:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
btnLevel.doLeft = function(pButton)
    pButton.parent.sortMode = "Level"

    pButton.setEnable()
    if pButton.parent.buttons["Score"] then
        pButton.parent.buttons["Score"].setDisable()
    end
    if pButton.parent.buttons["Class"] then
        pButton.parent.buttons["Class"].setDisable()
    end

    MultiBot.raidus.setRaidus()
end

-- Bouton "Class"
local btnClass = MultiBot.raidus.wowButton(
    "Class",
    sortBaseX + scoreWidth + sortSpacing + levelWidth + sortSpacing,
    sortY,
    classWidth,
    20,
    12
)
btnClass.setDisable()
btnClass:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.tips.raidus.class, 1, 1, 1, true)
end)
btnClass:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
btnClass.doLeft = function(pButton)
    pButton.parent.sortMode = "Class"

    pButton.setEnable()
    if pButton.parent.buttons["Score"] then
        pButton.parent.buttons["Score"].setDisable()
    end
    if pButton.parent.buttons["Level"] then
        pButton.parent.buttons["Level"].setDisable()
    end

    MultiBot.raidus.setRaidus()
end

MultiBot.raidus.wowButton("Save", -597, 360, 80, 20, 12)
.doLeft = function(pButton)
	local tSave = ""

	for i = 1, 8, 1 do
		local tGroup = ""

		for j = 1, 5, 1 do
			local tSlot = MultiBot.raidus.frames["Group" .. i].frames["Slot" .. j]
			local tName = MultiBot.IF(tSlot.name == nil, "-", tSlot.name)
			tGroup = tGroup .. MultiBot.IF(tGroup == "", "", ",")
			tGroup = tGroup .. tName
		end

		tSave = tSave .. MultiBot.IF(tSave == "", "", ";")
		tSave = tSave .. tGroup
	end

	MultiBotSave["Raidus" .. MultiBot.raidus.save] = tSave
	SendChatMessage("I wrote it down.", "SAY")
end

MultiBot.raidus.wowButton("Apply", -514, 360, 80, 20, 12)
.doLeft = function(pButton)
	local tRaidByIndex, tRaidByName = MultiBot.raidus.getRaidTarget()
	if(tRaidByIndex == nil or tRaidByName == nil) then return end

	local tSelf = UnitName("player")
	MultiBot.index.raidus = {}
    local tSelected = 0
    local selectedNames = {}

	for tName, tValue in pairs(MultiBot.frames["MultiBar"].frames["Units"].buttons) do
		if(tValue.state) then
            tSelected = tSelected + 1
            selectedNames[tName] = true
		else
			if(tName ~= tSelf and tRaidByName[tName] ~= nil) then
				table.insert(MultiBot.index.raidus, tName)
			end
		end
	end

	local tNeeds = #MultiBot.index.raidus

    local usedLayoutFallback = false

    local tFallback = {}
    local hasLayoutOnly = false
    for tName, _ in pairs(tRaidByName) do
        if tName ~= tSelf then
            if not selectedNames[tName] then
                hasLayoutOnly = true
            end
            if not MultiBot.isMember(tName) then
                table.insert(tFallback, tName)
            end
        end
    end

    if tSelected == 0 or hasLayoutOnly then
        if #tFallback > 0 then
            MultiBot.index.raidus = tFallback
            tNeeds = #tFallback
            usedLayoutFallback = true
        end
    end

    local tRaidByMembers = MultiBot.raidus.getRaidState()
    for tName, _ in pairs(tRaidByMembers) do
        if tName ~= tSelf and tRaidByName[tName] == nil then
            if MultiBot.isMember(tName) then
                UninviteUnit(tName)
            end
            SendChatMessage(".playerbot bot remove " .. tName, "SAY")
        end
    end

    local tList = ""
    if tNeeds > 0 then
        tList = table.concat(MultiBot.index.raidus, ", ")
    end
    if usedLayoutFallback then
        SendChatMessage("Raidus Apply: using layout list, selected=" .. tSelected .. " toInvite=" .. tNeeds, "SAY")
    else
        SendChatMessage("Raidus Apply: selected=" .. tSelected .. " toInvite=" .. tNeeds, "SAY")
    end
    if tList ~= "" then
        SendChatMessage("Raidus Apply list: " .. tList, "SAY")
    end

    if(tNeeds > 0) then
		SendChatMessage(MultiBot.info.starting, "SAY")
		MultiBot.timer.invite.roster = "raidus"
		MultiBot.timer.invite.needs = tNeeds
		MultiBot.timer.invite.index = 1
		MultiBot.auto.invite = true
	else
		MultiBot.timer.sort.elapsed = 0
		MultiBot.timer.sort.index = 1
		MultiBot.timer.sort.needs = 0
		MultiBot.auto.sort = true
	end
end

-- Bouton Auto-balance raid :
-- Clic gauche  : équilibrage simple par score
-- Clic droit   : équilibrage avancé Tank / Heal / DPS
local btnAuto = MultiBot.raidus.wowButton("Auto", -431, 360, 80, 20, 12)

btnAuto:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.tips.raidus.autobalance, 1, 1, 1, true)
end)

btnAuto:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Clic gauche : simple, on répartit les bots par score le plus équilibré possible
btnAuto.doLeft = function(pButton)
    MultiBot.raidus.autoBalanceRaid("score")
end

-- Clic droit : mode avancé Tank / Heal / DPS
btnAuto.doRight = function(pButton)
    MultiBot.raidus.autoBalanceRaid("role")
end

MultiBot.raidus.wowButton("<", -40, 360, 16, 20, 12)
.doLeft = function(pButton)
	for k,v in pairs(MultiBot.raidus.frames["Pool"].frames) do v:Hide() end

	MultiBot.raidus.from = MultiBot.raidus.from - 11
	MultiBot.raidus.to = MultiBot.raidus.to - 11

	if(MultiBot.raidus.to < 1) then
		MultiBot.raidus.from = MultiBot.raidus.slots - 10
		MultiBot.raidus.to = MultiBot.raidus.slots
	end

	for i = 1, MultiBot.raidus.slots, 1 do
		local tSlot = MultiBot.raidus.frames["Pool"].frames["Slot" .. i]
		if(i >= MultiBot.raidus.from and i <= MultiBot.raidus.to) then tSlot:Show() else tSlot:Hide() end
	end
end

MultiBot.raidus.wowButton(">", -20, 360, 16, 20, 12)
.doLeft = function(pButton)
	MultiBot.raidus.from = MultiBot.raidus.from + 11
	MultiBot.raidus.to = MultiBot.raidus.to + 11

	if(MultiBot.raidus.from > MultiBot.raidus.slots) then
		MultiBot.raidus.from = 1
		MultiBot.raidus.to = 11
	end

	for i = 1, MultiBot.raidus.slots, 1 do
		local tSlot = MultiBot.raidus.frames["Pool"].frames["Slot" .. i]
		if(i >= MultiBot.raidus.from and i <= MultiBot.raidus.to) then tSlot:Show() else tSlot:Hide() end
	end
end

MultiBot.raidus.getDrop = function()
	for i = 1, 8, 1 do
		local tGroup = MultiBot.raidus.frames["Group" .. i]

		if(MouseIsOver(tGroup)) then
			for j = 1, 5, 1 do
				local tSlot = tGroup.frames["Slot" .. j]
				if(MouseIsOver(tSlot)) then return tSlot end
			end
		end
	end

	for i = 1, MultiBot.raidus.slots, 1 do
		local tSlot = MultiBot.raidus.frames["Pool"].frames["Slot" .. i]
		if(MouseIsOver(tSlot)) then return tSlot end
	end

	return nil
end

-- SETTTER --

MultiBot.raidus.setRaidus = function()
	local tPool = MultiBot.raidus.frames["Pool"]
	local tSlot = 1
	local tY = 426

	for k,v in pairs(tPool.frames) do v:Hide() end

	local tBots = {}
	local tBotsIndex = 1
	-- Mode de tri actuel ("Score", "Level", "Class")
	local sortMode = MultiBot.raidus.sortMode or "Score"

    for tName, tValue in pairs(MultiBotGlobalSave) do
        local tDetails = MultiBot.doSplit(tValue, ",")
        local rawClass = tDetails[5]
        if rawClass and rawClass ~= "" then
            local tBot = {}
            tBot.name = tName
            tBot.race = tDetails[1]
            tBot.gender = tDetails[2]
            tBot.special = tDetails[3]
            tBot.talents = tDetails[4]
            tBot.class = rawClass
            tBot.level = tonumber(tDetails[6]) or 0
            tBot.score = tonumber(tDetails[7]) or 0
            tBot.role = MultiBotRaidusDetectRole(tBot)

            -- DEBUG
            --[[local debugClass   = MultiBot.toClass(tBot.class or "?")
            local debugTalents = tBot.talents or "?"
            local debugRole    = tBot.role or "nil"
            local debugName    = tBot.name or "?"
            print(string.format("[MultiBot Raidus] %s -> role=%s (class=%s, talents=%s)",
                debugName, debugRole, debugClass, debugTalents))--]]

            local tClass = MultiBot.toClass(tBot.class)
			local classWeight = MultiBotRaidusClassWeight[tClass] or 0
			local botLevel   = tBot.level or 0
			local botScore   = tBot.score or 0

			-- Tri Score / Level / Class
			if sortMode == "Score" then
				-- Score desc, puis niveau desc, puis classe
				tBot.sort = botScore * 1000000 + botLevel * 1000 + classWeight
			elseif sortMode == "Level" then
				-- Niveau desc, puis score desc, puis classe
				tBot.sort = botLevel * 1000000 + botScore * 1000 + classWeight
			elseif sortMode == "Class" then
				-- Classe (ordre fixe), puis niveau desc, puis score desc
				tBot.sort = classWeight * 1000000 + botLevel * 1000 + botScore
			else
				-- fallback : tri par score
				tBot.sort = botScore * 1000000 + botLevel * 1000 + classWeight
			end

			tBots[tBotsIndex] = tBot
			tBotsIndex = tBotsIndex + 1
		end
	end

	for tIndex = 1, #tBots do
		local tMax = tIndex

		for tSearch = tIndex + 1, #tBots do
			if(tBots[tMax].sort < tBots[tSearch].sort) then
				tMax = tSearch
			end
		end

		tBots[tIndex], tBots[tMax] = tBots[tMax], tBots[tIndex]
	end

	for tIndex = 1, #tBots do
		local tBot = tBots[tIndex]

		local tFrame = tPool.addFrame("Slot" .. tSlot, 0, tY, 28, 160, 36)
		tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
		tFrame:SetResizable(false)
		tFrame:SetMovable(true)
		tFrame.class = MultiBot.toClass(tBot.class)
		tFrame.slot = "Slot" .. tSlot
		tFrame.name = tBot.name
		tFrame.bot = tBot

		--local tButton = tFrame.addButton("Icon", -128, 3, "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tFrame.class) .. ".blp", "")
		--tButton.doRight = function(pButton)
			--SendChatMessage(".playerbot bot add " .. pButton.parent.name, "SAY")
		--end

        local tButton = tFrame.addButton("Icon", -128, 3, "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(tFrame.class) .. ".blp", "")

		tButton:SetScript("OnEnter", function(pButton)
			local bot = pButton.parent.bot
			if not bot then
				return
			end

			local botName    = bot.name or "?"
			local botGender  = bot.gender or "?"
			local botRace    = bot.race or "?"
			local botClass   = bot.class or "Unknown"
			local botTalents = bot.talents or "?"
			local botSpecial = bot.special or "?"
			local botLevel   = bot.level or 0
			local botScore   = bot.score or 0

			local tReward = botLevel .. "." .. MultiBot.IF(botScore < 100, "0", MultiBot.IF(botScore < 10, "00", "")) .. botScore

			pButton.tip = MultiBot.newFrame(pButton, -pButton.size, 160, 28, 256, 512, "TOPRIGHT")
			pButton.tip.addTexture("Interface\\AddOns\\MultiBot\\Textures\\Raidus_Wanted.blp")
			pButton.tip.addModel(botName, 0, 64, 160, 240, 1.0)
			pButton.tip.addText("1", "|cff555555- WANTED -|h", "TOP", 0, -30, 24)
			pButton.tip.addText("2", "|cff555555-DEAD OR ALIVE-|h", "TOP", 0, -55, 24)
			pButton.tip.addText("3", "|cff333333" .. botName .. " - " .. botGender .. " - " .. botRace .. "|h", "BOTTOM", 0, 220, 15)
			pButton.tip.addText("4", "|cff333333" .. botClass .. " - " .. botTalents .. " - " .. botSpecial .. "|h", "BOTTOM", 0, 200, 15)
			pButton.tip.addText("5", "|cff555555--------------------------------------------|h", "BOTTOM", 0, 188, 15)
			pButton.tip.addText("6", "|cff555555CASH - " .. tReward .. " - GOLD|h", "BOTTOM", 0, 170, 20)
			pButton.tip.addText("7", "|cff555555--------------------------------------------|h", "BOTTOM", 0, 160, 15)
			pButton.tip:Show()
		end)

        -- Clic gauche : drag & drop dans les groupes
        -- Clic droit  : connecte / déconnecte le bot (add/remove)
        tButton:SetScript("OnMouseDown", function(pButton, button)
            if button == "LeftButton" then
                pButton.parent:StartMoving()
                pButton.parent.isMoving = true
            end
        end)

        tButton:SetScript("OnMouseUp", function(pButton, button)
            if button == "LeftButton" then
                -- Drag & drop (inchangé)
                pButton.parent:StopMovingOrSizing()
                pButton.parent.isMoving = false

                local tDrag = pButton.parent
                local tDrop = MultiBot.raidus.getDrop()

                if tDrop ~= nil then
                    local tParent  = tDrag.parent
                    local tHeight  = tDrag.height
                    local tWidth   = tDrag.width
                    local dropSlot = tDrag.slot
                    local tX       = tDrag.x
                    local dropY    = tDrag.y

                    MultiBot.raidus.doDrop(
                        tDrag,
                        tDrop.parent,
                        tDrop.x,
                        tDrop.y,
                        tDrop.width,
                        tDrop.height,
                        tDrop.slot
                    )
                    MultiBot.raidus.doDrop(
                        tDrop,
                        tParent,
                        tX,
                        dropY,
                        tWidth,
                        tHeight,
                        dropSlot
                    )
                else
                    pButton.parent:ClearAllPoints()
                    pButton.parent:SetPoint(pButton.parent.align, pButton.parent.x, pButton.parent.y)
                    pButton.parent:SetSize(pButton.parent.width, pButton.parent.height)
                end

            elseif button == "RightButton" then
                local name = pButton.parent.name
                if not name or name == "" then
                    return
                end

                if MultiBotRaidusIsBotGrouped(name) then
                    -- Bot déjà dans le groupe/raid :
                    -- on laisse le core playerbots gérer leave + logout
                    SendChatMessage("logout", "WHISPER", nil, name)
                else
                    -- Bot pas dans le groupe/raid :
                    -- login + invite via playerbots
                    SendChatMessage(".playerbot bot add " .. name, "SAY")
                end
            end
        end)

		local displayClass   = tBot.class or "Unknown"
		local displayLevel   = tBot.level or 0
		local displayScore   = tBot.score or 0
		local displaySpecial = tBot.special or ""

		tFrame.addText("1", displayLevel .. " - " .. displayClass, "BOTTOMLEFT", 36, 18, 12)
		tFrame.addText("2", displayScore .. " - " .. displaySpecial, "BOTTOMLEFT", 36, 6, 12)

		if(tSlot > 11) then tFrame:Hide() else tFrame:Show() end
		tY = MultiBot.IF(tSlot % 11 == 0, 426, tY - 40)
		tSlot = tSlot + 1
	end

	for i = tSlot % 11, 11, 1 do
		local tFrame = tPool.addFrame("Slot" .. tSlot, 0, tY, 28, 160, 36)
		tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
		tFrame.slot = "Slot" .. tSlot
		if(tSlot > 11) then tFrame:Hide() else tFrame:Show() end
		tSlot = tSlot + 1
		tY = tY - 40
	end

	MultiBot.raidus.slots = tSlot - 1

	for i = 1, 8, 1 do
		local tGroup = MultiBot.raidus.frames["Group" .. i]
		local groupY = 182

		tGroup.addText("Title", "- Group" .. i .. " : 0 -", "BOTTOM", 0, 223, 12)
		tGroup.group = "Group" .. i
		tGroup.score = 0

		for j = 1, 5, 1 do
			local tFrame = tGroup.addFrame("Slot" .. j, 0, groupY, 28, 160, 36)
			tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
			tFrame.slot = "Slot" .. j
			groupY = groupY - 40
		end
	end
end

-- GETTER --

MultiBot.raidus.getRaidState = function()
	local tRaidByMembers = {}
	local tRaidByGroups = {}

	local tRaid = GetNumRaidMembers()
	local tGroup = GetNumPartyMembers()
	local tAmount = MultiBot.IF(tRaid > tGroup, tRaid, tGroup)

	for tIndex = 1, tAmount do
		local xName, xRank, xGroup = GetRaidRosterInfo(tIndex)
		if(xName and xRank and xGroup) then
			tRaidByMembers[xName] = { index = tIndex, group = xGroup }
			tRaidByGroups[xGroup] = (tRaidByGroups[xGroup] or 0) + 1
		end
	end

	return tRaidByMembers, tRaidByGroups
end

MultiBot.raidus.getRaidTarget = function()
	local tRaidByIndex = {}
	local tRaidByName = {}
	local tIndex = 1

	local tSelf = UnitName("player")
	local tUser = true
	local tBots = true

	for tGroup = 1, 8 do
		for tSlot = 1, 5 do
			local tName = MultiBot.raidus.frames["Group" .. tGroup].frames["Slot" .. tSlot].name
			if(tName ~= nil) then
				if(tName == tSelf) then tUser = false end
				tRaidByIndex[tIndex] = { name = tName, group = tGroup }
				tRaidByName[tName] = tGroup
				tIndex = tIndex + 1
				tBots = false
			end
		end
	end

	if(tBots) then return SendChatMessage("There is no Bot in the Raid", "SAY") end
	if(tUser) then return SendChatMessage("I must be in the Raid!", "SAY") end
	return tRaidByIndex, tRaidByName
end

-- EVENTS --

MultiBot.raidus.doRaidSortCheck = function()
	local _, tRaidByName = MultiBot.raidus.getRaidTarget()
	local tRaidByMembers = MultiBot.raidus.getRaidState()

	for tName, tGroup in pairs(tRaidByName) do
		if(tRaidByMembers[tName] ~= nil and tRaidByMembers[tName].group ~= tGroup) then return 1 end
	end

	return nil
end

MultiBot.raidus.doRaidSort = function(pIndex)
	local tRaidByIndex, tRaidByName = MultiBot.raidus.getRaidTarget()
	local tRaidByMembers, tRaidByGroups = MultiBot.raidus.getRaidState()

	if(pIndex > #tRaidByIndex) then return nil end

	local tName = tRaidByIndex[pIndex].name
	local tGroup = tRaidByIndex[pIndex].group

	if(tRaidByMembers[tName] ~= nil and tRaidByMembers[tName].group ~= tGroup) then
		if(tRaidByGroups[tGroup] == nil) then
			SetRaidSubgroup(tRaidByMembers[tName].index, tGroup)
		else
			if(tRaidByGroups[tGroup] < 5) then
				SetRaidSubgroup(tRaidByMembers[tName].index, tGroup)
			else
				for xName, xValue in pairs(tRaidByMembers) do
					if(xValue.group == tGroup and tRaidByName[xName] ~= tGroup) then
						SwapRaidSubgroup(tRaidByMembers[tName].index, xValue.index)
						break
					end
				end
			end
		end
	end

	return pIndex + 1
end

MultiBot.raidus.doGroupScore = function(pGroup)
	if(pGroup == nil or pGroup.group == nil) then return end
	local tScore = 0
	local tSize = 0

	for tKey, tSlot in pairs(pGroup.frames) do
		if(tSlot ~= nil and tSlot.bot ~= nil) then
			tScore = tScore + tSlot.bot.score
			tSize = tSize + 1
		end
	end

	pGroup.score = MultiBot.IF(tSize > 0, math.floor(tScore / tSize), 0)
	pGroup.setText("Title", "- " .. pGroup.group .. " : " .. pGroup.score .. " -")
end

MultiBot.raidus.doRaidScore = function()
	local tScore = 0
	local tSize = 0

	for tKey, tGroup in pairs(MultiBot.raidus.frames) do
		if(tGroup ~= nil and tGroup.score ~= nil and tGroup.score > 0) then
			tScore = tScore + tGroup.score
			tSize = tSize + 1
		end
	end

	tScore = MultiBot.IF(tSize > 0, math.floor(tScore / tSize), 0)
	MultiBot.raidus.setText("RaidScore", "RaidScore: " .. tScore)
end

MultiBot.raidus.doDrop = function(pObject, pParent, pX, pY, pWidth, pHeight, pSlot)
	pParent.frames[pSlot] = pObject
	pObject:ClearAllPoints()
	pObject:SetParent(pParent)
	pObject:SetPoint("BOTTOMRIGHT", pX, pY)
	pObject:SetSize(pWidth, pHeight)
	pObject.parent = pParent
	pObject.height = pHeight
	pObject.width = pWidth
	pObject.slot = pSlot
	pObject.x = pX
	pObject.y = pY
	MultiBot.raidus.doGroupScore(pParent)
	MultiBot.raidus.doRaidScore()
end

-- ---------------------------------------------------------------------------
--  AUTO BALANCE RAID
-- ---------------------------------------------------------------------------

-- Récupère la liste des bots candidats à l'auto-balance.
-- On prend d'abord les bots cochés dans MultiBar -> Units
-- Si aucun n'est coché, on prend tous les bots connus dans MultiBotGlobalSave
local function MultiBotRaidusCollectSelectedBots()
    local bots = {}
    local index = 1

    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local unitsFrame = multiBar and multiBar.frames and multiBar.frames["Units"]
    local unitButtons = unitsFrame and unitsFrame.buttons

    if unitButtons then
        for name, button in pairs(unitButtons) do
            if button.state and MultiBotGlobalSave and MultiBotGlobalSave[name] then
                local value = MultiBotGlobalSave[name]
                local details = MultiBot.doSplit(value, ",")
                local rawClass = details[5]
                if rawClass and rawClass ~= "" then
                    local bot = {}
                    bot.name = name
                    bot.race = details[1]
                    bot.gender = details[2]
                    bot.special = details[3]
                    bot.talents = details[4]
                    bot.class = rawClass
                    bot.level = tonumber(details[6]) or 0
                    bot.score = tonumber(details[7]) or 0
                    bot.role = MultiBotRaidusDetectRole(bot)

                    bots[index] = bot
                    index = index + 1
                end
            end
        end
    end

    -- Fallback : aucun bot sélectionné = on prend tout le monde
    if index == 1 and MultiBotGlobalSave then
        for name, value in pairs(MultiBotGlobalSave) do
            local details = MultiBot.doSplit(value, ",")
            local rawClass = details[5]
            if rawClass and rawClass ~= "" then
                local bot = {}
                bot.name = name
                bot.race = details[1]
                bot.gender = details[2]
                bot.special = details[3]
                bot.talents = details[4]
                bot.class = rawClass
                bot.level = tonumber(details[6]) or 0
                bot.score = tonumber(details[7]) or 0
                bot.role = MultiBotRaidusDetectRole(bot)

                bots[index] = bot
                index = index + 1
            end
        end
    end

    return bots
end

-- Applique une matrice de noms [groupe][slot] sur les frames Reidus,
-- en réutilisant la même logique de swap que le bouton "Load".
local function MultiBotRaidusApplyLayout(layout)
    local tPool = MultiBot.raidus.frames and MultiBot.raidus.frames["Pool"]
    if not tPool or not tPool.frames then
        return
    end

    for groupIndex = 1, 8 do
        local groupLayout = layout[groupIndex]
        if groupLayout then
            local tGroup = MultiBot.raidus.frames["Group" .. groupIndex]
            if tGroup and tGroup.frames then
                for slotIndex = 1, 5 do
                    local name = groupLayout[slotIndex]
                    if name and name ~= "-" then
                        local tDrop = tGroup.frames["Slot" .. slotIndex]
                        if tDrop then
                            for _, tDrag in pairs(tPool.frames) do
                                if tDrag.name ~= nil and tDrag.name == name then
                                    local tVisible = tDrag:IsVisible()
                                    local tParent = tDrag.parent
                                    local tHeight = tDrag.height
                                    local tWidth = tDrag.width
                                    local tSlot = tDrag.slot
                                    local tX = tDrag.x
                                    local tY = tDrag.y

                                    -- On place le bot dans le slot de raid
                                    MultiBot.raidus.doDrop(
                                        tDrag,
                                        tDrop.parent,
                                        tDrop.x,
                                        tDrop.y,
                                        tDrop.width,
                                        tDrop.height,
                                        tDrop.slot
                                    )
                                    if tDrop:IsVisible() then
                                        tDrag:Show()
                                    else
                                        tDrag:Hide()
                                    end

                                    -- Et on remet le frame de destination à la place d'origine
                                    MultiBot.raidus.doDrop(
                                        tDrop,
                                        tParent,
                                        tX,
                                        tY,
                                        tWidth,
                                        tHeight,
                                        tSlot
                                    )
                                    if tVisible then
                                        tDrop:Show()
                                    else
                                        tDrop:Hide()
                                    end

                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Tri générique par score décroissant puis niveau décroissant
local function MultiBotRaidusSortByScore(list)
    table.sort(list, function(a, b)
        local sa = a.score or 0
        local sb = b.score or 0
        if sa ~= sb then
            return sa > sb
        end
        local la = a.level or 0
        local lb = b.level or 0
        return la > lb
    end)
end

-- Auto balance :
--   mode == "score" : simple équilibrage par score
--   mode == "role"  : Tank / Heal / DPS
MultiBot.raidus.autoBalanceRaid = function(mode)
    -- On repart d'un état propre : pool reconstruite, groupes vidés
    if MultiBot.raidus.setRaidus then
        MultiBot.raidus.setRaidus()
    end

    local bots = MultiBotRaidusCollectSelectedBots()
    local botCount = #bots

    if botCount == 0 then
        SendChatMessage("Auto balance raid : aucun bot sélectionné.", "SAY")
        return
    end

    local groupsUsed = math.min(8, math.ceil(botCount / 5))
    if groupsUsed <= 0 then
        return
    end

    -- Matrice [groupe][slot] initialisée à "-"
    local layout = {}
    for g = 1, 8 do
        layout[g] = {}
        for s = 1, 5 do
            layout[g][s] = "-"
        end
    end

    if mode == "role" then
        -- Mode avancé Tank / Heal / DPS
        local tanks = {}
        local heals = {}
        local dps = {}

        for _, bot in ipairs(bots) do
            local role = bot.role or MultiBotRaidusDetectRole(bot)
            if role == "TANK" then
                table.insert(tanks, bot)
            elseif role == "HEAL" then
                table.insert(heals, bot)
            else
                table.insert(dps, bot)
            end
        end

        MultiBotRaidusSortByScore(tanks)
        MultiBotRaidusSortByScore(heals)
        MultiBotRaidusSortByScore(dps)

        local nextFreeSlot = {}
        for g = 1, groupsUsed do
            nextFreeSlot[g] = 1
        end

        local function placeListRoundRobin(list)
            local g = 1
            for _, bot in ipairs(list) do
                local tries = 0
                while tries < groupsUsed and nextFreeSlot[g] > 5 do
                    g = g + 1
                    if g > groupsUsed then
                        g = 1
                    end
                    tries = tries + 1
                end

                if nextFreeSlot[g] <= 5 then
                    layout[g][nextFreeSlot[g]] = bot.name
                    nextFreeSlot[g] = nextFreeSlot[g] + 1
                else
                    break
                end

                g = g + 1
                if g > groupsUsed then
                    g = 1
                end
            end
        end

        -- On commence par répartir les tanks, puis les heals, puis le reste
        placeListRoundRobin(tanks)
        placeListRoundRobin(heals)
        placeListRoundRobin(dps)
    else
        -- Mode score simple par défaut
        MultiBotRaidusSortByScore(bots)

        for index, bot in ipairs(bots) do
            local idx0 = index - 1
            local g = (idx0 % groupsUsed) + 1
            local s = math.floor(idx0 / groupsUsed) + 1
            if s <= 5 then
                layout[g][s] = bot.name
            end
        end
    end

    MultiBotRaidusApplyLayout(layout)
end