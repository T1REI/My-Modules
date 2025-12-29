local AimModule = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Settings = {
    Enabled = false,
    ActivateMode = "Hold",
    FOVVisible = false,
    FOVSize = 100,
    FOVThickness = 2,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVLockColor = Color3.fromRGB(255, 0, 0),
    TeamCheck = false,
    WallCheck = false,
    AimPart = "Head",
    Keybind = Enum.UserInputType.MouseButton2
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Settings.FOVThickness
FOVCircle.NumSides = 64
FOVCircle.Radius = Settings.FOVSize
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Settings.FOVColor
FOVCircle.Transparency = 1
FOVCircle.ZIndex = 999

local CurrentTarget = nil
local IsAiming = false
local RenderConnection = nil
local InputConnection = nil

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Settings.FOVSize
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local humanoid = character:FindFirstChild("Humanoid")
            local targetPart = character:FindFirstChild(Settings.AimPart)
            
            if humanoid and humanoid.Health > 0 and targetPart then
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then
                    continue
                end
                
                if Settings.WallCheck then
                    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 1000)
                    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character})
                    
                    if not hit or not hit:IsDescendantOf(character) then
                        continue
                    end
                end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function AimAt(player)
    if not player or not player.Character then return end
    
    local character = player.Character
    local targetPart = character:FindFirstChild(Settings.AimPart)
    
    if targetPart then
        local targetPos = targetPart.Position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
    end
end

function AimModule:SetEnabled(enabled)
    Settings.Enabled = enabled
    
    if enabled then
        if RenderConnection then
            RenderConnection:Disconnect()
        end
        if InputConnection then
            InputConnection:Disconnect()
        end
        
        RenderConnection = RunService.RenderStepped:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()
            FOVCircle.Position = mousePos
            FOVCircle.Radius = Settings.FOVSize
            FOVCircle.Thickness = Settings.FOVThickness
            
            if Settings.FOVVisible then
                FOVCircle.Visible = true
            else
                FOVCircle.Visible = false
            end
            
            if Settings.ActivateMode == "Hold" then
                if Settings.Keybind == Enum.UserInputType.MouseButton2 then
                    IsAiming = UserInputService:IsMouseButtonPressed(Settings.Keybind)
                else
                    IsAiming = UserInputService:IsKeyDown(Settings.Keybind)
                end
            end
            
            if IsAiming and Settings.Enabled then
                CurrentTarget = GetClosestPlayer()
                
                if CurrentTarget then
                    FOVCircle.Color = Settings.FOVLockColor
                    AimAt(CurrentTarget)
                else
                    FOVCircle.Color = Settings.FOVColor
                end
            else
                FOVCircle.Color = Settings.FOVColor
                CurrentTarget = nil
            end
        end)
        
        if Settings.ActivateMode == "Toggle" then
            InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                
                if input.UserInputType == Settings.Keybind or input.KeyCode == Settings.Keybind then
                    IsAiming = not IsAiming
                end
            end)
        end
    else
        if RenderConnection then
            RenderConnection:Disconnect()
            RenderConnection = nil
        end
        if InputConnection then
            InputConnection:Disconnect()
            InputConnection = nil
        end
        FOVCircle.Visible = false
        IsAiming = false
        CurrentTarget = nil
    end
end

function AimModule:Disable()
    Settings.Enabled = false
    
    if RenderConnection then
        RenderConnection:Disconnect()
        RenderConnection = nil
    end
    
    if InputConnection then
        InputConnection:Disconnect()
        InputConnection = nil
    end
    
    FOVCircle.Visible = false
    IsAiming = false
    CurrentTarget = nil
end

function AimModule:SetActivateMode(mode)
    Settings.ActivateMode = mode
    
    if InputConnection then
        InputConnection:Disconnect()
        InputConnection = nil
    end
    
    if mode == "Toggle" and Settings.Enabled then
        InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Settings.Keybind or input.KeyCode == Settings.Keybind then
                IsAiming = not IsAiming
            end
        end)
    end
end

function AimModule:SetFOVVisible(visible)
    Settings.FOVVisible = visible
end

function AimModule:SetFOVSize(size)
    Settings.FOVSize = size
    FOVCircle.Radius = size
end

function AimModule:SetFOVThickness(thickness)
    Settings.FOVThickness = thickness
    FOVCircle.Thickness = thickness
end

function AimModule:SetFOVColor(color)
    Settings.FOVColor = color
    FOVCircle.Color = color
end

function AimModule:SetFOVLockColor(color)
    Settings.FOVLockColor = color
end

function AimModule:SetTeamCheck(enabled)
    Settings.TeamCheck = enabled
end

function AimModule:SetWallCheck(enabled)
    Settings.WallCheck = enabled
end

function AimModule:SetAimPart(part)
    Settings.AimPart = part
end

function AimModule:SetKeybind(keybind)
    if keybind == "MouseButton2" then
        Settings.Keybind = Enum.UserInputType.MouseButton2
    elseif Enum.KeyCode[keybind] then
        Settings.Keybind = Enum.KeyCode[keybind]
    end
    
    if InputConnection then
        InputConnection:Disconnect()
        InputConnection = nil
    end
    
    if Settings.ActivateMode == "Toggle" and Settings.Enabled then
        InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Settings.Keybind or input.KeyCode == Settings.Keybind then
                IsAiming = not IsAiming
            end
        end)
    end
end

return AimModule
