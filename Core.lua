local addonName, addon = ...

-- Global reference for debugging
DuoDungeonTracker = addon

-- State
local currentRun = nil
addon.debugSoloMode = false

-- Event Frame
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Helper: Get current dungeon data (By Instance ID)
function addon:GetCurrentDungeonInfo()
    local _, _, _, _, _, _, _, zoneID = GetInstanceInfo()
    local data = addon.DungeonData[tonumber(zoneID)]
    if data then
        return data.name, data
    end
    return nil, nil
end

-- Helper: Get dungeon data by Name (for Slash Commands / UI)
function addon:GetDungeonDataByName(targetName)
    for id, data in pairs(addon.DungeonData) do
        if data.name == targetName then
            return data
        end
    end
    return nil
end

-- Helper: Check if party is valid (Exactly 2 players)
function addon:IsPartyValid()
    if addon.debugSoloMode then return true end
    return IsInGroup() and GetNumGroupMembers() == 2
end

-- Start a new run
function addon:StartRun(dungeonName, dungeonData)
    if currentRun then return end -- Already tracking
    
    print("|cFF00FFFF[DuoDungeonTracker]|r Starting run for: " .. dungeonName)
    
    currentRun = addon:CreateRunRecord(dungeonName)
    currentRun.dungeonData = dungeonData
    -- Identify the "End Boss" (last one in the list)
    currentRun.endBoss = dungeonData.bosses[#dungeonData.bosses]
    
    -- Map boss names to boolean for easy lookup of "is this a boss?"
    currentRun.bossLookup = {}
    for _, bossName in ipairs(dungeonData.bosses) do
        currentRun.bossLookup[bossName] = true
    end
    
    -- Update UI immediately
    if addon.UpdateDungeonList then addon:UpdateDungeonList() end
    if addon.UpdateDetailView then addon:UpdateDetailView(dungeonName) end
end

-- Stop/Discard current run
function addon:StopRun(reason)
    if not currentRun then return end
    local oldDungeonName = currentRun.dungeonName
    print("|cFF00FFFF[DuoDungeonTracker]|r Run ended: " .. reason)
    
    -- PARTIAL SAVE CHECK
    currentRun.endTime = GetTime()
    local duration = currentRun.endTime - currentRun.startTime
    
    -- Calculate boss count for check
    local bossCount = 0
    for _ in pairs(currentRun.bossesKilled) do 
        bossCount = bossCount + 1 
    end
    
    -- Save if we killed anything OR spent > 2 minutes inside
    if bossCount > 0 or duration > 120 then
        -- Mark as incomplete explicitly (though it should be false already)
        currentRun.completed = false
        addon:SaveRun(currentRun)
    else
        print("|cFF888888[DuoDungeonTracker]|r Run discarded (insufficient progress).|r")
    end

    currentRun = nil
    
    -- Update UI to remove "Started" status
    if addon.UpdateDungeonList then addon:UpdateDungeonList() end
    if addon.UpdateDetailView then addon:UpdateDetailView(oldDungeonName) end
end

-- Complete the run
function addon:CompleteRun()
    if not currentRun then return end
    
    currentRun.completed = true
    currentRun.endTime = GetTime()
    
    -- Snapshot Levels
    local myLevel = UnitLevel("player")
    local p2Level = UnitLevel("party1")
    if p2Level and p2Level > 0 then
        currentRun.partyLevelSum = myLevel + p2Level
        currentRun.partyMemberCount = 2
        currentRun.avgLevel = (myLevel + p2Level) / 2
    else
        -- Fallback if something is weird
        currentRun.partyLevelSum = myLevel
        currentRun.partyMemberCount = 1
        currentRun.avgLevel = myLevel
    end
    
    addon:SaveRun(currentRun)
    print("|cFF00FF00[DuoDungeonTracker]|r Dungeon Completed! Time: " .. string.format("%.1f", currentRun.endTime - currentRun.startTime) .. "s")
    
    currentRun = nil
end

-- Helper to get current run kills for UI
function addon:GetCurrentRunKills(dungeonName)
    if currentRun and currentRun.dungeonName == dungeonName then
        return currentRun.bossesKilled
    end
    return nil
end

-- Helper to check if a dungeon is the current run
function addon:IsCurrentRun(dungeonName)
    return currentRun and currentRun.dungeonName == dungeonName
end

-- Record a boss kill
function addon:RecordBossKill(bossName)
    if not currentRun then return end
    
    if currentRun.bossLookup[bossName] then
        if not currentRun.bossesKilled[bossName] then
            currentRun.bossesKilled[bossName] = true
            print("|cFF00FF00[DuoDungeonTracker]|r Boss Down: " .. bossName)
            
            -- Update UI if open
            if addon.UpdateDetailView then
                addon:UpdateDetailView(currentRun.dungeonName)
            end
            if addon.UpdateDungeonList then
                addon:UpdateDungeonList()
            end
            
            -- Check for Completion
            if bossName == currentRun.endBoss then
                addon:CompleteRun()
            end
        else
            print("|cFFFFFF00[DuoDungeonTracker]|r Boss " .. bossName .. " already killed this run.")
        end
    end
end

-- Record a player death
function addon:RecordPlayerDeath()
    if not currentRun then return end
    currentRun.wipes = currentRun.wipes + 1
    print("|cFFFF0000[DuoDungeonTracker]|r Player Died! Total Deaths: " .. currentRun.wipes)
end

-- Consolidated Zone Check
function addon:CheckZoneStatus()
    local inInstance, instanceType = IsInInstance()
    
    if inInstance then
        local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
        local data = addon.DungeonData[tonumber(instanceID)]
        
        -- Debug Print removed

        
        if (instanceType == "party") and data then
            -- We are in a tracked dungeon
            if addon:IsPartyValid() then
                if currentRun and currentRun.isGhostRecovery then
                    currentRun.isGhostRecovery = nil
                end
                addon:StartRun(data.name, data)
            else
                if currentRun then
                    addon:StopRun("Party size changed or invalid")
                end
            end
        end
    else
        -- Left instance
        if currentRun then
            -- Check for Wipe Recovery (Ghost/Dead)
            if UnitIsDeadOrGhost("player") then
                if not currentRun.isGhostRecovery then
                    print("|cFFFFFF00[DuoDungeonTracker]|r Player is a ghost. Waiting for return to dungeon...")
                    currentRun.isGhostRecovery = true
                end
                return
            end
            
            addon:StopRun("Left instance")
        end
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        addon:InitializeDB()
        addon:CheckZoneStatus() -- Check immediately on login
        
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
        addon:CheckZoneStatus()
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not currentRun then return end
        
        local timestamp, subevent, _, sourceGUID, sourceName, _, _, destGUID, destName, _, _ = CombatLogGetCurrentEventInfo()
        
        if subevent == "UNIT_DIED" then
            -- Check for Boss Kill
            if destName and currentRun.bossLookup[destName] then
                addon:RecordBossKill(destName)
            end
            
            -- Check for Player Death (Wipe tracking)
            if UnitInParty(destName) or destName == UnitName("player") then
                if string.find(destGUID, "Player") then
                    addon:RecordPlayerDeath()
                end
            end
        end
    end
end)

