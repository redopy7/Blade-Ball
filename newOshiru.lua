if not checkintegrity() then LPH_CRASH() end
repeat task.wait() until game:IsLoaded()

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Workspace = game:GetService("Workspace")
local ServerStatsItem = game:GetService("Stats").Network.ServerStatsItem
local Player = Players.LocalPlayer
local Last_Input = UserInputService:GetLastInputType()
local Alive = workspace:WaitForChild("Alive")

local distanceBuffer = {}
local bufferSize = 10
local backward = false
local status = "Idle"
local LastCurve, LastWarp, LastBack = 0, 0, 0
local VelHist, PingHist = {}, {}
local LerpRadians = 0
local PrevUpdate = tick()

local TrainingBall = false
local FPSBoost = false
local Parry_Method = "Remote"
local Selected_Parry_Type = "Camera"
local Speed_Divisor_Multiplier = 1.1
local ParryThreshold = 1.2
local SpamCheck = 1.5
local OshiruSpeed = 1

local Remotes = {}
local revertedRemotes = {}
local originalMetatables = {}
local Connections_Manager = {}
local Animation = {storage = {}, current = nil, track = nil}
local Parries = 0
local toggleOshiru = false
local spamConnection = nil
local Parried = false
local Last_Parry = 0
local Closest_Entity = nil
local Previous_Velocity = {}

local NoRender = nil
local descendantAddedConnection = nil
local EffectClasses = {["ParticleEmitter"] = true, ["Beam"] = true, ["Trail"] = true, ["Explosion"] = true}
local Lerp_Radians = 0
local Last_Warping = tick()
local Curving = tick()
local Vector2_Mouse_Location = nil
local Tornado_Time = tick()
local deathshit = false
local Infinity = false
local timehole = false
local AutoParry = true
local InputTask = nil
local Cooldown = 0.02
local currentNightMode = game:GetService("Players").LocalPlayer.PlayerGui.Settings.Frame.Frame["Misc/Night Mode"].Button.Icon.Visible

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid")
local Workspace = game:GetService("Workspace")
local ServerStatsItem = game:GetService("Stats").Network.ServerStatsItem
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Aerodynamic = false
local Aerodynamic_Time = tick()
local Last_Input = UserInputService:GetLastInputType()
local Debris = game:GetService("Debris")
local Alive = workspace.Alive
local Vector2_Mouse_Location = nil
local Grab_Parry = nil
local Parry_Remote = nil
local Parry_Key = nil
local Parry_Arg = nil
local Selected_Parry_Type = nil
local Lighting = game:GetService("Lighting") 

getgenv().ToggleFOV = false
getgenv().FOV_Value = 70
getgenv().skinChanger = false
getgenv().swordModel = ""
getgenv().swordAnimations = ""
getgenv().swordFX = ""
getgenv().AutoAbility = false
getgenv().CooldownProtection = false
getgenv().AbilitiesDetection = false
getgenv().Auto_Spam = false
getgenv().Spam_Speed = 1

local function safeGetPosition(object)
    if not object then return nil end
    if not object.Parent then return nil end
    
    local success, position = pcall(function()
        if object:IsA("Model") then
            local primaryPart = object.PrimaryPart
            return primaryPart and primaryPart.Position or nil
        elseif object:IsA("BasePart") then
            return object.Position
        elseif object:IsA("Attachment") then
            return object.WorldPosition
        end
        return nil
    end)
    
    return success and position or nil
end

local function safeGetCharacter()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return nil end
    
    local success = pcall(function()
        return char:IsDescendantOf(workspace)
    end)
    
    return success and char or nil
end

local function safeGetHumanoidRootPart()
    local char = safeGetCharacter()
    if not char then return nil end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not hrp.Parent then return nil end
    
    return hrp
end

local function safeGetDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    
    local success, distance = pcall(function()
        return (pos1 - pos2).Magnitude
    end)
    
    return success and distance or math.huge
end

local idkmaybearemote
local Parry_Remote, Parry_Key, Parry_Arg = nil, nil, nil
local parryRemotes = {}

task.spawn(function()
    while task.wait() and not idkmaybearemote do
        for _, v in getconnections(UserInputService.TouchTapInWorld) do
            if v.Function and islclosure(v.Function) and getconstants(v.Function)[#getconstants(v.Function)] == "Enabled" then
                idkmaybearemote = v.Function
                v:Disable()
            end
        end
    end

    local parryfuncshi = getupvalue(getupvalue(idkmaybearemote, 2), 2)
    local secondParryArg = getupvalue(parryfuncshi, 17)

    for _, v in getupvalues(parryfuncshi) do
        if typeof(v) == "Instance" and v:IsA("RemoteEvent") then
            table.insert(parryRemotes, v)
        end
    end

    local somebitchesletter = { "xpcall", "Parent", "CFrame", "lookAt", "Origin", "Length" }
    local parryStrings = {}
    for _, v in getconstants(parryfuncshi) do
        if type(v) == "string" and #v == 6 and not table.find(somebitchesletter, v) and #parryStrings < 3 then
            table.insert(parryStrings, v)
        end
    end

    if not secondParryArg or #secondParryArg ~= 6 then return warn("[Oshiru] Failed to resolve dynamic second parry arg") end
    if #parryStrings ~= 3 then parryStrings = (#parryStrings == 0 and {} or warn("[Oshiru] Failed to get constant parry strings") and {}) end
    if #parryRemotes ~= 3 then return warn("[Oshiru] Failed to get parry remotes (count is not 3)") end

    for _, v in parryRemotes do
        if typeof(v) ~= "Instance" or not v:IsA("RemoteEvent") then
            return warn("[Oshiru] Remote resolver failed bitch!")
        end
    end

    Parry_Remote, Parry_Key, Parry_Arg = parryRemotes, secondParryArg, parryStrings
    print("[Oshiru] Parry keys resolved yay nigger!")
end)

local function createAnimation(object, info, value)
    local animation = TweenService:Create(object, info, value)
    animation:Play()
    task.wait(info.Time)
    Debris:AddItem(animation, 0)
    animation:Destroy()
end

local function GetCharacterAndAnimator()
    if Parry_Method == "Remote" then 
        return Players.LocalPlayer.Character, Players.LocalPlayer.Character.Humanoid.Animator 
    else 
        return nil 
    end
end

local Auto_Parry = {}

Auto_Parry.Linear_Interpolation = function(a, b, t)
    return a + (b - a) * t
end

Auto_Parry.Parry_Animation = function()
    local character, animator = GetCharacterAndAnimator()
    if not character or not animator then 
        warn("Auto_Parry.Parry_Animation: Character or Animator not found for Parry_Method: " .. Parry_Method)
        return 
    end
    
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Parry_Animation
    local Current_Sword
    
    if Parry_Method == "Remote" then
        Parry_Animation = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry")
        Current_Sword = Players.LocalPlayer.Character:GetAttribute("CurrentlyEquippedSword")
    end
    
    if not Current_Sword then return end
    if not Parry_Animation then return end
    
    local Sword_Data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)
    if (not Sword_Data or not Sword_Data['AnimationType']) then return end
    
    for _, object in pairs(ReplicatedStorage.Shared.SwordAPI.Collection:GetChildren()) do
        if (object.Name == Sword_Data['AnimationType']) then
            local sword_animation_type = (object:FindFirstChild("GrabParry") and "GrabParry") or "Grab"
            Parry_Animation = object[sword_animation_type]
        end
    end
    
    local Grab_Parry = animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end

Auto_Parry.Play_Animation = function(v)
    local character, animator = GetCharacterAndAnimator()
    if not character or not animator then 
        warn("Auto_Parry.Play_Animation: Character or Animator not found for Parry_Method: " .. Parry_Method)
        return false 
    end
    
    local Animations = Animation.storage[v]
    if not Animations then return false end
    
    if Animation.track and Animation.track:IsA("AnimationTrack") then 
        Animation.track:Stop() 
    end
    
    Animation.track = animator:LoadAnimation(Animations)
    if Animation.track and Animation.track:IsA("AnimationTrack") then 
        Animation.track:Play() 
    end
    
    Animation.current = v
    return true
end

Auto_Parry.Get_Ball = function()
    local ballFolder
    
    if not TrainingBall then
        ballFolder = workspace:FindFirstChild("Balls")
    else
        local isInAlive = workspace.Alive:FindFirstChild(tostring(LocalPlayer))
        ballFolder = workspace:FindFirstChild(isInAlive and "Balls" or "TrainingBalls")
    end
    
    if not ballFolder then return nil end
    
    for _, ball in ipairs(ballFolder:GetChildren()) do
        if ball and ball.Parent and ball:GetAttribute("realBall") then
            ball.CanCollide = false
            return ball
        end
    end
    return nil
end

