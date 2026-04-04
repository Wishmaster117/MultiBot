if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local QuestCompletedFrame = MultiBot.QuestCompletedFrame or {}
MultiBot.QuestCompletedFrame = QuestCompletedFrame

local function getBotQuestsCompletedStore()
    return (MultiBot.Store and MultiBot.Store.EnsureRuntimeTable and MultiBot.Store.EnsureRuntimeTable("BotQuestsCompleted")) or (MultiBot.BotQuestsCompleted or {})
end

local function clearList(self)
    if self.scroll then
        self.scroll:ReleaseChildren()
    end
end

function MultiBot.BuildBotCompletedList(botName)
    local frame = MultiBot.InitializeQuestCompletedFrame()
    local entries = Shared.SortQuestEntries(getBotQuestsCompletedStore()[botName] or {})

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = botName and ("|cff80ff80" .. botName .. "|r") or (MultiBot.L("tips.quests.complist") or ""),
    })
end

function MultiBot.BuildAggregatedCompletedList()
    local frame = MultiBot.InitializeQuestCompletedFrame()
    local entries = Shared.BuildAggregatedQuestEntries(getBotQuestsCompletedStore())

    frame:Show()
    Shared.RenderQuestEntries(frame, entries, {
        summaryText = "",
    })
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
    local strataLevel = MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()
    if strataLevel then
        window.frame:SetFrameStrata(strataLevel)
    end

    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "BotQuestCompleted") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "bot_quest_comp_popup") end

    local content = aceGUI:Create("SimpleGroup")
    content:SetFullWidth(true)
    content:SetFullHeight(true)
    content:SetLayout("List")
    window:AddChild(content)

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
        local store = getBotQuestsCompletedStore()
        if wipe then
            wipe(store)
        else
            for key in pairs(store) do store[key] = nil end
        end
        clearList(QuestCompletedFrame)
    end)

    QuestCompletedFrame.window = window
    QuestCompletedFrame.aceGUI = aceGUI
    QuestCompletedFrame.scroll = scroll
    QuestCompletedFrame.summary = summary

    MultiBot.tBotCompPopup = window
    return QuestCompletedFrame
end