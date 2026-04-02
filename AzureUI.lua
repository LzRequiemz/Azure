local library = {count = 0, queue = {}, callbacks = {}, rainbowtable = {}, toggled = true, binds = {}, hideui = _G.HideUI};
local defaults;
local UIS = game:GetService("UserInputService");
local RunService = game:GetService("RunService");
local Debris = game:GetService("Debris");
do
    local dragger = {};
    do
        local players = game:service('Players');
        local player = players.LocalPlayer;
        local mouse = player:GetMouse();
        local run = game:service('RunService');
        local stepped = run.Stepped;
        dragger.new = function(obj)
            spawn(function()
                local minitial;
                local initial;
                local isdragging;
                obj.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        isdragging = true;
                        minitial = input.Position;
                        initial = obj.Position;
                        local con;
                        con = stepped:Connect(function()
                            if isdragging then
                                local delta = Vector3.new(mouse.X, mouse.Y, 0) - minitial;
                                obj.Position = UDim2.new(initial.X.Scale, initial.X.Offset + delta.X, initial.Y.Scale, initial.Y.Offset + delta.Y);
                            else
                                con:Disconnect();
                            end;
                        end);
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                isdragging = false;
                            end;
                        end);
                    end;
                end);
            end)
        end;
    end
    
    local function getVisibleChildCount(container)
        local count = 0;
        for _, child in next, container:GetChildren() do
            if (not child:IsA("UIListLayout")) then
                count = count + 1;
            end
        end
        return count;
    end

    local function getContainerHeight(container)
        local y = 0;
        for _, child in next, container:GetChildren() do
            if (not child:IsA("UIListLayout")) then
                y = y + child.AbsoluteSize.Y;
            end
        end
        return y + 5;
    end

    local function clearNonLayoutChildren(container)
        for _, child in next, container:GetChildren() do
            if (not child:IsA("UIListLayout")) then
                child:Destroy();
            end
        end
    end

    local function safeDisconnect(connection)
        if connection and connection.Connected then
            connection:Disconnect();
        end
    end

    local types = {}; do
        types.__index = types;
        -- ... [snip: unchanged code above slider] ...
        
        function types:Slider(name, options, callback)
            local default = options.default or options.min;
            local min     = options.min or 0;
            local max      = options.max or 1;
            local location = options.location or self.flags;
            local precise  = options.precise  or false -- e.g 0, 1 vs 0, 0.1, 0.2, ...
            local step     = options.step or options.increment or (precise and 0.1 or 1);
            local flag     = options.flag or "";
            local callback = callback or function() end

            local function normalizeValue(raw)
                local clamped = math.clamp(raw, min, max)
                if precise then
                    local snapped = math.floor((clamped / step) + 0.5) * step
                    return tonumber(string.format("%.2f", math.clamp(snapped, min, max)))
                end
                return math.floor(clamped)
            end

            location[flag] = default;

            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextLabel', {
                    Name = name;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    Text = "\r" .. name;
                    BackgroundTransparency = 1;
                    TextColor3 = library.options.textcolor;
                    Position = UDim2.new(0, 5, 0, 2);
                    Size     = UDim2.new(1, -5, 1, 0);
                    TextXAlignment = Enum.TextXAlignment.Left;
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    library:Create('Frame', {
                        Name = 'Container';
                        Size = UDim2.new(0, 60, 0, 20);
                        Position = UDim2.new(1, -65, 0, 3);
                        BackgroundTransparency = 1;
                        BorderSizePixel = 0;
                        -- slider background
                        library:Create('Frame', {
                            Name = 'Track';
                            Size = UDim2.new(1, 0, 0, 6);
                            AnchorPoint = Vector2.new(0, 0.5);
                            Position = UDim2.new(0, 0, 0.5, 0);
                            BackgroundColor3 = _G.UIUnderlineColor or Color3.fromRGB(40, 40, 40);
                            BorderSizePixel = 0;
                            BackgroundTransparency = 0;
                            -- moderate rounding for track
                            library:Create('UICorner', { CornerRadius = UDim.new(0, 6) });
                            -- The fill which represents the value
                            library:Create('Frame', {
                                Name = 'Fill';
                                Size = UDim2.new(0, 0, 1, 0);
                                Position = UDim2.new(0, 0, 0, 0);
                                BackgroundTransparency = 0;
                                BackgroundColor3 = Color3.fromRGB(80, 160, 255);
                                BorderSizePixel = 0;
                                library:Create('UICorner', { CornerRadius = UDim.new(0, 6) });
                                ZIndex = 3;
                            });
                        });
                        -- Value text
                        library:Create('TextLabel', {
                            Name = 'ValueLabel';
                            Text = default;
                            BackgroundTransparency = 1;
                            TextColor3 = library.options.textcolor;
                            Position = UDim2.new(0, -10, 0, 0);
                            Size     = UDim2.new(0, 1, 1, 0);
                            TextXAlignment = Enum.TextXAlignment.Right;
                            Font = library.options.font;
                            TextSize = library.options.fontsize;
                            TextStrokeTransparency = library.options.textstroke;
                            TextStrokeColor3 = library.options.strokecolor;
                        });
                        library:Create('TextButton', {
                            Name = 'Button';
                            Size = UDim2.new(0, 13, 0, 13);
                            AnchorPoint = Vector2.new(0.5,0.5);
                            Position = UDim2.new(0, 0, 0.5, 0);
                            AutoButtonColor = false;
                            Text = "";
                            BackgroundColor3 = Color3.fromRGB(90, 170, 255);
                            BorderSizePixel = 0;
                            ZIndex = 5;
                            -- moderate rounding for the handle (not super round: 7/13 is about halfway to a pill)
                            library:Create('UICorner', { CornerRadius = UDim.new(0.53, 0) });
                            TextStrokeTransparency = library.options.textstroke;
                            TextStrokeColor3 = library.options.strokecolor;
                        });
                    })
                });
                Parent = self.container;
            });

            local overlay = check:FindFirstChild(name);
            local container = overlay.Container;
            local track = container:FindFirstChild('Track');
            local fill = track and track:FindFirstChild('Fill');
            local valueLabel = container:FindFirstChild('ValueLabel');
            local button = container:FindFirstChild('Button');
            
            local renderSteppedConnection;
            local inputBeganConnection;
            local inputEndedConnection;
            local mouseLeaveConnection;
            local mouseDownConnection;
            local mouseUpConnection;

            -- Utility function to update fill and handle
            local function setSliderPosition(percent)
                percent = math.clamp(percent, 0, 1);
                -- Fill bar
                if fill then
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                end
                -- Slider handle
                if button then
                    button.Position = UDim2.new(percent, 0, 0.5, 0)
                end
            end

            local function setSliderValue(rawValue)
                local value = normalizeValue(rawValue)
                local percent = (value - min) / (max - min)
                setSliderPosition(percent)
                valueLabel.Text = value
                location[flag] = value
                callback(value)
            end

            local dragging = false

            container.MouseEnter:Connect(function()
                local function update()
                    dragging = true
                    if renderSteppedConnection then renderSteppedConnection:disconnect() end 
                    
                    renderSteppedConnection = RunService.RenderStepped:Connect(function()
                        local mouse = UIS:GetMouseLocation()
                        local trackAbs = track.AbsolutePosition
                        local trackSize = track.AbsoluteSize
                        local px = math.clamp(mouse.X - trackAbs.X, 0, trackSize.X)
                        local percent = px / trackSize.X
                        setSliderPosition(percent)
                        local num = min + (max - min) * percent
                        num = normalizeValue(num)
                        valueLabel.Text = num
                        callback(num)
                        location[flag] = num
                    end)
                end

                local function disconnect()
                    dragging = false
                    safeDisconnect(renderSteppedConnection)
                    safeDisconnect(inputBeganConnection)
                    safeDisconnect(inputEndedConnection)
                    safeDisconnect(mouseLeaveConnection)
                    safeDisconnect(mouseUpConnection)
                end

                inputBeganConnection = container.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        update()
                    end
                end)

                inputEndedConnection = container.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        disconnect()
                    end
                end)

                mouseDownConnection = button.MouseButton1Down:Connect(update)
                mouseUpConnection   = UIS.InputEnded:Connect(function(a, b)
                    if a.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                        disconnect()
                    end
                end)
            end)    

            -- Set initial slider value (handle and fill)
            local currentValue = default
            if currentValue ~= min then
                local percent = (currentValue - min) / (max - min)
                setSliderPosition(percent)
                valueLabel.Text = normalizeValue(currentValue)
            else
                setSliderPosition(0)
            end

            self:Resize();
            return {
                Set = function(self, value)
                    setSliderValue(value)
                end
            }
        end 

        -- ... [snip: unchanged code below slider] ...
        function types:SearchBox(text, options, callback) -- unchanged
            -- ... [as before] ...
            local list = options.list or {};
            local flag = options.flag or "";
            local location = options.location or self.flags;
            local callback = callback or function() end;

            local busy = false;
            local box = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                LayoutOrder = self:GetOrder();
                library:Create('TextBox', {
                    Text = "";
                    PlaceholderText = text;
                    PlaceholderColor3 = Color3.fromRGB(60, 60, 60);
                    Font = library.options.font;
                    TextSize = library.options.fontsize;
                    Name = 'Box';
                    Size = UDim2.new(1, -10, 0, 20);
                    Position = UDim2.new(0, 5, 0, 4);
                    TextColor3 = library.options.textcolor;
                    BackgroundColor3 = library.options.dropcolor;
                    BorderColor3 = library.options.bordercolor;
                    TextStrokeTransparency = library.options.textstroke;
                    TextStrokeColor3 = library.options.strokecolor;
                    library:Create('ScrollingFrame', {
                        Position = UDim2.new(0, 0, 1, 1);
                        Name = 'Container';
                        BackgroundColor3 = library.options.btncolor;
                        ScrollBarThickness = 0;
                        BorderSizePixel = 0;
                        BorderColor3 = library.options.bordercolor;
                        Size = UDim2.new(1, 0, 0, 0);
                        library:Create('UIListLayout', {
                            Name = 'ListLayout';
                            SortOrder = Enum.SortOrder.LayoutOrder;
                        });
                        ZIndex = 2;
                    });
                });
                Parent = self.container;
            })
            -- ... [rest of SearchBox/dropdown unchanged] ...
            local function rebuild(text)
                box:FindFirstChild('Box').Container.ScrollBarThickness = 0
                clearNonLayoutChildren(box:FindFirstChild('Box').Container)
                if #text > 0 then
                    for i, v in next, list do
                        if string.sub(string.lower(v), 1, string.len(text)) == string.lower(text) then
                            local button = library:Create('TextButton', {
                                Text = v;
                                Font = library.options.font;
                                TextSize = library.options.fontsize;
                                TextColor3 = library.options.textcolor;
                                BorderColor3 = library.options.bordercolor;
                                TextStrokeTransparency = library.options.textstroke;
                                TextStrokeColor3 = library.options.strokecolor;
                                Parent = box:FindFirstChild('Box').Container;
                                Size = UDim2.new(1, 0, 0, 20);
                                LayoutOrder = i;
                                BackgroundColor3 = library.options.btncolor;
                                ZIndex = 2;
                            })

                            button.MouseButton1Click:connect(function()
                                busy = true;
                                box:FindFirstChild('Box').Text = button.Text;
                                wait();
                                busy = false;

                                location[flag] = button.Text;
                                callback(location[flag])

                                box:FindFirstChild('Box').Container.ScrollBarThickness = 0
                                clearNonLayoutChildren(box:FindFirstChild('Box').Container)
                                box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, 0), 'Out', 'Quad', 0.25, true)
                            end)
                        end
                    end
                end

                local c = box:FindFirstChild('Box').Container:GetChildren()
                local ry = (20 * (#c)) - 20

                local y = math.clamp((20 * (#c)) - 20, 0, 100)
                if ry > 100 then
                    box:FindFirstChild('Box').Container.ScrollBarThickness = 5;
                end

                box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, y), 'Out', 'Quad', 0.25, true)
                box:FindFirstChild('Box').Container.CanvasSize = UDim2.new(1, 0, 0, (20 * (#c)) - 20)
            end

            box:FindFirstChild('Box'):GetPropertyChangedSignal('Text'):connect(function()
                if (not busy) then
                    rebuild(box:FindFirstChild('Box').Text)
                end
            end);

            local function reload(new_list)
                list = new_list;
                rebuild("")
            end
            self:Resize();
            return reload, box:FindFirstChild('Box');
        end

        -- ... rest (Dropdown, etc) unchanged ...
        -- ... [As original code from here] ...
        function types:Dropdown(name, options, callback)
            -- unchanged
            -- ... (see your original implementation) ...
            local location = options.location or self.flags;
            local flag = options.flag or "";
            local callback = callback or function() end;
            local list = options.list or {};

            location[flag] = list[1]
            local check = library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 0, 25);
                BackgroundColor3 = Color3.fromRGB(25, 25, 25);
                BorderSizePixel = 0;
                LayoutOrder = self:GetOrder();
                library:Create('Frame', {
                    Name = 'dropdown_lbl';
                    BackgroundTransparency = 0;
                    BackgroundColor3 = library.options.dropcolor;
                    Position = UDim2.new(0, 5, 0, 4);
                    BorderColor3 = library.options.bordercolor;
                    Size     = UDim2.new(1, -10, 0, 20);
                    library:Create('TextLabel', {
                        Name = 'Selection';
                        Size = UDim2.new(1, 0, 1, 0);
                        Text = list[1];
                        TextColor3 = library.options.textcolor;
                        BackgroundTransparency = 1;
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                    });
                    library:Create("TextButton", {
                        Name = 'drop';
                        BackgroundTransparency = 1;
                        Size = UDim2.new(0, 20, 1, 0);
                        Position = UDim2.new(1, -25, 0, 0);
                        Text = 'v';
                        TextColor3 = library.options.textcolor;
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                    })
                });
                Parent = self.container;
            });
            -- ... rest unchanged ...
            local button = check:FindFirstChild('dropdown_lbl').drop;
            local input;
            button.MouseButton1Click:connect(function()
                if (input and input.Connected) then
                    return
                end 
                check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = Color3.fromRGB(60, 60, 60);
                check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text = name;
                local c = 0;
                for i, v in next, list do
                    c = c + 20;
                end

                local size = UDim2.new(1, 0, 0, c)
                local clampedSize;
                local scrollSize = 0;
                if size.Y.Offset > 100 then
                    clampedSize = UDim2.new(1, 0, 0, 100)
                    scrollSize = 5;
                end

                local goSize = (clampedSize ~= nil and clampedSize) or size;    
                local container = library:Create('ScrollingFrame', {
                    TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                    BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png';
                    Name = 'DropContainer';
                    Parent = check:FindFirstChild('dropdown_lbl');
                    Size = UDim2.new(1, 0, 0, 0);
                    BackgroundColor3 = library.options.bgcolor;
                    BorderColor3 = library.options.bordercolor;
                    Position = UDim2.new(0, 0, 1, 0);
                    ScrollBarThickness = scrollSize;
                    CanvasSize = UDim2.new(0, 0, 0, size.Y.Offset);
                    ZIndex = 5;
                    ClipsDescendants = true;
                    library:Create('UIListLayout', {
                        Name = 'List';
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                })

                for i, v in next, list do
                    local btn = library:Create('TextButton', {
                        Size = UDim2.new(1, 0, 0, 20);
                        BackgroundColor3 = library.options.btncolor;
                        BorderColor3 = library.options.bordercolor;
                        Text = v;
                        Font = library.options.font;
                        TextSize = library.options.fontsize;
                        LayoutOrder = i;
                        Parent = container;
                        ZIndex = 5;
                        TextColor3 = library.options.textcolor;
                        TextStrokeTransparency = library.options.textstroke;
                        TextStrokeColor3 = library.options.strokecolor;
                    })
                    
                    btn.MouseButton1Click:connect(function()
                        check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
                        check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text = btn.Text;

                        location[flag] = tostring(btn.Text);
                        callback(location[flag])

                        Debris:AddItem(container, 0)
                        input:disconnect();
                    end)
                end

                container:TweenSize(goSize, 'Out', 'Quad', 0.15, true)
                local function isInGui(frame)
                    local mloc = UIS:GetMouseLocation();
                    local mouse = Vector2.new(mloc.X, mloc.Y - 36);
                    local x1, x2 = frame.AbsolutePosition.X, frame.AbsolutePosition.X + frame.AbsoluteSize.X;
                    local y1, y2 = frame.AbsolutePosition.Y, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y;
                    return (mouse.X >= x1 and mouse.X <= x2) and (mouse.Y >= y1 and mouse.Y <= y2)
                end
                input = UIS.InputBegan:connect(function(a)
                    if a.UserInputType == Enum.UserInputType.MouseButton1 and (not isInGui(container)) then
                        check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
                        check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').Text       = location[flag];

                        container:TweenSize(UDim2.new(1, 0, 0, 0), 'In', 'Quad', 0.15, true)
                        wait(0.15)

                        Debris:AddItem(container, 0)
                        input:disconnect();
                    end
                end)
            end)
            self:Resize();
            local function reload(self, array)
                options = array;
                location[flag] = array[1];
                pcall(function()
                    input:disconnect()
                end)
                check:WaitForChild('dropdown_lbl').Selection.Text = location[flag]
                check:FindFirstChild('dropdown_lbl'):WaitForChild('Selection').TextColor3 = library.options.textcolor
                Debris:AddItem(container, 0)
            end

            return {
                Refresh = reload;
            }
        end
    end
    
    function library:Create(class, data)
        local obj = Instance.new(class);
        for i, v in next, data do
            if i ~= 'Parent' then
                
                if typeof(v) == "Instance" then
                    v.Parent = obj;
                else
                    obj[i] = v
                end
            end
        end
        
        obj.Parent = data.Parent;
        return obj
    end
    
    function library:CreateWindow(name, options)
        if (not library.container) then
            library.container = self:Create("ScreenGui", {
                self:Create('Frame', {
                    Name = 'Container';
                    Size = UDim2.new(1, -30, 1, 0);
                    Position = UDim2.new(0, 20, 0, 20);
                    BackgroundTransparency = 1;
                    Active = false;
                });
                Parent = game:GetService("CoreGui");
            }):FindFirstChild('Container');
        end
        
        if (not library.options) then
            library.options = setmetatable(options or {}, {__index = defaults})
        end
        
        local window = types.window(name, library.options);
        dragger.new(window.object);
        return window
    end

    function library:Sethideui(bind)
        if typeof(bind) == "EnumItem" and bind.EnumType == Enum.KeyCode then
            library.hideui = bind;
            return true;
        end
        return false;
    end
    
    default = {
        topcolor       = Color3.fromRGB(30, 30, 30);
        titlecolor     = Color3.fromRGB(255, 255, 255);
        
        underlinecolor = _G.UIUnderlineColor;
        bgcolor        = Color3.fromRGB(35, 35, 35);
        boxcolor       = Color3.fromRGB(35, 35, 35);
        btncolor       = Color3.fromRGB(25, 25, 25);
        dropcolor      = Color3.fromRGB(25, 25, 25);
        sectncolor     = Color3.fromRGB(25, 25, 25);
        bordercolor    = Color3.fromRGB(60, 60, 60);

        font           = Enum.Font.SourceSans;
        titlefont      = Enum.Font.Code;

        fontsize       = 17;
        titlesize      = 18;

        textstroke     = 1;
        titlestroke    = 1;

        strokecolor    = Color3.fromRGB(0, 0, 0);

        textcolor      = Color3.fromRGB(255, 255, 255);
        titletextcolor = Color3.fromRGB(255, 255, 255);

        placeholdercolor = Color3.fromRGB(255, 255, 255);
        titlestrokecolor = Color3.fromRGB(0, 0, 0);
    }

    library.options = setmetatable({}, {__index = default})

    spawn(function()
        while true do
            for i=0, 1, 1 / 300 do              
                for _, obj in next, library.rainbowtable do
                    obj.BackgroundColor3 = Color3.fromHSV(i, 1, 1);
                end
                wait()
            end;
        end
    end)

    local function isreallypressed(bind, inp)
        local key = bind
        if typeof(key) == "Instance" then
            if key.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key.KeyCode then
                return true;
            elseif tostring(key.UserInputType):find('MouseButton') and inp.UserInputType == key.UserInputType then
                return true
            end
        end
        if tostring(key):find'MouseButton' then
            return key == inp.UserInputType
        else
            return key == inp.KeyCode
        end
    end

    game:GetService("UserInputService").InputBegan:connect(function(input)
        if library.container and input.KeyCode == library.hideui then
            library.toggled = not library.toggled;
            library.container.Visible = library.toggled;
            return;
        end

        if (not library.binding) then
            for idx, binds in next, library.binds do
                local real_binding = binds.location[idx];
                if real_binding and isreallypressed(real_binding, input) then
                    binds.callback(input, true)
                end
            end
        end
    end)
    game:GetService("UserInputService").InputEnded:connect(function(input)
        if (not library.binding) then
            for idx, binds in next, library.binds do
                local real_binding = binds.location[idx];
                if real_binding and isreallypressed(real_binding, input) then
                    binds.callback(input, false)
                end
            end
        end
    end)
end

return library
