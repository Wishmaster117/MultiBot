if not MultiBot then return end

local INVENTORY_WINDOW_DEFAULTS = {
    width = 520,
    height = 470,
    pointX = -700,
    pointY = -144,
    actionsWidth = 100,
    panelInset = 8,
    panelGap = 6,
    buttonSize = 32,
    buttonSpacing = 36,
    buttonOffsetX = 6,
    buttonStartOffsetY = 106,
    modeLabelHeight = 34,
    helperTextOffsetY = 6,
    helperTextHeight = 36,
    instantActionsTopPadding = 18,
    instantActionColumns = 3,
    instantActionSpacingX = 29,
    instantActionSpacingY = 34,
    itemSize = 32,
    itemSpacingX = 38,
    itemSpacingY = 37,
    itemsPerRow = 8,
    itemsPanelPadding = 8,
    scrollBarAllowance = 28,
    minCanvasHeight = 260,
}
local INVENTORY_LAYOUT_KEY = "InventoryPoint"

local ACTION_ORDER = { "Sell", "Equip", "Use", "Trade", "Destroy" }
local ACTION_MODE_CONFIG = {
    Sell = { value = "s", cancelTradeOnActivate = true },
    Equip = { value = "e", cancelTradeOnActivate = true },
    Use = { value = "u", cancelTradeOnActivate = true },
    Trade = { value = "give", cancelTradeOnActivate = false },
    Destroy = { value = "destroy", cancelTradeOnActivate = true },
}

local function getInventoryAceGUI()
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

local inventoryEscapeIndex = 0
local function registerInventoryEscapeClose(window, namePrefix)
    if not window or not window.frame or type(UISpecialFrames) ~= "table" then
        return
    end

    if window.__mbEscapeName then
        return
    end

    inventoryEscapeIndex = inventoryEscapeIndex + 1
    local safePrefix = tostring(namePrefix or "Inventory"):gsub("[^%w_]", "")
    local frameName = string.format("MultiBotAce%s_%d", safePrefix, inventoryEscapeIndex)

    window.__mbEscapeName = frameName
    _G[frameName] = window.frame

    for _, existing in ipairs(UISpecialFrames) do
        if existing == frameName then
            return
        end
    end

    table.insert(UISpecialFrames, frameName)
end

local function persistInventoryWindowPosition(frame)
    if not frame or not MultiBot.SetSavedLayoutValue or not MultiBot.toPoint then
        return
    end

    local offsetX, offsetY = MultiBot.toPoint(frame)
    MultiBot.SetSavedLayoutValue(INVENTORY_LAYOUT_KEY, offsetX .. ", " .. offsetY)
end

local function bindInventoryWindowPosition(window)
    if not window or not window.frame then
        return
    end

    local savedPoint = MultiBot.GetSavedLayoutValue and MultiBot.GetSavedLayoutValue(INVENTORY_LAYOUT_KEY) or nil
    if type(savedPoint) == "string" and savedPoint ~= "" then
        local splitPoint = MultiBot.doSplit(savedPoint, ", ")
        local offsetX = tonumber(splitPoint[1])
        local offsetY = tonumber(splitPoint[2])
        if offsetX and offsetY then
            window.frame:ClearAllPoints()
            window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", offsetX, offsetY)
        end
    end

    if window.__mbPositionHooked then
        return
    end

    window.__mbPositionHooked = true
    window.frame:HookScript("OnDragStop", function(frame)
        persistInventoryWindowPosition(frame)
    end)
end

local function addSimpleBackdrop(frame, bgAlpha)
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
        frame:SetBackdropColor(0.06, 0.06, 0.08, bgAlpha or 0.92)
    end

    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.95)
    end
end

