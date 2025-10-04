
getgenv().reducelag = true
getgenv().autoexecuter = true

local Players=game:GetService("Players")
local TeleportService=game:GetService("TeleportService")
local plr=Players.LocalPlayer

local gates={
    Vector3.new(203.697037,4.432990,92.043350),
    Vector3.new(5731.190918,1029.104736,89.828598),
    Vector3.new(5831.542480,1029.624512,43.592541)
}

local autoRunning,stopRequested=false,false
local roundDelay=2

local function getHRP()
    local c=plr.Character
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso"))
end
local function isAlive()
    local hum=plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health>0
end
local function waitForAlive(timeout)
    local t0=tick()
    while tick()-t0<(timeout or 10) do
        if isAlive() then return true end
        task.wait(0.2)
    end
end
local function tp(pos)
    local hrp=getHRP()
    if hrp then hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) end
    if getgenv().reducelag then RunService.Heartbeat:Wait() else task.wait(0.25) end
end
local function runOneRound()
    waitForAlive(5)
    for i=1,3 do
        tp(gates[i])
        task.wait(0.5)
        if not isAlive() then waitForAlive(10) end
    end
end
local function startAuto()
    if autoRunning then return end
    autoRunning,stopRequested=true,false
    task.spawn(function()
        while autoRunning do
            runOneRound()
            if stopRequested then break end
            local t=0
            while t<roundDelay do
                if stopRequested then break end
                task.wait(0.2) t=t+0.2
            end
        end
        autoRunning,stopRequested=false,false
    end)
end
local function stopAuto() if autoRunning then stopRequested=true end end

-- GUI
local screen=Instance.new("ScreenGui",plr:WaitForChild("PlayerGui"))
screen.Name="GateRunnerConsole" screen.ResetOnSpawn=false

local toggleBtn=Instance.new("TextButton",screen)
toggleBtn.Size=UDim2.new(0,160,0,32)
toggleBtn.Position=UDim2.new(0.5,-80,1,-40)
toggleBtn.Text="GateRunner Console"
toggleBtn.BackgroundColor3=Color3.fromRGB(40,40,40)
toggleBtn.TextColor3=Color3.new(1,1,1)
toggleBtn.Font=Enum.Font.GothamBold toggleBtn.TextSize=14
toggleBtn.AnchorPoint=Vector2.new(0.5,1)

local frame=Instance.new("Frame",screen)
frame.Size=UDim2.new(0,320,0,140)
frame.Position=UDim2.new(0.5,-160,1,-180)
frame.BackgroundColor3=Color3.fromRGB(25,25,30)
frame.Visible=false frame.Active=true frame.Selectable=true

local title=Instance.new("TextLabel",frame)
title.Size=UDim2.new(1,0,0,24) title.Text="GateRunner Console"
title.BackgroundTransparency=1
title.TextColor3=Color3.new(1,1,1)
title.Font=Enum.Font.GothamBold title.TextSize=16

local input=Instance.new("TextBox",frame)
input.Size=UDim2.new(1,-20,0,32)
input.Position=UDim2.new(0,10,0,36)
input.PlaceholderText=";runonce / ;auto / ;unauto"
input.Text="" input.ClearTextOnFocus=true
input.BackgroundColor3=Color3.fromRGB(50,50,60)
input.TextColor3=Color3.new(1,1,1)
input.Font=Enum.Font.Gotham input.TextSize=16

local log=Instance.new("TextLabel",frame)
log.Size=UDim2.new(1,-20,0,40)
log.Position=UDim2.new(0,10,0,80)
log.BackgroundTransparency=1
log.Text="..."
log.TextColor3=Color3.fromRGB(200,200,200)
log.TextWrapped=true
log.TextXAlignment=Enum.TextXAlignment.Left
log.Font=Enum.Font.Gotham log.TextSize=14

local function handleCommand(cmd)
    cmd=cmd:lower()
    if cmd==";runonce" or cmd=="runonce" then
        task.spawn(runOneRound) log.Text="Đang chạy 1 vòng..."
    elseif cmd==";auto" or cmd=="auto" then
        startAuto() log.Text="Auto ON"
    elseif cmd==";unauto" or cmd=="unauto" then
        stopAuto() log.Text="Auto OFF (dừng sau vòng)"
    else
        log.Text="Không hiểu lệnh: "..cmd
    end
end

local autoHideDelay=2
local lastInteraction=0
local function touchInteraction() lastInteraction=tick() end
local function showConsole(visible)
    frame.Visible=visible
    if visible then
        touchInteraction()
        task.spawn(function()
            while frame.Visible do
                if tick()-lastInteraction>=autoHideDelay then
                    frame.Visible=false
                    break
                end
                task.wait(0.12)
            end
        end)
    end
end

frame.InputBegan:Connect(touchInteraction)
frame.InputChanged:Connect(touchInteraction)
input.Focused:Connect(touchInteraction)
input:GetPropertyChangedSignal("Text"):Connect(touchInteraction)
input.FocusLost:Connect(function(enter)
    if enter and input.Text~="" then
        handleCommand(input.Text) input.Text=""
    end
    touchInteraction()
end)
toggleBtn.MouseButton1Click:Connect(function()
    showConsole(not frame.Visible)
end)

if getgenv().autoexecuter and queue_on_teleport then
    queue_on_teleport([[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ayypwm/Mewmew/main/Gaterunonce.lua"))()
    ]])
end
