if not MultiBot then return end

local sharedTimerAfter = MultiBot.TimerAfter or _G.TimerAfter

if type(sharedTimerAfter) ~= "function" then
    local function runProtectedCallback(callback)
        if type(callback) ~= "function" then
            return
        end

        local ok, err = pcall(callback)
        if not ok and MultiBot and type(MultiBot.dprint) == "function" then
            MultiBot.dprint("TimerAfter", err)
        end
    end

    sharedTimerAfter = function(delay, callback)
        if type(callback) ~= "function" then
            return nil
        end

        local waitTime = math.max(tonumber(delay) or 0, 0)

        if type(C_Timer) == "table" and type(C_Timer.After) == "function" then
            return C_Timer.After(waitTime, callback)
        end

        -- M11 ownership: keep this fallback OnUpdate local to the scheduler wrapper only.
        -- Reason: legacy compatibility when C_Timer.After is unavailable.
        local timerFrame = CreateFrame("Frame")
        local elapsed = 0

        timerFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + (tonumber(dt) or 0)
            if elapsed < waitTime then
                return
            end

            self:SetScript("OnUpdate", nil)
            runProtectedCallback(callback)
        end)

        return timerFrame
    end
end

MultiBot.TimerAfter = sharedTimerAfter
_G.TimerAfter = sharedTimerAfter

-- M11 scheduler contract:
-- TimerAfter/NextTick are the only delay APIs that should be used outside this file.
function MultiBot.NextTick(callback)
    if type(callback) ~= "function" then
        return nil
    end

    return sharedTimerAfter(0, callback)
end