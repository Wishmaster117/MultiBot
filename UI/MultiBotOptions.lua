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

local function getSavedLayoutOwners()
  if not MultiBot.GetSavedMainBarLayoutOwners then
    return {}
  end
  local owners = MultiBot.GetSavedMainBarLayoutOwners()
  local currentPlayer = UnitName and UnitName("player") or nil
  local currentRealm = GetRealmName and GetRealmName() or nil
  local currentOwner = currentPlayer
  if type(currentPlayer) == "string" and currentPlayer ~= "" and type(currentRealm) == "string" and currentRealm ~= "" then
    currentOwner = currentPlayer .. "-" .. currentRealm
  end

  if type(currentOwner) ~= "string" or currentOwner == "" then
    return owners
  end

  local ordered = {}
  for _, owner in ipairs(owners) do
    if owner == currentOwner then
      table.insert(ordered, 1, owner)
    else
      table.insert(ordered, owner)
    end
  end
  return ordered
end

local function importLayoutOwner(ownerKey)
  if not MultiBot.ImportSavedMainBarLayout then
    return false, "import_indisponible"
  end
  return MultiBot.ImportSavedMainBarLayout(ownerKey)
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
  local mainBarMoveLocked = MultiBot.GetMainBarMoveLocked and MultiBot.GetMainBarMoveLocked() or true

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

  local chkMainBarMoveLocked = CreateFrame("CheckButton", "MultiBot_MainBarMoveLockedCheck", scrollChild, "InterfaceOptionsCheckButtonTemplate")
  chkMainBarMoveLocked:SetPoint("TOPLEFT", chkMinimapHide, "BOTTOMLEFT", 0, -8)
  _G[chkMainBarMoveLocked:GetName() .. "Text"]:SetText("Verrouiller déplacement barre principale")
  chkMainBarMoveLocked.tooltipText = "Cochée: Ctrl + clic droit pour déplacer la barre.\nDécochée: clic droit suffit."
  chkMainBarMoveLocked:SetChecked(mainBarMoveLocked and true or false)
  chkMainBarMoveLocked:SetScript("OnClick", function(btn)
    if MultiBot.SetMainBarMoveLocked then
      MultiBot.SetMainBarMoveLocked(btn:GetChecked() and true or false)
    end
  end)

  panel.chkMinimapHide = chkMinimapHide
  panel.chkMainBarMoveLocked = chkMainBarMoveLocked

  local selectedOwnerKey = nil
  local refreshOwnerDropdown

  local exportBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
  exportBtn:SetSize(110, 22)
  exportBtn:SetPoint("TOPLEFT", chkMainBarMoveLocked, "BOTTOMLEFT", 0, -14)
  exportBtn:SetText("Export layout")
  exportBtn:SetScript("OnClick", function()
    if MultiBot.SaveMainBarLayoutForCurrentPlayer then
      local ok, ownerKey, payloadOrError = MultiBot.SaveMainBarLayoutForCurrentPlayer()
      if UIErrorsFrame then
        if ok then
          UIErrorsFrame:AddMessage(("Layout sauvegardé: %s"):format(ownerKey), 0.25, 1, 0.25, 1)
          selectedOwnerKey = ownerKey
          if refreshOwnerDropdown then
            refreshOwnerDropdown()
          end
        else
          UIErrorsFrame:AddMessage(("Export échoué: %s"):format(tostring(ownerKey or payloadOrError)), 1, 0.25, 0.25, 1)
        end
      end
    end
  end)

  local importBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
  importBtn:SetSize(110, 22)
  importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
  importBtn:SetText("Import layout")
  importBtn:SetScript("OnClick", function()
    if selectedOwnerKey then
      local ok, detail = importLayoutOwner(selectedOwnerKey)
      if UIErrorsFrame then
        if ok then
          UIErrorsFrame:AddMessage(("Layout importé: %s (%s entrées)"):format(selectedOwnerKey, tostring(detail)), 0.25, 1, 0.25, 1)
        else
          UIErrorsFrame:AddMessage(("Import échoué: %s"):format(tostring(detail)), 1, 0.25, 0.25, 1)
        end
      end
      return
    end
    if UIErrorsFrame then
      UIErrorsFrame:AddMessage("Aucun layout enregistré à importer.", 1, 0.25, 0.25, 1)
    end
  end)

  local deleteBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
  deleteBtn:SetSize(110, 22)
  deleteBtn:SetPoint("TOPLEFT", importBtn, "BOTTOMLEFT", 0, -6)
  deleteBtn:SetText("Suppr layout")
  deleteBtn:SetScript("OnClick", function()
    if not selectedOwnerKey then
      if UIErrorsFrame then
        UIErrorsFrame:AddMessage("Aucun layout sélectionné à supprimer.", 1, 0.25, 0.25, 1)
      end
      return
    end

    if not MultiBot.DeleteSavedMainBarLayout then
      if UIErrorsFrame then
        UIErrorsFrame:AddMessage("Suppression indisponible.", 1, 0.25, 0.25, 1)
      end
      return
    end

    local ok, detail = MultiBot.DeleteSavedMainBarLayout(selectedOwnerKey)
    if UIErrorsFrame then
      if ok then
        UIErrorsFrame:AddMessage(("Layout supprimé: %s"):format(selectedOwnerKey), 1, 0.82, 0, 1)
      else
        UIErrorsFrame:AddMessage(("Suppression échouée: %s"):format(tostring(detail)), 1, 0.25, 0.25, 1)
      end
    end
    refreshOwnerDropdown()
  end)

  local refreshBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
  refreshBtn:SetSize(110, 22)
  refreshBtn:SetPoint("LEFT", deleteBtn, "RIGHT", 8, 0)
  refreshBtn:SetText("Refresh liste")
  refreshBtn:SetScript("OnClick", function()
    refreshOwnerDropdown()
    if UIErrorsFrame then
      UIErrorsFrame:AddMessage("Liste layouts rafraîchie.", 0.25, 1, 0.25, 1)
    end
  end)

  local resetBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
  resetBtn:SetSize(110, 22)
  resetBtn:SetPoint("TOPLEFT", refreshBtn, "BOTTOMLEFT", 0, -6)
  resetBtn:SetText("Reset layout")
  resetBtn:SetScript("OnClick", function()
    if not MultiBot.ResetMainBarLayoutState then
      if UIErrorsFrame then
        UIErrorsFrame:AddMessage("Reset layout indisponible.", 1, 0.25, 0.25, 1)
      end
      return
    end
    local ok, removed = MultiBot.ResetMainBarLayoutState()
    if UIErrorsFrame then
      if ok then
        UIErrorsFrame:AddMessage(("Layout reset (%s clés)."):format(tostring(removed)), 1, 0.82, 0, 1)
      else
        UIErrorsFrame:AddMessage("Reset layout échoué.", 1, 0.25, 0.25, 1)
      end
    end
    refreshOwnerDropdown()
  end)

  local ownerDropDown = CreateFrame("Frame", "MultiBotLayoutOwnerDropDown", scrollChild, "UIDropDownMenuTemplate")
  ownerDropDown:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", -14, -8)
  local ownerLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ownerLabel:SetPoint("BOTTOMLEFT", ownerDropDown, "TOPLEFT", 16, 3)
  ownerLabel:SetText("Layout joueur à importer")

  refreshOwnerDropdown = function()
    local owners = getSavedLayoutOwners()
    UIDropDownMenu_Initialize(ownerDropDown, function(_, level)
      for idx, ownerKey in ipairs(owners) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = ownerKey
        info.value = ownerKey
        info.func = function(button)
          selectedOwnerKey = owners[button:GetID()]
          UIDropDownMenu_SetSelectedID(ownerDropDown, button:GetID())
        end
        UIDropDownMenu_AddButton(info, level)
      end
    end)
    if #owners > 0 then
      selectedOwnerKey = selectedOwnerKey or owners[1]
      local selectedIndex = 1
      for idx, ownerKey in ipairs(owners) do
        if ownerKey == selectedOwnerKey then
          selectedIndex = idx
          break
        end
      end
      UIDropDownMenu_SetSelectedID(ownerDropDown, selectedIndex)
      UIDropDownMenu_SetText(ownerDropDown, selectedOwnerKey)
    else
      selectedOwnerKey = nil
      UIDropDownMenu_SetText(ownerDropDown, "Aucun layout")
    end
  end
  refreshOwnerDropdown()

  strataDropDown:ClearAllPoints()
  strataDropDown:SetPoint("TOPLEFT", resetBtn, "BOTTOMLEFT", -14, -12)

  local strataLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  strataLabel:SetPoint("BOTTOMLEFT", strataDropDown, "TOPLEFT", 16, 3)
  strataLabel:SetText(MultiBot.L("options.frame_strata"))

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

    local selectedOwnerKey = nil
    local strataLevels = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "TOOLTIP" }

    local function addTabScroll(tabGroup)
      local scroll = AceGUI:Create("ScrollFrame")
      scroll:SetLayout("List")
      tabGroup:AddChild(scroll)
      return scroll
    end

    local function buildMinimapTab(tabGroup)
      local scroll = addTabScroll(tabGroup)
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
    end

    local function buildLayoutTab(tabGroup)
      local scroll = addTabScroll(tabGroup)
      local mainBarMoveLocked = MultiBot.GetMainBarMoveLocked and MultiBot.GetMainBarMoveLocked() or true

      local chkMainBarMoveLocked = AceGUI:Create("CheckBox")
      chkMainBarMoveLocked:SetLabel("Verrouiller déplacement barre principale")
      if chkMainBarMoveLocked.SetDescription then
        chkMainBarMoveLocked:SetDescription("Cochée: Ctrl + clic droit pour déplacer la barre. Décochée: clic droit suffit.")
      end
      chkMainBarMoveLocked:SetValue(mainBarMoveLocked and true or false)
      chkMainBarMoveLocked:SetFullWidth(true)
      chkMainBarMoveLocked:SetCallback("OnValueChanged", function(_, _, value)
        if MultiBot.SetMainBarMoveLocked then
          MultiBot.SetMainBarMoveLocked(value and true or false)
        end
      end)
      scroll:AddChild(chkMainBarMoveLocked)
      panel.chkMainBarMoveLocked = chkMainBarMoveLocked

      local ownerDropDown = AceGUI:Create("Dropdown")
      ownerDropDown:SetLabel("Layout joueur à importer")
      ownerDropDown:SetWidth(320)
      ownerDropDown:SetCallback("OnValueChanged", function(_, _, value)
        selectedOwnerKey = value
      end)

      local function refreshOwnerList()
        local owners = getSavedLayoutOwners()
        local options = {}
        for _, owner in ipairs(owners) do
          options[owner] = owner
        end
        ownerDropDown:SetList(options)
        if #owners == 0 then
          selectedOwnerKey = nil
          ownerDropDown:SetValue(nil)
          return
        end
        if not selectedOwnerKey or not options[selectedOwnerKey] then
          selectedOwnerKey = owners[1]
        end
        ownerDropDown:SetValue(selectedOwnerKey)
      end

      refreshOwnerList()
      scroll:AddChild(ownerDropDown)

      local layoutActions = AceGUI:Create("SimpleGroup")
      layoutActions:SetLayout("Flow")
      layoutActions:SetFullWidth(true)

      local exportBtn = AceGUI:Create("Button")
      exportBtn:SetText("Export layout")
      exportBtn:SetWidth(150)
      exportBtn:SetCallback("OnClick", function()
        if MultiBot.SaveMainBarLayoutForCurrentPlayer then
          local ok, ownerKey = MultiBot.SaveMainBarLayoutForCurrentPlayer()
          if UIErrorsFrame then
            if ok then
              UIErrorsFrame:AddMessage(("Layout sauvegardé: %s"):format(ownerKey), 0.25, 1, 0.25, 1)
            else
              UIErrorsFrame:AddMessage(("Export échoué: %s"):format(tostring(ownerKey)), 1, 0.25, 0.25, 1)
            end
          end
        end
        refreshOwnerList()
      end)
      layoutActions:AddChild(exportBtn)

      local importBtn = AceGUI:Create("Button")
      importBtn:SetText("Import layout")
      importBtn:SetWidth(150)
      importBtn:SetCallback("OnClick", function()
        if selectedOwnerKey then
          local ok, detail = importLayoutOwner(selectedOwnerKey)
          if UIErrorsFrame then
            if ok then
              UIErrorsFrame:AddMessage(("Layout importé: %s (%s entrées)"):format(selectedOwnerKey, tostring(detail)), 0.25, 1, 0.25, 1)
            else
              UIErrorsFrame:AddMessage(("Import échoué: %s"):format(tostring(detail)), 1, 0.25, 0.25, 1)
            end
          end
          return
        end
        if UIErrorsFrame then
          UIErrorsFrame:AddMessage("Aucun layout enregistré à importer.", 1, 0.25, 0.25, 1)
        end
      end)
      layoutActions:AddChild(importBtn)

      local deleteBtn = AceGUI:Create("Button")
      deleteBtn:SetText("Suppr layout")
      deleteBtn:SetWidth(150)
      deleteBtn:SetCallback("OnClick", function()
        if not selectedOwnerKey then
          if UIErrorsFrame then
            UIErrorsFrame:AddMessage("Aucun layout sélectionné à supprimer.", 1, 0.25, 0.25, 1)
          end
          return		  
        end
        if not MultiBot.DeleteSavedMainBarLayout then
          if UIErrorsFrame then
            UIErrorsFrame:AddMessage("Suppression indisponible.", 1, 0.25, 0.25, 1)
          end
          return
        end
        local ok, detail = MultiBot.DeleteSavedMainBarLayout(selectedOwnerKey)
        if UIErrorsFrame then
          if ok then
            UIErrorsFrame:AddMessage(("Layout supprimé: %s"):format(selectedOwnerKey), 1, 0.82, 0, 1)
          else
            UIErrorsFrame:AddMessage(("Suppression échouée: %s"):format(tostring(detail)), 1, 0.25, 0.25, 1)
          end
        end
        refreshOwnerList()
      end)
      layoutActions:AddChild(deleteBtn)

      local refreshBtn = AceGUI:Create("Button")
      refreshBtn:SetText("Refresh liste")
      refreshBtn:SetWidth(150)
      refreshBtn:SetCallback("OnClick", function()
        refreshOwnerList()
        if UIErrorsFrame then
          UIErrorsFrame:AddMessage("Liste layouts rafraîchie.", 0.25, 1, 0.25, 1)
        end
      end)
      layoutActions:AddChild(refreshBtn)

      local resetBtn = AceGUI:Create("Button")
      resetBtn:SetText("Reset layout")
      resetBtn:SetWidth(150)
      resetBtn:SetCallback("OnClick", function()
        if not MultiBot.ResetMainBarLayoutState then
          if UIErrorsFrame then
            UIErrorsFrame:AddMessage("Reset layout indisponible.", 1, 0.25, 0.25, 1)
          end
          return
        end
        local ok, removed = MultiBot.ResetMainBarLayoutState()
        if UIErrorsFrame then
          if ok then
            UIErrorsFrame:AddMessage(("Layout reset (%s clés)."):format(tostring(removed)), 1, 0.82, 0, 1)
          else
            UIErrorsFrame:AddMessage("Reset layout échoué.", 1, 0.25, 0.25, 1)
          end
        end
        refreshOwnerList()
      end)
      layoutActions:AddChild(resetBtn)
      scroll:AddChild(layoutActions)
    end

    local function buildStrataTab(tabGroup)
      local scroll = addTabScroll(tabGroup)
      local strata = AceGUI:Create("Dropdown")
      strata:SetLabel(MultiBot.L("options.frame_strata"))
      strata:SetWidth(240)
      local strataList = {}
      for _, strataLevel in ipairs(strataLevels) do
        strataList[strataLevel] = strataLevel
      end
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
    end

    local function buildIntervalsTab(tabGroup)
      local scroll = addTabScroll(tabGroup)

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
    end

    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Fill")
    tabGroup:SetTabs({
      { text = "Minimap", value = "minimap" },
      { text = "Layout", value = "layout" },
      { text = "Strata", value = "strata" },
      { text = "Intervals", value = "intervals" },
    })
    tabGroup:SetCallback("OnGroupSelected", function(widget, _, group)
      widget:ReleaseChildren()
      if group == "minimap" then
        buildMinimapTab(widget)
      elseif group == "layout" then
        buildLayoutTab(widget)
      elseif group == "strata" then
        buildStrataTab(widget)
      elseif group == "intervals" then
        buildIntervalsTab(widget)
      end
    end)
    root:AddChild(tabGroup)
    tabGroup:SelectTab("minimap")
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
