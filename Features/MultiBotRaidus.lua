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

local RAIDUS_GROUP_COUNT = 8
local RAIDUS_GROUP_SLOT_COUNT = 5
local RAIDUS_POOL_PAGE_SIZE = 11

MultiBot.raidus.save = ""
MultiBot.raidus.from = 1
MultiBot.raidus.to = RAIDUS_POOL_PAGE_SIZE
MultiBot.raidus.sortMode = "Score" -- "Score" | "Level" | "Class"

local function getRaidusGroupSlotFrame(groupIndex, slotIndex)
    local groupFrame = MultiBot.raidus.frames["Group" .. groupIndex]
    local groupSlots = groupFrame and groupFrame.frames
    if not groupSlots then
        return nil
    end

    return groupSlots["Slot" .. slotIndex]
end

local function forEachRaidusGroupSlot(visitor)
    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
            visitor(groupIndex, slotIndex, getRaidusGroupSlotFrame(groupIndex, slotIndex))
        end
    end
end

local function serializeRaidusLayoutFromFrames()
    local serializedGroups = {}

    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        local serializedNames = {}
        for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
            local slotFrame = getRaidusGroupSlotFrame(groupIndex, slotIndex)
            local slotName = MultiBot.IF(slotFrame and slotFrame.name ~= nil, slotFrame.name, "-")
            table.insert(serializedNames, slotName)
        end
        table.insert(serializedGroups, table.concat(serializedNames, ","))
    end

    return table.concat(serializedGroups, ";")
end

MultiBot.raidus.movButton("Move", -780, 790, 90, MultiBot.L("tips.move.raidus"))

MultiBot.raidus.wowButton("x", -13, 841, 16, 20, 12)
.doLeft = function(pButton)
	local tButton = MultiBot.frames["MultiBar"].frames["Main"].buttons["Raidus"]
	tButton.doLeft(tButton)
end


local RAIDUS_LAYOUT_SLOT_MAX = 8
local RAIDUS_LAYOUT_MIGRATION_VERSION = 1
local RAIDUS_LAYOUT_MIGRATION_KEY = "raidusLayoutsVersion"

-- Forward declaration keeps a local upvalue even if helpers are reordered later.
local getRaidusLayoutKey
local getLegacyRaidusLayoutStore

local function getRaidusLayoutStore(createLegacyIfMissing)
    local profile = MultiBot.db and MultiBot.db.profile
    if profile then
        profile.ui = profile.ui or {}
        profile.ui.raidusLayouts = profile.ui.raidusLayouts or {}
        return profile.ui.raidusLayouts
    end

    return getLegacyRaidusLayoutStore(createLegacyIfMissing)
end

getRaidusLayoutKey = function(slot)
    return "Raidus" .. (slot or "")
end

getLegacyRaidusLayoutStore = function(createIfMissing)
    local store = _G.MultiBotSave
    if type(store) ~= "table" then
        if not createIfMissing then
            return nil
        end

        store = {}
        _G.MultiBotSave = store
    end

    return store
end

local function cleanupLegacyRaidusLayoutKeys(legacyStore)
    if type(legacyStore) ~= "table" then
        return
    end

    for slotIndex = 1, RAIDUS_LAYOUT_SLOT_MAX do
        local slot = (slotIndex == 1) and nil or slotIndex
        local key = getRaidusLayoutKey(slot)
        if legacyStore[key] == "" then
            legacyStore[key] = nil
        end
    end
end

local function migrateLegacyRaidusLayoutsIfNeeded(store)
    if not MultiBot.GetProfileMigrationStore() then
        return
    end

    if not MultiBot.ShouldSyncLegacyState(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION) then
        return
    end

    local legacyStore = getLegacyRaidusLayoutStore(false)
    for slotIndex = 1, RAIDUS_LAYOUT_SLOT_MAX do
        local slot = (slotIndex == 1) and nil or slotIndex
        local key = getRaidusLayoutKey(slot)
        if store[key] == nil and legacyStore and legacyStore[key] ~= nil then
            store[key] = legacyStore[key]
        end
    end

    MultiBot.MarkLegacyStateMigrated(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION)

    -- Purge migrated legacy Raidus layout keys to avoid stale duplicate persistence.
    if type(legacyStore) == "table" then
        for slotIndex = 1, RAIDUS_LAYOUT_SLOT_MAX do
            local slot = (slotIndex == 1) and nil or slotIndex
            legacyStore[getRaidusLayoutKey(slot)] = nil
        end

        cleanupLegacyRaidusLayoutKeys(legacyStore)
    end
