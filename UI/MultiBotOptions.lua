-- MultiBotOptions.lua
-- print("MultiBotOptions.lua loaded")

local PANEL_NAME = "MultiBotOptionsPanel"

local function round(x, step) step = step or 1; return math.floor(x/step + 0.5)*step end

local function makeSlider(parent, key, label, minV, maxV, step, y)
  local name = PANEL_NAME .. "_" .. key .. "_Slider"
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", 16, y)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:SetWidth(300)

  _G[name .. "Text"]:SetText(label)
  _G[name .. "Low"]:SetText(string.format("%.1f s", minV))
  _G[name .. "High"]:SetText(string.format("%.1f s", maxV))

  local val = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  val:SetPoint("TOP", s, "BOTTOM", 0, 0)

  local function refresh()
    local v = MultiBot.GetTimer(key)
    s:SetValue(v)
    val:SetText(string.format("%.1f s", v))
  end

  s:SetScript("OnValueChanged", function(self, v)
    v = round(v, step)
    self:SetValue(v)
    MultiBot.SetTimer(key, v)
    val:SetText(string.format("%.1f s", v))
  end)

  s._refresh = refresh
  return s
end

-- Fabrique pour les sliders throttle (utilise Get/Set dédiés)
local function makeThrottleSlider(parent, key, label, minV, maxV, step, y)
  local name = PANEL_NAME .. "_" .. key .. "_Slider"
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", 16, y)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:SetWidth(300)

  _G[name .. "Text"]:SetText(label)
  _G[name .. "Low"]:SetText(tostring(minV))
  _G[name .. "High"]:SetText(tostring(maxV))

  local val = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  val:SetPoint("TOP", s, "BOTTOM", 0, 0)

  local function getValue()
    if key == "thr_rate" then return MultiBot.GetThrottleRate() else return MultiBot.GetThrottleBurst() end
  end
  local function setValue(v)
    if key == "thr_rate" then MultiBot.SetThrottleRate(v) else MultiBot.SetThrottleBurst(v) end
  end

  local function refresh()
    local v = getValue()
    s:SetValue(v)
    val:SetText(tostring(v))
  end

  s:SetScript("OnValueChanged", function(self, v)
    v = round(v, step)
    self:SetValue(v)
    setValue(v)
    val:SetText(tostring(v))
  end)

  s._refresh = refresh
  return s
end

