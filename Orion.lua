--LOCALSCRIPT

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("[⭐]         ▬ι══════>        ( -_•)╦̵̵̿╤─ !580sLibV2 ( -_•)╦̵̵̿╤─ ", "DarkTheme")

--TABS

local Aiming = Window:NewTab("Aiming")
local AimingSection = Aiming:NewSection("Aiming")

--BUTTON / TOGGLE

AimingSection:NewButton("Streamable Aimlock", "XD", function()
--eaten-streamable
loadstring(game:HttpGet("https://raw.githubusercontent.com/T0xicJacob/eatensdad/main/eaten-streamable", true))()
--eaten-streamable
end)

--SEPERATOR

AimingSection:NewSlider("Aimlock Smoothness", "XS", 5, 0.11234451, function(s) -- 500 (MaxValue) | 0 (MinValue)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)

local AimingSection = Aiming:NewSection("Silent Aim")

AimingSection:NewButton("Silent Aim", "[NO FOV CIRCLE]", function()
-- loader
if not game:IsLoaded() then 
    game.Loaded:Wait()
end
 
if not syn or not protectgui then
    getgenv().protectgui = function() end
end
 
local SilentAimSettings = {
    Enabled = true,
 
    ClassName = "Universal Silent Aim - Project Redacted",
    ToggleKey = "RightAlt",
 
    TeamCheck = true,
    VisibleCheck = false, 
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",
 
    FOVRadius = 200,
    FOVVisible = false,
    ShowSilentAimTarget = false, 
 
    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}
 
-- variables
getgenv().SilentAimSettings = Settings
local MainFileName = "UniversalSilentAim"
local SelectedFile, FileToSave = "", ""
 
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
 
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
 
local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation
 
local resume = coroutine.resume 
local create = coroutine.create
 
local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165
 
local mouse_box = Drawing.new("Square")
mouse_box.Visible = true 
mouse_box.ZIndex = 999 
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20 
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true 
 
local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)
 
local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}
 
function CalculateChance(Percentage)
    -- // Floor the percentage
    Percentage = math.floor(Percentage)
 
    -- // Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
 
    -- // Return
    return chance <= Percentage / 100
end
 
 
--[[file handling]] do 
    if not isfolder(MainFileName) then 
        makefolder(MainFileName);
    end
 
    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then 
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end
 
local Files = listfiles(string.format("%s/%s", "UniversalSilentAim", tostring(game.PlaceId)))
 
-- functions
local function GetFiles() -- credits to the linoria lib for this function, listfiles returns the files full path and its annoying
	local out = {}
	for i = 1, #Files do
		local file = Files[i]
		if file:sub(-4) == '.lua' then
			-- i hate this but it has to be done ...
 
			local pos = file:find('.lua', 1, true)
			local start = pos
 
			local char = file:sub(pos, pos)
			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end
 
			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1, start - 1))
			end
		end
	end
 
	return out
end
 
local function UpdateFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings))
end
 
local function LoadFile(FileName)
    assert(FileName or FileName == "string", "oopsies");
 
    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end
 
local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end
 
local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end
 
local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end
 
local function getMousePosition()
    return GetMouseLocation(UserInputService)
end
 
local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
 
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
 
    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
 
    if not PlayerRoot then return end 
 
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
 
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end
 
local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end
 
        local Character = Player.Character
        if not Character then continue end
 
        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end
 
        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end
 
        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end
 
        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value])
            DistanceToMouse = Distance
        end
    end
    return Closest
end
 
-- ui creating & handling
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xaxaxaxaxaxaxaxaxa/Libraries/main/UI's/Linoria/Source.lua"))()
 
local Window = Library:CreateWindow("Universal Silent Aim, by Project Redacted")
local GeneralTab = Window:AddTab("General")
local MainBOX = GeneralTab:AddLeftTabbox("Main") do
    local Main = MainBOX:AddTab("Main")
 
    Main:AddToggle("aim_Enabled", {Text = "Enabled"}):AddKeyPicker("aim_Enabled_KeyPicker", {Default = "RightAlt", SyncToggleState = true, Mode = "Toggle", Text = "Enabled", NoUI = false});
    Options.aim_Enabled_KeyPicker:OnClick(function()
        SilentAimSettings.Enabled = not SilentAimSettings.Enabled
 
        Toggles.aim_Enabled.Value = SilentAimSettings.Enabled
        Toggles.aim_Enabled:SetValue(SilentAimSettings.Enabled)
 
        mouse_box.Visible = SilentAimSettings.Enabled
    end)
 
    Main:AddToggle("TeamCheck", {Text = "Team Check", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
        SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
    end)
    Main:AddToggle("VisibleCheck", {Text = "Visible Check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
        SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
    end)
    Main:AddDropdown("TargetPart", {Text = "Target Part", Default = SilentAimSettings.TargetPart, Values = {"Head", "HumanoidRootPart", "Random"}}):OnChanged(function()
        SilentAimSettings.TargetPart = Options.TargetPart.Value
    end)
    Main:AddDropdown("Method", {Text = "Silent Aim Method", Default = SilentAimSettings.SilentAimMethod, Values = {
        "Raycast","FindPartOnRay",
        "FindPartOnRayWithWhitelist",
        "FindPartOnRayWithIgnoreList",
        "Mouse.Hit/Target"
    }}):OnChanged(function() 
        SilentAimSettings.SilentAimMethod = Options.Method.Value 
    end)
    Main:AddSlider('HitChance', {
        Text = 'Hit chance',
        Default = 100,
        Min = 0,
        Max = 100,
        Rounding = 1,
 
        Compact = false,
    })
    Options.HitChance:OnChanged(function()
        SilentAimSettings.HitChance = Options.HitChance.Value
    end)
end
 
local MiscellaneousBOX = GeneralTab:AddLeftTabbox("Miscellaneous")
local FieldOfViewBOX = GeneralTab:AddLeftTabbox("Field Of View") do
    local Main = FieldOfViewBOX:AddTab("Visuals")
 
    Main:AddToggle("Visible", {Text = "Show FOV Circle"}):AddColorPicker("Color", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        fov_circle.Visible = Toggles.Visible.Value
        SilentAimSettings.FOVVisible = Toggles.Visible.Value
    end)
    Main:AddSlider("Radius", {Text = "FOV Circle Radius", Min = 0, Max = 360, Default = 130, Rounding = 0}):OnChanged(function()
        fov_circle.Radius = Options.Radius.Value
        SilentAimSettings.FOVRadius = Options.Radius.Value
    end)
    Main:AddToggle("MousePosition", {Text = "Show Silent Aim Target"}):AddColorPicker("MouseVisualizeColor", {Default = Color3.fromRGB(54, 57, 241)}):OnChanged(function()
        mouse_box.Visible = Toggles.MousePosition.Value 
        SilentAimSettings.ShowSilentAimTarget = Toggles.MousePosition.Value 
    end)
    local PredictionTab = MiscellaneousBOX:AddTab("Prediction")
    PredictionTab:AddToggle("Prediction", {Text = "Mouse.Hit/Target Prediction"}):OnChanged(function()
        SilentAimSettings.MouseHitPrediction = Toggles.Prediction.Value
    end)
    PredictionTab:AddSlider("Amount", {Text = "Prediction Amount", Min = 0.165, Max = 1, Default = 0.165, Rounding = 3}):OnChanged(function()
        PredictionAmount = Options.Amount.Value
        SilentAimSettings.MouseHitPredictionAmount = Options.Amount.Value
    end)
end
 
local CreateConfigurationBOX = GeneralTab:AddRightTabbox("Create Configuration") do 
    local Main = CreateConfigurationBOX:AddTab("Create Configuration")
 
    Main:AddInput("CreateConfigTextBox", {Default = "", Numeric = false, Finished = false, Text = "Create Configuration to Create", Tooltip = "Creates a configuration file containing settings you can save and load", Placeholder = "File Name here"}):OnChanged(function()
        if Options.CreateConfigTextBox.Value and string.len(Options.CreateConfigTextBox.Value) ~= "" then 
            FileToSave = Options.CreateConfigTextBox.Value
        end
    end)
 
    Main:AddButton("Create Configuration File", function()
        if FileToSave ~= "" or FileToSave ~= nil then 
            UpdateFile(FileToSave)
        end
    end)
end
 
local SaveConfigurationBOX = GeneralTab:AddRightTabbox("Save Configuration") do 
    local Main = SaveConfigurationBOX:AddTab("Save Configuration")
    Main:AddDropdown("SaveConfigurationDropdown", {Values = GetFiles(), Text = "Choose Configuration to Save"})
    Main:AddButton("Save Configuration", function()
        if Options.SaveConfigurationDropdown.Value then 
            UpdateFile(Options.SaveConfigurationDropdown.Value)
        end
    end)
end
 
local LoadConfigurationBOX = GeneralTab:AddRightTabbox("Load Configuration") do 
    local Main = LoadConfigurationBOX:AddTab("Load Configuration")
 
    Main:AddDropdown("LoadConfigurationDropdown", {Values = GetFiles(), Text = "Choose Configuration to Load"})
    Main:AddButton("Load Configuration", function()
        if table.find(GetFiles(), Options.LoadConfigurationDropdown.Value) then
            LoadFile(Options.LoadConfigurationDropdown.Value)
 
            Toggles.TeamCheck:SetValue(SilentAimSettings.TeamCheck)
            Toggles.VisibleCheck:SetValue(SilentAimSettings.VisibleCheck)
            Options.TargetPart:SetValue(SilentAimSettings.TargetPart)
            Options.Method:SetValue(SilentAimSettings.SilentAimMethod)
            Toggles.Visible:SetValue(SilentAimSettings.FOVVisible)
            Options.Radius:SetValue(SilentAimSettings.FOVRadius)
            Toggles.MousePosition:SetValue(SilentAimSettings.ShowSilentAimTarget)
            Toggles.Prediction:SetValue(SilentAimSettings.MouseHitPrediction)
            Options.Amount:SetValue(SilentAimSettings.MouseHitPredictionAmount)
            Options.HitChance:SetValue(SilentAimSettings.HitChance)
        end
    end)
end
 
resume(create(function()
    RenderStepped:Connect(function()
        if Toggles.MousePosition.Value and Toggles.aim_Enabled.Value then
            if getClosestPlayer() then 
                local Root = getClosestPlayer().Parent.PrimaryPart or getClosestPlayer()
                local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position);
                -- using PrimaryPart instead because if your Target Part is "Random" it will flicker the square between the Target's Head and HumanoidRootPart (its annoying)
 
                mouse_box.Visible = IsOnScreen
                mouse_box.Position = Vector2.new(RootToViewportPoint.X, RootToViewportPoint.Y)
            else 
                mouse_box.Visible = false 
                mouse_box.Position = Vector2.new()
            end
        end
 
        if Toggles.Visible.Value then 
            fov_circle.Visible = Toggles.Visible.Value
            fov_circle.Color = Options.Color.Value
            fov_circle.Position = getMousePosition()
        end
    end)
end))
 
-- hooks
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    if Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and chance == true then
        if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local A_Ray = Arguments[2]
 
                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)
 
                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local A_Ray = Arguments[2]
 
                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)
 
                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.Method.Value:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]
 
                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)
 
                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "Raycast" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]
 
                local HitPart = getClosestPlayer()
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)
 
                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))
 