local function makeActionButton(parent, key, iconTexture, tooltipText, yOffset, xOffset)
    local size = INVENTORY_WINDOW_DEFAULTS.buttonSize
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset or INVENTORY_WINDOW_DEFAULTS.buttonOffsetX, yOffset)
    button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(MultiBot.SafeTexturePath(iconTexture))

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    button.border:Hide()

    button.state = false
    button.tip = tooltipText
    button.parent = parent.inventoryRef
    button.actionKey = key

    function button.setDisable(_)
        button.state = false
        if button.icon and button.icon.SetDesaturated then
            button.icon:SetDesaturated(true)
        end
        if button.border then
            button.border:Hide()
        end
        return button
    end

    function button.setEnable(_)
        button.state = true
        if button.icon and button.icon.SetDesaturated then
            button.icon:SetDesaturated(false)
        end
        if button.border then
            button.border:Show()
        end
        return button
    end

    function button.getButton(_, index)
        return button.parent and button.parent.getButton and button.parent.getButton(index) or nil
    end

    function button.getName()
        return MultiBot.inventory and MultiBot.inventory.name or nil
    end

    button:SetScript("OnEnter", function(self)
        if not self.tip or not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip and GameTooltip.Hide then
            GameTooltip:Hide()
        end
    end)

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" and self.doLeft then
            self.doLeft(self)
            return
        end

        if mouseButton == "RightButton" and self.doRight then
            self.doRight(self)
        end
    end)

    return button
end