end

local function getRaidusLayoutValue(slot)
    local key = getRaidusLayoutKey(slot)
    local hasProfileStore = MultiBot.db and MultiBot.db.profile
    local store = getRaidusLayoutStore(not hasProfileStore)
    migrateLegacyRaidusLayoutsIfNeeded(store)

    local value = store[key]
    if value ~= nil then
        return value
    end

    local shouldSyncLegacy = MultiBot.ShouldSyncLegacyState(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION)
    if shouldSyncLegacy then
        local legacyStore = getLegacyRaidusLayoutStore(false)
        value = legacyStore and legacyStore[key]
        if value ~= nil then
            store[key] = value
        end
    end

    return value
end

local function setRaidusLayoutValue(slot, value)
    local key = getRaidusLayoutKey(slot)
    local store = getRaidusLayoutStore(true)
    migrateLegacyRaidusLayoutsIfNeeded(store)
    store[key] = value

    local shouldSyncLegacy = MultiBot.ShouldSyncLegacyState(RAIDUS_LAYOUT_MIGRATION_KEY, RAIDUS_LAYOUT_MIGRATION_VERSION)
    if shouldSyncLegacy then
        local legacyStore = getLegacyRaidusLayoutStore(true)
        legacyStore[key] = value
    end
end

local function parseRaidusLayoutData(layoutData)
    if type(layoutData) ~= "string" or layoutData == "" then
        return nil
    end

    local layout = {}
    local serializedGroups = MultiBot.doSplit(layoutData, ";")
    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        layout[groupIndex] = MultiBot.doSplit(serializedGroups[groupIndex], ",")
    end

    return layout
end

local function buildRaidusPoolFrameIndex(poolFrames)
    local index = {}
    if not poolFrames then
        return index
    end

    for _, dragFrame in pairs(poolFrames) do
        if dragFrame and dragFrame.name ~= nil and dragFrame.name ~= "" and dragFrame.name ~= "-" then
            index[dragFrame.name] = dragFrame
        end
    end

    return index
end

local function getRaidusPoolFrameByName(poolFrameIndex, name)
    if not poolFrameIndex or not name or name == "" or name == "-" then
        return nil
    end

    return poolFrameIndex[name]
end

local function swapRaidusFrameIntoSlot(dragFrame, dropFrame)
    if not dragFrame or not dropFrame then
        return
    end

    local wasDragVisible = dragFrame:IsVisible()
    local dragParent = dragFrame.parent
    local dragHeight = dragFrame.height
    local dragWidth = dragFrame.width
    local dragSlot = dragFrame.slot
    local dragX = dragFrame.x
    local dragY = dragFrame.y

    MultiBot.raidus.doDrop(dragFrame, dropFrame.parent, dropFrame.x, dropFrame.y, dropFrame.width, dropFrame.height, dropFrame.slot)
    if dropFrame:IsVisible() then dragFrame:Show() else dragFrame:Hide() end

    MultiBot.raidus.doDrop(dropFrame, dragParent, dragX, dragY, dragWidth, dragHeight, dragSlot)
    if wasDragVisible then dropFrame:Show() else dropFrame:Hide() end
end

local function applyRaidusLayout(layout)
    if type(layout) ~= "table" then
        return
    end

    local frames = MultiBot.raidus and MultiBot.raidus.frames
    local pool = frames and frames["Pool"]
    local poolFrames = pool and pool.frames
    if not poolFrames then
        return
    end
    local poolFrameIndex = buildRaidusPoolFrameIndex(poolFrames)

    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        local groupLayout = layout[groupIndex]

        if groupLayout then
            for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
                local botName = groupLayout[slotIndex]
                if botName and botName ~= "-" then
                    local dropFrame = getRaidusGroupSlotFrame(groupIndex, slotIndex)
                    local dragFrame = getRaidusPoolFrameByName(poolFrameIndex, botName)
                    if dropFrame and dragFrame then
                        swapRaidusFrameIntoSlot(dragFrame, dropFrame)
                    end
                end
            end
        end
    end