function addon:InitializeDB()
    if not DuoDungeonTrackerDB then
        DuoDungeonTrackerDB = {
            history = {}, -- List of all completed runs
            best = {},    -- Summary of best runs per dungeon
        }
    end
    
    -- Ensure tables exist
    if not DuoDungeonTrackerDB.history then DuoDungeonTrackerDB.history = {} end
    if not DuoDungeonTrackerDB.best then DuoDungeonTrackerDB.best = {} end
    
    -- Initialize UI elements that depend on DB
    if addon.CreateMinimapButton then
        addon:CreateMinimapButton()
    end
    
    print("|cFF00FF00DuoDungeonTracker|r Loaded. Ready to track! Type /ddt for commands.")
end

-- Helper to create a new run record
function addon:CreateRunRecord(dungeonName)
    return {
        dungeonName = dungeonName,
        startTime = GetTime(),
        bossesKilled = {}, -- Table of [BossName] = true
        wipes = 0,
        deaths = 0, 
        partyLevelSum = 0, 
        partyMemberCount = 0,
        completed = false,
        date = date("%Y-%m-%d %H:%M:%S")
    }
end

-- Function to save a run
function addon:SaveRun(runData)
    -- Clean up temporary data before saving
    runData.dungeonData = nil
    runData.bossLookup = nil
    runData.endBoss = nil
    
    -- Calculate boss count for storage
    local bossCount = 0
    for _ in pairs(runData.bossesKilled) do 
        bossCount = bossCount + 1 
    end
    runData.bossCount = bossCount
    
    table.insert(DuoDungeonTrackerDB.history, runData)
    
    -- Update Best Time / Best Run Logic
    local duration = runData.endTime - runData.startTime
    local best = DuoDungeonTrackerDB.best[runData.dungeonName]
    local isNewBest = false
    
    if not best then
        -- Case 1: No existing best -> Save as best
        isNewBest = true
    else
        -- We have an existing best run
        local bestIsCompleted = best.completed
        local newIsCompleted = runData.completed
        
        if newIsCompleted then
            if not bestIsCompleted then
                -- Case 2a: Completed overwrites Partial
                isNewBest = true
            else
                -- Case 2b: Completed vs Completed -> Faster wins
                if duration < best.time then
                    isNewBest = true
                end
            end
        else
            -- New run is Partial
            if not bestIsCompleted then
                -- Case 3: Partial vs Partial -> More bosses wins
                -- Ensure old best has a bossCount (legacy support)
                local oldBossCount = best.bossCount or 0
                if bossCount > oldBossCount then
                    isNewBest = true
                end
            end
            -- If best is Completed, we do nothing (Priority A)
        end
    end
    
    if isNewBest then
        DuoDungeonTrackerDB.best[runData.dungeonName] = {
            time = duration,
            date = runData.date,
            wipes = runData.wipes,
            avgLevel = runData.avgLevel,
            bossesKilled = runData.bossesKilled,
            completed = runData.completed,
            bossCount = bossCount
        }
        if runData.completed then
            print("|cFF00FF00New Record for " .. runData.dungeonName .. "!|r")
        else
            print("|cFFFFFF00New Best Attempt for " .. runData.dungeonName .. "! (" .. bossCount .. " bosses)|r")
        end
    else
        if not runData.completed then
             print("|cFF888888Partial run saved, but did not beat best attempt.|r")
        end
    end
    
    -- Update UI
    if addon.UpdateDungeonList then addon:UpdateDungeonList() end
    if addon.UpdateDetailView then addon:UpdateDetailView(runData.dungeonName) end
