-- Configuration Luacheck
std = "lua53"

-- Autoriser certaines globales spécifiques à MultiBot et WoW API
globals = {
    "MultiBot", "GetLocale", "GetSpellInfo", "GetSpellLink", "MultiBotSave", "SendChatMessage", "CreateFrame", "UIParent",
    "MultiBotGlobalSave", "DEFAULT_CHAT_FRAME", "C_Timer_After", "IsInRaid", "GetNumRaidMembers", "IsInGroup", "GetNumPartyMembers",
    "GetNumGroupMembers", "GetNumSubgroupMembers", "lvl", "C_Timer", "UnitClass", "InspectUnit", "InspectFrame", "HideUIPanel",
    "tinsert", "strtrim", "wipe", "UnitName", "GetRealmName", "GameTooltip", "GameTooltip_Hide", "MultiBotDB", "SlashCmdList",
    "GetScreenWidth", "tParts", "tSpace", "strsub", "strlen", "GetNumTalents", "UnitLevel", "IsSpellKnown", "GetInventoryItemLink",
    "iName", "iLink", "iRare", "iMinLevel", "iType", "iSubType", "iStack", "GetItemInfo", "floor", "tIcon", "tBody", "GetMacroInfo",
    "CreateMacro", "PickupMacro", "UnitSex", "UnitRace", "substr", "StaticPopupDialogs", "ACCEPT", "CANCEL", "StaticPopup_Show",
    "MultiBotPVPFrame", "GetItemIcon", "OKAY", "_MB_getIcon", "_MB_applyDesat", "_MB_applyDesatToTexture", "_MB_setDesat", "unpack"
}

-- Interdire les tabulations
no_tab_indent = true

-- Indentation à 4 espaces
indent_size = 4

-- Options de propreté du code
unused_args = false        -- Interdit les arguments non utilisés
unused_vars = false        -- Interdit les variables locales non utilisées
redefined_vars = false     -- Interdit la redéfinition de variables locales
unused_values = false      -- Interdit les valeurs calculées mais jamais utilisées
ignore = { "511" }         -- Exemple : ignorer "ligne trop longue" si besoin

-- Interdire les globals implicites
allow_defined_top = false  -- Interdit de définir des globals hors de 'globals'

-- Forcer les noms de variables cohérents
self = "self"              -- Vérifie que 'self' est utilisé correctement
max_line_length = 120      -- Limite la longueur des lignes