if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local QuestIncompleteFrame = MultiBot.QuestIncompleteFrame or {}
MultiBot.QuestIncompleteFrame = QuestIncompleteFrame

MultiBot.BotQuestsIncompleted = MultiBot.BotQuestsIncompleted or {}

local function clearList(self)
    if self.scroll then
        self.scroll:ReleaseChildren()
    end
end

function MultiBot.BuildBotQuestList(botName)
    local frame = MultiBot.InitializeQuestIncompleteFrame()
    local entries = Shared.SortQuestEntries(MultiBot.BotQuestsIncompleted[botName] or {})

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = botName and ("|cff80ff80" .. botName .. "|r") or (MultiBot.L("tips.quests.incomplist") or ""),
    })
end

function MultiBot.BuildAggregatedQuestList()
    local frame = MultiBot.InitializeQuestIncompleteFrame()
    local entries = Shared.BuildAggregatedQuestEntries(MultiBot.BotQuestsIncompleted)

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = "",
    })
end

function QuestIncompleteFrame:Show()
    if self.window then
        self.window:Show()
    end
end

function MultiBot.InitializeQuestIncompleteFrame()
    if QuestIncompleteFrame.window then
        return QuestIncompleteFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_BotQuestPopup") or nil
    assert(aceGUI, "AceGUI-3.0 is required for MB_BotQuestPopup")

    local window = aceGUI:Create("Window")
    assert(window, "AceGUI-3.0 is required for MB_BotQuestPopup")

    window:SetTitle(MultiBot.L("tips.quests.incomplist"))
    window:SetWidth(380)
    window:SetHeight(420)
    window:EnableResize(false)
    window:SetLayout("Fill")
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotQuestIncomplete") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_quest_popup") end

    local content = aceGUI:Create("SimpleGroup")
    content:SetFullWidth(true)
    content:SetFullHeight(true)
    content:SetLayout("List")
    window:AddChild(content)

    local heading = aceGUI:Create("Heading")
    heading:SetFullWidth(true)
    heading:SetText(MultiBot.L("tips.quests.incomplist"))
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
        MultiBot.BotQuestsIncompleted = {}
        clearList(QuestIncompleteFrame)
    end)

    QuestIncompleteFrame.window = window
    QuestIncompleteFrame.aceGUI = aceGUI
    QuestIncompleteFrame.scroll = scroll
    QuestIncompleteFrame.summary = summary

    MultiBot.tBotPopup = window
    return QuestIncompleteFrame
end