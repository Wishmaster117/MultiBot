-- MultiBot PvP UI with cache per bots
-- local ADDON = "MultiBot"

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
    titleBg:SetTexture(MultiBot.SafeTexturePath("Interface\\DialogFrame\\UI-DialogBox-Header"))
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
    customHeader:SetText(MultiBot.tips.every.pvpcustom)
    top = top + 18 + 6

    -- Bot selector (cache par bot) - alimenté par les réponses [PVP] reçues en whisper
    local botDropDown = CreateFrame("Frame", "MultiBotPVPBotDropDown", content, "UIDropDownMenuTemplate")
    botDropDown:SetPoint("TOPRIGHT", content, "TOPRIGHT", 18, 10)
    UIDropDownMenu_SetWidth(botDropDown, 180)
    UIDropDownMenu_SetText(botDropDown, "Bot")

    -- HONNEUR section: only one row "Honneur"
    local honorHeight = 18 + 1 * 18 + 8
    local honor = CreateSection(content, top, honorHeight, "Honneur")

    -- Column header labels for Honneur (1st renamed Total)
    local hdr1 = honor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdr1:SetPoint("TOPRIGHT", honor, "TOPRIGHT", colOffsets[1], -2)
    hdr1:SetText(MultiBot.tips.every.pvptotal)
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
    local arenaSep = arena:CreateTexture(nil, "ARTWORK")
    arenaSep:SetHeight(1)
    arenaSep:SetPoint("TOPLEFT", arena, "TOPLEFT", 0, -18)
    arenaSep:SetPoint("TOPRIGHT", arena, "TOPRIGHT", 0, -18)
    arenaSep:SetTexture(0.5, 0.5, 0.5, 0.6)

    -- Points d'Arène (affiché à gauche de la section Arène)
    arena.pointsLabel = arena:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arena.pointsLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", 120, 0)
    arena.pointsLabel:SetText(MultiBot.tips.every.pvparenapoints)

    arena.pointsValue = arena:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    arena.pointsValue:SetPoint("LEFT", arena.pointsLabel, "RIGHT", 6, 0)
    arena.pointsValue:SetText("-")

    -- helper to create per-mode display inside arena
    local function CreateArenaModeRow(parent, idx, modeLabel, offsetY)
        -- mode title (e.g., "Mode: 2v2")
        local modeText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        modeText:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offsetY -32)
        modeText:SetText(MultiBot.tips.every.pvparenamode .. modeLabel)

        -- team name
        local teamText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        teamText:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -offsetY - 50)
        teamText:SetText(MultiBot.tips.every.pvparenanoteam)

        -- rating
        local ratingText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ratingText:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -offsetY - 34)
        ratingText:SetText(MultiBot.tips.every.pvparenanoteamrank)

        return { mode = modeText, team = teamText, rating = ratingText }
    end

    -- create rows for 2v2, 3v3, 5v5
    local modes = { "2v2", "3v3", "5v5" }
    local arenaRows = {}
    for i = 1, 3 do
        -- local offset = 0 + (i-1) * (arenaBlockHeight + spacing)
        arenaRows[modes[i]] = CreateArenaModeRow(arena, i, modes[i], 0 + (i-1) * (arenaBlockHeight + 6))
    end

    --top = top + arenaBlockHeight * 3 + spacing * 2
    -- Tabs (bottom)
    local tabs = {}
    --local tabNames = { "JcJ", "Dummy" }
	local tabNames = { "JcJ" }

    for i, name in ipairs(tabNames) do
        local template = (_G["CharacterFrameTabButtonTemplate"] and
            "CharacterFrameTabButtonTemplate") or "UIPanelButtonTemplate"
        local tab = CreateFrame("Button", f:GetName() .. "Tab" .. i, f, template)
        tab:SetSize(90, 22)
        tab:SetText(name)
        tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",
            12 + (i - 1) * 98, 12)
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
	f._botDropDown = botDropDown
	f._arena = arena
    f._honorTotal = honorRow[1]
    f._arenaRows = arenaRows
    f._customHeader = customHeader

    return f
end

-- ==========================
-- PvP cache par bot (whispers)
-- ==========================

local function MBPVP_NormalizeSenderName(sender)
    if not sender or sender == "" then
        return ""
    end

    local simpleName = sender:match("([^%-]+)") or sender
    simpleName = simpleName:match("([^%.%-]+)") or simpleName
    return simpleName
end

local function MBPVP_ExtractFirstTwoNumbers(line)
    local a, b
    for n in tostring(line):gmatch("(%d+)") do
        if not a then
            a = n
        else
            b = n
            break
        end
    end
    return a, b
end

-- Extrait un rating quel que soit le mot localisé:
-- "(rating 1234)" "(cote 1234)" "(Wertung 1234)" "(评分 1234)" "(평점 1234)" etc.
local function MBPVP_ExtractTeamRating(line)
    return tostring(line):match("%(%s*[^%d]*(%d+)%s*%)")
