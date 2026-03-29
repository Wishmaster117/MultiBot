if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local QuestCompletedFrame = MultiBot.QuestCompletedFrame or {}
MultiBot.QuestCompletedFrame = QuestCompletedFrame

MultiBot.BotQuestsCompleted = MultiBot.BotQuestsCompleted or {}

local function clearList(self)
    if self.scroll then
        self.scroll:ReleaseChildren()
    end
end

local function createQuestEntryRow(self, entry)
    local row = self.aceGUI:Create("SimpleGroup")
    row:SetFullWidth(true)
    row:SetLayout("Flow")

    local icon = self.aceGUI:Create("Icon")
    icon:SetImage(Shared.ICON_BOT_QUEST or "Interface\\Icons\\inv_misc_note_02")
    icon:SetImageSize(14, 14)
    icon:SetWidth(20)
    row:AddChild(icon)

    local label = self.aceGUI:Create("InteractiveLabel")
    label:SetWidth(320)
    label:SetText(Shared.BuildQuestLink(entry.id, entry.name))
    label:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(widget.frame, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink("quest:" .. tostring(entry.id))
        GameTooltip:Show()
    end)
    label:SetCallback("OnLeave", function()
        GameTooltip_Hide()
    end)
    row:AddChild(label)

    self.scroll:AddChild(row)

    if entry.bots and #entry.bots > 0 then
        local botsLabel = self.aceGUI:Create("Label")
        botsLabel:SetFullWidth(true)
        botsLabel:SetText("    " .. Shared.FormatBotsLabel(entry.bots))
        self.scroll:AddChild(botsLabel)
    end
end

local function renderQuestList(self, entries, summaryText)
    clearList(self)

    local questEntries = entries or {}
    for _, entry in ipairs(questEntries) do
        createQuestEntryRow(self, entry)
    end

    if #questEntries == 0 then
        local noData = self.aceGUI:Create("Label")
        noData:SetFullWidth(true)
        noData:SetText(MultiBot.L("tips.quests.gobnosearchdata") or "No quests")
        self.scroll:AddChild(noData)
    end

    if self.summary then
        self.summary:SetText(summaryText or MultiBot.L("tips.quests.complist") or "")
    end
end

function MultiBot.BuildBotCompletedList(botName)
    local frame = MultiBot.InitializeQuestCompletedFrame()
    local entries = Shared.SortQuestEntries(MultiBot.BotQuestsCompleted[botName] or {})

    frame:Show()
    renderQuestList(frame, entries, botName and ("|cff80ff80" .. botName .. "|r") or nil)
end

function MultiBot.BuildAggregatedCompletedList()
    local frame = MultiBot.InitializeQuestCompletedFrame()
    local entries = Shared.BuildAggregatedQuestEntries(MultiBot.BotQuestsCompleted)

    frame:Show()
    renderQuestList(frame, entries, "")
end

function QuestCompletedFrame:Show()
    if self.window then
        self.window:Show()
    end
end

function MultiBot.InitializeQuestCompletedFrame()
    if QuestCompletedFrame.window then
        return QuestCompletedFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_BotQuestCompPopup") or nil
    assert(aceGUI, "AceGUI-3.0 is required for MB_BotQuestCompPopup")

    local window = aceGUI:Create("Window")
    assert(window, "AceGUI-3.0 is required for MB_BotQuestCompPopup")

    window:SetTitle(MultiBot.L("tips.quests.complist"))
    window:SetWidth(380)
    window:SetHeight(420)
    window:EnableResize(false)
    window:SetLayout("Fill")
    window.frame:SetFrameStrata("DIALOG")

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotQuestCompleted") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_quest_comp_popup") end

    local content = aceGUI:Create("SimpleGroup")
    content:SetFullWidth(true)
    content:SetFullHeight(true)
    content:SetLayout("List")
    window:AddChild(content)

    local heading = aceGUI:Create("Heading")
    heading:SetFullWidth(true)
    heading:SetText(MultiBot.L("tips.quests.complist"))
    content:AddChild(heading)

    local summary = aceGUI:Create("Label")
    summary:SetFullWidth(true)
    summary:SetText("")
    content:AddChild(summary)

    local scroll = aceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetFullHeight(true)
    scroll:SetLayout("List")
    content:AddChild(scroll)

    window.frame:HookScript("OnHide", function()
        MultiBot.BotQuestsCompleted = {}
        clearList(QuestCompletedFrame)
    end)

    QuestCompletedFrame.window = window
    QuestCompletedFrame.aceGUI = aceGUI
    QuestCompletedFrame.scroll = scroll
    QuestCompletedFrame.summary = summary

    MultiBot.tBotCompPopup = window
    return QuestCompletedFrame
end