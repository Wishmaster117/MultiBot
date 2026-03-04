-- MultiBotOptions.lua
-- print("MultiBotOptions.lua loaded")

local PANEL_NAME = "MultiBotOptionsPanel"

local function round(x, step) step = step or 1; return math.floor(x/step + 0.5)*step end

local function optL(key)
  return MultiBot.L(key)
end

local function secondsLabel(value)
  local suffix = MultiBot.L("options.seconds_suffix")
  return string.format("%.1f %s", value, suffix)
end

local function getAceGUI()
  if type(LibStub) ~= "table" then return nil end
  return LibStub("AceGUI-3.0", true)
end

local function formatSliderLabel(baseLabel, valueLabel)
  return string.format("%s (%s)", baseLabel, valueLabel)
end

local function debugCall(method, ...)
  if not MultiBot.Debug then return end
  local fn = MultiBot.Debug[method]
  if type(fn) == "function" then
    fn(...)
  end
end

local function makeSlider(parent, key, label, minV, maxV, step, y)
  local name = PANEL_NAME .. "_" .. key .. "_Slider"
  local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", 16, y)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  s:SetWidth(300)

  _G[name .. "Text"]:SetText(label)
  _G[name .. "Low"]:SetText(secondsLabel(minV))
  _G[name .. "High"]:SetText(secondsLabel(maxV))

  local val = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  val:SetPoint("TOP", s, "BOTTOM", 0, 0)

  local function refresh()
    local v = MultiBot.GetTimer(key)
    s:SetValue(v)
    val:SetText(secondsLabel(v))
  end

  s:SetScript("OnValueChanged", function(self, v)
    v = round(v, step)
    self:SetValue(v)
    MultiBot.SetTimer(key, v)
    val:SetText(secondsLabel(v))
  end)

  s._refresh = refresh
  return s
end

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