Auto_Parry.Get_Balls = function()
    local ballFolder
    
    if not TrainingBall then
        ballFolder = workspace:FindFirstChild("Balls")
    else
        local isInAlive = workspace.Alive:FindFirstChild(tostring(LocalPlayer))
        ballFolder = workspace:FindFirstChild(isInAlive and "Balls" or "TrainingBalls")
    end
    
    if not ballFolder then return {} end
    
    local balls = {}
    for _, ball in ipairs(ballFolder:GetChildren()) do
        if ball and ball.Parent and ball:GetAttribute("realBall") then
            ball.CanCollide = false
            balls[#balls + 1] = ball
        end
    end
    return balls
end

function Auto_Parry.Closest_Player()
    local char = safeGetCharacter()
    if not char or char.Parent ~= Alive then
        return false
    end
    
    local Max_Distance = math.huge
    local Closest_Player = nil
    
    for _, Entity in Alive:GetChildren() do
        if Entity and Entity ~= char and Entity.PrimaryPart then
            local entityPos = safeGetPosition(Entity)
            local charPos = safeGetPosition(char)
            
            if entityPos and charPos then
                local distance = safeGetDistance(entityPos, charPos)
                if distance < Max_Distance then
                    Max_Distance = distance
                    Closest_Player = Entity
                end
            end
        end
    end
    Closest_Entity = Closest_Player
    return Closest_Entity
end

Auto_Parry.Parry_Data = function(Parry_Type)
    local Events = {}
    local Camera = workspace.CurrentCamera
    local Vector2_Mouse_Location

    if Last_Input == Enum.UserInputType.MouseButton1 or 
       Last_Input == Enum.UserInputType.MouseButton2 or 
       Last_Input == Enum.UserInputType.Keyboard then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        if Camera then 
            Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2} 
        else 
            Vector2_Mouse_Location = {0, 0} 
        end
    end

    for _, Value in pairs(workspace.Alive:GetChildren()) do 
        if Value and Value.PrimaryPart then 
            local valuePos = safeGetPosition(Value)
            if valuePos then
                local success, screenPoint = pcall(function()
                    return Camera:WorldToScreenPoint(valuePos)
                end)
                if success then
                    Events[tostring(Value)] = screenPoint
                end
            end
        end 
    end

    local directionMap = {
        ["Camera"] = function() return Camera.CFrame end, 
        ["Random"] = function() 
            return CFrame.new(Camera.CFrame.Position, Vector3.new(
                math.random(-3000, 3000), 
                math.random(-3000, 3000), 
                math.random(-3000, 3000)
            )) 
        end, 
        ["Straight"] = function() 
            if Closest_Entity and Closest_Entity.PrimaryPart then
                local playerChar = safeGetCharacter()
                local playerPos = safeGetPosition(playerChar)
                local entityPos = safeGetPosition(Closest_Entity)
                
                if playerPos and entityPos then
                    return CFrame.new(playerPos, entityPos)
                end
            end
            return Camera.CFrame
        end, 
        ["Backwards"] = function() 
            local Backwards_Direction = -Camera.CFrame.LookVector
            Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z)
            return CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction) 
        end,
        ["Up"] = function() 
            return CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.UpVector * 1000)) 
        end,
        ["Right"] = function() 
            return CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.RightVector * 1000)) 
        end,
        ["Left"] = function() 
            return CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - (Camera.CFrame.RightVector * 1000)) 
        end
    }

    local parryCFrame = directionMap[Parry_Type] and directionMap[Parry_Type]() or Camera and Camera.CFrame or CFrame.new()
    return {0, parryCFrame, Events, Vector2_Mouse_Location}
end

Auto_Parry.Parry = function(parryType)
    if not Parry_Remote or type(Parry_Remote) ~= "table" or #Parry_Remote == 0 then
        warn("[Auto_Parry.Parry] Parry_Remote is nil or not valid, cannot parry")
        return false
    end
    
    local hrp = safeGetHumanoidRootPart()
    if not hrp then return end
    if hrp:FindFirstChild("SingularityCape") or hrp:FindFirstChild("MaxShield") then
        return
    end
    
    local Parry_Data = Auto_Parry.Parry_Data(parryType or Selected_Parry_Type)
    if not Parry_Data then
        warn("[Auto_Parry.Parry] Failed to get Parry_Data")
        return false
    end
    
  if Parry_Method == "Remote" then
    local success, err = pcall(function()
        for index, remote in ipairs(Parry_Remote) do
            remote:FireServer(Parry_Arg[index] or "", Parry_Key, Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4], false)
        end
    end)
    if not success then warn("[Auto_Parry.Parry] Failed to fire remote:", err) return false 
    end
    elseif Parry_Method == "F_Key" then
        pcall(function()
            local vim = VirtualInputManager
            vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
            vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    elseif Parry_Method == "VirtualInputManager" then
        pcall(function()
            local vim = VirtualInputManager
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end
    
    if Parries > 7 then return false end
    Parries += 1
    task.delay(0.5, function()
        Parries = math.max(0, Parries - 1)
    end)
end

local function AngleBetween(a, b)
    return math.deg(math.acos(math.clamp(a:Dot(b), -1, 1)))
end

function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()
    if not Ball then return false end
    local Zoomies = Ball:FindFirstChild("zoomies")
    if not Zoomies then return false end
    local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit
    local playerPos = Player.Character and Player.Character.PrimaryPart and Player.Character.PrimaryPart.Position
    if not playerPos then return false end
    local ballPos = Ball.Position
    local Direction = (playerPos - ballPos).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Speed = Velocity.Magnitude
    local Distance = (playerPos - ballPos).Magnitude
    local Reach_Time = Distance / Speed - (Ping / 1000)
    local Speed_Threshold = math.min(Speed / 100, 40)
    local Angle_Threshold = 55 * math.max(Dot, 0)
    local Ball_Distance_Threshold = 10 - math.min(Distance / 1000, 15) + Speed_Threshold + Angle_Threshold
    local Enough_Speed = Speed > 160
    if Enough_Speed and Reach_Time > (Ping / 10 + 0.03) then
        local reduction = 15 + (Speed - 160) * (5 / 840)
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - reduction, 15)
    end
    table.insert(Previous_Velocity, Velocity)
    if #Previous_Velocity > 4 then
        table.remove(Previous_Velocity, 1)
    end
    if Ball:FindFirstChild("AeroDynamicSlashVFX") then
        game:GetService("Debris"):AddItem(Ball.AeroDynamicSlashVFX, 0)
        Tornado_Time = tick()
    end
    local Runtime = workspace.Runtime
    if Runtime:FindFirstChild("Tornado") then
        if (tick() - Tornado_Time) < ((Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159) then
            return true
        end
    end
    if Distance < Ball_Distance_Threshold then
        return false
    end
    local adjustedReachTime = Reach_Time + 0.03
    local divisor = 1.2 + (Speed - 160) * (0.3 / 840)
    if (tick() - Curving) < (adjustedReachTime / divisor) then
        return true
    end
    local Dot_Threshold = 0 - Ping / 1000
    local Direction_Difference = (Ball_Direction - Velocity.Unit).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)
    local Dot_Difference = Dot - Direction_Similarity
    if Dot_Difference < Dot_Threshold then
        return true
    end
    local Clamped_Dot = math.clamp(Dot, -1, 1)
    local Radians = math.deg(math.asin(Clamped_Dot))
    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)
    local angleThreshold = Speed < 300 and 0.02 or 0.018
    if Lerp_Radians < angleThreshold then
        Last_Warping = tick()
    end
    local timeDivisor = Speed < 300 and 1.19 or 1.5
    if (tick() - Last_Warping) < (adjustedReachTime / timeDivisor) then
        return true
    end
    if #Previous_Velocity >= 4 then
        for i = 1, 2 do
            local prevDir = (Ball_Direction - Previous_Velocity[i].Unit).Unit
            local prevDot = Direction:Dot(prevDir)
            if (Dot - prevDot) < Dot_Threshold then
                return true
            end
        end
    end
    return Dot < Dot_Threshold
end

for _, animation in pairs(ReplicatedStorage.Misc.Emotes:GetChildren()) do
    if animation:IsA("Animation") and animation:GetAttribute("EmoteName") then
        Animation.storage[animation:GetAttribute("EmoteName")] = animation
    end
end

local Emotes_Data = {}
for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end
table.sort(Emotes_Data)

Auto_Parry.Get_Entity_Properties = function(self)
	Auto_Parry.Closest_Player();
	if not Closest_Entity then
		return false;
	end
	local entityVelocity = Closest_Entity.PrimaryPart.Velocity;
	local entityDirection = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit;
	local entityDistance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude;
	return {Velocity=entityVelocity,Direction=entityDirection,Distance=entityDistance};
end;

Auto_Parry.Get_Ball_Properties = function(self)
	local ball = Auto_Parry.Get_Ball();
	if not ball then
		return false;
	end
	local character = LocalPlayer.Character;
	if (not character or not character.PrimaryPart) then
		return false;
	end
	local ballVelocity = ball.AssemblyLinearVelocity;
	local ballDirection = (character.PrimaryPart.Position - ball.Position).Unit;
	local ballDistance = (character.PrimaryPart.Position - ball.Position).Magnitude;
	local ballDot = ballDirection:Dot(ballVelocity.Unit);
	return {Velocity=ballVelocity,Direction=ballDirection,Distance=ballDistance,Dot=ballDot};
end;

