script_name("Season-Setter")
script_author("Andrei")
script_version("final")
script_url("---")

local imgui = require 'imgui'
local modsWindow = imgui.ImBool(true)
local confirmWindow = imgui.ImBool(false)
local currentSeason = nil
local selectedSeason = nil
local selectionTimer = nil
local timerStart = nil

local screenHeight = 1080
local windowHeight = 500
local posY = (screenHeight / 2) - (windowHeight / 2)

local summerImages = {
    "moonloader/resources/seasons/summer/summer_preview1.jpg",
    "moonloader/resources/seasons/summer/summer_preview2.jpg",
    "moonloader/resources/seasons/summer/summer_preview3.jpg",
    "moonloader/resources/seasons/summer/summer_preview4.jpg",
    "moonloader/resources/seasons/summer/summer_preview5.jpg"
}

local winterImages = {
    "moonloader/resources/seasons/winter/winter_preview1.jpg",
    "moonloader/resources/seasons/winter/winter_preview2.jpg",
    "moonloader/resources/seasons/winter/winter_preview3.jpg",
    "moonloader/resources/seasons/winter/winter_preview4.jpg",
    "moonloader/resources/seasons/winter/winter_preview5.jpg"
}

local summerTextures = {}
local winterTextures = {}

for i, path in ipairs(summerImages) do
    summerTextures[i] = imgui.CreateTextureFromFile(path)
end
for i, path in ipairs(winterImages) do
    winterTextures[i] = imgui.CreateTextureFromFile(path)
end

local selectedSummerImage = summerTextures[1]
local selectedWinterImage = winterTextures[1]

-- Funcția pentru timer
function drawTimer()
    if timerStart then
        local elapsed = os.clock() - timerStart
        local remaining = math.max(0, 10 - math.floor(elapsed))
        local minutes = string.format("%02d", math.floor(remaining / 60))
        local seconds = string.format("%02d", remaining % 60)
        local timeText = minutes .. ":" .. seconds

        local color = imgui.ImVec4(1, 1, 1, 1) -- Alb
        if remaining <= 7 and remaining > 5 then
            color = imgui.ImVec4(1, 1, 0, 1) -- Galben
        elseif remaining <= 5 and remaining > 3 then
            color = imgui.ImVec4(1, 0.5, 0, 1) -- Portocaliu
        elseif remaining <= 3 then
            color = imgui.ImVec4(1, 0, 0, 1) -- Roșu
        end

        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)
        imgui.TextColored(color, "Time left: " .. timeText)
    end
end

function startSelectionTimer()
    if selectionTimer then return end
    timerStart = os.clock() -- Înregistrează timpul de start
    selectionTimer = lua_thread.create(function()
        wait(10000)
        if modsWindow.v then
            modsWindow.v = false
            selectionTimer = nil
        end
    end)
end

function main()
    while true do
        wait(0)
        imgui.Process = modsWindow.v or confirmWindow.v
    end
end

function imgui.OnDrawFrame()
    if modsWindow.v then
        startSelectionTimer()
        imgui.SetNextWindowPos(imgui.ImVec2(0, posY), imgui.Cond.Always)
        imgui.SetNextWindowSize(imgui.ImVec2(320, 467))
        imgui.Begin('SEASON SETTER', modsWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), "You can't change it IN GAME, you will need to relog!")

        drawTimer()
        imgui.Spacing()

        imgui.Image(selectedSummerImage, imgui.ImVec2(280, 140))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1, 0.5, 0, 1))
        if imgui.Button("SUMMER", imgui.ImVec2(140, 35)) then
            selectedSeason = "SUMMER"
            confirmWindow.v = true
            modsWindow.v = false
            selectionTimer = nil
        end
        imgui.PopStyleColor()

        imgui.Spacing()
        imgui.Image(selectedWinterImage, imgui.ImVec2(280, 140))
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 0.5, 1, 1))
        if imgui.Button("WINTER", imgui.ImVec2(140, 35)) then
            selectedSeason = "WINTER"
            confirmWindow.v = true
            modsWindow.v = false
            selectionTimer = nil
        end
        imgui.PopStyleColor()

        imgui.End()
    end

    if confirmWindow.v and selectedSeason then
        imgui.SetNextWindowPos(imgui.ImVec2(320, 300), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(300, 120))
        imgui.Begin("Confirmation", confirmWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        imgui.Text("Are you sure you want to change to " .. selectedSeason .. "?")

        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0, 1, 0, 1))
        if imgui.Button("Yes", imgui.ImVec2(90, 35)) then
            setSeason(selectedSeason)
            confirmWindow.v = false
        end
        imgui.PopStyleColor()

        imgui.SameLine()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(1, 0, 0, 1))
        if imgui.Button("No", imgui.ImVec2(90, 35)) then
            confirmWindow.v = false
            modsWindow.v = true
            startSelectionTimer()
        end
        imgui.PopStyleColor()

        imgui.End()
    end
end

function setSeason(season)
    currentSeason = season
    local url = (season == 'SUMMER') and
        'https://raw.githubusercontent.com/lehadus79x/sampwade/main/summer_modloader.ini' or
        'https://raw.githubusercontent.com/lehadus79x/sampwade/main/winter_modloader.ini'

    lua_thread.create(function()
        if doesFileExist('modloader/modloader.ini') then
            os.remove('modloader/modloader.ini')
        end

        local success = downloadUrlToFile(url, 'modloader/modloader.ini')

        if success then
            sampAddChatMessage('{ffffff}The change of season has been {00ff00}set', -1)
        else
            sampAddChatMessage('{FF0000}Error: Could not download config!', -1)
        end
    end)
end
