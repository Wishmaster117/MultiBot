-- Configuration Luacheck
std = "lua53"

globals = {
    "MultiBot", "GetLocale", "GetSpellInfo", "GetSpellLink", "MultiBotSave", "SendChatMessage", "CreateFrame", "UIParent",
    "MultiBotGlobalSave", "DEFAULT_CHAT_FRAME", "C_Timer_After", "IsInRaid", "GetNumRaidMembers", "IsInGroup", "GetNumPartyMembers",
    "GetNumGroupMembers", "GetNumSubgroupMembers", "lvl", "C_Timer", "UnitClass", "InspectUnit", "InspectFrame", "HideUIPanel",
    "tinsert", "strtrim", "wipe", "UnitName", "GetRealmName", "GameTooltip", "GameTooltip_Hide", "MultiBotDB", "SlashCmdList",
    "GetScreenWidth", "tParts", "tSpace", "strsub", "strlen", "GetNumTalents", "UnitLevel", "IsSpellKnown", "GetInventoryItemLink",
    "iName", "iLink", "iRare", "iMinLevel", "iType", "iSubType", "iStack", "GetItemInfo", "floor", "tIcon", "tBody", "GetMacroInfo",
    "CreateMacro", "PickupMacro", "UnitSex", "UnitRace", "substr", "StaticPopupDialogs", "ACCEPT", "CANCEL", "StaticPopup_Show",
    "MultiBotPVPFrame", "GetItemIcon", "OKAY", "_MB_getIcon", "_MB_applyDesat", "_MB_applyDesatToTexture", "_MB_setDesat", "unpack",
	"CheckInteractDistance"
}

-- Interdire les tabulations
no_tab_indent = true

-- Indentation à 4 espaces
indent_size = 4

-- Options de propreté du code
unused_args = false
unused_vars = false
redefined_vars = false
unused_values = false

-- Interdire les globals implicites
allow_defined_top = false

-- Considérer 'self' comme utilisé automatiquement
self = true

-- Limite de longueur de ligne
max_line_length = 120