Auto_Parry.Spam_Service = function(self)
    local ball = Auto_Parry.Get_Ball();
    if not ball then
        return false;
    end
    Auto_Parry.Closest_Player();
    local spamDelay = 0;
    local spamAccuracy = 100;
    if not self.Spam_Sensitivity then
        self.Spam_Sensitivity = 75;
    end
    if not self.Ping_Based_Spam then
        self.Ping_Based_Spam = false;
    end
    local velocity = ball.AssemblyLinearVelocity;
    local speed = velocity.Magnitude;
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit;
    local dot = direction:Dot(velocity.Unit);
    local targetPosition = Closest_Entity and Closest_Entity.PrimaryPart and Closest_Entity.PrimaryPart.Position;
    if not targetPosition then
        return spamAccuracy;
    end
    local targetDistance = LocalPlayer:DistanceFromCharacter(targetPosition);
    local maximumSpamDistance = self.Ping + math.min(speed / 5, 100);
    maximumSpamDistance = maximumSpamDistance * self.Spam_Sensitivity;
    if self.Ping_Based_Spam then
        maximumSpamDistance = maximumSpamDistance + self.Ping;
    end
    if ((self.Entity_Properties.Distance > maximumSpamDistance) or (self.Ball_Properties.Distance > maximumSpamDistance) or (targetDistance > maximumSpamDistance)) then
        return spamAccuracy;
    end
    local maximumSpeed = 5 - math.min(speed / 5, 5);
    local maximumDot = math.clamp(dot, -1, 0) * maximumSpeed;
    spamAccuracy = maximumSpamDistance - maximumDot;
    task.wait(0.0000000000000000001);
    return spamAccuracy;
end;

ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
    if d then
        deathshit = true
    else
        deathshit = false
    end
end)

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    if b then
        Infinity = true
    else
        Infinity = false
    end
end)

ReplicatedStorage.Remotes.TimeHoleHoldBall.OnClientEvent:Connect(function(e, f)
    if f then
        timehole = true
    else
        timehole = false
    end
end)

local Balls = workspace:WaitForChild('Balls')
local CurrentBall = nil
local RunTime = workspace:FindFirstChild("Runtime")

local function GetBall()
    for _, Ball in ipairs(Balls:GetChildren()) do
        if Ball:FindFirstChild("ff") then
            return Ball
        end
    end
    return nil
end

local function SpamInput(Label)
    if InputTask then return end
    InputTask = task.spawn(function()
        while AutoParry do
            Auto_Parry.Parry(Selected_Parry_Type)
            task.wait(Cooldown)
        end
        InputTask = nil
    end)
end

Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().AbilitiesDetection and Child.Name == 'ComboCounter' then
            local Sof_Label = Child:FindFirstChildOfClass('TextLabel')

            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)

                    if Slashes_Counter and Slashes_Counter < 32 then
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end

                    task.wait()

                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)
local player10239123 = Players.LocalPlayer
if not player10239123 then return end
RunTime.ChildAdded:Connect(function(Object)
    local Name = Object.Name
    if getgenv().PhantomV2Detection then
        if Name == "maxTransmission" or Name == "transmissionpart" then
            local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character = player10239123.Character or player10239123.CharacterAdded:Wait()
                if Character and Weld.Part1 == Character.HumanoidRootPart then
                    CurrentBall = GetBall()
                    Weld:Destroy()
                    if CurrentBall then
                        local FocusConnection
                        FocusConnection = RunService.RenderStepped:Connect(function()
                            local Highlighted = CurrentBall:GetAttribute("highlighted")
                            if Highlighted == true then
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                if HumanoidRootPart then
                                    local PlayerPosition = HumanoidRootPart.Position
                                    local BallPosition = CurrentBall.Position
                                    local PlayerToBall = (BallPosition - PlayerPosition).Unit
                                    game.Players.LocalPlayer.Character.Humanoid:Move(PlayerToBall, false)
                                end
                            elseif Highlighted == false then
                                FocusConnection:Disconnect()
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 10
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                task.delay(3, function()
                                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                end)
                                CurrentBall = nil
                            end
                        end)
                        task.delay(3, function()
                            if FocusConnection and FocusConnection.Connected then
                                FocusConnection:Disconnect()
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                CurrentBall = nil
                            end
                        end)
                    end
                end
            end
        end
    end
end)

local SlashesNet = ReplicatedStorage:WaitForChild("Packages")._Index:FindFirstChild("sleitnick_net@0.1.0")
local SlashesRemote = SlashesNet and SlashesNet:FindFirstChild("net"):FindFirstChild("RE/SlashesOfFuryActivate")
local SlashesStartTime = 0
if SlashesRemote then
    SlashesRemote.OnClientEvent:Connect(function()
        SlashesStartTime = tick()
    end)
end
local function IsSlashesOfFuryActive()
    return (tick() - SlashesStartTime) <= 1 
end

local player11 = game.Players.LocalPlayer
local PlayerGui = player11:WaitForChild("PlayerGui")
local playerGui = player11:WaitForChild("PlayerGui")
local Hotbar = PlayerGui:WaitForChild("Hotbar")

local ParryCD = playerGui.Hotbar.Block.UIGradient
local AbilityCD = playerGui.Hotbar.Ability.UIGradient

local function isCooldownInEffect1(uigradient)
    return uigradient.Offset.Y < 0.4
end

local function isCooldownInEffect2(uigradient)
    return uigradient.Offset.Y == 0.5
end

local function cooldownProtection()
    if isCooldownInEffect1(ParryCD) then
        game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

local function AutoAbility()
    if isCooldownInEffect2(AbilityCD) then
        if Player.Character.Abilities["Raging Deflection"].Enabled or Player.Character.Abilities["Rapture"].Enabled or Player.Character.Abilities["Calming Deflection"].Enabled or Player.Character.Abilities["Aerodynamic Slash"].Enabled or Player.Character.Abilities["Fracture"].Enabled or Player.Character.Abilities["Death Slash"].Enabled or Player.Character.Abilities["Flash Counter"].Enabled then
            Parried = true
            game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
            task.wait(2.432)
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
            return true
        end
    end
    return false
end

local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared",9e9):WaitForChild("ReplicatedInstances",9e9):WaitForChild("Swords",9e9)
local swordInstances = require(swordInstancesInstance)

local swordsController

while task.wait() and (not swordsController) do
    for i,v in getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent) do
        if v.Function and islclosure(v.Function) then
            local upvalues = getupvalues(v.Function)
            if #upvalues == 1 and type(upvalues[1]) == "table" then
                swordsController = upvalues[1]
                break
            end
        end
    end
end

function getSlashName(swordName)
    local slashName = swordInstances:GetSword(swordName)
    return (slashName and slashName.SlashName) or "SlashEffect"
end

function setSword()
    if not getgenv().skinChanger then return end
    
    setupvalue(rawget(swordInstances,"EquipSwordTo"),2,false)
    
    swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)
    swordsController:SetSword(getgenv().swordAnimations)
end

local playParryFunc
local parrySuccessAllConnection

while task.wait() and not parrySuccessAllConnection do
    for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parrySuccessAllConnection = v
            playParryFunc = v.Function
            v:Disable()
        end
    end
end

local parrySuccessClientConnection
while task.wait() and not parrySuccessClientConnection do
    for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parrySuccessClientConnection = v
            v:Disable()
        end
    end
end

getgenv().slashName = getSlashName(getgenv().swordFX)

local lastOtherParryTimestamp = 0
local clashConnections = {}

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
    setthreadidentity(2)
    local args = {...}
    if tostring(args[4]) ~= LocalPlayer.Name then
        lastOtherParryTimestamp = tick()
    elseif getgenv().skinChanger then
        args[1] = getgenv().slashName
        args[3] = getgenv().swordFX
    end
    return playParryFunc(unpack(args))
end)

table.insert(clashConnections, getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent)[1])

getgenv().updateSword = function()
    getgenv().slashName = getSlashName(getgenv().swordFX)
    setSword()
end

task.spawn(function()
    while task.wait(1) do
        if getgenv().skinChanger then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                setSword()
            end
            if char and (not char:FindFirstChild(getgenv().swordModel)) then
                setSword()
            end
            for _,v in (char and char:GetChildren()) or {} do
                if v:IsA("Model") and v.Name ~= getgenv().swordModel then
                    v:Destroy()
                end
                task.wait()
            end
        end
    end
end)

local soundOptions = {
   ["Eeyuh"] = "rbxassetid://16190782181",
   ["Sweep"] = "rbxassetid://103508936658553",
   ["Bounce"] = "rbxassetid://134818882821660",
   ["Everybody Wants To Rule The World"] = "rbxassetid://87209527034670",
   ["Missing Money"] = "rbxassetid://134668194128037",
   ["Sour Grapes"] = "rbxassetid://117820392172291",
   ["Erwachen"] = "rbxassetid://124853612881772",
   ["Grasp the Light"] = "rbxassetid://89549155689397",
   ["Beyond the Shadows"] = "rbxassetid://120729792529978",
   ["Rise to the Horizon"] = "rbxassetid://72573266268313",
   ["Echoes of the Candy Kingdom"] = "rbxassetid://103040477333590",
   ["Speed"] = "rbxassetid://125550253895893",
   ["Lo-fi Chill A"] = "rbxassetid://9043887091",
   ["Lo-fi Ambient"] = "rbxassetid://129775776987523",
   ["Tears in the Rain"] = "rbxassetid://129710845038263"
}

local currentSound = Instance.new("Sound")
currentSound.Volume = 3
currentSound.Looped = false
currentSound.Parent = game:GetService("SoundService")

local function playSoundById(soundId)
   currentSound:Stop()
   currentSound.SoundId = soundId
   currentSound:Play()
end

getgenv().soundmodule = false
local selectedSound = "Eeyuh"

