if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
local ResultsFrame = MultiBot.GameObjectResultsFrame or {}
MultiBot.GameObjectResultsFrame = ResultsFrame

function MultiBot.ShowGameObjectPopup()
    local frame = MultiBot.InitializeGameObjectResultsFrame()
    if not frame then
        return
    end

    if frame.window:IsShown() then
        frame.window:Hide()
    end

    frame.scroll:ReleaseChildren()

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_GameObjPopup") or nil
    if not aceGUI then
        return
    end

    local bots = Shared.CollectSortedGameObjectBots and Shared.CollectSortedGameObjectBots() or {}
    for _, bot in ipairs(bots) do
        local botLabel = aceGUI:Create("Label")
        botLabel:SetFullWidth(true)
        botLabel:SetText("Bot: |cff80ff80" .. bot .. "|r")
        frame.scroll:AddChild(botLabel)

        for _, textLine in ipairs(Shared.GetGameObjectEntries(bot) or {}) do
            local line = aceGUI:Create("Label")
            line:SetFullWidth(true)
            if Shared.IsDashedSectionHeader(textLine) then
                line:SetText("|cffffff66" .. textLine .. "|r")
            else
                line:SetText("   " .. textLine)
            end
            frame.scroll:AddChild(line)
        end

        local spacer = aceGUI:Create("Label")
        spacer:SetFullWidth(true)
        spacer:SetText(" ")
        frame.scroll:AddChild(spacer)
    end

    if #bots == 0 then
        local noData = aceGUI:Create("Label")
        noData:SetFullWidth(true)
        noData:SetText(MultiBot.L("tips.quests.gobnosearchdata"))
        frame.scroll:AddChild(noData)
    end

    frame.window:Show()
end

function MultiBot.InitializeGameObjectResultsFrame()
    if ResultsFrame.window then
        return ResultsFrame
    end

    local aceGUI = MultiBot.ResolveAceGUI and MultiBot.ResolveAceGUI("AceGUI-3.0 is required for MB_GameObjPopup") or nil
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(MultiBot.L("tips.quests.gobsfound"))
    window:SetWidth(420)
    window:SetHeight(380)
    window:EnableResize(false)
    window:SetLayout("Flow")
    window.frame:SetFrameStrata("DIALOG")
    if MultiBot.SetAceWindowCloseToHide then MultiBot.SetAceWindowCloseToHide(window) end
    if MultiBot.RegisterAceWindowEscapeClose then MultiBot.RegisterAceWindowEscapeClose(window, "GameObjPopup") end
    if MultiBot.BindAceWindowPosition then MultiBot.BindAceWindowPosition(window, "gameobject_popup") end

    local scroll = aceGUI:Create("ScrollFrame")
    scroll:SetFullWidth(true)
    scroll:SetHeight(280)
    scroll:SetLayout("List")
    window:AddChild(scroll)

    local buttonSpacer = aceGUI:Create("Label")
    buttonSpacer:SetFullWidth(true)
    buttonSpacer:SetText(" ")
    window:AddChild(buttonSpacer)

    local copyButton = aceGUI:Create("Button")
    copyButton:SetText(MultiBot.L("tips.quests.gobselectall"))
    copyButton:SetWidth(170)
    copyButton:SetCallback("OnClick", function()
        if MultiBot.ShowGameObjectCopyBox then
            MultiBot.ShowGameObjectCopyBox()
        end
    end)
    window:AddChild(copyButton)

    ResultsFrame.window = window
    ResultsFrame.scroll = scroll
    ResultsFrame.copyButton = copyButton
    MultiBot.GameObjPopup = ResultsFrame
    return ResultsFrame
end