end

MultiBot.raidus.wowButton("Load", -762, 360, 80, 20, 12)
.doLeft = function(pButton)
	local layoutData = getRaidusLayoutValue(MultiBot.raidus.save)
	if(layoutData == nil or layoutData == "") then
		SendChatMessage(MultiBot.L("info.nothing"), "SAY")
		return
	end

	local layout = parseRaidusLayoutData(layoutData)
	applyRaidusLayout(layout)
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
slotButton.tip = MultiBot.L("tips.raidus.slot")
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
    GameTooltip:SetText(MultiBot.L("tips.raidus.score"), 1, 1, 1, true)
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
    GameTooltip:SetText(MultiBot.L("tips.raidus.level"), 1, 1, 1, true)
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
    GameTooltip:SetText(MultiBot.L("tips.raidus.class"), 1, 1, 1, true)
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
	setRaidusLayoutValue(MultiBot.raidus.save, serializeRaidusLayoutFromFrames())
	SendChatMessage("I wrote it down.", "SAY")
end

local function collectRaidusApplyInviteList(raidByName, selfName)
    local inviteList = {}
    local selectedCount = 0
    local selectedNames = {}

    for unitName, unitButton in pairs(MultiBot.frames["MultiBar"].frames["Units"].buttons) do
        if unitButton.state then
            selectedCount = selectedCount + 1
            selectedNames[unitName] = true
        elseif unitName ~= selfName and raidByName[unitName] ~= nil then
            table.insert(inviteList, unitName)
        end
    end

    local fallbackInviteList = {}
    local hasLayoutOnly = false
    for raidName, _ in pairs(raidByName) do
        if raidName ~= selfName then
            if not selectedNames[raidName] then
                hasLayoutOnly = true
            end
            if not MultiBot.isMember(raidName) then
                table.insert(fallbackInviteList, raidName)
            end
        end
    end

    local usedLayoutFallback = false
    if (selectedCount == 0 or hasLayoutOnly) and #fallbackInviteList > 0 then
        inviteList = fallbackInviteList
        usedLayoutFallback = true
    end

    return selectedCount, inviteList, usedLayoutFallback
end

local function removeRaidusMembersOutsideLayout(raidByMembers, raidByName, selfName)
    for raidMemberName, _ in pairs(raidByMembers) do
        if raidMemberName ~= selfName and raidByName[raidMemberName] == nil then
            if MultiBot.isMember(raidMemberName) then
                UninviteUnit(raidMemberName)
            end
            SendChatMessage(".playerbot bot remove " .. raidMemberName, "SAY")
        end
    end
end

local function announceRaidusApplySelection(selectedCount, inviteList, usedLayoutFallback)
    local inviteCount = #inviteList
    local selectedList = inviteCount > 0 and table.concat(inviteList, ", ") or ""

    if usedLayoutFallback then
        SendChatMessage("Raidus Apply: using layout list, selected=" .. selectedCount .. " toInvite=" .. inviteCount, "SAY")
    else
        SendChatMessage("Raidus Apply: selected=" .. selectedCount .. " toInvite=" .. inviteCount, "SAY")
    end

    if selectedList ~= "" then
        SendChatMessage("Raidus Apply list: " .. selectedList, "SAY")
    end
end

local function startRaidusApplyInviteOrSort(inviteCount)
    if inviteCount > 0 then
        SendChatMessage(MultiBot.L("info.starting"), "SAY")
        MultiBot.timer.invite.roster = "raidus"
        MultiBot.timer.invite.needs = inviteCount
        MultiBot.timer.invite.index = 1
        MultiBot.auto.invite = true
    else
        MultiBot.timer.sort.elapsed = 0
        MultiBot.timer.sort.index = 1
        MultiBot.timer.sort.needs = 0
        MultiBot.auto.sort = true
    end