local function calculatePing()
    local ping = 50
    pcall(function()
        ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    return ping > 400 and ping * 1.3 or ping > 200 and ping * 1.2 or ping
end

local function getDistance(p1, p2)
    if not p1 or not p2 then return math.huge end
    return safeGetDistance(p1, p2)
end

local function isBallApproaching(ballPos, ballVel, targetPos)
    if not ballPos or not targetPos then return false end
    
    local dist = getDistance(targetPos, ballPos)
    if ballVel.Magnitude < 0.1 then return false end
    if dist < 12 then return true end
    return ballVel.Unit:Dot((targetPos - ballPos).Unit) > (dist < 25 and 0.4 or 0.6)
end

local OshiruGUI = Instance.new("ScreenGui")
OshiruGUI.Name = "OshiruGUI"
OshiruGUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
OshiruGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
OshiruGUI.ResetOnSpawn = false

local Background = Instance.new("ImageLabel")
Background.Name = "Background"
Background.Size = UDim2.new(0, 100, 0, 50)
Background.BorderSizePixel = 0
Background.BackgroundTransparency = 1
Background.Position = UDim2.new(0.5, 0, 0.5, 0)
Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Background.ScaleType = Enum.ScaleType.Crop
Background.ImageTransparency = 0.5
Background.Image = "rbxassetid://103072558218646"
Background.Visible = false
Background.Parent = OshiruGUI

local BackgroundCorner = Instance.new("UICorner")
BackgroundCorner.CornerRadius = UDim.new(0, 5)
BackgroundCorner.Parent = Background

local BackgroundStroke = Instance.new("UIStroke")
BackgroundStroke.Thickness = 1.5
BackgroundStroke.Color = Color3.fromRGB(0, 0, 0)
BackgroundStroke.Parent = Background

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0, 100, 0, 33)
Status.BackgroundTransparency = 1
Status.TextSize = 18
Status.Position = UDim2.new(0, 0, 0.34, 0)
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.Text = "Status: OFF"
Status.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
Status.Parent = Background

local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0, 10, 0, 10)
StatusFrame.BorderSizePixel = 0
StatusFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
StatusFrame.Parent = Background

local StatusFrameCorner = Instance.new("UICorner")
StatusFrameCorner.CornerRadius = UDim.new(0, 5)
StatusFrameCorner.Parent = StatusFrame

local Credit = Instance.new("TextLabel")
Credit.Size = UDim2.new(0, 35, 0, 19)
Credit.BackgroundTransparency = 1
Credit.Position = UDim2.new(0.2, 0, 0.06, 0)
Credit.TextSize = 14
Credit.TextColor3 = Color3.fromRGB(255, 255, 255)
Credit.Text = "Clxty"
Credit.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
Credit.TextXAlignment = Enum.TextXAlignment.Left
Credit.Parent = Background

local BackgroundShadow = Instance.new("ImageLabel")
BackgroundShadow.AnchorPoint = Vector2.new(0.5, 0.5)
BackgroundShadow.ZIndex = 0
BackgroundShadow.Size = UDim2.new(1, 147, 1, 147)
BackgroundShadow.BackgroundTransparency = 1
BackgroundShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
BackgroundShadow.ScaleType = Enum.ScaleType.Slice
BackgroundShadow.ImageTransparency = 0.5
BackgroundShadow.Image = "rbxassetid://12817478937"
BackgroundShadow.SliceCenter = Rect.new(Vector2.new(85, 85), Vector2.new(427, 427))
BackgroundShadow.Parent = Background

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local lastExecutionTime = 0
local minInterval = 0.008
local adaptiveBatchSize = 3
local frameCounter = 0
local performanceBuffer = {}
local OshiruKey = Enum.KeyCode.E

local function adjustPerformance()
    local avgFrameTime = 0
    if #performanceBuffer > 0 then
        for _, time in ipairs(performanceBuffer) do
            avgFrameTime = avgFrameTime + time
        end
        avgFrameTime = avgFrameTime / #performanceBuffer
    end
    
    if avgFrameTime > 0.016 then 
        adaptiveBatchSize = math.max(1, adaptiveBatchSize - 1)
    elseif avgFrameTime < 0.012 then
        adaptiveBatchSize = math.min(8, adaptiveBatchSize + 1)
    end
end

local function Oshiru()
    toggleOshiru = not toggleOshiru
    
    local targetColor = toggleOshiru and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    TweenService:Create(StatusFrame, tweenInfo, {BackgroundColor3 = targetColor}):Play()
    Status.Text = toggleOshiru and "Status: ON" or "Status: OFF"
    
    if spamConnection then
        spamConnection:Disconnect()
        spamConnection = nil
    end
    
    if toggleOshiru then
        spamConnection = RunService.Heartbeat:Connect(function()
            if not toggleOshiru then return end
            
            local frameStart = tick()
            local currentTime = frameStart
            
            if currentTime - lastExecutionTime < minInterval then return end
            lastExecutionTime = currentTime
            
            frameCounter = frameCounter + 1
            
            if frameCounter % 30 == 0 then
                adjustPerformance()
                if #performanceBuffer > 10 then
                    performanceBuffer = {}
                end
            end
            
            for i = 1, adaptiveBatchSize do
                if not toggleOshiru then break end
                
                local delay = (i - 1) * 0.001
                
                task.wait(delay)
                
                local success, err = pcall(function()
                    if Auto_Parry and Auto_Parry.Parry then
                        Auto_Parry.Parry(Selected_Parry_Type)
                    else
                        warn("Auto_Parry or Parry function not found")
                    end
                end)
                
                if not success then
                    warn("Error in Auto_Parry.Parry:", err)
                    adaptiveBatchSize = math.max(1, adaptiveBatchSize - 1)
                    break
                end
            end
            
            local frameEnd = tick()
            table.insert(performanceBuffer, frameEnd - frameStart)
        end)
    end
end

local dragging, startPos, startInput, hasDragged = false, nil, nil, false
local dragThreshold = 5

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function StartDrag(input)
    dragging = true
    hasDragged = false
    startPos = Background.Position
    startInput = input.Position
end

local function UpdateDrag(input)
    if dragging then
        local delta = input.Position - startInput
        if math.abs(delta.X) > dragThreshold or math.abs(delta.Y) > dragThreshold then
            hasDragged = true
        end
        Background.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end

Background.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        StartDrag(input)
    end
end)

Background.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        UpdateDrag(input)
    end
end)

Background.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if isMobile() and not hasDragged then
            Oshiru()
        end
        dragging = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == OshiruKey and not isMobile() then
        Oshiru()
    end
end)

OshiruGUI.AncestryChanged:Connect(function()
    if spamConnection then
        spamConnection:Disconnect()
        spamConnection = nil
    end
end)

local visualizerEnabled = false
local function get_character()
    return LocalPlayer and LocalPlayer.Character
end
local function get_primary_part()
    local char = get_character()
    return char and char.PrimaryPart
end
local function get_ball()
    local ballContainer = Workspace:FindFirstChild("Balls")
    if ballContainer then
        for _, ball in ipairs(ballContainer:GetChildren()) do
            if not ball.Anchored then
                return ball
            end
        end
    end
    return nil
end

local Ball_Target = nil
local visualizer = Instance.new("Part")
visualizer.Shape = Enum.PartType.Ball
visualizer.Anchored = true
visualizer.CanCollide = false
visualizer.Material = Enum.Material.ForceField
visualizer.Transparency = 0.5
visualizer.Parent = Workspace
visualizer.Size = Vector3.new(0, 0, 0)

RunService.RenderStepped:Connect(function()
    if not visualizerEnabled then
        visualizer.Size = Vector3.new(0, 0, 0)
        return
    end

    local primaryPart = get_primary_part()
    local ball = get_ball()

    if primaryPart and ball then
        Ball_Target = ball:GetAttribute("target")

        local radius = math.clamp(ball.Velocity.Magnitude / 2.4 + 10, 15, 200)
        visualizer.Size = Vector3.new(radius, radius, radius)
        visualizer.CFrame = primaryPart.CFrame
        visualizer.Color = (Ball_Target == tostring(LocalPlayer)) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 0, 0)
    else
        visualizer.Size = Vector3.new(0, 0, 0)
    end
end)

getgenv().LookAtBall = false
getgenv().LookAtBall_Mode = "Character"

local function StartLookAtBall()
    local LocalPlayer = game.Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local Character
    local HumanoidRootPart
    local Humanoid
    local Connection

    local function GetCharacter()
        Character = LocalPlayer.Character
        HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        Humanoid = Character and Character:FindFirstChild("Humanoid")
    end

    local function UpdateCameraLookAt()
        if LookAtBall_Mode == "Camera" then
            local ClosestBall = Auto_Parry.Get_Ball()
            if ClosestBall then
                local BallPosition = ClosestBall.Position
                local LookAtPosition = BallPosition + Vector3.new(0, -20, 0)

                local LookDirection = (LookAtPosition - Camera.CFrame.Position).unit
                local TargetCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + LookDirection)
                Camera.CFrame = Camera.CFrame:Lerp(TargetCFrame, 0.88)
            end
        end
    end

    local function UpdateCharacterLookAt()
        if LookAtBall_Mode == "Character" then
            local ClosestBall = Auto_Parry.Get_Ball()
            if ClosestBall and Humanoid and Humanoid.Health > 0 then
                local BallPosition = ClosestBall.Position
                local LookDirection = (BallPosition - HumanoidRootPart.Position).unit
                local TargetCFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + Vector3.new(LookDirection.X, 0, LookDirection.Z))
                HumanoidRootPart.CFrame = TargetCFrame
            end
            Camera.CameraType = Enum.CameraType.Custom 
        end
    end

    Connection = game:GetService("RunService").Heartbeat:Connect(function()
        if not getgenv().LookAtBall then
            Connection:Disconnect()
            return
        end

        if not Alive:FindFirstChild(LocalPlayer.Name) then
            return
        end

        GetCharacter()

        if LookAtBall_Mode == "Camera" then
            UpdateCameraLookAt()
        elseif LookAtBall_Mode == "Character" then
            UpdateCharacterLookAt()
        end
    end)

    Alive.ChildAdded:Connect(function(child)
        if child.Name == LocalPlayer.Name and getgenv().LookAtBall == false then
        end
    end)
