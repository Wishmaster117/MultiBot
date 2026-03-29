if not MultiBot then return end

local MAIN_FRAME_NAME = "Main"
local MAIN_BUTTON_NAME = "Main"
local MAIN_BUTTON_ICON = "inv_gizmo_02"
local MAIN_FRAME_X = -2
local MAIN_FRAME_Y = 38
local LEFT_LAYOUT_SHIFT = 34

local LEFT_LAYOUT_NAMES = {
    "Tanker",
    "Attack",
    "Mode",
    "Stay",
    "Follow",
    "ExpandStay",
    "ExpandFollow",
    "Flee",
    "Format",
    "Beast",
}

local leftLayoutBase = nil

local function withLeftRoot(callback)
    local multibar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local leftRoot = multibar and multibar.frames and multibar.frames["Left"]
    if not leftRoot then
        return
    end

    callback(leftRoot, multibar)
end

local function getMainToggleState(name)
    local multibar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local mainFrame = multibar and multibar.frames and multibar.frames["Main"]
    local button = mainFrame and mainFrame.buttons and mainFrame.buttons[name]
    return button and button.state == true
end

local function captureLeftLayoutBase(leftRoot)
    if leftLayoutBase then
        return
    end

    leftLayoutBase = {
        buttons = {},
        frames = {},
    }

    for _, name in ipairs(LEFT_LAYOUT_NAMES) do
        local button = leftRoot.buttons and leftRoot.buttons[name]
        if button then
            leftLayoutBase.buttons[name] = { x = button.x, y = button.y }
        end

        local frame = leftRoot.frames and leftRoot.frames[name]
        if frame then
            leftLayoutBase.frames[name] = { x = frame.x, y = frame.y }
        end
    end
end

local function setLeftElementX(leftRoot, name, x)
    local button = leftRoot.buttons and leftRoot.buttons[name]
    if button then
        button.setPoint(x, button.y)
    end

    local frame = leftRoot.frames and leftRoot.frames[name]
    if frame then
        local baseButton = leftLayoutBase and leftLayoutBase.buttons and leftLayoutBase.buttons[name]
        local baseFrame = leftLayoutBase and leftLayoutBase.frames and leftLayoutBase.frames[name]
        local frameOffset = -2
        if baseButton and baseFrame then
            frameOffset = baseFrame.x - baseButton.x
        end
        frame.setPoint(x + frameOffset, frame.y)
    end
end

local function getLeftBaseX(leftRoot, name)
    local baseButton = leftLayoutBase and leftLayoutBase.buttons and leftLayoutBase.buttons[name]
    if baseButton then
        return baseButton.x
    end

    local button = leftRoot.buttons and leftRoot.buttons[name]
    if button then
        return button.x
    end

    return 0
end

local function refreshLeftLayout()
    withLeftRoot(function(leftRoot)
        captureLeftLayoutBase(leftRoot)

        if not leftLayoutBase then
            return
        end

        local creatorEnabled = getMainToggleState("Creator")
        local beastEnabled = getMainToggleState("Beast")
        local expandEnabled = getMainToggleState("Expand")

        local commonShift = 0
        if creatorEnabled then
            commonShift = commonShift - LEFT_LAYOUT_SHIFT
        end
        if beastEnabled then
            commonShift = commonShift - LEFT_LAYOUT_SHIFT
        end

        local heavyShift = commonShift
        if expandEnabled then
            heavyShift = heavyShift - LEFT_LAYOUT_SHIFT
        end

        setLeftElementX(leftRoot, "Tanker", getLeftBaseX(leftRoot, "Tanker") + heavyShift)
        setLeftElementX(leftRoot, "Attack", getLeftBaseX(leftRoot, "Attack") + heavyShift)
        setLeftElementX(leftRoot, "Mode", getLeftBaseX(leftRoot, "Mode") + heavyShift)

        setLeftElementX(leftRoot, "Stay", getLeftBaseX(leftRoot, "Stay") + commonShift)
        setLeftElementX(leftRoot, "Follow", getLeftBaseX(leftRoot, "Follow") + commonShift)
        setLeftElementX(leftRoot, "ExpandStay", getLeftBaseX(leftRoot, "ExpandStay") + commonShift)
        setLeftElementX(leftRoot, "ExpandFollow", getLeftBaseX(leftRoot, "ExpandFollow") + commonShift)
        setLeftElementX(leftRoot, "Flee", getLeftBaseX(leftRoot, "Flee") + commonShift)
        setLeftElementX(leftRoot, "Format", getLeftBaseX(leftRoot, "Format") + commonShift)

        setLeftElementX(leftRoot, "Beast", getLeftBaseX(leftRoot, "Beast") + (creatorEnabled and -LEFT_LAYOUT_SHIFT or 0))

        if expandEnabled then
            leftRoot.buttons["ExpandFollow"]:Show()
            leftRoot.buttons["ExpandStay"]:Show()
            leftRoot.buttons["Follow"]:Hide()
            leftRoot.buttons["Stay"]:Hide()
        else
            leftRoot.buttons["ExpandFollow"]:Hide()
            leftRoot.buttons["ExpandStay"]:Hide()
            leftRoot.buttons["Follow"]:Show()
            leftRoot.buttons["Stay"]:Show()
        end
    end)
