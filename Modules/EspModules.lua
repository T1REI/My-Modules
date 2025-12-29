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
    TracersColor = Color3.fromRGB(255, 255, 255),
    Chams = false,
    VisibleChamsColor = Color3.fromRGB(0, 255, 0),
    InvisibleChamsColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = false,
    HealthBar = false,
    NameTag = false
}

local function CreateDrawing(Type)
    local drawing = Drawing.new(Type)
    return drawing
end

local function CreateESP(player)
    local esp = {
        Player = player,
        Drawings = {},
        Tracer = nil,
        Chams = {},
        HealthBarOutline = nil,
        HealthBarFill = nil,
        NameTag = nil
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
    
    local healthOutline = CreateDrawing("Line")
    healthOutline.Thickness = 4
    healthOutline.Color = Color3.fromRGB(0, 0, 0)
    healthOutline.Visible = false
    esp.HealthBarOutline = healthOutline
    
    local healthFill = CreateDrawing("Line")
    healthFill.Thickness = 2
    healthFill.Visible = false
    esp.HealthBarFill = healthFill
    
    local nameTag = CreateDrawing("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Visible = false
    esp.NameTag = nameTag
    
    return esp
end

local function RemoveESP(esp)
    for _, drawing in pairs(esp.Drawings) do
        drawing:Remove()
    end
    if esp.Tracer then
        esp.Tracer:Remove()
    end
    if esp.HealthBarOutline then
        esp.HealthBarOutline:Remove()
    end
    if esp.HealthBarFill then
        esp.HealthBarFill:Remove()
    end
    if esp.NameTag then
        esp.NameTag:Remove()
    end
    if esp.Chams then
        for _, part in pairs(esp.Chams) do
            if part then
                part:Destroy()
            end
        end
    end
end

local function ApplyChams(character)
    if not character then return {} end
    
    local chams = {}
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local originalTransparency = part.Transparency
            part.Transparency = 0.3
            
            local highlight = Instance.new("Highlight")
            highlight.Adornee = character
            highlight.FillColor = Settings.VisibleChamsColor
            highlight.OutlineColor = Settings.InvisibleChamsColor
            highlight.FillTransparency = 0.3
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = character
            
            local pointLight = Instance.new("PointLight")
            pointLight.Brightness = 2
            pointLight.Range = 16
            pointLight.Color = Settings.VisibleChamsColor
            pointLight.Parent = part
            
            table.insert(chams, highlight)
            table.insert(chams, pointLight)
            table.insert(chams, {Part = part, OriginalTransparency = originalTransparency})
            
            break
        end
    end
    
    return chams
end

local function UpdateChams(esp)
    if Settings.Chams then
        local character = esp.Player.Character
        if character and #esp.Chams == 0 then
            esp.Chams = ApplyChams(character)
        end
        
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local ray = Ray.new(Camera.CFrame.Position, (hrp.Position - Camera.CFrame.Position).Unit * 1000)
                local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
                
                local isVisible = hit and hit:IsDescendantOf(character)
                
                for _, obj in pairs(esp.Chams) do
                    if typeof(obj) == "Instance" then
                        if obj:IsA("Highlight") then
                            if isVisible then
                                obj.FillColor = Settings.VisibleChamsColor
                                obj.OutlineColor = Settings.VisibleChamsColor
                            else
                                obj.FillColor = Settings.InvisibleChamsColor
                                obj.OutlineColor = Settings.InvisibleChamsColor
                            end
                        elseif obj:IsA("PointLight") then
                            if isVisible then
                                obj.Color = Settings.VisibleChamsColor
                            else
                                obj.Color = Settings.InvisibleChamsColor
                            end
                        end
                    end
                end
            end
        end
    else
        if #esp.Chams > 0 then
            for _, obj in pairs(esp.Chams) do
                if typeof(obj) == "Instance" and obj then
                    obj:Destroy()
                elseif typeof(obj) == "table" and obj.Part then
                    obj.Part.Transparency = obj.OriginalTransparency
                end
            end
            esp.Chams = {}
        end
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
        if esp.HealthBarOutline then
            esp.HealthBarOutline.Visible = false
        end
        if esp.HealthBarFill then
            esp.HealthBarFill.Visible = false
        end
        if esp.NameTag then
            esp.NameTag.Visible = false
        end
        if #esp.Chams > 0 then
            for _, obj in pairs(esp.Chams) do
                if typeof(obj) == "Instance" and obj then
                    obj:Destroy()
                elseif typeof(obj) == "table" and obj.Part then
                    obj.Part.Transparency = obj.OriginalTransparency
                end
            end
            esp.Chams = {}
        end
        return
    end
    
    if Settings.TeamCheck and player.Team == LocalPlayer.Team then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        if esp.Tracer then
            esp.Tracer.Visible = false
        end
        if esp.HealthBarOutline then
            esp.HealthBarOutline.Visible = false
        end
        if esp.HealthBarFill then
            esp.HealthBarFill.Visible = false
        end
        if esp.NameTag then
            esp.NameTag.Visible = false
        end
        return
    end
    
    UpdateChams(esp)
    
    local hrp = character.HumanoidRootPart
    local head = character:FindFirstChild("Head")
    
    if not head then
        for _, drawing in pairs(esp.Drawings) do
            drawing.Visible = false
        end
        if esp.Tracer then
            esp.Tracer.Visible = false
        end
        if esp.HealthBarOutline then
            esp.HealthBarOutline.Visible = false
        end
        if esp.HealthBarFill then
            esp.HealthBarFill.Visible = false
        end
        if esp.NameTag then
            esp.NameTag.Visible = false
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
        if esp.HealthBarOutline then
            esp.HealthBarOutline.Visible = false
        end
        if esp.HealthBarFill then
            esp.HealthBarFill.Visible = false
        end
        if esp.NameTag then
            esp.NameTag.Visible = false
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
    
    if Settings.HealthBar and esp.HealthBarOutline and esp.HealthBarFill then
        local humanoid = character.Humanoid
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        
        local barX = bottomLeft.X - 7
        local barTopY = topLeft.Y
        local barBottomY = bottomLeft.Y
        local barHeight = barBottomY - barTopY
        
        esp.HealthBarOutline.From = Vector2.new(barX, barTopY)
        esp.HealthBarOutline.To = Vector2.new(barX, barBottomY)
        esp.HealthBarOutline.Visible = true
        
        local healthBarHeight = barHeight * healthPercent
        esp.HealthBarFill.From = Vector2.new(barX, barBottomY)
        esp.HealthBarFill.To = Vector2.new(barX, barBottomY - healthBarHeight)
        esp.HealthBarFill.Color = Color3.fromRGB(
            255 * (1 - healthPercent),
            255 * healthPercent,
            0
        )
        esp.HealthBarFill.Visible = true
    else
        if esp.HealthBarOutline then
            esp.HealthBarOutline.Visible = false
        end
        if esp.HealthBarFill then
            esp.HealthBarFill.Visible = false
        end
    end
    
    if Settings.NameTag and esp.NameTag then
        esp.NameTag.Text = player.Name
        esp.NameTag.Position = Vector2.new(headScreen.X, topLeft.Y - 18)
        esp.NameTag.Visible = true
    else
        if esp.NameTag then
            esp.NameTag.Visible = false
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

function EspModule:SetChams(enabled)
    Settings.Chams = enabled
    
    if not enabled then
        for _, esp in pairs(ESPObjects) do
            if #esp.Chams > 0 then
                for _, obj in pairs(esp.Chams) do
                    if obj then
                        obj:Destroy()
                    end
                end
                esp.Chams = {}
            end
        end
    end
end

function EspModule:SetVisibleChamsColor(color)
    Settings.VisibleChamsColor = color
end

function EspModule:SetInvisibleChamsColor(color)
    Settings.InvisibleChamsColor = color
end

function EspModule:SetTeamCheck(enabled)
    Settings.TeamCheck = enabled
end

function EspModule:SetHealthBar(enabled)
    Settings.HealthBar = enabled
end

function EspModule:SetNameTag(enabled)
    Settings.NameTag = enabled
end

return EspModule