end

getgenv().ViewBall = false 
local function StartViewBall()
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = game.Players.LocalPlayer
    local Connection

    Connection = RunService.RenderStepped:Connect(function()
        if not getgenv().ViewBall then
            Connection:Disconnect()
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character
            return
        end

        local Ball = Auto_Parry.Get_Ball()
        if Ball then
            Camera.CameraSubject = Ball
        else
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character
        end
    end)
end
----------------------------
local auto_rewards_enabled = false
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local net = ReplicatedStorage:WaitForChild("Packages")["_Index"]["sleitnick_net@0.1.0"].net
local function claim_rewards()
	pcall(function()
		if ReplicatedStorage:FindFirstChild("Remote") and ReplicatedStorage.Remote:FindFirstChild("RemoteEvent") then
			local event = ReplicatedStorage.Remote.RemoteEvent:FindFirstChild('ClaimLoginReward')
			if event then
				event:FireServer()
			end
		end
	end)
	task.defer(function()
		for day = 1, 30 do
			task.wait()
			pcall(function()
				if ReplicatedStorage.Remote:FindFirstChild("RemoteFunction") then
					ReplicatedStorage.Remote.RemoteFunction:InvokeServer('ClaimNewDailyLoginReward', day)
				end
			end)
			for _, wheel in ipairs({"SummerWheel", "CyborgWheel", "SynthWheel"}) do
				pcall(function()
					local processRoll = net:FindFirstChild("RE/" .. wheel .. "/ProcessRoll")
					if processRoll then
						processRoll:FireServer()
					end
				end)
			end
			pcall(function()
				if net:FindFirstChild("RE/ProcessTournamentRoll") then
					net["RE/ProcessTournamentRoll"]:FireServer()
				end
				if net:FindFirstChild("RE/RolledReturnCrate") then
					net["RE/RolledReturnCrate"]:FireServer()
				end
				if net:FindFirstChild("RE/ProcessLTMRoll") then
					net["RE/ProcessLTMRoll"]:FireServer()
				end
			end)
		end
	end)
	task.defer(function()
		for reward = 1, 6 do
			pcall(function()
				if net:FindFirstChild("RF/ClaimPlaytimeReward") then
					net["RF/ClaimPlaytimeReward"]:InvokeServer(reward)
				end
			end)
			pcall(function()
				if net:FindFirstChild("RE/ClaimSeasonPlaytimeReward") then
					net["RE/ClaimSeasonPlaytimeReward"]:FireServer(reward)
				end
			end)
			pcall(function()
				if ReplicatedStorage.Remote:FindFirstChild("RemoteFunction") then
					ReplicatedStorage.Remote.RemoteFunction:InvokeServer('SpinWheel')
				end
			end)
			pcall(function()
				if net:FindFirstChild("RE/SpinFinished") then
					net["RE/SpinFinished"]:FireServer()
				end
			end)
		end
	end)
	task.defer(function()
		for reward = 1, 5 do
			pcall(function()
				if net:FindFirstChild("RF/RedeemQuestsType") then
					net["RF/RedeemQuestsType"]:InvokeServer('SummerClashEvent', 'Daily', reward)
				end
			end)
		end
	end)
	task.defer(function()
		for reward = 1, 4 do
			pcall(function()
				if net:FindFirstChild("RE/SummerWheel/ClaimStreakReward") then
					net["RE/SummerWheel/ClaimStreakReward"]:FireServer(reward)
				end
			end)
		end
	end)
end
local reward_interval = 60
task.defer(function()
	while task.wait(reward_interval) do
		pcall(function()
			if auto_rewards_enabled then
				claim_rewards()
			end
		end)
	end
end)
--------------------------------
local AutoSpinWheel = false
spawn(function()
	while AutoSpinWheel do task.wait()
		game.ReplicatedStorage.Remote.RemoteFunction:InvokeServer("SpinWheel")
	end
end)

local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if not success then
    warn("Failed to load WindUI")
    return
end

local Window = WindUI:CreateWindow({
    Title = "Oshiru",
    Author = "Clxtyy / Zen",
    Folder = "OshiruFolder",
    Size = UDim2.fromOffset(600, 300),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 170
})

local Tabs = {
    Home = Window:Tab({Title = "Home", Icon = "house"}),
    Main = Window:Tab({Title = "Main", Icon = "swords"}),
    Visual = Window:Tab({Title = "Visuals", Icon = "eye"})
    --[[Players = Window:Tab({Title = "Players", Icon = "users"}),
    Abilities = Window:Tab({Title = "Abilities", Icon = "zap"}),
    UISettings = Window:Tab({Title = "UI Settings", Icon = "settings-2"})]]
}

Tabs.Home:Paragraph({
  Title = "Hello!",
  Desc = [[Welcome to Oshiru Blade Ball!
Thank you for using our script we truly appreciate it.]]
})

Tabs.Home:Paragraph({
    Title = "Credits",
    Desc = [[
    Special thanks to:
    - Clxtyy - Owner of Oshiru.
    - Zen - Main Developers.
    - ZxnixW - Auto Spam logic.
    - Footagesus - WindUI library.
    ]]
})

Tabs.Home:Section({ Title = "Media Social" })
Tabs.Home:Button({
    Title = "Our Discord Server",
    Desc = "Click this button to copy the Discord link.",
    Callback = function()
        syn.request({
            Url = "https://discord.gg/99KZwWT8dH",
            Method = "GET"
        })
    end
})

Tabs.Home:Button({
    Title = "Clxtyy Youtube Channel",
    Desc = "Click this button to copy the Channel link.",
    Callback = function()
        syn.request({
            Url = "https://youtube.com/@clxty.?si=JvtiifTD-k7ZKonr",
            Method = "GET"
        })
    end
})

Tabs.Home:Button({
    Title = "T4Dripz Youtube Channel",
    Desc = "Click this button to copy the Channel link.",
    Callback = function()
        syn.request({
            Url = "https://youtube.com/@t4dripz?si=zy6mpZvqYRt6v-Y4",
            Method = "GET"
        })
    end
})

Tabs.Main:Toggle({
    Title = "Training Ball",
    Value = false,
    Callback = function(v)
        TrainingBall = v
    end
})

Tabs.Main:Toggle({
    Title = "Auto Parry",
    Value = false,
    Callback = function(v)
        if v then
            Connections_Manager["Auto Parry"] = RunService.PreSimulation:Connect(function()
                local char = safeGetCharacter()
                local hrp = safeGetHumanoidRootPart()
                if not char or not hrp then return end
                if hrp:FindFirstChild("SingularityCape") or hrp:FindFirstChild("MaxShield") then
                    return
                end
                local One_Ball = Auto_Parry.Get_Ball()
                local Balls = Auto_Parry.Get_Balls()
                for _, Ball in pairs(Balls) do
                    if not Ball or not Ball.Parent then continue end
                    local Zoomies = Ball:FindFirstChild("zoomies")
                    if not Zoomies then return end
                    Ball:GetAttributeChangedSignal("target"):Once(function()
                        Parried = false
                    end)
                    char = safeGetCharacter()
                    hrp = safeGetHumanoidRootPart()
                    if not char or not hrp or Parried then continue end
                    if hrp and hrp:FindFirstChild("SingularityCape") then return end
                    if Parried then return end
                    local Ball_Target = (Ball.GetAttribute and Ball:GetAttribute("target")) or nil
                    local One_Target = (typeof(One_Ball) == "Instance" and One_Ball.GetAttribute and One_Ball:GetAttribute("target")) or nil
                    local Velocity = Zoomies.VectorVelocity
                    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
                    local Speed = Velocity.Magnitude
                    local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                    local Parry_Accuracy = (Speed / 3.25) + Ping
                    local Curved = Auto_Parry.Is_Curved()
                    if Phantom and Player.Character:FindFirstChild('ParryHighlight') and getgenv().PhantomV2Detection then
                        ContextActionService:BindAction('BlockPlayerMovement', BlockMovement, false, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.UserInputType.Touch)
                        Player.Character.Humanoid.WalkSpeed = 36
                        Player.Character.Humanoid:MoveTo(Ball.Position)
                        task.spawn(function()
                            repeat
                                if Player.Character.Humanoid.WalkSpeed ~= 36 then
                                    Player.Character.Humanoid.WalkSpeed = 36
                                end
                                task.wait()
                            until not Phantom
                        end)
                        Ball:GetAttributeChangedSignal('target'):Once(function()
                            ContextActionService:UnbindAction('BlockPlayerMovement')
                            Phantom = false
                            Player.Character.Humanoid:MoveTo(Player.Character.HumanoidRootPart.Position)
                            Player.Character.Humanoid.WalkSpeed = 10
                            task.delay(3, function()
                                Player.Character.Humanoid.WalkSpeed = 36
                            end)
                        end)
                    end
                    if Ball:FindFirstChild("AeroDynamicSlashVFX") then
                        Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                        Tornado_Time = tick()
                    end
                    if One_Target == tostring(Player) and Curved then return end
                    if One_Target == tostring(Player) and Backwards then return end
                    if Ball:FindFirstChild("ComboCounter") then return end
                    local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild("SingularityCape")
                    if Singularity_Cape then return end
                    if getgenv().InfinityDetection and Infinity then return end
                    if getgenv().DeathSlashDetection and DeathBall then return end
                    if getgenv().TimeHoleDetection and TimeHole then return end
                    if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                        local Parry_Time = os.clock()
                        local Time_View = Parry_Time - Last_Parry
                        if Time_View > 0.5 then
                            Auto_Parry.Parry_Animation()
                        end
                        if IsSlashesOfFuryActive() then
                            for i = 1, 30 do
                                task.spawn(function()
                                    Auto_Parry.Parry(Selected_Parry_Type)
                                end)
                                task.wait(0.001)
                            end
                        else
                            Auto_Parry.Parry(Selected_Parry_Type)
                        end
                        Last_Parry = Parry_Time
                        Parried = true
                    end
                    local Last_Parrys = tick()
                    repeat
                        RunService.PreSimulation:Wait()
                    until (tick() - Last_Parrys) >= 1 or not Parried
                    Parried = false
                end
            end)
        elseif Connections_Manager["Auto Parry"] then
            Connections_Manager["Auto Parry"]:Disconnect()
            Connections_Manager["Auto Parry"] = nil
        end
    end
})

