-- Configuration Luacheck
std = "lua53"

-- Autoriser la globale MultiBot
globals = { "MultiBot", "GetLocale", "GetSpellInfo", "GetSpellLink", "MultiBotSave", "SendChatMessage", "CreateFrame", "UIParent", "MultiBotGlobalSave", "DEFAULT_CHAT_FRAME", "C_Timer_After",
             "IsInRaid", "GetNumRaidMembers", "IsInGroup", "GetNumPartyMembers", "GetNumGroupMembers", "GetNumSubgroupMembers", "lvl",
             "C_Timer", "UnitClass", "InspectUnit", "InspectFrame", "HideUIPanel", "tinsert", "strtrim", "wipe", "UnitName", "GetRealmName", "GameTooltip", "GameTooltip_Hide" }

-- Interdire les tabulations
no_tab_indent = true

-- Indentation à 4 espaces
indent_size = 4