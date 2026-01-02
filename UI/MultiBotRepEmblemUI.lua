-- MultiBot Reputations & Emblems UI

local MBRepEmblems = MultiBot.RepEmblems or {}
MultiBot.RepEmblems = MBRepEmblems

MBRepEmblems.cache = MBRepEmblems.cache or {}
MBRepEmblems.currentBot = MBRepEmblems.currentBot or nil
MBRepEmblems.currentTab = MBRepEmblems.currentTab or "reputations"

local LINE_HEIGHT = 18
local NAME_WIDTH = 160
local BAR_WIDTH = 200
local VISIBLE_LINES = 18

local REPUTATION_GROUPS = {
	{
		key = "wrath",
		label = "Wrath of the Lich King",
		subgroups = {
			{ key = "horde", label = "Horde", icon = "Interface\\TARGETINGFRAME\\UI-PVP-HORDE" },
			{ key = "alliance", label = "Alliance", icon = "Interface\\TARGETINGFRAME\\UI-PVP-ALLIANCE" },
			{ key = "both", label = "Both", icon = "Interface\\TARGETINGFRAME\\UI-PVP-FFA" },
		},
		factions = {
			["horde expedition"] = "horde",
			["warsong offensive"] = "horde",
			["the taunka"] = "horde",
			["the sunreavers"] = "horde",
			["the hand of vengeance"] = "horde",
			["alliance vanguard"] = "alliance",
			["explorers' league"] = "alliance",
			["the frostborn"] = "alliance",
			["the silver covenant"] = "alliance",
			["valiance expedition"] = "alliance",
			["frenzyheart tribe"] = "both",
			["the oracles"] = "both",
			["the sons of hodir"] = "both",
			["the kalu'ak"] = "both",
			["kirin tor"] = "both",
			["knights of the ebon blade"] = "both",
			["argent crusade"] = "both",
			["the wyrmrest accord"] = "both",
			["the ashen verdict"] = "both",
		},
	},
	{
		key = "burningcrusade",
		label = "Burning Crusade",
		subgroups = {
			{ key = "horde", label = "Horde", icon = "Interface\\TARGETINGFRAME\\UI-PVP-HORDE" },
			{ key = "alliance", label = "Alliance", icon = "Interface\\TARGETINGFRAME\\UI-PVP-ALLIANCE" },
			{ key = "both", label = "Both", icon = "Interface\\TARGETINGFRAME\\UI-PVP-FFA" },
		},
		factions = {
			["thrallmar"] = "horde",
			["the mag'har"] = "horde",
			["tranquillien"] = "horde",
			["honor hold"] = "alliance",
			["kurenai"] = "alliance",
			["cenarion expedition"] = "both",
			["ogri'la"] = "both",
			["netherwing"] = "both",
			["the consortium"] = "both",
			["sporeggar"] = "both",
			["lower city"] = "both",
			["the sha'tar"] = "both",
			["shattered sun offensive"] = "both",
			["sha'tari skyguard"] = "both",
			["the scryers"] = "both",
			["the aldor"] = "both",
			["keepers of time"] = "both",
			["the violet eye"] = "both",
			["ashtongue deathsworn"] = "both",
			["the scale of the sands"] = "both",
		},
	},
	{
		key = "classic",
		label = "Classic",
		subgroups = {
			{ key = "horde", label = "Horde", icon = "Interface\\TARGETINGFRAME\\UI-PVP-HORDE" },
			{ key = "alliance", label = "Alliance", icon = "Interface\\TARGETINGFRAME\\UI-PVP-ALLIANCE" },
			{ key = "both", label = "Both", icon = "Interface\\TARGETINGFRAME\\UI-PVP-FFA" },
		},
		factions = {
			["orgrimmar"] = "horde",
			["thunder bluff"] = "horde",
			["darkspear trolls"] = "horde",
			["undercity"] = "horde",
			["silvermoon city"] = "horde",
			["bilgewater cartel"] = "horde",
			["huojin pandaren"] = "horde",
			["dark talons"] = "horde",
			["warsong outriders"] = "horde",
			["the defilers"] = "horde",
			["frostwolf clan"] = "horde",
			["brawl'gar arena (season 4)"] = "horde",
			["stormwind"] = "alliance",
			["ironforge"] = "alliance",
			["darnassus"] = "alliance",
			["gnomeregan"] = "alliance",
			["exodar"] = "alliance",
			["gilneas"] = "alliance",
			["tushui pandaren"] = "alliance",
			["obsidian warders"] = "alliance",
			["silverwing sentinels"] = "alliance",
			["the league of arathor"] = "alliance",
			["stormpike guard"] = "alliance",
			["bizmo's brawlpub (season 4)"] = "alliance",
			["argent dawn"] = "both",
			["cenarion circle"] = "both",
			["booty bay"] = "both",
			["ratchet"] = "both",
			["gadgetzan"] = "both",
			["everlook"] = "both",
			["bloodsail buccaneers"] = "both",
			["darkmoon faire"] = "both",
			["thorium brotherhood"] = "both",
			["brood of nozdormu"] = "both",
			["hydraxian waterlords"] = "both",
			["ravenholdt"] = "both",
			["syndicate"] = "both",
			["timbermaw hold"] = "both",
			["wintersaber trainers"] = "both",
			["gelkis clan centaur"] = "both",
			["magram clan centaur"] = "both",
		},
	},
}