local targetPlayer = nil
local previousTarget = nil
local SpamSpeed = 1
local SpamAggression = 1.9

local SpamSpeedLogicNum = {
    [1] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
    [2] = {11, 12, 13, 14, 15, 16, 17, 18, 19, 20},
    [3] = {21, 22, 23, 24, 25, 26, 27, 28, 29, 30},
    [4] = {31, 32, 33, 34, 35, 36, 37, 38, 39, 40},
    [5] = {41, 42, 43, 44, 45, 46, 47, 48, 49, 50},
    [6] = {51, 52, 53, 54, 55, 56, 57, 58, 59, 60},
    [7] = {61, 62, 63, 64, 65, 66, 67, 68, 69, 70},
    [8] = {71, 72, 73, 74, 75, 76, 77, 78, 79, 80},
    [9] = {81, 82, 83, 84, 85, 86, 87, 88, 89, 90},
    [10] = {91, 92, 93, 94, 95, 96, 97, 98, 99, 100}
}

local function getPlayerVelocity(player)
    local part = player and player:IsDescendantOf(workspace) and player.PrimaryPart
    return (part and part:FindFirstChild("Velocity") and part.Velocity.Value) or
           (part and part:IsA("BasePart") and part.AssemblyLinearVelocity) or Vector3.zero
end

local function calculateProximityThreshold(ballSpeed, ping, threatLevel)
    local baseThreshold = 10
    local speedAdjust = math.clamp(ballSpeed / 20, 0, 5)
    local pingAdjust = math.clamp(ping / 200, 0, 2)
    local threatAdjust = threatLevel * 2
    return baseThreshold + speedAdjust + pingAdjust + threatAdjust
end

local function calculateThreatLevel(ballPos, ballVel, playerPos, targetPos, ballSpeed)
    local b2p = getDistance(ballPos, playerPos)
    local b2t = getDistance(ballPos, targetPos)
    local p2t = getDistance(playerPos, targetPos)
    local maxDist = ParryThreshold or 1
    local crit = math.min(12, 9 + ballSpeed / 20)
    local extreme = 7
    local closest = math.min(b2p, b2t)
    local t = 0

    if closest <= extreme then
        t = 1
    elseif closest <= crit then
        t = 0.9 + 0.1 * (1 - (closest - extreme) / (crit - extreme))
    elseif closest <= maxDist then
        t = 0.5 + 0.4 * (1 - (closest - crit) / (maxDist - crit))
    else
        t = math.max(0, 0.3 * (1 - (closest - maxDist) / 6))
    end

    local pBonus = (p2t < 18 and b2p < 18 and b2t < 18) and (0.4 * (1 - p2t / 18)) or 0
    local dThreat = 0

    if ballVel.Magnitude > 1 and (isBallApproaching(ballPos, ballVel, playerPos) or isBallApproaching(ballPos, ballVel, targetPos)) then
        dThreat = 0.7 + 0.3 * (1 - closest / maxDist)
    end

    local sThreat = math.min(1, ballSpeed / 130) * 0.7
    local combined = math.max(t + pBonus, dThreat, sThreat)

    return math.min(1, (b2p < 5 or b2t < 5) and 1 or combined)
end

local function calculateSpamTiming(threat, ping, speed)
    local base = 0.006 - threat * 0.004
    local speedAdj = math.min(0.002, speed / 10000)
    local pingAdj = ping < 160 and math.min(0.005, (ping / 600) * 1.1) or math.min(0.005, (ping / 800) * (1 + math.min(1, ping / 400)))
    return math.max(0.001, base - speedAdj + pingAdj)
end