local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
        local HitPart = getClosestPlayer()
 
        if Index == "Target" or Index == "target" then 
            return HitPart
        elseif Index == "Hit" or Index == "hit" then 
            return ((Toggles.Prediction.Value and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not Toggles.Prediction.Value and HitPart.CFrame))
        elseif Index == "X" or Index == "x" then 
            return self.X 
        elseif Index == "Y" or Index == "y" then 
            return self.Y 
        elseif Index == "UnitRay" then 
            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
        end
    end
 
    return oldIndex(self, Index)
end))
end)

--SEPERATOR

AimingSection:NewSlider("SilentAim FOV Circle", "XS", 120, 1, function(s) -- 500 (MaxValue) | 0 (MinValue)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = s
end)

AimingSection:NewButton("Reset FOV Circle", "Resets Fov Circle", function()
    print("Clicked")
end)

local AimingSection = Aiming:NewSection("AntiLock")

AimingSection:NewToggle("AntiLock", "AntiLock", function(state)
    if state then
        local Toggled = true
        local KeyCode = 'z'
        local hip = 2.80
        local val = -35
        
        
        
        
        
        function AA()
            local oldVelocity = game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(oldVelocity.X, val, oldVelocity.Z)
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(oldVelocity.X, oldVelocity.Y, oldVelocity.Z)
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(oldVelocity.X, val, oldVelocity.Z)
            game.Players.LocalPlayer.Character.Humanoid.HipHeight = hip
        end
        
        game:GetService('UserInputService').InputBegan:Connect(function(Key)
            if Key.KeyCode == Enum.KeyCode[KeyCode:upper()] and not game:GetService('UserInputService'):GetFocusedTextBox() then
                if Toggled then
                    Toggled = false
                    game.Players.LocalPlayer.Character.Humanoid.HipHeight = hip
        
                elseif not Toggled then
                    Toggled = true
        
                    while Toggled do
                        AA()
                        task.wait()
                    end
                end
            end
        end)
    else
        loadstring(game:HttpGet("https://raw.githubusercontent.com/chrsschrs/antilocks/main/aa"))
    end
end)

--VISUALS

local Visuals = Window:NewTab("Visuals")
local VisualsSection = Visuals:NewSection("Visuals")

--TAB2

VisualsSection:NewButton("Item ESP [NOT WORKING RN]", "Item ESP", function()
    Script: spawn(loadstring(game:HttpGet("https://pastebin.com/raw/zKjj0TQD", true)))()
end)

VisualsSection:NewButton("ESP", "ESP", function()
    getgenv().enabled = true --Toggle on/off
    getgenv().filluseteamcolor = false --Toggle fill color using player team color on/off
    getgenv().outlineuseteamcolor = false --Toggle outline color using player team color on/off
    getgenv().fillcolor = Color3.new(1, 1, 1) --Change fill color, no need to edit if using team color
    getgenv().outlinecolor = Color3.new(0, 0, 0) --Change outline color, no need to edit if using team color
    getgenv().filltrans = 0 --Change fill transparency
    getgenv().outlinetrans = 0 --Change outline transparency
     
    loadstring(game:HttpGet("https://raw.githubusercontent.com/zntly/highlight-esp/main/esp.lua"))()

end)
local VisualsSection = Visuals:NewSection("Animations")

VisualsSection:NewButton("Cartoony", "Cartoony", function()
    print("Clicked")
end)

VisualsSection:NewButton("Levitation", "Levitation", function()
    print("Clicked")
end)

VisualsSection:NewButton("Robot", "Robot", function()
    print("Clicked")
end)

VisualsSection:NewButton("Stylish", "Stylish", function()
    print("Clicked")
end)

VisualsSection:NewButton("Superhero", "Superhero", function()
    print("Clicked")
end)

VisualsSection:NewButton("Zombie", "Zombie", function()
    print("Clicked")
end)

VisualsSection:NewButton("Ninja", "Ninja", function()
    print("Clicked")
end)

VisualsSection:NewButton("Knight", "Knight", function()
    print("Clicked")
end)