end

MultiBot.raidus.wowButton("Apply", -514, 360, 80, 20, 12)
.doLeft = function(pButton)
    local tRaidByIndex, tRaidByName = MultiBot.raidus.getRaidTarget()
    if(tRaidByIndex == nil or tRaidByName == nil) then return end

    local tSelf = UnitName("player")
    local tSelected, inviteList, usedLayoutFallback = collectRaidusApplyInviteList(tRaidByName, tSelf)

    MultiBot.index.raidus = inviteList
    local tNeeds = #inviteList

    local tRaidByMembers = MultiBot.raidus.getRaidState()
    removeRaidusMembersOutsideLayout(tRaidByMembers, tRaidByName, tSelf)

    announceRaidusApplySelection(tSelected, inviteList, usedLayoutFallback)
    startRaidusApplyInviteOrSort(tNeeds)
end


-- Bouton Auto-balance raid :
-- Clic gauche  : équilibrage simple par score
-- Clic droit   : équilibrage avancé Tank / Heal / DPS
local btnAuto = MultiBot.raidus.wowButton("Auto", -431, 360, 80, 20, 12)

btnAuto:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(MultiBot.L("tips.raidus.autobalance"), 1, 1, 1, true)
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

-- Update pool visibility according to current Raidus page window.
local function refreshRaidusPoolPageVisibility()
	local poolFrames = MultiBot.raidus.frames["Pool"].frames
	for slotIndex = 1, MultiBot.raidus.slots, 1 do
		local poolSlot = poolFrames["Slot" .. slotIndex]
		if(slotIndex >= MultiBot.raidus.from and slotIndex <= MultiBot.raidus.to) then poolSlot:Show() else poolSlot:Hide() end
	end
end

MultiBot.raidus.wowButton("<", -40, 360, 16, 20, 12)
.doLeft = function(pButton)
	MultiBot.raidus.from = MultiBot.raidus.from - RAIDUS_POOL_PAGE_SIZE
	MultiBot.raidus.to = MultiBot.raidus.to - RAIDUS_POOL_PAGE_SIZE

	if(MultiBot.raidus.to < 1) then
		MultiBot.raidus.from = MultiBot.raidus.slots - (RAIDUS_POOL_PAGE_SIZE - 1)
		MultiBot.raidus.to = MultiBot.raidus.slots
	end

	refreshRaidusPoolPageVisibility()
end

MultiBot.raidus.wowButton(">", -20, 360, 16, 20, 12)
.doLeft = function(pButton)
	MultiBot.raidus.from = MultiBot.raidus.from + RAIDUS_POOL_PAGE_SIZE
	MultiBot.raidus.to = MultiBot.raidus.to + RAIDUS_POOL_PAGE_SIZE

	if(MultiBot.raidus.from > MultiBot.raidus.slots) then
		MultiBot.raidus.from = 1
		MultiBot.raidus.to = RAIDUS_POOL_PAGE_SIZE
	end

	refreshRaidusPoolPageVisibility()
end

MultiBot.raidus.getDrop = function()
	for i = 1, RAIDUS_GROUP_COUNT, 1 do
		local tGroup = MultiBot.raidus.frames["Group" .. i]

		if(MouseIsOver(tGroup)) then
			for j = 1, RAIDUS_GROUP_SLOT_COUNT, 1 do
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

-- SETTER --

local function getRaidusGlobalBotStore()
    if MultiBot.GetGlobalBotStore then
        return MultiBot.GetGlobalBotStore()
    end

    if type(_G.MultiBotGlobalSave) ~= "table" then
        _G.MultiBotGlobalSave = {}
    end

    return _G.MultiBotGlobalSave
end

local function buildRaidusBotFromGlobalSave(name, value)
    if not value then
        return nil
    end

    local details = MultiBot.doSplit(value, ",")
    local rawClass = details[5]
    if not rawClass or rawClass == "" then
        return nil
    end

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
    return bot
end

local function appendRaidusBotIfValid(bots, name, value)
    local bot = buildRaidusBotFromGlobalSave(name, value)
    if bot then
        table.insert(bots, bot)
    end