local function calculateSpamCount(threatLevel, ballToClosest, ballSpeed, parryCount, ping, spamSpeed)
    if parryCount <= 1 then return 0 end
    local speedTable = SpamSpeedLogicNum[math.clamp(spamSpeed, 1, 10)] or SpamSpeedLogicNum[1]
    local index = math.floor((threatLevel * #speedTable) + 0.5)
    local base = math.clamp(speedTable[index], 1, ping < 160 and 12 or 18)
    base = base + (
        ballToClosest <= 5 and 4 or
        ballToClosest <= 8 and 3 or
        ballToClosest <= 12 and 2 or
        ballToClosest <= 18 and 1 or 0
    )
    base = base + (
        ballSpeed > 140 and 3 or
        ballSpeed > 90 and 2 or
        ballSpeed > 40 and 1 or 0
    )
    return ping < 160 and (parryCount < 3 and math.min(base, 9) or math.min(base, 12)) or
           (parryCount < 3 and math.min(base, 12) or math.min(base, 15))
end

Tabs.Main:Toggle({
    Title = "Auto Spam",
    Value = false,
    Callback = function(state)
        getgenv().Auto_Spam = state
        
        if state then
            if Connections_Manager["Auto Spam"] then
                Connections_Manager["Auto Spam"]:Disconnect()
                Connections_Manager["Auto Spam"] = nil
            end

            local lastSpamTime = 0
            local previousBallPos = nil
            local previousBallTime = 0
            local targetSwitchTime = 0
            local consecutiveSpams = 0
            local ballSpeedHistory = {0, 0, 0}
            local pingHistory = {50, 50, 50}
            local spamCycle = 1
            local activeCoroutine = nil
            local lastValidTargetTime = 0
            local spamTimeout = 0.2

            Connections_Manager["Auto Spam"] = game:GetService("RunService").Heartbeat:Connect(function()
                if not getgenv().Auto_Spam then return end

                local char = safeGetCharacter()
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if not char or not humanoid or humanoid.Health <= 0 then
                    consecutiveSpams = 0
                    return
                end

                local hrp = safeGetHumanoidRootPart()
                if not hrp then
                    consecutiveSpams = 0
                    return
                end

                local playerPos = safeGetPosition(hrp)
                if not playerPos then
                    consecutiveSpams = 0
                    return
                end

                Auto_Parry.Closest_Player()
                local targetPlayer = Closest_Entity
                if not targetPlayer or not targetPlayer:IsDescendantOf(workspace) or not targetPlayer.PrimaryPart then
                    consecutiveSpams = 0
                    if tick() - lastValidTargetTime > spamTimeout then
                        lastSpamTime = tick()
                    end
                    return
                end

                local targetHumanoid = targetPlayer:FindFirstChildOfClass("Humanoid")
                if not targetHumanoid or targetHumanoid.Health <= 0 then
                    consecutiveSpams = 0
                    if tick() - lastValidTargetTime > spamTimeout then
                        lastSpamTime = tick()
                    end
                    return
                end

                local targetPos = safeGetPosition(targetPlayer.PrimaryPart)
                if not targetPos then
                    consecutiveSpams = 0
                    return
                end

                local playerToTargetDist = getDistance(playerPos, targetPos)
                if playerToTargetDist > 55 then
                    consecutiveSpams = 0
                    if tick() - lastValidTargetTime > spamTimeout then
                        lastSpamTime = tick()
                    end
                    return
                end

                local ball = Auto_Parry.Get_Ball()
                if not ball or not ball:IsDescendantOf(workspace) or not ball:FindFirstChild("zoomies") or (ball.Position.Magnitude < 1) then
                    consecutiveSpams = 0
                    if tick() - lastValidTargetTime > spamTimeout then
                        lastSpamTime = tick()
                    end
                    local waitTime = 0
                    repeat
                        task.wait(0.0000000000000000001)
                        waitTime = waitTime + 0.0000000000000000001
                        ball = Auto_Parry.Get_Ball()
                    until (ball and ball:IsDescendantOf(workspace) and ball:FindFirstChild("zoomies") and (ball.Position.Magnitude > 1)) or (waitTime >= 2.5)
                    return
                end

                local ballPos = safeGetPosition(ball)
                if not ballPos then
                    consecutiveSpams = 0
                    return
                end

                local ballVel = ball.zoomies.VectorVelocity or Vector3.zero
                local currentTime = tick()
                local calculatedBallSpeed = 0

                if previousBallPos and (currentTime - previousBallTime) > 0 then
                    calculatedBallSpeed = (ballPos - previousBallPos).Magnitude / (currentTime - previousBallTime)
                end

                previousBallPos = ballPos
                previousBallTime = currentTime

                table.remove(ballSpeedHistory, 1)
                table.insert(ballSpeedHistory, math.max(ballVel.Magnitude, calculatedBallSpeed))
                local ballSpeed = (ballSpeedHistory[1] + ballSpeedHistory[2] + ballSpeedHistory[3]) / 3 * 1.05

                table.remove(pingHistory, 1)
                table.insert(pingHistory, calculatePing() or 50)
                local currentPing = (pingHistory[1] + pingHistory[2] + pingHistory[3]) / 3

                local ballToPlayer = getDistance(ballPos, playerPos)
                local ballToTarget = getDistance(ballPos, targetPos)
                local ballToClosest = math.min(ballToPlayer, ballToTarget)

                local ballProperties = Auto_Parry:Get_Ball_Properties()
                local entityProperties = Auto_Parry:Get_Entity_Properties()
                local pingThreshold = math.clamp(currentPing / 10, 6, 12)
                local spamAccuracy = Auto_Parry.Spam_Service({
                    Ball_Properties = ballProperties,
                    Entity_Properties = entityProperties,
                    Ping = pingThreshold,
                    Spam_Sensitivity = 75,
                    Ping_Based_Spam = true
                })

                local threatLevel = calculateThreatLevel(ballPos, ballVel, playerPos, targetPos, ballSpeed) or 0
                local proximityThreshold = calculateProximityThreshold(ballSpeed, currentPing, threatLevel)
                local closeProximity = (ballToPlayer < proximityThreshold or ballToTarget < proximityThreshold) and 
                                      playerToTargetDist < (18 + threatLevel * 5) and
                                      (isBallApproaching(ballPos, ballVel, playerPos) or isBallApproaching(ballPos, ballVel, targetPos))
                local ballApproachingPlayer = isBallApproaching(ballPos, ballVel, playerPos)
                local ballApproachingTarget = isBallApproaching(ballPos, ballVel, targetPos)
                local ballApproaching = ballApproachingPlayer or ballApproachingTarget
                local inClash = consecutiveSpams > 1 and ballSpeed > 50 and playerToTargetDist < 15

                if closeProximity then
                    threatLevel = math.max(threatLevel, 0.95)
                elseif inClash then
                    threatLevel = math.max(threatLevel, 0.9)
                end

                local fps = 1 / game:GetService("RunService").Heartbeat:Wait()
                local pingAdj = math.clamp((currentPing / 10) * (60 / fps), 5, 20)
                local threshold = ParryThreshold or 1
                local triggerDist = threshold

                local ballTargetName = ball:GetAttribute("target")
                local ballTarget = ballTargetName and workspace:FindFirstChild(ballTargetName)
                local ballTargetPP = ballTarget and ballTarget.PrimaryPart
                local ballTargetDist = ballTargetPP and getDistance(ballTargetPP.Position, playerPos) or math.huge
                local isPlayerTarget = ballTargetName == LocalPlayer.Name

                local shouldSpam = false
                if (tick() - targetSwitchTime) < 0.01 then
                    shouldSpam = false
                elseif closeProximity and ballSpeed > 30 then
                    shouldSpam = true
                elseif inClash or (ballApproaching and ballToClosest < triggerDist and ballSpeed > 30) then
                    shouldSpam = true
                elseif isPlayerTarget and ballToPlayer <= triggerDist * 1.2 and playerToTargetDist <= triggerDist * 1.5 then
                    shouldSpam = true
                elseif spamAccuracy and (Parries > 1.5) and (ballToClosest <= 25) and ballSpeed > 30 then
                    shouldSpam = true
                end

                local pulsed = LocalPlayer.Character:GetAttribute("Pulsed")
                if pulsed then
                    consecutiveSpams = 0
                    return
                end

                if shouldSpam then
                    lastValidTargetTime = tick()
                elseif tick() - lastValidTargetTime > spamTimeout then
                    consecutiveSpams = 0
                    return
                end

                local spamStop = SpamCheck or 1
                local spamCount = calculateSpamCount(threatLevel, ballToClosest, ballSpeed, Parries, currentPing, getgenv().Spam_Speed) or 1
                local spamDelay = calculateSpamTiming(threatLevel, currentPing, ballSpeed) or 0.05
                spamCount = math.max(1, math.floor(tonumber(spamCount) or 1))

                if shouldSpam and spamCount > 0 and (tick() - lastSpamTime) > (spamDelay * 1.1) then
                    if Parries > threshold then
                        if activeCoroutine and coroutine.status(activeCoroutine) == "running" then
                            return
                        end
                        lastSpamTime = tick()
                        consecutiveSpams = consecutiveSpams + 1
                        local spamAmount = math.clamp(getgenv().Spam_Speed or 1, 1, 50)
                        activeCoroutine = coroutine.wrap(function()
                            for i = 1, spamCount do
                                if Parries < spamStop or not getgenv().Auto_Spam then
                                    consecutiveSpams = 0
                                    break
                                end
                                Auto_Parry.Parry(Selected_Parry_Type)
                                if i < spamCount then
                                    coroutine.yield()
                                    task.wait(spamDelay * (1 + (currentPing < 160 and 0.07 or 0.03)))
                                end
                            end
                        end)()
                        spamCycle = (spamCycle % #SpamSpeedLogicNum[math.clamp(getgenv().Spam_Speed or 1, 1, 10)]) + 1
                    else
                        if (tick() - lastSpamTime) > 0.15 then
                            consecutiveSpams = math.max(0, consecutiveSpams - 1)
                        end
                    end
                else
                    if (tick() - lastSpamTime) > 0.15 then
                        consecutiveSpams = math.max(0, consecutiveSpams - 1)
                    end
                end
            end)
        else
            if Connections_Manager["Auto Spam"] then
                Connections_Manager["Auto Spam"]:Disconnect()
                Connections_Manager["Auto Spam"] = nil
            end
        end
    end
})

Tabs.Main:Toggle({
    Title = "Manual Spam",
    Value = false,
    Callback = function(v)
      Background.Visible = v
    end
})

Tabs.Main:Toggle({
    Title = "LookAt Ball",
    Value = false,
    Callback = function(v)
        getgenv().LookAtBall = v
        if v then
            StartLookAtBall()
        end
    end
})

Tabs.Main:Toggle({
    Title = "View Ball",
    Value = false,
    Callback = function(v)
        getgenv().ViewBall = v
        if v then
            StartViewBall()
        end
    end
})

Tabs.Main:Toggle({
    Title = "Visualizer",
    Value = false,
    Callback = function(v)
        visualizerEnabled = v
    end
})

Tabs.Main:Section({ Title = "Settings" })
Tabs.Main:Dropdown({
    Title = "Parry Method",
    Values = {"Remote", "VirtualInputManager", "F_Key"},
    Value = "Remote",
    Callback = function(v)
        Parry_Method = v
    end
})

Tabs.Main:Dropdown({
    Title = "Parry Direction",
    Values = {"Camera", "Random", "Straight", "Backwards", "Up", "Right", "Left"},
    Value = "Camera",
    Callback = function(v)
        Selected_Parry_Type = v
    end
})

Tabs.Main:Slider({
    Title = "Parry Accuracy",
    Value = {
        Min = 1,
        Max = 100,
        Default = 100
    },
    Callback = function(Value)
        local Adjusted_Value = Value / 5.5
        getgenv().Parry_Accuracy = tonumber(Adjusted_Value)
    end
})

Tabs.Main:Slider({
    Title = "Spam Speed",
    Value = {
        Min = 1,
        Max = 10,
        Default = 1
    },
    Callback = function(v)
        getgenv().Spam_Speed = v
    end
})

Tabs.Main:Slider({
    Title = "Manual Spam Speed",
    Value = {
        Min = 1,
        Max = 10,
        Default = 1
    },
    Callback = function(v)
        OshiruSpeed = v
    end
})

Tabs.Main:Keybind({
    Title = "Manual Spam Keybind",
    Value = "E",
    Callback = function(v)
        OshiruKey = v
    end
})

Tabs.Main:Dropdown({
    Title = "LookAt Ball Method",
    Values = { "Character", "Camera" },
    Value = "Character",
    Callback = function(v)
        if v == "Character" then
            LookAtBall_Mode = "Character"
            local Camera = workspace.CurrentCamera
            Camera.CameraType = Enum.CameraType.Custom
        elseif v == "Camera" then
            LookAtBall_Mode = "Camera"
        end
    end
})

Tabs.Visual:Section({ Title = "Swords" })
Tabs.Visual:Toggle({
    Title = "Skin Changer",
    Value = false,
    Callback = function(v)
        getgenv().skinChanger = v
        if v then
            getgenv().updateSword()
        end
    end
})

Tabs.Visual:Input({
    Title = "Skin Name",
    Value = "",
    Placeholder = "Enter skin name",
    Callback = function(text)
        getgenv().swordModel = text
        getgenv().swordAnimations = text
        getgenv().swordFX = text
    end
})

Tabs.Visual:Button({
    Title = "Update Skin",
    Callback = function()
        if getgenv().skinChanger then
            getgenv().updateSword()
        end
    end
})

Tabs.Visual:Section({ Title = "Emotes" })
local EmoteDropdown

Tabs.Visual:Button({
    Title = "Fetch All Emote",
    Callback = function()
        if not EmoteDropdown then return end
        EmoteDropdown:Refresh(Emotes_Data)
    end
})

EmoteDropdown = Tabs.Visual:Dropdown({
    Title = "List's of Emotes Available",
    Values = {},
    Value = nil,
    Callback = function(option)
        if option then
            Animation.current = option
            if getgenv().Animations then
                Auto_Parry.Play_Animation(option)
            end
        end
    end
})

Tabs.Visual:Toggle({
    Title = "Auto Emote",
    Value = false,
    Callback = function(v)
        getgenv().Animations = v
        if v and Animation.current then
            Auto_Parry.Play_Animation(Animation.current)
        end
    end
})

Tabs.Visual:Section({ Title = "Songs" })
Tabs.Visual:Toggle({
    Title = "Play Song",
    Value = false,
    Callback = function(v)
        getgenv().soundmodule = v
        if v then
            playSoundById(soundOptions[selectedSound])
        else
            currentSound:Stop()
        end
    end
})

Tabs.Visual:Toggle({
    Title = "Loop Song",
    Value = false,
    Callback = function(v)
        currentSound.Looped = v
    end
})

Tabs.Visual:Slider({
    Title = "Volume",
    Value = {
        Min = 1,
        Max = 10,
        Default = 3,
    },
    Callback = function(v)
        currentSound.Volume = v
    end
})

Tabs.Visual:Dropdown({
    Title = "Select Song",
    Values = {
        "Eeyuh",
        "Sweep",
        "Bounce",
        "Everybody Wants To Rule The World",
        "Missing Money",
        "Sour Grapes",
        "Erwachen",
        "Grasp the Light",
        "Beyond the Shadows",
        "Rise to the Horizon",
        "Echoes of the Candy Kingdom",
        "Speed",
        "Lo-fi Chill A",
        "Lo-fi Ambient",
        "Tears in the Rain"
    },
    Value = "Eeyuh",
    Callback = function(v)
        selectedSound = v
        if getgenv().soundmodule then
            playSoundById(soundOptions[v])
        end
    end
})

Tabs.Visual:Section({ Title = "Optimizer" })
_G.Settings = {
    Players = {["Ignore Me"] = true, ["Ignore Others"] = true},
    Meshes = {Destroy = false, LowDetail = true},
    Images = {Invisible = true, LowDetail = false, Destroy = false},
    ["No Particles"] = true,
    ["No Camera Effects"] = true,
    ["No Explosions"] = true,
    ["No Clothes"] = true,
    ["Low Water Graphics"] = true,
    ["No Shadows"] = true,
    ["Low Rendering"] = true,
    ["Low Quality Parts"] = true
}

local lighting = game:GetService("Lighting")
local defaultBrightness = 2
local defaultFogEnd = 9e9

local function setParticleVisibility(enabled)
    for _, v in pairs(workspace:GetDescendants()) do 
        if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then 
            v.Enabled = enabled 
        end 
    end
end

local function applySettings()
    if _G.Settings["No Shadows"] then 
        lighting.GlobalShadows = false 
    else 
        lighting.GlobalShadows = true 
    end
    
    lighting.Brightness = _G.Settings["No Camera Effects"] and 0 or defaultBrightness
    lighting.FogEnd = defaultFogEnd
    setParticleVisibility(not _G.Settings["No Particles"])
end

Tabs.Visual:Toggle({
    Title = "FPS Boost",
    Value = false,
    Callback = function(value)
        FPSBoost = value

        if value then
            applySettings()
        else
            lighting.GlobalShadows = true
            lighting.Brightness = defaultBrightness
            lighting.FogEnd = defaultFogEnd
            setParticleVisibility(true)
        end
    end
})

Tabs.Visual:Toggle({
    Title = "No Render",
    Value = false,
    Callback = function(state)
        if LocalPlayer and LocalPlayer.PlayerScripts and LocalPlayer.PlayerScripts.EffectScripts then
            LocalPlayer.PlayerScripts.EffectScripts.ClientFX.Disabled = state
        end

        if state then
            task.spawn(function()
                for _, descendant in ipairs(workspace:GetDescendants()) do
                    if EffectClasses[descendant.ClassName] then
                        descendant:Destroy()
                    end
                end
            end)

            descendantAddedConnection = workspace.DescendantAdded:Connect(function(instance)
                if EffectClasses[instance.ClassName] then
                    Debris:AddItem(instance, 0)
                end
            end)
        else
            if descendantAddedConnection then
                descendantAddedConnection:Disconnect()
                descendantAddedConnection = nil
            end

            if LocalPlayer and LocalPlayer.PlayerScripts and LocalPlayer.PlayerScripts.EffectScripts then
                LocalPlayer.PlayerScripts.EffectScripts.ClientFX.Disabled = false
            end
        end
    end
})

Tabs.Visual:Section({ Title = "Misc" })
local AntiAFK = false

Tabs.Visual:Toggle({
    Title = "AFK",
    Value = false,
    Callback = function(v)
      game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("ChangedAfkMode"):FireServer(v)
    end
})

Tabs.Visual:Toggle({
    Title = "Anti AFK",
    Value = false,
    Callback = function(v)
        AntiAFK = v
        if afkEnabled then
            for _, v in pairs(getconnections(game.Players.LocalPlayer.Idled)) do
                v:Disable()
            end
        end
    end
})

local FOVLoopConnection = nil
Tabs.Visual:Toggle({
    Title = "FOV Toggle",
    Value = false,
    Callback = function(v)
        getgenv().ToggleFOV = v
        if v then
            if FOVLoopConnection then FOVLoopConnection:Disconnect() end
            FOVLoopConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local Camera = workspace.CurrentCamera
                if Camera and getgenv().ToggleFOV then
                    Camera.FieldOfView = getgenv().FOV_Value
                end
            end)
        else
            if FOVLoopConnection then
                FOVLoopConnection:Disconnect()
                FOVLoopConnection = nil
            end
        end
    end
})

local fovSlider = Tabs.Visual:Slider({
    Title = "FOV Value",
    Value = {
        Min = 0,
        Max = 120,
        Default = 70,
    },
    Callback = function(v)
        getgenv().FOV_Value = v
    end
})

Tabs.Visual:Button({
    Title = "Reset FOV",
    Callback = function()
        getgenv().FOV_Value = 70
    end
})

Tabs.Visual:Toggle({
    Title = "Night Mode",
    Value = currentNightMode,
    Callback = function(v)
      if v ~= currentNightMode then
        game:GetService("ReplicatedStorage").Packages["_Index"]["sleitnick_net@0.1.0"].net["RE/ToggleMisc"]:FireServer("Night Mode")
        currentNightMode = v
      end
    end
})

Tabs.Visual:Toggle({
    Title = "Auto Claim Daily Quest",
    Value = false,
    Callback = function(v)
      ClaimDailyQuest = v
    end
})

Tabs.Visual:Toggle({
    Title = "Auto Claim Playtime Reward",
    Value = false,
    Callback = function(v)
      ClaimPlaytimeReward = v
    end
})

task.spawn(function()
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    pcall(function()
        workspace.Balls.ChildAdded:Connect(function() Parried = false end)
        workspace.Balls.ChildRemoved:Connect(function()
            Parries = 0
            Parried = false
            if Connections_Manager['Target Change'] then
                Connections_Manager['Target Change']:Disconnect()
                Connections_Manager['Target Change'] = nil
            end
        end)
    end)
end)

local Runtime = workspace.Runtime
Runtime.ChildAdded:Connect(function(Value)
    if Value.Name == "Tornado" then Tornado_Time = tick() end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(
    function(_, root)
        if not Player.Character or not Player.Character.PrimaryPart then
            return
        end
        if root.Parent and root.Parent ~= Player.Character then
            if root.Parent.Parent ~= workspace.Alive then
                return
            end
        end
        if not getgenv().Auto_Spam then
            return
        end
        Auto_Parry.Closest_Player()
        local Ball = Auto_Parry.Get_Ball()
        if not Ball then
            return
        end
        local Target_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
        local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
        local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
        local Dot = Direction:Dot(Ball.AssemblyLinearVelocity.Unit)
        local Curve_Detected = Auto_Parry.Is_Curved()
        if Target_Distance < 15 and Distance < 15 and Dot > -0.25 then
            if Curve_Detected then
                Auto_Parry.Parry(Selected_Parry_Type)
            end
        end
        local Zoomies = Ball:FindFirstChild("zoomies")
        if Zoomies then
            local Speed = Zoomies.VectorVelocity.Magnitude
            local Velocity = Zoomies.VectorVelocity
            local Ball_Direction = Velocity.Unit
            local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
            local Dot = Direction:Dot(Ball_Direction)
            local Pings = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            local Speed_Threshold = math.min(Speed / 100, 40)
            local Reach_Time = Distance / Speed - (Pings / 1000)
            local Enough_Speed = Speed > 100
            local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold
            if Enough_Speed and Reach_Time > Pings / 10 then
                Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
            end
            if root ~= Player.Character.PrimaryPart and Distance > Ball_Distance_Threshold then
                Curving = tick()
            end
        end
        if Grab_Parry then
            Grab_Parry:Stop()
        end
    end
)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if Player.Character.Parent ~= workspace.Alive then return end
    if Grab_Parry then Grab_Parry:Stop() end
end)