end

local function resetDefaultWindowPositions()
    MultiBot.frames["MultiBar"].setPoint(-262, 144)
    MultiBot.inventory.setPoint(-700, -144)
    MultiBot.spellbook.setPoint(-802, 302)
    MultiBot.talent.setPoint(-104, -276)
    MultiBot.reward.setPoint(-754, 238)
    MultiBot.itemus.setPoint(-860, -144)
    MultiBot.iconos.setPoint(-860, -144)
    local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
    if statsFrame and statsFrame.setPoint then
        statsFrame.setPoint(-60, 560)
    end
end

local function toggleMasters(button)
    if MultiBot.GM == false then
        SendChatMessage(MultiBot.L("info.rights"), "SAY")
        return
    end

    if MultiBot.OnOffSwitch(button) then
        MultiBot.doRepos("Right", 38)
        MultiBot.frames["MultiBar"].frames["Masters"]:Hide()
        MultiBot.frames["MultiBar"].buttons["Masters"]:Show()
        return
    end

    MultiBot.doRepos("Right", -38)
    MultiBot.frames["MultiBar"].frames["Masters"]:Hide()
    MultiBot.frames["MultiBar"].buttons["Masters"]:Hide()
end

local function toggleRTSC(button)
    if MultiBot.OnOffSwitch(button) then
        MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y + 34)
        MultiBot.frames["MultiBar"].frames["RTSC"]:Show()
        MultiBot.ActionToGroup("rtsc")
        return
    end

    MultiBot.frames["MultiBar"].setPoint(MultiBot.frames["MultiBar"].x, MultiBot.frames["MultiBar"].y - 34)
    MultiBot.frames["MultiBar"].frames["RTSC"]:Hide()
    MultiBot.ActionToGroup("rtsc reset")
end

local function toggleRaidus(button)
    if MultiBot.OnOffSwitch(button) then
        MultiBot.raidus.setRaidus()
        MultiBot.raidus:Show()
        return
    end

    MultiBot.raidus:Hide()
end

local function toggleCreator(button)
    withLeftRoot(function(leftRoot)
        if MultiBot.OnOffSwitch(button) then
            leftRoot.frames["Creator"]:Hide()
            leftRoot.buttons["Creator"]:Show()
        else
            leftRoot.frames["Creator"]:Hide()
            leftRoot.buttons["Creator"]:Hide()
        end

        refreshLeftLayout()
    end)
end

local function toggleBeast(button)
    withLeftRoot(function(leftRoot)
        if MultiBot.OnOffSwitch(button) then
            leftRoot.frames["Beast"]:Hide()
            leftRoot.buttons["Beast"]:Show()
        else
            leftRoot.frames["Beast"]:Hide()
            leftRoot.buttons["Beast"]:Hide()
        end

        refreshLeftLayout()
    end)
end

local function toggleExpand(button)
    MultiBot.OnOffSwitch(button)
    refreshLeftLayout()
end

local function toggleRelease(button)
    MultiBot.auto.release = MultiBot.OnOffSwitch(button) and true or false
end

local function toggleStats(button)
    local statsFrame = MultiBot.EnsureStatsUI and MultiBot.EnsureStatsUI() or MultiBot.stats
    if not statsFrame then
        return
    end

    if GetNumRaidMembers() > 0 then
        SendChatMessage(MultiBot.L("info.stats"), "SAY")
        return
    end

    if MultiBot.OnOffSwitch(button) then
        MultiBot.auto.stats = true
        for index = 1, GetNumPartyMembers() do
            SendChatMessage("stats", "WHISPER", nil, UnitName("party" .. index))
        end
        statsFrame:Show()
        return
    end

    MultiBot.auto.stats = false
    for _, value in pairs(statsFrame.frames) do
        value:Hide()
    end
    statsFrame:Hide()
end

