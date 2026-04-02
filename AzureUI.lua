local library = {
	count = 0,
	queue = {},
	callbacks = {},
	rainbowtable = {},
	toggled = true,
	binds = {},
	hideui = _G.HideUI
}
local defaults
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

do
	local dragger = {}
	do
		local players = game:service('Players')
		local player = players.LocalPlayer
		local mouse = player:GetMouse()
		local run = game:service('RunService')
		local stepped = run.Stepped
		dragger.new = function(obj)
			spawn(function()
				local minitial, initial, isdragging
				obj.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						isdragging = true
						minitial = input.Position
						initial = obj.Position
						local con
						con = stepped:Connect(function()
							if isdragging then
								local delta = Vector3.new(mouse.X, mouse.Y, 0) - minitial
								obj.Position = UDim2.new(initial.X.Scale, initial.X.Offset + delta.X, initial.Y.Scale, initial.Y.Offset + delta.Y)
							else
								con:Disconnect()
							end
						end)
						input.Changed:Connect(function()
							if input.UserInputState == Enum.UserInputState.End then
								isdragging = false
							end
						end)
					end
				end)
			end)
		end
	end

	local function getVisibleChildCount(container)
		local count = 0
		for _, child in next, container:GetChildren() do
			if not child:IsA("UIListLayout") then
				count = count + 1
			end
		end
		return count
	end

	local function getContainerHeight(container)
		local y = 0
		for _, child in next, container:GetChildren() do
			if not child:IsA("UIListLayout") then
				y = y + child.AbsoluteSize.Y
			end
		end
		return y + 5
	end

	local function clearNonLayoutChildren(container)
		for _, child in next, container:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	local function safeDisconnect(connection)
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	local types = {}
	do
		types.__index = types

		function types.window(name, options)
			library.count = library.count + 1
			local newWindow = library:Create('Frame', {
				Name = name,
				Size = UDim2.new(0, 240, 0, 38),
				BackgroundColor3 = options.topcolor or Color3.fromRGB(40, 40, 40),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				Parent = library.container,
				Position = UDim2.new(0, (30 + (260 * library.count) - 260), 0, 0),
				ZIndex = 3,
				CornerRadius = library:Create("UICorner", {CornerRadius = UDim.new(0, 10)}),
				library:Create('TextLabel', {
					Text = name,
					Size = UDim2.new(1, -35, 1, 0),
					Position = UDim2.new(0, 16, 0, 0),
					BackgroundTransparency = 1,
					Font = options.titlefont or Enum.Font.GothamBold,
					TextSize = options.titlesize or 19,
					TextColor3 = options.titletextcolor or Color3.fromRGB(255,255,255),
					TextStrokeTransparency = 0.75,
					TextStrokeColor3 = library.options.titlestrokecolor or Color3.fromRGB(0,0,0),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 3
				}),
				library:Create("TextButton", {
					-- smooth toggle button
					Size = UDim2.new(0, 30, 0, 30),
					Position = UDim2.new(1, -35, 0, 0),
					BackgroundTransparency = 1,
					Text = "-",
					TextSize = options.titlesize or 19,
					Font = options.titlefont or Enum.Font.GothamBold,
					Name = 'window_toggle',
					TextColor3 = options.titletextcolor or Color3.fromRGB(255, 255, 255),
					TextStrokeTransparency = 0.75,
					TextStrokeColor3 = library.options.titlestrokecolor or Color3.fromRGB(0,0,0),
					ZIndex = 3
				}),
				library:Create("Frame", {
					Name = 'Underline',
					Size = UDim2.new(1, 0, 0, 3),
					Position = UDim2.new(0, 0, 1, -3),
					BackgroundColor3 = (options.underlinecolor ~= "rainbow" and options.underlinecolor or Color3.new()),
					BorderSizePixel = 0,
					ZIndex = 3,
					library:Create("UICorner", {CornerRadius = UDim.new(1,0)})
				}),
				library:Create('Frame', {
					Name = 'container',
					Position = UDim2.new(0, 0, 1, 0),
					Size = UDim2.new(1, 0, 0, 0),
					BorderSizePixel = 0,
					BackgroundColor3 = options.bgcolor or Color3.fromRGB(40,40,40),
					BackgroundTransparency = 0,
					ClipsDescendants = false,
					library:Create('UIListLayout', {
						Name = 'List',
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 7)
					}),
					library:Create("UICorner", {CornerRadius = UDim.new(0,8)})
				})
			})

			if options.underlinecolor == "rainbow" then
				table.insert(library.rainbowtable, newWindow:FindFirstChild('Underline'))
			end

			local window = setmetatable({
				count = 0,
				object = newWindow,
				container = newWindow.container,
				toggled = true,
				flags = {},
			}, types)

			table.insert(library.queue, {
				w = window.object,
				p = window.object.Position
			})

			newWindow:FindFirstChild("window_toggle").MouseButton1Click:Connect(function()
				window.toggled = not window.toggled
				newWindow:FindFirstChild("window_toggle").Text = (window.toggled and "+" or "-")
				if not window.toggled then
					window.container.ClipsDescendants = true
				end
				wait()
				local targetSize = window.toggled and UDim2.new(1, 0, 0, getContainerHeight(window.container)) or UDim2.new(1, 0, 0, 0)
				local targetDirection = window.toggled and "In" or "Out"
				window.container:TweenSize(targetSize, targetDirection, "Quad", 0.18, true)
				wait(0.16)
				if window.toggled then
					window.container.ClipsDescendants = false
				end
			end)

			return window
		end

		function types:Resize()
			self.container.Size = UDim2.new(1, 0, 0, getContainerHeight(self.container))
		end

		function types:GetOrder()
			return getVisibleChildCount(self.container)
		end

		function types:Toggle(name, options, callback)
			local default  = options.default or false
			local location = options.location or self.flags
			local flag     = options.flag or ""
			local callback = callback or function() end

			location[flag] = default

			local check = library:Create('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 32),
				LayoutOrder = self:GetOrder(),
				library:Create('TextLabel', {
					Name = name,
					Text = name,
					BackgroundTransparency = 1,
					TextColor3 = library.options.textcolor,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -40, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = library.options.font,
					TextSize = library.options.fontsize,
					TextStrokeTransparency = 0.8,
					TextStrokeColor3 = library.options.strokecolor,
				}),
				library:Create("TextButton", {
					Text = (location[flag] and utf8.char(10003) or ""),
					Font = library.options.font,
					TextSize = 16,
					Name = 'Checkmark',
					Size = UDim2.new(0, 22, 0, 22),
					Position = UDim2.new(1, -30, 0.5, -11),
					TextColor3 = (location[flag] and Color3.fromRGB(70, 187, 251) or Color3.fromRGB(220,220,220)),
					BackgroundColor3 = Color3.fromRGB(30,30,35),
					BorderColor3 = Color3.fromRGB(45,45,45),
					TextStrokeTransparency = 0.85,
					TextStrokeColor3 = Color3.fromRGB(0,0,0),
					AutoButtonColor = true,
					library:Create("UICorner", {CornerRadius = UDim.new(0.5,0)})
				})
			})
			check.Parent = self.container

			local function click()
				location[flag] = not location[flag]
				callback(location[flag])
				local checkBtn = check:FindFirstChild('Checkmark')
				checkBtn.Text = location[flag] and utf8.char(10003) or ""
				checkBtn.TextColor3 = location[flag] and Color3.fromRGB(70, 187, 251) or Color3.fromRGB(220,220,220)
			end

			check:FindFirstChild('Checkmark').MouseButton1Click:Connect(click)
			library.callbacks[flag] = click

			if location[flag] == true then callback(location[flag]) end

			self:Resize()
			return {
				Set = function(self, b)
					location[flag] = b
					callback(location[flag])
					local checkBtn = check:FindFirstChild('Checkmark')
					checkBtn.Text = location[flag] and utf8.char(10003) or ""
					checkBtn.TextColor3 = location[flag] and Color3.fromRGB(70, 187, 251) or Color3.fromRGB(220,220,220)
				end
			}
		end

		function types:Button(name, callback)
			callback = callback or function() end

			local check = library:Create('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 32),
				LayoutOrder = self:GetOrder(),
				library:Create('TextButton', {
					Name = name,
					Text = name,
					BackgroundColor3 = Color3.fromRGB(56,132,239),
					BorderColor3 = Color3.fromRGB(36, 36, 64),
					TextStrokeTransparency = 0.85,
					TextStrokeColor3 = library.options.strokecolor,
					TextColor3 = Color3.new(1,1,1),
					Position = UDim2.new(0, 10, 0, 5),
					Size = UDim2.new(1, -20, 0, 24),
					Font = library.options.font,
					TextSize = library.options.fontsize,
					AutoButtonColor = true,
					library:Create("UICorner", {CornerRadius = UDim.new(0.5,0)})
				})
			})
			check.Parent = self.container

			check:FindFirstChild(name).MouseButton1Click:Connect(callback)
			self:Resize()

			return {
				Fire = function() callback() end
			}
		end

		function types:Box(name, options, callback)
			local type   = options.type or ""
			local default = options.default or ""
			local data = options.data
			local location = options.location or self.flags
			local flag     = options.flag or ""
			local callback = callback or function() end
			local min      = options.min or 0
			local max      = options.max or 9e9

			if type == 'number' and (not tonumber(default)) then
				location[flag] = default
			else
				location[flag] = ""
				default = ""
			end

			local check = library:Create('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 32),
				LayoutOrder = self:GetOrder(),
				library:Create('TextLabel', {
					Name = name,
					Text = name,
					BackgroundTransparency = 1,
					TextColor3 = library.options.textcolor,
					TextStrokeTransparency = 0.85,
					TextStrokeColor3 = library.options.strokecolor,
					Font = library.options.font,
					TextSize = library.options.fontsize,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -90, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				library:Create('TextBox', {
					TextStrokeTransparency = 0.85,
					TextStrokeColor3 = library.options.strokecolor,
					Text = tostring(default),
					Font = library.options.font,
					TextSize = library.options.fontsize,
					Name = 'Box',
					Size = UDim2.new(0, 60, 0, 22),
					Position = UDim2.new(1, -68, 0.5, -11),
					TextColor3 = library.options.textcolor,
					BackgroundColor3 = Color3.fromRGB(35,48,65),
					BorderColor3 = library.options.bordercolor,
					PlaceholderColor3 = library.options.placeholdercolor,
					ClearTextOnFocus = false,
					library:Create("UICorner", {CornerRadius = UDim.new(0.5,0)})
				})
			})
			check.Parent = self.container

			local box = check:FindFirstChild('Box')
			box.FocusLost:Connect(function(e)
				local old = location[flag]
				if type == "number" then
					local num = tonumber(box.Text)
					if not num then
						box.Text = tostring(location[flag])
					else
						location[flag] = math.clamp(num, min, max)
						box.Text = tostring(location[flag])
					end
				else
					location[flag] = tostring(box.Text)
				end

				callback(location[flag], old, e)
			end)

			if type == 'number' then
				box:GetPropertyChangedSignal('Text'):Connect(function()
					box.Text = string.gsub(box.Text, "[%a+]", "")
				end)
			end

			self:Resize()
			return box
		end

		function types:Section(name)
			local order = self:GetOrder()
			local determinedSize = UDim2.new(1, 0, 0, 26)
			local determinedPos = UDim2.new(0, 0, 0, 7)
			local secondarySize = UDim2.new(1, 0, 0, 21)
			if order == 0 then
				determinedSize = UDim2.new(1, 0, 0, 24)
				determinedPos = UDim2.new(0, 0, 0, -1)
				secondarySize = nil
			end

			local check = library:Create('Frame', {
				Name = 'Section',
				BackgroundTransparency = 1,
				Size = determinedSize,
				BackgroundColor3 = Color3.fromRGB(45,50,60),
				BorderSizePixel = 0,
				LayoutOrder = order,
				library:Create('TextLabel', {
					Name = 'section_lbl',
					Text = name:upper(),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextColor3 = Color3.fromRGB(163,189,240),
					Position = determinedPos,
					Size = (secondarySize or UDim2.new(1, 0, 1, 0)),
					Font = Enum.Font.GothamBold,
					TextSize = library.options.fontsize,
					TextStrokeTransparency = 0.7,
					TextStrokeColor3 = Color3.fromRGB(0,0,0)
				}),
				Parent = self.container
			})

			self:Resize()
		end

		function types:Slider(name, options, callback)
			local default = options.default or options.min
			local min = options.min or 0
			local max = options.max or 1
			local location = options.location or self.flags
			local precise  = options.precise or false
			local step = options.step or options.increment or (precise and 0.1 or 1)
			local flag = options.flag or ""
			local callback = callback or function() end

			local function normalizeValue(raw)
				local clamped = math.clamp(raw, min, max)
				if precise then
					local snapped = math.floor((clamped / step) + 0.5) * step
					return tonumber(string.format("%.2f", math.clamp(snapped, min, max)))
				end
				return math.floor(clamped)
			end

			location[flag] = default

			local check = library:Create('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 38),
				LayoutOrder = self:GetOrder(),
				library:Create('TextLabel', {
					Name = name,
					TextStrokeTransparency = 0.8,
					TextStrokeColor3 = library.options.strokecolor,
					Text = name,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(210,210,210),
					Position = UDim2.new(0, 12, 0, 2),
					Size = UDim2.new(1, -75, 0, 18),
					TextXAlignment = Enum.TextXAlignment.Left,
					Font = library.options.font,
					TextSize = library.options.fontsize,
				}),
				library:Create('Frame', {
					Name = 'SliderBarBG',
					Size = UDim2.new(1, -60, 0, 10),
					Position = UDim2.new(0, 12, 0, 22),
					BackgroundColor3 = Color3.fromRGB(30,30,38),
					BorderSizePixel = 0,
					library:Create("UICorner", {CornerRadius = UDim.new(1,0)}),
					library:Create('Frame', {
						Name = 'SliderBarFG',
						Size = UDim2.new(0, 0, 1, 0),
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundColor3 = Color3.fromRGB(75, 186, 254),
						BorderSizePixel = 0,
						library:Create("UICorner", {CornerRadius = UDim.new(1,0)})
					}),
					library:Create('TextButton', {
						Name = 'Button',
						Size = UDim2.new(0, 18, 0, 18),
						Position = UDim2.new(0, -9, 0.5, -9),
						AutoButtonColor = false,
						Text = "",
						BackgroundColor3 = Color3.fromRGB(255,255,255),
						BackgroundTransparency = 0,
						BorderSizePixel = 0,
						ZIndex = 2,
						library:Create("UICorner", {CornerRadius = UDim.new(1,0)})
					})
				}),
				library:Create('TextLabel', {
					Name = 'ValueLabel',
					TextStrokeTransparency = 0.8,
					TextStrokeColor3 = library.options.strokecolor,
					Text = tostring(default),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(90, 190, 250),
					Position = UDim2.new(1, -45, 0, 14),
					Size = UDim2.new(0, 34, 0, 22),
					TextXAlignment = Enum.TextXAlignment.Right,
					Font = library.options.font,
					TextSize = 15,
				})
			})
			check.Parent = self.container

			local overlay = check

			local sliderBarBG = check:FindFirstChild('SliderBarBG')
			local sliderBarFG = sliderBarBG:FindFirstChild('SliderBarFG')
			local sliderButton = sliderBarBG:FindFirstChild('Button')
			local valueLabel = check:FindFirstChild('ValueLabel')

			local renderSteppedConnection
			local mouseDownConnection
			local mouseUpConnection

			local function setSlider(percent)
				percent = math.clamp(percent, 0, 1)
				local num = min + (max - min) * percent
				local value = normalizeValue(num)
				location[flag] = tonumber(value)
				sliderBarFG.Size = UDim2.new(percent, 0, 1, 0)
				sliderButton.Position = UDim2.new(percent, -9, 0.5, -9)
				valueLabel.Text = tostring(value)
				callback(tonumber(value))
			end

			local function updateSliderWithMouse()
				if renderSteppedConnection then renderSteppedConnection:Disconnect() end

				renderSteppedConnection = RunService.RenderStepped:Connect(function()
					local mouse = UIS:GetMouseLocation()
					local rel = mouse.X - sliderBarBG.AbsolutePosition.X
					local percent = rel / sliderBarBG.AbsoluteSize.X
					setSlider(percent)
				end)
			end

			local function disconnectSliderDragging()
				safeDisconnect(renderSteppedConnection)
				safeDisconnect(mouseDownConnection)
				safeDisconnect(mouseUpConnection)
			end

			sliderBarBG.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					updateSliderWithMouse()
				end
			end)

			sliderButton.MouseButton1Down:Connect(function()
				updateSliderWithMouse()
			end)

			mouseUpConnection = UIS.InputEnded:Connect(function(a)
				if a.UserInputType == Enum.UserInputType.MouseButton1 then
					disconnectSliderDragging()
				end
			end)

			-- Set initial slider value and visuals
			do
				local percent = (default - min) / (max - min)
				setSlider(percent or 0)
			end

			self:Resize()
			return {
				Set = function(self, value)
					local percent = (value - min) / (max - min)
					setSlider(percent)
				end
			}
		end

		-- Rest: SearchBox, Dropdown stay mostly visually clean
		function types:SearchBox(text, options, callback)
			local list = options.list or {}
			local flag = options.flag or ""
			local location = options.location or self.flags
			local callback = callback or function() end

			local busy = false
			local box = library:Create('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 32),
				LayoutOrder = self:GetOrder(),
				library:Create('TextBox', {
					Text = "",
					PlaceholderText = text,
					PlaceholderColor3 = Color3.fromRGB(85, 85, 105),
					Font = library.options.font,
					TextSize = library.options.fontsize,
					Name = 'Box',
					Size = UDim2.new(1, -15, 0, 24),
					Position = UDim2.new(0, 7, 0, 4),
					TextColor3 = Color3.fromRGB(250,250,250),
					BackgroundColor3 = Color3.fromRGB(40,50,65),
					BorderColor3 = Color3.fromRGB(30,30,38),
					ClearTextOnFocus = false,
					TextStrokeTransparency = 1,
					library:Create("UICorner", {CornerRadius = UDim.new(0.3,0)}),
					library:Create('ScrollingFrame', {
						Position = UDim2.new(0, 0, 1, 2),
						Name = 'Container',
						BackgroundColor3 = Color3.fromRGB(35,40,70),
						ScrollBarThickness = 0,
						BorderSizePixel = 0,
						BorderColor3 = Color3.fromRGB(45,45,65),
						Size = UDim2.new(1, 0, 0, 0),
						library:Create('UIListLayout', {
							Name = 'ListLayout',
							SortOrder = Enum.SortOrder.LayoutOrder
						}),
						ZIndex = 2,
						library:Create("UICorner", {CornerRadius = UDim.new(0.2,0)})
					})
				})
			})
			box.Parent = self.container

			local function rebuild(text)
				box:FindFirstChild('Box').Container.ScrollBarThickness = 0
				clearNonLayoutChildren(box:FindFirstChild('Box').Container)

				if #text > 0 then
					for i, v in next, list do
						if string.sub(string.lower(v), 1, string.len(text)) == string.lower(text) then
							local button = library:Create('TextButton', {
								Text = v,
								Font = library.options.font,
								TextSize = library.options.fontsize,
								TextColor3 = Color3.fromRGB(225,225,225),
								BorderColor3 = Color3.fromRGB(40,40,68),
								TextStrokeTransparency = 1,
								Parent = box:FindFirstChild('Box').Container,
								Size = UDim2.new(1, 0, 0, 22),
								LayoutOrder = i,
								BackgroundColor3 = Color3.fromRGB(57,64,109),
								ZIndex = 2,
								library:Create("UICorner", {CornerRadius = UDim.new(0.2,0)})
							})

							button.MouseButton1Click:Connect(function()
								busy = true
								box:FindFirstChild('Box').Text = button.Text
								wait()
								busy = false

								location[flag] = button.Text
								callback(location[flag])

								box:FindFirstChild('Box').Container.ScrollBarThickness = 0
								clearNonLayoutChildren(box:FindFirstChild('Box').Container)
								box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, 0), 'Out', 'Quad', 0.22, true)
							end)
						end
					end
				end

				local c = box:FindFirstChild('Box').Container:GetChildren()
				local y = math.clamp(22 * (#c), 0, 100)
				if y > 98 then
					box:FindFirstChild('Box').Container.ScrollBarThickness = 5
				end
				box:FindFirstChild('Box').Container:TweenSize(UDim2.new(1, 0, 0, y), 'Out', 'Quad', 0.18, true)
				box:FindFirstChild('Box').Container.CanvasSize = UDim2.new(1, 0, 0, (22 * (#c)))
			end

			box:FindFirstChild('Box'):GetPropertyChangedSignal('Text'):Connect(function()
				if not busy then
					rebuild(box:FindFirstChild('Box').Text)
				end
			end)

			local function reload(new_list)
				list = new_list
				rebuild("")
			end
			self:Resize()
			return reload, box:FindFirstChild('Box')
		end

		function types:Dropdown(name, options, callback)
			local location = options.location or self.flags
			local flag = options.flag or ""
			local callback = callback or function() end
			local list = options.list or {}

			location[flag] = list[1]
			local check = library:Create('Frame', {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 35),
				BackgroundColor3 = Color3.fromRGB(25, 25, 25),
				BorderSizePixel = 0,
				LayoutOrder = self:GetOrder(),
				library:Create("Frame", {
					Name = 'dropdown_lbl',
					BackgroundTransparency = 0,
					BackgroundColor3 = Color3.fromRGB(49,51,65),
					Position = UDim2.new(0, 8, 0, 6),
					BorderColor3 = Color3.fromRGB(80,80,128),
					Size = UDim2.new(1, -16, 0, 24),
					library:Create("UICorner", {CornerRadius = UDim.new(0.35,0)}),
					library:Create("TextLabel", {
						Name = 'Selection',
						Size = UDim2.new(1, 0, 1, 0),
						Text = list[1],
						TextColor3 = Color3.fromRGB(220, 220, 245),
						BackgroundTransparency = 1,
						Font = library.options.font,
						TextSize = library.options.fontsize,
						TextStrokeTransparency = 1,
					}),
					library:Create("TextButton", {
						Name = 'drop',
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 22, 1, 0),
						Position = UDim2.new(1, -28, 0, 2),
						Text = '▼',
						TextColor3 = Color3.fromRGB(120, 140,180),
						Font = Enum.Font.Gotham,
						TextSize = 17,
						TextStrokeTransparency = 1
					})
				})
			})
			check.Parent = self.container

			local button = check:FindFirstChild('dropdown_lbl').drop
			local input

			button.MouseButton1Click:Connect(function()
				if input and input.Connected then return end

				local selLabel = check:FindFirstChild('dropdown_lbl').Selection
				selLabel.TextColor3 = Color3.fromRGB(90, 100, 110)
				selLabel.Text = name
				local c = 0
				for i, v in next, list do c = c + 22 end

				local size = UDim2.new(1, 0, 0, c)
				local clampedSize
				local scrollSize = 0
				if size.Y.Offset > 120 then
					clampedSize = UDim2.new(1, 0, 0, 120)
					scrollSize = 5
				end

				local goSize = clampedSize or size
				local container = library:Create('ScrollingFrame', {
					Name = 'DropContainer',
					Parent = check:FindFirstChild('dropdown_lbl'),
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromRGB(44,45,60),
					BorderColor3 = Color3.fromRGB(60,60,110),
					Position = UDim2.new(0, 0, 1, 0),
					ScrollBarThickness = scrollSize,
					CanvasSize = UDim2.new(0, 0, 0, size.Y.Offset),
					ZIndex = 5,
					ClipsDescendants = true,
					library:Create('UIListLayout', {
						Name = 'List',
						SortOrder = Enum.SortOrder.LayoutOrder
					}),
					library:Create("UICorner", {CornerRadius = UDim.new(0.18,0)})
				})

				for i, v in next, list do
					local btn = library:Create('TextButton', {
						Size = UDim2.new(1, 0, 0, 22),
						BackgroundColor3 = Color3.fromRGB(66,74,115),
						BorderColor3 = Color3.fromRGB(45,45,65),
						Text = v,
						Font = library.options.font,
						TextSize = library.options.fontsize,
						LayoutOrder = i,
						Parent = container,
						ZIndex = 5,
						TextColor3 = Color3.fromRGB(230,230,250),
						TextStrokeTransparency = 1,
						library:Create("UICorner", {CornerRadius = UDim.new(0.22,0)})
					})
					btn.MouseButton1Click:Connect(function()
						selLabel.TextColor3 = Color3.fromRGB(220, 220, 245)
						selLabel.Text = btn.Text
						location[flag] = tostring(btn.Text)
						callback(location[flag])
						Debris:AddItem(container, 0)
						if input then input:Disconnect() end
					end)
				end

				container:TweenSize(goSize, 'Out', 'Quad', 0.14, true)
				local function isInGui(frame)
					local mloc = UIS:GetMouseLocation()
					local mouse = Vector2.new(mloc.X, mloc.Y - 36)
					local x1, x2 = frame.AbsolutePosition.X, frame.AbsolutePosition.X + frame.AbsoluteSize.X
					local y1, y2 = frame.AbsolutePosition.Y, frame.AbsolutePosition.Y + frame.AbsoluteSize.Y
					return (mouse.X >= x1 and mouse.X <= x2) and (mouse.Y >= y1 and mouse.Y <= y2)
				end
				input = UIS.InputBegan:Connect(function(a)
					if a.UserInputType == Enum.UserInputType.MouseButton1 and (not isInGui(container)) then
						selLabel.TextColor3 = Color3.fromRGB(220, 220, 245)
						selLabel.Text = location[flag]
						container:TweenSize(UDim2.new(1, 0, 0, 0), 'In', 'Quad', 0.13, true)
						wait(0.13)
						Debris:AddItem(container, 0)
						if input then input:Disconnect() end
					end
				end)
			end)

			self:Resize()
			local function reload(self, array)
				options = array
				location[flag] = array[1]
				pcall(function() input:Disconnect() end)
				check:WaitForChild('dropdown_lbl').Selection.Text = location[flag]
				check:FindFirstChild('dropdown_lbl').Selection.TextColor3 = Color3.fromRGB(220, 220, 245)
			end

			return { Refresh = reload }
		end
	end

	function library:Create(class, data)
		local obj = Instance.new(class)
		for i, v in next, data do
			if i ~= 'Parent' then
				if typeof(v) == "Instance" then
					v.Parent = obj
				else
					obj[i] = v
				end
			end
		end
		if data.CornerRadius then
			local uicor = Instance.new("UICorner")
			uicor.CornerRadius = data.CornerRadius
			uicor.Parent = obj
		end
		obj.Parent = data.Parent
		return obj
	end

	function library:CreateWindow(name, options)
		if not library.container then
			library.container = self:Create("ScreenGui", {
				self:Create('Frame', {
					Name = 'Container',
					Size = UDim2.new(1, -30, 1, 0),
					Position = UDim2.new(0, 20, 0, 20),
					BackgroundTransparency = 0.65,
					Active = false,
					library:Create("UICorner", {CornerRadius = UDim.new(0.1, 6)})
				}),
				Parent = game:GetService("CoreGui")
			}):FindFirstChild('Container')
		end

		if not library.options then
			library.options = setmetatable(options or {}, {__index = defaults})
		end

		local window = types.window(name, library.options)
		dragger.new(window.object)
		return window
	end

	function library:Sethideui(bind)
		if typeof(bind) == "EnumItem" and bind.EnumType == Enum.KeyCode then
			library.hideui = bind
			return true
		end
		return false
	end

	default = {
		topcolor       = Color3.fromRGB(40, 48, 70),
		titlecolor     = Color3.fromRGB(255, 255, 255),
		underlinecolor = _G.UIUnderlineColor,
		bgcolor        = Color3.fromRGB(37, 41, 56),
		boxcolor       = Color3.fromRGB(35, 48, 65),
		btncolor       = Color3.fromRGB(41, 58, 110),
		dropcolor      = Color3.fromRGB(41, 58, 110),
		sectncolor     = Color3.fromRGB(57, 76, 119),
		bordercolor    = Color3.fromRGB(60, 72, 102),
		font           = Enum.Font.Gotham,
		titlefont      = Enum.Font.GothamBold,
		fontsize       = 17,
		titlesize      = 19,
		textstroke     = 1,
		titlestroke    = 1,
		strokecolor    = Color3.fromRGB(0, 0, 0),
		textcolor      = Color3.fromRGB(230, 230, 242),
		titletextcolor = Color3.fromRGB(240, 249, 255),
		placeholdercolor = Color3.fromRGB(145, 145, 160),
		titlestrokecolor = Color3.fromRGB(32, 36, 41)
	}

	library.options = setmetatable({}, {__index = default})

	-- Rainbow underline color loop
	spawn(function()
		while true do
			for i = 0, 1, 1 / 300 do
				for _, obj in next, library.rainbowtable do
					obj.BackgroundColor3 = Color3.fromHSV(i, 1, 1)
				end
				wait()
			end
		end
	end)

	local function isreallypressed(bind, inp)
		local key = bind
		if typeof(key) == "Instance" then
			if key.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key.KeyCode then
				return true
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

	game:GetService("UserInputService").InputBegan:Connect(function(input)
		if library.container and input.KeyCode == library.hideui then
			library.toggled = not library.toggled
			library.container.Visible = library.toggled
			return
		end
		if not library.binding then
			for idx, binds in next, library.binds do
				local real_binding = binds.location[idx]
				if real_binding and isreallypressed(real_binding, input) then
					binds.callback(input, true)
				end
			end
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if not library.binding then
			for idx, binds in next, library.binds do
				local real_binding = binds.location[idx]
				if real_binding and isreallypressed(real_binding, input) then
					binds.callback(input, false)
				end
			end
		end
	end)
end

return library
