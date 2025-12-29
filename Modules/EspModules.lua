local EspModule = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPObjects = {}
local Settings = {
    Enabled = false,
    BoxType = "Full",
    BoxColor = Color3.fromRGB(255, 255, 255)
}

local function CreateDrawing(Type)
    local drawing = Drawing.new(Type)
    return drawing
end

local function CreateESP(player)
    local esp = {
        Player = player,
        Drawings = {}
    }
    
    if Settings.BoxType == "Full" then
        for i = 1, 4 do
            local line = CreateDrawing("Line")
            line.Thickness = 2
            line.Color = Settings.BoxColor
            line.Visible = false
            table.insert(esp.Drawings, line)
        end
    else
        for i = 1, 16 do
            local line = CreateDrawing("Line")
            line.Thickness = 2
            line.Color = Settings.BoxColor
            line.Visible = false
            table.insert(esp.Drawings, line)
        end
    end
    
    return esp
end

local function RemoveESP(esp)
    for _, drawing in pairs(esp.Drawings) do
        drawing:Remove()
    end
end

local function UpdateESP(esp)
    local player = esp.Player
    local character = player.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end
    
    local hrp = character.HumanoidRootPart
    local head = character:FindFirstChild("Head")
    
    if not head then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end
    
    local headPos = head.Position + Vector3.new(0, 0.5, 0)
    local legPos = hrp.Position - Vector3.new(0, 3, 0)
    
    local headScreen, headOnScreen = Camera:WorldToViewportPoint(headPos)
    local legScreen, legOnScreen = Camera:WorldToViewportPoint(legPos)
    
    if not headOnScreen and not legOnScreen then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        return
    end
    
    local height = math.abs(headScreen.Y - legScreen.Y)
    local width = height / 2
    
    local topLeft = Vector2.new(headScreen.X - width / 2, headScreen.Y)
    local topRight = Vector2.new(headScreen.X + width / 2, headScreen.Y)
    local bottomLeft = Vector2.new(legScreen.X - width / 2, legScreen.Y)
    local bottomRight = Vector2.new(legScreen.X + width / 2, legScreen.Y)
    
    if Settings.BoxType == "Full" then
        esp.Drawings[1].From = topLeft
        esp.Drawings[1].To = topRight
        esp.Drawings[1].Visible = true
        
        esp.Drawings[2].From = topRight
        esp.Drawings[2].To = bottomRight
        esp.Drawings[2].Visible = true
        
        esp.Drawings[3].From = bottomRight
        esp.Drawings[3].To = bottomLeft
        esp.Drawings[3].Visible = true
        
        esp.Drawings[4].From = bottomLeft
        esp.Drawings[4].To = topLeft
        esp.Drawings[4].Visible = true
    else
        local cornerSize = math.min(width, height) * 0.25
        
        esp.Drawings[1].From = topLeft
        esp.Drawings[1].To = topLeft + Vector2.new(cornerSize, 0)
        esp.Drawings[1].Visible = true
        
        esp.Drawings[2].From = topLeft
        esp.Drawings[2].To = topLeft + Vector2.new(0, cornerSize)
        esp.Drawings[2].Visible = true
        
        esp.Drawings[3].From = topRight
        esp.Drawings[3].To = topRight + Vector2.new(-cornerSize, 0)
        esp.Drawings[3].Visible = true
        
        esp.Drawings[4].From = topRight
        esp.Drawings[4].To = topRight + Vector2.new(0, cornerSize)
        esp.Drawings[4].Visible = true
        
        esp.Drawings[5].From = bottomLeft
        esp.Drawings[5].To = bottomLeft + Vector2.new(cornerSize, 0)
        esp.Drawings[5].Visible = true
        
        esp.Drawings[6].From = bottomLeft
        esp.Drawings[6].To = bottomLeft + Vector2.new(0, -cornerSize)
        esp.Drawings[6].Visible = true
        
        esp.Drawings[7].From = bottomRight
        esp.Drawings[7].To = bottomRight + Vector2.new(-cornerSize, 0)
        esp.Drawings[7].Visible = true
        
        esp.Drawings[8].From = bottomRight
        esp.Drawings[8].To = bottomRight + Vector2.new(0, -cornerSize)
        esp.Drawings[8].Visible = true
        
        for i = 9, 16 do
            esp.Drawings[i].Visible = false
        end
    end
end

function EspModule:Enable()
    Settings.Enabled = true
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESPObjects[player] = CreateESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        if Settings.Enabled and player ~= LocalPlayer then
            ESPObjects[player] = CreateESP(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        if ESPObjects[player] then
            RemoveESP(ESPObjects[player])
            ESPObjects[player] = nil
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if Settings.Enabled then
            for player, esp in pairs(ESPObjects) do
                UpdateESP(esp)
            end
        end
    end)
end

function EspModule:Disable()
    Settings.Enabled = false
    
    for player, esp in pairs(ESPObjects) do
        RemoveESP(esp)
    end
    
    ESPObjects = {}
end

function EspModule:SetBoxType(boxType)
    Settings.BoxType = boxType
    
    for player, esp in pairs(ESPObjects) do
        RemoveESP(esp)
    end
    
    ESPObjects = {}
    
    if Settings.Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                ESPObjects[player] = CreateESP(player)
            end
        end
    end
end

function EspModule:SetBoxColor(color)
    Settings.BoxColor = color
    
    for _, esp in pairs(ESPObjects) do
        for _, drawing in pairs(esp.Drawings) do
            drawing.Color = color
        end
    end
end

return EspModule
