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