end

MultiBot.raidus.setRaidus = function()
	local tPool = MultiBot.raidus.frames["Pool"]
	local tSlot = 1
	local tY = 426

	for k,v in pairs(tPool.frames) do v:Hide() end

	local tBots = {}
	-- Mode de tri actuel ("Score", "Level", "Class")
	local sortMode = MultiBot.raidus.sortMode or "Score"

    for tName, tValue in pairs(getRaidusGlobalBotStore()) do
        local tBot = buildRaidusBotFromGlobalSave(tName, tValue)
        if tBot then
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

			table.insert(tBots, tBot)
		end
	end

	table.sort(tBots, function(a, b)
		return (a.sort or 0) > (b.sort or 0)
	end)

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
                    SendChatMessage(".playerbot bot remove " .. name, "SAY")
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

		if(tSlot > RAIDUS_POOL_PAGE_SIZE) then tFrame:Hide() else tFrame:Show() end
		tY = MultiBot.IF(tSlot % RAIDUS_POOL_PAGE_SIZE == 0, 426, tY - 40)
		tSlot = tSlot + 1
	end

	for i = tSlot % RAIDUS_POOL_PAGE_SIZE, RAIDUS_POOL_PAGE_SIZE, 1 do
		local tFrame = tPool.addFrame("Slot" .. tSlot, 0, tY, 28, 160, 36)
		tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
		tFrame.slot = "Slot" .. tSlot
		if(tSlot > RAIDUS_POOL_PAGE_SIZE) then tFrame:Hide() else tFrame:Show() end
		tSlot = tSlot + 1
		tY = tY - 40
	end

	MultiBot.raidus.slots = tSlot - 1

	for i = 1, RAIDUS_GROUP_COUNT, 1 do
		local tGroup = MultiBot.raidus.frames["Group" .. i]
		local groupY = 182

		tGroup.addText("Title", "- Group" .. i .. " : 0 -", "BOTTOM", 0, 223, 12)
		tGroup.group = "Group" .. i
		tGroup.score = 0

		for j = 1, RAIDUS_GROUP_SLOT_COUNT, 1 do
			local tFrame = tGroup.addFrame("Slot" .. j, 0, groupY, 28, 160, 36)
			tFrame.addTexture("Interface\\AddOns\\MultiBot\\Textures\\grey.blp")
			tFrame.slot = "Slot" .. j
			groupY = groupY - 40
		end
	end
end

-- GETTER --

local function buildRaidusCurrentRosterState()
	local raidByMembers = {}
	local raidByGroups = {}
	local raidCount = GetNumRaidMembers() or 0

	for raidIndex = 1, raidCount do
		local raidName, _, raidGroup = GetRaidRosterInfo(raidIndex)
		if raidName and raidGroup then
			raidByMembers[raidName] = { index = raidIndex, group = raidGroup }
			raidByGroups[raidGroup] = (raidByGroups[raidGroup] or 0) + 1
		end
	end

	return raidByMembers, raidByGroups
end

MultiBot.raidus.getRaidState = function()
	return buildRaidusCurrentRosterState()
end

MultiBot.raidus.getRaidTarget = function()
	local tRaidByIndex = {}
	local tRaidByName = {}
	local tIndex = 1

	local tSelf = UnitName("player")
	local tUser = true
	local tBots = true

	forEachRaidusGroupSlot(function(groupIndex, slotIndex, slotFrame)
		local slotName = slotFrame and slotFrame.name
		if(slotName ~= nil) then
			if(slotName == tSelf) then tUser = false end
			tRaidByIndex[tIndex] = { name = slotName, group = groupIndex }
			tRaidByName[slotName] = groupIndex
			tIndex = tIndex + 1
			tBots = false
		end
	end)

	if(tBots) then return SendChatMessage("There is no Bot in the Raid", "SAY") end
	if(tUser) then return SendChatMessage("I must be in the Raid!", "SAY") end
	return tRaidByIndex, tRaidByName
end