local EMBLEM_ICON_BY_ID = {
	[29434] = "spell_holy_championsbond",
	[40752] = "spell_holy_proclaimchampion",
	[40753] = "spell_holy_proclaimchampion_02",
	[45624] = "spell_holy_championsgrace",
	[47241] = "spell_holy_summonchampion",
	[49426] = "inv_misc_frostemblem_01",
}

local function NormalizeFactionName(name)
	return string.lower(strtrim(name or ""))
end

local function BuildReputationView(entries)
	local grouped = {}
	local remaining = {}

	for _, entry in ipairs(entries) do
		if not entry or not entry.name then
			return entries
		end
	end

	for _, entry in ipairs(entries) do
		remaining[NormalizeFactionName(entry.name)] = entry
	end

	local view = {}
	for _, group in ipairs(REPUTATION_GROUPS) do
		local groupEntries = {}
		for _, entry in ipairs(entries) do
			local key = NormalizeFactionName(entry.name)
			local subgroup = group.factions[key]
			if subgroup then
				groupEntries[subgroup] = groupEntries[subgroup] or {}
				table.insert(groupEntries[subgroup], entry)
				remaining[key] = nil
			end
		end

		local hasAny = false
		for _, subgroup in ipairs(group.subgroups) do
			if groupEntries[subgroup.key] and #groupEntries[subgroup.key] > 0 then
				hasAny = true
				break
			end
		end

		if hasAny then
			table.insert(view, { type = "header", name = group.label })
			for _, subgroup in ipairs(group.subgroups) do
				local list = groupEntries[subgroup.key]
				if list and #list > 0 then
					table.insert(view, { type = "subheader", name = subgroup.label, icon = subgroup.icon })
					for _, entry in ipairs(list) do
						table.insert(view, entry)
					end
				end
			end
		end
	end

	local leftovers = {}
	for _, entry in pairs(remaining) do
		table.insert(leftovers, entry)
	end
	table.sort(leftovers, function(a, b)
		return (a.name or "") < (b.name or "")
	end)

	if #leftovers > 0 then
		table.insert(view, { type = "header", name = "Other" })
		for _, entry in ipairs(leftovers) do
			table.insert(view, entry)
		end
	end

	return view
end

local function NormalizeSenderName(sender)
	if not sender or sender == "" then
		return ""
	end

	local simpleName = sender:match("([^%-]+)") or sender
	simpleName = simpleName:match("([^%.%-]+)") or simpleName
	return simpleName
end

local function CleanMessage(msg)
	if type(msg) ~= "string" then
		return ""
	end

	return (msg
		:gsub("|c%x%x%x%x%x%x%x%x", "")
		:gsub("|r", "")
		:gsub("\r?\n", " ")
		:gsub("^%s+", "")
		:gsub("%s+$", ""))
end

local function GetHeader(clean)
	local lower = clean:lower()
	if lower:match("^===%s*reputations%s*===%s*$") then
		return "reputations"
	end
	if lower:match("^===%s*emblems%s*===%s*$") then
		return "emblems"
	end
	return nil
end

local function EnsureState(botName)
	if not MBRepEmblems.cache[botName] then
		MBRepEmblems.cache[botName] = {
			reputations = {},
			emblems = {},
			repIndex = {},
			emblemIndex = {},
			collecting = nil,
		}
	end

	return MBRepEmblems.cache[botName]