local function makeItemsContainer(parent, scrollChild)
    local items = {
        host = parent,
        child = scrollChild,
        buttons = {},
        index = 0,
        iconSize = INVENTORY_WINDOW_DEFAULTS.itemSize,
        spacingX = INVENTORY_WINDOW_DEFAULTS.itemSpacingX,
        spacingY = INVENTORY_WINDOW_DEFAULTS.itemSpacingY,
        itemsPerRow = INVENTORY_WINDOW_DEFAULTS.itemsPerRow,
    }

    function items:getName()
        return MultiBot.inventory and MultiBot.inventory.name or nil
    end

    function items:get()
        return MultiBot.inventory
    end

    function items.getButton(index)
        return MultiBot.inventory and MultiBot.inventory.getButton and MultiBot.inventory.getButton(index) or nil
    end

    function items:getAvailableWidth()
        local hostWidth = self.host and self.host.GetWidth and self.host:GetWidth() or 0
        local horizontalPadding = (INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding * 2) + INVENTORY_WINDOW_DEFAULTS.scrollBarAllowance
        return math.max(self.iconSize, hostWidth - horizontalPadding)
    end

    function items:refreshLayoutMetrics()
        local stepX = math.max(self.iconSize, self.spacingX or self.iconSize)
        local usableWidth = self:getAvailableWidth()
        local additionalSlots = math.floor(math.max(0, usableWidth - self.iconSize) / stepX)
        self.itemsPerRow = math.max(1, additionalSlots + 1)
        self.child:SetWidth(math.max(usableWidth, self.itemsPerRow * stepX))
    end

    function items:getNextSlotPosition()
        self:refreshLayoutMetrics()
        local perRow = math.max(1, self.itemsPerRow or 1)
        local posX = (self.index % perRow) * (self.spacingX or 0)
        local posY = math.floor(self.index / perRow) * -(self.spacingY or 0)
        return posX, posY
    end

    function items:addChatItem(itemInfo)
        if not itemInfo or itemInfo == "" or not MultiBot.InventoryAddItem then
            return nil
        end

        return MultiBot.InventoryAddItem(self, itemInfo)
    end

    function items:clear()
        for key, button in pairs(self.buttons) do
            if button and button.Hide then
                button:Hide()
            end
            self.buttons[key] = nil
        end
        self.index = 0
        self:updateCanvas()
    end

    function items:updateCanvas()
        self:refreshLayoutMetrics()

        local count = math.max(self.index or 0, 0)
        if count == 0 then
            for _ in pairs(self.buttons) do
                count = count + 1
            end
        end

        local rows = math.max(1, math.ceil(count / math.max(1, self.itemsPerRow or 1)))
        local height = math.max(INVENTORY_WINDOW_DEFAULTS.minCanvasHeight, 20 + (rows * self.spacingY))
        self.child:SetHeight(height)
    end

    function items:updateLayout()
        self:refreshLayoutMetrics()

        for _, button in pairs(self.buttons) do
            if button and button.ClearAllPoints then
                local layoutIndex = button.layoutIndex or 0
                local posX = (layoutIndex % self.itemsPerRow) * (self.spacingX or 0)
                local posY = math.floor(layoutIndex / self.itemsPerRow) * -(self.spacingY or 0)
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", self.child, "TOPLEFT", posX, posY)
                button.x = posX
                button.y = posY
            end
        end

        self:updateCanvas()
    end

    function items.addButton(pName, pX, pY, pTexture, pTip)
        local button = CreateFrame("Button", nil, items.child)
        button:SetSize(items.iconSize, items.iconSize)
        button:SetPoint("TOPLEFT", items.child, "TOPLEFT", pX, pY)
        button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")

        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints(button)
        button.icon:SetTexture(MultiBot.SafeTexturePath(pTexture))

        button.border = button:CreateTexture(nil, "OVERLAY")
        button.border:SetTexture("Interface\\AddOns\\MultiBot\\Icons\\border.blp")
        button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
        button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)

        button.parent = items
        button.name = pName
        button.tip = pTip
        button.texture = MultiBot.SafeTexturePath(pTexture)
        button.size = items.iconSize
        button.layoutIndex = items.index or 0
        button.x = pX
        button.y = pY

        function button.setAmount(pAmount)
            if button.amount and button.amount.Hide then
                button.amount:Hide()
            end
            button.amount = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            button.amount:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, 1)
            button.amount:SetText(pAmount)
            return button
        end

        function button.getButton(_, index)
            return button.parent and button.parent.getButton and button.parent.getButton(index) or nil
        end

        function button.getName()
            return items:getName()
        end

        button:SetScript("OnEnter", function(self)
            if not self.tip or not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if type(self.tip) == "string" and string.sub(self.tip, 1, 1) == "|" then
                GameTooltip:SetHyperlink(self.tip)
            else
                GameTooltip:SetText(self.tip, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            if GameTooltip and GameTooltip.Hide then
                GameTooltip:Hide()
            end
        end)

        button:SetScript("OnClick", function(self, mouseButton)
            if mouseButton == "LeftButton" and self.doLeft then
                self.doLeft(self)
                return
            end

            if mouseButton == "RightButton" and self.doRight then
                self.doRight(self)
            end
        end)

        items.buttons[pName] = button
        items:updateLayout()
        return button
    end

    return items
end

local function updateModeLabel()
    local inventory = MultiBot.inventory
    if not inventory or not inventory.modeLabel then
        return
    end

    local labels = {
        [""] = MultiBot.L("info.action", "Action") .. ": -",
        s = MultiBot.L("info.action", "Action") .. ": Sell",
        e = MultiBot.L("info.action", "Action") .. ": Equip",
        u = MultiBot.L("info.action", "Action") .. ": Use",
        give = MultiBot.L("info.action", "Action") .. ": Trade",
        destroy = MultiBot.L("info.action", "Action") .. ": Destroy",
    }

    inventory.modeLabel:SetText(labels[inventory.action or ""] or (MultiBot.L("info.action", "Action") .. ": -"))
end

local function getInventoryWindowTitle(botName)
    local defaultTitle = MB_INVENTORY_LABEL or INVENTORY_TOOLTIP or BAGSLOT or "Inventory"
    if not botName or botName == "" then
        return defaultTitle
    end

    return MultiBot.doReplace(MultiBot.L("info.inventory", defaultTitle), "NAME", botName)
end

local function disableActionModes(exceptKey)
    local inventory = MultiBot.inventory
    if not inventory or not inventory.buttons then
        return
    end

    for _, key in ipairs(ACTION_ORDER) do
        if key ~= exceptKey then
            local button = inventory.buttons[key]
            if button and button.setDisable then
                button.setDisable()
            end
        end
    end
end

local function syncInventoryButtonState(enabled)
    local inventory = MultiBot.inventory
    if not inventory or not inventory.name then
        return
    end

    local units = MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames["Units"]

    local unitFrame = units and units.frames and units.frames[inventory.name] or nil
    local sourceButton = unitFrame and unitFrame.getButton and unitFrame.getButton("Inventory") or nil
    if not sourceButton then
        return
    end

    if enabled then
        if sourceButton.setEnable then sourceButton.setEnable() end
    else
        if sourceButton.setDisable then sourceButton.setDisable() end
    end
end

local function getInventoryUnitsFrame()
    return MultiBot.frames
        and MultiBot.frames["MultiBar"]
        and MultiBot.frames["MultiBar"].frames
        and MultiBot.frames["MultiBar"].frames["Units"]
        or nil
end

local function getInventorySourceButton(botName)
    if not botName or botName == "" then
        return nil
    end

    local units = getInventoryUnitsFrame()
    local unitFrame = units and units.frames and units.frames[botName] or nil
    return unitFrame and unitFrame.getButton and unitFrame.getButton("Inventory") or nil
end

local function getInventoryWaitButton(botName)
    if not botName or botName == "" then
        return nil
    end

    local units = getInventoryUnitsFrame()
    return units and units.buttons and units.buttons[botName] or nil
end

local function disableOtherInventoryButtons(activeBotName)
    local units = getInventoryUnitsFrame()
    if not units or not MultiBot.index or not MultiBot.index.actives then
        return
    end

    for _, botName in pairs(MultiBot.index.actives) do
        if botName ~= UnitName("player") then
            local button = units.frames
                and units.frames[botName]
                and units.frames[botName].getButton
                and units.frames[botName].getButton("Inventory")
                or nil

            if button and button.setDisable and botName ~= activeBotName then
                button.setDisable()
            end
        end
    end
end

local function setInventoryBotName(botName)
    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    inventory.name = botName or ""

    if inventory.window and inventory.window.SetTitle then
        inventory.window:SetTitle(getInventoryWindowTitle(inventory.name))
    end

    if inventory.helperText then
        inventory.helperText:SetText(botName or "")
    end
end

local function resetInventoryViewState()
    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    setInventoryBotName("")
    inventory.pendingLootBot = nil

    if inventory.resetItems then
        inventory:resetItems()
    end
end

local function requestInventoryForBot(botName)
    local waitButton = getInventoryWaitButton(botName)
    if waitButton then
        waitButton.waitFor = "INVENTORY"
    end

    if botName and botName ~= "" then
        SendChatMessage("items", "WHISPER", nil, botName)
    end
end

MultiBot.RequestBotInventory = function(botName)
    if not botName or botName == "" then
        return false
    end

    local inventory = MultiBot.inventory
    if (not inventory or not inventory.requestBotInventory) and MultiBot.InitializeInventoryFrame then
        inventory = MultiBot.InitializeInventoryFrame()
    end

    if inventory and inventory.requestBotInventory then
        return inventory:requestBotInventory(botName)
    end

    requestInventoryForBot(botName)
    return true
end

local function closeInventoryWindow()
    local inventory = MultiBot.inventory
    if not inventory then return end
    if inventory.window then
        inventory.window:Hide()
    end
    syncInventoryButtonState(false)
    resetInventoryViewState()
end

local function openInventoryWindow()
    local inventory = MultiBot.inventory
    if inventory and inventory.window then
        inventory.window:Show()
        syncInventoryButtonState(true)
    end
end

local function prepareInventoryForBot(botName)
    if not botName or botName == "" then
        return false
    end

    disableOtherInventoryButtons(botName)
    setInventoryBotName(botName)

    local sourceButton = getInventorySourceButton(botName)
    if sourceButton and sourceButton.setEnable then
        sourceButton.setEnable()
    end

    requestInventoryForBot(botName)
    return true
end

local function setInventoryActionState(buttonKey, options)
    local inventory = MultiBot.inventory
    if not inventory then
        return
    end

    options = options or {}

    local nextState = buttonKey and ACTION_MODE_CONFIG[buttonKey] or nil
    local previousAction = inventory.action or ""
    local shouldCancelTrade = options.cancelTrade

    if shouldCancelTrade == nil then
        shouldCancelTrade = previousAction == ACTION_MODE_CONFIG.Trade.value
            and (not nextState or nextState.value ~= ACTION_MODE_CONFIG.Trade.value)
    end

    if shouldCancelTrade then
        CancelTrade()
    end

    inventory.action = nextState and nextState.value or ""
    disableActionModes(buttonKey)

    if nextState then
        local button = inventory.buttons and inventory.buttons[buttonKey] or nil
        if button and button.setEnable then
            button.setEnable()
        end
    end

    updateModeLabel()
end

local function toggleInventoryAction(buttonKey, button)
    local inventory = MultiBot.inventory
    local state = ACTION_MODE_CONFIG[buttonKey]
    if not inventory or not state or not button then
        return
    end

    if button.state then
        setInventoryActionState(nil, {
            cancelTrade = state.value == ACTION_MODE_CONFIG.Trade.value,
        })
        return
    end

    if buttonKey == "Trade" then
        InitiateTrade(button.getName())
    end

    setInventoryActionState(buttonKey, {
        cancelTrade = state.cancelTradeOnActivate,
    })
end

local function runInventoryInstantAction(botName, command, options)
    options = options or {}

    if not botName or botName == "" or not command or command == "" then
        return false
    end

    if options.requiresTarget and not MultiBot.isTarget() then
        return false
    end

    if options.clearActionState then
        CancelTrade()
        setInventoryActionState(nil, { cancelTrade = false })
    end

    SendChatMessage(command, "WHISPER", nil, botName)

    if options.refreshDelay ~= nil and MultiBot.RefreshInventory then
        MultiBot.RefreshInventory(options.refreshDelay)
    elseif options.refresh and MultiBot.RefreshInventory then
        MultiBot.RefreshInventory()
    end

    return true
end

local function createInventoryContent(window)
    local content = window.content
    content:SetPoint("TOPLEFT", window.frame, "TOPLEFT", 10, -30)
    content:SetPoint("BOTTOMRIGHT", window.frame, "BOTTOMRIGHT", -10, 10)

    local panelInset = INVENTORY_WINDOW_DEFAULTS.panelInset
    local panelGap = INVENTORY_WINDOW_DEFAULTS.panelGap

    local root = CreateFrame("Frame", nil, content)
    root:SetAllPoints(content)
    addSimpleBackdrop(root, 0.90)

    local leftPanel = CreateFrame("Frame", nil, root)
    leftPanel:SetPoint("TOPLEFT", root, "TOPLEFT", panelInset, -panelInset)
    leftPanel:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", panelInset, panelInset)
    leftPanel:SetWidth(INVENTORY_WINDOW_DEFAULTS.actionsWidth)
    addSimpleBackdrop(leftPanel, 0.55)

    local itemsPanel = CreateFrame("Frame", nil, root)
    itemsPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", panelGap, 0)
    itemsPanel:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -panelInset, panelInset)
    addSimpleBackdrop(itemsPanel, 0.55)

    local modeLabel = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    modeLabel:SetPoint("TOPLEFT", leftPanel, "TOPLEFT", 10, -14)
    modeLabel:SetPoint("TOPRIGHT", leftPanel, "TOPRIGHT", -8, -14)
    modeLabel:SetJustifyH("LEFT")
    modeLabel:SetJustifyV("TOP")
    modeLabel:SetHeight(INVENTORY_WINDOW_DEFAULTS.modeLabelHeight)
    if modeLabel.SetNonSpaceWrap then
        modeLabel:SetNonSpaceWrap(true)
    end
    if modeLabel.SetWordWrap then
        modeLabel:SetWordWrap(true)
    end
    modeLabel:SetText(MultiBot.L("info.action", "Action") .. ": Sell")

    local helperText = leftPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    helperText:SetPoint("TOPLEFT", modeLabel, "BOTTOMLEFT", 0, -INVENTORY_WINDOW_DEFAULTS.helperTextOffsetY)
    helperText:SetPoint("TOPRIGHT", modeLabel, "BOTTOMRIGHT", 0, -INVENTORY_WINDOW_DEFAULTS.helperTextOffsetY)
    helperText:SetJustifyH("LEFT")
    helperText:SetJustifyV("TOP")
    helperText:SetHeight(INVENTORY_WINDOW_DEFAULTS.helperTextHeight)
    if helperText.SetWordWrap then
        helperText:SetWordWrap(true)
    end
    helperText:SetText("")

    local scrollFrame = CreateFrame("ScrollFrame", "MultiBotInventoryScrollFrame", itemsPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", itemsPanel, "TOPLEFT", INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding, -INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding)
    scrollFrame:SetPoint("BOTTOMRIGHT", itemsPanel, "BOTTOMRIGHT", -INVENTORY_WINDOW_DEFAULTS.scrollBarAllowance, INVENTORY_WINDOW_DEFAULTS.itemsPanelPadding)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(1)
    scrollChild:SetHeight(INVENTORY_WINDOW_DEFAULTS.minCanvasHeight)
    scrollFrame:SetScrollChild(scrollChild)

    local actionHost = { inventoryRef = nil }
    local buttons = {}
    local modeButtonDefs = {
        { key = "Sell", texture = "inv_misc_coin_16", tip = MultiBot.L("tips.inventory.sell") },
        { key = "Equip", texture = "inv_helmet_22", tip = MultiBot.L("tips.inventory.equip") },
        { key = "Use", texture = "inv_gauntlets_25", tip = MultiBot.L("tips.inventory.use") },
        { key = "Trade", texture = "achievement_reputation_01", tip = MultiBot.L("tips.inventory.trade") },
        { key = "Destroy", texture = "inv_hammer_15", tip = MultiBot.L("tips.inventory.drop") },
    }
    local instantButtonDefs = {
        { key = "SellGrey", texture = "inv_misc_coin_03", tip = MultiBot.L("tips.inventory.sellgrey") },
        { key = "SellVendor", texture = "inv_misc_coin_04", tip = MultiBot.L("tips.inventory.sellvendor") },
        { key = "Open", texture = "inv_misc_gift_05", tip = MultiBot.L("tips.inventory.open") },
    }

    for index, definition in ipairs(modeButtonDefs) do
        local yOffset = -INVENTORY_WINDOW_DEFAULTS.buttonStartOffsetY - ((index - 1) * INVENTORY_WINDOW_DEFAULTS.buttonSpacing)
        buttons[definition.key] = makeActionButton(leftPanel, definition.key, definition.texture, definition.tip, yOffset)
    end

    local instantStartY = -INVENTORY_WINDOW_DEFAULTS.buttonStartOffsetY
        - (#modeButtonDefs * INVENTORY_WINDOW_DEFAULTS.buttonSpacing)
        - INVENTORY_WINDOW_DEFAULTS.instantActionsTopPadding
    local instantColumns = math.max(1, INVENTORY_WINDOW_DEFAULTS.instantActionColumns or 1)
    local instantSpacingX = INVENTORY_WINDOW_DEFAULTS.instantActionSpacingX or INVENTORY_WINDOW_DEFAULTS.buttonSpacing
    local instantSpacingY = INVENTORY_WINDOW_DEFAULTS.instantActionSpacingY or INVENTORY_WINDOW_DEFAULTS.buttonSpacing
    for index, definition in ipairs(instantButtonDefs) do
        local column = (index - 1) % instantColumns
        local row = math.floor((index - 1) / instantColumns)
        local xOffset = INVENTORY_WINDOW_DEFAULTS.buttonOffsetX + (column * instantSpacingX)
        local yOffset = instantStartY - (row * instantSpacingY)
        buttons[definition.key] = makeActionButton(leftPanel, definition.key, definition.texture, definition.tip, yOffset, xOffset)
    end

    local items = makeItemsContainer(itemsPanel, scrollChild)
    items:updateLayout()

    itemsPanel:SetScript("OnSizeChanged", function()
        items:updateLayout()
    end)

    return {
        root = root,
        leftPanel = leftPanel,
        itemsPanel = itemsPanel,
        items = items,
        modeLabel = modeLabel,
        helperText = helperText,
        actionHost = actionHost,
        buttons = buttons,
    }
end

function MultiBot.InitializeInventoryFrame()
    if MultiBot.inventory and MultiBot.inventory.__aceInitialized then
        return MultiBot.inventory
    end

    local aceGUI = getInventoryAceGUI()
    if not aceGUI then
        UIErrorsFrame:AddMessage("AceGUI-3.0 is required for Inventory", 1, 0.2, 0.2, 1)
        return nil
    end

    local window = aceGUI:Create("Window")
    window:SetTitle(getInventoryWindowTitle(nil))
    window:SetLayout("Manual")
    window:SetWidth(INVENTORY_WINDOW_DEFAULTS.width)
    window:SetHeight(INVENTORY_WINDOW_DEFAULTS.height)
    window:EnableResize(false)
    window.frame:SetClampedToScreen(true)
    window.frame:SetFrameStrata("HIGH")
    window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", INVENTORY_WINDOW_DEFAULTS.pointX, INVENTORY_WINDOW_DEFAULTS.pointY)
    window:SetCallback("OnClose", function(widget)
        closeInventoryWindow()
        widget:Hide()
    end)
    window:Hide()
    window.frame:HookScript("OnHide", function()
        syncInventoryButtonState(false)
    end)

    registerInventoryEscapeClose(window, "Inventory")
    bindInventoryWindowPosition(window)

    local content = createInventoryContent(window)

    local inventory = {
        __aceInitialized = true,
        window = window,
        root = content.root,
        buttons = content.buttons,
        frames = { Items = content.items },
        texts = { Title = content.modeLabel },
        modeLabel = content.modeLabel,
        helperText = content.helperText,
        name = "",
        action = "s",
        pendingLootBot = nil,
    }

    MultiBot.inventory = inventory

    content.actionHost.inventoryRef = inventory
    for _, button in pairs(content.buttons) do
        button.parent = inventory
    end

    function inventory.setText(key, value)
        if key == "Title" then
            if inventory.window and inventory.window.SetTitle then
                inventory.window:SetTitle(value or getInventoryWindowTitle(inventory.name))
            end
            return inventory
        end

        if key == "Mode" and inventory.modeLabel then
            inventory.modeLabel:SetText(value or "")
        end
        return inventory
    end

    function inventory.getButton(index)
        return inventory.buttons and inventory.buttons[index] or nil
    end

    function inventory.getFrame(index)
        return inventory.frames and inventory.frames[index] or nil
    end

    function inventory:Show()
        openInventoryWindow()
    end

    function inventory:Hide()
        closeInventoryWindow()
    end

    function inventory:IsVisible()
        return self.window and self.window.frame and self.window.frame:IsShown() or false
    end

    function inventory:GetRight()
        return self.window and self.window.frame and self.window.frame:GetRight() or 0
    end

    function inventory:GetBottom()
        return self.window and self.window.frame and self.window.frame:GetBottom() or 0
    end

    function inventory.setPoint(x, y)
        if type(x) ~= "number" or type(y) ~= "number" then return end
        window.frame:ClearAllPoints()
        window.frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x, y)
        persistInventoryWindowPosition(window.frame)
    end

    function inventory:resetItems()
        local items = self.frames and self.frames.Items
        if items and items.clear then
            items:clear()
        end
        if items then
            items.index = 0
        end
    end

    function inventory:setBotName(botName)
        setInventoryBotName(botName)
        return inventory
    end

    function inventory:requestBotInventory(botName)
        return prepareInventoryForBot(botName)
    end

    function inventory:refresh(delay, botName)
        local targetBotName = botName or self.name
        if not targetBotName or targetBotName == "" or not self:IsVisible() then
            return false
        end

        local function doRefresh()
            if not self:IsVisible() then
                return false
            end

            return prepareInventoryForBot(targetBotName)
        end

        if type(delay) == "number" and delay > 0 and MultiBot.TimerAfter then
            MultiBot.TimerAfter(delay, doRefresh)
            return true
        end

        return doRefresh()
    end

    function inventory:markLootPending(botName)
        local targetBotName = botName or self.name
        if not targetBotName or targetBotName == "" then
            return false
        end

        self.pendingLootBot = targetBotName
        return true
    end

    function inventory:handleLootReceived(botName)
        local targetBotName = botName or self.pendingLootBot
        if not targetBotName or targetBotName == "" then
            return false
        end

        if self.pendingLootBot and self.pendingLootBot ~= targetBotName then
            return false
        end

        self.pendingLootBot = nil
        return self:refresh(nil, targetBotName)
    end

    function inventory:beginPayload(botName)
        setInventoryBotName(botName or "")
        self.pendingLootBot = nil
        self:resetItems()
        return self
    end

    function inventory:appendItem(itemInfo)
        local items = self.frames and self.frames.Items
        if items and items.addChatItem then
            return items:addChatItem(itemInfo)
        end

        if MultiBot.addItem and items then
            return MultiBot.addItem(items, itemInfo)
        end

        return nil
    end

    for _, key in ipairs(ACTION_ORDER) do
        inventory.buttons[key].doLeft = function(pButton)
            toggleInventoryAction(key, pButton)
        end
    end

    inventory.buttons.SellGrey.doLeft = function(pButton)
        runInventoryInstantAction(pButton.getName(), "s *", {
            requiresTarget = true,
            clearActionState = true,
            refreshDelay = 0.5,
        })
    end

    inventory.buttons.SellVendor.doLeft = function(pButton)
        runInventoryInstantAction(pButton.getName(), "s vendor", {
            requiresTarget = true,
            clearActionState = true,
            refresh = true,
        })
    end

    inventory.buttons.Open.doLeft = function(pButton)
        runInventoryInstantAction(pButton.getName(), "open items")
    end

    setInventoryActionState("Sell", { cancelTrade = false })
    resetInventoryViewState()

    return inventory
end