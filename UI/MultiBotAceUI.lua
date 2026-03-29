if not MultiBot then return end

local AceUI = MultiBot.AceUI or {}
MultiBot.AceUI = AceUI

local escapeFrameIndex = 0
local questTooltipName = "MB_LocalizeQuestTooltip"

local function ensureHiddenTooltip(name, parent)
    local tooltip = _G[name]
    if tooltip then
        return tooltip
    end

    tooltip = CreateFrame("GameTooltip", name, parent or UIParent, "GameTooltipTemplate")
    tooltip:SetOwner(parent or UIParent, "ANCHOR_NONE")
    return tooltip
end

function AceUI.EnsureHiddenTooltip(name, parent)
    return ensureHiddenTooltip(name, parent)
end

function AceUI.GetLocalizedQuestName(questID)
    local tooltip = ensureHiddenTooltip(questTooltipName, UIParent)
    tooltip:ClearLines()
    tooltip:SetHyperlink("quest:" .. questID)

    local textObject = _G[questTooltipName .. "TextLeft1"]
    return (textObject and textObject:GetText()) or tostring(questID)
end

function AceUI.GetAceGUI()
    if type(LibStub) ~= "table" then
        return nil
    end

    local ok, aceGUI = pcall(LibStub.GetLibrary, LibStub, "AceGUI-3.0", true)
    if ok and type(aceGUI) == "table" and type(aceGUI.Create) == "function" then
        return aceGUI
    end

    return nil
end

function AceUI.ResolveAceGUI(missingDepMessage)
    local aceGUI = AceUI.GetAceGUI()
    if not aceGUI and missingDepMessage then
        UIErrorsFrame:AddMessage(missingDepMessage, 1, 0.2, 0.2, 1)
    end

    return aceGUI
end

function AceUI.SetWindowCloseToHide(window)
    if window and window.SetCallback then
        window:SetCallback("OnClose", function(widget)
            widget:Hide()
        end)
    end
end

function AceUI.RegisterWindowEscapeClose(window, namePrefix)
    if not window or not window.frame or type(UISpecialFrames) ~= "table" then
        return
    end

    if window.__mbEscapeName then
        return
    end

    escapeFrameIndex = escapeFrameIndex + 1
    local safePrefix = tostring(namePrefix or "Popup"):gsub("[^%w_]", "")
    local frameName = string.format("MultiBotAce%s_%d", safePrefix, escapeFrameIndex)

    window.__mbEscapeName = frameName
    _G[frameName] = window.frame

    for _, existing in ipairs(UISpecialFrames) do
        if existing == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function getUiProfileStore()
    local profile = MultiBot.db and MultiBot.db.profile
    if not profile then
        return nil
    end

    profile.ui = profile.ui or {}
    return profile.ui
end

function AceUI.BindWindowPosition(window, persistenceKey)
    if not window or not window.frame or not persistenceKey then
        return
    end

    local uiStore = getUiProfileStore()
    if not uiStore then
        return
    end

    uiStore.popupPositions = uiStore.popupPositions or {}
    local positions = uiStore.popupPositions
    local saved = positions[persistenceKey]
    if saved and saved.point then
        window.frame:ClearAllPoints()
        window.frame:SetPoint(saved.point, UIParent, saved.point, saved.x or 0, saved.y or 0)
    end

    if window.__mbPositionHooked then
        return
    end

    window.__mbPositionHooked = true
    window.frame:HookScript("OnDragStop", function(frame)
        local point, _, _, x, y = frame:GetPoint(1)
        if point then
            positions[persistenceKey] = { point = point, x = x or 0, y = y or 0 }
        end
    end)
end

function AceUI.CreatePopupHost(title, width, height, missingDepMessage, persistenceKey, escapePrefix)
    local aceGUI = AceUI.ResolveAceGUI(missingDepMessage or "AceGUI-3.0 is required")
    if not aceGUI then
        return nil
    end

    local window = aceGUI:Create("Window")
    if not window then
        return nil
    end

    window:SetTitle(title or "")
    window:SetWidth(width)
    window:SetHeight(height)
    window:EnableResize(false)
    window:SetLayout("Fill")
    window.frame:SetFrameStrata("DIALOG")

    AceUI.SetWindowCloseToHide(window)
    AceUI.RegisterWindowEscapeClose(window, escapePrefix or "PopupHost")
    AceUI.BindWindowPosition(window, persistenceKey)
    window:Hide()

    local host = CreateFrame("Frame", nil, window.content)
    host:SetAllPoints(window.content)
    host.window = window

    function host:Show()
        self.window:Show()
    end

    function host:Hide()
        self.window:Hide()
    end

    function host:IsShown()
        return self.window and self.window.frame and self.window.frame:IsShown()
    end

    return host
end

MultiBot.GetLocalizedQuestName = MultiBot.GetLocalizedQuestName or AceUI.GetLocalizedQuestName
MultiBot.GetAceGUI = MultiBot.GetAceGUI or AceUI.GetAceGUI
MultiBot.ResolveAceGUI = MultiBot.ResolveAceGUI or AceUI.ResolveAceGUI
MultiBot.SetAceWindowCloseToHide = MultiBot.SetAceWindowCloseToHide or AceUI.SetWindowCloseToHide
MultiBot.RegisterAceWindowEscapeClose = MultiBot.RegisterAceWindowEscapeClose or AceUI.RegisterWindowEscapeClose
MultiBot.BindAceWindowPosition = MultiBot.BindAceWindowPosition or AceUI.BindWindowPosition
MultiBot.CreateAceQuestPopupHost = MultiBot.CreateAceQuestPopupHost or function(title, width, height, missingDepMessage, persistenceKey)
    return AceUI.CreatePopupHost(title, width, height, missingDepMessage, persistenceKey, "QuestHost")
end