VisualsSection:NewButton("Mage", "Mage", function()
    print("Clicked")
end)

VisualsSection:NewButton("Pirate", "Pirate", function()
    print("Clicked")
end)

VisualsSection:NewButton("Elder", "Elder", function()
    print("Clicked")
end)

VisualsSection:NewButton("Toy", "Toy", function()
    print("Clicked")
end)

VisualsSection:NewButton("Bubbly", "Bubbly", function()
    print("Clicked")
end)

VisualsSection:NewButton("Astronaut", "Astronaut", function()
    print("Clicked")
end)

VisualsSection:NewButton("Vampire", "Vampire", function()
    print("Clicked")
end)

VisualsSection:NewButton("Werewolf", "Werewolf", function()
    print("Clicked")
end)

VisualsSection:NewButton("Rthro", "Rthro", function()
    print("Clicked")
end)

VisualsSection:NewButton("Oldschool", "Oldschool", function()
    print("Clicked")
end)

--SEPERATOR

local LocalPlayer = Window:NewTab("LocalPlayer")
local LocalPlayerSection = LocalPlayer:NewSection("LocalPlayer")

LocalPlayerSection:NewButton("GodMode V3", "Immortality", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/cypherdh/GodMode-V3/main/script"))()
end)

LocalPlayerSection:NewButton("Fly [DONT USE IN DH PERMA BAN]", "fly.", function()
    local speed = 50
    local bodyvelocityenabled = true
     
    local Imput = game:GetService("UserInputService")
    local Plr = game.Players.LocalPlayer
    local nextmsgspd = false
    local nextmsgrc = false
    local flying = true
    local rc = 5
    local Mouse = Plr:GetMouse()
    local cn
    local cn1
    local cn2
    local cn3
    local cn4
    local currentTween
     
    local speedPart = Instance.new("Part", workspace)
    speedPart.Anchored = true
    speedPart.Transparency = 1
    speedPart.CanCollide = false
    speedPart.Size = Vector3.new(10, 25, 10)
     
    function To(position)
    if not flying then return end
    local Chr = Plr.Character
    if Chr ~= nil then
    local ts = game:GetService("TweenService")
    local char = game.Players.LocalPlayer.Character
    local hm = char.HumanoidRootPart
    local dist = (hm.Position - Mouse.Hit.p).magnitude
    local tweenspeed = dist/tonumber(speed)
    local ti = TweenInfo.new(tonumber(tweenspeed), Enum.EasingStyle.Linear)
    local tp = {CFrame = CFrame.new(position)}
    currentTween = ts:Create(hm, ti, tp)
    currentTween:Play()
    if bodyvelocityenabled == true then
    local bv = Instance.new("BodyVelocity")
    bv.Name = "BypassedFlyBodyVelocity"
    bv.Parent = hm
    bv.MaxForce = Vector3.new(100000,100000,100000)
    bv.Velocity = Vector3.new(0,0,0)
    wait(tonumber(tweenspeed))
    bv:Destroy()
    end
    end
    end
     
    cn4 = Imput.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.F then
            flying = not flying
            for i,v in pairs(Plr.Character:GetDescendants()) do
                if v.Name == "BypassedFlyBodyVelocity" then
                    v:Destroy()
                end
            end
        end
    end)
     
    cn = Plr.Chatted:Connect(function(msg)
        if nextmsgspd then
            speed = tonumber(msg)
            nextmsgspd = false
        end
        if nextmsgrc then
            rc = tonumber(msg)
            nextmsgrc = false
        end
        if string.lower(tostring(msg)) == "set fly speed" then
            nextmsgspd = true
        end
        if string.lower(tostring(msg)) == "toggle visibility" then
            if speedPart.Transparency == 1 then
                speedPart.Transparency = .75
            else speedPart.Transparency = 1
            end
        end
        if string.lower(tostring(msg)) == "set rc" then
            nextmsgrc = true
        end
        if string.lower(tostring(msg)) == "unload fly" then
            cn:Disconnect()
            cn1:Disconnect()
            cn2:Disconnect()
            cn3:Disconnect()
            cn4:Disconnect()
            speedPart:Destroy()
            flying = false
            wait(.1)
            for i,v in pairs(Plr.Character:GetDescendants()) do
                if v.Name == "BypassedFlyBodyVelocity" then
                    v:Destroy()
                end
            end
            spawn(function()
                currentTween:Cancel()
            end)
            print("Unloaded.")
        end
    end)
     
    local mousePressed = false
     
    cn1 = Mouse.Button1Down:Connect(function()
        mousePressed = true
    end)
     
    cn2 = Mouse.Button1Up:Connect(function()
        mousePressed = false
        if currentTween then
            currentTween:Cancel()
        end
    end)
     
    local btz = 0
    cn3 = game:GetService("RunService").Heartbeat:Connect(function()
        speedPart.CFrame = CFrame.new(Plr.Character.HumanoidRootPart.Position + (Mouse.UnitRay.Direction * 15), Plr.Character.HumanoidRootPart.Position)
        if flying and mousePressed and btz >= rc then
            btz = 0
            if currentTween then
                currentTween:Cancel()
            end
            To(Plr.Character.HumanoidRootPart.Position + (Mouse.UnitRay.Direction * 50) + Vector3.new(0, 2.5, 0))
        end
        btz = btz + 1
    end)
    wait(.03)
    print("Bypassed fly loaded")
end)

LocalPlayerSection:NewButton("Speed [C]", "Lazy Macro XD", function()
--Settings
local sped = 200 -- Speed
local keybind = "c"




--The Script

yes = false
	plr = game.Players.LocalPlayer
	mouse = plr:GetMouse()
	mouse.KeyDown:connect(function(key)
		if key == keybind and yes == false then
			yes = true
			game.Players.LocalPlayer.Character.Humanoid.Name = "Humz"
			game.Players.LocalPlayer.Character.Humz.WalkSpeed = sped
			game.Players.LocalPlayer.Character.Humz.JumpPower = 50
		elseif key == keybind and yes == true then
			yes = false
			game.Players.LocalPlayer.Character.Humz.WalkSpeed = 16
			game.Players.LocalPlayer.Character.Humz.JumpPower = 50
			game.Players.LocalPlayer.Character.Humz.Name = "Humanoid"
		end
	end)
end)

--SEPERATOR

local LocalPlayerSection = LocalPlayer:NewSection("Others")

LocalPlayerSection:NewButton("Rejoin", "Doesnt work in servers on ur own.", function()
    TeleportService:Teleport(game.PlaceId,plr)
end)

LocalPlayerSection:NewButton("Reset", "Respawn", function()
    for i, v in pairs (game:GetService("Players"):GetPlayers()) do
        v.Character:FindFirstChild("Humanoid").Health = 0
    end
    
    -- This works currently of 10/19/2020
end)