end

local function ResetSection(state, section)
	state[section] = {}
	if section == "reputations" then
		state.repIndex = {}
	else
		state.emblemIndex = {}
	end
end

local function Upsert(list, indexMap, key, entry)
	local index = indexMap[key]
	if index then
		list[index] = entry
	else
		indexMap[key] = #list + 1
		list[#list + 1] = entry
	end
end

local function ParseReputationLine(clean)
	local name, status, current, total = clean:match("^%s*([^:]+)%s*:%s*([^%(]+)%s*%((%d+)%s*/%s*(%d+)%)")
	if not name then
		return nil
	end

	return {
		name = strtrim(name),
		status = strtrim(status),
		current = tonumber(current),
		total = tonumber(total),
	}
end

local function ParseEmblemLine(clean)
	local count = tonumber(clean:match("x(%d+)"))
	local itemId = tonumber(clean:match("Hitem:(%d+)"))

	local name = ""
	if itemId then
		local itemName = GetItemInfo(itemId)
		if itemName then
			name = itemName
		else
			local emblemMap = {
				[29434] = { name = MultiBot.tips.every.BadgeofJustice, icon = "spell_holy_championsbond" },
				[40752] = { name = MultiBot.tips.every.EmblemofHeroism, icon = "spell_holy_proclaimchampion" },
				[40753] = { name = MultiBot.tips.every.EmblemofValor, icon = "spell_holy_proclaimchampion_02" },
				[45624] = { name = MultiBot.tips.every.EmblemofConquest, icon = "spell_holy_championsgrace" },
				[47241] = { name = MultiBot.tips.every.EmblemofTriumph, icon = "spell_holy_summonchampion" },
				[49426] = { name = MultiBot.tips.every.EmblemofFrost, icon = "inv_misc_frostemblem_01" },
			}
			local fallback = emblemMap[itemId]
			if fallback then
				name = fallback.name
				icon = fallback.icon
			else
				name = "Item " .. itemId
			end
		end
	else
		name = clean:match("^%s*([^%-]+)%s*%-%s*%[")
			or clean:match("^%s*([^%[]+)%[")
			or clean
		name = name and strtrim(name) or ""
	end

	if name == "" then
		return nil
	end

	if not icon and itemId then
		icon = GetItemIcon(itemId)
	end

	return {
		name = name,
		count = count,
		icon = icon,
		itemId = itemId,
	}
end

local function CreateStyledFrame()
	local f = CreateFrame("Frame", "MultiBotRepEmblemFrame", UIParent)
	f:SetSize(440, 520)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:Hide()
	f:EnableMouse(true)
	f:SetMovable(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self) self:StartMoving() end)
	f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

	f:SetBackdrop({
		bgFile = "Interface\\RAIDFRAME\\UI-RaidFrame-GroupBg",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	})
	if f.SetBackdropColor then f:SetBackdropColor(0, 0, 0, 1) end
	if f.SetBackdropBorderColor then f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end

	local titleBg = f:CreateTexture(nil, "ARTWORK")
	titleBg:SetTexture(MultiBot.SafeTexturePath("Interface\\DialogFrame\\UI-DialogBox-Header"))
	titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -6)
	titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -6)
	titleBg:SetHeight(48)

	f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.Title:SetPoint("TOP", titleBg, "TOP", 0, -10)
	f.Title:SetText(MultiBot.tips.every.repemblemstitle or "Reputations & Emblems")

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
	close:SetScript("OnClick", function() f:Hide() end)

	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
	content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 64)

	f.BotLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.BotLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	f.BotLabel:SetText(MultiBot.tips.every.repemblemsbot or "Bot")

	f.BotName = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	f.BotName:SetPoint("LEFT", f.BotLabel, "RIGHT", 8, 0)
	f.BotName:SetText("-")

	local botDropDown = CreateFrame("Frame", "MultiBotRepEmblemBotDropDown", content, "UIDropDownMenuTemplate")
	botDropDown:SetPoint("TOPRIGHT", content, "TOPRIGHT", 18, 10)
	UIDropDownMenu_SetWidth(botDropDown, 180)
	UIDropDownMenu_SetText(botDropDown, MultiBot.tips.every.repemblemsselectbot or "Bot")
	f.BotDropDown = botDropDown

	f.ColumnLeft = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.ColumnLeft:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -26)
	f.ColumnLeft:SetText(MultiBot.tips.every.repemblemsfaction or "Faction")

	f.ColumnRight = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	f.ColumnRight:SetPoint("TOPRIGHT", content, "TOPRIGHT", -126, -26)
	f.ColumnRight:SetText(MultiBot.tips.every.repemblemsstanding or "Standing")

	local sep = content:CreateTexture(nil, "ARTWORK")
	sep:SetHeight(1)
	sep:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -42)
	sep:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -42)
	sep:SetTexture(0.5, 0.5, 0.5, 0.6)

	local scroll = CreateFrame(
		"ScrollFrame",
		"MultiBotRepEmblemScrollFrame",
		content,
		"FauxScrollFrameTemplate"
	)
	scroll:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -48)
	scroll:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", -26, 10)
	f.ScrollFrame = scroll

	f.Rows = {}
	for i = 1, VISIBLE_LINES do
		local row = CreateFrame("Frame", nil, content)
		row:SetHeight(LINE_HEIGHT)
		row:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -48 - (i - 1) * LINE_HEIGHT)
		row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -6, -48 - (i - 1) * LINE_HEIGHT)

		row.left = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row.left:SetPoint("LEFT", row, "LEFT", 0, 0)
		row.left:SetJustifyH("LEFT")
		row.left:SetWidth(NAME_WIDTH)

		row.icon = row:CreateTexture(nil, "OVERLAY")
		row.icon:SetSize(12, 12)
		row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
		row.icon:Hide()

		row.right = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		row.right:SetPoint("RIGHT", row, "RIGHT", -20, 0)
		row.right:SetJustifyH("RIGHT")

		row.emblemIcon = row:CreateTexture(nil, "OVERLAY")
		row.emblemIcon:SetSize(14, 14)
		row.emblemIcon:SetPoint("RIGHT", row, "RIGHT", 0, 0)
		row.emblemIcon:Hide()

		row.bar = CreateFrame("StatusBar", nil, row)
		row.bar:SetHeight(12)
		row.bar:SetPoint("LEFT", row, "LEFT", NAME_WIDTH + 10, 0)
		row.bar:SetWidth(BAR_WIDTH)
		row.bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		row.bar:EnableMouse(true)
		row.bar:SetMinMaxValues(0, 1)
		row.bar:SetValue(0)
		row.bar:Hide()

		row.barBg = row.bar:CreateTexture(nil, "BACKGROUND")
		row.barBg:SetAllPoints(row.bar)
		row.barBg:SetTexture(MultiBot.SafeTexturePath("Interface\\TARGETINGFRAME\\UI-StatusBar"))
		row.barBg:SetVertexColor(0.2, 0.2, 0.2, 0.7)

		row.barText = row.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		row.barText:SetPoint("CENTER", row.bar, "CENTER", 0, 0)
		row.barText:SetJustifyH("CENTER")

		f.Rows[i] = row
	end

	scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, LINE_HEIGHT, function()
			if MBRepEmblems.Refresh then
				MBRepEmblems:Refresh()
			end
		end)
	end)

	local tabs = {}
	local tabNames = {
		MultiBot.tips.every.repemblemsreptab or "Reputations",
		MultiBot.tips.every.repemblemsemtab or "Emblems",
	}

	for i, name in ipairs(tabNames) do
		local template = (_G["CharacterFrameTabButtonTemplate"] and "CharacterFrameTabButtonTemplate")
			or "UIPanelButtonTemplate"
		local tab = CreateFrame("Button", f:GetName() .. "Tab" .. i, f, template)
		tab:SetSize(110, 22)
		tab:SetText(name)
		tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12 + (i - 1) * 118, 12)
		tab.id = i
		tab:SetScript("OnClick", function(self)
			if MBRepEmblems.SelectTab then
				MBRepEmblems:SelectTab(self.id)
			end
		end)
		tabs[i] = tab
	end

	f.Tabs = tabs

	return f
