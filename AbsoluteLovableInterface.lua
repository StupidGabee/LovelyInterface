--[[
    LovelyInterface - Modern GUI Library for Roblox
    Created by: StupidGabee
    Last Updated: 2025-03-15
    
    Features:
    - Fully draggable windows and elements
    - Enhanced color customization with themes
    - Improved tab system with animations
    - Modern toggles, buttons, and sliders
    - Mobile-friendly with responsive design
    - Comprehensive documentation and examples
    
    Documentation:
    1. Initialization:
        local GUI = loadstring(game:HttpGet("URL_TO_RAW_FILE"))()
        local Window = GUI:CreateWindow("My GUI", {
            Theme = "Dark", -- or "Light", "Custom"
            Colors = {      -- Optional custom colors
                Primary = Color3.fromRGB(30, 30, 30),
                Secondary = Color3.fromRGB(45, 45, 45),
                Accent = Color3.fromRGB(255, 75, 75),
                Text = Color3.fromRGB(255, 255, 255),
                TextDark = Color3.fromRGB(175, 175, 175)
            }
        })
    
    2. Creating Tabs:
        local MainTab = Window:AddTab("Main", {
            Icon = "rbxassetid://ICON_ID", -- Optional
            Order = 1                       -- Optional
        })
    
    3. Adding Elements:
        -- Button
        MainTab:AddButton({
            Text = "Click Me",
            Icon = "rbxassetid://ICON_ID", -- Optional
            Callback = function()
                print("Button clicked!")
            end
        })
        
        -- Toggle
        MainTab:AddToggle({
            Text = "Enable Feature",
            Default = false,
            Callback = function(Value)
                print("Toggle:", Value)
            end
        })
        
        -- Slider
        MainTab:AddSlider({
            Text = "Speed",
            Min = 0,
            Max = 100,
            Default = 50,
            Increment = 1,
            Callback = function(Value)
                print("Slider:", Value)
            end
        })
]]

-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Variables
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Themes
local Themes = {
    Dark = {
        Primary = Color3.fromRGB(30, 30, 30),
        Secondary = Color3.fromRGB(45, 45, 45),
        Accent = Color3.fromRGB(255, 75, 75),
        Text = Color3.fromRGB(255, 255, 255),
        TextDark = Color3.fromRGB(175, 175, 175)
    },
    Light = {
        Primary = Color3.fromRGB(240, 240, 240),
        Secondary = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 120, 255),
        Text = Color3.fromRGB(50, 50, 50),
        TextDark = Color3.fromRGB(100, 100, 100)
    }
}

-- Library Creation
local Library = {
    Windows = {},
    Theme = "Dark",
    CustomColors = nil,
    IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
}

-- Utility Functions
local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

local function AddCorners(instance, radius)
    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, radius or 6)
    })
    corner.Parent = instance
    return corner
end

local function AddShadow(instance, transparency)
    local shadow = CreateInstance("ImageLabel", {
        Name = "Shadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 24, 1, 24),
        ZIndex = instance.ZIndex - 1,
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Parent = instance
    })
    return shadow
end

-- Enhanced Dragging Function
local function EnhancedDragging(window, dragZone)
    local dragging = false
    local dragInput, dragStart, startPos
    local lastMousePos
    local lastGoalPos
    local DRAG_SPEED = 0.064

    local function lerp(a, b, m)
        return a + (b - a) * m
    end

    local function updateDrag(input)
        local delta = input.Position - dragStart
        local goalPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                 startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        
        if lastGoalPos ~= goalPos then
            lastGoalPos = goalPos
            TweenService:Create(window, TweenInfo.new(DRAG_SPEED), {
                Position = goalPos
            }):Play()
        end
    end

    dragZone.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            lastMousePos = dragStart
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragZone.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    RunService.RenderStepped:Connect(function(delta)
        if dragging and dragInput then
            if lastMousePos then
                local mousePos = dragInput.Position
                local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + (mousePos - dragStart).X,
                                          startPos.Y.Scale, startPos.Y.Offset + (mousePos - dragStart).Y)
                lastGoalPos = targetPos
                
                -- Smooth dragging
                window.Position = UDim2.new(
                    startPos.X.Scale,
                    lerp(window.Position.X.Offset, targetPos.X.Offset, delta * 10),
                    startPos.Y.Scale,
                    lerp(window.Position.Y.Offset, targetPos.Y.Offset, delta * 10)
                )
                lastMousePos = mousePos
            end
        end
    end)