LocalPlayerSection:NewButton("ChatSpy", "Chatspy", function()
--This script reveals ALL hidden messages in the default chat
 
enabled = true --chat "/spy" to toggle!
spyOnMyself = true --if true will check your messages too
public = false --if true will chat the logs publicly (fun, risky)
publicItalics = true --if true will use /me to stand out
privateProperties = { --customize private logs
	Color = Color3.fromRGB(0,255,255); 
	Font = Enum.Font.SourceSansBold;
	TextSize = 18;
}
 
 
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
local saymsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
local getmsg = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("OnMessageDoneFiltering")
local instance = (_G.chatSpyInstance or 0) + 1
_G.chatSpyInstance = instance
 
local function onChatted(p,msg)
	if _G.chatSpyInstance == instance then
		if p==player and msg:lower():sub(1,4)=="/spy" then
			enabled = not enabled
			wait(0.3)
			privateProperties.Text = "{SPY "..(enabled and "EN" or "DIS").."ABLED}"
			StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
		elseif enabled and (spyOnMyself==true or p~=player) then
			msg = msg:gsub("[\n\r]",''):gsub("\t",' '):gsub("[ ]+",' ')
			local hidden = true
			local conn = getmsg.OnClientEvent:Connect(function(packet,channel)
				if packet.SpeakerUserId==p.UserId and packet.Message==msg:sub(#msg-#packet.Message+1) and (channel=="All" or (channel=="Team" and public==false and Players[packet.FromSpeaker].Team==player.Team)) then
					hidden = false
				end
			end)
			wait(1)
			conn:Disconnect()
			if hidden and enabled then
				if public then
					saymsg:FireServer((publicItalics and "/me " or '').."{SPY} [".. p.Name .."]: "..msg,"All")
				else
					privateProperties.Text = "{SPY} [".. p.Name .."]: "..msg
					StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
				end
			end
		end
	end
end
 
for _,p in ipairs(Players:GetPlayers()) do
	p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end
Players.PlayerAdded:Connect(function(p)
	p.Chatted:Connect(function(msg) onChatted(p,msg) end)
end)
privateProperties.Text = "{SPY "..(enabled and "EN" or "DIS").."ABLED}"
StarterGui:SetCore("ChatMakeSystemMessage",privateProperties)
if not player.PlayerGui:FindFirstChild("Chat") then wait(3) end
local chatFrame = player.PlayerGui.Chat.Frame
chatFrame.ChatChannelParentFrame.Visible = true
chatFrame.ChatBarParentFrame.Position = chatFrame.ChatChannelParentFrame.Position+UDim2.new(UDim.new(),chatFrame.ChatChannelParentFrame.Size.Y)
end)

--SEPERATOR

local Settings = Window:NewTab("Settings")
local SettingsSection = Settings:NewSection("Settings")


SettingsSection:NewKeybind("GUI Toggle", "TogglesGUI", Enum.KeyCode.F, function()
	Library:ToggleUI()
end)

SettingsSection:NewLabel("Made By 580s")

LocalPlayerSection:NewToggle("No Jump Cooldown [UNTOGGLEABLE]", "NJC", function(state)
    if state then
        for i,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
            require(v.Stats).Cooldown = 0
        end
    else
        for i,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
            require(v.Stats).Cooldown = 0
        end
    end
end)

--SPOOFERS ECT

local Spoofers = Window:NewTab("Spoofers")
local SpoofersSection = Spoofers:NewSection("Spoofers")

SpoofersSection:NewButton("Ping Spoofer", "Ping Spoofer", function()
    local PerformanceStats = game:GetService("CoreGui"):WaitForChild("RobloxGui"):WaitForChild("PerformanceStats");
    local PingLabel;
    for I, Child in next, PerformanceStats:GetChildren() do
        if Child.StatsMiniTextPanelClass.TitleLabel.Text == "Ping" then
            PingLabel = Child.StatsMiniTextPanelClass.ValueLabel;
            break;
        end;
    end;
    
    local text = "50.5 ms";
    PingLabel:GetPropertyChangedSignal("Text"):Connect(function()
        PingLabel.Text = text;
    end);
    PingLabel.Text = text;
end)

SpoofersSection:NewButton("Memory Spoofer", "Mem Spoof", function()
    local PerformanceStats = game:GetService("CoreGui"):WaitForChild("RobloxGui"):WaitForChild("PerformanceStats");
    local MemLabel;
    for I, Child in next, PerformanceStats:GetChildren() do
        if Child.StatsMiniTextPanelClass.TitleLabel.Text == "Mem" then
            MemLabel = Child.StatsMiniTextPanelClass.ValueLabel;
            break;
        end;
    end;
    
    local text = "462.52 MB";
    MemLabel:GetPropertyChangedSignal("Text"):Connect(function()
        MemLabel.Text = text;
    end);
    MemLabel.Text = text;
end)

local Extra = Window:NewTab("Extras ;)")
local ExtraSection = Extra:NewSection("Extras ;)")

ExtraSection:NewButton("FPSGUI", "FPSGUI", function()
    pcall(function()
        local espcolor = Color3.fromRGB(140, 69, 102)
        local wallhack_esp_transparency = .4
        local gui_hide_button = {Enum.KeyCode.LeftControl, "h"}
        local plrs = game:GetService("Players")
        local lplr = game:GetService("Players").LocalPlayer
        local TeamBased = false ; local teambasedswitch = "m"
        local presskeytoaim = true; local aimkey = "e"
        aimbothider = false; aimbothiderspeed = .5
        local Aim_Assist = false ; Aim_Assist_Key = {Enum.KeyCode.LeftControl, ""}
        local espupdatetime = 5; autoesp = false; local charmsesp = false
        local movementcounting = true
        
        
        
        
        local mouselock = false
        local canaimat = true
        local lockaim = true; local lockangle = 5
        local ver = "2.4"
        local cam = game.Workspace.CurrentCamera
        local BetterDeathCount = true
        local ballisticsboost = 0
        
        local mouse = lplr:GetMouse()
        local switch = false
        local key = "k"
        local aimatpart = nil
        local lightesp = false
        
        local abs = math.abs
        
        local Gui = Instance.new("ScreenGui")
        local Move = Instance.new("Frame")
        local Main = Instance.new("Frame")
        local EspStatus = Instance.new("TextLabel")
        local st1 = Instance.new("TextLabel")
        local st1_2 = Instance.new("TextLabel")
        local st1_3 = Instance.new("TextBox")
        local Name = Instance.new("TextLabel")
        --Properties:
        
        Gui.Parent = plrs.LocalPlayer:WaitForChild("PlayerGui")
        
        
        local aimbotstatus = {"qc", "qr", "qe", "qd", "qi", "qt", "qs", "dd", "sp", "ql", "qa", "qd", "qs"}
        local gotstring = 0
        local function getrandomstring()
            gotstring = gotstring+666
            local str = ""
            local randomstring = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "g", "k", "l", "m", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
                 "а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","о","п","р","с","т","у","ф","х","ч","щ","ъ","ы","ъ","э","ю","я", "`", "$", 
                "0","1","2","3","4","5","6","7","8","9", }
            local counting123 = 0
            for i, v in ipairs(randomstring) do
                counting123 = i
            end
            do
                math.randomseed(tick()+gotstring)
                for i = 3, math.random(1,100) do
                        math.randomseed(i+tick()+gotstring)
                        
                        local oneortwo = math.random(1,2)
                        if oneortwo == 2 then
                            math.randomseed(i+tick()+gotstring)
                            str = str..""..randomstring[math.random(1, counting123)]
                        else
                            math.randomseed(i+tick()+gotstring)
                            str = str..""..string.upper(randomstring[math.random(1, counting123)])
                        end
                    
                end
            end
            return str
        end
        local mousedown = false
        local isonmovething = false
        local mouseoffset = Vector2.new()
        local mousedown = false
        local bspeed = 3584
        local aimbotoffset = {dd = ":", sp = " ", qa = "a", qb = "b",qc = "c", qd = "d", qe = "e", qf = "f", qg = "g" , qh = "h" , qi = "i", qj = "j", qk = "k", ql = "l", qm = "m", qn = "n", qo = "o", qp = "p", qq = "q", qr = "r", qs = "s", qt = "t", qu = "u", qv = "w", qx = "x", qy = "y", qz = "z"}
        
        
        
        Gui.Name = getrandomstring()
        
        Move.Name = getrandomstring()
        Move.Draggable = true
        Move.Parent = Gui
        Move.BackgroundColor3 = Color3.new(0.0431373, 1, 0.0745098)
        Move.BackgroundTransparency = 0.40000000596046
        Move.BorderSizePixel = 0
        Move.Position = UDim2.new(0.5, 0,0.018, 0)
        Move.Size = UDim2.new(0, 320, 0, 30)
        
        Move.MouseEnter:Connect(function()
            
            isonmovething = true
            
        end)
        Move.MouseLeave:Connect(function()
            
            isonmovething = mousedown and true or false
        end)
        mouse.Button1Down:connect(function()
            mousedown = true
            mouseoffset = Move.AbsolutePosition - Vector2.new(mouse.X, mouse.Y)
        end)
        mouse.Button1Up:connect(function()
            mousedown = false
        end)
        
        mouse.Move:Connect(function()
            if isonmovething == true and mousedown then
                Move.Position = UDim2.new(0, mouseoffset.X + mouse.X, 0, mouseoffset.Y + mouse.Y)
            end
        end)
        local function uc (st)
            local ast = ""
            for i, v in ipairs(st) do
                local let = aimbotoffset[v]
                ast = ast..let
            end
            return ast
        end
        
        Main.Name = getrandomstring()
        Main.Parent = Move
        Main.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
        Main.BackgroundTransparency = 0.69999998807907
        Main.Position = UDim2.new(0, 0, 0.995670795, 0)
        Main.Size = UDim2.new(1.0000006, 0, 11.2, 0)
        
        st1.Name = getrandomstring()
        st1.Parent = Main
        st1.BackgroundColor3 = Color3.new(1, 1, 1)
        st1.BackgroundTransparency = 1
        st1.Position = UDim2.new(0, 0, 0, 0)
        st1.Size = UDim2.new(1, 0, 0.161862016, 0)
        st1.Font = Enum.Font.ArialBold
        st1.Text = uc(aimbotstatus)
        st1.TextColor3 = Color3.new(0.0431373, 1, 0.0745098)
        st1.TextScaled = true
        st1.TextSize = 14
        st1.TextWrapped = true
        
        st1_2.Name = getrandomstring()
        st1_2.Parent = Main
        st1_2.BackgroundColor3 = Color3.new(1, 1, 1)
        st1_2.BackgroundTransparency = 1
        st1_2.Position = UDim2.new(0, 0, 0.375590861, 0)
        st1_2.Size = UDim2.new(0.999999881, 0, 0.161862016, 0)
        st1_2.Font = Enum.Font.ArialBold
        st1_2.TextXAlignment = Enum.TextXAlignment.Left
        st1_2.Text = "Current ballistics: 0"
        st1_2.TextColor3 = Color3.new(0.0431373, 1, 0.0745098)
        st1_2.TextScaled = true
        st1_2.TextSize = 14
        st1_2.TextWrapped = true
        
        local aimbothiderbox = Instance.new("TextBox")
        aimbothiderbox.Name = getrandomstring()
        aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." off"
        aimbothiderbox.Size = UDim2.new(1, 0,0.162, 0)
        aimbothiderbox.TextScaled = true
        aimbothiderbox.TextColor3 =Color3.fromRGB(255, 0, 0)
        aimbothiderbox.Position = UDim2.new(0, 0,0.853, 0)
        aimbothiderbox.BackgroundTransparency = 1
        aimbothiderbox.Parent = Main
        
        st1_3.Name = getrandomstring()
        st1_3.Parent = Main
        st1_3.BackgroundColor3 = Color3.new(1, 1, 1)
        st1_3.BackgroundTransparency = 1
        st1_3.Position = UDim2.new(0, 0, 0.18558608, 0)
        st1_3.Size = UDim2.new(0.999999881, 0, 0.161862016, 0)
        st1_3.Font = Enum.Font.ArialBold
        st1_3.Text = "Bullet speed = 3584"
        st1_3.TextColor3 = Color3.new(0.0431373, 1, 0.0745098)
        st1_3.TextScaled = true
        st1_3.TextSize = 14
        st1_3.TextWrapped = true
        local teambasedstatus = st1_3:Clone()
        teambasedstatus.Parent = Main
        teambasedstatus.TextScaled = true
        teambasedstatus.Position = UDim2.new(0, 0,.7, 0)
        teambasedstatus.Size = UDim2.new(1, 0,.1, 0)
        teambasedstatus.Name = getrandomstring()
        teambasedstatus.Text = "Team Based: "..tostring(TeamBased)
        local espstatustext = teambasedstatus:Clone()
        espstatustext.Name = getrandomstring()
        espstatustext.Position = UDim2.new(0, 0,0.58, 0)
        espstatustext.Text = "Esp loop :"..tostring(autoesp)
        espstatustext.Parent = Main
        local hide = Instance.new("TextButton")
        hide.Text = "_"
        hide.BackgroundTransparency = 1
        hide.TextScaled = true
        hide.TextWrapped = true
        hide.Size = UDim2.new(0.1, 0,1, 0)
        hide.Position = UDim2.new(0.9, 0,-0.15, 0)
        hide.Name = getrandomstring()
        hide.Parent = Move
        Name.Name = getrandomstring()
        Name.Parent = Move
        Name.BackgroundColor3 = Color3.new(1, 1, 1)
        Name.BackgroundTransparency = 1
        Name.Size = UDim2.new(0.838, 0, 1, 0)
        Name.Font = Enum.Font.Arial
        Name.Text = "FPS gui v"..ver
        Name.TextColor3 = Color3.new(0, 0, 0)
        Name.TextScaled = true
        Name.TextSize = 14
        Name.TextWrapped = true
        Name.TextXAlignment = Enum.TextXAlignment.Left
        local scr = Instance.new("ScrollingFrame")
        scr.Size = Main.Size
        scr.Position = Main.Position
        scr.ScrollBarThickness = 0
        scr.BackgroundTransparency = 1
        scr.Name = getrandomstring()
        Main.Size = UDim2.new(1, 0, 1, 0)
        Main.Position = UDim2.new(0,0,0,0)
        Main.Parent = scr
        scr.Parent = Move
        startpos = Main.Position
        Move.Active = true
        
        -- Scripts:
        hided = false
        hide.MouseButton1Click:Connect(function()
            if hided == false then
                hided = true
                Main:TweenPosition(UDim2.new(0, 0, -1.5, 0))
            else
                hided = false
                Main:TweenPosition(startpos)
            end
        end)
        
        
        aimbothiderbox.FocusLost:Connect(function()
            local numb = tonumber(aimbothiderbox.Text)
            if aimbothider == true then
                aimbothiderbox.TextColor3 =Color3.fromRGB(11, 255, 19)
            else
                aimbothiderbox.TextColor3 =Color3.fromRGB(255, 0, 0)
            end
            if numb ~= nil then
                aimbothiderspeed = numb
                if aimbothider == true then
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." on"
                else
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." off"
                end
            else
                if aimbothider == true then
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." on"
                else
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." off"
                end
            end
        end)
        
        
        local plrsforaim = {}
        
        
        Move.Draggable = true
        Gui.ResetOnSpawn = false
        --Gui.Name = "Chat"
        Gui.DisplayOrder = 999
        pcall(function()
        if not game:GetService("CoreGui") then
            Gui.Parent = plrs.LocalPlayer.PlayerGui
        else
            Gui.Parent = game:GetService("CoreGui")
        end
        end)
        local espheadthing
        do
        local BillboardGui = Instance.new("BillboardGui")
        local PName = Instance.new("TextLabel")
        local Pdist = Instance.new("TextLabel")
        local ImageLabel = Instance.new("ImageLabel")
        local ImageLabel_2 = Instance.new("ImageLabel")
        --Properties:
        --BillboardGui.Parent = game.Workspace.Part
        BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        BillboardGui.AlwaysOnTop = true
        BillboardGui.LightInfluence = 0
        BillboardGui.Size = UDim2.new(0, 100, 0, 46)
        BillboardGui.Name = "headoverthing"
        PName.Name = "PName"
        PName.Parent = BillboardGui
        PName.BackgroundColor3 = espcolor
        PName.BackgroundTransparency = 0.55000001192093
        PName.BorderSizePixel = 0
        PName.Size = UDim2.new(0, 100, 0, 23)
        PName.Font = Enum.Font.SourceSans
        PName.Text = "urmom"
        PName.TextColor3 = Color3.new(0, 0, 0)
        PName.TextScaled = true
        PName.TextSize = 14
        PName.TextWrapped = true
        st1.Text = uc(aimbotstatus)
        Pdist.Name = "Pdist"
        Pdist.Parent = BillboardGui
        Pdist.AnchorPoint = Vector2.new(0.5, 0)
        Pdist.BackgroundColor3 = espcolor
        Pdist.BackgroundTransparency = 0.55000001192093
        Pdist.BorderSizePixel = 0
        Pdist.Position = UDim2.new(0.5, 0, 0.5, 0)
        Pdist.Size = UDim2.new(0, 70, 0, 23)
        Pdist.Font = Enum.Font.SourceSans
        Pdist.Text = "666"
        Pdist.TextColor3 = Color3.new(0, 0, 0)
        Pdist.TextScaled = true
        Pdist.TextSize = 14
        Pdist.TextWrapped = true
        
        ImageLabel.Parent = BillboardGui
        ImageLabel.BackgroundColor3 = Color3.new(0.298039, 1, 0)
        ImageLabel.BackgroundTransparency = 1
        ImageLabel.BorderColor3 = espcolor
        ImageLabel.Position = UDim2.new(1, -15, 0.5, 0)
        ImageLabel.Rotation = 180
        ImageLabel.Size = UDim2.new(0, 15, 0, 23)
        ImageLabel.Image = "rbxassetid://2832171824"
        ImageLabel.ImageColor3 = espcolor
        ImageLabel.ImageTransparency = 0.55000001192093
        
        ImageLabel_2.Parent = BillboardGui
        ImageLabel_2.BackgroundColor3 = espcolor
        ImageLabel_2.BackgroundTransparency = 1
        ImageLabel_2.BorderColor3 = Color3.new(0.298039, 1, 0)
        ImageLabel_2.Position = UDim2.new(0, 0, 0.5, 0)
        ImageLabel_2.Rotation = 180
        ImageLabel_2.Size = UDim2.new(0, 15, 0, 23)
        ImageLabel_2.Image = "rbxassetid://2832177613"
        ImageLabel_2.ImageColor3 = espcolor
        ImageLabel_2.ImageTransparency = 0.55000001192093
        espheadthing = BillboardGui
        end
        
        
        
        f = {}
        f.UpdateHeadUI = function(v)
            
                
                    if v.Adornee and v.Adornee ~= nil then
                        local destr = false
                        if TeamBased then
                            destr = true
                            local plr = plrs:GetPlayerFromCharacter(v.Adornee.Parent)
                            if plr and plr.Team and plr.Team.Name ~= lplr.Team.Name then
                                destr = false
                            end
                        end
                        if lightesp == true then
                            v.Pdist.TextColor3 = Color3.new(1,1,1)
                            v.PName.TextColor3 = Color3.new(1,1,1)
                        else
                            v.Pdist.TextColor3 = Color3.new(0,0,0)
                            v.PName.TextColor3 = Color3.new(0,0,0)
                        end
                        local d = math.floor((cam.CFrame.p - v.Adornee.CFrame.p).magnitude)
                        v.Pdist.Text = tostring(d)
                        if d < 14 then
                            v.Enabled = false
                        else
                            v.Enabled = true
                        end
                        v.StudsOffset = Vector3.new(0,.6+d/14,0)
                        if destr then
                            v:Destroy()
                        end
                    else
                        v:Destroy()
                    end
                
            
        end
        st1.Text = uc(aimbotstatus)
        local espforlder
        local partconverter = Instance.new("Part")
        --local headsupdatelist = {}
        st1_3.FocusLost:connect(function()
            if tonumber(st1_3.Text) then
                bspeed = tonumber(st1_3.Text)
            else
                
            end
        end)
        f.addesp = function()
            pcall(function()
            --print("ESP ran")
            if espforlder then
                espforlder:Destroy()
                espforlder = Instance.new("Folder")
                espforlder.Parent = game.Workspace.CurrentCamera
            else
                espforlder = Instance.new("Folder")
                espforlder.Parent = game.Workspace.CurrentCamera
            end
            for i, v in pairs(espforlder:GetChildren()) do
                v:Destroy()
            end
            for _, plr in pairs(plrs:GetChildren()) do
                if plr.Character and plr.Character.Humanoid.Health > 0 and plr.Name ~= lplr.Name then
                    if TeamBased == true then
                        
                        if plr.Team.Name ~= plrs.LocalPlayer.Team.Name  then
                            pcall(function()
                            local e = espforlder:FindFirstChild(plr.Name)
                            if not e then
                                local fold = Instance.new("Folder", espforlder)
                                fold.Name = plr.Name
                                
                                --partconverter.BrickColor = plr.Team.Color
                                --local teamc = partconverter.Color
                                for i, p in pairs(plr.Character:GetChildren()) do
                                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                                        if charmsesp then
                                        local urmom = Instance.new("BoxHandleAdornment")
                                        urmom.ZIndex = 10
                                        urmom.AlwaysOnTop = true
                                        urmom.Color3 = espcolor
                                        urmom.Size = p.Size
                                        urmom.Adornee = p
                                        urmom.Name = tick().." Ur mom has big gay"
                                        urmom.Transparency = wallhack_esp_transparency
                                        urmom.Parent = fold
                                        if p.Name == "Head" then
                                            local th = p:FindFirstChild("headoverthing")
                                            if not th then
                                                local ht = espheadthing:Clone()
                                                ht.PName.Text = p.Parent.Name
                                                ht.Adornee = p
                                                --table.insert(headsupdatelist, ht)
                                                delay(0, function()
                                                    while wait(0.08) and plr and p do
                                                        f.UpdateHeadUI(ht)
                                                    end
                                                end)
                                                ht.Parent = p
                                            end
                                        end
                                        end
                                    end
                                end
                                plr.Character.Humanoid.Died:Connect(function()
                                    fold:Destroy()
                                end)
                                
                            end
                            end)
                        end
                    else
                        local e = espforlder:FindFirstChild(plr.Name)
                        if not e then
                            local fold = Instance.new("Folder", espforlder)
                                fold.Name = plr.Name
                                
                                --partconverter.BrickColor = plr.Team.Color
                                --local teamc = Move.BackgroundColor3
                                for i, p in pairs(plr.Character:GetChildren()) do
                                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                                        pcall(function()
                                        if charmsesp then
                                        local urmom = Instance.new("BoxHandleAdornment")
                                        urmom.ZIndex = 10
                                        urmom.AlwaysOnTop = true
                                        urmom.Color3 = espcolor
                                        urmom.Size = p.Size
                                        urmom.Adornee = p
                                        urmom.Name = tick().." Ur mom has big gay"
                                        urmom.Transparency = wallhack_esp_transparency
                                        urmom.Parent = fold
                                        end
                                        if p.Name == "Head" then
                                            local th = p:FindFirstChild("headoverthing")
                                            if not th then
                                                local ht = espheadthing:Clone()
                                                ht.PName.Text = p.Parent.Name
                                                ht.Adornee = p
                                                delay(0, function()
                                                    while wait(0.08) and plr and p do
                                                        f.UpdateHeadUI(ht)
                                                    end
                                                end)
                                                --table.insert(headsupdatelist, ht)
                                                ht.Parent = p
                                            end
                                        end
                                        end)
                                    end
                                end
                                plr.Character.Humanoid.Died:Connect(function()
                                    fold:Destroy()
                                end)
                        end
                    end
                    
                    
                end
            end
            end)
        end
        
        local uis = game:GetService("UserInputService")
        local bringall = false
        local hided2 = false
        local upping = false
        local downing = false
        mouse.KeyDown:Connect(function(a)
            
            if a == "" then
                --print("worked1")
                f.addesp()
            elseif a == gui_hide_button[2] and uis:IsKeyDown(gui_hide_button[1]) then
                if hided2 == false then
                    hided2 = true
                    autoesp =false
                    if espforlder then
                        espforlder:Destroy()
                    end
                    Gui.Enabled = false
                else
                    Gui.Enabled = true
                    hided2 = false
                end
                    
            elseif a == "y" then
                if aimbothider == false then
                    aimbothider = true
                    if aimbothider == true then
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." on"
                else
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." off"
                end
                else
                    
                    aimbothider = false
                    if aimbothider == true then
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." on"
                else
                    aimbothiderbox.Text = "Speed :"..tostring(aimbothiderspeed).." off"
                end
                end
                if aimbothider == true then
                    aimbothiderbox.TextColor3 =Color3.fromRGB(11, 255, 19)
                else
                    aimbothiderbox.TextColor3 =Color3.fromRGB(255, 0, 0)
                end
            elseif a == "l" then
                if not uis:IsKeyDown(Enum.KeyCode.LeftControl) then
                    if autoesp == false then
                        autoesp = true
                    else
                        autoesp = false
                    end
                else
                    if lightesp == true then
                        lightesp = false
                    else
                        lightesp = true
                    end
                end
            elseif a == "]" then
                upping = true
                downing = false
            elseif a== "[" then
                downing = true
                upping = false
            elseif a == Aim_Assist_Key[2] and uis:IsKeyDown(Aim_Assist_Key[1]) then
                if Aim_Assist == true then
                    Aim_Assist = false
                    --print("disabled")
                else
                    Aim_Assist = true
                end
            end
            if a == "" then
                if mouse.Target then
                    mouse.Target:Destroy()
                end
            end
            if a == key then
                if switch == false then
                    switch = true
                else
                    switch = false
                    if aimatpart ~= nil then
                        aimatpart = nil
                    end
                end
            elseif a == "b" and uis:IsKeyDown(Enum.KeyCode.LeftControl) and not uis:IsKeyDown(Enum.KeyCode.R) then
                if movementcounting then
                    movementcounting = false
                else
                    movementcounting = true
                end
            elseif a == teambasedswitch then
                if TeamBased == true then
                    TeamBased = false
                    teambasedstatus.Text = "Team Based: "..tostring(TeamBased)
                else
                    TeamBased = true
                    teambasedstatus.Text = "Team Based: "..tostring(TeamBased)
                end
            elseif a == "b" and uis:IsKeyDown(Enum.KeyCode.LeftControl) and uis:IsKeyDown(Enum.KeyCode.R) then
                ballisticsboost = 0
            elseif a == aimkey then
                if not aimatpart then
                    local maxangle = math.rad(20)
                    for i, plr in pairs(plrs:GetChildren()) do
                        if plr.Name ~= lplr.Name and plr.Character and plr.Character.Head and plr.Character.Humanoid and plr.Character.Humanoid.Health > 1 then
                            if TeamBased == true then
                                if plr.Team.Name ~= lplr.Team.Name then
                                    local an = checkfov(plr.Character.Head)
                                    if an < maxangle then
                                        maxangle = an
                                        aimatpart = plr.Character.Head
                                    end
                                end
                            else
                                local an = checkfov(plr.Character.Head)
                                    if an < maxangle then
                                        maxangle = an
                                        aimatpart = plr.Character.Head
                                    end
                                    --print(plr)
                            end
                            local old = aimatpart
                            plr.Character.Humanoid.Died:Connect(function()
                                --print("died")
                                if aimatpart and aimatpart == old then
                                    aimatpart = nil
                                end
                            end)
                            
                        end
                    end
                else
                    aimatpart = nil
                    canaimat = false
                    delay(1.1, function()
                        canaimat = true
                    end)
                end
            end
        end)
        
        function getfovxyz (p0, p1, deg)
            local x1, y1, z1 = p0:ToOrientation()
            local cf = CFrame.new(p0.p, p1.p)
            local x2, y2, z2 = cf:ToOrientation()
            local d = math.deg
            if deg then
                return Vector3.new(d(x1-x2), d(y1-y2), d(z1-z2))
            else
                return Vector3.new((x1-x2), (y1-y2), (z1-z2))
            end
        end
        
        
        function aimat(part)
            if part then
                --print(part)
                local d = (cam.CFrame.p - part.CFrame.p).magnitude
                local calculatedrop
                local timetoaim = 0
                local pos2 = Vector3.new()
                if movementcounting == true then
                    timetoaim = d/bspeed
                    pos2 = part.Velocity * timetoaim
                end
                local minuseddrop = (ballisticsboost+50)/50
                if ballisticsboost ~= 0 then
                    calculatedrop = d - (d/minuseddrop)
                    
                else
                    calculatedrop = 0
                end
                --print(calculatedrop)
                local addative = Vector3.new()
                if movementcounting then
                    addative = pos2
                end
                local cf = CFrame.new(cam.CFrame.p, (addative + part.CFrame.p+ Vector3.new(0, calculatedrop, 0)))
                if aimbothider == true or Aim_Assist == true then
                    cam.CFrame = cam.CFrame:Lerp(cf, aimbothiderspeed)
                else
                    
                    cam.CFrame = cf
                end
                --print(cf)
            end
        end
        function checkfov (part)
            local fov = getfovxyz(game.Workspace.CurrentCamera.CFrame, part.CFrame)
            local angle = math.abs(fov.X) + math.abs(fov.Y)
            return angle
        end
        pcall(function()
            delay(0, function()
                while wait(.32) do
                    if Aim_Assist and not aimatpart and canaimat and lplr.Character and lplr.Character.Humanoid and lplr.Character.Humanoid.Health > 0 then
                        for i, plr in pairs(plrs:GetChildren()) do
                            
                            
                                local minangle = math.rad(5.5)
                                local lastpart = nil
                                local function gg(plr)
                                    pcall(function()
                                    if plr.Name ~= lplr.Name and plr.Character and plr.Character.Humanoid and plr.Character.Humanoid.Health > 0 and plr.Character.Head then
                                        local raycasted = false
                                        local cf1 = CFrame.new(cam.CFrame.p, plr.Character.Head.CFrame.p) * CFrame.new(0, 0, -4)
                                        local r1 = Ray.new(cf1.p, cf1.LookVector * 9000)
                                        local obj, pos = game.Workspace:FindPartOnRayWithIgnoreList(r1,  {lplr.Character.Head})
                                        local dist = (plr.Character.Head.CFrame.p- pos).magnitude
                                        if dist < 4 then
                                            raycasted = true
                                        end
                                        if raycasted == true then
                                            local an1 = getfovxyz(cam.CFrame, plr.Character.Head.CFrame)
                                            local an = abs(an1.X) + abs(an1.Y)
                                            if an < minangle then
                                                minangle = an
                                                lastpart = plr.Character.Head
                                            end
                                        end
                                    end
                                    end)
                                end
                                if TeamBased then
                                    if plr.Team.Name ~= lplr.Team.Name then
                                        gg(plr)
                                    end
                                else
                                    gg(plr)
                                end
                                --print(math.deg(minangle))
                                if lastpart then
                                    aimatpart = lastpart
                                    aimatpart.Parent.Humanoid.Died:Connect(function()
                                        if aimatpart == lastpart then
                                            aimatpart = nil
                                        end
                                    end)
                                
                            end
                        end
                    end
                end
            end)
        end)
        local oldheadpos
        local lastaimapart
        game:GetService("RunService").RenderStepped:Connect(function(dt)
            if uis:IsKeyDown(Enum.KeyCode.RightBracket) or uis:IsKeyDown(Enum.KeyCode.LeftBracket) then
                if upping then
                    ballisticsboost = ballisticsboost + dt/1.9
                elseif downing then
                    ballisticsboost = ballisticsboost - dt/1.9
                end
            end
            if movementcounting then
                st1_2.TextColor3 = Color3.new(0.0431373, 1, 0.0745098)
                st1_2.Text = "Current ballistics: "..tostring(math.floor(ballisticsboost*10)/10)
            else
                st1_2.TextColor3 = Color3.new(1,0,0)
            end
            espstatustext.Text = "Esp loop :"..tostring(autoesp)
            if aimatpart and lplr.Character and lplr.Character.Head then
                if BetterDeathCount and lastaimapart and lastaimapart == aimatpart then
                    local dist = (oldheadpos - aimatpart.CFrame.p).magnitude
                    if dist > 40 then
                        aimatpart = nil
                    end
                end
                lastaimapart = aimatpart
                oldheadpos = lastaimapart.CFrame.p
                do 
                    if aimatpart.Parent == plrs.LocalPlayer.Character then
                        aimatpart = nil
                    end
                    aimat(aimatpart)
                    pcall(function()
                        if Aim_Assist == true then
                            local cf1 = CFrame.new(cam.CFrame.p, aimatpart.CFrame.p) * CFrame.new(0, 0, -4)
                            local r1 = Ray.new(cf1.p, cf1.LookVector * 1000)
                            local obj, pos = game.Workspace:FindPartOnRayWithIgnoreList(r1,  {lplr.Character.Head})
                            local dist = (aimatpart.CFrame.p- pos).magnitude
                            if obj then
                                --print(obj:GetFullName())
                            end
                            if not obj or dist > 6 then
                                aimatpart = nil
                                --print("ooof")
                            end
                            canaimat = false
                            delay(.5, function()
                                canaimat = true
                            end)
                        end
                    end)
                end
                
                
                
            end
        end)
        
        
        delay(0, function()
            while wait(espupdatetime) do
                if autoesp == true then
                    pcall(function()
                    f.addesp()
                    end)
                end
            end
        end)
        --warn("loaded")
        end)
end)

