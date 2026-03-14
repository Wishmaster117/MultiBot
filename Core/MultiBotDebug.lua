-- MultiBotDebug.lua
-- Temporary migration debug helpers.
-- Keep this file during ACE3 migration; remove once migration diagnostics are no longer needed.

MultiBot.Debug = MultiBot.Debug or {}

local function EmitDebugMessage(message, colorHex)
  local text = message
  if colorHex and colorHex ~= "" then
    text = "|cff" .. colorHex .. message .. "|r"
  end

  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(text)
  elseif type(print) == "function" then
    print(message)
  end
end

function MultiBot.Debug.Print(message, colorHex)
  EmitDebugMessage(tostring(message), colorHex)
end

function MultiBot.Debug.Once(key, message, colorHex)
  if type(key) ~= "string" or key == "" then
    MultiBot.Debug.Print(message, colorHex)
    return
  end

  MultiBot._debugOnceFlags = MultiBot._debugOnceFlags or {}
  if MultiBot._debugOnceFlags[key] then
    return
  end

  MultiBot._debugOnceFlags[key] = true
  MultiBot.Debug.Print(message, colorHex)
end

function MultiBot.Debug.OptionsPath(path, detail)
  local message = string.format("MultiBot Options: using %s path", tostring(path))
  if detail and detail ~= "" then
    message = message .. string.format(" (%s)", detail)
  end
  MultiBot.Debug.Once("options.path", message, "33ff99")
end

function MultiBot.Debug.AceGUILoadState(reason)
  local hasLibStub = type(LibStub) == "table"
  local aceMinor = nil
  local aceLoaded = false

  if hasLibStub and type(LibStub.minors) == "table" then
    aceMinor = LibStub.minors["AceGUI-3.0"]
    aceLoaded = LibStub.libs and LibStub.libs["AceGUI-3.0"] ~= nil
  end

  local message = string.format(
    "MultiBot Options: AceGUI debug => reason=%s, LibStub=%s, minor=%s, loaded=%s",
    tostring(reason),
    tostring(hasLibStub),
    tostring(aceMinor),
    tostring(aceLoaded)
  )

  MultiBot.Debug.Once("options.acegui.load", message, "ffff00")
end