if not MultiBot then return end

local function inventoryItemL(key, fallback)
    return MultiBot.L("info." .. key, fallback)
end

local function buildInventoryButtonKey(frame, itemName)
    return string.format("%s_%d", itemName or "Item", frame.index or 0)
end

local function buildInventoryItemLink(parts)
    return "|" .. parts[2] .. "|" .. parts[3] .. "|" .. parts[4] .. "|h|r"
end

local function splitInventoryItemPayload(itemInfo)
    local parts = MultiBot.doSplit(itemInfo or "", "|")
    local itemData = parts[3] and MultiBot.doSplit(parts[3], ":") or {}
    return parts, itemData
end

local function extractInventoryItemCount(parts)
    local amountInfo = parts and parts[6] or nil
    if type(amountInfo) ~= "string" or string.sub(amountInfo, 1, 2) ~= "rx" then
        return nil
    end

    local amountToken = MultiBot.doSplit(amountInfo, " ")[1]
    local amount = tonumber(string.sub(amountToken or "", 3))
    return amount and amount > 1 and amount or nil
end

local function resolveInventoryItemName(parts, itemName)
    if itemName ~= nil then
        return itemName
    end

    local rawLinkText = parts and parts[4] or nil
    if type(rawLinkText) ~= "string" or string.len(rawLinkText) < 4 then
        return "Item"
    end

    return string.sub(rawLinkText, 3, string.len(rawLinkText) - 1)
end

local function resolveInventoryItemLink(parts, itemLink)
    if itemLink ~= nil then
        return itemLink
    end

    return buildInventoryItemLink(parts)
end

local function resolveInventoryItemRarity(itemRare)
    if itemRare ~= nil then
        return itemRare
    end

    return 4
end

local function getInventoryItemPosition(frame)
    if frame and frame.getNextSlotPosition then
        return frame:getNextSlotPosition()
    end

    local index = (frame and frame.index) or 0
    local itemsPerRow = (frame and frame.itemsPerRow) or 8
    local spacingX = (frame and frame.spacingX) or 38
    local spacingY = (frame and frame.spacingY) or 37
    return (index % itemsPerRow) * spacingX, math.floor(index / itemsPerRow) * -spacingY
end

local function buildInventoryItemRecord(itemInfo)
    local parts, itemData = splitInventoryItemPayload(itemInfo)
    local itemId = itemData[2]
    if not itemId or itemId == "" then
        return nil
    end

    local itemIcon = GetItemIcon(itemId)
    local itemName, itemLink, itemRare, _, _, itemType, itemSubType, _, _, _, _, itemClassId = GetItemInfo(itemId)

    return {
        id = itemId,
        icon = itemIcon,
        name = resolveInventoryItemName(parts, itemName),
        link = resolveInventoryItemLink(parts, itemLink),
        rare = resolveInventoryItemRarity(itemRare),
        itemType = itemType,
        itemSubType = itemSubType,
        itemClassId = itemClassId,
        count = extractInventoryItemCount(parts),
        info = itemInfo,
        parts = parts,
    }
end

local function getInventoryItemActionState()
    local inventory = MultiBot.inventory or {}
    return inventory.action or "", inventory.name or ""
end

local function requestInventoryRefresh(delay)
    if MultiBot.RefreshInventory then
        MultiBot.RefreshInventory(delay)
    end
end

local function bindInventoryDestroyConfirm(button, botName)
    if not StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] then
        StaticPopupDialogs["MULTIBOT_CONFIRM_DESTROY"] = {
            text = inventoryItemL("itemdestroyalert", "Are you sure you want to destroy this item?"),
            button1 = OKAY,
            button2 = CANCEL,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1,
            OnAccept = function(_, data)
                if not data or not data.button then return end
                sendInventoryItemCommand("destroy", data.button, data.botName, {
                    hideButton = true,
                })
            end,
        }
    end

    StaticPopup_Show("MULTIBOT_CONFIRM_DESTROY", button.item.link, nil, {
        button = button,
        botName = botName,
    })
end

local function sendInventoryFeedback(key, fallback)
    SendChatMessage(inventoryItemL(key, fallback), "SAY")
end

local function isInventoryProtectedKey(item)
    return MultiBot.isInside(item and item.info or "", "%f[%a][Kk]ey%f[%A]")
end

local function isInventoryProtectedHearthstone(item)
    return item and item.id == "6948"
end

