-- UI/MultiBotPVPUI.lua
-- MultiBot PvP UI
local ADDON = "MultiBot"

local function CreateStyledFrame()
    -- Main frame
    local f = CreateFrame("Frame", "MultiBotPVPFrame", UIParent)
    f:SetSize(420, 460)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:Hide()
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Backdrop
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    if f.SetBackdropColor then f:SetBackdropColor(0, 0, 0, 0.8) end
    if f.SetBackdropBorderColor then f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end

    -- Header + title
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -6)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -6)
    titleBg:SetHeight(48)
    f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.Title:SetPoint("TOP", titleBg, "TOP", 0, -10)
    f.Title:SetText("MultiBot PvP Panel")

    -- Close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Content area
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 64)

    -- Column offsets (relative to right edge of section)
    local colOffsets = { -120, -80, -40 }

    -- Section factory (simple)
    local function CreateSection(parent, topOffset, height, title)
        local sec = CreateFrame("Frame", nil, parent)
        sec:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -topOffset)
        sec:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -topOffset)
        sec:SetHeight(height)
        sec.title = sec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        sec.title:SetPoint("TOPLEFT", sec, "TOPLEFT", 0, 0)
        sec.title:SetText(title)
        return sec
    end

    -- AddRow returns fontstrings so they can be updated later
    local function AddRow(sec, index, label, col1, col2, col3)
        local lineHeight, startY = 18, -22
        local y = startY - (index - 1) * lineHeight
        local lbl = sec:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("TOPLEFT", sec, "TOPLEFT", 4, y)
        lbl:SetText(label)
        local out = {}
        local vals = { col1 or "-", col2 or "-", col3 or "-" }
        for i = 1, 3 do
            local v = sec:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            v:SetPoint("TOPRIGHT", sec, "TOPRIGHT", colOffsets[i], y)
            v:SetText(vals[i])
            out[i] = v
        end
        return out
    end

    -- Build layout top-down
    local top = 0
    local spacing = 12

    -- Header that will display bot name (updated from whisper sender)
    local customHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -top)
    customHeader:SetText("Données PvP custom")
    top = top + 18 + 6

    -- HONNEUR section: only one row "Honneur"
    local honorHeight = 18 + 1 * 18 + 8
    local honor = CreateSection(content, top, honorHeight, "Honneur")

    -- Column header labels for Honneur (1st renamed Total)
    local hdr1 = honor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr1:SetPoint("TOPRIGHT", honor, "TOPRIGHT", colOffsets[1], -2)
    hdr1:SetText("Total")
    --local hdr2 = honor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    --hdr2:SetPoint("TOPRIGHT", honor, "TOPRIGHT", colOffsets[2], -2)
    --hdr2:SetText("Hier")
    --local hdr3 = honor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    --hdr3:SetPoint("TOPRIGHT", honor, "TOPRIGHT", colOffsets[3], -2)
    --hdr3:SetText("À vie")

    -- separator
    local sepH = honor:CreateTexture(nil, "ARTWORK")
    sepH:SetHeight(1)
    sepH:SetPoint("TOPLEFT", honor, "TOPLEFT", 0, -18)
    sepH:SetPoint("TOPRIGHT", honor, "TOPRIGHT", 0, -18)
    sepH:SetTexture(0.5, 0.5, 0.5, 0.6)

    -- Only the Honneur row (we keep placeholders)
    local honorRow = AddRow(honor, 1, "Honneur", "-", "-", "-")
	if honorRow[2] then honorRow[2]:Hide() end
    if honorRow[3] then honorRow[3]:Hide() end
    -- honorRow[1] = Total column fontstring

    top = top + honorHeight + spacing

    -- ARENE section: we create three sub-blocks, one per mode, stacked vertically
    local arenaBlockHeight = 18 + 2 * 18 + 6 -- title + two lines (team + rating) approx
    local arena = CreateSection(content, top, arenaBlockHeight * 3 + spacing * 2, "Arène")

    -- separator
    local sepH = arena:CreateTexture(nil, "ARTWORK")
    sepH:SetHeight(1)
    sepH:SetPoint("TOPLEFT", arena, "TOPLEFT", 0, -18)
    sepH:SetPoint("TOPRIGHT", arena, "TOPRIGHT", 0, -18)
    sepH:SetTexture(0.5, 0.5, 0.5, 0.6)

    -- Points d'Arène (affiché à gauche de la section Arène)
    arena.pointsLabel = arena:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arena.pointsLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", 120, 0)
    arena.pointsLabel:SetText("Points d'Arène:")

    arena.pointsValue = arena:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arena.pointsValue:SetPoint("LEFT", arena.pointsLabel, "RIGHT", 6, 0)
    arena.pointsValue:SetText("-")
	
    -- helper to create per-mode display inside arena
    local function CreateArenaModeRow(parent, idx, modeLabel, offsetY)
        -- mode title (e.g., "Mode: 2v2")
        local modeText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modeText:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offsetY -32)
        modeText:SetText("Mode: " .. modeLabel)

        -- team name
        local teamText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        teamText:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offsetY - 50)
        teamText:SetText("Equipe: No team")

        -- rating
        local ratingText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ratingText:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -offsetY - 34)
        ratingText:SetText("Cote équipe: -")

        return { mode = modeText, team = teamText, rating = ratingText }
    end

    -- create rows for 2v2, 3v3, 5v5
    local modes = { "2v2", "3v3", "5v5" }
    local arenaRows = {}
    for i = 1, 3 do
        local offset = 0 + (i-1) * (arenaBlockHeight + spacing)
        arenaRows[modes[i]] = CreateArenaModeRow(arena, i, modes[i], 0 + (i-1) * (arenaBlockHeight + 6))
    end

    top = top + arenaBlockHeight * 3 + spacing * 2

    -- Tabs (bottom)
    local tabs = {}
    --local tabNames = { "JcJ", "Dummy" }
	local tabNames = { "JcJ" }
    for i, name in ipairs(tabNames) do
        local template = (_G["CharacterFrameTabButtonTemplate"] and "CharacterFrameTabButtonTemplate") or "UIPanelButtonTemplate"
        local tab = CreateFrame("Button", f:GetName() .. "Tab" .. i, f, template)
        tab:SetSize(90, 22)
        tab:SetText(name)
        tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12 + (i - 1) * 98, 12)
        tab.id = i
        tabs[i] = tab
    end

    -- Dummy pane (shares content area)
    local dummy = CreateFrame("Frame", nil, f)
    dummy:SetPoint("TOPLEFT", content, "TOPLEFT")
    dummy:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT")
    dummy:Hide()
    dummy.text = dummy:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dummy.text:SetPoint("TOPLEFT", dummy, "TOPLEFT", 4, -4)
    dummy.text:SetText("Dummy tab (placeholder)")

    -- SelectTab: show/hide + visual feedback
    local function SelectTab(id)
        if id == 1 then content:Show(); dummy:Hide() else content:Hide(); dummy:Show() end
        for idx, t in ipairs(tabs) do
            if t.LockHighlight then
                if idx == id then t:LockHighlight() else t:UnlockHighlight() end
            else
                if idx == id and t.Disable then t:Disable() elseif t.Enable then t:Enable() end
            end
        end
    end

    for _, t in ipairs(tabs) do
        t:SetScript("OnClick", function(self) SelectTab(self.id) end)
    end

    SelectTab(1)

    -- expose references for update from chat handler
	f._arena = arena
    f._honorTotal = honorRow[1]
    f._arenaRows = arenaRows
    f._customHeader = customHeader

    return f