local function createRewardButton(mainFrame)
    local rewardButton = mainFrame.addButton(
        "Reward",
        0,
        306,
        "Interface\\AddOns\\MultiBot\\Icons\\reward.blp",
        MultiBot.L("tips.main.reward")
    ):setDisable()

    rewardButton.doRight = function()
        MultiBot.rewardReopenIfAvailable()
    end

    rewardButton.doLeft = function(button)
        local wasSavedEnabled = MultiBot.GetSavedMainBarValue and MultiBot.GetSavedMainBarValue("Reward") == "true"
        local isEnabled = MultiBot.OnOffSwitch(button)

        MultiBot.rewardSetEnabled(isEnabled)

        if MultiBot.SetSavedMainBarValue then
            MultiBot.SetSavedMainBarValue("Reward", MultiBot.IF(isEnabled, "true", "false"))
        end

        if isEnabled and not wasSavedEnabled and MultiBot.rewardShowConfigPopup then
            MultiBot.rewardShowConfigPopup()
        end
    end

    return rewardButton
end

local function createMainActionButton(mainFrame, definition)
    local button = mainFrame.addButton(definition.name, 0, definition.y, definition.icon, MultiBot.L(definition.tip))

    if definition.disabled then
        button:setDisable()
    end

    button.doLeft = definition.doLeft

    if definition.doRight then
        button.doRight = definition.doRight
    end

    return button
end

function MultiBot.InitializeMainUI(tMultiBar)
    if not tMultiBar or not tMultiBar.addButton or not tMultiBar.addFrame then
        return nil
    end

    local mainButton = tMultiBar.addButton(MAIN_BUTTON_NAME, 0, 0, MAIN_BUTTON_ICON, MultiBot.L("tips.main.master"))
    mainButton:RegisterForDrag("RightButton")
    mainButton:SetScript("OnDragStart", function()
        MultiBot.frames["MultiBar"]:StartMoving()
    end)
    mainButton:SetScript("OnDragStop", function()
        MultiBot.frames["MultiBar"]:StopMovingOrSizing()
    end)
    mainButton.doLeft = function(button)
        MultiBot.ShowHideSwitch(button.parent.frames[MAIN_FRAME_NAME])
    end

    local mainFrame = tMultiBar.addFrame(MAIN_FRAME_NAME, MAIN_FRAME_X, MAIN_FRAME_Y)
    mainFrame:Hide()

    createMainActionButton(mainFrame, {
        name = "Coords",
        y = 0,
        icon = "inv_gizmo_03",
        tip = "tips.main.coords",
        doLeft = function()
            resetDefaultWindowPositions()
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Masters",
        y = 34,
        icon = "mail_gmicon",
        tip = "tips.main.masters",
        disabled = true,
        doLeft = function(button)
            toggleMasters(button)
        end,
    })

    createMainActionButton(mainFrame, {
        name = "RTSC",
        y = 68,
        icon = "ability_hunter_markedfordeath",
        tip = "tips.main.rtsc",
        disabled = true,
        doLeft = function(button)
            toggleRTSC(button)
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Raidus",
        y = 102,
        icon = "inv_misc_head_dragon_01",
        tip = "tips.main.raidus",
        disabled = true,
        doLeft = function(button)
            toggleRaidus(button)
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Creator",
        y = 136,
        icon = "inv_helmet_145a",
        tip = "tips.main.creator",
        disabled = true,
        doLeft = function(button)
            toggleCreator(button)
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Beast",
        y = 170,
        icon = "ability_mount_swiftredwindrider",
        tip = "tips.main.beast",
        disabled = true,
        doLeft = function(button)
            toggleBeast(button)
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Expand",
        y = 204,
        icon = "Interface\\AddOns\\MultiBot\\Icons\\command_follow.blp",
        tip = "tips.main.expand",
        disabled = true,
        doLeft = function(button)
            toggleExpand(button)
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Release",
        y = 238,
        icon = "achievement_bg_xkills_avgraveyard",
        tip = "tips.main.release",
        disabled = true,
        doLeft = function(button)
            toggleRelease(button)
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Stats",
        y = 272,
        icon = "inv_scroll_08",
        tip = "tips.main.stats",
        disabled = true,
        doLeft = function(button)
            toggleStats(button)
        end,
    })

    local rewardButton = createRewardButton(mainFrame)

    refreshLeftLayout()

    createMainActionButton(mainFrame, {
        name = "Reset",
        y = 340,
        icon = "inv_misc_tournaments_symbol_gnome",
        tip = "tips.main.reset",
        doLeft = function()
            MultiBot.ActionToTargetOrGroup("reset botAI")
        end,
    })

    createMainActionButton(mainFrame, {
        name = "Actions",
        y = 374,
        icon = "inv_helmet_02",
        tip = "tips.main.action",
        doLeft = function()
            MultiBot.ActionToTargetOrGroup("reset")
        end,
    })

    return {
        mainButton = mainButton,
        frame = mainFrame,
        rewardButton = rewardButton,
    }
end