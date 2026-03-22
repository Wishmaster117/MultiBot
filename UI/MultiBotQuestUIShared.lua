if not MultiBot then return end

local Shared = MultiBot.QuestUIShared or {}
MultiBot.QuestUIShared = Shared

Shared.ROW_HEIGHT = 24
Shared.DETAIL_ROW_HEIGHT = 16
Shared.PANEL_ALPHA = 0.90
Shared.SUBPANEL_ALPHA = 0.72
Shared.ICON_QUEST = "Interface\\Icons\\inv_misc_note_01"
Shared.ICON_BOT_QUEST = "Interface\\Icons\\inv_misc_note_02"

local function getAceGUI()
    if MultiBot.GetAceGUI then
        local ace = MultiBot.GetAceGUI()
        if type(ace) == "table" and type(ace.Create) == "function" then
            return ace
        end
    end

    if type(LibStub) == "table" then
        local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
        if ok and type(aceGUI) == "table" and type(aceGUI.Create) == "function" then
            return aceGUI
        end
    end

    return nil
end

Shared.GetAceGUI = Shared.GetAceGUI or getAceGUI

function Shared.ApplyPanelStyle(frame, bgAlpha)
    if not frame or not frame.SetBackdrop then
        return
    end

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })

    if frame.SetBackdropColor then
        frame:SetBackdropColor(0.06, 0.06, 0.08, bgAlpha or Shared.PANEL_ALPHA)
    end
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
    end
end

function Shared.ApplyEditBoxStyle(widget)
    if not widget or not widget.frame or not widget.editbox then
        return
    end

    Shared.ApplyPanelStyle(widget.frame, 0.92)

    local editBox = widget.editbox
    if editBox.GetRegions then
        for _, region in ipairs({ editBox:GetRegions() }) do
            if region and region.GetObjectType and region:GetObjectType() == "Texture" and region.SetAlpha then
                region:SetAlpha(0)
            end
        end
    end

    editBox:ClearAllPoints()
    editBox:SetPoint("TOPLEFT", widget.frame, "TOPLEFT", 8, -4)
    editBox:SetPoint("BOTTOMRIGHT", widget.frame, "BOTTOMRIGHT", -8, 4)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetTextInsets(4, 4, 3, 3)

    widget:SetHeight(32)
    if widget.frame.SetHeight then
        widget.frame:SetHeight(32)
    end
end

function Shared.ClearFrameChildren(frame, clearRegions)
    if not frame then
        return
    end

    if frame.GetNumChildren and frame.GetChildren then
        for index = (frame:GetNumChildren() or 0), 1, -1 do
            local child = select(index, frame:GetChildren())
            if child then
                child:Hide()
                child:SetParent(nil)
            end
        end
    end

    if clearRegions and frame.GetRegions then
        for _, region in ipairs({ frame:GetRegions() }) do
            if region and region.Hide then
                region:Hide()
            end
            if region and region.GetObjectType then
                local regionType = region:GetObjectType()
                if regionType == "FontString" and region.SetText then
                    region:SetText("")
                elseif regionType == "Texture" and region.SetTexture then
                    region:SetTexture(nil)
                end
            end
        end
    end
end

function Shared.CreateSectionTitle(parent, text)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    title:SetJustifyH("LEFT")
    title:SetText(text or "")
    return title
end

function Shared.CreateSummaryLabel(parent, anchor, xOffset, yOffset)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint(anchor or "TOPLEFT", parent, anchor or "TOPLEFT", xOffset or 10, yOffset or -30)
    label:SetWidth(math.max((parent.GetWidth and parent:GetWidth() or 360) - 24, 120))
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetTextColor(0.85, 0.82, 0.72)
    return label
end

function Shared.CreateStyledScrollArea(parent, name, insets)
    local padding = insets or { left = 10, right = -28, top = -48, bottom = 10 }

    local panel = CreateFrame("Frame", nil, parent)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -8)
    panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -8, 8)
    Shared.ApplyPanelStyle(panel, Shared.SUBPANEL_ALPHA)

    local scrollFrame = CreateFrame("ScrollFrame", name, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", padding.left, padding.top)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", padding.right, padding.bottom)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(1)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    local summary = Shared.CreateSummaryLabel(panel, "TOPLEFT", 12, -30)

    return panel, scrollFrame, content, summary
end