ExtraSection:NewButton("Good Streamable", "[Hardly any groundshots]", function()
-- // Dependencies
_G.PRED = 0.025
local Aiming = loadstring(game:HttpGet("https://github.com/Ezucii/new/blob/main/sourceeeeeeeeeeeeee.lua"))()
Aiming.TeamCheck(false)
Aiming.ShowFOV = false
Aiming.FOV = 25
-- // Services
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- // Vars
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CurrentCamera = Workspace.CurrentCamera

local DaHoodSettings = {
    SilentAim = true,
    AimLock = false,
    Prediction = 0.025,
    AimLockKeybind = Enum.KeyCode.E
}
getgenv().DaHoodSettings = DaHoodSettings

-- // Overwrite to account downed
function Aiming.Check()
    -- // Check A
    if not (Aiming.Enabled == true and Aiming.Selected ~= LocalPlayer and Aiming.SelectedPart ~= nil) then
        return false
    end

    -- // Check if downed
    local Character = Aiming.Character(Aiming.Selected)
    local KOd = Character:WaitForChild("BodyEffects")["K.O"].Value
    local Grabbed = Character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil

    -- // Check B
    if (KOd or Grabbed) then
        return false
    end

    -- //
    return true
end

-- // Hook
local __index
__index = hookmetamethod(game, "__index", function(t, k)
    -- // Check if it trying to get our mouse's hit or target and see if we can use it
    if (t:IsA("Mouse") and (k == "Hit" or k == "Target") and Aiming.Check()) then
        -- // Vars
        local SelectedPart = Aiming.SelectedPart

        -- // Hit/Target
        if (DaHoodSettings.SilentAim and (k == "Hit" or k == "Target")) then
            -- // Hit to account prediction
            local Hit = SelectedPart.CFrame + (SelectedPart.Velocity * DaHoodSettings.Prediction)

            -- // Return modded val
            return (k == "Hit" and Hit or SelectedPart)
        end
    end

    -- // Return
    return __index(t, k)
end)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

mouse.KeyDown:Connect(function(key)
    if key == "v" then
        if Aiming.Enabled == false then
        Aiming.Enabled = true
        else
        Aiming.Enabled = false
        end
    end
end)


RunService.RenderStepped:Connect(function()

    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString()
    local Value = tostring(ping)
    local pingValue = Value:split(" ")
    local PingNumber = pingValue[1]
    
    DaHoodSettings.Prediction = PingNumber / 1000 + _G.PRED
    
                    if Aiming.Character.Humanoid.Jump == true and AimlockTarget.Character.Humanoid.FloorMaterial == Enum.Material.Air then
                    Aiming.TargetPart = "RightFoot"
                else
                    Aiming.Character:WaitForChild("Humanoid").StateChanged:Connect(function(new)
                    
                    if new == Enum.HumanoidStateType.Freefall then
                    Aiming.TargetPart = "RightFoot"
                    else
                    
                    Aiming.TargetPart = Aiming.SelectedPart
                    
                    end
                    
                    end)
                    
                end

end)
end)

