if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local QuestIncompleteFrame = MultiBot.QuestIncompleteFrame or {}
MultiBot.QuestIncompleteFrame = QuestIncompleteFrame

MultiBot.BotQuestsIncompleted = MultiBot.BotQuestsIncompleted or {}

local function clearContent(self)
    Shared.ClearFrameChildren(self.content)
end

local function renderQuestList(self, entries, summaryText)
    clearContent(self)

    local yOffset = -4
    for _, entry in ipairs(entries or {}) do
        local line = CreateFrame("Frame", nil, self.content)
        line:SetSize(320, Shared.ROW_HEIGHT)
        line:SetPoint("TOPLEFT", 0, yOffset)
        Shared.ApplyPanelStyle(line, 0.34)

        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(Shared.ICON_BOT_QUEST)
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 6, 0)

        local html = Shared.CreateQuestHTML(line, 280, 20, Shared.BuildQuestLink(entry.id, entry.name))
        html:SetPoint("LEFT", 28, 0)
        Shared.BindHyperlinkTooltip(html)

        yOffset = yOffset - Shared.ROW_HEIGHT - 4

        if entry.bots and #entry.bots > 0 then
            local botRow = CreateFrame("Frame", nil, self.content)
            botRow:SetSize(320, Shared.DETAIL_ROW_HEIGHT)
            botRow:SetPoint("TOPLEFT", 0, yOffset)

            local botsLine = botRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            botsLine:SetPoint("LEFT", 28, 0)
            botsLine:SetJustifyH("LEFT")
            botsLine:SetText(Shared.FormatBotsLabel(entry.bots))

            yOffset = yOffset - Shared.DETAIL_ROW_HEIGHT - 2
        end
    end

    if self.summaryLabel then
        self.summaryLabel:SetText(summaryText or MultiBot.L("tips.quests.incomplist") or "")
    end
    self.content:SetHeight(math.max(-yOffset + 4, 1))
    self.scrollFrame:SetVerticalScroll(0)
end

function MultiBot.BuildBotQuestList(botName)
    local frame = MultiBot.InitializeQuestIncompleteFrame()
    local entries = Shared.SortQuestEntries(MultiBot.BotQuestsIncompleted[botName] or {})
    frame:Show()
    renderQuestList(frame, entries, botName and ((MultiBot.L("tips.quests.incomplist") or "Current Quests") .. ": |cff80ff80" .. botName .. "|r") or nil)
end

function MultiBot.BuildAggregatedQuestList()
    local frame = MultiBot.InitializeQuestIncompleteFrame()
    local entries = Shared.BuildAggregatedQuestEntries(MultiBot.BotQuestsIncompleted)

    frame:Show()
    renderQuestList(frame, entries, MultiBot.L("tips.quests.incomplist") or "")
end

function QuestIncompleteFrame:Show()
    self.host:Show()
end

function MultiBot.InitializeQuestIncompleteFrame()
    if QuestIncompleteFrame.host then
        return QuestIncompleteFrame
    end

    local host = MultiBot.CreateAceQuestPopupHost and MultiBot.CreateAceQuestPopupHost(MultiBot.L("tips.quests.incomplist"), 380, 420, "AceGUI-3.0 is required for MB_BotQuestPopup", "bot_quest_popup") or nil
    assert(host, "AceGUI-3.0 is required for MB_BotQuestPopup")

    local panel, scrollFrame, content, summaryLabel = Shared.CreateStyledScrollArea(host, "MB_BotQuestScroll", { left = 10, right = -28, top = -34, bottom = 10 })
    Shared.CreateSectionTitle(panel, MultiBot.L("tips.quests.incomplist"))

    QuestIncompleteFrame.host = host
    QuestIncompleteFrame.panel = panel
    QuestIncompleteFrame.scrollFrame = scrollFrame
    QuestIncompleteFrame.content = content
    QuestIncompleteFrame.summaryLabel = summaryLabel

    host:SetScript("OnHide", function()
        MultiBot.BotQuestsIncompleted = {}
        clearContent(QuestIncompleteFrame)
    end)

    MultiBot.tBotPopup = host
    return QuestIncompleteFrame
end