local function buildLegacyOptionsContent(panel)
  if panel._legacyInitialized then return end
  panel._legacyInitialized = true

  local scrollFrame = CreateFrame("ScrollFrame", PANEL_NAME .. "ScrollFrame", panel, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", 3, -4)
  scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

  local scrollChild = CreateFrame("Frame", PANEL_NAME .. "ScrollChild", scrollFrame)
  scrollChild:SetSize(1, 1)
  scrollFrame:SetScrollChild(scrollChild)

  local minimapConfig = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or { hide = false }

  local strataDropDown = CreateFrame("Frame", "MultiBotStrataDropDown", scrollChild, "UIDropDownMenuTemplate")

  local chkMinimapHide = CreateFrame("CheckButton", "MultiBot_MinimapHideCheck", scrollChild, "InterfaceOptionsCheckButtonTemplate")
  chkMinimapHide:SetPoint("TOPLEFT", 16, -36)
  _G[chkMinimapHide:GetName() .. "Text"]:SetText(optL("info.buttonoptionshide"))
  chkMinimapHide.tooltipText = optL("info.buttonoptionshidetooltip")
  chkMinimapHide:SetChecked(minimapConfig.hide and true or false)
  chkMinimapHide:SetScript("OnClick", function(btn)
    local hide = btn:GetChecked() and true or false
    if MultiBot.SetMinimapConfig then
      MultiBot.SetMinimapConfig("hide", hide)
    end
    if MultiBot.Minimap_Refresh then
      MultiBot.Minimap_Refresh()
    else
      local b = _G["MultiBot_MinimapButton"] or MultiBot.MinimapButton
      if b then
        if hide then b:Hide() else b:Show() end
      end
    end
  end)

  strataDropDown:ClearAllPoints()
  strataDropDown:SetPoint("TOPLEFT", chkMinimapHide, "BOTTOMLEFT", -14, -18)

  local strataLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  strataLabel:SetPoint("BOTTOMLEFT", strataDropDown, "TOPLEFT", 16, 3)
  strataLabel:SetText(MultiBot.L("options.frame_strata"))

  panel.chkMinimapHide = chkMinimapHide

  local current = (MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()) or "HIGH"
  local strataLevels = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP" }

  local function OnClick(button)
    UIDropDownMenu_SetSelectedID(strataDropDown, button:GetID())
    if MultiBot.SetGlobalStrataLevel then
      MultiBot.SetGlobalStrataLevel(strataLevels[button:GetID()])
    end
    if MultiBot.ApplyGlobalStrata then
      MultiBot.ApplyGlobalStrata()
    end
  end

  local function Initialize(dropdown, level)
    local info
    for _, v in ipairs(strataLevels) do
      info = UIDropDownMenu_CreateInfo()
      info.text = v
      info.value = v
      info.func = OnClick
      UIDropDownMenu_AddButton(info, level)
    end
  end

  UIDropDownMenu_Initialize(strataDropDown, Initialize)
  UIDropDownMenu_SetWidth(strataDropDown, 120)
  UIDropDownMenu_SetButtonWidth(strataDropDown, 144)
  UIDropDownMenu_SetSelectedValue(strataDropDown, current)
  UIDropDownMenu_JustifyText(strataDropDown, "LEFT")

  local sub = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", strataDropDown, "BOTTOMLEFT", 20, -12)
  sub:SetText(optL("tips.sliders.actionsinter"))

  scrollChild.s_stats = makeSlider(scrollChild, "stats", optL("tips.sliders.statsinter"), 5, 300, 1, -40)
  scrollChild.s_talent = makeSlider(scrollChild, "talent", optL("tips.sliders.talentsinter"), 1, 30, 0.5, -90)
  scrollChild.s_invite = makeSlider(scrollChild, "invite", optL("tips.sliders.invitsinter"), 1, 60, 1, -140)
  scrollChild.s_sort = makeSlider(scrollChild, "sort", optL("tips.sliders.sortinter"), 0.2, 10, 0.2, -190)

  scrollChild.s_thr_rate = makeThrottleSlider(scrollChild, "thr_rate", optL("tips.sliders.messpersec"), 1, 20, 1, 0)
  scrollChild.s_thr_burst = makeThrottleSlider(scrollChild, "thr_burst", optL("tips.sliders.maxburst"), 1, 50, 1, 0)

  scrollChild.s_stats:ClearAllPoints()
  scrollChild.s_stats:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)

  scrollChild.s_talent:ClearAllPoints()
  scrollChild.s_talent:SetPoint("TOPLEFT", scrollChild.s_stats, "BOTTOMLEFT", 0, -36)

  scrollChild.s_invite:ClearAllPoints()
  scrollChild.s_invite:SetPoint("TOPLEFT", scrollChild.s_talent, "BOTTOMLEFT", 0, -36)

  scrollChild.s_sort:ClearAllPoints()
  scrollChild.s_sort:SetPoint("TOPLEFT", scrollChild.s_invite, "BOTTOMLEFT", 0, -36)

  scrollChild.s_thr_rate:ClearAllPoints()
  scrollChild.s_thr_rate:SetPoint("TOPLEFT", scrollChild.s_sort, "BOTTOMLEFT", 0, -36)

  scrollChild.s_thr_burst:ClearAllPoints()
  scrollChild.s_thr_burst:SetPoint("TOPLEFT", scrollChild.s_thr_rate, "BOTTOMLEFT", 0, -36)

  local btn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
  btn:SetSize(140, 22)
  btn:ClearAllPoints()
  btn:SetPoint("TOPLEFT", scrollChild.s_thr_burst, "BOTTOMLEFT", 0, -24)
  btn:SetText(optL("tips.sliders.rstbutn"))
  btn:SetScript("OnClick", function()
    MultiBot.SetTimer("stats", 45)
    MultiBot.SetTimer("talent", 3)
    MultiBot.SetTimer("invite", 5)
    MultiBot.SetTimer("sort", 1)
    scrollChild.s_stats._refresh(); scrollChild.s_talent._refresh(); scrollChild.s_invite._refresh(); scrollChild.s_sort._refresh()

    MultiBot.SetThrottleRate(5)
    MultiBot.SetThrottleBurst(8)
    scrollChild.s_thr_rate._refresh(); scrollChild.s_thr_burst._refresh()
  end)

  scrollChild.s_stats._refresh(); scrollChild.s_talent._refresh(); scrollChild.s_invite._refresh(); scrollChild.s_sort._refresh()
  scrollChild.s_thr_rate._refresh(); scrollChild.s_thr_burst._refresh()
end