local function getRaidusTargetAndState()
	local raidByIndex, raidByName = MultiBot.raidus.getRaidTarget()
	if not raidByIndex or not raidByName then
		return nil
	end

	local raidByMembers, raidByGroups = buildRaidusCurrentRosterState()
	return {
		raidByIndex = raidByIndex,
		raidByName = raidByName,
		raidByMembers = raidByMembers,
		raidByGroups = raidByGroups,
	}
end

local function findRaidusSwapCandidateIndex(raidByMembers, raidByName, expectedGroup)
	for memberName, memberData in pairs(raidByMembers) do
		if memberData.group == expectedGroup and raidByName[memberName] ~= expectedGroup then
			return memberData.index
		end
	end

	return nil
end

local function moveRaidusMemberToTargetGroup(memberData, expectedGroup, raidByGroups, raidByMembers, raidByName)
	if not memberData or memberData.group == expectedGroup then
		return false
	end

	local targetSize = raidByGroups[expectedGroup] or 0
	if targetSize < RAIDUS_GROUP_SLOT_COUNT then
		SetRaidSubgroup(memberData.index, expectedGroup)
		return true
	end

	local swapIndex = findRaidusSwapCandidateIndex(raidByMembers, raidByName, expectedGroup)
	if swapIndex then
		SwapRaidSubgroup(memberData.index, swapIndex)
		return true
	end

	return false
end

-- EVENTS --

MultiBot.raidus.doRaidSortCheck = function()
	local raidContext = getRaidusTargetAndState()
	if not raidContext then
		return nil
	end

	for targetName, targetGroup in pairs(raidContext.raidByName) do
		local memberData = raidContext.raidByMembers[targetName]
		if memberData and memberData.group ~= targetGroup then
			return 1
		end
	end

	return nil
end

MultiBot.raidus.doRaidSort = function(pIndex)
	local raidContext = getRaidusTargetAndState()
	if not raidContext then
		return nil
	end

	local targetEntry = raidContext.raidByIndex[pIndex]
	if not targetEntry then
		return nil
	end

	local memberData = raidContext.raidByMembers[targetEntry.name]
	moveRaidusMemberToTargetGroup(
		memberData,
		targetEntry.group,
		raidContext.raidByGroups,
		raidContext.raidByMembers,
		raidContext.raidByName
	)

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

    local multiBar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local unitsFrame = multiBar and multiBar.frames and multiBar.frames["Units"]
    local unitButtons = unitsFrame and unitsFrame.buttons

    local globalBots = getRaidusGlobalBotStore()

    if unitButtons then
        for name, button in pairs(unitButtons) do
            if button.state then
                appendRaidusBotIfValid(bots, name, globalBots[name])
            end
        end
    end

    -- Fallback : aucun bot sélectionné = on prend tout le monde
    if #bots == 0 then
        for name, value in pairs(globalBots) do
            appendRaidusBotIfValid(bots, name, value)
        end
    end

    return bots
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

local function createEmptyRaidusLayout()
    local layout = {}
    for groupIndex = 1, RAIDUS_GROUP_COUNT do
        layout[groupIndex] = {}
        for slotIndex = 1, RAIDUS_GROUP_SLOT_COUNT do
            layout[groupIndex][slotIndex] = "-"
        end
    end
    return layout
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
        SendChatMessage("Auto balance raid : No bots selectd", "SAY")
        return
    end

    local groupsUsed = math.min(RAIDUS_GROUP_COUNT, math.ceil(botCount / RAIDUS_GROUP_SLOT_COUNT))
    if groupsUsed <= 0 then
        return
    end

    -- Matrice [groupe][slot] initialisée à "-"
    local layout = createEmptyRaidusLayout()

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
                while tries < groupsUsed and nextFreeSlot[g] > RAIDUS_GROUP_SLOT_COUNT do
                    g = g + 1
                    if g > groupsUsed then
                        g = 1
                    end
                    tries = tries + 1
                end

                if nextFreeSlot[g] <= RAIDUS_GROUP_SLOT_COUNT then
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
            if s <= RAIDUS_GROUP_SLOT_COUNT then
                layout[g][s] = bot.name
            end
        end
    end

     applyRaidusLayout(layout)
end