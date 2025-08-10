--[[
MultiBotSpecUI.lua  – Extension module for the MultiBot addon by TheWarlock aka Wishmaster117
Adds a “Set talents” button on each bot frame and builds a dynamic dropdown list
with all spec builds returned by the command  /w <bot> "talents spec list".
]]--

local icons = MultiBot.data.iconos or {}

local defaultIcon = "Interface\\Icons\\Achievement_Reputation_08"

-- canonicalisation des petits préfixes
local specCanonical = {
  -- Paladin
  holy        = "Holy", 
  ret         = "Ret",  
  -- Druid
  balance     = "Balance",
  bear        = "Bear",  
  cat         = "Cat",
  resto       = "Restoration",
  -- Shaman
  ele         = "Ele",
  enh         = "Enh",
  -- Warrior
  arms        = "Arms",
  fury        = "Fury",
  prot        = "Protection",
  -- Hunter
  bm          = "BM",
  mm          = "Marksmanship",
  surv        = "Survival",
  -- Priest
  shadow      = "Shadow",
  disc        = "Discipline",
  -- Mage	
  arcane      = "Arcane",
  fire        = "Fire",
  frostfire   = "Frostfire",  
  frost       = "Frost",
  -- Warlock
  affli       = "Affliction",
  demo        = "Demonology",
  destro      = "Destruction",
  -- DK
  blood       = "Blood",
  unholy      = "Unholy",
  double      = "Double",
  -- Rogue
  as          = "As",
  combat      = "Combat",
  subtlety    = "Subtlety",
}