local inventorySellGuardTooltipName = "MB_InventorySellGuardTooltip"
local function getInventorySellGuardTooltip()
    if MultiBot.AceUI and MultiBot.AceUI.EnsureHiddenTooltip then
        return MultiBot.AceUI.EnsureHiddenTooltip(inventorySellGuardTooltipName, UIParent)
    end

    local tooltip = _G[inventorySellGuardTooltipName]
    if tooltip then
        return tooltip
    end

    tooltip = CreateFrame("GameTooltip", inventorySellGuardTooltipName, UIParent, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    return tooltip
end

local function tooltipContainsQuestHint(itemLink)
    if type(itemLink) ~= "string" or itemLink == "" then
        return false
    end

    local tooltip = getInventorySellGuardTooltip()
    if not tooltip then
        return false
    end

    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)

    local questMarkers = {
        ITEM_STARTS_QUEST,
        QUESTS_LABEL,
        TRACKER_HEADER_QUESTS,
        "Quest",
        "Quête",
        "任务",
        "퀘스트",
    }

    for lineIndex = 1, 12 do
        local line = _G[inventorySellGuardTooltipName .. "TextLeft" .. lineIndex]
        local text = line and line.GetText and line:GetText() or nil
        if text and text ~= "" then
            for _, marker in ipairs(questMarkers) do
                if type(marker) == "string" and marker ~= "" and string.find(text, marker, 1, true) then
                    return true
                end
            end
        end
    end

    return false
end

local function isInventoryQuestType(item)
    if not item then
        return false
    end

    local itemType = tostring(item.itemType or "")
    local questTypeTokens = {
        QUESTS_LABEL,
        TRACKER_HEADER_QUESTS,
        "Quest",
        "Quête",
        "任务",
        "퀘스트",
    }

    for _, token in ipairs(questTypeTokens) do
        if type(token) == "string" and token ~= "" and itemType == token then
            return true
        end
    end

    return false
end

local function isInventoryProtectedQuestItem(item)
    if not item then
        return false
    end

    if isInventoryQuestType(item) then
        return true
    end

    return tooltipContainsQuestHint(item.link)
end

local function needsInventoryDestroyConfirmation(item)
    return isInventoryProtectedHearthstone(item)
        or isInventoryProtectedKey(item)
        or ((item and item.rare or 0) > 3)
end

local function sendInventoryItemCommand(command, button, botName, options)
    options = options or {}

    if not command or command == "" or not button or not botName or botName == "" then
        return false
    end

    SendChatMessage(command .. " " .. button.tip, "WHISPER", nil, botName)

    if options.hideButton and button.Hide then
        button:Hide()
    end

    if options.refreshDelay ~= nil then
        requestInventoryRefresh(options.refreshDelay)
    elseif options.refresh then
        requestInventoryRefresh()
    end

    if options.followupRefreshDelay ~= nil then
        requestInventoryRefresh(options.followupRefreshDelay)
    end

    return true
end

local function handleInventoryItemClick(button)
    local action, botName = getInventoryItemActionState()
    local item = button and button.item or nil

    if action == "" then
        sendInventoryFeedback("action", "Choose an action first")
        return
    end

    if action == "s" then
        if not MultiBot.isTarget() then
            sendInventoryFeedback("inventoryvendortarget", "Target a vendor first")
            return
        end

        if isInventoryProtectedHearthstone(item) then
            sendInventoryFeedback("itemsellalert", "You cannot sell this item")
            return
        end

        if isInventoryProtectedKey(item) then
            sendInventoryFeedback("keydestroyalert", "I will not sell Keys.")
            return
        end

        if isInventoryProtectedQuestItem(item) then
            sendInventoryFeedback("itemsellalert", "I will not sell quest items.")
            return
        end

        sendInventoryItemCommand(action, button, botName, {
            hideButton = true,
            refreshDelay = 0.3,
        })
        return
    end

    if action == "e" or action == "give" then
        sendInventoryItemCommand(action, button, botName)
        return
    end

    if action == "u" then
        sendInventoryItemCommand(action, button, botName, {
            refreshDelay = 0.12,
            followupRefreshDelay = 0.45,
        })
        return
    end

    if action ~= "destroy" then
        return
    end

    if needsInventoryDestroyConfirmation(item) then
        bindInventoryDestroyConfirm(button, botName)
        return
    end

    sendInventoryItemCommand(action, button, botName, {
        hideButton = true,
    })
end

MultiBot.InventoryAddItem = function(frame, itemInfo)
    if not frame then
        return nil
    end

    local item = buildInventoryItemRecord(itemInfo)
    if not item then
        return nil
    end

    local itemX, itemY = getInventoryItemPosition(frame)
    local itemIndex = frame.index or 0
    local buttonKey = buildInventoryButtonKey(frame, item.name)
    local button = frame.addButton(buttonKey, itemX, itemY, item.icon, item.link)

    item.index = itemIndex
    item.x = itemX
    item.y = itemY
    button.item = item

    button.doLeft = handleInventoryItemClick

    if item.count then
        button.setAmount(item.count)
    end

    frame.index = itemIndex + 1
    return button
end

MultiBot.addItem = MultiBot.InventoryAddItem