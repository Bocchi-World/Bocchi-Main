local Library = {
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(30, 30, 35),
            Secondary = Color3.fromRGB(25, 25, 30),
            Accent = Color3.fromRGB(65, 150, 255),
            TextColor = Color3.fromRGB(255, 255, 255)
        }
    },
    Settings = {
        Theme = "Default",
        ToggleKey = Enum.KeyCode.RightControl
    }
}

local function InitLibrary()
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    
    local function Create(class, properties)
        local instance = Instance.new(class)
        for property, value in pairs(properties) do
            instance[property] = value
        end
        return instance
    end
    
    local function Tween(instance, properties, duration)
        local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quart), properties)
        tween:Play()
        return tween
    end
    
    local function SaveConfig()
        local config = {
            Flags = Library.Flags,
            Instances = Library.SavedInstances
        }
        writefile("UILibrary.config", HttpService:JSONEncode(config))
    end
    
    local function LoadConfig()
        if isfile("UILibrary.config") then
            local config = HttpService:JSONDecode(readfile("UILibrary.config"))
            for flag, value in pairs(config.Flags) do
                if Library.Flags[flag] ~= nil then
                    Library.Flags[flag] = value
                end
            end
            for instance, data in pairs(config.Instances) do
                if Library.SavedInstances[instance] then
                    Library.SavedInstances[instance] = data
                end
            end
        end
    end
    
    Library.SavedInstances = {}
    
    function Library:CreateWindow(name)
        local Window = {}
        
        Window.MainGui = Create("ScreenGui", {
            Name = "UILibrary",
            Parent = CoreGui,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        })
        
        Window.Main = Create("Frame", {
            Name = "Main",
            Parent = Window.MainGui,
            BackgroundColor3 = self.Themes[self.Settings.Theme].Main,
            BorderSizePixel = 0,
            Position = UDim2.new(0.5, -300, 0.5, -200),
            Size = UDim2.new(0, 600, 0, 400),
            ClipsDescendants = true
        })
        
        Window.TitleBar = Create("Frame", {
            Name = "TitleBar",
            Parent = Window.Main,
            BackgroundColor3 = self.Themes[self.Settings.Theme].Secondary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30)
        })
        
        Window.Title = Create("TextLabel", {
            Name = "Title",
            Parent = Window.TitleBar,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Font = Enum.Font.SourceSansBold,
            Text = name,
            TextColor3 = self.Themes[self.Settings.Theme].TextColor,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        
        Window.TabContainer = Create("Frame", {
            Name = "TabContainer",
            Parent = Window.Main,
            BackgroundColor3 = self.Themes[self.Settings.Theme].Secondary,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 30),
            Size = UDim2.new(0, 150, 1, -30)
        })
        
        Window.TabList = Create("UIListLayout", {
            Parent = Window.TabContainer,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 5)
        })
        
        Window.ContentContainer = Create("Frame", {
            Name = "ContentContainer",
            Parent = Window.Main,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 160, 0, 40),
            Size = UDim2.new(1, -170, 1, -50)
        })
        
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        Window.TitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Window.Main.Position
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Window.Main.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == self.Settings.ToggleKey then
                Window.MainGui.Enabled = not Window.MainGui.Enabled
            end
        end)
        
        if RunService:IsMobile() then
            local ToggleButton = Create("ImageButton", {
                Name = "ToggleButton",
                Parent = Window.MainGui,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 10),
                Size = UDim2.new(0, 50, 0, 50),
                Image = "rbxassetid://1234567890", -- Replace with your image asset ID
                ScaleType = Enum.ScaleType.Fit,
                AnchorPoint = Vector2.new(0, 0)
            })
            
            ToggleButton.MouseButton1Click:Connect(function()
                Window.MainGui.Enabled = not Window.MainGui.Enabled
            end)
        end
        
        function Window:Tab(name)
            local Tab = {}
            
            Tab.Button = Create("TextButton", {
                Name = name,
                Parent = self.TabContainer,
                BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 30),
                Font = Enum.Font.SourceSansBold,
                Text = name,
                TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                TextSize = 14
            })
            
            Tab.Content = Create("ScrollingFrame", {
                Name = name.."Content",
                Parent = self.ContentContainer,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 2,
                Visible = false
            })
            
            local UIListLayout = Create("UIListLayout", {
                Parent = Tab.Content,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5)
            })
            
            function Tab:Toggle(name, default, flag, callback)
                local toggle = Create("Frame", {
                    Name = name,
                    Parent = self.Content,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                    Size = UDim2.new(1, -10, 0, 30)
                })
                
                local button = Create("TextButton", {
                    Parent = toggle,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Main,
                    Position = UDim2.new(1, -50, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20),
                    Text = ""
                })
                
                local title = Create("TextLabel", {
                    Parent = toggle,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.SourceSans,
                    Text = name,
                    TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local toggled = default or false
                Library.Flags[flag] = toggled
                
                local function updateToggle()
                    button.BackgroundColor3 = toggled and Library.Themes[Library.Settings.Theme].Accent or Library.Themes[Library.Settings.Theme].Main
                    if callback then callback(toggled) end
                end
                
                button.MouseButton1Click:Connect(function()
                    toggled = not toggled
                    Library.Flags[flag] = toggled
                    updateToggle()
                end)
                
                updateToggle()
            end
            
            function Tab:Button(name, callback)
                local button = Create("TextButton", {
                    Name = name,
                    Parent = self.Content,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                    Size = UDim2.new(1, -10, 0, 30),
                    Font = Enum.Font.SourceSans,
                    Text = name,
                    TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                    TextSize = 14
                })
                
                button.MouseButton1Click:Connect(callback)
            end
            
            function Tab:Dropdown(name, options, default, flag, callback)
                local dropdown = Create("Frame", {
                    Name = name,
                    Parent = self.Content,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                    Size = UDim2.new(1, -10, 0, 30)
                })
                
                local button = Create("TextButton", {
                    Parent = dropdown,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Main,
                    Position = UDim2.new(1, -50, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20),
                    Text = default or "Select",
                    TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                    TextSize = 14
                })
                
                local title = Create("TextLabel", {
                    Parent = dropdown,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.SourceSans,
                    Text = name,
                    TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
                
                local selected = default or options[1]
                Library.Flags[flag] = selected
                
                button.MouseButton1Click:Connect(function()
                    for _, option in pairs(options) do
                        if option == selected then
                            selected = nil
                            break
                        end
                    end
                    if selected then
                        button.Text = selected
                        Library.Flags[flag] = selected
                        if callback then callback(selected) end
                    end
                end)
            end
            
            if #self.TabContainer:GetChildren() == 2 then
                Tab.Content.Visible = true
            end
            
            Tab.Button.MouseButton1Click:Connect(function()
                for _, tab in pairs(self.ContentContainer:GetChildren()) do
                    tab.Visible = false
                end
                Tab.Content.Visible = true
            end)
            
            return Tab
        end
        
        return Window
    end
end

InitLibrary()

return Library
