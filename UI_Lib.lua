local Library = {
    Flags = {},
    Themes = {
        Default = {
            Main = Color3.fromRGB(32, 32, 32),       -- Màu nền chính (tối)
            Secondary = Color3.fromRGB(25, 25, 25),  -- Màu nền phụ (tối hơn)
            Accent = Color3.fromRGB(0, 120, 215),    -- Màu accent (xanh dương)
            TextColor = Color3.fromRGB(255, 255, 255) -- Màu chữ (trắng)
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
    
    local function ApplyUICorner(instance, cornerRadius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, cornerRadius)
        corner.Parent = instance
    end
    
    local function ApplyUIStroke(instance, thickness, color)
        local stroke = Instance.new("UIStroke")
        stroke.Thickness = thickness
        stroke.Color = color
        stroke.Parent = instance
    end
    
    local function MakeDraggable(frame, dragHandle)
        local dragging = false
        local dragStart = nil
        local startPos = nil

        dragHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
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
    end
    
    local function AnimateUI(instance, properties, duration, easingStyle, easingDirection)
        local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
        local tween = TweenService:Create(instance, tweenInfo, properties)
        tween:Play()
        return tween
    end
    
    local function CreateScrollableFrame(parent, size, position, canvasSize)
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size = size
        scrollFrame.Position = position
        scrollFrame.CanvasSize = canvasSize
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.ScrollBarThickness = 5
        scrollFrame.Parent = parent

        local uiListLayout = Instance.new("UIListLayout")
        uiListLayout.Parent = scrollFrame
        uiListLayout.Padding = UDim.new(0, 5)

        return scrollFrame
    end
    
    local function SaveConfig()
        local config = {
            Flags = Library.Flags,
            Instances = Library.SavedInstances
        }
        if not isfolder("BocchiWorld/AA/config_all") then
            makefolder("BocchiWorld")
            makefolder("BocchiWorld/AA")
            makefolder("BocchiWorld/AA/config_all")
        end
        writefile("BocchiWorld/AA/config_all/UILibrary.config", HttpService:JSONEncode(config))
    end
    
    local function LoadConfig()
        local configPath = "BocchiWorld/AA/config_all/UILibrary.config"
        if isfile(configPath) then
            local config = HttpService:JSONDecode(readfile(configPath))
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
        ApplyUICorner(Window.Main, 10)
        ApplyUIStroke(Window.Main, 1, Color3.fromRGB(50, 50, 50))
        
        Window.TitleBar = Create("Frame", {
            Name = "TitleBar",
            Parent = Window.Main,
            BackgroundColor3 = self.Themes[self.Settings.Theme].Secondary,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30)
        })
        ApplyUICorner(Window.TitleBar, 10)
        
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
        ApplyUICorner(Window.TabContainer, 5)
        
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
        
        MakeDraggable(Window.Main, Window.TitleBar)
        
        if UserInputService.TouchEnabled then
            local ToggleButton = Create("ImageButton", {
                Name = "ToggleButton",
                Parent = Window.MainGui,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 10),
                Size = UDim2.new(0, 50, 0, 50),
                Image = "rbxassetid://1234567890",
                ScaleType = Enum.ScaleType.Fit,
                AnchorPoint = Vector2.new(0, 0)
            })
            ApplyUICorner(ToggleButton, 10)
            
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
            ApplyUICorner(Tab.Button, 5)
            
            Tab.Content = CreateScrollableFrame(self.ContentContainer, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 2, 0))
            
            function Tab:Toggle(name, default, flag, callback)
                local toggle = Create("Frame", {
                    Name = name,
                    Parent = self.Content,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                    Size = UDim2.new(1, -10, 0, 30)
                })
                ApplyUICorner(toggle, 5)
                
                local button = Create("TextButton", {
                    Parent = toggle,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Main,
                    Position = UDim2.new(1, -50, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20),
                    Text = ""
                })
                ApplyUICorner(button, 10)
                
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
                ApplyUICorner(button, 5)
                
                button.MouseButton1Click:Connect(callback)
            end
            
            function Tab:Dropdown(name, options, default, flag, callback)
                local dropdown = Create("Frame", {
                    Name = name,
                    Parent = self.Content,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                    Size = UDim2.new(1, -10, 0, 30)
                })
                ApplyUICorner(dropdown, 5)
                
                local button = Create("TextButton", {
                    Parent = dropdown,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Main,
                    Position = UDim2.new(1, -50, 0.5, -10),
                    Size = UDim2.new(0, 40, 0, 20),
                    Text = default or "Select",
                    TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                    TextSize = 14
                })
                ApplyUICorner(button, 10)
                
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
                
                local dropdownOptions = Create("Frame", {
                    Parent = dropdown,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                    Position = UDim2.new(0, 0, 1, 5),
                    Size = UDim2.new(1, 0, 0, 0),
                    ClipsDescendants = true,
                    Visible = false
                })
                ApplyUICorner(dropdownOptions, 5)
                ApplyUIStroke(dropdownOptions, 1, Color3.fromRGB(50, 50, 50))

                local optionsList = Create("UIListLayout", {
                    Parent = dropdownOptions,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 5)
                })

                local selected = default or options[1]
                Library.Flags[flag] = selected

                local function updateDropdown()
                    button.Text = selected
                    Library.Flags[flag] = selected
                    if callback then callback(selected) end
                end

                local function toggleDropdown()
                    dropdownOptions.Visible = not dropdownOptions.Visible
                    if dropdownOptions.Visible then
                        dropdownOptions.Size = UDim2.new(1, 0, 0, #options * 25 + 10)
                    else
                        dropdownOptions.Size = UDim2.new(1, 0, 0, 0)
                    end
                end

                for _, option in pairs(options) do
                    local optionButton = Create("TextButton", {
                        Parent = dropdownOptions,
                        BackgroundColor3 = Library.Themes[Library.Settings.Theme].Main,
                        Size = UDim2.new(1, -10, 0, 25),
                        Position = UDim2.new(0, 5, 0, 0),
                        Text = option,
                        TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                        TextSize = 14,
                        AutoButtonColor = false
                    })
                    ApplyUICorner(optionButton, 5)

                    optionButton.MouseButton1Click:Connect(function()
                        selected = option
                        updateDropdown()
                        toggleDropdown()
                    end)
                end

                button.MouseButton1Click:Connect(toggleDropdown)
                updateDropdown()
            end
            
            function Tab:Keybind(name, defaultKey, flag, callback)
                local keybindFrame = Create("Frame", {
                    Name = name,
                    Parent = self.Content,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Secondary,
                    Size = UDim2.new(1, -10, 0, 30)
                })
                ApplyUICorner(keybindFrame, 5)
    
                local keybindButton = Create("TextButton", {
                    Parent = keybindFrame,
                    BackgroundColor3 = Library.Themes[Library.Settings.Theme].Main,
                    Position = UDim2.new(1, -60, 0.5, -10),
                    Size = UDim2.new(0, 50, 0, 20),
                    Font = Enum.Font.SourceSans,
                    Text = tostring(defaultKey),
                    TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                    TextSize = 14
                })
                ApplyUICorner(keybindButton, 5)
    
                local title = Create("TextLabel", {
                    Parent = keybindFrame,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Font = Enum.Font.SourceSans,
                    Text = name,
                    TextColor3 = Library.Themes[Library.Settings.Theme].TextColor,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left
                })
    
                local listening = false
    
                keybindButton.MouseButton1Click:Connect(function()
                    listening = true
                    keybindButton.Text = "..."
                end)
    
                UserInputService.InputBegan:Connect(function(input)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        listening = false
                        local key = input.KeyCode.Name
                        keybindButton.Text = key
                        Library.Flags[flag] = key
                        if callback then callback(key) end
                    end
                end)
            end
            
            return Tab
        end
        
        return Window
    end
    
    return Library
end

InitLibrary()

return Library
