local addonName, addon = ...

-- UI Constants
local WINDOW_WIDTH = 600
local WINDOW_HEIGHT = 450
local LIST_WIDTH = 200

-- Main UI Frame
local uiFrame = nil
local detailFrame = nil
local listContentFrame = nil

-- --- Minimap Button ---
function addon:CreateMinimapButton()
    local mmBtn = CreateFrame("Button", "DuoDungeonTrackerMinimapButton", Minimap)
    mmBtn:SetSize(32, 32)
    mmBtn:SetFrameStrata("MEDIUM")
    mmBtn:SetFrameLevel(8)
    
    -- Icon
    local icon = mmBtn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\Inv_Misc_Map02")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    
    -- Border
    local border = mmBtn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    
    -- Restore Position Logic (User Provided)
    if DuoDungeonTrackerDB.minimapPos then
        local pos = DuoDungeonTrackerDB.minimapPos
        mmBtn:ClearAllPoints()
        -- Restore relative to UIParent to allow free movement anywhere
        mmBtn:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Default position (near minimap)
        mmBtn:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    end
    
    -- Dragging Logic
    mmBtn:SetMovable(true)
    mmBtn:EnableMouse(true)
    mmBtn:RegisterForDrag("LeftButton")
    
    mmBtn:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    mmBtn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        
        -- Save to DB
        DuoDungeonTrackerDB.minimapPos = {
            point = point,
            relativePoint = relativePoint,
            x = x,
            y = y
        }
    end)
    
    -- Click
    mmBtn:SetScript("OnClick", function()
        addon:ToggleUI()
    end)
    
    -- Tooltip
    mmBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Duo Dungeon Tracker")
        GameTooltip:AddLine("Click to toggle main window", 1, 1, 1)
        GameTooltip:Show()
    end)
    mmBtn:SetScript("OnLeave", GameTooltip_Hide)
end

-- --- Main Window ---

local function CreateDetailView(parent)
    local f = CreateFrame("Frame", nil, parent)
    -- Increased margin from LIST_WIDTH + 10 to LIST_WIDTH + 30
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", LIST_WIDTH + 30, -30)
    f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    
    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    f.title:SetPoint("TOPLEFT", 0, 0)
    f.title:SetText("Select a Dungeon")
    
    -- Stats Block
    f.stats = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.stats:SetPoint("TOPLEFT", 0, -30)
    f.stats:SetJustifyH("LEFT")
    f.stats:SetText("")
    
    -- Boss List
    f.bossListTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.bossListTitle:SetPoint("TOPLEFT", 0, -120)
    f.bossListTitle:SetText("Bosses:")

    -- Reset Button
    f.resetBtn = CreateFrame("Button", "ResetDungeonButton", f, "UIPanelButtonTemplate")
    f.resetBtn:SetSize(100, 22)
    f.resetBtn:SetPoint("TOPRIGHT", -10, -10)
    f.resetBtn:SetText("Reset Data")
    f.resetBtn:SetScript("OnClick", function(self)
        if self:GetText() == "Reset Data" then
            self:SetText("Confirm?")
        elseif self:GetText() == "Confirm?" then
            if detailFrame.selectedDungeon then
                addon:ResetDungeonData(detailFrame.selectedDungeon)
            end
            self:SetText("Reset Data")
        end
    end)
    f.resetBtn:SetScript("OnHide", function(self)
        self:SetText("Reset Data")
    end)
    f.resetBtn:Hide() -- Initial state hidden
    
    -- Boss List Scroll Frame
    f.bossScrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    f.bossScrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -140)
    f.bossScrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 10) -- Leave room for scrollbar
    
    f.bossContentFrame = CreateFrame("Frame", nil, f.bossScrollFrame)
    f.bossContentFrame:SetSize(WINDOW_WIDTH - LIST_WIDTH - 60, 100) -- Width adjusted, Height dynamic
    f.bossScrollFrame:SetScrollChild(f.bossContentFrame)
    
    f.bossList = f.bossContentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.bossList:SetPoint("TOPLEFT", 10, 0)
    f.bossList:SetJustifyH("LEFT")
    f.bossList:SetText("")
    
    return f
end