end

-- --- Slash Commands ---
SLASH_DUODUNGEONTRACKER1 = "/ddt"
SLASH_DUODUNGEONTRACKER2 = "/duo"

SlashCmdList["DUODUNGEONTRACKER"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    
    local cmd = args[1]
    
    if cmd == "toggle" then
        addon:ToggleUI()
        
    elseif cmd == "clear" then
        DuoDungeonTrackerDB = { history = {}, best = {} }
        print("|cFF00FF00[DuoDungeonTracker]|r Database Cleared.")
        
    elseif cmd == "print" then
        if currentRun then
            local timeElapsed = GetTime() - currentRun.startTime
            local bossCount = 0
            for _ in pairs(currentRun.bossesKilled) do bossCount = bossCount + 1 end
            print(string.format("Current Run: %s | Time: %.1fs | Bosses: %d | Wipes: %d", 
                currentRun.dungeonName, timeElapsed, bossCount, currentRun.wipes))
        else
            print("No active run.")
        end
        
    elseif cmd == "debug" then
        local sub = args[2]
        
        if sub == "enter" then
            -- Usage: /ddt debug enter [Dungeon Name]
            local dungeonName = ""
            for i = 3, #args do
                dungeonName = dungeonName .. args[i] .. " "
            end
            dungeonName = strtrim(dungeonName)
            
            local data = addon:GetDungeonDataByName(dungeonName)
            if data then
                -- Force start run
                if currentRun then addon:StopRun("Debug forced new run") end
                addon:StartRun(dungeonName, data)
                print("Debug: Entered " .. dungeonName)
            else
                print("Debug: Dungeon not found '" .. dungeonName .. "'")
            end
            
        elseif sub == "kill" then
            -- Usage: /ddt debug kill [Boss Name]
            local bossName = ""
            for i = 3, #args do
                bossName = bossName .. args[i] .. " "
            end
            bossName = strtrim(bossName)
            
            if currentRun then
                addon:RecordBossKill(bossName)
            else
                print("Debug: No active run.")
            end
            
        elseif sub == "wipe" then
            if currentRun then
                addon:RecordPlayerDeath()
            else
                print("Debug: No active run.")
            end
            
        elseif sub == "finish" then
            if currentRun then
                -- Kill the end boss
                addon:RecordBossKill(currentRun.endBoss)
            else
                print("Debug: No active run.")
            end
            
        elseif sub == "solo" then
            addon.debugSoloMode = not addon.debugSoloMode
            if addon.debugSoloMode then
                print("|cFF00FF00[DuoDungeonTracker]|r Solo Debug Mode: ON")
                addon:CheckZoneStatus() -- Re-check immediately
            else
                print("|cFFFF0000[DuoDungeonTracker]|r Solo Debug Mode: OFF")
                addon:CheckZoneStatus() -- Re-check immediately
            end
        
        else
            print("Debug commands: enter [name], kill [name], wipe, finish, solo")
        end
        
    else
        print("DuoDungeonTracker Commands:")
        print("  /ddt toggle - Open UI")
        print("  /ddt print - Show current run stats")
        print("  /ddt clear - Reset DB")
        print("  /ddt debug enter [Name] - Simulate entry")
        print("  /ddt debug kill [Name] - Simulate boss kill")
        print("  /ddt debug wipe - Simulate death")
        print("  /ddt debug finish - Simulate completion")
        print("  /ddt debug solo - Toggle solo testing mode")
    end
end