local specIconMap = {
  DeathKnight = {
    Blood  = {
      pve = { icon = icons[5427], tip =  MultiBot.tips.spec.dkbloodpve },
      pvp = { icon = icons[5427], tip =  MultiBot.tips.spec.dkbloodpvp },
    },
    Frost  = {
      pve = { icon = icons[5438], tip = MultiBot.tips.spec.dkbfrostpve },
      pvp = { icon = icons[5438], tip = MultiBot.tips.spec.dkbfrostpvp },
    },
    Unholy = {
      pve = { icon = icons[5454], tip = MultiBot.tips.spec.dkunhopve },
      pvp = { icon = icons[5454], tip = MultiBot.tips.spec.dkunhopvp  },
    },
    Double = {
      pve = { icon = icons[5946], tip = MultiBot.tips.spec.dkdoublepve },
    },	
  },

  Druid = {
    Balance     = {
      pve = { icon = icons[73], tip = MultiBot.tips.spec.druidbalpve },
      pvp = { icon = icons[73], tip = MultiBot.tips.spec.druidbalpvp },
    },
    Cat        = {
      pve = { icon = icons[28] , tip = MultiBot.tips.spec.druidcatpve },
      pvp = { icon = icons[28], tip = MultiBot.tips.spec.druidcatpvp },
    },
    Bear       = {
      pve = { icon = icons[325] , tip = MultiBot.tips.spec.druidbearpve },
    },	
    Restoration = {
      pve = { icon = icons[5745]  , tip = MultiBot.tips.spec.druidrestopve },
      pvp = { icon = icons[5745], tip = MultiBot.tips.spec.druidrestopvp },
    },
  },

  Hunter = {
    BM           = {
      pve = { icon = icons[103], tip = MultiBot.tips.spec.huntbmpve },
      pvp = { icon = icons[103], tip = MultiBot.tips.spec.huntbmpvp },
    },
    Marksmanship = {
      pve = { icon = icons[214], tip = MultiBot.tips.spec.huntmarkpve },
      pvp = { icon = icons[214], tip = MultiBot.tips.spec.huntmarkpvp },
    },
    Survival     = {
      pve = { icon = icons[181]  , tip = MultiBot.tips.spec.huntsurvpve },
      pvp = { icon = icons[181]  , tip = MultiBot.tips.spec.huntsurvpvp },
    },
  },

  Mage = {
    Arcane = {
      pve = { icon = icons[5551], tip = MultiBot.tips.spec.magearcapve},
      pvp = { icon = icons[5551], tip = MultiBot.tips.spec.magearcapvp },
    },
    Fire   = {
      pve = { icon = icons[5494] , tip = MultiBot.tips.spec.magefirepve },
      pvp = { icon = icons[5494], tip = MultiBot.tips.spec.magefirepvp },
    },
    Frostfire   = {
      pve = { icon = icons[200] , tip = MultiBot.tips.spec.magefrostfirepve },
    },	
    Frost  = {
      pve = { icon = icons[5521] , tip = MultiBot.tips.spec.magefrostpve },
      pvp = { icon = icons[5521], tip = MultiBot.tips.spec.magefrostpvp},
    },
  },

  Paladin = {
    Holy = {
      pve = { icon = icons[5608], tip = MultiBot.tips.spec.paladinholypve},
      pvp = { icon = icons[5608], tip = MultiBot.tips.spec.paladinholypvp},
    },
    Protection = {
      pve = { icon = icons[5578] , tip = MultiBot.tips.spec.paladinprotpve },
      pvp = { icon = icons[5578], tip = MultiBot.tips.spec.paladinprotpvp },
    },
    Ret   = {
      pve = { icon = icons[300], tip = MultiBot.tips.spec.paladinretpve },
      pvp = { icon = icons[300], tip = MultiBot.tips.spec.paladinretpvp },
    },
  },

  Priest = {
    Discipline = {
      pve = { icon = icons[5685], tip = MultiBot.tips.spec.priestdiscipve },
      pvp = { icon = icons[5685], tip = MultiBot.tips.spec.priestdiscipvp },
    },
    Holy = {
      pve = { icon = icons[5601], tip = MultiBot.tips.spec.priestholypve },
      pvp = { icon = icons[5601], tip = MultiBot.tips.spec.priestholypvp },
    },
    Shadow = {
      pve = { icon = icons[5929], tip = MultiBot.tips.spec.priestshadowpve },
      pvp = { icon = icons[5929], tip = MultiBot.tips.spec.priestshadowpvp },
    },
  },

  Rogue = {
    As = {
      pve = { icon = icons[346], tip = MultiBot.tips.spec.rogassapve },
      pvp = { icon = icons[346], tip = MultiBot.tips.spec.rogassapvp },
    },
    Combat = {
      pve = { icon = icons[358], tip = MultiBot.tips.spec.rogcombatpve },
      pvp = { icon = icons[358], tip = MultiBot.tips.spec.rogcombatpvp },
    },
    Subtlety = {
      pve = { icon = icons[331], tip = MultiBot.tips.spec.rogsubtipve },
      pvp = { icon = icons[331], tip = MultiBot.tips.spec.rogsubtipvp },
    },
  },

  Shaman = {
    Ele   = {
      pve = { icon = icons[5716], tip = MultiBot.tips.spec.shamanelempve },
      pvp = { icon = icons[5716], tip = MultiBot.tips.spec.shamanelempvp },
    },
    Enh  = {
      pve = { icon = icons[5755], tip = MultiBot.tips.spec.shamanenhpve },
      pvp = { icon = icons[5755], tip = MultiBot.tips.spec.shamanenhpvp },
    },
    Restoration = {
      pve = { icon = icons[5756], tip = MultiBot.tips.spec.shamanrestopve },
      pvp = { icon = icons[5756], tip = MultiBot.tips.spec.shamanrestopvp },
    },
  },

  Warlock = {
    Affliction = {
      pve = { icon = icons[5852], tip = MultiBot.tips.spec.warlockafflipve },
      pvp = { icon = icons[5852], tip = MultiBot.tips.spec.warlockafflipvp },
    },
    Demonology = {
      pve = { icon = icons[5889], tip = MultiBot.tips.spec.warlockdemonopve },
      pvp = { icon = icons[5889], tip = MultiBot.tips.spec.warlockdemonopvp },
    },
    Destruction = {
      pve = { icon = icons[5907], tip = MultiBot.tips.spec.warlockdestrupve },
      pvp = { icon = icons[5907], tip = MultiBot.tips.spec.warlockdestrupvp },
    },
  },

  Warrior = {
    Arms = {
      pve = { icon = icons[436], tip = MultiBot.tips.spec.warriorarmspve },
      pvp = { icon = icons[436], tip = MultiBot.tips.spec.warriorarmspvp },
    },
    Fury = {
      pve = { icon = icons[480], tip = MultiBot.tips.spec.warriorfurypve },
      pvp = { icon = icons[480], tip = MultiBot.tips.spec.warriorfurypvp },
    },
    Protection = {
      pve = { icon = icons[4456], tip = MultiBot.tips.spec.warriorprotecpve },
      pvp = { icon = icons[4456], tip = MultiBot.tips.spec.warriorprotecpvp },
    },
  },
}

