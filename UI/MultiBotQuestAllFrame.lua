if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local QuestAllFrame = MultiBot.QuestAllFrame or {}
MultiBot.QuestAllFrame = QuestAllFrame

MultiBot.BotQuestsAll = MultiBot.BotQuestsAll or {}
MultiBot.BotQuestsCompleted = MultiBot.BotQuestsCompleted or {}
MultiBot.BotQuestsIncompleted = MultiBot.BotQuestsIncompleted or {}

local function clearContent(self)
    Shared.ClearFrameChildren(self.content, true)
    if self.content and self.content.text then
        self.content.text:SetText("")
    end
end

function MultiBot.ClearAllContent()
    local frame = MultiBot.InitializeQuestAllFrame()
    clearContent(frame)
end

local function createHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 0, yOffset)
    header:SetText(text or "")
    return header
end

local function renderQuestWithBots(parent, yOffset, entry)
    local line = CreateFrame("Frame", nil, parent)
    line:SetSize(360, 20)
    line:SetPoint("TOPLEFT", 0, yOffset)
    Shared.ApplyPanelStyle(line, 0.34)

    local icon = line:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(Shared.ICON_BOT_QUEST)
    icon:SetSize(12, 12)
    icon:SetPoint("LEFT", 6, 0)

    local html = Shared.CreateQuestHTML(line, 320, Shared.ROW_HEIGHT, Shared.BuildQuestLink(entry.id, entry.name))
    html:SetPoint("LEFT", icon, "RIGHT", 6, -6)
    Shared.BindHyperlinkTooltip(html)

    yOffset = yOffset - 24

    local botsLine = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    botsLine:SetPoint("TOPLEFT", 28, yOffset)
    botsLine:SetText(Shared.FormatBotsLabel(entry.bots))

    return yOffset - 18
end

function MultiBot.BuildBotAllList(botName)
    local frame = MultiBot.InitializeQuestAllFrame()
    clearContent(frame)

    local yOffset = -4
    for _, link in ipairs(MultiBot.BotQuestsAll[botName] or {}) do
        local questID = tonumber(link:match("|Hquest:(%d+):"))
        local localizedName = questID and Shared.GetLocalizedQuestName(questID, link) or link
        local displayLink = link:gsub("%[[^%]]+%]", "|cff00ff00[" .. localizedName .. "]|r")

        local line = CreateFrame("Frame", nil, frame.content)
        line:SetSize(360, 20)
        line:SetPoint("TOPLEFT", 0, yOffset)
        Shared.ApplyPanelStyle(line, 0.34)

        local icon = line:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(Shared.ICON_BOT_QUEST)
        icon:SetSize(12, 12)
        icon:SetPoint("LEFT", 6, 0)

        local html = Shared.CreateQuestHTML(line, 320, Shared.ROW_HEIGHT, displayLink)
        html:SetPoint("LEFT", icon, "RIGHT", 6, -6)
        Shared.BindHyperlinkTooltip(html)

        yOffset = yOffset - 24
    end

    if frame.summaryLabel then
        frame.summaryLabel:SetText(botName and ((MultiBot.L("tips.quests.alllist") or "All Quests") .. ": |cff80ff80" .. botName .. "|r") or (MultiBot.L("tips.quests.alllist") or ""))
    end

    frame.content:SetHeight(math.max(-yOffset + 4, 1))
    frame.scrollFrame:SetVerticalScroll(0)
end

function MultiBot.BuildAggregatedAllList()
    local frame = MultiBot.InitializeQuestAllFrame()
    clearContent(frame)

    local yOffset = -4
    local completeEntries = Shared.BuildAggregatedQuestEntries(MultiBot.BotQuestsCompleted)
    local incompleteEntries = Shared.BuildAggregatedQuestEntries(MultiBot.BotQuestsIncompleted)

    createHeader(frame.content, MultiBot.L("tips.quests.compheader"), yOffset)
    yOffset = yOffset - 30
    for _, entry in ipairs(completeEntries) do
        yOffset = renderQuestWithBots(frame.content, yOffset, entry)
    end

    yOffset = yOffset - 12
    createHeader(frame.content, MultiBot.L("tips.quests.incompheader"), yOffset)
    yOffset = yOffset - 30
    for _, entry in ipairs(incompleteEntries) do
        yOffset = renderQuestWithBots(frame.content, yOffset, entry)
    end

    if frame.summaryLabel then
        frame.summaryLabel:SetText("")
    end

    frame.content:SetHeight(math.max(-yOffset + 4, 1))
    frame.scrollFrame:SetVerticalScroll(0)
end

function QuestAllFrame:SetLoading()
    clearContent(self)
    self.content.text = self.content.text or self.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.content.text:SetPoint("TOPLEFT", 8, -8)
    self.content.text:SetText(LOADING)
    self.content:SetHeight(40)
    self.scrollFrame:SetVerticalScroll(0)
end

function QuestAllFrame:Show()
    self.host:Show()
end

function MultiBot.InitializeQuestAllFrame()
    if QuestAllFrame.host then
        return QuestAllFrame
    end

    local host = MultiBot.CreateAceQuestPopupHost and MultiBot.CreateAceQuestPopupHost(MultiBot.L("tips.quests.alllist"), 420, 460, "AceGUI-3.0 is required for MB_BotQuestAllPopup", "bot_quest_all_popup") or nil
    assert(host, "AceGUI-3.0 is required for MB_BotQuestAllPopup")

    local panel, scrollFrame, content, summaryLabel = Shared.CreateStyledScrollArea(host, "MB_BotQuestAllScroll", { left = 10, right = -28, top = -34, bottom = 10 })
    Shared.CreateSectionTitle(panel, MultiBot.L("tips.quests.alllist"))

    QuestAllFrame.host = host
    QuestAllFrame.panel = panel
    QuestAllFrame.scrollFrame = scrollFrame
    QuestAllFrame.content = content
    QuestAllFrame.summaryLabel = summaryLabel

    host.content = content
    host:SetScript("OnHide", function()
        MultiBot.BotQuestsAll = {}
        MultiBot.BotQuestsCompleted = {}
        MultiBot.BotQuestsIncompleted = {}
        clearContent(QuestAllFrame)
    end)

    MultiBot.tBotAllPopup = host
    return QuestAllFrame
end