local EspModule = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPObjects = {}
local RenderConnection = nil
local Settings = {
    Enabled = false,
    BoxType = "Full",
    BoxColor = Color3.fromRGB(255, 255, 255),
    Tracers = false,
    TracersPosition = "Center",
    TracersColor = Color3.fromRGB(255, 255, 255)
}

local function CreateDrawing(Type)
    local drawing = Drawing.new(Type)
    return drawing
end

local function CreateESP(player)
    local esp = {
        Player = player,
        Drawings = {},
        Tracer = nil
    }
    
    for i = 1, 4 do
        local line = CreateDrawing("Line")
        line.Thickness = 2
        line.Color = Settings.BoxColor
        line.Visible = false
        table.insert(esp.Drawings, line)
    end
    
    for i = 1, 8 do
        local line = CreateDrawing("Line")
        line.Thickness = 2
        line.Color = Settings.BoxColor
        line.Visible = false
        table.insert(esp.Drawings, line)
    end
    
    local tracer = CreateDrawing("Line")
    tracer.Thickness = 2
    tracer.Color = Settings.TracersColor
    tracer.Visible = false
    esp.Tracer = tracer
    
    return esp
end

local function RemoveESP(esp)
    for _, drawing in pairs(esp.Drawings) do
        drawing:Remove()
    end
    if esp.Tracer then
        esp.Tracer:Remove()
    end
end

local function UpdateESP(esp)
    local player = esp.Player
    local character = player.Character
    
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        if esp.Tracer then
            esp.Tracer.Visible = false
        end
        return
    end
    
    local hrp = character.HumanoidRootPart
    local head = character:FindFirstChild("Head")
    
    if not head then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        if esp.Tracer then
            esp.Tracer.Visible = false
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
        if esp.Tracer then
            esp.Tracer.Visible = false
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
        for i = 5, 12 do
            esp.Drawings[i].Visible = false
        end
        
        esp.Drawings[1].From = topLeft
        esp.Drawings[1].To = topRight
        esp.Drawings[1].Visible = true
        esp.Drawings[1].Color = Settings.BoxColor
        
        esp.Drawings[2].From = topRight
        esp.Drawings[2].To = bottomRight
        esp.Drawings[2].Visible = true
        esp.Drawings[2].Color = Settings.BoxColor
        
        esp.Drawings[3].From = bottomRight
        esp.Drawings[3].To = bottomLeft
        esp.Drawings[3].Visible = true
        esp.Drawings[3].Color = Settings.BoxColor
        
        esp.Drawings[4].From = bottomLeft
        esp.Drawings[4].To = topLeft
        esp.Drawings[4].Visible = true
        esp.Drawings[4].Color = Settings.BoxColor
    else
        for i = 1, 4 do
            esp.Drawings[i].Visible = false
        end
        
        local cornerLength = math.min(width * 0.3, height * 0.15)
        
        esp.Drawings[5].From = topLeft
        esp.Drawings[5].To = Vector2.new(topLeft.X + cornerLength, topLeft.Y)
        esp.Drawings[5].Visible = true
        esp.Drawings[5].Color = Settings.BoxColor
        
        esp.Drawings[6].From = topLeft
        esp.Drawings[6].To = Vector2.new(topLeft.X, topLeft.Y + cornerLength)
        esp.Drawings[6].Visible = true
        esp.Drawings[6].Color = Settings.BoxColor
        
        esp.Drawings[7].From = topRight
        esp.Drawings[7].To = Vector2.new(topRight.X - cornerLength, topRight.Y)
        esp.Drawings[7].Visible = true
        esp.Drawings[7].Color = Settings.BoxColor
        
        esp.Drawings[8].From = topRight
        esp.Drawings[8].To = Vector2.new(topRight.X, topRight.Y + cornerLength)
        esp.Drawings[8].Visible = true
        esp.Drawings[8].Color = Settings.BoxColor
        
        esp.Drawings[9].From = bottomLeft
        esp.Drawings[9].To = Vector2.new(bottomLeft.X + cornerLength, bottomLeft.Y)
        esp.Drawings[9].Visible = true
        esp.Drawings[9].Color = Settings.BoxColor
        
        esp.Drawings[10].From = bottomLeft
        esp.Drawings[10].To = Vector2.new(bottomLeft.X, bottomLeft.Y - cornerLength)
        esp.Drawings[10].Visible = true
        esp.Drawings[10].Color = Settings.BoxColor
        
        esp.Drawings[11].From = bottomRight
        esp.Drawings[11].To = Vector2.new(bottomRight.X - cornerLength, bottomRight.Y)
        esp.Drawings[11].Visible = true
        esp.Drawings[11].Color = Settings.BoxColor
        
        esp.Drawings[12].From = bottomRight
        esp.Drawings[12].To = Vector2.new(bottomRight.X, bottomRight.Y - cornerLength)
        esp.Drawings[12].Visible = true
        esp.Drawings[12].Color = Settings.BoxColor
    end
    
    if Settings.Tracers and esp.Tracer and headOnScreen then
        local tracerStart
        if Settings.TracersPosition == "Center" then
            tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        elseif Settings.TracersPosition == "Bottom" then
            tracerStart = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        else
            tracerStart = Vector2.new(Camera.ViewportSize.X / 2, 0)
        end
        
        esp.Tracer.From = tracerStart
        esp.Tracer.To = Vector2.new(headScreen.X, headScreen.Y)
        esp.Tracer.Color = Settings.TracersColor
        esp.Tracer.Visible = true
    else
        if esp.Tracer then
            esp.Tracer.Visible = false
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
    
    if RenderConnection then
        RenderConnection:Disconnect()
    end
    
    RenderConnection = RunService.RenderStepped:Connect(function()
        if Settings.Enabled then
            for player, esp in pairs(ESPObjects) do
                UpdateESP(esp)
            end
        end
    end)
end

function EspModule:Disable()
    Settings.Enabled = false
    
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    
    for player, esp in pairs(ESPObjects) do
        RemoveESP(esp)
    end
    
    ESPObjects = {}
end

function EspModule:SetBoxType(boxType)
    Settings.BoxType = boxType
end

function EspModule:SetBoxColor(color)
    Settings.BoxColor = color
    
    for _, esp in pairs(ESPObjects) do
        for _, drawing in pairs(esp.Drawings) do
            drawing.Color = color
        end
    end
end

function EspModule:SetTracers(enabled)
    Settings.Tracers = enabled
end

function EspModule:SetTracersPosition(position)
    Settings.TracersPosition = position
end

function EspModule:SetTracersColor(color)
    Settings.TracersColor = color
    
    for _, esp in pairs(ESPObjects) do
        if esp.Tracer then
            esp.Tracer.Color = color
        end
    end
end

return EspModule