end

-- Window Creation
function Library:CreateWindow(title, options)
    options = options or {}
    local window = {
        Tabs = {},
        CurrentTab = nil,
        Theme = options.Theme or self.Theme,
        Colors = options.Colors or self.CustomColors or Themes[self.Theme]
    }
    
    -- Create ScreenGui
    window.ScreenGui = CreateInstance("ScreenGui", {
        Name = "LovelyInterface",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    
    -- Try to parent to CoreGui
    pcall(function()
        window.ScreenGui.Parent = CoreGui
    end)
    
    if not window.ScreenGui.Parent then
        window.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    end
    
    -- Create Main Window
    window.Main = CreateInstance("Frame", {
        Name = "MainWindow",
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = window.Colors.Primary,
        BorderSizePixel = 0,
        Parent = window.ScreenGui
    })
    
    -- Add shadow and corners
    AddShadow(window.Main)
    AddCorners(window.Main)
    
    -- Create Title Bar
    window.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = window.Colors.Secondary,
        BorderSizePixel = 0,
        Parent = window.Main
    })
    
    -- Add Title Text
    window.TitleText = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = window.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = window.TitleBar
    })
    
    -- Add Close Button
    window.CloseButton = CreateInstance("ImageButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://10184159300", -- Close icon
        ImageColor3 = window.Colors.Text,
        Parent = window.TitleBar
    })
    
    -- Add corners to title bar
    AddCorners(window.TitleBar)
    
    -- Create Tab Container
    window.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 150, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = window.Colors.Secondary,
        BorderSizePixel = 0,
        Parent = window.Main
    })
    
    -- Add Tab List
    window.TabList = CreateInstance("ScrollingFrame", {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = window.Colors.Accent,
        Parent = window.TabContainer
    })
    
    -- Add Tab List Layout
    local tabListLayout = CreateInstance("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = window.TabList
    })
    
    -- Create Content Container
    window.ContentContainer = CreateInstance("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -150, 1, -40),
        Position = UDim2.new(0, 150, 0, 40),
        BackgroundTransparency = 1,
        Parent = window.Main
    })
    
    -- Setup window dragging
    EnhancedDragging(window.Main, window.TitleBar)
    
    -- Setup close button
    window.CloseButton.MouseButton1Click:Connect(function()
        window.ScreenGui:Destroy()
    end)
    
    -- Window Methods
    function window:AddTab(name, options)
        options = options or {}
        
        local tab = {
            Name = name,
            Icon = options.Icon,
            Order = options.Order or #self.Tabs + 1,
            Elements = {}
        }
        
        -- Create tab button
        tab.Button = CreateInstance("TextButton", {
            Name = name .. "Tab",
            Size = UDim2.new(1, -10, 0, 36),
            Position = UDim2.new(0, 5, 0, 0),
            BackgroundColor3 = self.Colors.Primary,
            BorderSizePixel = 0,
            Text = "",
            Parent = self.TabList
        })
        
        -- Add tab icon
        if tab.Icon then
            CreateInstance("ImageLabel", {
                Name = "Icon",
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(0, 10, 0.5, -10),
                BackgroundTransparency = 1,
                Image = tab.Icon,
                ImageColor3 = self.Colors.TextDark,
                Parent = tab.Button
            })
            
            CreateInstance("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 35, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = self.Colors.TextDark,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tab.Button
            })
        else
            CreateInstance("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -20, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = name,
                TextColor3 = self.Colors.TextDark,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = tab.Button
            })
        end
        
        -- Add corners to tab button
        AddCorners(tab.Button)
        
        -- Create tab content
        tab.Content = CreateInstance("ScrollingFrame", {
            Name = name .. "Content",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = self.Colors.Accent,
            Visible = false,
            Parent = self.ContentContainer
        })
        
        -- Add content layout
        local contentLayout = CreateInstance("UIListLayout", {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tab.Content
        })
        
        -- Update canvas size
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
               tab.Content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
        end)
        
        -- Add tab selection handler
        tab.Button.MouseButton1Click:Connect(function()
            self:SelectTab(name)
        end)
        
        -- Add tab methods
        function tab:AddButton(options)
            options = options or {}
            local button = {
                Text = options.Text or "Button",
                Icon = options.Icon,
                Callback = options.Callback
            }
            
            -- Create button frame
            button.Frame = CreateInstance("Frame", {
                Name = button.Text .. "Button",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = window.Colors.Secondary,
                BorderSizePixel = 0,
                Parent = self.Content
            })
            
            -- Add button elements
            if button.Icon then
                CreateInstance("ImageLabel", {
                    Name = "Icon",
                    Size = UDim2.new(0, 20, 0, 20),
                    Position = UDim2.new(0, 10, 0.5, -10),
                    BackgroundTransparency = 1,
                    Image = button.Icon,
                    ImageColor3 = window.Colors.Text,
                    Parent = button.Frame
                })
                
                CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -40, 1, 0),
                    Position = UDim2.new(0, 35, 0, 0),
                    BackgroundTransparency = 1,
                    Text = button.Text,
                    TextColor3 = window.Colors.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = button.Frame
                })
            else
                CreateInstance("TextLabel", {
                    Name = "Label",
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    BackgroundTransparency = 1,
                    Text = button.Text,
                    TextColor3 = window.Colors.Text,
                    TextSize = 14,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = button.Frame
                })
            end
            
            -- Add corners and effects
            AddCorners(button.Frame)
            
            -- Add hover and click effects
            local function updateButtonStyle(isHovered)
                TweenService:Create(button.Frame, TweenInfo.new(0.2), {
                    BackgroundColor3 = isHovered and window.Colors.Accent or window.Colors.Secondary
                }):Play()
            end
            
            button.Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if button.Callback then
                        button.Callback()
                    end
                end
            end)
            
            button.Frame.MouseEnter:Connect(function()
                updateButtonStyle(true)
            end)
            
            button.Frame.MouseLeave:Connect(function()
                updateButtonStyle(false)
            end)
            
            return button
        end
        
        function tab:AddToggle(options)
            options = options or {}
            local toggle = {
                Text = options.Text or "Toggle",
                Default = options.Default or false,
                Callback = options.Callback
            }
            
            -- Create toggle frame
            toggle.Frame = CreateInstance("Frame", {
                Name = toggle.Text .. "Toggle",
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = window.Colors.Secondary,
                BorderSizePixel = 0,
                Parent = self.Content
            })
            
            -- Add toggle label
            CreateInstance("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -60, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = toggle.Text,
                TextColor3 = window.Colors.Text,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = toggle.Frame
            })
            
            -- Create switch
            toggle.Switch = CreateInstance("Frame", {
                Name = "Switch",
                Size = UDim2.new(0, 40, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = window.Colors.TextDark,
                BorderSizePixel = 0,
                Parent = toggle.Frame
            })
            
            toggle.Indicator = CreateInstance("Frame", {
                Name = "Indicator",
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new(0, 2, 0.5, -8),
                BackgroundColor3 = window.Colors.Text,
                BorderSizePixel = 0,
                Parent = toggle.Switch
            })
            
            -- Add corners
            AddCorners(toggle.Frame)
            AddCorners(toggle.Switch, 10)
            AddCorners(toggle.Indicator, 8)
            
            -- Toggle functionality
            toggle.Value = toggle.Default
            
            local function updateToggle()
                TweenService:Create(toggle.Switch, TweenInfo.new(0.2), {
                    BackgroundColor3 = toggle.Value and window.Colors.Accent or window.Colors.TextDark
                }):Play()
                
                TweenService:Create(toggle.Indicator, TweenInfo.new(0.2), {
                    Position = toggle.Value 
                        and UDim2.new(1, -18, 0.5, -8)
                        or UDim2.new(0, 2, 0.5, -8)
                }):Play()
                
                if toggle.Callback then
                    toggle.Callback(toggle.Value)
                end
            end
            
            -- Set initial state
            updateToggle()
            
            -- Add click handler
            toggle.Frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    toggle.Value = not toggle.Value
                    updateToggle()
                end
            end)
            
            -- Add hover effects
            toggle.Frame.MouseEnter:Connect(function()
                TweenService:Create(toggle.Frame, TweenInfo.new(0.2), {
                    BackgroundColor3 = window.Colors.Accent
                }):Play()
            end)
            
            toggle.Frame.MouseLeave:Connect(function()
                TweenService:Create(toggle.Frame, TweenInfo.new(0.2), {
                    BackgroundColor3 = window.Colors.Secondary
                }):Play()
            end)
            
            return toggle
        end
        
        function tab:AddSlider(options)
            options = options or {}
            local slider = {
                Text = options.Text or "Slider",
                Min = options.Min or 0,
                Max = options.Max or 100,
                Default = options.Default or 50,
                Increment = options.Increment or 1,
                Callback = options.Callback
            }
            
            -- Create slider frame
            slider.Frame = CreateInstance("Frame", {
                Name = slider.Text .. "Slider",
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundColor3 = window.Colors.Secondary,
                BorderSizePixel = 0,
                Parent = self.Content
            })
            
            -- Add slider label
            CreateInstance("TextLabel", {
                Name = "Label",
                Size = UDim2.new(1, -60, 0, 30),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = slider.Text,
                TextColor3 = window.Colors.Text,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = slider.Frame
            })
            
            -- Add value label
            slider.ValueLabel = CreateInstance("TextLabel", {
                Name = "Value",
                Size = UDim2.new(0, 50, 0, 30),
                Position = UDim2.new(1, -60, 0, 0),
                BackgroundTransparency = 1,
                Text = tostring(slider.Default),
                TextColor3 = window.Colors.Text,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                Parent = slider.Frame
            })
            
            -- Create slider bar
            slider.Bar = CreateInstance("Frame", {
                Name = "SliderBar",
                Size = UDim2.new(1, -20, 0, 4),
                Position = UDim2.new(0, 10, 0, 45),
                BackgroundColor3 = window.Colors.TextDark,
                BorderSizePixel = 0,
                Parent = slider.Frame
            })
            
            slider.Fill = CreateInstance("Frame", {
                Name = "SliderFill",
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = window.Colors.Accent,
                BorderSizePixel = 0,
                Parent = slider.Bar
            })
            
            -- Add corners
            AddCorners(slider.Frame)
            AddCorners(slider.Bar)
            AddCorners(slider.Fill)
            
            -- Slider functionality
            local dragging = false
            slider.Value = slider.Default
            
            local function updateSlider(input)
                local pos = math.clamp((input.Position.X - slider.Bar.AbsolutePosition.X) / slider.Bar.AbsoluteSize.X, 0, 1)
                local value = math.floor((slider.Min + ((slider.Max - slider.Min) * pos)) / slider.Increment) * slider.Increment
                slider.Value = value
                slider.ValueLabel.Text = tostring(value)
                slider.Fill.Size = UDim2.new(pos, 0, 1, 0)
                
                if slider.Callback then
                    slider.Callback(value)
                end
            end
            
            -- Set initial state
            local defaultPos = (slider.Default - slider.Min) / (slider.Max - slider.Min)
            slider.Fill.Size = UDim2.new(defaultPos, 0, 1, 0)
            
            -- Add input handlers
            slider.Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                               input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            -- Add hover effects
            slider.Frame.MouseEnter:Connect(function()
                TweenService:Create(slider.Frame, TweenInfo.new(0.2), {
                    BackgroundColor3 = window.Colors.Accent
                }):Play()
            end)
            
            slider.Frame.MouseLeave:Connect(function()
                TweenService:Create(slider.Frame, TweenInfo.new(0.2), {
                    BackgroundColor3 = window.Colors.Secondary
                }):Play()
            end)
            
            return slider
        end
        
        -- Store tab
        self.Tabs[name] = tab
        
        -- Select tab if it's the first one
        if #self.Tabs == 1 then
            self:SelectTab(name)
        end
        
        return tab
    end
    
    -- Tab selection
    function window:SelectTab(name)
        if not self.Tabs[name] then return end
        
        -- Deselect current tab
        if self.CurrentTab then
            self.CurrentTab.Button.BackgroundColor3 = self.Colors.Primary
            self.CurrentTab.Content.Visible = false
            
            local label = self.CurrentTab.Button:FindFirstChild("Label")
            if label then
                label.TextColor3 = self.Colors.TextDark
            end
            
            local icon = self.CurrentTab.Button:FindFirstChild("Icon")
            if icon then
                icon.ImageColor3 = self.Colors.TextDark
            end
        end
        
        -- Select new tab
        self.CurrentTab = self.Tabs[name]
        self.CurrentTab.Button.BackgroundColor3 = self.Colors.Accent
        self.CurrentTab.Content.Visible = true
        
        local label = self.CurrentTab.Button:FindFirstChild("Label")
        if label then
            label.TextColor3 = self.Colors.Text
        end
        
        local icon = self.CurrentTab.Button:FindFirstChild("Icon")
        if icon then
            icon.ImageColor3 = self.Colors.Text
        end
    end
    
    -- Store window
    table.insert(self.Windows, window)
    
    return window
end

return Library