function MultiBot.BuildOptionsPanel()
  if MultiBot._optionsBuilt then return end

  -- parent = UIParent (pas InterfaceOptionsFramePanelContainer sur 3.3.5)
  local panel = CreateFrame("Frame", PANEL_NAME, UIParent)
  panel.name = "MultiBot"
  panel:Hide()

  panel:SetScript("OnShow", function(self)
    if self._initialized then return end
    self._initialized = true

    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(MultiBot.tips.sliders.frametitle)

    local sub = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText(MultiBot.tips.sliders.actionsinter)

    -- Sliders : on les crée puis on les ANCRE sous le sous-titre pour éviter tout chevauchement
    self.s_stats  = makeSlider(self, "stats",  MultiBot.tips.sliders.statsinter,           5, 300, 1,   -40)
    self.s_talent = makeSlider(self, "talent", MultiBot.tips.sliders.talentsinter,         1,  30, 0.5, -90)
    self.s_invite = makeSlider(self, "invite", MultiBot.tips.sliders.invitsinter, 1,  60, 1,   -140)
    self.s_sort   = makeSlider(self, "sort",   MultiBot.tips.sliders.sortinter, 0.2,10, 0.2, -190)

    -- Throttle (NOUVEAU)
    self.s_thr_rate  = makeThrottleSlider(self, "thr_rate",  MultiBot.tips.sliders.messpersec, 1, 20, 1, 0)
    self.s_thr_burst = makeThrottleSlider(self, "thr_burst", MultiBot.tips.sliders.maxburst,    1, 50, 1, 0)

    -- Ré-ancrage vertical
    self.s_stats:ClearAllPoints()
    self.s_stats:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
    
    self.s_talent:ClearAllPoints()
    self.s_talent:SetPoint("TOPLEFT", self.s_stats, "BOTTOMLEFT", 0, -36)
    
    self.s_invite:ClearAllPoints()
    self.s_invite:SetPoint("TOPLEFT", self.s_talent, "BOTTOMLEFT", 0, -36)
    
    self.s_sort:ClearAllPoints()
    self.s_sort:SetPoint("TOPLEFT", self.s_invite, "BOTTOMLEFT", 0, -36)
    
    self.s_thr_rate:ClearAllPoints()
    self.s_thr_rate:SetPoint("TOPLEFT", self.s_sort, "BOTTOMLEFT", 0, -36)
    
    self.s_thr_burst:ClearAllPoints()
    self.s_thr_burst:SetPoint("TOPLEFT", self.s_thr_rate, "BOTTOMLEFT", 0, -36)

    -- Bouton : descendu sous le dernier slider
    local btn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    btn:SetSize(140, 22)
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", self.s_thr_burst, "BOTTOMLEFT", 0, -24)
    btn:SetText(MultiBot.tips.sliders.rstbutn)
    btn:SetScript("OnClick", function()
      -- Timers
      MultiBot.SetTimer("stats",  45)
      MultiBot.SetTimer("talent", 3)
      MultiBot.SetTimer("invite", 5)
      MultiBot.SetTimer("sort",   1)
      self.s_stats._refresh(); self.s_talent._refresh(); self.s_invite._refresh(); self.s_sort._refresh()
    
      -- Throttle (défauts)
      MultiBot.SetThrottleRate(5)
      MultiBot.SetThrottleBurst(8)
      self.s_thr_rate._refresh(); self.s_thr_burst._refresh()
    end)

    self.s_stats._refresh(); self.s_talent._refresh(); self.s_invite._refresh(); self.s_sort._refresh()
    self.s_thr_rate._refresh(); self.s_thr_burst._refresh()
  end)

  -- Enregistre proprement dans le menu Options (avec fallback 3.3.5)
  if type(InterfaceOptions_AddCategory) == "function" then
    InterfaceOptions_AddCategory(panel)
  elseif type(InterfaceOptionsFrame_AddCategory) == "function" then
    InterfaceOptionsFrame_AddCategory(panel)
  elseif type(INTERFACEOPTIONS_ADDONCATEGORIES) == "table" then
    table.insert(INTERFACEOPTIONS_ADDONCATEGORIES, panel)
  end

  MultiBot._optionsPanel = panel   -- garder une référence pour /mbopt
  MultiBot._optionsBuilt = true
  -- print("MultiBotOptions: panel registered")
end

-- Slash pour ouvrir le panneau (double appel nécessaire sur 3.3.5 parfois)
SLASH_MULTIBOTOPTIONS1 = "/mbopt"
SlashCmdList["MULTIBOTOPTIONS"] = function()
  if not MultiBot._optionsBuilt then
    if MultiBot.BuildOptionsPanel then MultiBot.BuildOptionsPanel() end
  end
  local p = MultiBot._optionsPanel
  if p and InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(p)
    InterfaceOptionsFrame_OpenToCategory(p)
  elseif p then
    -- Fallback très simple : affiche juste le frame si l’API n’existe pas
    p:Show()
  end
end

-- Ouvre/ferme le panneau d'options. Retourne true si ouvert, false si fermé.
function MultiBot.ToggleOptionsPanel()
  if not MultiBot._optionsBuilt and MultiBot.BuildOptionsPanel then
    MultiBot.BuildOptionsPanel()
  end
  local p = MultiBot._optionsPanel
  if not p then return false end

  local io = InterfaceOptionsFrame
  -- Si notre panneau est déjà affiché, on ferme la fenêtre d’options
  if io and io:IsShown() and p:IsShown() then
    HideUIPanel(io)
    return false
  end

  -- Sinon on l’ouvre (double appel nécessaire sur 3.3.5)
  if InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(p)
    InterfaceOptionsFrame_OpenToCategory(p)
  else
    p:Show()
  end
  return true
end