function MultiBot.BuildOptionsPanel()
  if MultiBot._optionsBuilt then return end

  local panel = CreateFrame("Frame", PANEL_NAME, UIParent)
  panel.name = optL("tips.sliders.frametitle")
  panel:Hide()

  panel:SetScript("OnShow", function(self)
    if self._initialized then return end
    self._initialized = true

    local AceGUI = getAceGUI()
    if not AceGUI then
      debugCall("AceGUILoadState", "LibStub returned nil for AceGUI-3.0")
      debugCall("OptionsPath", "legacy", "LibStub('AceGUI-3.0') not available")
      buildLegacyOptionsContent(self)
      return
    end

    local probeOk, probeWidget = pcall(AceGUI.Create, AceGUI, "Label")
    if not probeOk or not probeWidget then
      debugCall("AceGUILoadState", "AceGUI:Create('Label') failed: " .. tostring(probeWidget))
      debugCall("OptionsPath", "legacy", "AceGUI widget creation failed")
      buildLegacyOptionsContent(self)
      return
    end
    AceGUI:Release(probeWidget)
    --debugAceGUILoadState("AceGUI widget probe succeeded")
    --debugOptionsPath("AceGUI", "widget probe succeeded")

    local root = AceGUI:Create("SimpleGroup")
    root:SetFullWidth(true)
    root:SetFullHeight(true)
    root:SetLayout("Fill")
    root.frame:SetParent(self)
    root.frame:ClearAllPoints()
    root.frame:SetPoint("TOPLEFT", 8, -8)
    root.frame:SetPoint("BOTTOMRIGHT", -8, 8)
    self._aceRoot = root

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    root:AddChild(scroll)

    local minimapConfig = MultiBot.GetMinimapConfig and MultiBot.GetMinimapConfig() or { hide = false }
    local chkMinimapHide = AceGUI:Create("CheckBox")
    chkMinimapHide:SetLabel(optL("info.buttonoptionshide"))
    chkMinimapHide:SetValue(minimapConfig.hide and true or false)
    chkMinimapHide:SetFullWidth(true)
    chkMinimapHide:SetCallback("OnValueChanged", function(_, _, hide)
      if MultiBot.SetMinimapConfig then
        MultiBot.SetMinimapConfig("hide", hide and true or false)
      end
      if MultiBot.Minimap_Refresh then
        MultiBot.Minimap_Refresh()
      else
        local b = _G["MultiBot_MinimapButton"] or MultiBot.MinimapButton
        if b then
          if hide then b:Hide() else b:Show() end
        end
      end
    end)
    scroll:AddChild(chkMinimapHide)
    panel.chkMinimapHide = chkMinimapHide

    local strata = AceGUI:Create("Dropdown")
    strata:SetLabel(MultiBot.L("options.frame_strata"))
    strata:SetWidth(240)
    local strataLevels = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP" }
    local strataList = {}
    for _, v in ipairs(strataLevels) do strataList[v] = v end
    strata:SetList(strataList)
    strata:SetValue((MultiBot.GetGlobalStrataLevel and MultiBot.GetGlobalStrataLevel()) or "HIGH")
    strata:SetCallback("OnValueChanged", function(_, _, value)
      if MultiBot.SetGlobalStrataLevel then
        MultiBot.SetGlobalStrataLevel(value)
      end
      if MultiBot.ApplyGlobalStrata then
        MultiBot.ApplyGlobalStrata()
      end
    end)
    scroll:AddChild(strata)

    local spacer = AceGUI:Create("Label")
    spacer:SetText(" ")
    spacer:SetFullWidth(true)
    scroll:AddChild(spacer)

    local sub = AceGUI:Create("Label")
    sub:SetText(optL("tips.sliders.actionsinter"))
    sub:SetFullWidth(true)
    scroll:AddChild(sub)

    local sliderRefs = {}

    local function buildTimerSlider(key, label, minV, maxV, step)
      local slider = AceGUI:Create("Slider")
      slider:SetFullWidth(true)
      slider:SetSliderValues(minV, maxV, step)
      slider:SetLabel(label)
      slider:SetCallback("OnValueChanged", function(widget, _, value)
        value = round(value, step)
        MultiBot.SetTimer(key, value)
        widget:SetLabel(formatSliderLabel(label, secondsLabel(value)))
        widget:SetValue(value)
      end)
      slider._refresh = function()
        local value = MultiBot.GetTimer(key)
        slider:SetValue(value)
        slider:SetLabel(formatSliderLabel(label, secondsLabel(value)))
      end
      sliderRefs[#sliderRefs + 1] = slider
      scroll:AddChild(slider)
      return slider
    end

    local function buildThrottleSlider(key, label, minV, maxV, step)
      local getValue = (key == "thr_rate") and MultiBot.GetThrottleRate or MultiBot.GetThrottleBurst
      local setValue = (key == "thr_rate") and MultiBot.SetThrottleRate or MultiBot.SetThrottleBurst
      local slider = AceGUI:Create("Slider")
      slider:SetFullWidth(true)
      slider:SetSliderValues(minV, maxV, step)
      slider:SetLabel(label)
      slider:SetCallback("OnValueChanged", function(widget, _, value)
        value = round(value, step)
        setValue(value)
        widget:SetLabel(formatSliderLabel(label, tostring(value)))
        widget:SetValue(value)
      end)
      slider._refresh = function()
        local value = getValue()
        slider:SetValue(value)
        slider:SetLabel(formatSliderLabel(label, tostring(value)))
      end
      sliderRefs[#sliderRefs + 1] = slider
      scroll:AddChild(slider)
      return slider
    end

    local s_stats = buildTimerSlider("stats", optL("tips.sliders.statsinter"), 5, 300, 1)
    local s_talent = buildTimerSlider("talent", optL("tips.sliders.talentsinter"), 1, 30, 0.5)
    local s_invite = buildTimerSlider("invite", optL("tips.sliders.invitsinter"), 1, 60, 1)
    local s_sort = buildTimerSlider("sort", optL("tips.sliders.sortinter"), 0.2, 10, 0.2)
    local s_thr_rate = buildThrottleSlider("thr_rate", optL("tips.sliders.messpersec"), 1, 20, 1)
    local s_thr_burst = buildThrottleSlider("thr_burst", optL("tips.sliders.maxburst"), 1, 50, 1)

    local btn = AceGUI:Create("Button")
    btn:SetText(optL("tips.sliders.rstbutn"))
    btn:SetWidth(180)
    btn:SetCallback("OnClick", function()
      MultiBot.SetTimer("stats", 45)
      MultiBot.SetTimer("talent", 3)
      MultiBot.SetTimer("invite", 5)
      MultiBot.SetTimer("sort", 1)
      MultiBot.SetThrottleRate(5)
      MultiBot.SetThrottleBurst(8)
      for _, slider in ipairs(sliderRefs) do
        slider._refresh()
      end
    end)
    scroll:AddChild(btn)

    s_stats._refresh()
    s_talent._refresh()
    s_invite._refresh()
    s_sort._refresh()
    s_thr_rate._refresh()
    s_thr_burst._refresh()
  end)

  if type(InterfaceOptions_AddCategory) == "function" then
    InterfaceOptions_AddCategory(panel)
  elseif type(InterfaceOptionsFrame_AddCategory) == "function" then
    InterfaceOptionsFrame_AddCategory(panel)
  elseif type(INTERFACEOPTIONS_ADDONCATEGORIES) == "table" then
    table.insert(INTERFACEOPTIONS_ADDONCATEGORIES, panel)
  end

  MultiBot._optionsPanel = panel
  MultiBot._optionsBuilt = true
end

local function OpenOptionsPanelFromSlash()
  if not MultiBot._optionsBuilt then
    if MultiBot.BuildOptionsPanel then MultiBot.BuildOptionsPanel() end
  end
  local p = MultiBot._optionsPanel
  if p and InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(p)
    InterfaceOptionsFrame_OpenToCategory(p)
  elseif p then
    p:Show()
  end
end

MultiBot.RegisterCommandAliases("MULTIBOTOPTIONS", OpenOptionsPanelFromSlash, { "mbopt" })

function MultiBot.ToggleOptionsPanel()
  if not MultiBot._optionsBuilt and MultiBot.BuildOptionsPanel then
    MultiBot.BuildOptionsPanel()
  end
  local p = MultiBot._optionsPanel
  if not p then return false end

  local io = InterfaceOptionsFrame
  if io and io:IsShown() and p:IsShown() then
    HideUIPanel(io)
    return false
  end

  if InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(p)
    InterfaceOptionsFrame_OpenToCategory(p)
  else
    p:Show()
  end
  return true
end