end

local function MBPVP_PrefixFromTemplate(s, fallback)
    if type(s) ~= "string" then
        return fallback or ""
    end

    local p = s:match("^(.-:%s*)")
    return p or (fallback or "")
end

local function MBPVP_EnsureCache(frame)
    if not frame._botCache then
        frame._botCache = {}
    end
end

local function MBPVP_GetState(frame, botName)
    MBPVP_EnsureCache(frame)

    if not frame._botCache[botName] then
        frame._botCache[botName] = {
            honorPoints = nil,
            arenaPoints = nil,
            teams = {
                ["2v2"] = { team = nil, rating = nil, noTeam = true },
                ["3v3"] = { team = nil, rating = nil, noTeam = true },
                ["5v5"] = { team = nil, rating = nil, noTeam = true },
            },
            lastUpdate = 0,
        }
    end

    return frame._botCache[botName]
end

local function MBPVP_GetSortedBotList(frame)
    MBPVP_EnsureCache(frame)

    local list = {}
    for name, st in pairs(frame._botCache) do
        list[#list + 1] = { name = name, ts = st.lastUpdate or 0 }
    end

    table.sort(list, function(a, b)
        if a.ts == b.ts then
            return a.name < b.name
        end
        return a.ts > b.ts
    end)

    local out = {}
    for _, v in ipairs(list) do
        out[#out + 1] = v.name
    end
    return out
end

local function MBPVP_ApplyStateToUi(frame, botName)
    if not frame or not botName or botName == "" then
        return
    end

    MBPVP_EnsureCache(frame)

    local st = frame._botCache[botName]
    if not st then
        return
    end

    -- Header
    if frame._customHeader then
        frame._customHeader:SetText(MultiBot.tips.every.pvparenadata .. botName)
    end

    -- Currency
    if frame._honorTotal then
        frame._honorTotal:SetText(st.honorPoints or "-")
    end

    if frame._arena and frame._arena.pointsValue then
        frame._arena.pointsValue:SetText(st.arenaPoints or "-")
    end

    -- Rows
    if frame._arenaRows then
        local teamPrefix = MBPVP_PrefixFromTemplate(MultiBot.tips.every.pvparenanoteam, "Team: ")
        local rankPrefix = MBPVP_PrefixFromTemplate(MultiBot.tips.every.pvparenanoteamrank, "Rating: ")

        for _, mode in ipairs({ "2v2", "3v3", "5v5" }) do
            local row = frame._arenaRows[mode]
            local mt = st.teams and st.teams[mode]
            if row then
                row.mode:SetText(MultiBot.tips.every.pvparenamode .. mode)

                if mt and mt.team then
                    row.team:SetText(teamPrefix .. mt.team)
                else
                    row.team:SetText(MultiBot.tips.every.pvparenanoteam)
                end

                if mt and mt.rating then
                    row.rating:SetText(rankPrefix .. mt.rating)
                else
                    row.rating:SetText(MultiBot.tips.every.pvparenanoteamrank)
                end
            end
        end
    end
end

local function MBPVP_SetCurrentBot(frame, botName)
    if not frame then
        return
    end

    frame._currentBot = botName

    if frame._botDropDown then
        UIDropDownMenu_SetSelectedValue(frame._botDropDown, botName)
        UIDropDownMenu_SetText(frame._botDropDown, botName ~= "" and botName or "Bot")
    end

    MBPVP_ApplyStateToUi(frame, botName)
end

local function MBPVP_InitBotDropDown(frame)
    if not frame or not frame._botDropDown or frame._botDropDown._mbInit then
        return
    end

    frame._botDropDown._mbInit = true

    UIDropDownMenu_Initialize(frame._botDropDown, function(self, level)
        local bots = MBPVP_GetSortedBotList(frame)
        for _, name in ipairs(bots) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.func = function()
                MBPVP_SetCurrentBot(frame, name)
                if not frame:IsShown() then
                    frame:Show()
                end
            end
            info.checked = (frame._currentBot == name)
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetText(frame._botDropDown, "Bot")
end

local function MBPVP_IsNoTeamMessage(msg)
    if type(msg) ~= "string" then
        return false
    end

    local lower = msg:lower()

    -- EN + locales DB (text_loc1..8) de ton extract
    if lower:find("i have no arena team", 1, true) or lower:find("no arena team", 1, true) then
        return true
    end
    if msg:find("투기장 팀이 없습니다", 1, true) then return true end
    if msg:find("Je n'ai aucune équipe d'arène", 1, true) then return true end
    if msg:find("Ich habe kein Arenateam", 1, true) then return true end
    if msg:find("我没有竞技场战队", 1, true) then return true end
    if msg:find("我沒有競技場隊伍", 1, true) then return true end
    if msg:find("No tengo equipo de arena", 1, true) then return true end
    if msg:find("У меня нет команды арены", 1, true) then return true end

    return false
end

-- Create frame on login and listen for whispers
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("CHAT_MSG_WHISPER")

local function NormalizeSenderName(sender)
    if not sender or sender == "" then
        return ""
    end

    -- Strip realm if present ("Name-Realm") and any separators you already used elsewhere
    local simpleName = sender:match("([^%-]+)") or sender
    simpleName = simpleName:match("([^%.%-]+)") or simpleName
    return simpleName
end

local function ResetPvpUi(frame)
    if not frame then return end

    if frame._honorTotal then
        frame._honorTotal:SetText("-")
    end
    if frame._arena and frame._arena.pointsValue then
        frame._arena.pointsValue:SetText("-")
    end

    if frame._arenaRows then
        for _, mode in ipairs({ "2v2", "3v3", "5v5" }) do
            local row = frame._arenaRows[mode]
            if row then
                row.mode:SetText(MultiBot.tips.every.pvparenamode .. mode)
                row.team:SetText(MultiBot.tips.every.pvparenanoteam)
                row.rating:SetText(MultiBot.tips.every.pvparenanoteamrank)
            end
        end
    end
end

loader:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        if not MultiBotPVPFrame then
            MultiBotPVPFrame = CreateStyledFrame()
        end

        MBPVP_EnsureCache(MultiBotPVPFrame)
        MBPVP_InitBotDropDown(MultiBotPVPFrame)

        return
    end

    if event == "CHAT_MSG_WHISPER" then
        local msg, sender = ...
        if not MultiBotPVPFrame then return end

        if type(msg) ~= "string" then return end

        -- Ouvrir la frame uniquement sur les réponses PvP du module playerbots
        if not msg:find("%[PVP%]") then
            return
        end

        local simpleName = NormalizeSenderName(sender)

        -- Si on reçoit un nouveau bot, on réinitialise l'affichage pour éviter de mélanger les données
        if MultiBotPVPFrame._currentSender ~= simpleName then
            MultiBotPVPFrame._currentSender = simpleName
            ResetPvpUi(MultiBotPVPFrame)
        end

        -- Ouvre la frame dès qu'un bot répond
        if not MultiBotPVPFrame:IsShown() then
            MultiBotPVPFrame:Show()
        end

        if type(msg) ~= "string" then
            return
        end

        -- Ne traiter que les réponses PvP du module playerbots
        if not msg:find("%[PVP%]") then
            return
        end

        MBPVP_InitBotDropDown(MultiBotPVPFrame)

        local botName = MBPVP_NormalizeSenderName(sender)
        if botName == "" then
            return
        end

        local st = MBPVP_GetState(MultiBotPVPFrame, botName)
        st.lastUpdate = time()

        -- 1) Ligne currency: toujours un "|" et 2 nombres dans l'ordre (arena_points puis honor_points)
        if msg:find("|", 1, true) then
            local arenaPoints, honorPoints = MBPVP_ExtractFirstTwoNumbers(msg)
            if arenaPoints then st.arenaPoints = arenaPoints end
            if honorPoints then st.honorPoints = honorPoints end
        else
            local bracket = msg:match("([235]v[235])")

            -- 2) Message global "no arena team" (EN + locales DB)
            if MBPVP_IsNoTeamMessage(msg) then
                for _, mode in ipairs({ "2v2", "3v3", "5v5" }) do
                    st.teams[mode] = st.teams[mode] or {}
                    st.teams[mode].team = nil
                    st.teams[mode].rating = nil
                end
            -- 3) Ligne par bracket: "[PVP] 5v5 : <TeamName> (motLocalisé 1047)"
            elseif bracket then
                st.teams[bracket] = st.teams[bracket] or {}

                local team = msg:match("<([^>]+)>")
                local rating = MBPVP_ExtractTeamRating(msg)

                if team then
                    st.teams[bracket].team = team
                    st.teams[bracket].rating = rating
                else
                    -- Bracket présent mais pas de nom d'équipe => on réinitialise ce bracket
                    st.teams[bracket].team = nil
                    st.teams[bracket].rating = nil
                end
            end
        end

        -- Ouvre la frame dès qu'un bot répond
        if not MultiBotPVPFrame:IsShown() then
            MultiBotPVPFrame:Show()
        end

        -- Sélection automatique:
        -- - si aucune sélection en cours, on sélectionne le bot qui vient de répondre
        -- - sinon, on n'écrase pas l'affichage (cache seulement), sauf si c'est le bot affiché
        if not MultiBotPVPFrame._currentBot or MultiBotPVPFrame._currentBot == "" then
            MBPVP_SetCurrentBot(MultiBotPVPFrame, botName)
        elseif MultiBotPVPFrame._currentBot == botName then
            MBPVP_ApplyStateToUi(MultiBotPVPFrame, botName)
        end
    end
end)

-- Expose helper to recreate if needed
_G.MultiBotPVP_Ensure = CreateStyledFrame