function Shared.CreateQuestHTML(parent, width, height, text)
    local html = CreateFrame("SimpleHTML", nil, parent)
    html:SetSize(width or 260, height or 20)
    html:SetFontObject("GameFontNormal")
    html:SetText(text or "")
    html:SetHyperlinksEnabled(true)
    return html
end

function Shared.BindHyperlinkTooltip(html)
    if not html then
        return
    end

    html:SetScript("OnHyperlinkEnter", function(self, _, link)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    html:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
end

function Shared.GetLocalizedQuestName(questID, fallback)
    if MultiBot.GetLocalizedQuestName then
        return MultiBot.GetLocalizedQuestName(questID) or fallback or tostring(questID)
    end

    return fallback or tostring(questID)
end

function Shared.BuildQuestLink(questID, questName)
    local localizedName = Shared.GetLocalizedQuestName(questID, questName)
    return ("|cff00ff00|Hquest:%s:0|h[%s]|h|r"):format(questID, localizedName)
end

function Shared.SortQuestEntries(questsById)
    local entries = {}
    for questID, questName in pairs(questsById or {}) do
        local numericID = tonumber(questID)
        table.insert(entries, {
            id = numericID or questID,
            sortID = numericID or 0,
            name = Shared.GetLocalizedQuestName(numericID, questName),
            originalName = questName,
        })
    end

    table.sort(entries, function(left, right)
        local leftName = string.lower(tostring(left.name or left.originalName or ""))
        local rightName = string.lower(tostring(right.name or right.originalName or ""))
        if leftName == rightName then
            return (left.sortID or 0) < (right.sortID or 0)
        end
        return leftName < rightName
    end)

    return entries
end

function Shared.AppendBotName(target, botName)
    if not target.bots then
        target.bots = {}
    end

    table.insert(target.bots, botName)
    table.sort(target.bots)
end

function Shared.FormatBotsLabel(bots)
    return (MultiBot.L("tips.quests.botsword") or "Bots: ") .. table.concat(bots or {}, ", ")
end

function Shared.BuildAggregatedQuestEntries(source)
    local questMap = {}

    for botName, quests in pairs(source or {}) do
        for questID, questName in pairs(quests or {}) do
            local numericID = tonumber(questID)
            if numericID then
                if not questMap[numericID] then
                    questMap[numericID] = {
                        id = numericID,
                        name = Shared.GetLocalizedQuestName(numericID, questName),
                        bots = {},
                    }
                end
                Shared.AppendBotName(questMap[numericID], botName)
            end
        end
    end

    local entries = {}
    for _, entry in pairs(questMap) do
        table.insert(entries, entry)
    end

    table.sort(entries, function(left, right)
        local leftName = string.lower(tostring(left.name or ""))
        local rightName = string.lower(tostring(right.name or ""))
        if leftName == rightName then
            return (left.id or 0) < (right.id or 0)
        end
        return leftName < rightName
    end)

    return entries
end

function Shared.GetGameObjectEntries(bot)
    local entries = MultiBot.LastGameObjectSearch and MultiBot.LastGameObjectSearch[bot]
    if type(entries) ~= "table" then
        return nil
    end

    return entries
end

function Shared.CollectSortedGameObjectBots()
    local bots = {}
    for bot in pairs(MultiBot.LastGameObjectSearch or {}) do
        local entries = Shared.GetGameObjectEntries(bot)
        if entries and #entries > 0 then
            table.insert(bots, bot)
        end
    end
    table.sort(bots)
    return bots
end

function Shared.IsDashedSectionHeader(text)
    return type(text) == "string" and text:find("^%s*%-+%s*.-%s*%-+%s*$") ~= nil
end

function Shared.BuildGameObjectCopyText(bots)
    local lines = {}

    for _, bot in ipairs(bots or {}) do
        local entries = Shared.GetGameObjectEntries(bot) or {}
        table.insert(lines, ("Bot: %s"):format(bot))
        for _, entry in ipairs(entries) do
            table.insert(lines, entry)
        end
        table.insert(lines, "")
    end

    if #lines == 0 then
        return MultiBot.L("tips.quests.gobnosearchdata")
    end

    return table.concat(lines, "\n")
end

function Shared.ResolveAceGUI(message)
    if MultiBot.ResolveAceGUI then
        return MultiBot.ResolveAceGUI(message)
    end

    local aceGUI = Shared.GetAceGUI()
    if not aceGUI and message then
        UIErrorsFrame:AddMessage(message, 1, 0.2, 0.2, 1)
    end
    return aceGUI
end