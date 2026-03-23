if not MultiBot then return end

local MAIN_FRAME_NAME = "Main"
local MAIN_BUTTON_NAME = "Main"
local MAIN_BUTTON_ICON = "inv_gizmo_02"
local MAIN_FRAME_X = -2
local MAIN_FRAME_Y = 38

local LEFT_REPOS_KEYS = {
    "Tanker",
    "Attack",
    "Mode",
    "Stay",
    "Follow",
    "ExpandStay",
    "ExpandFollow",
    "Flee",
    "Format",
}

local LEFT_REPOS_KEYS_WITH_BEAST = {
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

local function shiftButtons(buttonNames, delta)
    for _, buttonName in ipairs(buttonNames) do
        MultiBot.doRepos(buttonName, delta)
    end
end

local function withLeftRoot(callback)
    local multibar = MultiBot.frames and MultiBot.frames["MultiBar"]
    local leftRoot = multibar and multibar.frames and multibar.frames["Left"]
    if not leftRoot then
        return
    end

    callback(leftRoot, multibar)
end

local function resetDefaultWindowPositions()
    MultiBot.frames["MultiBar"].setPoint(-262, 144)
    MultiBot.inventory.setPoint(-700, -144)
    MultiBot.spellbook.setPoint(-802, 302)
    MultiBot.talent.setPoint(-104, -276)
    MultiBot.reward.setPoint(-754, 238)
    MultiBot.itemus.setPoint(-860, -144)
    MultiBot.iconos.setPoint(-860, -144)
    MultiBot.stats.setPoint(-60, 560)
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
            shiftButtons(LEFT_REPOS_KEYS_WITH_BEAST, -34)
            leftRoot.frames["Creator"]:Hide()
            leftRoot.buttons["Creator"]:Show()
            return
        end

        shiftButtons(LEFT_REPOS_KEYS_WITH_BEAST, 34)
        leftRoot.frames["Creator"]:Hide()
        leftRoot.buttons["Creator"]:Hide()
    end)
end

local function toggleBeast(button)
    withLeftRoot(function(leftRoot)
        if MultiBot.OnOffSwitch(button) then
            shiftButtons(LEFT_REPOS_KEYS, -34)
            leftRoot.frames["Beast"]:Hide()
            leftRoot.buttons["Beast"]:Show()
            return
        end

        shiftButtons(LEFT_REPOS_KEYS, 34)
        leftRoot.frames["Beast"]:Hide()
        leftRoot.buttons["Beast"]:Hide()
    end)
end

local function toggleExpand(button)
    withLeftRoot(function(leftRoot)
        if MultiBot.OnOffSwitch(button) then
            MultiBot.doRepos("Tanker", -34)
            MultiBot.doRepos("Attack", -34)
            MultiBot.doRepos("Mode", -34)
            leftRoot.buttons["ExpandFollow"]:Show()
            leftRoot.buttons["ExpandStay"]:Show()
            leftRoot.buttons["Follow"]:Hide()
            leftRoot.buttons["Stay"]:Hide()
            return
        end

        MultiBot.doRepos("Tanker", 34)
        MultiBot.doRepos("Attack", 34)
        MultiBot.doRepos("Mode", 34)
        leftRoot.buttons["ExpandFollow"]:Hide()
        leftRoot.buttons["ExpandStay"]:Hide()
        leftRoot.buttons["Follow"]:Show()
        leftRoot.buttons["Stay"]:Show()
    end)
end

local function toggleRelease(button)
    MultiBot.auto.release = MultiBot.OnOffSwitch(button) and true or false
end

local function toggleStats(button)
    if GetNumRaidMembers() > 0 then
        SendChatMessage(MultiBot.L("info.stats"), "SAY")
        return
    end

    if MultiBot.OnOffSwitch(button) then
        MultiBot.auto.stats = true
        for index = 1, GetNumPartyMembers() do
            SendChatMessage("stats", "WHISPER", nil, UnitName("party" .. index))
        end
        MultiBot.stats:Show()
        return
    end

    MultiBot.auto.stats = false
    for _, value in pairs(MultiBot.stats.frames) do
        value:Hide()
    end
    MultiBot.stats:Hide()
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