-- Made global to addon for real-time updates
function addon:UpdateDetailView(dungeonName)
    if not detailFrame or not dungeonName then return end
    
    -- Store current selection to refresh it if needed
    detailFrame.selectedDungeon = dungeonName
    
    local data = addon:GetDungeonDataByName(dungeonName)
    if not data then return end
    
    detailFrame.title:SetText(dungeonName)
    
    -- Get Best Run info
    local best = DuoDungeonTrackerDB.best[dungeonName]
    local history = DuoDungeonTrackerDB.history
    
    -- Check if we have any history for this dungeon to determine "Attempted" status if not completed
    local attempted = false
    for _, run in ipairs(history) do
        if run.dungeonName == dungeonName then
            attempted = true
            break
        end
    end
    
    local statusText = "|cFF808080Not Started|r"
    local timeText = "N/A"
    local dateText = "N/A"
    local wipesText = "0"
    local levelText = "N/A"
    
    if best then
        -- Check for Full Clear
        local allDead = true
        if data.bosses and best.bossesKilled then
            for _, bossName in ipairs(data.bosses) do
                if not best.bossesKilled[bossName] then
                    allDead = false
                    break
                end
            end
        elseif data.bosses and not best.bossesKilled then
             -- Old data format or no kills recorded
             allDead = false
        end

        if allDead then
            statusText = "|cFF00FF00Cleared!|r"
        else
            statusText = "|cFFFFFF00Partial clear!|r"
        end
        
        timeText = string.format("%.1f min", best.time / 60)
        dateText = best.date
        wipesText = best.wipes or 0
        levelText = best.avgLevel and string.format("%.1f", best.avgLevel) or "N/A"
    elseif attempted then
        statusText = "|cFFFFFF00In Progress / Attempted|r"
    end
    
    -- Check current run for live updates (Partial Clear)
    local currentRunKills = {}
    if DuoDungeonTracker and DuoDungeonTracker.GetCurrentRunKills then
         currentRunKills = DuoDungeonTracker:GetCurrentRunKills(dungeonName) or {}
    end
    
    if currentRunKills and next(currentRunKills) then
        if statusText ~= "|cFF00FF00Cleared!|r" then
             statusText = "|cFFFFFF00Partial clear|r"
        end
    elseif DuoDungeonTracker and DuoDungeonTracker.IsCurrentRun and DuoDungeonTracker:IsCurrentRun(dungeonName) then
        -- Active run, 0 kills
        if statusText ~= "|cFF00FF00Cleared!|r" and statusText ~= "|cFFFFFF00Partial clear!|r" then
            statusText = "|cFF00CCFFStarted|r"
        end
    end
    
    detailFrame.stats:SetText(
        "Status: " .. statusText .. "\n" ..
        "Best Time: " .. timeText .. "\n" ..
        "Avg Level: " .. levelText .. "\n" ..
        "Wipes (Best Run): " .. wipesText .. "\n" ..
        "Date: " .. dateText
    )
    
    -- Boss List
    local bossText = "|cFFFFD100Dungeon Bosses:|r\n"
    
    -- Check current run for live updates
    local currentRunKills = {}
    if DuoDungeonTracker and DuoDungeonTracker.GetCurrentRunKills then
         currentRunKills = DuoDungeonTracker:GetCurrentRunKills(dungeonName) or {}
    end

    -- Helper to format boss line
    local function GetBossLine(bName)
        local color = "|cFF808080" -- Grey
        local check = "[ ]"
        
        -- Check if killed in the BEST run (if completed) OR current run
        local isKilledInBest = best and best.bossesKilled and best.bossesKilled[bName]
        local isKilledInCurrent = currentRunKills and currentRunKills[bName]
        
        if isKilledInBest or isKilledInCurrent then
             color = "|cFF00FF00" -- Green
             check = "[x]"
        end
        return color .. check .. " " .. bName .. "|r\n"
    end

    -- Mandatory Bosses
    if data.bosses then
        for _, bossName in ipairs(data.bosses) do
            bossText = bossText .. GetBossLine(bossName)
        end
    end
    
    -- Rare Spawns
    if data.rares and #data.rares > 0 then
        bossText = bossText .. "\n|cFFFFD100Rare Spawns:|r\n"
        for _, bossName in ipairs(data.rares) do
            bossText = bossText .. GetBossLine(bossName)
        end
    end
    
    detailFrame.bossList:SetText(bossText)
    
    -- Resize content frame to fit text
    local height = detailFrame.bossList:GetStringHeight()
    detailFrame.bossContentFrame:SetHeight(height + 20)

    -- Update Reset Button Visibility
    if detailFrame.resetBtn then
        -- Safety Check: If no dungeon selected, strictly hide
        if not dungeonName then
            detailFrame.resetBtn:Hide()
        -- Conditional Visibility: Only show if we have data (Best or Attempted)
        elseif best or attempted then
            detailFrame.resetBtn:Show()
            detailFrame.resetBtn:Enable()
            detailFrame.resetBtn:SetText("Reset Data")
        else
            detailFrame.resetBtn:Hide()
        end
    end
end