---------------------------------------------------------------------
-- Helper TimerAfter
---------------------------------------------------------------------
local function TimerAfter(delay, callback)
    if C_Timer and C_Timer.After then            
        return C_Timer.After(delay, callback)
    end                                          
    local f = CreateFrame("Frame")
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            if callback then pcall(callback) end
        end
    end)
end

-- renvoie le premier champ userdata trouvé dans un wrapper
local function unwrapFrame(obj)
    if type(obj) == "userdata" then return obj end
    if type(obj) == "table" then
        for _, v in pairs(obj) do
            if type(v) == "userdata" then
                return v
            end
        end
    end
    return nil
end


local MultiBot = _G["MultiBot"] or {}
_G["MultiBot"] = MultiBot

local Spec = MultiBot.spec or {}
Spec.currentBuild = {}  -- table pour conserver la build courante de chaque bot (ex : "0-13-58")
-- Spec.currentBuild = Spec.currentBuild or {}
Spec.busy = false
Spec.pendingRefresh = nil
MultiBot.spec = Spec

if Spec.initialised then
    return
end
Spec.initialised = true

Spec.pending, Spec.buttons = nil, {}

function Spec:RequestList(bot, wrapper)
    if self.busy then
        return                  --    on ignore le clic
    end                        
    local frame = unwrapFrame(wrapper)
    if type(frame) ~= "userdata" then
        -- print("|cffff0000[SpecUI] impossible de localiser le frame du bouton|r")
        return
    end

    self:HideDropdown()

    self.pending = {
        bot     = bot,
        anchor  = frame,
        wrapper = wrapper,
        specs   = {},
        builds  = {},
    }

    -- 1) on demande d'abord la spé courante
    SendChatMessage("talents", "WHISPER", nil, bot)
	-- print(">>> TALENTS demandé à", bot)

    -- 2) on attend ~0.2s puis on enchaîne sur la liste
    local t = self._timerFrame or CreateFrame("Frame")
    self._timerFrame = t
    t.elapsed = 0
    t:SetScript("OnUpdate", function(self, delta)
        self.elapsed = self.elapsed + delta
        if self.elapsed >= 0.2 then
            -- si on est toujours sur le même bot, on demande la liste
            if Spec.pending and Spec.pending.bot == bot then
                SendChatMessage("talents spec list", "WHISPER", nil, bot)
                -- print("|cffffff00[SpecDEBUG]|r Message talents spec list envoyé!!!!!!!!!!!!!!!!!")
            end
            -- on désactive l’OnUpdate et reset le timer
            self:SetScript("OnUpdate", nil)
            self.elapsed = 0
        end
    end)
end


local function short(name)
    local dash = name:find("-", 1, true)
    return dash and name:sub(1, dash-1) or name
end

