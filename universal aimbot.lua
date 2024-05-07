local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "KR0SS HUB",
    SubTitle = "by KR0SS",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "lucide-crosshair" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "lucide-settings" })
}

local Options = Fluent.Options

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera

local Client = Players.LocalPlayer
local ClientCharacter = Client.Character or Client.CharacterAdded:Wait()

local TweenProgress = nil

local FovCircle = Drawing.new("Circle")
FovCircle.Radius = 120
FovCircle.Color = Color3.new(1, 1, 1)
FovCircle.Visible = false

local Aimbot = Tabs.Main:AddToggle("Aimbot", {
    Title = "Aimbot",
    Description = "Enable aimbot.",
    Default = true
})

local UseShiftlockAsKeybind = Tabs.Main:AddToggle("UseShiftlockAsKeybind", {
    Title = "Use Shift Lock as Keybind",
    Description = "Use Shift Lock as Keybind.",
    Default = false
})

local Prediction = Tabs.Main:AddToggle("Prediction", {
    Title = "Prediction",
    Description = "Enable aimbot prediction.",
    Default = false
})

local WallCheck = Tabs.Main:AddToggle("WallCheck", {
    Title = "Wall Check",
    Description = "Check if target behind an objects [ currently broken ].",
    Default = false
})

local ShowFov = Tabs.Main:AddToggle("ShowFov", {
    Title = "ShowFov",
    Description = "Show Fov.",
    Default = true,
    Callback = function(value)
        FovCircle.Visible = value
    end
})

local Fov = Tabs.Main:AddSlider("Fov", {
    Title = "Fov",
    Description = "Adjust aimbot fov.",
    Default = 120,
    Min = 1,
    Max = 360,
    Rounding = 0,
    Callback = function(value)
        FovCircle.Radius = value
    end
})

local Sensivity = Tabs.Main:AddSlider("Sensivity", {
    Title = "Sensivity",
    Description = "Adjust your aimbot sensivity.",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 1
})

local PredictionTime = Tabs.Main:AddSlider("Prediction Time", {
    Title = "Prediction Time",
    Description = "Predict target position.",
    Default = 0.25,
    Min = 0,
    Max = 1,
    Rounding = 1
})

local Keybind = Tabs.Main:AddKeybind("Keybind", {
    Title = "KeyBind",
    Mode = "Hold",
    Default = "Q"
})

local function GetTargetPos()
    local TargetPos, MousePos, DistanceLimit = nil, {0, 0}, tonumber(Fov.Value)

    for _, Target in pairs(Players:GetPlayers()) do
        if Target == Client then continue end

        local Character = Target.Character

        if not Character then continue end

        local TargetPart = Character:FindFirstChild("Head")
        local Humanoid = Character:FindFirstChild("Humanoid")

        if not TargetPart or not Humanoid or Humanoid.Health <= 0 then continue end

        local WorldPos = Prediction.Value and TargetPart.Position + TargetPart.Velocity * PredictionTime.Value or TargetPart.Position
        local ScreenPos, IsOnScreen = Camera:WorldToViewportPoint(WorldPos)

        if not IsOnScreen then continue end

        if WallCheck.Value and #(Camera:GetPartsObscuringTarget({WorldPos}, {Camera, ClientCharacter, Character})) > 0 then continue end

        local MouseLocation = UserInputService:GetMouseLocation()
        local TargetLocation = Vector2.new(ScreenPos.X, ScreenPos.Y)
        local Distance = (MouseLocation - TargetLocation).Magnitude
        
        if Distance <= DistanceLimit then
            TargetPos = WorldPos
            MousePos = {TargetLocation.X - MouseLocation.X, TargetLocation.Y - MouseLocation.Y}
            DistanceLimit = Distance
        end
    end

    return TargetPos, MousePos
end

RunService.RenderStepped:Connect(function()
    FovCircle.Position = UserInputService:GetMouseLocation()

    if Aimbot.Value and (UseShiftlockAsKeybind.Value and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter or not UseShiftlockAsKeybind.Value and Keybind:GetState()) then
        local TargetPos, MousePos = GetTargetPos()

        mousemoverel(MousePos[1], MousePos[2])

        if TargetPos then
            local Speed = tonumber(Sensivity.Value)

            if Speed > 0 then
                if TweenProgress then
                    TweenProgress:Cancel()
                end

                TweenProgress = TweenService:Create(Camera, TweenInfo.new(Speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, TargetPos)})
                TweenProgress:Play()
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, TargetPos)
            end
        end
    elseif TweenProgress then
        TweenProgress:Cancel()
        TweenProgress = nil
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("KR0SSHUB")
SaveManager:SetFolder("KR0SSHUB/UniversalAimbot")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "KR0SS HUB",
    Content = "KR0SS HUB has been loaded.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
