if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local QuestLogFrame = MultiBot.QuestLogFrame or {}
MultiBot.QuestLogFrame = QuestLogFrame

local function clearContent(self)
    Shared.ClearFrameChildren(self.content)
end

local function getMemberNamesOnQuest(questIndex)
    local names = {}

    if GetNumRaidMembers() > 0 then
        for index = 1, 40 do
            local unit = "raid" .. index
            if UnitExists(unit) and IsUnitOnQuest(questIndex, unit) then
                local name = UnitName(unit)
                if name then
                    table.insert(names, name)
                end
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for index = 1, 4 do
            local unit = "party" .. index
            if UnitExists(unit) and IsUnitOnQuest(questIndex, unit) then
                local name = UnitName(unit)
                if name then
                    table.insert(names, name)
                end
            end
        end
    end

    table.sort(names)
    return names
end

local function attachQuestLogTooltip(html, questIndex)
    html:SetScript("OnHyperlinkEnter", function(self, _, fullLink)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(fullLink)

        local objectiveCount = GetNumQuestLeaderBoards(questIndex)
        if objectiveCount and objectiveCount > 0 then
            for objectiveIndex = 1, objectiveCount do
                local objectiveText, _, finished = GetQuestLogLeaderBoard(objectiveIndex, questIndex)
                if objectiveText then
                    local tint = finished and 0.5 or 1
                    GameTooltip:AddLine("• " .. objectiveText, tint, tint, tint)
                end
            end
        end

        local members = getMemberNamesOnQuest(questIndex)
        if #members > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Groupe :", 0.8, 0.8, 0.8)
            for _, name in ipairs(members) do
                GameTooltip:AddLine("- " .. name)
            end
        end

        GameTooltip:Show()
    end)
    html:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
end

local function attachQuestLogClick(html)
    html:SetScript("OnHyperlinkClick", function(_, _, link, button)
        if type(link) ~= "string" or not link:match("|Hquest:") then
            return
        end

        local clickedQuestID = tonumber(link:match("|Hquest:(%d+):"))
        if not clickedQuestID then
            return
        end

        for questIndex = 1, GetNumQuestLogEntries() do
            local questLink = GetQuestLink(questIndex)
            local questID = tonumber(questLink and questLink:match("|Hquest:(%d+):"))
            if questID == clickedQuestID then
                SelectQuestLogEntry(questIndex)
                if button == "RightButton" then
                    if GetNumRaidMembers() > 0 then
                        SendChatMessage("drop " .. questLink, "RAID")
                    elseif GetNumPartyMembers() > 0 then
                        SendChatMessage("drop " .. questLink, "PARTY")
                    end
                    SetAbandonQuest()
                    AbandonQuest()
                else
                    QuestLogPushQuest()
                end
                break
            end
        end
    end)
end

function QuestLogFrame:Refresh()
    clearContent(self)

    local entries = GetNumQuestLogEntries()
    local rowOffset = -4
    local visibleCount = 0

    for questIndex = 1, entries do
        local questLink = GetQuestLink(questIndex)
        local _, _, _, _, isCollapsed = GetQuestLogTitle(questIndex)

        if questLink and isCollapsed == nil then
            visibleCount = visibleCount + 1
            local row = CreateFrame("Frame", nil, self.content)
            row:SetSize(332, Shared.ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, rowOffset)
            Shared.ApplyPanelStyle(row, 0.38)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetTexture(Shared.ICON_QUEST)
            icon:SetSize(18, 18)
            icon:SetPoint("LEFT", 6, 0)

            local html = Shared.CreateQuestHTML(row, 290, 20, questLink:gsub("%[", "|cff00ff00["):gsub("%]", "]|r"))
            html:SetPoint("LEFT", 28, 0)
            attachQuestLogTooltip(html, questIndex)
            attachQuestLogClick(html)

            rowOffset = rowOffset - Shared.ROW_HEIGHT - 4
        end
    end

    local emptyState = visibleCount == 0 and (MultiBot.L("tips.quests.gobnosearchdata") or NO_QUESTS_LABEL) or (QUESTS_LABEL or QUEST_LOG)
    if self.summaryLabel then
        self.summaryLabel:SetText(emptyState)
    end

    self.content:SetHeight(math.max(-rowOffset + 4, 1))
    self.scrollFrame:SetVerticalScroll(0)
end

function QuestLogFrame:Toggle()
    if self.host:IsShown() then
        self.host:Hide()
        return
    end

    self.host:Show()
    self:Refresh()
end

function MultiBot.InitializeQuestLogFrame()
    if QuestLogFrame.host then
        return QuestLogFrame
    end

    local host = MultiBot.CreateAceQuestPopupHost and MultiBot.CreateAceQuestPopupHost(QUEST_LOG, 390, 470, "AceGUI-3.0 is required for MB_QuestPopup", "quest_popup") or nil
    assert(host, "AceGUI-3.0 is required for MB_QuestPopup")

    local panel, scrollFrame, content, summaryLabel = Shared.CreateStyledScrollArea(host, "MB_QuestScroll", { left = 10, right = -28, top = -34, bottom = 10 })
    Shared.CreateSectionTitle(panel, QUEST_LOG)

    QuestLogFrame.host = host
    QuestLogFrame.panel = panel
    QuestLogFrame.scrollFrame = scrollFrame
    QuestLogFrame.content = content
    QuestLogFrame.summaryLabel = summaryLabel
    QuestLogFrame.summaryLabel:SetText(QUESTS_LABEL or QUEST_LOG)

    return QuestLogFrame
end