end

function MBRepEmblems:EnsureFrame()
	if self.Frame then
		return
	end

	self.Frame = CreateStyledFrame()
	if MultiBot.PromoteFrame then
		MultiBot.PromoteFrame(self.Frame)
	end
	self:SelectTab(self.currentTab == "emblems" and 2 or 1)
end

function MBRepEmblems:SetCurrentBot(botName)
	self.currentBot = botName
	self:Refresh()
	self:UpdateDropDown()
end

function MBRepEmblems:GetEntries()
	if not self.currentBot then
		return {}
	end

	local state = self.cache[self.currentBot]
	if not state then
		return {}
	end

	if self.currentTab == "emblems" then
		return state.emblems or {}
	end

	return state.reputations or {}
end

function MBRepEmblems:SelectTab(tabId)
	self.currentTab = (tabId == 2) and "emblems" or "reputations"

	if self.Frame and self.Frame.Tabs then
		for idx, tab in ipairs(self.Frame.Tabs) do
			if tab.LockHighlight then
				if idx == tabId then tab:LockHighlight() else tab:UnlockHighlight() end
			elseif idx == tabId and tab.Disable then
				tab:Disable()
			elseif tab.Enable then
				tab:Enable()
			end
		end
	end

	self:Refresh()
end

function MBRepEmblems:Refresh()
	if not self.Frame then
		return
	end

	local repColor = {
		hated = { 0.8, 0.1, 0.1 },
		hostile = { 0.9, 0.2, 0.2 },
		unfriendly = { 0.85, 0.3, 0.2 },
		neutral = { 0.9, 0.8, 0.2 },
		friendly = { 0.2, 0.8, 0.2 },
		honored = { 0.2, 0.8, 0.6 },
		revered = { 0.2, 0.5, 0.9 },
		exalted = { 0.6, 0.2, 0.9 },
	}

	local frame = self.Frame
	local entries = self:GetEntries()
	if self.currentTab == "reputations" then
		entries = BuildReputationView(entries)
	end
	local scroll = frame.ScrollFrame
	local offset = FauxScrollFrame_GetOffset(scroll) or 0

	FauxScrollFrame_Update(scroll, #entries, VISIBLE_LINES, LINE_HEIGHT)

	if self.currentTab == "emblems" then
		frame.ColumnLeft:SetText(MultiBot.tips.every.repemblemsemblem or "Emblem")
		frame.ColumnRight:SetText(MultiBot.tips.every.repemblemscount or "Count")
	else
		frame.ColumnLeft:SetText(MultiBot.tips.every.repemblemsfaction or "Faction")
		frame.ColumnRight:SetText(MultiBot.tips.every.repemblemsstanding or "Standing")
	end

	if frame.BotName then
		frame.BotName:SetText(self.currentBot or "-")
	end

	for i = 1, VISIBLE_LINES do
		local row = frame.Rows[i]
		local entry = entries[i + offset]

		if entry then
			row:Show()
			if entry.type == "header" or entry.type == "subheader" then
				local isSub = entry.type == "subheader"
				row.left:SetFontObject(isSub and "GameFontNormal" or "GameFontNormal")
				row.left:SetTextColor(1, 0.82, 0)
				row.left:ClearAllPoints()
				row.left:SetPoint("LEFT", row, "LEFT", isSub and 16 or 0, 0)
				if isSub and entry.icon then
					row.icon:SetTexture(MultiBot.SafeTexturePath(entry.icon))
					row.icon:Show()
				else
					row.icon:Hide()
				end
				row.left:SetText(entry.name or "-")
				row.right:Hide()
				row.emblemIcon:Hide()
				row.bar:Hide()
				row.bar:SetScript("OnEnter", nil)
				row.bar:SetScript("OnLeave", nil)
			elseif self.currentTab == "emblems" then
				row.left:SetFontObject("GameFontHighlightSmall")
                row.left:SetTextColor(1, 1, 1)
				row.left:ClearAllPoints()
				row.left:SetPoint("LEFT", row, "LEFT", 0, 0)
				row.icon:Hide()
				row.left:SetText(entry.name or "-")
				local countText = entry.count and tostring(entry.count) or "-"
				row.right:SetText(countText)
				row.right:Show()
				local emblemIcon = entry.icon
				if entry.itemId and EMBLEM_ICON_BY_ID[entry.itemId] then
					emblemIcon = EMBLEM_ICON_BY_ID[entry.itemId]
				elseif entry.itemId then
					emblemIcon = emblemIcon or GetItemIcon(entry.itemId)
				end
				if emblemIcon then
					row.emblemIcon:SetTexture(MultiBot.SafeTexturePath(emblemIcon))
					row.emblemIcon:Show()
				else
					row.emblemIcon:Hide()
				end
				row.bar:Hide()
				row.bar:SetScript("OnEnter", nil)
				row.bar:SetScript("OnLeave", nil)
			else
				row.left:SetFontObject("GameFontHighlightSmall")
                row.left:SetTextColor(1, 1, 1)
				row.left:ClearAllPoints()
				row.left:SetPoint("LEFT", row, "LEFT", 0, 0)
				row.icon:Hide()
				row.left:SetText(entry.name or "-")
				row.emblemIcon:Hide()
				local status = entry.status or "-"
				local current = entry.current or 0
				local total = entry.total or 0
				local displayStatus = status
				local lowerStatus = string.lower(status)
				local color = repColor[lowerStatus] or { 0.4, 0.6, 0.9 }

				row.right:Hide()
				row.bar:Show()
				row.bar:SetMinMaxValues(0, math.max(total, 1))
				row.bar:SetValue(current)
				row.bar:SetStatusBarColor(color[1], color[2], color[3])
				row.barText:SetText(displayStatus)

				row.bar:SetScript("OnEnter", function()
					row.barText:SetText(string.format("%d/%d", current, total))
				end)
				row.bar:SetScript("OnLeave", function()
					row.barText:SetText(displayStatus)
				end)
			end
		else
			row.left:SetText("")
			row.right:SetText("")
			row.emblemIcon:Hide()
            row.bar:Hide()
			row.bar:SetScript("OnEnter", nil)
			row.bar:SetScript("OnLeave", nil)
			row:Hide()
		end
	end
end

function MBRepEmblems:UpdateDropDown()
	if not (self.Frame and self.Frame.BotDropDown) then
		return
	end

	local dropDown = self.Frame.BotDropDown
	local items = {}
	for botName in pairs(self.cache) do
		items[#items + 1] = botName
	end
	table.sort(items)

	UIDropDownMenu_Initialize(dropDown, function()
		local info = UIDropDownMenu_CreateInfo()
		for _, name in ipairs(items) do
			info.text = name
			info.func = function()
				MBRepEmblems:SetCurrentBot(name)
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	UIDropDownMenu_SetText(dropDown, self.currentBot or (MultiBot.tips.every.repemblemsselectbot or "Bot"))
end

function MBRepEmblems:ShowFrame()
	self:EnsureFrame()
	self:UpdateDropDown()
	self:Refresh()

	if not self.Frame:IsShown() then
		self.Frame:Show()
	end
end

function MBRepEmblems:Request(botName, section)
	if not botName or botName == "" then
		return
	end

	local target = NormalizeSenderName(botName)
	local state = EnsureState(target)
	ResetSection(state, section)
	state.collecting = section
	self.currentBot = target
	self.currentTab = section
	self:ShowFrame()

	local command = (section == "emblems") and "emblems" or "rep all"
	SendChatMessage(command, "WHISPER", nil, botName)
end

function MultiBot.RequestReputations(botName)
	MBRepEmblems:Request(botName, "reputations")
end

function MultiBot.RequestEmblems(botName)
	MBRepEmblems:Request(botName, "emblems")
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("CHAT_MSG_WHISPER")

loader:SetScript("OnEvent", function(_, event, ...)
	if event == "PLAYER_LOGIN" then
		MBRepEmblems:EnsureFrame()
		return
	end

	if event ~= "CHAT_MSG_WHISPER" then
		return
	end

	local msg, sender = ...
	local clean = CleanMessage(msg)
	if clean == "" then
		return
	end

	local section = GetHeader(clean)
	if section then
		local botName = NormalizeSenderName(sender)
		if botName == "" then
			return
		end

		local state = EnsureState(botName)
		ResetSection(state, section)
		state.collecting = section

		MBRepEmblems.currentBot = botName
		MBRepEmblems.currentTab = section
		MBRepEmblems:ShowFrame()
		return
	end

	local botName = NormalizeSenderName(sender)
	if botName == "" then
		return
	end

	local state = MBRepEmblems.cache[botName]
	if not state or not state.collecting then
		return
	end

	if state.collecting == "reputations" then
		local entry = ParseReputationLine(clean)
		if not entry then
			return
		end
		Upsert(state.reputations, state.repIndex, entry.name, entry)
	elseif state.collecting == "emblems" then
		local entry = ParseEmblemLine(clean)
		if not entry then
			return
		end
		Upsert(state.emblems, state.emblemIndex, entry.name, entry)
	end

	MBRepEmblems.currentBot = botName
	MBRepEmblems:ShowFrame()
end)