function addon:UpdateDungeonList()
    if not listContentFrame then return end
    
    -- Clear existing children (Simple way: Hide them and create new ones, or reuse. 
    -- For simplicity in this small addon, we'll just release/hide all and recreate or update text if we kept references.
    -- Let's just release all children to be safe and simple.)
    local kids = {listContentFrame:GetChildren()}
    for _, child in ipairs(kids) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Sort dungeons by level
    local sortedDungeons = {}
    for id, data in pairs(addon.DungeonData) do
        table.insert(sortedDungeons, {name = data.name, level = data.level or 0})
    end
    table.sort(sortedDungeons, function(a, b) return a.level < b.level end)
    
    local yOffset = 0
    for _, entry in ipairs(sortedDungeons) do
        local name = entry.name
        local btn = CreateFrame("Button", nil, listContentFrame)
        btn:SetSize(LIST_WIDTH - 20, 20)
        btn:SetPoint("TOPLEFT", 0, yOffset)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", 5, 0)
        
        -- Determine Color
        local best = DuoDungeonTrackerDB.best[name]
        local isFullClear = false
        local hasKills = false
        
        local data = addon:GetDungeonDataByName(name)
        
        -- Scan history for Full Clear and Kills
        if DuoDungeonTrackerDB.history then
            for _, run in ipairs(DuoDungeonTrackerDB.history) do
                if run.dungeonName == name then
                    -- Check for any kills
                    if run.bossesKilled and next(run.bossesKilled) then
                        hasKills = true
                    end
                    
                    -- Check for Full Clear
                    if run.completed and data then
                        local allDead = true
                        for _, bossName in ipairs(data.bosses) do
                            if not run.bossesKilled or not run.bossesKilled[bossName] then
                                allDead = false
                                break
                            end
                        end
                        if allDead then
                            isFullClear = true
                        end
                    end
                end
            end
        end
        
        -- Check current run for kills (Real-time update)
        if not isFullClear and not hasKills then
            local currentKills = addon.GetCurrentRunKills and addon:GetCurrentRunKills(name)
            if currentKills and next(currentKills) then
                hasKills = true
            end
        end
        
        if isFullClear then
            text:SetText("|cFF00FF00" .. name .. "|r") -- Green (Full Clear)
        elseif best or hasKills then
            text:SetText("|cFFFFFF00" .. name .. "|r") -- Yellow (Partial/Attempted)
        elseif DuoDungeonTracker and DuoDungeonTracker.IsCurrentRun and DuoDungeonTracker:IsCurrentRun(name) then
            text:SetText("|cFF00CCFF" .. name .. "|r") -- Light Blue (Started)
        else
            text:SetText("|cFF808080" .. name .. "|r") -- Grey (None)
        end
        
        btn:SetScript("OnClick", function()
            addon:UpdateDetailView(name)
        end)
        
        yOffset = yOffset - 20
    end
    
    listContentFrame:SetHeight(-yOffset)

    -- Auto-hide ScrollBar if content fits
    local scrollFrame = listContentFrame:GetParent()
    if scrollFrame and scrollFrame.GetName then
        local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
        if scrollBar then
            if listContentFrame:GetHeight() <= scrollFrame:GetHeight() then
                scrollBar:Hide()
                scrollBar:SetValue(0) -- Reset scroll
            else
                scrollBar:Show()
            end
        end
    end
end

local function CreateDungeonList(parent)
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "DuoDungeonTrackerListScrollFrame", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", LIST_WIDTH, 10)
    
    -- Content Frame
    listContentFrame = CreateFrame("Frame", nil, scrollFrame)
    listContentFrame:SetSize(LIST_WIDTH - 20, 800) -- Height will be adjusted dynamically
    scrollFrame:SetScrollChild(listContentFrame)
    
    addon:UpdateDungeonList()
end

local function CreateMainWindow()
    local f = CreateFrame("Frame", "DuoDungeonTrackerMainFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide() -- Start hidden
    
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("CENTER", f.TitleBg, "CENTER", 0, 0)
    
    local version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0"
    f.title:SetText("|cffC79C6EJacob|r|cffFFFFFF&|r|cffF58CBALau|r|cffFFFFFF's Duo Dungeon Tracker|r |cff808080(v" .. version .. ")|r")
    
    -- Vertical Separator
    f.separator = f:CreateTexture(nil, "ARTWORK")
    f.separator:SetColorTexture(1, 1, 1, 0.2)
    f.separator:SetWidth(1)
    f.separator:SetPoint("TOPLEFT", f, "TOPLEFT", LIST_WIDTH + 5, -30)
    f.separator:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LIST_WIDTH + 5, 10)
    
    CreateDungeonList(f)
    detailFrame = CreateDetailView(f)
    
    -- Enable ESC to close
    tinsert(UISpecialFrames, f:GetName())
    
    return f
end

function addon:ToggleUI()
    if not uiFrame then
        uiFrame = CreateMainWindow()
    end
    
    if uiFrame:IsShown() then
        uiFrame:Hide()
    else
        uiFrame:Show()
    end
end

-- Initialize UI
-- Moved to Core.lua InitializeDB to ensure correct order
-- local frame = CreateFrame("Frame")
-- frame:RegisterEvent("PLAYER_LOGIN")
-- frame:SetScript("OnEvent", function()
--     CreateMinimapButton()
-- end)