local ExtraSection = Extra:NewSection("Desyncs")

ExtraSection:NewButton("Desync1", "Desync", function()
    getgenv().slammeAA = true 

    game:GetService("RunService").heartbeat:Connect(function()
        if getgenv().slammeAA == true then 
        local abc = game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity
        game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(1,1,1) * (2^16)
        game:GetService("RunService").RenderStepped:Wait()
        game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = abc
        end 
    end)
end)

ExtraSection:NewButton("Desync2", "Desync", function()
    getgenv().slammeAA = true 

    game:GetService("RunService").heartbeat:Connect(function()
        if getgenv().slammeAA == true then 
        local abc = game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity
        game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(1,1,1) * (2^16)
        game:GetService("RunService").RenderStepped:Wait()
        game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = abc
        end 
    end)
end)

ExtraSection:NewButton("Desync3", "Desync", function()
    _G.Desync = true

    game.RunService.Heartbeat:Connect(function()
    if _G.Desync then
    local CurrentVelocity = game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(0),0)
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0,math.rad(7),0)
    game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(7000,7000,7000)
    game.RunService.RenderStepped:Wait()
    game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = CurrentVelocity
        end
    end)
end)

local players = game:GetService("Players")
local scriptSerivce = game:GetService("ServerScriptService")

local ChatService = require(scriptSerivce.ChatServiceRunner.ChatService)

ChatService.SpeakerAdded:Connect(function (speakerName)
	local PLAYER_USER_ID = players:FindFirstChild(speakerName).UserId
	local speaker = ChatService:GetSpeaker(speakerName)
	
	if PLAYER_USER_ID == game.CreatorId then
		
		local TheirTag = {
			{
				TagText = "[👑]";
				TagColor = Color3.fromRGB(math.random(1, 255), math.random(1, 255), math.random(1, 255));
			};
			{
				TagText = "Game Owner";
				TagColor = Color3.fromRGB(math.random(1, 255), math.random(1, 255), math.random(1, 255))
			}
		}
		
		speaker:SetExtraData("Tags", TheirTag)
	end
end)