--------------------------------------------------------------
-- Listener des whispers  (capture build & liste des specs)
--------------------------------------------------------------
local whisperFrame = CreateFrame("Frame")
whisperFrame:RegisterEvent("CHAT_MSG_WHISPER")
whisperFrame:SetScript("OnEvent", function(_, _, msg, sender)

    ----------------------------------------------------------------
    -- 1) Nettoyage basique de la ligne reçue
    ----------------------------------------------------------------
    local clean = msg
        :gsub("|c%x%x%x%x%x%x%x%x", "")   -- codes couleur
        :gsub("|r", "")
        :gsub("\r?\n", " ")               -- retours à la ligne → espace

    --[[if not clean:match("^%s*My current talent spec is:") 
       and not (Spec.pending and short(sender) == short(Spec.pending.bot)) then
        -- Pas un message talent, on ne fait RIEN ici!
        return
    end]]--
    ----------------------------------------------------------------
    -- 2) « My current talent spec is: … (x/x/x) »
    ----------------------------------------------------------------
    if clean:match("^%s*My current talent spec is:") then
        -- a) extrait ce qu’il y a entre parenthèses
        local inside = clean:match("%(([^%)]+)%)")
        if inside then
            -- b) récupère les trois nombres, séparateur quelconque
            local a, b, c = inside:match("(%d+)[^%d]*(%d+)[^%d]*(%d+)")
            if a and b and c then
                local key = short(sender):lower()        -- clé normalisée
                Spec.currentBuild[key] = a.."-"..b.."-"..c
                -- print("Captured build for", key, "=", Spec.currentBuild[key])
            end
        end

        ----------------------------------------------------------------
        -- 2-bis) refresh en attente 
        ----------------------------------------------------------------
        if Spec.pendingRefresh and short(sender) == short(Spec.pendingRefresh) then
            local unit = MultiBot.toUnit(sender)
            if unit then
                if not MultiBot.talent:IsShown() then
                    local _, token = UnitClass(unit)
                    MultiBot.talent.name  = sender
                    MultiBot.talent.class = MultiBot.toClass(token)
                end
                TimerAfter(0.6, function()
                    MultiBot.auto.talent = true
                    InspectUnit(unit)
                    if InspectFrame then HideUIPanel(InspectFrame) end
                    TimerAfter(0.1, function()
                        if MultiBot.talent:IsShown() then MultiBot.talent:Hide() end
                    end)
                end)
            end
            Spec.pendingRefresh = nil
            Spec.busy           = false
        end
        return           -- on stoppe là pour cette ligne
    end

    ----------------------------------------------------------------
    -- 3) Liste des specs : “1) Feral pve (0-60-11)” … “Total …”
    ----------------------------------------------------------------
    local P = Spec.pending
    if not P or short(sender) ~= short(P.bot) then return end

    -- a) ligne de spec
    local name  = clean:match("^%d+[%.%)]?%s*([^%(]+)%s*%(")
                or clean:match("^([^%(]+)%s*%(")
    if name then
        local build = clean:match("%((%d+%-%d+%-%d+)%)")
        tinsert(P.specs,  strtrim(name))
        tinsert(P.builds, strtrim(build))
        return
    end

    -- b) ligne de fin (« Total X specs found »)
    local plain = clean:lower()
    if plain:find("total") and plain:find("spec") then
        Spec:BuildDropdown()
        Spec.pending = nil
    end
end)


function Spec:HideDropdown()
    if self.dropdown then
        self.dropdown:Hide()
        self.dropdown:SetParent(nil)
        self.dropdown = nil
    end
    for _,b in ipairs(self.buttons) do b:Hide(); b:SetParent(nil) end
    wipe(self.buttons)
end

function Spec:BuildDropdown()
    -- 0) Protection
    if self.busy then return end

    local p = self.pending
    if not p or #p.specs == 0 then return end

