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

-- Helper: Get current dungeon data
function addon:GetCurrentDungeonInfo()
    local zoneName = GetRealZoneText()
    local data = addon.DungeonData[zoneName]
    if data then
        return zoneName, data
    end
    return nil, nil
end

-- Helper: Check if party is valid (Exactly 2 players)
function addon:IsPartyValid()
    if addon.debugSoloMode then return true end
    -- GetNumGroupMembers returns total members (including player) in a party/raid
    -- We want exactly 2.
    return IsInGroup() and GetNumGroupMembers() == 2
end

-- ... (StartRun, StopRun, CompleteRun, GetCurrentRunKills, RecordBossKill, RecordPlayerDeath, CheckZoneStatus, OnEvent, InitializeDB, CreateRunRecord, SaveRun omitted for brevity as they don't change, but we need to target the SlashCmdList area for the new command)

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
            -- We need to reconstruct the name if it has spaces
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
        end
    else
        -- Left instance
        if currentRun then
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
        deaths = 0, -- Keeping both for now, but logic uses 'wipes' as death count based on request
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
    
    table.insert(DuoDungeonTrackerDB.history, runData)
    
    -- Update Best Time
    local duration = runData.endTime - runData.startTime
    local best = DuoDungeonTrackerDB.best[runData.dungeonName]
    
    if runData.completed then
        if not best or duration < best.time then
            DuoDungeonTrackerDB.best[runData.dungeonName] = {
                time = duration,
                date = runData.date,
                wipes = runData.wipes,
                avgLevel = runData.avgLevel,
                bossesKilled = runData.bossesKilled -- Store specific kills
            }
            print("|cFF00FF00New Record for " .. runData.dungeonName .. "!|r")
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
            -- We need to reconstruct the name if it has spaces
            local dungeonName = ""
            for i = 3, #args do
                dungeonName = dungeonName .. args[i] .. " "
            end
            dungeonName = strtrim(dungeonName)
            
            local data = addon.DungeonData[dungeonName]
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