end

-- Create frame on login and listen for whispers
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("CHAT_MSG_WHISPER")
loader:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if not MultiBotPVPFrame then
            MultiBotPVPFrame = CreateStyledFrame()
        end
        return
    end

    if event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        if not MultiBotPVPFrame then return end

        -- Update header with sender name (strip realm if present)
        if sender and MultiBotPVPFrame._customHeader then
            local simpleName = sender:match("([^%-]+)") or sender
            simpleName = simpleName:match("([^%.%-]+)") or simpleName
            MultiBotPVPFrame._customHeader:SetText("Données PvP " .. simpleName)
        end

        -- Parse Honor Points (both languages)
        local honor = msg:match("Honor Points:%s*(%d+)") or msg:match("Honor:%s*(%d+)") or msg:match("Honneur:%s*(%d+)")
        if honor and MultiBotPVPFrame._honorTotal then
            MultiBotPVPFrame._honorTotal:SetText(honor)
        end

        -- Parse Arena points (English or localized variants)
        local arenaPoints = msg:match("Arena points:%s*(%d+)") or msg:match("Arena points%s*[:]%s*(%d+)") or msg:match("Points d'Arène:%s*(%d+)")
        if arenaPoints and MultiBotPVPFrame._arena then
            MultiBotPVPFrame._arena.pointsValue:SetText(arenaPoints)
        end
		
        -- Detect explicit "no team" messages (English/French)
        local noTeamMsg = msg:lower():find("no[%s_-]*team") or msg:lower():find("i have no arena team") or msg:lower():find("pas d'?équipe") or msg:lower():find("pas d'?équipe d'arène")
        if noTeamMsg then
            -- Set all modes to No team / rating 0
            for _, mode in ipairs({"2v2","3v3","5v5"}) do
                local row = MultiBotPVPFrame._arenaRows[mode]
                if row then
                    row.mode:SetText("Mode: " .. mode)
                    row.team:SetText("Equipe: No team")
                    row.rating:SetText("Cote équipe: 0")
                end
            end
            return
        end

        -- Otherwise parse per-mode lines and update matching rows
        for _, modePattern in ipairs({ "2v2", "3v3", "5v5" }) do
            -- try strict pattern: mode followed by colon and <Team> and (rating N)
            local pattern1 = modePattern .. "%s*[:]?%s*<([^>]+)>%s*%(%s*rating%s*(%d+)%s*%)"
            local team1, rating1 = msg:match(pattern1)
            if team1 then
                local row = MultiBotPVPFrame._arenaRows[modePattern]
                if row then
                    row.mode:SetText("Mode: " .. modePattern)
                    row.team:SetText("Equipe: " .. team1)
                    row.rating:SetText("Cote équipe: " .. rating1)
                end
            else
                -- looser pattern: mode then team (with or without <>), then rating
                local pattern2 = modePattern .. "[:%s]*<?([^>%(]+)>?%s*%(%s*rating%s*(%d+)%s*%)"
                local team2, rating2 = msg:match(pattern2)
                if team2 then
                    local row = MultiBotPVPFrame._arenaRows[modePattern]
                    if row then
                        row.mode:SetText("Mode: " .. modePattern)
                        row.team:SetText("Equipe: " .. team2)
                        row.rating:SetText("Cote équipe: " .. rating2)
                    end
                else
                    -- fallback: if message contains modePattern and a <Team> somewhere, use them
                    if msg:match(modePattern) then
                        local team3 = msg:match("<([^>]+)>")
                        local rating3 = msg:match("rating%s*(%d+)")
                        if team3 and MultiBotPVPFrame._arenaRows[modePattern] then
                            local row = MultiBotPVPFrame._arenaRows[modePattern]
                            row.mode:SetText("Mode: " .. modePattern)
                            row.team:SetText("Equipe: " .. team3)
                            if rating3 then row.rating:SetText("Cote équipe: " .. rating3) end
                        end
                    end
                end
            end
        end
    end
end)

-- Expose helper to recreate if needed
_G.MultiBotPVP_Ensure = CreateStyledFrame