local botKey  = short(p.bot):lower()   -- ← ajoute :lower()
local current = Spec.currentBuild[botKey]

    -- 1) Fenêtre conteneur
    local df = self.dropdown
    if not df then
        df = CreateFrame("Frame", nil, UIParent)
        if df.SetBackdrop then
            df:SetBackdrop({
                bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile     = true, tileSize = 16,
                edgeSize = 16,
                insets   = { left = 4, right = 4, top = 4, bottom = 4 },
            })
            df:SetBackdropColor(0, 0, 0, 0.8)
        end
        df:SetFrameStrata("DIALOG")
        self.dropdown = df
    end
    df:ClearAllPoints()
    df:SetPoint("TOP", p.anchor, "BOTTOM", 0, -4)

    -- 2) Boutons --------------------------------------------------------
    local step, needed = 37, #p.specs
    while #self.buttons < needed do
        local b = CreateFrame("Button", nil, df)
        b:RegisterForClicks("AnyUp")
        b:SetSize(32, 32)
        b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
        b:SetFrameStrata("DIALOG")
        table.insert(self.buttons, b)
    end

    local alreadyMarked = false
	for i, b in ipairs(self.buttons) do
        if i <= needed then
            local spec  = p.specs[i]      -- « Balance pve »
            local build = p.builds[i]     -- « 58-0-13 »

            -- positionnement
            b:ClearAllPoints()
            if i == 1 then
                b:SetPoint("TOP", df, "TOP", 0, -4)
            else
                b:SetPoint("TOP", self.buttons[i-1], "BOTTOM", 0, -4)
            end

            -- icône & tooltip
            local mode   = spec:lower():find("pvp") and "pvp" or "pve"
            local prefix = spec:match("^[^%s]+"):lower()
            local canon  = specCanonical[prefix] or prefix:gsub("^%l", string.upper)
            local class  = p.wrapper:getClass():gsub("^%l", string.upper)
            local entry  = (((specIconMap[class] or {})[canon] or {})[mode]) or {}
            local icon   = entry.icon or defaultIcon
            local tip    = entry.tip  or spec

            b:SetNormalTexture(icon)
            b:SetDisabledTexture(icon)
            b:Show()

            -- 3) CLIC -----------------------------------------------------
            local bot = p.bot
			    local buildNum   = (build   and strtrim(build))   or ""
				local currentNum = (current and strtrim(current)) or ""
				if (not alreadyMarked) and build == current then
				alreadyMarked = true
				b:SetAlpha(0.4)
				local tex = b:GetNormalTexture()
				if tex and tex.SetDesaturated then tex:SetDesaturated(true) end
				b:SetScript("OnClick", nil)
            else
                b:SetAlpha(1)
                b:SetScript("OnClick", function(self, btn)
                    if Spec.busy then return end
                    Spec.busy = true

                    -- a) stopcasting
                    SendChatMessage("stopcasting", "WHISPER", nil, bot)

                    -- b) switch talent-group (G = 1, D = 2)
                    local slot = (btn == "RightButton") and 2 or 1
                    SendChatMessage("talents switch " .. slot, "WHISPER", nil, bot)

                    -- c) 0,4 s plus tard → talents spec <nom>
                    TimerAfter(0.4, function()
                        SendChatMessage("talents spec " .. spec, "WHISPER", nil, bot)
                    end)

                    -- d) attente du whisper ou timer-secours
                    Spec.pendingRefresh = bot
                    Spec:HideDropdown()

                    -- timer-secours 1,3 s
					TimerAfter(1.3, function()
						if Spec.pendingRefresh and Spec.pendingRefresh == bot then
							local unit      = MultiBot.toUnit(bot)
							local className = p.wrapper:getClass()           -- "Druid", "Paladin", …

							if unit then
								if not MultiBot.talent:IsShown() then
									MultiBot.talent.name  = bot
									MultiBot.talent.class = className        -- déjà normalisé
								end

								TimerAfter(0.6, function()
									MultiBot.auto.talent = true
									InspectUnit(unit)

									if InspectFrame then HideUIPanel(InspectFrame) end
									TimerAfter(0.1, function()
										if MultiBot.talent:IsShown() then MultiBot.talent:Hide() end
									end)
								end)
							end
							Spec.pendingRefresh = nil
							Spec.busy           = false
						end
					end)
                end)
            end

            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip, nil, nil, nil, nil, true)
            end)
            b:SetScript("OnLeave", GameTooltip_Hide)
        else
            b:Hide()
        end
    end

    df:SetWidth(40)
    df:SetHeight(needed * step)
    df:Show()
end
