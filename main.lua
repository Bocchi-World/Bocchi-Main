-- Bocchi (MacUI bundle) | https://github.com/Ngducok/MacUI-luau
local MacUI = (function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local UI = (function()
		-- MacUI | https://github.com/Ngducok/MacUI-luau
		local nodes = { [""] = { Name = "MacUI" } }
		for _, path in
			{
				"Components",
				"Core",
				"Data",
				"Overlays",
				"Window",
				"Components/AnimatedImage",
				"Components/AutoPlayFeature",
				"Components/Button",
				"Components/Card",
				"Components/ColorPicker",
				"Components/Control",
				"Components/Crafting",
				"Components/Display",
				"Components/Dropdown",
				"Components/Input",
				"Components/Keybind",
				"Components/PrioritySelector",
				"Components/Slider",
				"Components/Toggle",
				"Components/Traits",
				"Components/UpdateLog",
				"Core/Animations",
				"Core/Blur",
				"Core/Cleanup",
				"Core/Factory",
				"Core/Icons",
				"Core/Input",
				"Core/Registry",
				"Core/Store",
				"Core/Theme",
				"Core/Util",
				"Data/UpdateLogs",
				"Overlays/CommandPalette",
				"Overlays/Dialog",
				"Overlays/Notifications",
				"Overlays/PopupManager",
				"Window/Account",
				"Window/DragResize",
				"Window/MobileLauncher",
				"Window/Page",
				"Window/Section",
				"Window/Sidebar",
				"Window/Window",
				"Components/AutoPlayFeature/UnitSettingsStore",
				"Components/AutoPlayFeature/UnitCatalogStore",
				"Components/Crafting/CraftingStore",
				"Components/Crafting/Views",
			}
		do
			local parent, name = string.match(path, "^(.*)/([^/]+)$")
			if not name then
				parent, name = "", path
			end
			local node = { Name = name, Parent = nodes[parent] }
			nodes[path] = node
			node.Parent[name] = node
		end
		local loaders, cache, loading = {}, {}, {}

		-- Components/AnimatedImage
		loaders[nodes["Components/AnimatedImage"]] = function(script, require)
			local RunService = game:GetService("RunService")

			local Factory = require(script.Parent.Parent.Core.Factory)
			local Animations = require(script.Parent.Parent.Core.Animations)

			local AnimatedImage = {}
			AnimatedImage.__index = AnimatedImage

			local active = {}
			local heartbeat
			local clock = 0

			local function onScreen(inst: GuiObject): boolean
				local node: Instance? = inst
				while node and not node:IsA("LayerCollector") do
					if node:IsA("GuiObject") and not node.Visible then
						return false
					end
					node = node.Parent
				end
				return node ~= nil and (node :: any).Enabled ~= false
			end

			local function step(dt: number)
				clock += dt
				for anim in active do
					if clock < anim.nextCheck then
						continue
					end
					anim.nextCheck = clock + 1 / anim.fps
					if anim.paused or Animations.reducedMotion or not onScreen(anim.Instance) then
						continue
					end
					anim:_advance()
				end
			end

			local function track(anim)
				active[anim] = true
				if not heartbeat then
					heartbeat = RunService.Heartbeat:Connect(step)
				end
			end

			local function untrack(anim)
				active[anim] = nil
				if heartbeat and next(active) == nil then
					heartbeat:Disconnect()
					heartbeat = nil
				end
			end

			export type Options = {
				Image: string,
				FrameSize: Vector2,
				Columns: number,
				Frames: number,
				FPS: number?,
				Loop: boolean?,
				Autoplay: boolean?,
				Speed: number?,
				Size: UDim2?,
			}

			function AnimatedImage.new(options: Options)
				assert(options.Image, "AnimatedImage needs Image")
				assert(
					options.FrameSize and options.Columns and options.Frames,
					"AnimatedImage needs FrameSize, Columns and Frames"
				)

				local self = setmetatable({
					frame = 0,
					frames = options.Frames,
					columns = options.Columns,
					frameSize = options.FrameSize,
					baseFps = options.FPS or 12,
					speed = options.Speed or 1,
					loop = options.Loop ~= false,
					paused = options.Autoplay == false,
					nextCheck = 0,
				}, AnimatedImage)
				self.fps = math.max(1, self.baseFps * self.speed)

				self.Instance = Factory.new("ImageLabel", {
					Size = options.Size or UDim2.fromOffset(options.FrameSize.X, options.FrameSize.Y),
					BackgroundTransparency = 1,
					Image = options.Image,
					ImageRectSize = options.FrameSize,
					ScaleType = Enum.ScaleType.Fit,
				})
				self:_render()
				track(self)
				return self
			end

			function AnimatedImage:_render()
				local col = self.frame % self.columns
				local row = self.frame // self.columns
				self.Instance.ImageRectOffset = Vector2.new(col * self.frameSize.X, row * self.frameSize.Y)
			end

			function AnimatedImage:_advance()
				local nextFrame = self.frame + 1
				if nextFrame >= self.frames then
					if not self.loop then
						self.paused = true
						return
					end
					nextFrame = 0
				end
				self.frame = nextFrame
				self:_render()
			end

			function AnimatedImage:Play()
				if not self.loop and self.frame >= self.frames - 1 then
					self.frame = 0
					self:_render()
				end
				self.paused = false
			end

			function AnimatedImage:Pause()
				self.paused = true
			end

			function AnimatedImage:SetFrame(index: number)
				self.frame = math.clamp(index, 0, self.frames - 1)
				self:_render()
			end

			function AnimatedImage:SetSpeed(speed: number)
				self.speed = speed
				self.fps = math.max(1, self.baseFps * speed)
			end

			function AnimatedImage:IsPlaying(): boolean
				return not self.paused
			end

			function AnimatedImage:Destroy()
				untrack(self)
				self.Instance:Destroy()
			end

			function AnimatedImage.activeCount(): number
				local count = 0
				for _ in active do
					count += 1
				end
				return count
			end

			return AnimatedImage
		end

		-- Components/AutoPlayFeature/UnitSettingsStore
		loaders[nodes["Components/AutoPlayFeature/UnitSettingsStore"]] = function(script, require)
			local Settings = {}
			Settings.PlacementOptions = {
				PlacementMode = { "Default", "Circle" },
				PositionMode = { "Per Slot", "Shared Position", "Path" },
				PathTarget = { "Path 1", "Path 2", "Between Paths" },
			}
			local function number(value, default, name)
				value = if value == nil then default else value
				assert(
					type(value) == "number"
						and value >= 0
						and value <= 100000
						and (name:find("Delay") or value % 1 == 0),
					`Invalid {name}`
				)
				return value
			end
			local function name(value)
				assert(type(value) == "string" and value:match("%S"), "Unit ID or preset name is missing")
				return value
			end
			function Settings.normalize(records)
				assert(type(records) == "table", "Unit settings must be an array")
				local result, seen = {}, {}
				for _, record in ipairs(records) do
					assert(type(record) == "table", "Invalid unit settings")
					local id = name(record.UnitId)
					assert(not seen[id], "Duplicate unit settings: " .. id)
					seen[id] = true
					assert(record.FocusFarm == nil or type(record.FocusFarm) == "boolean", "Invalid FocusFarm")
					local unit = { UnitId = id, FocusFarm = record.FocusFarm == true }
					for _, field in
						{ "PlaceCap", "UpgradeCap", "PlaceWave", "UpgradeWave", "PlaceDelay", "UpgradeDelay" }
					do
						unit[field] = number(record[field], if field:find("Wave") then 1 else 0, field)
					end
					for field, choices in Settings.PlacementOptions do
						if record[field] ~= nil then
							assert(table.find(choices, record[field]), "Invalid " .. field)
							unit[field] = record[field]
						end
					end
					if record.PathPosition ~= nil then
						unit.PathPosition = number(record.PathPosition, 0, "PathPosition")
						assert(unit.PathPosition <= 100, "Invalid PathPosition")
					end
					table.insert(result, unit)
				end
				for key in records do
					assert(
						type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #result,
						"Unit settings must be a dense array"
					)
				end
				return result
			end
			-- Version 1 action queues become one settings record per owned UUID.
			function Settings.fromSteps(steps)
				assert(type(steps) == "table", "Invalid legacy queue")
				local records, byId = {}, {}
				for _, step in ipairs(steps) do
					assert(
						type(step) == "table" and (step.Action == "Place" or step.Action == "Upgrade"),
						"Invalid legacy action"
					)
					local id = name(step.UnitId)
					local unit = byId[id]
					if not unit then
						unit = { UnitId = id, PlaceCap = 0, UpgradeCap = 0 }
						byId[id] = unit
						table.insert(records, unit)
					end
					assert(step.Enabled == nil or type(step.Enabled) == "boolean", "Invalid legacy enabled state")
					local cap = number(if step.Action == "Place" then step.Count else step.TargetLevel, 1, "legacy cap")
					local wave = step.Wave
					if wave == nil and step.Condition and step.Condition ~= "" then
						assert(type(step.Condition) == "string", "Invalid legacy condition")
						wave = tonumber(step.Condition:match("^[Ww]ave%s+(%d+)$"))
						assert(wave, "Invalid legacy wave")
					end
					wave = number(wave, 1, "legacy wave")
					local delay = step.Delay or 0
					assert(type(delay) == "number" and delay >= 0 and delay <= 100000, "Invalid legacy delay")
					if step.Enabled ~= false and cap > 0 then
						local action = step.Action
						unit[action .. "Cap"] = math.max(unit[action .. "Cap"], cap)
						-- ponytail: multiple schedules collapse to the latest wave and highest cap; use separate wave milestones if needed later.
						unit[action .. "Wave"] = math.max(unit[action .. "Wave"] or 0, wave)
						unit[action .. "Delay"] = math.max(unit[action .. "Delay"] or 0, delay)
					end
				end
				return Settings.normalize(records)
			end
			function Settings.normalizeState(value)
				assert(type(value) == "table" and type(value.Presets) == "table", "Invalid Auto Play settings")
				local legacy = value.Units == nil and value.Steps ~= nil
				local result = {
					Units = if legacy then Settings.fromSteps(value.Steps) else Settings.normalize(value.Units),
					Presets = {},
				}
				for preset, records in value.Presets do
					result.Presets[name(preset)] = if legacy
						then Settings.fromSteps(records)
						else Settings.normalize(records)
				end
				if value.ActivePreset ~= nil then
					assert(result.Presets[name(value.ActivePreset)], "Active config does not exist")
					result.ActivePreset = value.ActivePreset
				end
				return result
			end
			return Settings
		end

		-- Components/AutoPlayFeature/UnitCatalogStore
		loaders[nodes["Components/AutoPlayFeature/UnitCatalogStore"]] = function(script, require)
			local Catalog = {}
			Catalog.__index = Catalog

			local function text(value, name)
				assert(type(value) == "string" and value:match("%S"), `{name} must be a non-empty string`)
				return value
			end

			function Catalog.toImageUri(value)
				if type(value) == "number" then
					if value <= 0 or value % 1 ~= 0 or value > 9007199254740991 then
						return nil
					end
					value = string.format("%.0f", value)
				end
				if type(value) ~= "string" then
					return nil
				end
				local digits = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
				return if digits and digits:match("[1-9]") then "rbxassetid://" .. digits else nil
			end

			function Catalog.new(records)
				assert(type(records) == "table", "UnitCatalog must be an array")
				local self = setmetatable({ units = {}, byId = {} }, Catalog)
				for i, record in ipairs(records) do
					assert(type(record) == "table", "Unit record must be a table")
					local id = text(record.UnitId, "UnitId")
					assert(not self.byId[id], `Duplicate UnitId: {id}`)
					local image = Catalog.toImageUri(record.ImageAssetId)
					if not image and not record.ViewportSource then
						warn(`[MacUI Auto Play] {id}: waiting for unit portrait`)
					end
					assert(record.Rarity == nil or type(record.Rarity) == "string", "Rarity must be a string")
					assert(
						record.MaxPlace == nil
							or type(record.MaxPlace) == "number"
								and record.MaxPlace > 0
								and record.MaxPlace < math.huge
								and record.MaxPlace % 1 == 0,
						"MaxPlace must be a positive integer"
					)
					assert(
						record.MaxUpgrade == nil
							or type(record.MaxUpgrade) == "number"
								and record.MaxUpgrade >= 0
								and record.MaxUpgrade <= 100000
								and record.MaxUpgrade % 1 == 0,
						"MaxUpgrade must be a nonnegative integer"
					)
					assert(record.IsFarm == nil or type(record.IsFarm) == "boolean", "IsFarm must be a boolean")
					assert(record.Variants == nil or type(record.Variants) == "table", "Variants must be an array")
					local unit = {
						UnitId = id,
						Name = text(record.Name, "Name"),
						ImageAssetId = image,
						Rarity = record.Rarity,
						IsFarm = record.IsFarm == true,
						MaxPlace = record.MaxPlace,
						MaxUpgrade = record.MaxUpgrade,
						Slot = record.Slot,
						ViewportSource = record.ViewportSource,
						Variants = {},
					}
					local seen = {}
					for _, variant in ipairs(record.Variants or {}) do
						assert(type(variant) == "table", "Variant must be a table")
						local variantId = text(variant.VariantId, "VariantId")
						assert(not seen[variantId], `Duplicate VariantId: {variantId}`)
						seen[variantId] = true
						local uri = Catalog.toImageUri(variant.ImageAssetId)
						if variant.ImageAssetId ~= nil and not uri then
							warn(`[MacUI Auto Play] {id}/{variantId}: invalid ImageAssetId; using base image`)
						end
						table.insert(
							unit.Variants,
							table.freeze({
								VariantId = variantId,
								Name = text(variant.Name or variantId, "Variant name"),
								ImageAssetId = uri,
							})
						)
					end
					table.freeze(unit.Variants)
					self.units[i], self.byId[id] = table.freeze(unit), unit
				end
				for key in records do
					assert(
						type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #self.units,
						"UnitCatalog must be a dense array"
					)
				end
				return self
			end

			function Catalog:Get(id)
				return self.byId[id]
			end

			function Catalog:Search(query)
				query = string.lower(query or "")
				local result = {}
				for _, unit in self.units do
					if string.find(string.lower(`{unit.Name} {unit.Rarity or ""} {unit.UnitId}`), query, 1, true) then
						table.insert(result, unit)
					end
				end
				return result
			end

			function Catalog:Image(id, variantId)
				local unit = self:Get(id)
				if not unit then
					return nil
				end
				for _, variant in unit.Variants do
					if variant.VariantId == variantId then
						return variant.ImageAssetId or unit.ImageAssetId, unit.ViewportSource
					end
				end
				return unit.ImageAssetId, unit.ViewportSource
			end

			return Catalog
		end

		-- Components/AutoPlayFeature
		loaders[nodes["Components/AutoPlayFeature"]] = function(script, require)
			local Components = script.Parent
			local Core = Components.Parent.Core
			local Factory = require(Core.Factory)
			local Theme = require(Core.Theme)
			local Icons = require(Core.Icons)
			local Animations = require(Core.Animations)
			local Cleanup = require(Core.Cleanup)
			local Store = require(Core.Store)
			local Util = require(Core.Util)
			local Control = require(Components.Control)
			local Dropdown = require(Components.Dropdown)
			local Input = require(Components.Input)
			local Toggle = require(Components.Toggle)
			local Button = require(Components.Button)
			local Display = require(Components.Display)
			local Catalog = require(script.UnitCatalogStore)
			local Settings = require(script.UnitSettingsStore)
			local AutoPlay = Control.extend("AutoPlay")
			local PAD, GAP, HEAD, LINE, UNIT_ROW = 12, 12, 24, 28, 48
			local LIST_TOP, MIN_PANE = 94, 380
			local function motion(animate, key)
				return if animate then Theme.Motion[key] else nil
			end
			local function text(parent, props)
				props.Parent = parent
				return Factory.text(props)
			end
			local function thumbnail(parent, size, cleanup)
				local radius = math.max(6, math.round(size * 0.24))
				local root = Factory.new("Frame", {
					Name = "Thumbnail",
					Size = UDim2.fromOffset(size, size),
					Parent = parent,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(radius) })
				local fallback = Icons.create({ Icon = "person", Color = "TextMuted" }, math.round(size * 0.5), {
					Name = "Fallback",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = root,
				})
				local image = Factory.new("ImageLabel", {
					Name = "UnitImage",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = "",
					ScaleType = Enum.ScaleType.Crop,
					Parent = root,
				}, { Factory.corner(radius) })
				local viewport, source
				local function loaded()
					fallback.Visible = not viewport and (image.Image == "" or not image.IsLoaded)
				end
				cleanup:connect(image:GetPropertyChangedSignal("IsLoaded"), loaded)
				return {
					Instance = root,
					Set = function(_, uri, view)
						image.Image = uri or ""
						if source ~= view or uri and viewport then
							if viewport then
								viewport:Destroy()
								viewport = nil
							end
							source = view
							if not uri and view and view:IsA("ViewportFrame") then
								local ok, clone = pcall(function()
									return view:Clone()
								end)
								if ok and clone then
									viewport = clone
									for _, item in clone:GetDescendants() do
										if item:IsA("LuaSourceContainer") then
											item:Destroy()
										end
									end
									clone.Name, clone.Position, clone.AnchorPoint =
										"UnitViewport", UDim2.fromOffset(0, 0), Vector2.zero
									clone.Size, clone.BackgroundTransparency, clone.Visible =
										UDim2.fromScale(1, 1), 1, true
									clone.ZIndex, clone.Parent = image.ZIndex + 1, root
									if view.CurrentCamera then
										local camera = view.CurrentCamera:Clone()
										camera.Parent, clone.CurrentCamera = clone, camera
									end
								end
							end
						end
						loaded()
					end,
				}
			end

			local function describe(unit)
				local parts = {}
				if unit.Slot then
					table.insert(parts, `Slot {unit.Slot}`)
				end
				if unit.Rarity then
					table.insert(parts, unit.Rarity)
				end
				if unit.MaxPlace then
					table.insert(parts, `max {unit.MaxPlace}`)
				end
				return table.concat(parts, ", ")
			end

			function AutoPlay:_action(fn)
				return function(...)
					if self.disabled or self.destroyed then
						return
					end
					self:_notice("")
					local ok, err = pcall(fn, ...)
					if not ok then
						self:_notice(string.gsub(tostring(err), "^.-:%d+: ", ""), true)
					end
				end
			end

			function AutoPlay:_notice(message, isError)
				self.message.Text = message
				self.message.Visible = message ~= ""
				Theme.bind(self.message, { TextColor3 = if isError then "Danger" else "TextSecondary" })
			end

			function AutoPlay:_control(class, parent, options, cleanup)
				options.Searchable = false
				local control = class.new(self.editCtx, parent, options);
				(cleanup or self.cleanup):add(control)
				return control
			end

			function AutoPlay:_flattenHost(parent)
				local node = parent
				for _ = 1, 4 do
					node = node and node.Parent
					if node and node.Name == "Group" and node:IsA("Frame") then
						local cards = 0
						for _, child in node:GetChildren() do
							if child:IsA("GuiObject") then
								cards += 1
							end
						end
						if cards ~= 1 then
							return
						end
						local group, alpha = node, node.BackgroundTransparency
						group.BackgroundTransparency = 1
						local padding = parent:FindFirstChildOfClass("UIPadding")
						local saved = if padding
							then { padding.PaddingTop, padding.PaddingRight, padding.PaddingBottom, padding.PaddingLeft }
							else nil
						if padding then
							padding.PaddingTop, padding.PaddingRight, padding.PaddingBottom, padding.PaddingLeft =
								UDim.new(), UDim.new(), UDim.new(), UDim.new()
						end
						self.cleanup:add(function()
							group.BackgroundTransparency = alpha
							if padding then
								padding.PaddingTop, padding.PaddingRight, padding.PaddingBottom, padding.PaddingLeft =
									table.unpack(saved)
							end
						end)
						return
					end
				end
			end

			function AutoPlay.new(ctx, parent, options)
				options = table.clone(options or {})
				local self =
					setmetatable(Control.new(ctx, parent, { LayoutOrder = options.LayoutOrder }, true), AutoPlay)
				self.options, self.catalog = options, Catalog.new(options.UnitCatalog or {})
				self.unitRows, self.defaults, self.presets = {}, {}, {}
				self.Instance.Name = options.Id or "AutoPlay"
				self.Instance:SetAttribute("NoWindowDrag", true)
				self.editCtx = setmetatable({ store = Store.new() }, { __index = ctx })
				self.catalogCleanup = self.cleanup:add(Cleanup.new())
				self.id = ctx.store:define(options.Id, { Units = {}, Presets = {} }, Settings.normalizeState)
				self.value = ctx.store:get(self.id)
				self.cleanup:add(function()
					ctx.store:remove(self.id)
				end)
				self.cleanup:add(function()
					if self.menu then
						self.menu.close()
					end
					if self.savePopup then
						self.savePopup.close()
					end
				end)
				self:_flattenHost(parent)
				self.message = text(self.widget, {
					Typography = "Description",
					LayoutOrder = 3,
					TextWrapped = true,
					TextTruncate = Enum.TextTruncate.None,
					AutomaticSize = Enum.AutomaticSize.Y,
					Size = UDim2.fromScale(1, 0),
					Visible = false,
					Theme = { TextColor3 = "TextSecondary" },
				})
				self:_buildToolbar()
				self.panels = Factory.new("Frame", {
					Name = "Panels",
					Size = UDim2.new(1, 0, 0, MIN_PANE),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Parent = self.widget,
				})
				for _, name in { "EquippedUnits", "UnitSettings" } do
					self[if name == "EquippedUnits" then "left" else "right"] = Factory.new("Frame", {
						Name = name,
						Size = UDim2.fromOffset(200, MIN_PANE),
						BackgroundTransparency = 0.04,
						ClipsDescendants = true,
						Parent = self.panels,
						Theme = { BackgroundColor3 = "Surface" },
					}, { Factory.corner(10) })
				end
				self:_buildLibrary()
				self:_buildSettings()
				local node = self.Instance.Parent
				while node and not node:IsA("ScrollingFrame") do
					node = node.Parent
				end
				self.viewport = node
				if node then
					self.cleanup:connect(node:GetPropertyChangedSignal("AbsoluteWindowSize"), function()
						self:_fit()
					end)
				end
				self.cleanup:connect(self.panels:GetPropertyChangedSignal("AbsoluteSize"), function()
					self:_fit()
				end)
				self.cleanup:add(ctx.store:observe(self.id, function(value)
					self.value, self.presets = value, value.Presets
					self:_syncSettings()
					self:_renderPresets()
					self:_refreshSummaries()
				end))
				self:SetCatalog(options.UnitCatalog or {})
				self:_renderPresets()
				self:_fit()
				self.ready = true
				self:register("auto play unit settings placement upgrade caps waves")
				return self
			end

			function AutoPlay:_expansion(title, order)
				local group = Factory.new("Frame", {
					Name = title,
					LayoutOrder = order,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = self.form,
				}, { Factory.list(0) })
				local button = Factory.button({
					Name = title .. "Header", Size = UDim2.new(1, 0, 0, 38), LayoutOrder = 1,
					Parent = group, Theme = { BackgroundColor3 = "SurfaceHover" },
				}, { Factory.corner(Theme.get("RadiusControl")) })
				local label = text(button, {
					Text = title, Typography = "Feature", Position = UDim2.fromOffset(12, 0),
					Size = UDim2.new(1, -42, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
					Theme = { TextColor3 = "TextPrimary" },
				})
				local chevron = Icons.create({ Icon = "chevron-small-down", Color = "TextSecondary" }, 15, {
					AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Parent = button,
				})
				local clip = Factory.new("Frame", {
					Name = "Expand",
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 0),
					ClipsDescendants = true,
					BackgroundTransparency = 1,
					Parent = group,
				})
				local layout = Factory.list(10)
				local body = Factory.new("Frame", {
					Name = "Options",
					Position = UDim2.fromOffset(0, 8),
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = clip,
				}, { layout })
				local expanded = false
				local function paint()
					local color = if button.GuiState == Enum.GuiState.Press then "SurfaceActive"
						elseif button.GuiState == Enum.GuiState.Hover or expanded then "SurfaceHover" else "SurfaceActive"
					Theme.bind(button, { BackgroundColor3 = color })
					Animations.tween(button, { BackgroundTransparency = if expanded or button.GuiState ~= Enum.GuiState.Idle then 0 else 0.42 }, Theme.Motion.Hover)
				end
				self.cleanup:connect(button:GetPropertyChangedSignal("GuiState"), paint)
				paint()
				local function resize(animate)
					local height = if expanded
						then math.ceil(layout.AbsoluteContentSize.Y / self.ctx.scale()) + 8
						else 0
					Animations.tween(clip, { Size = UDim2.new(1, 0, 0, height) }, motion(animate, "Expand"))
				end
				self.cleanup:connect(
					button.Activated,
					self:_action(function()
						expanded = not expanded
						Animations.tween(chevron, { Rotation = if expanded then 180 else 0 }, Theme.Motion.Expand)
						paint()
						if not expanded then
							for _, field in self.fields do
								if field.Instance.Parent == body and field.Close then
									field:Close()
								end
							end
						end
						resize(true)
					end)
				)
				self.cleanup:connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					resize(false)
				end)
				return body
			end

			function AutoPlay:_buildSettings()
				self.detailIcon = thumbnail(self.right, 36, self.cleanup)
				self.detailIcon.Instance.Position = UDim2.fromOffset(PAD, PAD)
				self.detailName = text(self.right, {
					Text = "Unit settings",
					Typography = "Section",
					Position = UDim2.fromOffset(60, 12),
					Size = UDim2.new(1, -72, 0, 20),
				})
				self.detailMeta = text(self.right, {
					Typography = "Description",
					Position = UDim2.fromOffset(60, 33),
					Size = UDim2.new(1, -72, 0, 16),
					Theme = { TextColor3 = "TextMuted" },
				})
				self.details = Factory.new("ScrollingFrame", {
					Name = "Settings",
					Position = UDim2.fromOffset(PAD, 60),
					Size = UDim2.new(1, -PAD * 2, 1, -72),
					BackgroundTransparency = 1,
					ScrollBarThickness = 3,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					Parent = self.right,
					Theme = { ScrollBarImageColor3 = "Border" },
				})
				self.empty = text(self.details, {
					Text = "Equip units to start Auto Play.",
					Typography = "Description",
					Size = UDim2.new(1, 0, 0, 32),
					Theme = { TextColor3 = "TextMuted" },
				})
				self.form = Factory.new("Frame", {
					Name = "UnitSettingsForm",
					Size = UDim2.new(1, -8, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Visible = false,
					Parent = self.details,
				}, { Factory.list(10) })
				self.fields = {}
				local timing = self:_expansion("Timing options", 6)
				local placement = self:_expansion("Placement options", 7)
				for order, spec in
					{
						{ "PlaceCap", "Place cap" },
						{ "UpgradeCap", "Upgrade cap" },
						{ "PlaceWave", "Place at wave" },
						{ "UpgradeWave", "Upgrade at wave" },
						{ "PlaceDelay", "Placement delay (s)" },
						{ "UpgradeDelay", "Upgrade delay (s)" },
					}
				do
					local key = spec[1]
					self.fields[key] = self:_control(Input, if key:find("Delay") then timing else self.form, {
						Title = spec[2],
						Width = 96,
						Clearable = false,
						LayoutOrder = order,
						Default = "0",
						Validate = function(raw)
							local unit = self.catalog:Get(self.selectedUnit)
							local limit = if key == "PlaceCap"
								then unit and unit.MaxPlace or 100000
								elseif key == "UpgradeCap" then unit and unit.MaxUpgrade or 100000
								else 100000
							local n = tonumber(raw)
							return if n
									and n >= 0
									and n <= limit
									and (key:find("Delay") or n % 1 == 0)
								then true
								else `Enter a value from 0 to {limit}`
						end,
						Callback = function(raw)
							if not self.syncing and self.selectedUnit then
								self:_action(function()
									self:UpdateUnit(self.selectedUnit, { [key] = tonumber(raw) })
								end)()
							end
						end,
					})
				end
				self.focusFarm = self:_control(Toggle, self.form, {
					Title = "Focus on farm",
					Description = "Upgrade this farm first; save Yen for its next upgrade.",
					LayoutOrder = 5,
					Default = false,
					Callback = function(value)
						local unit = self.catalog:Get(self.selectedUnit)
						if not self.syncing and unit and unit.IsFarm then
							self:_action(function()
								self:UpdateUnit(self.selectedUnit, { FocusFarm = value })
							end)()
						end
					end,
				})
				for order, spec in
					{
						{ "PlacementMode", "Placement mode" },
						{ "PositionMode", "Position mode" },
						{ "PathTarget", "Path target" },
					}
				do
					local key = spec[1]
					self.fields[key] = self:_control(Dropdown, placement, {
						Title = spec[2],
						Width = 132,
						LayoutOrder = order,
						Options = Settings.PlacementOptions[key],
						Default = Settings.PlacementOptions[key][1],
						Callback = function(value)
							if not self.syncing and self.selectedUnit then
								self:_action(function()
									self:UpdateUnit(self.selectedUnit, { [key] = value })
								end)()
							end
						end,
					})
				end
				self.fields.PathPosition = self:_control(Input, placement, {
					Title = "Path position (%)",
					Width = 72,
					LayoutOrder = 4,
					Default = "0",
					Clearable = false,
					Validate = function(raw)
						local n = tonumber(raw)
						return if n and n >= 0 and n <= 100 and n % 1 == 0 then true else "Enter a value from 0 to 100"
					end,
					Callback = function(raw)
						if not self.syncing and self.selectedUnit then
							self:_action(function()
								self:UpdateUnit(self.selectedUnit, { PathPosition = tonumber(raw) })
							end)()
						end
					end,
				})
				local actions = Factory.new("Frame", {
					Name = "PositionActions",
					LayoutOrder = 5,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = placement,
				}, { Factory.list(6, true, { Wraps = true }) })
				for order, spec in { { "Choose position", false }, { "Reset position", true } } do
					local button = Button.make({ Text = spec[1], Variant = "Secondary", Height = 28 })
					button.LayoutOrder, button.Parent = order, actions
					self.cleanup:connect(
						button.Activated,
						self:_action(function()
							local unit = self.catalog:Get(self.selectedUnit)
							if unit and self.options.OnPosition then
								self.options.OnPosition(unit, spec[2])
							end
						end)
					)
				end
				local apply = Button.make({ Text = "Apply to all slots", Variant = "Secondary", Height = 28 })
				apply.LayoutOrder, apply.Parent = 3, actions
				self.cleanup:connect(apply.Activated, self:_action(function()
					self:_commitInputs()
					local source = self:_getUnit(self.selectedUnit)
					assert(source, "Choose a unit first.")
					local equipped, units = {}, self:GetUnitSettings()
					for _, item in ipairs(self.catalog.units) do equipped[item.UnitId] = true end
					for _, unit in ipairs(units) do
						if equipped[unit.UnitId] then
							for _, key in ipairs({ "PlacementMode", "PositionMode", "PathTarget", "PathPosition" }) do
								unit[key] = source[key]
							end
						end
					end
					self:SetUnits(units)
					self:_notice("Placement options applied to all equipped slots.")
				end))
			end

			function AutoPlay:_getUnit(id)
				for _, unit in self.value.Units do
					if unit.UnitId == id then
						return unit
					end
				end
			end
			function AutoPlay:_commitInputs()
				for _, field in self.fields do
					if field.field and field.field:IsA("TextBox") and field.field:IsFocused() then
						field.field:ReleaseFocus()
					end
					if field.Close then
						field:Close()
					end
				end
			end
			function AutoPlay:_selectUnit(id)
				local changed = self.selectedUnit ~= id
				self:_commitInputs()
				self.selectedUnit = id
				self:_syncSettings()
				self:_paintSelection(true)
				if changed then
					self.details.CanvasPosition = Vector2.zero
					for _, label in { self.detailName, self.detailMeta } do
						label.TextTransparency = if Animations.reducedMotion then 0 else 1
						Animations.tween(label, { TextTransparency = 0 }, Theme.Motion.Page)
					end
				end
			end
			function AutoPlay:_syncSettings()
				local unit, setting = self.catalog:Get(self.selectedUnit), self:_getUnit(self.selectedUnit)
				self.form.Visible, self.empty.Visible = unit ~= nil and setting ~= nil, unit == nil
				self.detailName.Text = if unit then unit.Name else "Unit settings"
				self.detailMeta.Text = if unit then describe(unit) else ""
				self.detailIcon:Set(self.catalog:Image(self.selectedUnit))
				if not unit or not setting then
					return
				end
				self.syncing = true
				self.focusFarm:SetVisible(unit.IsFarm == true)
				self.focusFarm:SetValue(setting.FocusFarm == true)
				for key, field in self.fields do
					local value = setting[key]
					if value == nil then
						value = (self.options.PlacementDefaults or {})[key]
					end
					if value == nil then
						value = if key == "PathPosition" then 0 else Settings.PlacementOptions[key][1]
					end
					local input = field.field and field.field:IsA("TextBox")
					if not input or not field.field:IsFocused() then
						field:SetValue(if input then tostring(value) else value)
					end
				end
				self.syncing = false
				local path = self.fields.PositionMode:GetValue() == "Path"
				self.fields.PathTarget:SetVisible(path)
				self.fields.PathPosition:SetVisible(path)
			end
			function AutoPlay:_refreshSummaries()
				for id, row in self.unitRows do
					local setting, unit = self:_getUnit(id), self.catalog:Get(id)
					if setting and unit then
						row.meta.Text =
							`Slot {unit.Slot or "?"} · Place {setting.PlaceCap} · Upgrade {setting.UpgradeCap}`
					end
				end
			end
			function AutoPlay:_paintSelection(animate)
				for id, row in self.unitRows do
					local active = id == self.selectedUnit
					Animations.tween(
						row.select,
						{ BackgroundTransparency = if row.hover and not active then 0.5 else 1 },
						motion(animate, "Hover")
					)
				end
				self:_placePill(animate)
			end
			function AutoPlay:_placePill(animate)
				local row = self.unitRows[self.selectedUnit]
				self.pill.Visible = row ~= nil and row.select.Visible
				if row then
					Animations.tween(self.pill, { Position = UDim2.fromOffset(0, row.y) }, motion(animate, "Select"))
				end
			end
			function AutoPlay:_fit(animate)
				if not self.panels then
					return
				end
				local scale = self.ctx.scale()
				local width = math.floor(self.panels.AbsoluteSize.X / scale)
				if width <= 0 then
					return
				end
				if self.team then
					local narrow = width < 600
					self.toolbar.Size = UDim2.new(1, 0, 0, if narrow then 64 else 30)
					self.presetButtons.AnchorPoint = Vector2.new(1, if narrow then 1 else 0.5)
					self.presetButtons.Position = UDim2.fromScale(1, if narrow then 1 else 0.5)
					if self.placeMode then
						self.placeMode.Instance.Size = UDim2.fromOffset(math.max(95, math.min(165, width - 136)), 28)
					end
				end
				local stacked = width < 540 or self.panels.AbsoluteSize.X < 420
				self.stacked = stacked
				local leftWidth = if stacked then width else math.floor((width - GAP) * 0.38)
				local height = math.max(
					MIN_PANE,
					if self.viewport then self.viewport.AbsoluteWindowSize.Y / scale - 150 else MIN_PANE
				)
				local leftHeight = if stacked
					then LIST_TOP + math.clamp(self.visibleUnits or 0, 1, 3) * (UNIT_ROW + 2) + PAD
					else height
				local duration = motion(animate ~= false and self.ready, "Expand")
				Animations.tween(self.left, { Size = UDim2.fromOffset(leftWidth, leftHeight) }, duration)
				Animations.tween(self.right, {
					Position = if stacked
						then UDim2.fromOffset(0, leftHeight + GAP)
						else UDim2.fromOffset(leftWidth + GAP, 0),
					Size = UDim2.fromOffset(if stacked then width else width - leftWidth - GAP, height),
				}, duration)
				self.panels.Size = UDim2.new(1, 0, 0, if stacked then leftHeight + GAP + height else height)
				Animations.tween(self.library, { Size = UDim2.new(1, -12, 0, leftHeight - LIST_TOP - PAD) }, duration)
			end
			function AutoPlay:_publish(units, reason, active)
				active = active or self.value.ActivePreset
				local presets = table.clone(self.presets)
				if active then
					presets[active] = Settings.normalize(units)
				end
				self.ctx.store:set(self.id, { Units = units, Presets = presets, ActivePreset = active })
				Util.safeCall(self.options.Callback, self:GetUnitSettings(), reason)
			end
			function AutoPlay:GetValue()
				return Settings.normalizeState(self.ctx.store:get(self.id))
			end
			function AutoPlay:GetUnitSettings()
				return Settings.normalize(self.value.Units)
			end
			function AutoPlay:SetValue(value)
				self.ctx.store:set(self.id, value)
				Util.safeCall(self.options.Callback, self:GetUnitSettings(), "Import")
			end
			function AutoPlay:SetUnits(units)
				self:_publish(Settings.normalize(units), "Update")
			end
			function AutoPlay:UpdateUnit(id, fields)
				local units, found = self:GetUnitSettings(), false
				for _, unit in units do
					if unit.UnitId == id then
						for key, value in fields do
							assert(key ~= "UnitId", "Unit ID cannot change")
							unit[key] = value
						end
						found = true
					end
				end
				assert(found, "Unit is not configured")
				self:SetUnits(units)
			end
			function AutoPlay:SavePreset(name)
				assert(type(name) == "string" and name:match("%S"), "Enter a config name")
				self:_commitInputs()
				self:_publish(self:GetUnitSettings(), "SavePreset", Util.trim(name))
			end
			function AutoPlay:LoadPreset(name)
				assert(self.presets[name], "Choose a saved config")
				self:_commitInputs()
				local units, seen = Settings.normalize(self.presets[name]), {}
				for _, unit in units do
					seen[unit.UnitId] = true
				end
				for id, unit in self.defaults do
					if not seen[id] then
						table.insert(units, table.clone(unit))
					end
				end
				self:_publish(units, "LoadPreset", name)
			end
			function AutoPlay:SetCatalog(records, defaults)
				self.catalog = Catalog.new(records)
				local units, seen, changed = self:GetUnitSettings(), {}, false
				for _, unit in units do
					seen[unit.UnitId] = true
				end
				local supplied = {}
				for _, unit in Settings.normalize(defaults or {}) do
					supplied[unit.UnitId] = unit
				end
				for _, record in self.catalog.units do
					local unit = supplied[record.UnitId]
						or {
							UnitId = record.UnitId,
							PlaceCap = math.min(4, record.MaxPlace or 4),
							UpgradeCap = record.MaxUpgrade or 0,
						}
					for key, choices in Settings.PlacementOptions do
						unit[key] = unit[key] or (self.options.PlacementDefaults or {})[key] or choices[1]
					end
					if unit.PathPosition == nil then
						unit.PathPosition = (self.options.PlacementDefaults or {}).PathPosition or 0
					end
					self.defaults[record.UnitId] = Settings.normalize({ unit })[1]
					if not seen[record.UnitId] then
						table.insert(units, unit)
						changed = true
					end
				end
				if changed then
					self:SetUnits(units)
				end
				self:_renderCatalog()
				if not self.catalog:Get(self.selectedUnit) then
					self.selectedUnit = if self.catalog.units[1] then self.catalog.units[1].UnitId else nil
				end
				self:_syncSettings()
				self:_refreshSummaries()
				self:_paintSelection(false)
			end

			function AutoPlay:_buildToolbar()
				local bar = Factory.new("Frame", {
					Name = "Presets",
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = self.widget,
				})
				local actions = Factory.new("Frame", {
					Name = "Actions",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(0, 28),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Parent = bar,
				}, { Factory.list(6, true) })
				self.toolbar = bar
				if self.options.OnTeam then
					self.team = self:_control(Dropdown, bar, {
						Options = {
							{ Value = "1", Label = "Team 1" },
							{ Value = "2", Label = "Team 2" },
							{ Value = "3", Label = "Team 3" },
							{ Value = "4", Label = "Team 4" },
							{ Value = "5", Label = "Team 5" },
							{ Value = "6", Label = "Team 6" },
						},
						Default = "",
						Width = 130,
						Callback = function(value)
							if self.renderingTeam or value == "" then
								return
							end
							local previous = self.selectedTeam or ""
							self.team:SetDisabled(true)
							local ok, err = pcall(function()
								self:_commitInputs()
								self.options.OnTeam(value)
							end)
							if not self.destroyed then
								if ok then
									self.selectedTeam = value
								else
									self.renderingTeam = true
									self.team:SetValue(previous)
									self.renderingTeam = false
									self:_notice(tostring(err), true)
								end
								self.team:SetDisabled(false)
							end
						end,
					})
					self.team.valueLabel.Text = "Team"
					self.team.Instance.AutomaticSize = Enum.AutomaticSize.None
					self.team.Instance.Size = UDim2.fromOffset(130, 28)
				end
				if self.options.OnPlaceMode then
					self.placeMode = self:_control(Dropdown, bar, {
						Options = {
							{ Value = "Slots by Slots", Label = "Slots by Slots" },
							{ Value = "Place When Affordable", Label = "Place When Affordable" },
						},
						Default = self.options.PlaceMode or "Place When Affordable",
						Width = 165,
						Callback = function(value)
							if value == "Slots by Slots" or value == "Place When Affordable" then
								self.options.OnPlaceMode(value)
							end
						end,
					})
					self.placeMode.Instance.Position = UDim2.fromOffset(136, 0)
					self.placeMode.Instance.AutomaticSize = Enum.AutomaticSize.None
					self.placeMode.Instance.Size = UDim2.fromOffset(165, 28)
				end
				self.presetButtons = actions
				self.preset = self:_control(Dropdown, actions, {
					Options = {},
					Default = "",
					Width = 150,
					LayoutOrder = 1,
					Callback = function(name)
						if self.renderingPresets then
							return
						end
						if name ~= "" and name ~= self.value.ActivePreset then
							self:_action(function()
								self:LoadPreset(name)
							end)()
						end
						self:_presetLabel()
					end,
				})
				self.preset.Instance.AutomaticSize, self.preset.Instance.Size =
					Enum.AutomaticSize.None, UDim2.fromOffset(150, 28)
				self.save = Button.make({ Text = "Save", LayoutOrder = 2 })
				self.save.Parent = actions
				self.cleanup:connect(
					self.save.Activated,
					self:_action(function()
						self:_save()
					end)
				)
				self.presetMenu = Display.iconButton("three-dots-horizontal", 28)
				self.presetMenu.Name, self.presetMenu.LayoutOrder, self.presetMenu.Parent = "PresetMenu", 3, actions
				self.cleanup:connect(self.presetMenu.Activated, function()
					self:_menu(self.presetMenu, {
						{
							Name = "Load",
							Text = "Load config",
							Callback = function()
								self:LoadPreset(self.preset:GetValue())
							end,
						},
						{
							Name = "SaveAs",
							Text = "Save as new config",
							Callback = function()
								self:_saveAs()
							end,
						},
						{
							Name = "Reset",
							Text = "Reset selected unit",
							Callback = function()
								local unit = self.defaults[self.selectedUnit]
								if unit then
									local fields = table.clone(unit)
									fields.UnitId = nil
									self:UpdateUnit(unit.UnitId, fields)
								end
							end,
						},
					})
				end)
			end

			function AutoPlay:_buildLibrary()
				local left = self.left
				text(left, {
					Text = "Units",
					Typography = "Section",
					Position = UDim2.fromOffset(PAD, PAD),
					Size = UDim2.new(1, -PAD * 2, 0, HEAD),
				})
				self.libraryCount = text(left, {
					Typography = "Description",
					TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -PAD, 0, PAD),
					Size = UDim2.fromOffset(90, HEAD),
					Theme = { TextColor3 = "TextMuted" },
				})
				local box = Factory.new("Frame", {
					Name = "Search",
					Position = UDim2.fromOffset(PAD, PAD + HEAD + 8),
					Size = UDim2.new(1, -PAD * 2, 0, 30),
					Parent = left,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, { Factory.corner(8) })
				Icons.create(
					{ Icon = "magnifying-glass", Color = "TextMuted" },
					14,
					{ AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Parent = box }
				)
				self.search = text(box, {
					ClassName = "TextBox",
					Name = "Query",
					Text = "",
					PlaceholderText = "Search units",
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.None,
					ClipsDescendants = true,
					Position = UDim2.fromOffset(32, 0),
					Size = UDim2.new(1, -40, 1, 0),
					Theme = { PlaceholderColor3 = "TextMuted" },
				})
				self.cleanup:connect(self.search:GetPropertyChangedSignal("Text"), function()
					self:_filterCatalog()
				end)
				self.cleanup:connect(
					self.search.FocusLost,
					self:_action(function(enter)
						local first = self.visibleList and self.visibleList[1]
						if enter and first then
							self:_selectUnit(first.UnitId)
						end
					end)
				)
				self.library = Factory.new("ScrollingFrame", {
					Name = "Units",
					Position = UDim2.fromOffset(6, LIST_TOP),
					Size = UDim2.new(1, -12, 0, UNIT_ROW),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 3,
					Parent = left,
					Theme = { ScrollBarImageColor3 = "Border" },
				})
				self.pill = Factory.new("Frame", {
					Name = "Selection",
					Size = UDim2.new(1, -6, 0, UNIT_ROW),
					Visible = false,
					Parent = self.library,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(8) })
				Factory.new("Frame", {
					Name = "Marker",
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(3, 16),
					Parent = self.pill,
					Theme = { BackgroundColor3 = "Accent" },
				}, { Factory.corner(2) })
				self.catalogEmpty = text(self.library, {
					Typography = "Description",
					TextXAlignment = Enum.TextXAlignment.Center,
					Position = UDim2.fromOffset(0, 12),
					Size = UDim2.new(1, 0, 0, 20),
					Theme = { TextColor3 = "TextMuted" },
				})
			end

			function AutoPlay:_menu(anchor, items)
				if self.menu then
					self.menu.close()
					return
				end
				local list = Factory.new("Frame", {
					Name = "AutoPlayMenu",
					Size = UDim2.fromOffset(184, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Active = true,
					Theme = { BackgroundColor3 = "Palette" },
				}, { Factory.corner(10), Factory.stroke("PaletteBorder"), Factory.padding(4), Factory.list(2) })
				for i, item in items do
					local row = Factory.button({
						Name = item.Name,
						Size = UDim2.new(1, 0, 0, 30),
						LayoutOrder = i,
						Parent = list,
						Theme = { BackgroundColor3 = "PaletteSelected" },
					}, { Factory.corner(6) })
					text(row, {
						Text = item.Text,
						Position = UDim2.fromOffset(10, 0),
						Size = UDim2.new(1, -20, 1, 0),
						Theme = { TextColor3 = if item.Danger then "Danger" else "TextPrimary" },
					})
					row.MouseEnter:Connect(function()
						row.BackgroundTransparency = 0
					end)
					row.MouseLeave:Connect(function()
						row.BackgroundTransparency = 1
					end)
					row.Activated:Connect(function()
						if self.menu then
							self.menu.close()
						end
						self:_action(item.Callback)()
					end)
				end
				self.menu = self.ctx.popups:open({
					content = list,
					anchor = anchor,
					align = "right",
					onClose = function()
						self.menu = nil
					end,
				})
			end

			function AutoPlay:_save()
				local name = self.preset:GetValue()
				if name == nil or name == "" then
					self:_saveAs()
					return
				end
				self:SavePreset(name)
				self:_notice(`Saved "{name}".`)
			end

			function AutoPlay:_saveAs()
				if self.savePopup then
					self.savePopup.close()
				end
				local box = Factory.new("Frame", {
					Name = "SavePreset",
					Size = UDim2.fromOffset(240, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Active = true,
					Theme = { BackgroundColor3 = "Palette" },
				}, { Factory.corner(10), Factory.stroke("PaletteBorder"), Factory.padding(10), Factory.list(8) })
				text(box, {
					Text = "Config name",
					Typography = "Hint",
					Size = UDim2.new(1, 0, 0, 16),
					LayoutOrder = 1,
					Theme = { TextColor3 = "TextMuted" },
				})
				local count = 0
				for _ in self.presets do
					count += 1
				end
				local input = text(box, {
					ClassName = "TextBox",
					Name = "Name",
					Text = if count == 0 then "Default" else `Config {count + 1}`,
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.None,
					Size = UDim2.new(1, 0, 0, 30),
					LayoutOrder = 2,
					BackgroundTransparency = 0,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				})
				Factory.corner(8).Parent = input
				Factory.padding(0, 10).Parent = input
				local actions = Factory.new(
					"Frame",
					{ Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 3, Parent = box },
					{ Factory.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right }) }
				)
				local save = Button.make({ Text = "Save config", Variant = "Primary" })
				save.Parent = actions
				local function submit()
					self:_action(function()
						local name = Util.trim(input.Text)
						self:SavePreset(name)
						if self.savePopup then
							self.savePopup.close()
						end
						self:_notice(`Saved "{name}".`)
					end)()
				end
				save.Activated:Connect(submit)
				input.FocusLost:Connect(function(enter)
					if enter then
						submit()
					end
				end)
				self.savePopup = self.ctx.popups:open({
					content = box,
					anchor = self.presetButtons,
					align = "right",
					onClose = function()
						self.savePopup = nil
					end,
				})
				task.defer(function()
					if input.Parent and input.CaptureFocus then
						input:CaptureFocus()
					end
				end)
			end

			function AutoPlay:_presetLabel()
				local value = self.preset:GetValue()
				if value == nil or value == "" then
					self.preset.valueLabel.Text = if next(self.presets) then "Choose config" else "No configs"
					Theme.bind(self.preset.valueLabel, { TextColor3 = "TextMuted" })
				end
			end

			function AutoPlay:_renderCatalog()
				self.catalogCleanup:clean()
				table.clear(self.unitRows)
				for _, unit in self.catalog.units do
					local cleanup = self.catalogCleanup:add(Cleanup.new())
					local select = cleanup:add(Factory.button({
						Name = unit.UnitId,
						Size = UDim2.new(1, -6, 0, UNIT_ROW),
						Parent = self.library,
						Theme = { BackgroundColor3 = "SurfaceHover" },
					}, { Factory.corner(8) }))
					local icon = thumbnail(select, LINE, cleanup)
					icon.Instance.Position = UDim2.fromOffset(10, (UNIT_ROW - LINE) // 2)
					icon:Set(self.catalog:Image(unit.UnitId))
					local meta = describe(unit)
					text(select, {
						Text = unit.Name,
						Typography = "Section",
						Position = UDim2.fromOffset(48, if meta ~= "" then 4 else 11),
						Size = UDim2.new(1, -56, 0, 17),
					})
					text(select, {
						Name = "UnitSummary",
						Text = meta,
						Typography = "Description",
						Position = UDim2.fromOffset(48, 21),
						Size = UDim2.new(1, -56, 0, 14),
						Theme = { TextColor3 = "TextMuted" },
					})
					local tile = { select = select, icon = icon, y = 0, meta = select:FindFirstChild("UnitSummary") }
					cleanup:connect(
						select.Activated,
						self:_action(function()
							self:_selectUnit(unit.UnitId)
						end)
					)
					cleanup:connect(select.MouseEnter, function()
						tile.hover = true
						self:_paintSelection(true)
					end)
					cleanup:connect(select.MouseLeave, function()
						tile.hover = false
						self:_paintSelection(true)
					end)
					self.unitRows[unit.UnitId] = tile
				end
				self:_filterCatalog()
			end

			function AutoPlay:_filterCatalog()
				if not self.search then
					return
				end
				local matches = self.catalog:Search(self.search.Text)
				self.visibleList = matches
				for _, tile in self.unitRows do
					tile.select.Visible = false
				end
				for index, unit in matches do
					local tile = self.unitRows[unit.UnitId]
					tile.y = (index - 1) * (UNIT_ROW + 2)
					tile.select.Visible = true
					Animations.tween(
						tile.select,
						{ Position = UDim2.fromOffset(0, tile.y) },
						motion(self.ready, "Select")
					)
				end
				self.visibleUnits = #matches
				self.library.CanvasSize = UDim2.fromOffset(0, math.max(0, #matches * (UNIT_ROW + 2) - 2))
				local total = #self.catalog.units
				self.libraryCount.Text = if total == 1 then "1 unit" else `{total} units`
				self.catalogEmpty.Visible = #matches == 0
				self.catalogEmpty.Text = if total == 0 then "No units available." else "No matching units."
				self:_paintSelection(self.ready)
				self:_fit()
			end

			function AutoPlay:_renderPresets()
				local names = {}
				for name in self.presets do
					table.insert(names, name)
				end
				table.sort(names)
				self.renderingPresets = true
				self.preset:SetOptions(names, true)
				self.preset:SetValue(self.value.ActivePreset or "")
				self.renderingPresets = false
				self:_presetLabel()
			end

			-- Side by side (38/62), stacked on narrow screens. Real sizes only, no nested UIScale.

			return AutoPlay
		end

		-- Components/Button
		loaders[nodes["Components/Button"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Icons = require(Core.Icons)
			local Util = require(Core.Util)
			local Control = require(script.Parent.Control)

			local VARIANTS = {
				Primary = { rest = "Accent", hover = "Accent", text = "OnAccent", hoverAlpha = 0.12 },
				Secondary = { rest = "SurfaceActive", hover = "SurfaceHover", text = "TextPrimary" },
				Ghost = { rest = "SurfaceHover", hover = "SurfaceHover", text = "TextPrimary", restAlpha = 1 },
				Destructive = { rest = "SurfaceActive", hover = "SurfaceHover", text = "Danger" },
			}

			local Button = Control.extend("Button")

			-- Plain styled button, usable anywhere (dialogs, headers, inputs).
			function Button.make(options: { [string]: any }): TextButton
				local variant = VARIANTS[options.Variant or "Secondary"] or VARIANTS.Secondary
				local restAlpha = variant.restAlpha or 0
				local height = options.Height or 28

				local button = Factory.button({
					Name = options.Text or "Button",
					Size = UDim2.fromOffset(options.Width or 0, height),
					AutomaticSize = if options.Width then Enum.AutomaticSize.None else Enum.AutomaticSize.X,
					BackgroundTransparency = restAlpha,
					LayoutOrder = options.LayoutOrder or 0,
					Theme = { BackgroundColor3 = variant.rest },
				}, {
					Factory.corner(Theme.get("RadiusControl") - 1),
					Factory.padding(0, if options.Text then 12 else 6),
					Factory.list(6, true, { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
				})

				if options.Icon then
					Icons.create(
						{ Icon = options.Icon, Color = variant.text },
						16,
						{ LayoutOrder = 1, Parent = button }
					)
				end
				local label
				if options.Text then
					label = Factory.text({
						Name = "Label",
						Text = options.Text,
						AutomaticSize = Enum.AutomaticSize.X,
						Size = UDim2.fromOffset(0, height),
						TextTruncate = if options.Width then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None,
						LayoutOrder = 2,
						Parent = button,
						Theme = { TextColor3 = variant.text },
					}, { Factory.new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink }) })
				end

				local hovered = false
				local function paint()
					local alpha = restAlpha
					if hovered then
						alpha = if variant.hoverAlpha then variant.hoverAlpha else 0
					end
					Theme.bind(button, { BackgroundColor3 = if hovered then variant.hover else variant.rest })
					Animations.tween(button, { BackgroundTransparency = alpha }, Theme.Motion.Hover)
				end
				button.MouseEnter:Connect(function()
					hovered = true
					paint()
				end)
				button.MouseLeave:Connect(function()
					hovered = false
					paint()
				end)

				local scale = Factory.new("UIScale", { Parent = button })
				button.MouseButton1Down:Connect(function()
					Animations.tween(scale, { Scale = 0.97 }, 0.08)
				end)
				button.MouseButton1Up:Connect(function()
					Animations.tween(scale, { Scale = 1 }, 0.12)
				end)
				button.MouseLeave:Connect(function()
					Animations.tween(scale, { Scale = 1 }, 0.12)
				end)

				if options.Callback then
					button.Activated:Connect(function()
						Util.safeCall(options.Callback)
					end)
				end
				return button, label
			end

			function Button.new(ctx, parent, options)
				local self = setmetatable(
					Control.new(ctx, parent, {
						Id = options.Id,
						Title = options.Label,
						Description = options.Description,
						LayoutOrder = options.LayoutOrder,
					}),
					Button
				)
				self.options = options
				self.Instance:SetAttribute("NoWindowDrag", true)

				local button, label = Button.make({
					Text = options.Title or "Button",
					Icon = options.Icon,
					Variant = options.Variant,
				})
				button.Parent = self.widget
				self.button, self.label = button, label

				if options.Label == nil then
					self.widget.Size = UDim2.fromScale(1, 0)
					self.widget:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = if options.Align
							== "Right"
						then Enum.HorizontalAlignment.Right
						else Enum.HorizontalAlignment.Left
				end

				self.cleanup:connect(button.Activated, function()
					if not self.disabled then
						Util.safeCall(options.Callback)
					end
				end)

				self:register("button")
				return self
			end

			function Button:searchTitle(): string
				local options, ctx = self.options, self.ctx
				local title = options.Label or options.Title or "Action"
				return options.SearchTitle or (if ctx.cardTitle then `{ctx.cardTitle}: {title}` else title)
			end

			function Button:register()
				local options = self.options
				if options.Searchable == false then
					return
				end
				local title = options.Label or options.Title
				if
					(title == nil or string.lower(title) == "open" or string.lower(title) == "button")
					and not options.SearchTitle
					and options.Searchable ~= true
				then
					return
				end
				local ctx = self.ctx
				self.registryKey = options._SearchId
					or `{ctx.searchId}/control:{options.Id or options.LayoutOrder or title}`
				self.cleanup:add(ctx.registry:add({
					id = self.registryKey,
					kind = "control",
					title = self:searchTitle(),
					subtitle = ctx.searchPath,
					keywords = `button {options.Keywords or ""}`,
					aliases = options.Aliases,
					icon = options.Icon or "cursor",
					activate = function()
						if ctx.locate then
							ctx.locate(self.Instance)
						end
					end,
					visible = function()
						return self.visible
					end,
				}))
			end

			function Button:SetText(text: string)
				self.options.Label = text
				if self.registryKey then
					self.ctx.registry:update(self.registryKey, { title = self:searchTitle() })
				end
				if self.label then
					self.label.Text = text
				end
			end

			function Button:GetValue()
				return nil
			end

			function Button:SetValue() end

			return Button
		end

		-- Components/Card
		loaders[nodes["Components/Card"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Overlays = script.Parent.Parent.Overlays
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Cleanup = require(Core.Cleanup)
			local Icons = require(Core.Icons)
			local Util = require(Core.Util)
			local PopupManager = require(Overlays.PopupManager)
			local Components = script.Parent
			local Toggle = require(Components.Toggle)
			local Display = require(Components.Display)
			local AnimatedImage = require(Components.AnimatedImage)

			local CONTROLS = {
				Toggle = require(Components.Toggle),
				Slider = require(Components.Slider),
				Dropdown = require(Components.Dropdown),
				PrioritySelector = require(Components.PrioritySelector),
				UpdateLog = require(Components.UpdateLog),
				AutoPlay = require(Components.AutoPlayFeature),
				Crafting = require(Components.Crafting),
				Traits = require(Components.Traits),
				Button = require(Components.Button),
				Input = require(Components.Input),
				Keybind = require(Components.Keybind),
				ColorPicker = require(Components.ColorPicker),
				Label = Display.Label,
				Paragraph = Display.Paragraph,
				Divider = Display.Divider,
				Status = Display.Status,
				Progress = Display.Progress,
				Image = Display.Image,
			}

			local PAD_X = 14
			local ICON = 20

			local Card = {}
			Card.__index = Card

			export type Options = {
				Id: string?,
				Title: string,
				Description: string?,
				Icon: any?,
				AnimatedIcon: { [string]: any }?,
				Badge: string?,
				Collapsible: boolean?,
				DefaultExpanded: boolean?,
				Toggle: boolean?,
				Default: boolean?,
				Callback: ((boolean) -> ())?,
				Keywords: string?,
				Aliases: (string | { string })?,
				Searchable: boolean?,
				NavigateTo: string?,
				Popover: PopupManager.Policy?,
				Layout: "CompactGrid"?,
				Columns: ("Auto" | number)?,
				UniqueChoices: boolean?,
				Responsive: boolean?,
			}

			function Card.new(section, options: Options)
				assert(
					options.NavigateTo == nil or type(options.NavigateTo) == "string",
					"NavigateTo must be a page ID"
				)
				assert(options.Popover == nil or type(options.Popover) == "table", "Popover must be a table")
				assert(options.Layout == nil or options.Layout == "CompactGrid", "Card.Layout must be CompactGrid")
				assert(
					options.Columns == nil
						or options.Columns == "Auto"
						or options.Columns == 1
						or options.Columns == 2
						or options.Columns == 3,
					"Columns must be Auto, 1, 2 or 3"
				)
				assert(
					options.UniqueChoices == nil or type(options.UniqueChoices) == "boolean",
					"UniqueChoices must be a boolean"
				)
				assert(
					options.Responsive == nil or type(options.Responsive) == "boolean",
					"Responsive must be a boolean"
				)
				local ctx = section.ctx
				if options.Id then
					for _, existing in section.cards or {} do
						assert(
							existing.options.Id ~= options.Id,
							`Card id "{options.Id}" already exists in this section`
						)
					end
				end
				local grid = section.grid
				local self = setmetatable({
					section = section,
					options = options,
					cleanup = Cleanup.new(),
					controls = {},
					count = 0,
					visible = true,
					disabled = false,
					grid = grid,
					compactDropdowns = options.Layout == "CompactGrid",
					collapsible = options.Collapsible == true or grid,
				}, Card)
				self.expanded = self.collapsible and not grid and options.DefaultExpanded == true
					or not self.collapsible

				-- Search hits on a control expand its card before scrolling to it.
				self.ctx = setmetatable({
					searchId = `{ctx.searchId}/card:{options.Id or section.order + 1}`,
					searchPath = `{ctx.searchPath} › {options.Title}`,
					cardTitle = options.Title,
					locate = function(target: GuiObject, after: (() -> ())?)
						if grid then
							ctx.locate(self.Instance, function()
								self:SetExpanded(true)
								if after then
									after()
								end
							end)
							return
						end
						if self.collapsible and not self.expanded then
							self:SetExpanded(true, true)
						end
						ctx.locate(target, after)
					end,
				}, { __index = ctx })

				section.order += 1
				self.Instance = self.cleanup:add(Factory.new("Frame", {
					Name = options.Id or options.Title,
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = if grid then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
					BackgroundTransparency = if grid then 0.04 else 1,
					LayoutOrder = section.order,
					ClipsDescendants = grid,
					Parent = section.container,
					Theme = { BackgroundColor3 = "Surface" },
				}, {
					Factory.list(0, false, { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
					if grid then Factory.corner(Theme.get("RadiusCard") - 2) else nil,
					if grid then Factory.stroke("Border", 0.5) else nil,
				}))
				self.Instance:SetAttribute(
					"NoWindowDrag",
					self.collapsible or options.NavigateTo ~= nil or options.Toggle == true
				)

				self:_buildHeader()
				self:_buildBody()

				if options.Toggle then
					self:_buildSwitch()
				end

				self.registryKey = self.ctx.searchId
				if options.Searchable ~= false then
					self.cleanup:add(ctx.registry:add({
						id = self.registryKey,
						kind = "card",
						title = options.Title,
						subtitle = ctx.searchPath,
						keywords = `{options.Description or ""} {options.Keywords or ""}`,
						aliases = options.Aliases,
						icon = options.Icon or "three-sliders-horizontal",
						state = function()
							return if self.enabledId
								then (if ctx.store:get(self.enabledId) then "On" else "Off")
								else nil
						end,
						activate = function()
							self:Focus()
						end,
						visible = function()
							return self.visible
						end,
					}))
				end

				section:_refresh()
				return self
			end

			function Card.newDropdownGroup(section, options)
				options = table.clone(options or {})
				assert(
					options.DefaultEnabled == nil or type(options.DefaultEnabled) == "boolean",
					"DefaultEnabled must be a boolean"
				)
				options.Layout = options.Layout or "CompactGrid"
				options.Toggle, options.Collapsible = true, true
				if options.DefaultEnabled ~= nil then
					options.Default = options.DefaultEnabled
				end
				local group = Card.new(section, options)
				group.ClassName = "ToggleDropdownGroup"
				return group
			end

			function Card:_buildHeader()
				local options = self.options
				local grid = self.grid

				local header = Factory.button({
					Name = "Header",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Active = self.collapsible or options.NavigateTo ~= nil,
					Parent = self.Instance,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, {
					Factory.padding(if options.Description then 9 else 12, PAD_X),
					Factory.new("UISizeConstraint", { MinSize = Vector2.new(0, 44) }),
					Factory.list(10, not grid, {
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalFlex = if grid then nil else Enum.UIFlexAlignment.None,
					}),
				})
				self.header = header
				header:SetAttribute("NoWindowDrag", self.collapsible or options.NavigateTo ~= nil)

				if options.AnimatedIcon then
					local anim = AnimatedImage.new(
						Util.merge(options.AnimatedIcon, { Size = UDim2.fromOffset(ICON + 4, ICON + 4) })
					)
					anim.Instance.LayoutOrder = 1
					anim.Instance.Parent = header
					self.animation = anim
					self.cleanup:add(anim)
				elseif options.Icon then
					self.icon = Icons.create(options.Icon, ICON - 4, { LayoutOrder = 1, Parent = header })
				end

				local text = Factory.new("Frame", {
					Name = "Text",
					Size = UDim2.fromScale(if grid then 1 else 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Parent = header,
				}, {
					Factory.list(2),
					if grid then nil else Factory.fill(),
				})

				local titleRow = Factory.new("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = text,
				}, { Factory.list(8, true) })

				self.titleLabel = Factory.text({
					Text = options.Title,
					Typography = "Feature",
					Size = UDim2.fromOffset(0, 20),
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = 1,
					Parent = titleRow,
				}, { Factory.new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink }) })

				self.spinner = Icons.create({ Icon = "arrow-spin-clockwise", Color = "TextMuted" }, 14, {
					LayoutOrder = 3,
					Visible = false,
					Parent = titleRow,
				})

				self.descriptionLabel = Factory.text({
					Text = options.Description or "",
					Typography = "Description",
					TextWrapped = true,
					TextTruncate = if grid then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None,
					Size = UDim2.new(1, 0, 0, if grid then 26 else 0),
					AutomaticSize = if grid then Enum.AutomaticSize.None else Enum.AutomaticSize.Y,
					TextYAlignment = Enum.TextYAlignment.Top,
					Visible = options.Description ~= nil,
					LayoutOrder = 2,
					Parent = text,
					Theme = { TextColor3 = "TextSecondary" },
				})

				self.actions = Factory.new("Frame", {
					Name = "Actions",
					Size = UDim2.fromScale(0, 0),
					AutomaticSize = Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Parent = header,
				}, { Factory.list(6, true) })

				if grid then
					self.actions.AnchorPoint = Vector2.new(1, 0)
					self.actions.Position = UDim2.new(1, 0, 0, 0)
					local layout = header:FindFirstChildOfClass("UIListLayout")
					layout.Padding = UDim.new(0, 6)
					local top = Factory.new("Frame", {
						Size = UDim2.new(1, 0, 0, ICON + 4),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						Parent = header,
					})
					local icon = self.icon or (self.animation and self.animation.Instance)
					if icon then
						icon.Parent = top
						icon.AnchorPoint = Vector2.new(0, 0.5)
						icon.Position = UDim2.fromScale(0, 0.5)
					end
					self.actions.Parent = top
					self.actions.AnchorPoint = Vector2.new(1, 0.5)
					self.actions.Position = UDim2.fromScale(1, 0.5)
				end

				if options.Badge then
					self:SetBadge(options.Badge)
				end

				if self.collapsible or options.NavigateTo then
					local chevron = Icons.create(
						if options.NavigateTo
							then { Icon = "chevron-small-right", Color = Color3.fromRGB(165, 165, 170) }
							else if grid then "chevron-small-right" else "chevron-small-down",
						if options.NavigateTo then 16 else 18,
						{
							Name = "Chevron",
							LayoutOrder = 10,
							Rotation = if options.NavigateTo or self.expanded or grid then 0 else -90,
							Parent = self.actions,
						}
					)
					self.chevron = chevron

					self.cleanup:connect(header.MouseEnter, function()
						Animations.tween(
							header,
							{ BackgroundTransparency = if grid then 1 else 0.6 },
							Theme.Motion.Hover
						)
						if grid then
							Theme.bind(self.Instance, { BackgroundColor3 = "SurfaceHover" })
						end
					end)
					self.cleanup:connect(header.MouseLeave, function()
						Animations.tween(header, { BackgroundTransparency = 1 }, Theme.Motion.Hover)
						if grid then
							Theme.bind(self.Instance, { BackgroundColor3 = "Surface" })
						end
					end)
					self.cleanup:connect(header.Activated, function()
						if not self.disabled then
							if options.NavigateTo then
								self.section.page.window:SelectPage(options.NavigateTo)
							else
								self:SetExpanded(not self:IsExpanded())
							end
						end
					end)
				end
			end

			function Card:_buildBody()
				local holder = Factory.new("Frame", {
					Name = "Body",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					LayoutOrder = 2,
					Visible = false,
					Parent = self.Instance,
				})
				self.cleanup:add(holder)

				local inner = Factory.new("Frame", {
					Name = "Content",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = holder,
				}, {
					Factory.list(10),
					Factory.padding(2, PAD_X, 12, if self.icon or self.animation then PAD_X + ICON + 8 else PAD_X),
				})

				self.body, self.content = holder, inner
				if self.compactDropdowns then
					inner:FindFirstChildOfClass("UIListLayout"):Destroy()
					inner:FindFirstChildOfClass("UIPadding"):Destroy()
					inner.Name = "DropdownGridContainer"
					inner.AutomaticSize = Enum.AutomaticSize.None
					Factory.padding(12, PAD_X).Parent = inner
					self.dropdownLayout = Factory.new("UIGridLayout", {
						CellPadding = UDim2.fromOffset(10, 12),
						CellSize = UDim2.fromOffset(180, 54),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = inner,
					})
					self.cleanup:connect(inner:GetPropertyChangedSignal("AbsoluteSize"), function()
						self:_fitDropdownGrid()
					end)
					self.cleanup:connect(self.dropdownLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
						-- Both absolute measurements include ancestor UIScale; convert back to layout pixels once.
						local scale = self.dropdownLayout.AbsoluteCellSize.Y / 54
						if scale <= 0 then
							return
						end
						local height = self.dropdownLayout.AbsoluteContentSize.Y / scale
						inner.Size = UDim2.new(1, 0, 0, if height > 0 then math.round(height) + 24 else 0)
					end)
					self:_fitDropdownGrid()
				end
			end

			function Card:_fitDropdownGrid()
				local width = math.floor(self.content.AbsoluteSize.X / self.ctx.scale() + 0.001) - PAD_X * 2
				if width <= 0 then
					return
				end
				local columns = if width >= 590 then 3 elseif width >= 370 then 2 else 1
				-- Two pixels of hysteresis keep a boundary from oscillating during resize/scale rounding.
				if self.dropdownColumns == 3 and width >= 588 then
					columns = 3
				elseif self.dropdownColumns == 2 and width >= 368 and width < 590 then
					columns = 2
				end
				if type(self.options.Columns) == "number" then
					columns = math.min(columns, self.options.Columns)
				end
				if self.options.Responsive == false and type(self.options.Columns) == "number" then
					columns = math.min(self.options.Columns, math.max(1, math.floor((width + 10) / 180)))
				end
				self.dropdownColumns = columns
				local cell = math.max(1, math.floor((width - 10 * (columns - 1)) / columns))
				if self.dropdownCell ~= cell then
					self.dropdownCell = cell
					self.dropdownLayout.CellSize = UDim2.fromOffset(cell, 54)
				end
				self.dropdownLayout.FillDirectionMaxCells = columns
			end

			function Card:_buildSwitch()
				local options, store = self.options, self.ctx.store
				local track, render = Toggle.switch()
				track.LayoutOrder = 5
				track.Parent = self.actions

				local id, value =
					store:define(if options.Id then `{options.Id}.enabled` else nil, options.Default == true)
				self.enabledId = id
				render(value)
				self.cleanup:add(store:observe(id, function(on)
					render(on)
					Util.safeCall(options.Callback, on)
				end))
				self.cleanup:add(function()
					store:remove(id)
				end)
				self.cleanup:connect(track.Activated, function()
					if not self.disabled then
						store:set(id, not store:get(id))
					end
				end)
			end

			function Card:_naturalHeight(): number
				return self.content.AbsoluteSize.Y / self.ctx.scale()
			end

			function Card:_hasBody(): boolean
				return self.count > 0
			end

			-- Open bodies auto-size to their content; only the transition uses a measured, fixed height.
			function Card:_layoutBody(animate: boolean)
				local holder = self.body
				if self.grid then
					return
				end
				local open = self.expanded and self:_hasBody()
				local token = {}
				self.animToken = token

				local function settle()
					if self.animToken ~= token then
						return
					end
					holder.AutomaticSize = if open then Enum.AutomaticSize.Y else Enum.AutomaticSize.None
					holder.Size = UDim2.new(1, 0, 0, 0)
					holder.Visible = open
				end

				if not animate or Animations.reducedMotion then
					settle()
					return
				end

				local from = holder.AbsoluteSize.Y / self.ctx.scale()
				holder.Visible = true
				holder.AutomaticSize = Enum.AutomaticSize.None
				holder.Size = UDim2.new(1, 0, 0, from)
				local target = if open then self:_naturalHeight() else 0
				local tween = Animations.tween(
					holder,
					{ Size = UDim2.new(1, 0, 0, target) },
					Theme.Motion.Expand,
					Enum.EasingStyle.Quint
				)
				if tween then
					tween.Completed:Once(settle)
				else
					settle()
				end
			end

			function Card:SetExpanded(expanded: boolean, instant: boolean?)
				if not self.collapsible then
					return
				end
				if self.grid then
					if expanded then
						self:_openInspector()
					elseif self.inspector then
						self.inspector.close()
					end
					return
				end
				self.expanded = expanded
				if self.chevron then
					Animations.tween(
						self.chevron,
						{ Rotation = if expanded then 0 else -90 },
						if instant then 0 else Theme.Motion.Expand
					)
				end
				self:_layoutBody(not instant)
			end

			function Card:IsExpanded(): boolean
				return if self.grid then self.inspector ~= nil else self.expanded
			end

			function Card:_openInspector()
				if self.inspector then
					return
				end
				local surface = PopupManager.surface(340, { Name = "CardInspector" })
				Factory.list(0).Parent = surface

				local head = Factory.new("Frame", {
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = surface,
				}, { Factory.padding(14, PAD_X, 10, PAD_X), Factory.list(3) })
				Factory.text({
					Text = self.options.Title,
					Typography = "Feature",
					Size = UDim2.new(1, 0, 0, 20),
					Parent = head,
				})
				if self.options.Description then
					Factory.text({
						Text = self.options.Description,
						Typography = "Description",
						TextWrapped = true,
						TextTruncate = Enum.TextTruncate.None,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 2,
						Parent = head,
						Theme = { TextColor3 = "TextSecondary" },
					})
				end

				local content = self.content
				content.Parent = surface
				content.LayoutOrder = 2
				local padding = content:FindFirstChildOfClass("UIPadding")
				local oldLeft = padding.PaddingLeft
				padding.PaddingLeft = UDim.new(0, PAD_X)

				if self.count == 0 then
					Factory.text({
						Name = "Empty",
						Text = "No settings for this feature yet.",
						Size = UDim2.new(1, 0, 0, 20),
						LayoutOrder = -1,
						Parent = content,
						Theme = { TextColor3 = "TextMuted" },
					})
				end

				self.inspector = self.ctx.popups:open({
					content = surface,
					anchor = self.Instance,
					gap = 8,
					group = "feature",
					policy = self.options.Popover,
					onClose = function()
						for _, control in self.controls do
							if control.stopDrag then
								control.stopDrag()
							end
						end
						local empty = content:FindFirstChild("Empty")
						if empty then
							empty:Destroy()
						end
						padding.PaddingLeft = oldLeft
						content.Parent = self.body
						self.inspector = nil
					end,
				})
			end

			function Card:_add(kind: string, options: { [string]: any })
				if self.ctx.buildYield then self.ctx.buildYield("control " .. kind) end
				local class = CONTROLS[kind]
				options = table.clone(options or {})
				local usedChoices
				if options.Id then
					for _, existing in self.controls do
						assert(
							existing.options.Id ~= options.Id,
							`Element id "{options.Id}" already exists in this card`
						)
					end
				end
				if self.compactDropdowns then
					assert(kind == "Dropdown", "CompactGrid groups accept dropdowns only")
					options._CompactGrid = true
				end
				if self.options.UniqueChoices and kind == "Dropdown" then
					assert(options.Multi ~= true, "UniqueChoices requires single-select dropdowns")
					local used = {}
					usedChoices = used
					for _, field in self.controls do
						used[field:GetValue()] = true
					end
					if options.Default == nil or used[options.Default] then
						options.Default = nil
						for _, item in options.Options or {} do
							local value = if type(item) == "table" then item.Value else item
							if value ~= nil and not used[value] then
								options.Default = value
								break
							end
						end
						assert(options.Default ~= nil, "UniqueChoices requires an unused option for each slot")
					end
				end
				self.controlOrder = (self.controlOrder or 0) + 1
				options._SearchId = `{self.ctx.searchId}/control:{options.Id or self.controlOrder}`
				options.LayoutOrder = options.LayoutOrder or self.count + 1
				local control
				if kind == "ToggleDropdownGroup" then
					local host = setmetatable({
						ctx = self.ctx,
						container = self.content,
						grid = false,
						order = 0,
						cards = {},
						_refresh = function() end,
						_forget = function() end,
					}, { __index = self.section })
					control = Card.newDropdownGroup(host, options)
					control.Instance.LayoutOrder = options.LayoutOrder
				else
					control = class.new(self.ctx, self.content, options)
				end
				if kind == "Button" and options.Label == nil and options.Description == nil then
					local previous = self.controls[#self.controls]
					if
						previous
						and previous.kind == "Button"
						and previous.options.Label == nil
						and previous.options.Description == nil
					then
						local row = previous.actionRow
							or Factory.new("Frame", {
								Name = "ButtonActions",
								Size = UDim2.fromScale(1, 0),
								AutomaticSize = Enum.AutomaticSize.Y,
								BackgroundTransparency = 1,
								LayoutOrder = previous.Instance.LayoutOrder,
								Parent = self.content,
							}, { Factory.list(8, true, { Wraps = true }) })
						for _, field in ipairs({ previous, control }) do
							field.actionRow = row
							field.Instance.AutomaticSize = Enum.AutomaticSize.XY
							field.Instance.Size = UDim2.fromOffset(0, 0)
							field.widget.Size = UDim2.fromOffset(0, 0)
							field.Instance.Parent = row
						end
					end
				end
				self.count += 1
				if self.options.UniqueChoices and kind == "Dropdown" then
					if usedChoices[control:GetValue()] then
						control:SetValue(options.Default)
					end
					local setValue = control.SetValue
					control.SetValue = function(field, value)
						local previous = field:GetValue()
						if previous == value then
							return
						end
						local valid = false
						for _, item in field.items do
							if (if type(item) == "table" then item.Value else item) == value then
								valid = true
								break
							end
						end
						assert(valid, "UniqueChoices value must be in Options")
						for _, other in self.controls do
							if other ~= field and other:GetValue() == value then
								local canSwap = false
								for _, item in other.items do
									if (if type(item) == "table" then item.Value else item) == previous then
										canSwap = true
										break
									end
								end
								assert(canSwap, "UniqueChoices slots must support the swapped value")
								setValue(other, previous)
								break
							end
						end
						setValue(field, value)
					end
				end
				control.kind = kind
				control.onDestroy = function(c)
					local index = table.find(self.controls, c)
					if index then
						table.remove(self.controls, index)
						self.count -= 1
						if c.actionRow and #c.actionRow:GetChildren() == 1 then
							c.actionRow:Destroy()
						end
						self:_layoutBody(false)
					end
				end
				table.insert(self.controls, control)
				if self.disabled then
					control:SetDisabled(true)
				end
				self:_layoutBody(false)
				return control
			end

			function Card:AddToggleDropdownGroup(options)
				return self:_add("ToggleDropdownGroup", options)
			end

			for kind in CONTROLS do
				Card["Add" .. kind] = function(self, options)
					return self:_add(kind, options)
				end
			end

			function Card:AddAnimatedImage(options)
				return self:_add("Image", options)
			end

			function Card:AddAction(options: { Icon: string?, Text: string?, Tooltip: string?, Callback: (() -> ())? })
				local button
				if options.Text then
					button = require(Components.Button).make({
						Text = options.Text,
						Icon = options.Icon,
						Variant = options.Variant,
						Callback = options.Callback,
					})
				else
					button = Display.iconButton(options.Icon or "three-dots-horizontal", 26, options.Callback)
				end
				button.LayoutOrder = 4
				button.Parent = self.actions
				if options.Tooltip then
					self.cleanup:add(Display.tooltip(self.ctx.popups, button, options.Tooltip))
				end
				self.cleanup:add(button)
				return button
			end

			function Card:SetBadge(text: string?, kind: string?)
				if self.badge then
					self.badge:Destroy()
					self.badge = nil
				end
				if text then
					self.badge = Display.badge(text, kind)
					self.badge.LayoutOrder = 2
					self.badge.Parent = self.titleLabel.Parent
				end
			end

			function Card:SetLoading(loading: boolean)
				self.spinner.Visible = loading
				if self.stopSpin then
					self.stopSpin()
					self.stopSpin = nil
				end
				if loading and self.section.page.window.visible then
					self.stopSpin = Animations.spin(self.spinner)
				end
			end

			function Card:SetTitle(title: string)
				self.options.Title = title
				self.titleLabel.Text = title
				self.ctx.searchPath = `{self.section.ctx.searchPath} › {title}`
				self.ctx.cardTitle = title
				self.ctx.registry:update(self.registryKey, { title = title })
				for _, control in self.controls do
					if control.ClassName == "ToggleDropdownGroup" then
						control:SetTitle(control.options.Title)
					end
					if control.registryKey then
						self.ctx.registry:update(control.registryKey, {
							subtitle = self.ctx.searchPath,
							title = if control.searchTitle then control:searchTitle() else control.options.Title,
						})
					end
				end
			end

			function Card:SetDescription(description: string?)
				self.options.Description = description
				self.descriptionLabel.Text = description or ""
				self.descriptionLabel.Visible = description ~= nil
				self.ctx.registry:update(
					self.registryKey,
					{ keywords = `{description or ""} {self.options.Keywords or ""}` }
				)
			end

			function Card:GetEnabled(): boolean?
				return if self.enabledId then self.ctx.store:get(self.enabledId) else nil
			end

			function Card:SetEnabled(on: boolean)
				if self.enabledId then
					self.ctx.store:set(self.enabledId, on == true)
				end
			end

			function Card:SetDisabled(disabled: boolean)
				self.disabled = disabled
				self.header.Interactable = not disabled
				Theme.setTextDisabled(self.titleLabel, disabled)
				Theme.setTextDisabled(self.descriptionLabel, disabled)
				if self.icon and self.icon:IsA("TextLabel") then
					Theme.setTextDisabled(self.icon, disabled)
				end
				for _, control in self.controls do
					control:SetDisabled(disabled)
				end
			end

			function Card:SetVisible(visible: boolean)
				self.visible = visible
				self.Instance.Visible = visible
				self.section:_refresh()
			end

			function Card:Focus()
				self.ctx.locate(self.Instance, function()
					if self.collapsible and not self:IsExpanded() then
						self:SetExpanded(true)
					end
				end)
				self:Flash()
			end

			function Card:Flash()
				local target = if self.grid then self.Instance else self.header
				local rest = if self.grid then 0 else 1
				Theme.bind(target, { BackgroundColor3 = "SurfaceActive" })
				target.BackgroundTransparency = 0
				task.delay(0.35, function()
					Animations.tween(target, { BackgroundTransparency = rest }, 0.6)
					task.delay(0.6, function()
						Theme.bind(target, { BackgroundColor3 = if self.grid then "Surface" else "SurfaceHover" })
					end)
				end)
			end

			function Card:GetControls()
				return table.clone(self.controls)
			end

			function Card:Destroy()
				if self.destroyed then
					return
				end
				self.destroyed = true
				if self.inspector then
					self.inspector.close()
				end
				for i = #self.controls, 1, -1 do
					self.controls[i].onDestroy = nil
					self.controls[i]:Destroy()
				end
				if self.stopSpin then
					self.stopSpin()
				end
				self.cleanup:clean()
				self.section:_forget(self)
				if self.onDestroy then
					self.onDestroy(self)
				end
			end

			return Card
		end

		-- Components/ColorPicker
		loaders[nodes["Components/ColorPicker"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Overlays = script.Parent.Parent.Overlays
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Input = require(Core.Input)
			local Util = require(Core.Util)
			local PopupManager = require(Overlays.PopupManager)
			local Control = require(script.Parent.Control)

			local WIDTH = 240
			local MAX_RECENT = 8

			local recent: { Color3 } = {}

			local ColorPicker = Control.extend("ColorPicker")

			local function remember(color: Color3)
				for i = #recent, 1, -1 do
					if recent[i]:ToHex() == color:ToHex() then
						table.remove(recent, i)
					end
				end
				table.insert(recent, 1, color)
				recent[MAX_RECENT + 1] = nil
			end

			local function bar(height: number, order: number, parent: Instance)
				return Factory.button({
					Size = UDim2.new(1, 0, 0, height),
					BackgroundTransparency = 0,
					BackgroundColor3 = Color3.new(1, 1, 1),
					LayoutOrder = order,
					Parent = parent,
				}, { Factory.corner(height // 2) })
			end

			local function cursor(parent: Instance, size: number)
				return Factory.new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(size, size),
					BackgroundTransparency = 1,
					ZIndex = 3,
					Parent = parent,
				}, {
					Factory.corner(size // 2),
					Factory.new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }),
				})
			end

			local function field(width: number, order: number, parent: Instance)
				local box = Factory.new("Frame", {
					Size = UDim2.fromOffset(width, 26),
					LayoutOrder = order,
					Parent = parent,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(7), Factory.padding(0, 8) })
				return Factory.text({
					ClassName = "TextBox",
					Size = UDim2.fromScale(1, 1),
					ClearTextOnFocus = false,
					Typography = "Description",
					TextXAlignment = Enum.TextXAlignment.Center,
					TextTruncate = Enum.TextTruncate.None,
					Parent = box,
				})
			end

			function ColorPicker.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options), ColorPicker)
				self.hasAlpha = options.Transparency ~= nil

				local swatch = Factory.button({
					Name = "Swatch",
					Size = UDim2.fromOffset(44, 24),
					BackgroundTransparency = 0,
					LayoutOrder = 2,
					Parent = self.widget,
				}, { Factory.corner(7), Factory.stroke("Border") })
				self.swatch = swatch

				self.hexLabel = Factory.text({
					Size = UDim2.fromOffset(62, 24),
					Typography = "Description",
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 1,
					Parent = self.widget,
					Theme = { TextColor3 = "TextSecondary" },
				})

				local store = ctx.store
				if self.hasAlpha then
					self.alphaId = store:define(
						if options.Id then `{options.Id}.transparency` else nil,
						math.clamp(options.Transparency, 0, 1)
					)
					self.cleanup:add(store:observe(self.alphaId, function(alpha)
						swatch.BackgroundTransparency = alpha
						Util.safeCall(options.Callback, self:GetValue(), alpha)
						if self.renderInspector then
							self.renderInspector()
						end
					end))
					swatch.BackgroundTransparency = store:get(self.alphaId)
					self.cleanup:add(function()
						store:remove(self.alphaId)
					end)
				end

				local callback = options.Callback
				self.options = Util.merge(options, {
					Callback = function(color)
						if callback then
							callback(color, self:GetTransparency())
						end
					end,
				})
				self:bind(options.Default or Color3.new(1, 1, 1), function(color)
					swatch.BackgroundColor3 = color
					self.hexLabel.Text = "#" .. string.upper(color:ToHex())
					if self.renderInspector then
						self.renderInspector()
					end
				end)

				self.cleanup:connect(swatch.Activated, function()
					if self.popup then
						self:Close()
					elseif not self.disabled then
						self:Open()
					end
				end)
				self.cleanup:add(function()
					self:Close()
				end)

				self:register("color picker hex rgb")
				return self
			end

			function ColorPicker:GetTransparency(): number
				return if self.alphaId then self.ctx.store:get(self.alphaId) else 0
			end

			function ColorPicker:SetTransparency(alpha: number)
				if self.alphaId then
					self.ctx.store:set(self.alphaId, math.clamp(alpha, 0, 1))
				end
			end

			function ColorPicker:normalize(value)
				if typeof(value) == "Color3" then
					return value
				end
				if type(value) == "string" then
					local ok, color = pcall(Color3.fromHex, value)
					if ok then
						return color
					end
				end
				return self:GetValue()
			end

			function ColorPicker:stateText()
				return "#" .. string.upper(self:GetValue():ToHex())
			end

			function ColorPicker:Open()
				if self.popup then
					return
				end
				local h, s, v = self:GetValue():ToHSV()

				local surface = PopupManager.surface(WIDTH, { Name = "ColorInspector" })
				Factory.list(10).Parent = surface
				Factory.padding(12).Parent = surface

				local sv = Factory.button({
					Size = UDim2.new(1, 0, 0, 140),
					BackgroundTransparency = 0,
					LayoutOrder = 1,
					ClipsDescendants = false,
					Parent = surface,
				}, { Factory.corner(8) })
				local white = Factory.new("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(1, 1, 1),
					Parent = sv,
				}, {
					Factory.corner(8),
					Factory.new("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
				})
				Factory.new("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.new(0, 0, 0),
					ZIndex = 2,
					Parent = sv,
				}, {
					Factory.corner(8),
					Factory.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }),
				})
				white.ZIndex = 1
				local svCursor = cursor(sv, 12)

				local hueBar = bar(12, 2, surface)
				local stops = {}
				for i = 0, 6 do
					table.insert(stops, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 % 1, 1, 1)))
				end
				Factory.new("UIGradient", { Color = ColorSequence.new(stops), Parent = hueBar })
				local hueCursor = cursor(hueBar, 14)

				local alphaBar, alphaCursor, alphaGradient
				if self.hasAlpha then
					alphaBar = bar(12, 3, surface)
					alphaGradient =
						Factory.new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = alphaBar })
					alphaCursor = cursor(alphaBar, 14)
				end

				local inputs = Factory.new("Frame", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					LayoutOrder = 4,
					Parent = surface,
				}, { Factory.list(6, true) })
				local hexBox = field(78, 1, inputs)
				local rgbBoxes = { field(40, 2, inputs), field(40, 3, inputs), field(40, 4, inputs) }
				local alphaBox = if self.hasAlpha then field(40, 5, inputs) else nil

				local recentRow = Factory.new("Frame", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					LayoutOrder = 5,
					Visible = #recent > 0,
					Parent = surface,
				}, { Factory.list(6, true) })

				local function commit()
					self:SetValue(Color3.fromHSV(h, s, v))
				end

				local function render()
					local color = Color3.fromHSV(h, s, v)
					sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					svCursor.Position = UDim2.fromScale(s, 1 - v)
					hueCursor.Position = UDim2.fromScale(h, 0.5)
					if alphaBar then
						alphaBar.BackgroundColor3 = color
						alphaCursor.Position = UDim2.fromScale(self:GetTransparency(), 0.5)
						alphaGradient.Transparency = NumberSequence.new(0, 0.9)
						if not alphaBox:IsFocused() then
							alphaBox.Text = `{math.round((1 - self:GetTransparency()) * 100)}%`
						end
					end
					if not hexBox:IsFocused() then
						hexBox.Text = "#" .. string.upper(color:ToHex())
					end
					local rgb = { color.R, color.G, color.B }
					for i, box in rgbBoxes do
						if not box:IsFocused() then
							box.Text = tostring(math.round(rgb[i] * 255))
						end
					end
				end

				self.renderInspector = function()
					local color = self:GetValue()
					if Color3.fromHSV(h, s, v):ToHex() ~= color:ToHex() then
						h, s, v = color:ToHSV()
					end
					render()
				end

				local function dragArea(area: GuiButton, onPoint: (Vector2) -> ())
					area.InputBegan:Connect(function(input)
						if Input.isPointer(input) then
							self.stopDrag = Input.drag(input, function(point)
								local rel = (point - area.AbsolutePosition) / area.AbsoluteSize
								onPoint(Vector2.new(math.clamp(rel.X, 0, 1), math.clamp(rel.Y, 0, 1)))
							end)
						end
					end)
				end
				dragArea(sv, function(rel)
					s, v = rel.X, 1 - rel.Y
					commit()
					render()
				end)
				dragArea(hueBar, function(rel)
					h = rel.X
					commit()
					render()
				end)
				if alphaBar then
					dragArea(alphaBar, function(rel)
						self:SetTransparency(rel.X)
					end)
				end

				hexBox.FocusLost:Connect(function()
					local text = string.gsub(hexBox.Text, "#", "")
					local ok, color = pcall(Color3.fromHex, text)
					if ok and #text == 6 then
						h, s, v = color:ToHSV()
						commit()
					end
					hexBox.Text = ""
					render()
				end)
				for i, box in rgbBoxes do
					box.FocusLost:Connect(function()
						local color = Color3.fromHSV(h, s, v)
						local rgb = { color.R * 255, color.G * 255, color.B * 255 }
						local n = tonumber(box.Text)
						if n then
							rgb[i] = math.clamp(math.round(n), 0, 255)
							h, s, v = Color3.fromRGB(rgb[1], rgb[2], rgb[3]):ToHSV()
							commit()
						end
						box.Text = ""
						render()
					end)
				end
				if alphaBox then
					alphaBox.FocusLost:Connect(function()
						local n = tonumber((string.gsub(alphaBox.Text, "%%", "")))
						if n then
							self:SetTransparency(1 - math.clamp(n, 0, 100) / 100)
						end
						alphaBox.Text = ""
						render()
					end)
				end

				for i, color in recent do
					local chip = Factory.button({
						Size = UDim2.fromOffset(20, 20),
						BackgroundTransparency = 0,
						BackgroundColor3 = color,
						LayoutOrder = i,
						Parent = recentRow,
					}, { Factory.corner(6), Factory.stroke("Border") })
					chip.Activated:Connect(function()
						h, s, v = color:ToHSV()
						commit()
						render()
					end)
				end

				render()
				self.popup = self.ctx.popups:open({
					content = surface,
					anchor = self.swatch,
					align = "right",
					onClose = function()
						if self.stopDrag then
							self.stopDrag()
						end
						remember(self:GetValue())
						self.popup = nil
						self.renderInspector = nil
					end,
				})
			end

			function ColorPicker:Close()
				if self.popup then
					self.popup.close()
				end
			end

			return ColorPicker
		end

		-- Components/Control
		loaders[nodes["Components/Control"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Cleanup = require(Core.Cleanup)
			local Util = require(Core.Util)

			-- Shared base for every control: a row with title/description on the left and a widget on the right.
			local Control = {}
			Control.__index = Control

			export type Context = {
				store: any,
				registry: any,
				popups: any,
				notify: (any) -> (),
				locate: (() -> ())?,
				pageTitle: string?,
				cardTitle: string?,
			}

			function Control.new(ctx: Context, parent: GuiObject, options: { [string]: any }, stacked: boolean?)
				local self = setmetatable({
					ctx = ctx,
					options = options,
					cleanup = Cleanup.new(),
					disabled = false,
					visible = true,
				}, Control)

				local hasText = options.Title ~= nil or options.Description ~= nil
				self.Instance = self.cleanup:add(Factory.new("Frame", {
					Name = options.Id or options.Title or "Control",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = options.LayoutOrder or 0,
				}, {
					Factory.list(if stacked then 8 else 12, not stacked, {
						VerticalAlignment = Enum.VerticalAlignment.Center,
						HorizontalFlex = if stacked then nil else Enum.UIFlexAlignment.None,
					}),
				}))

				if hasText then
					local text = Factory.new("Frame", {
						Name = "Text",
						Size = UDim2.fromScale(if stacked then 1 else 0, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						Parent = self.Instance,
					}, {
						Factory.list(2),
						if stacked then nil else Factory.fill(),
					})

					self.titleLabel = Factory.text({
						Text = options.Title or "",
						Size = UDim2.new(1, 0, 0, 18),
						Visible = options.Title ~= nil,
						LayoutOrder = 1,
						Parent = text,
					})

					self.descriptionLabel = Factory.text({
						Text = options.Description or "",
						Typography = "Description",
						TextWrapped = true,
						TextTruncate = Enum.TextTruncate.None,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						Visible = options.Description ~= nil,
						LayoutOrder = 2,
						Parent = text,
						Theme = { TextColor3 = "TextSecondary" },
					})
				end

				self.widget = Factory.new("Frame", {
					Name = "Widget",
					Size = if stacked then UDim2.fromScale(1, 0) else UDim2.fromScale(0, 0),
					AutomaticSize = if stacked then Enum.AutomaticSize.Y else Enum.AutomaticSize.XY,
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Parent = self.Instance,
				}, {
					Factory.list(8, not stacked, { HorizontalAlignment = Enum.HorizontalAlignment.Right }),
				})

				self.Instance.Parent = parent
				return self
			end

			-- Binds this control to a store flag. apply(value) renders, called now and on every change.
			function Control:bind(default: any, apply: (any) -> ())
				self.Instance:SetAttribute("NoWindowDrag", true)
				local options, store = self.options, self.ctx.store
				local id, value = store:define(options.Id, default)
				self.id = id
				self.cleanup:add(store:observe(id, function(new)
					apply(new)
					Util.safeCall(options.Callback, new)
				end))
				self.cleanup:add(function()
					store:remove(id)
				end)
				apply(value)
				return id
			end

			function Control:register(kind: string?)
				local options = self.options
				if not options.Title or options.Searchable == false then
					return
				end
				local ctx = self.ctx
				local key = options._SearchId
					or `{ctx.searchId}/control:{options.Id or options.LayoutOrder or options.Title}`
				self.registryKey = key
				self.cleanup:add(ctx.registry:add({
					id = key,
					kind = "control",
					title = options.Title,
					subtitle = ctx.searchPath,
					keywords = `{kind or ""} {options.Keywords or ""} {options.Description or ""}`,
					aliases = options.Aliases,
					icon = options.Icon or "three-sliders-horizontal",
					state = function()
						return self:stateText()
					end,
					activate = function()
						if ctx.locate then
							ctx.locate(self.Instance)
						end
					end,
					visible = function()
						return self.visible
					end,
				}))
			end

			function Control:stateText(): string?
				return nil
			end

			function Control:GetValue(): any
				return if self.id then self.ctx.store:get(self.id) else nil
			end

			function Control:SetValue(value: any)
				if self.id then
					self.ctx.store:set(self.id, self:normalize(value))
				end
			end

			function Control:normalize(value: any): any
				return value
			end

			function Control:SetDisabled(disabled: boolean)
				self.disabled = disabled
				self.Instance.Interactable = not disabled
				local alpha = if disabled then 0.55 else 0
				for _, inst in self.Instance:GetDescendants() do
					if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
						Theme.setTextDisabled(inst, disabled)
					elseif inst:IsA("ImageLabel") then
						inst.ImageTransparency = alpha
					end
				end
			end

			function Control:SetVisible(visible: boolean)
				self.visible = visible
				self.Instance.Visible = visible
			end

			function Control:SetTitle(title: string)
				self.options.Title = title
				if self.registryKey then
					self.ctx.registry:update(self.registryKey, { title = title })
				end
				if self.titleLabel then
					self.titleLabel.Text = title
					self.titleLabel.Visible = true
				end
			end

			function Control:SetDescription(description: string?)
				self.options.Description = description
				if self.descriptionLabel then
					self.descriptionLabel.Text = description or ""
					self.descriptionLabel.Visible = description ~= nil
				end
			end

			function Control:Destroy()
				if self.destroyed then
					return
				end
				self.destroyed = true
				self.cleanup:clean()
				if self.onDestroy then
					self.onDestroy(self)
				end
			end

			function Control.extend(name: string)
				local class = setmetatable({}, { __index = Control })
				class.__index = class
				class.ClassName = name
				return class
			end

			return Control
		end

		-- Components/Crafting/CraftingStore
		loaders[nodes["Components/Crafting/CraftingStore"]] = function(script, require)
			local CraftingStore = {}
			CraftingStore.__index = CraftingStore

			local function text(value, name)
				assert(type(value) == "string" and value:match("%S"), `{name} must be a non-empty string`)
				return value
			end

			local function integer(value, name, minimum)
				assert(
					type(value) == "number" and value % 1 == 0 and value >= minimum and value <= 9007199254740991,
					`{name} must be a finite integer >= {minimum}`
				)
				return value
			end

			local function array(value, name)
				assert(type(value) == "table", `{name} must be an array`)
				local count = 0
				for key in value do
					count += 1
					assert(
						type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #value,
						`{name} must be a dense array`
					)
				end
				assert(count == #value, `{name} must be a dense array`)
				return value
			end

			function CraftingStore.toImageUri(value)
				if type(value) == "number" then
					if value <= 0 or value % 1 ~= 0 or value > 9007199254740991 then
						return nil
					end
					value = string.format("%.0f", value)
				end
				if type(value) ~= "string" then
					return nil
				end
				local digits = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$")
				return if digits and digits:match("[1-9]") then "rbxassetid://" .. digits else nil
			end

			local function image(record, id)
				local asset = if record.ImageAssetId ~= nil then record.ImageAssetId else record.ThumbnailAssetId
				local uri = CraftingStore.toImageUri(asset)
				if asset ~= nil and not uri then
					warn(`[MacUI Crafting] {id}: invalid image asset ID`)
				end
				return uri
			end

			function CraftingStore.new(data)
				assert(type(data) == "table", "Crafting data must be a table")
				local self = setmetatable({ recipes = {}, materials = {}, categories = { "All" } }, CraftingStore)
				for _, record in array(data.Materials or {}, "Materials") do
					assert(type(record) == "table", "Material must be a table")
					local id = text(record.MaterialId, "MaterialId")
					assert(not self.materials[id], `Duplicate MaterialId: {id}`)
					self.materials[id] = {
						MaterialId = id,
						Name = text(record.Name, "Material name"),
						ImageAssetId = image(record, id),
						Owned = if record.Owned ~= nil then integer(record.Owned, "Owned", 0) else nil,
					}
				end
				local seen = { All = true }
				for _, record in array(data.Recipes or {}, "Recipes") do
					assert(type(record) == "table", "Recipe must be a table")
					local id = text(record.RecipeId, "RecipeId")
					assert(not self:GetRecipe(id), `Duplicate RecipeId: {id}`)
					local category = text(record.Category or "Other", "Category")
					local recipe = {
						RecipeId = id,
						Name = text(record.Name, "Recipe name"),
						ImageAssetId = image(record, id),
						Category = category,
						OutputCount = integer(record.OutputCount or 1, "OutputCount", 1),
						Materials = {},
					}
					if record.Station ~= nil then
						recipe.Station = text(record.Station, "Station")
					end
					if record.Tier ~= nil then
						recipe.Tier = integer(record.Tier, "Tier", 1)
					end
					local ingredients = {}
					for _, material in array(record.Materials or {}, "Recipe materials") do
						assert(type(material) == "table", "Recipe material must be a table")
						local materialId = text(material.MaterialId, "Ingredient MaterialId")
						assert(not ingredients[materialId], `Duplicate ingredient: {materialId}`)
						ingredients[materialId] = true
						table.insert(
							recipe.Materials,
							{ MaterialId = materialId, Amount = integer(material.Amount, "Amount", 1) }
						)
					end
					table.insert(self.recipes, recipe)
					if not seen[category] then
						seen[category] = true
						table.insert(self.categories, category)
					end
				end
				return self
			end

			function CraftingStore:GetRecipe(id)
				for _, recipe in self.recipes do
					if recipe.RecipeId == id then
						return recipe
					end
				end
				return nil
			end

			function CraftingStore:Search(query, category)
				query = string.lower(query or "")
				local result = {}
				for _, recipe in self.recipes do
					if
						(category == nil or category == "All" or recipe.Category == category)
						and string.find(
							string.lower(`{recipe.Name} {recipe.RecipeId} {recipe.Category}`),
							query,
							1,
							true
						)
					then
						table.insert(result, recipe)
					end
				end
				return result
			end

			function CraftingStore:SetOwned(id, amount)
				assert(self.materials[id], `Unknown MaterialId: {id}`)
				self.materials[id].Owned = integer(amount, "Owned", 0)
			end

			function CraftingStore:Requirements(id, quantity)
				local recipe = self:GetRecipe(id)
				assert(recipe, `Unknown RecipeId: {id}`)
				integer(quantity, "Quantity", 1)
				assert(recipe.OutputCount <= 9007199254740991 / quantity, "Output quantity is too large")
				local result, craftable = {}, true
				for _, ingredient in recipe.Materials do
					assert(ingredient.Amount <= 9007199254740991 / quantity, "Material quantity is too large")
					local material = self.materials[ingredient.MaterialId]
					local required = ingredient.Amount * quantity
					local known = material ~= nil and material.Owned ~= nil
					local owned = if known then material.Owned else 0
					local missing = math.max(0, required - owned)
					if not known or missing > 0 then
						craftable = false
					end
					table.insert(result, {
						MaterialId = ingredient.MaterialId,
						Name = if material then material.Name else ingredient.MaterialId,
						ImageAssetId = if material then material.ImageAssetId else nil,
						Required = required,
						Owned = owned,
						Missing = missing,
						Available = material ~= nil,
						InventoryKnown = known,
					})
				end
				return result, craftable, recipe.OutputCount * quantity
			end

			return CraftingStore
		end

		-- Components/Crafting/Views
		loaders[nodes["Components/Crafting/Views"]] = function(script, require)
			local Core = script.Parent.Parent.Parent.Core
			local Factory = require(Core.Factory)
			local Theme = require(Core.Theme)
			local Icons = require(Core.Icons)
			local Animations = require(Core.Animations)

			local Views = {}

			-- The shared tween helper replaces goals; retain only the latest tween per small visual for cleanup.
			function Views.animator(cleanup)
				local running = {}
				cleanup:add(function()
					for _, tween in running do
						tween:Cancel()
					end
					table.clear(running)
				end)
				return function(inst, goal, duration)
					if running[inst] then
						running[inst]:Cancel()
					end
					running[inst] = Animations.tween(inst, goal, duration, Enum.EasingStyle.Quad)
				end
			end

			function Views.tint(animate, inst, property, token, duration)
				local previous = inst[property]
				Theme.bind(inst, { [property] = token })
				local target = inst[property]
				inst[property] = previous
				animate(inst, { [property] = target }, duration)
			end

			-- Direct pointer events drive motion; selection remains independent of hover/press.
			function Views.interact(button, cleanup, paint)
				local hovered, pressing = false, nil
				local function refresh(duration)
					paint(
						hovered and button.Interactable ~= false,
						pressing ~= nil and button.Interactable ~= false,
						duration
					)
				end
				cleanup:connect(button.MouseEnter, function()
					hovered = true
					refresh(0.12)
				end)
				cleanup:connect(button.MouseLeave, function()
					hovered, pressing = false, nil
					refresh(0.12)
				end)
				cleanup:connect(button.InputBegan, function(input)
					if
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
					then
						pressing = input
						refresh()
					end
				end)
				cleanup:connect(button.InputEnded, function(input)
					if input == pressing then
						pressing = nil
						refresh(0.1)
					end
				end)
				cleanup:connect(button:GetPropertyChangedSignal("Interactable"), function()
					if not button.Interactable then
						hovered, pressing = false, nil
					end
					refresh()
				end)
				return refresh
			end

			function Views.text(parent, text, typography, color)
				return Factory.text({
					Text = text,
					Typography = typography or "Control",
					Size = UDim2.new(1, 0, 0, 20),
					Parent = parent,
					Theme = { TextColor3 = color or "TextPrimary" },
				})
			end

			function Views.panel(parent, name, title)
				local root = Factory.new("Frame", {
					Name = name,
					BackgroundTransparency = 0.04,
					ClipsDescendants = true,
					Parent = parent,
					Theme = { BackgroundColor3 = "Surface" },
				}, { Factory.corner(Theme.get("RadiusCard")), Factory.stroke("Border", 0.65) })
				local heading = Views.text(root, title, "Section")
				heading.Position, heading.Size = UDim2.fromOffset(12, 10), UDim2.new(1, -24, 0, 20)
				return root, heading
			end

			function Views.scroll(parent, name, top)
				return Factory.new("ScrollingFrame", {
					Name = name,
					Position = UDim2.fromOffset(8, top),
					Size = UDim2.new(1, -16, 1, -top - 8),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 3,
					VerticalScrollBarInset = Enum.ScrollBarInset.Always,
					Parent = parent,
					Theme = { ScrollBarImageColor3 = "Border" },
				}, { Factory.list(4) })
			end

			function Views.thumbnail(parent, size, cleanup)
				local root = Factory.new("Frame", {
					Name = "Thumbnail",
					Size = UDim2.fromOffset(size, size),
					BackgroundTransparency = 0.3,
					Parent = parent,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(Theme.get("RadiusControl") - 1) })
				local fallback = Icons.create({ Icon = "cube", Color = "TextMuted" }, math.round(size * 0.45), {
					Name = "Fallback",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = root,
				})
				local image = Factory.new("ImageLabel", {
					Name = "ItemImage",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = "",
					ScaleType = Enum.ScaleType.Fit,
					Parent = root,
				}, { Factory.corner(Theme.get("RadiusControl") - 1) })
				local function loaded()
					fallback.Visible = image.Image == "" or not image.IsLoaded
				end
				cleanup:connect(image:GetPropertyChangedSignal("IsLoaded"), loaded)
				return {
					Instance = root,
					image = image,
					fallback = fallback,
					Set = function(_, uri)
						if image.Image ~= (uri or "") then
							image.Image = uri or ""
						end
						loaded()
					end,
				}
			end

			function Views.recipeCard(parent, recipe, cleanup, onSelect)
				local stroke = Factory.stroke("Border", 0.85)
				local button = Factory.button({
					Name = recipe.RecipeId,
					Size = UDim2.fromOffset(128, 104),
					BackgroundTransparency = 0.72,
					Parent = parent,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(Theme.get("RadiusControl")), stroke })
				button.SelectionImageObject = cleanup:add(
					Factory.new(
						"Frame",
						{ Name = "RecipeFocus", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 },
						{ Factory.corner(Theme.get("RadiusControl")), Factory.stroke("TextSecondary", 0.15) }
					)
				)
				local icon = Views.thumbnail(button, 44, cleanup)
				icon:Set(recipe.ImageAssetId)
				local title = Views.text(button, recipe.Name, "Section")
				title.Position, title.Size = UDim2.fromOffset(10, 62), UDim2.new(1, -20, 0, 18)
				local metadata = if recipe.Tier then `Tier {recipe.Tier}` else `Output ×{recipe.OutputCount}`
				local meta = Views.text(button, metadata, "Hint", "TextMuted")
				meta.Position, meta.Size = UDim2.fromOffset(10, 82), UDim2.new(1, -20, 0, 14)
				local animate = Views.animator(cleanup)
				local row = { Instance = button, icon = icon, selected = false, stroke = stroke }
				local repaint = Views.interact(button, cleanup, function(hovered, pressed, duration)
					local alpha = if row.selected
						then (if hovered then 0.08 else 0.18)
						elseif hovered then 0.58
						else 0.72
					animate(button, { BackgroundTransparency = if pressed then 0.5 else alpha }, duration)
					animate(
						stroke,
						{ Transparency = if row.selected then 0.45 elseif hovered then 0.65 else 0.85 },
						duration
					)
					Theme.bind(title, { TextColor3 = if row.selected then "TextPrimary" else "TextSecondary" })
				end)
				function row:Select(selected, motion)
					if self.selected == selected then
						return
					end
					self.selected = selected
					repaint(if motion then 0.18 else nil)
				end
				function row:Resize(width)
					local size = if width >= 160 then 48 else 44
					icon.Instance.AnchorPoint = Vector2.zero
					icon.Instance.Position = UDim2.fromOffset(math.floor((width - size) / 2), 10)
					icon.Instance.Size = UDim2.fromOffset(size, size)
					repaint()
				end
				cleanup:connect(button.Activated, onSelect)
				row:Resize(128)
				return row
			end

			function Views.materialRow(parent, cleanup)
				local root = Factory.new("Frame", {
					Name = "Requirement",
					Size = UDim2.new(1, 0, 0, 64),
					BackgroundTransparency = 0.7,
					Parent = parent,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(Theme.get("RadiusControl") - 2) })
				local icon = Views.thumbnail(root, 32, cleanup)
				icon.Instance.Position = UDim2.fromOffset(8, 10)
				local name = Views.text(root, "")
				name.Position, name.Size = UDim2.fromOffset(48, 6), UDim2.new(1, -56, 0, 18)
				local amount = Views.text(root, "", "Hint", "TextSecondary")
				local status = Views.text(root, "", "Hint", "CraftingReady")
				local animate = Views.animator(cleanup)
				local previous, previousColor
				local row = { Instance = root, icon = icon, amountLabel = amount, statusLabel = status }
				function row:Resize(width)
					local wide = width >= 260
					name.Size = UDim2.new(1, if wide then -144 else -56, 0, 18)
					amount.Position, amount.Size =
						UDim2.fromOffset(48, 25), UDim2.new(1, if wide then -144 else -56, 0, 16)
					status.Position = if wide then UDim2.new(1, -88, 0, 23) else UDim2.fromOffset(48, 43)
					status.Size = if wide then UDim2.fromOffset(80, 18) else UDim2.new(1, -56, 0, 16)
					status.TextXAlignment = if wide then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left
				end
				function row:Update(requirement, motion)
					name.Text = requirement.Name
					icon:Set(requirement.ImageAssetId)
					local value = if requirement.InventoryKnown
						then `Owned {requirement.Owned} / Need {requirement.Required}`
						else `Need {requirement.Required} · unknown`
					status.Text = if not requirement.InventoryKnown
						then "Unknown"
						elseif requirement.Missing > 0 then `Missing {requirement.Missing}`
						else "Ready"
					local color = if not requirement.InventoryKnown
						then "TextMuted"
						elseif requirement.Missing > 0 then "CraftingMissing"
						else "CraftingReady"
					Views.tint(
						animate,
						status,
						"TextColor3",
						color,
						if motion and previousColor ~= color then 0.18 else nil
					)
					previousColor = color
					if value ~= previous then
						amount.Text = value
						if motion and not Animations.reducedMotion then
							root.BackgroundTransparency = 0.08
						end
						animate(root, { BackgroundTransparency = 0.7 }, if motion then 0.2 else nil)
						previous = value
					end
				end
				row:Resize(160)
				return row
			end

			return Views
		end

		-- Components/Crafting
		loaders[nodes["Components/Crafting"]] = function(script, require)
			local Components = script.Parent
			local Core = Components.Parent.Core
			local Factory = require(Core.Factory)
			local Theme = require(Core.Theme)
			local Cleanup = require(Core.Cleanup)
			local Store = require(Core.Store)
			local Animations = require(Core.Animations)
			local Control = require(Components.Control)
			local TextInput = require(Components.Input)
			local Icons = require(Core.Icons)
			local Model = require(script.CraftingStore)
			local Views = require(script.Views)

			local Crafting = Control.extend("Crafting")
			local GAP, MIN_HEIGHT = 10, 420
			-- ponytail: preview batches stop at 999; raise this ceiling for games with larger crafting batches.
			local MAX_QUANTITY = 999

			function Crafting.new(ctx, parent, options)
				options = table.clone(options or {})
				assert(options.OnCraft == nil or type(options.OnCraft) == "function", "OnCraft must be a function")
				local model = Model.new({ Recipes = options.Recipes, Materials = options.Materials })
				assert(
					options.DefaultRecipeId == nil or model:GetRecipe(options.DefaultRecipeId),
					"Unknown DefaultRecipeId"
				)
				local self =
					setmetatable(Control.new(ctx, parent, { LayoutOrder = options.LayoutOrder }, true), Crafting)
				self.options, self.model = options, model
				self.quantity, self.busy = 1, false
				self.rows, self.materialRows = {}, {}
				self.animate = Views.animator(self.cleanup)
				self.Instance.Name = options.Id or "Crafting"
				self.Instance:SetAttribute("NoWindowDrag", true)
				self.dataCleanup = self.cleanup:add(Cleanup.new())
				self.materialCleanup = self.cleanup:add(Cleanup.new())
				self.workspace = Factory.new("Frame", {
					Name = "CraftingWorkspace",
					Size = UDim2.new(1, 0, 0, MIN_HEIGHT),
					BackgroundTransparency = 1,
					Parent = self.widget,
				})
				self.browser, self.browserHeading = Views.panel(self.workspace, "RecipeBrowser", "Crafting Recipes")
				self.details = Views.panel(self.workspace, "RecipeDetails", "Selected Recipe")
				self.materials = Views.panel(self.workspace, "MaterialsNeeded", "Materials Needed")
				self.recipeList = Views.scroll(self.browser, "Recipes", 78)
				self.recipeList:FindFirstChildOfClass("UIListLayout"):Destroy()
				-- Keep the outer card strokes inside the scrolling clip, including the first/last row.
				Factory.padding(2).Parent = self.recipeList
				self.recipeGrid = Factory.new("UIGridLayout", {
					CellSize = UDim2.fromOffset(128, 104),
					CellPadding = UDim2.fromOffset(8, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = self.recipeList,
				})
				self.materialList = Views.scroll(self.materials, "Materials", 60)
				self.materialList.Size = UDim2.new(1, -16, 1, -104)
				self.materialRecipe = Views.text(self.materials, "", "Hint", "TextSecondary")
				self.materialRecipe.Position, self.materialRecipe.Size =
					UDim2.fromOffset(12, 34), UDim2.new(1, -24, 0, 18)
				self.materialSummary = Views.text(self.materials, "", "Hint", "TextSecondary")
				self.materialSummary.Position, self.materialSummary.Size =
					UDim2.new(0, 12, 1, -32), UDim2.new(1, -24, 0, 20)
				self.materialSummary.Visible = false
				self.browserEmpty = Views.text(self.browser, "No recipes available.", "Description", "TextMuted")
				self.browserEmpty.TextWrapped, self.browserEmpty.TextTruncate = true, Enum.TextTruncate.None
				self.browserEmpty.Position, self.browserEmpty.Size = UDim2.fromOffset(12, 80), UDim2.new(1, -24, 0, 40)
				self.materialEmpty =
					Views.text(self.materialList, "Select a recipe to view materials.", "Description", "TextMuted")
				self.materialEmpty.TextWrapped, self.materialEmpty.TextTruncate = true, Enum.TextTruncate.None
				self.materialEmpty.Size = UDim2.new(1, 0, 0, 48)
				self:_buildSearch()
				self:_buildDetails()
				self.cleanup:add(Theme.onChanged(function()
					self:_refresh()
				end))
				self.cleanup:connect(self.workspace:GetPropertyChangedSignal("AbsoluteSize"), function()
					if self.lastWidth ~= self.workspace.AbsoluteSize.X then
						self:_fit()
					end
				end)
				local node = parent
				while node and not node:IsA("ScrollingFrame") do
					node = node.Parent
				end
				self.viewport = node
				if node then
					self.cleanup:connect(node:GetPropertyChangedSignal("AbsoluteWindowSize"), function()
						self:_fit()
					end)
					self.cleanup:connect(node:GetPropertyChangedSignal("Visible"), function()
						if node.Visible then
							self:_reveal()
						end
					end)
				end
				self:_renderData()
				self:_fit()
				self:SelectRecipe(options.DefaultRecipeId)
				if node and node.Visible then
					task.defer(function()
						if not self.destroyed then
							self:_reveal()
						end
					end)
				end
				return self
			end

			function Crafting:_reveal()
				if self.entered then
					return
				end
				self.entered = true
				if Animations.reducedMotion then
					return
				end
				for _, inst in self.workspace:GetDescendants() do
					local property = if inst:IsA("TextLabel")
						then "TextTransparency"
						elseif inst:IsA("ImageLabel") then "ImageTransparency"
						else nil
					if property and type(inst[property]) == "number" and inst[property] < 1 then
						local target = inst[property]
						inst[property] = math.min(1, target + 0.3)
						self.animate(inst, { [property] = target }, 0.18)
					end
				end
			end

			function Crafting:_buildSearch()
				local editCtx = setmetatable({ store = Store.new() }, { __index = self.ctx })
				self.search = self.cleanup:add(TextInput.new(editCtx, self.browser, {
					Placeholder = "Search recipes…",
					Live = true,
					Searchable = false,
					Callback = function()
						self:_filter()
					end,
				}))
				self.search.Instance.AutomaticSize = Enum.AutomaticSize.None
				self.search.Instance.Position, self.search.Instance.Size =
					UDim2.fromOffset(12, 36), UDim2.new(1, -24, 0, 32)
				self.search.widget.AutomaticSize, self.search.widget.Size =
					Enum.AutomaticSize.None, UDim2.fromScale(1, 1)
				self.search.field.Parent.Size = UDim2.fromScale(1, 1)
			end

			function Crafting:_buildDetails()
				self.detailsEmpty =
					Views.text(self.details, "Select a recipe to view details.", "Description", "TextMuted")
				self.detailsEmpty.Position, self.detailsEmpty.Size = UDim2.fromOffset(12, 40), UDim2.new(1, -24, 0, 40)
				self.detailsEmpty.TextWrapped, self.detailsEmpty.TextTruncate = true, Enum.TextTruncate.None
				self.detailContent = Factory.new("Frame", {
					Name = "Content",
					Position = UDim2.fromOffset(12, 38),
					Size = UDim2.new(1, -24, 1, -50),
					BackgroundTransparency = 1,
					Visible = false,
					Parent = self.details,
				})
				self.preview = Views.thumbnail(self.detailContent, 48, self.cleanup)
				self.outputName = Views.text(self.detailContent, "", "Feature")
				self.outputName.Position, self.outputName.Size = UDim2.fromOffset(60, 2), UDim2.new(1, -60, 0, 20)
				self.outputCount = Views.text(self.detailContent, "", "Description", "TextSecondary")
				self.outputCount.Position, self.outputCount.Size = UDim2.fromOffset(60, 26), UDim2.new(1, -60, 0, 16)
				self.station = Views.text(self.detailContent, "", "Description", "TextMuted")
				self.station.Position, self.station.Size = UDim2.fromOffset(0, 60), UDim2.new(1, -116, 0, 28)
				local stepper = Factory.new("Frame", {
					Name = "Quantity",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 60),
					Size = UDim2.fromOffset(104, 28),
					BackgroundTransparency = 0,
					Parent = self.detailContent,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(Theme.get("RadiusControl") - 1) })
				self.quantityField = Factory.text({
					ClassName = "TextBox",
					Name = "QuantityInput",
					Text = "1",
					ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextTruncate = Enum.TextTruncate.None,
					Position = UDim2.fromOffset(30, 0),
					Size = UDim2.fromOffset(44, 28),
					Parent = stepper,
				})
				local function quantityButton(name, icon, x, delta)
					local button = Factory.button({
						Name = name,
						Position = UDim2.fromOffset(x, 0),
						Size = UDim2.fromOffset(28, 28),
						Parent = stepper,
						Theme = { BackgroundColor3 = "SurfaceHover" },
					}, { Factory.corner(6) })
					Icons.create(icon, 16, { Position = UDim2.fromOffset(6, 6), Parent = button })
					Views.interact(button, self.cleanup, function(hovered, pressed, duration)
						self.animate(
							button,
							{ BackgroundTransparency = if pressed then 0 elseif hovered then 0.35 else 1 },
							duration
						)
					end)
					self.cleanup:connect(button.Activated, function()
						if not self.disabled then
							self:SetQuantity(math.clamp(self.quantity + delta, 1, MAX_QUANTITY))
						end
					end)
					return button
				end
				self.minus = quantityButton("Decrease", "minus", 0, -1)
				self.plus = quantityButton("Increase", "plus", 76, 1)
				self.cleanup:connect(self.quantityField.FocusLost, function()
					local ok = not self.disabled and pcall(self.SetQuantity, self, tonumber(self.quantityField.Text))
					if not ok then
						self.quantityField.Text = tostring(self.quantity)
						self.status.Text = `Enter a quantity from 1 to {MAX_QUANTITY}.`
					end
				end)
				self.craftButton = Factory.button(
					{ Name = "Craft", Parent = self.detailContent, Theme = { BackgroundColor3 = "SurfaceActive" } },
					{ Factory.corner(Theme.get("RadiusControl") - 1), Factory.stroke("Border", 0.5) }
				)
				self.craftLabel = Views.text(self.craftButton, "Craft", "Section")
				self.craftLabel.Size, self.craftLabel.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
				self.paintCraft = Views.interact(self.craftButton, self.cleanup, function(hovered, pressed, duration)
					local enabled = self.craftButton.Interactable
					self.animate(self.craftButton, {
						BackgroundTransparency = if not enabled
							then 0.78
							elseif pressed then 0.55
							elseif hovered then 0.08
							else 0.2,
					}, duration)
					Theme.bind(self.craftLabel, { TextColor3 = if enabled then "TextPrimary" else "TextMuted" })
				end)
				self.cleanup:connect(self.craftButton.Activated, function()
					self:_craft()
				end)
				self.summary = Views.text(self.detailContent, "", "Description", "TextSecondary")
				self.status = Views.text(self.detailContent, "", "Description", "TextMuted")
			end

			function Crafting:_renderData()
				self.dataCleanup:clean()
				table.clear(self.rows)
				for index, recipe in self.model.recipes do
					local row = Views.recipeCard(self.recipeList, recipe, self.dataCleanup, function()
						if not self.disabled then
							self:SelectRecipe(recipe.RecipeId, true)
						end
					end)
					self.dataCleanup:add(row.Instance)
					row.Instance.LayoutOrder = index
					self.rows[recipe.RecipeId] = row
				end
				self:_filter()
			end

			function Crafting:_filter()
				local matches = self.model:Search(self.search:GetValue())
				for _, row in self.rows do
					row.Instance.Visible = false
				end
				for _, recipe in matches do
					self.rows[recipe.RecipeId].Instance.Visible = true
				end
				self.browserEmpty.Visible = #matches == 0
				self.browserEmpty.Text = if #self.model.recipes == 0
					then "No recipes available."
					else "No matching recipes."
			end

			function Crafting:SelectRecipe(id, animate)
				local recipe = if id then self.model:GetRecipe(id) else nil
				assert(id == nil or recipe, `Unknown RecipeId: {id}`)
				local changed = self.selectedRecipe ~= id
				self.selectedRecipe = id
				self.detailContent.Visible, self.detailsEmpty.Visible = recipe ~= nil, recipe == nil
				for rowId, row in self.rows do
					row:Select(rowId == id, animate and changed)
				end
				self.materialEmpty.Visible = recipe == nil or #recipe.Materials == 0
				self.materialEmpty.Text = if recipe
					then "No materials required."
					else "Select a recipe to view materials."
				self.materialRecipe.Text = if recipe then recipe.Name else ""
				self.materialSummary.Visible = recipe ~= nil
				if not recipe then
					for _, row in self.materialRows do
						row.Instance.Visible = false
					end
					self.materialCount = 0
					self:_fitMaterials()
					return
				end
				self.preview:Set(recipe.ImageAssetId)
				self.outputName.Text = recipe.Name
				self.station.Text = (recipe.Station or "No station")
					.. (if recipe.Tier then ` · Tier {recipe.Tier}` else "")
				self:_refresh(animate)
				local duration = if animate and changed then 0.18 else nil
				if duration and not Animations.reducedMotion then
					self.detailContent.Position = UDim2.fromOffset(12, 44)
				end
				self.animate(self.detailContent, { Position = UDim2.fromOffset(12, 38) }, duration)
				for _, inst in self.detailContent:GetDescendants() do
					local property = if inst:IsA("TextLabel")
						then "TextTransparency"
						elseif inst:IsA("ImageLabel") then "ImageTransparency"
						else nil
					if property then
						local target = if inst:IsA("ImageLabel") and self.disabled then 0.55 else 0
						if duration and not Animations.reducedMotion then
							inst[property] = 0.35
						end
						self.animate(inst, { [property] = target }, duration)
					end
				end
			end

			function Crafting:_refresh(animate)
				local recipe = self.model:GetRecipe(self.selectedRecipe)
				if not recipe then
					return
				end
				local requirements, craftable, output = self.model:Requirements(recipe.RecipeId, self.quantity)
				self.quantityField.Text = tostring(self.quantity)
				self.outputCount.Text = `Output ×{output}`
				self.minus.Interactable, self.plus.Interactable =
					not self.disabled and self.quantity > 1, not self.disabled and self.quantity < MAX_QUANTITY
				for _, row in self.materialRows do
					row.Instance.Visible = false
				end
				for index, requirement in requirements do
					local row = self.materialRows[requirement.MaterialId]
					if not row then
						row = Views.materialRow(self.materialList, self.materialCleanup)
						self.materialCleanup:add(row.Instance)
						self.materialRows[requirement.MaterialId] = row
					end
					row.Instance.LayoutOrder = index
					row.Instance.Visible = true
					row:Resize(self.materials.Size.X.Offset - 19)
					row:Update(requirement, animate)
				end
				self.materialCount = #requirements
				self:_fitMaterials()
				local unknown, firstMissing, missingCount = false, nil, 0
				for _, requirement in requirements do
					if not requirement.InventoryKnown then
						unknown = true
					elseif requirement.Missing > 0 then
						missingCount += 1
						firstMissing = firstMissing or requirement
					end
				end
				self.summary.Text = if unknown
					then "Inventory unknown"
					elseif firstMissing then `Missing {firstMissing.Missing} {firstMissing.Name}`
					else `Ready to craft ×{self.quantity}`
				self.materialSummary.Text = if unknown
					then "Inventory unknown"
					elseif firstMissing then `Missing {missingCount} {if missingCount == 1
						then "material"
						else "materials"}`
					else "All materials ready"
				local color = if unknown then "TextMuted" elseif firstMissing then "CraftingMissing" else "CraftingReady"
				Theme.bind(self.summary, { TextColor3 = color })
				Theme.bind(self.materialSummary, { TextColor3 = color })
				self.craftButton.Interactable = craftable and not self.busy and not self.disabled
				self.craftLabel.Text = if self.busy then "Sending…" else "Craft"
				self.paintCraft()
				self.status.Text = if self.busy
					then "Waiting for game integration."
					elseif not self.options.OnCraft then "Preview only. No items are consumed."
					else ""
			end

			function Crafting:SetQuantity(quantity)
				assert(
					type(quantity) == "number" and quantity % 1 == 0 and quantity >= 1 and quantity <= MAX_QUANTITY,
					`Quantity must be an integer from 1 to {MAX_QUANTITY}`
				)
				if self.selectedRecipe then
					self.model:Requirements(self.selectedRecipe, quantity)
				end
				local changed = self.quantity ~= quantity
				self.quantity = quantity
				self:_refresh(true)
				if changed and not self.quantityField:IsFocused() then
					if not Animations.reducedMotion then
						self.quantityField.TextTransparency = 0.3
					end
					self.animate(self.quantityField, { TextTransparency = 0 }, 0.1)
				end
			end

			function Crafting:_craft()
				if self.disabled or self.busy or not self.selectedRecipe then
					return
				end
				local requirements, craftable, output = self.model:Requirements(self.selectedRecipe, self.quantity)
				if not craftable then
					return
				end
				if not self.options.OnCraft then
					self.status.Text = "Preview only. No items are consumed."
					return
				end
				local id = self.selectedRecipe
				local request =
					{ RecipeId = id, Quantity = self.quantity, OutputCount = output, Requirements = requirements }
				self.busy = true
				self:_refresh()
				local onCraft = self.options.OnCraft
				task.spawn(function()
					if self.destroyed then
						return
					end
					local ok, result, message = pcall(onCraft, request)
					if self.destroyed then
						return
					end
					self.busy = false
					self:_refresh()
					if self.selectedRecipe == id then
						self.status.Text = if not ok
							then "Craft request failed."
							elseif result == false then tostring(message or "Craft request declined.")
							else "Craft request sent."
					end
					if not ok then
						warn(`[MacUI Crafting] OnCraft failed: {result}`)
					end
				end)
			end

			function Crafting:SetData(data)
				local model = Model.new(data)
				local id = if model:GetRecipe(self.selectedRecipe) then self.selectedRecipe else nil
				if id then
					model:Requirements(id, self.quantity)
				end
				self.model, self.selectedRecipe = model, nil
				self.materialCleanup:clean()
				table.clear(self.materialRows)
				self:_renderData()
				self:_fit()
				self:SelectRecipe(id)
				if self.disabled then
					self:SetDisabled(true)
				end
			end

			function Crafting:SetOwned(id, amount)
				self.model:SetOwned(id, amount)
				self:_refresh(true)
			end

			function Crafting:SetDisabled(disabled)
				Control.SetDisabled(self, disabled)
				self.search:SetDisabled(disabled)
				self:_refresh()
			end

			function Crafting:_fitMaterials()
				local height = math.min(
					math.max(0, self.materials.Size.Y.Offset - 104),
					math.max(0, (self.materialCount or 0) * 68 - 4)
				)
				if self.materialEmpty.Visible then
					height = 48
				end
				self.materialList.Size = UDim2.new(1, -16, 0, height)
				self.materialSummary.Position = UDim2.fromOffset(12, 60 + height + 8)
			end

			function Crafting:_fit()
				local scale = self.ctx.scale()
				local width = math.floor(self.workspace.AbsoluteSize.X / scale)
				if width <= 0 then
					return
				end
				self.lastWidth = self.workspace.AbsoluteSize.X
				local compact = width < 520 or self.workspace.AbsoluteSize.X < 420
				local available = if self.viewport
					then math.floor(self.viewport.AbsoluteWindowSize.Y / scale) - 20
					else MIN_HEIGHT
				local height = math.max(MIN_HEIGHT, available)
				local centerX, centerY, centerWidth, materialsX, materialsY, materialsWidth
				if compact then
					centerX, centerY, centerWidth = 0, 0, width
					materialsX, materialsY, materialsWidth = 0, centerY + height + GAP, width
					self.workspace.Size = UDim2.new(1, 0, 0, materialsY + 220)
				else
					local usable = width - GAP
					local rightWidth = math.floor(usable * 0.30)
					centerX, centerY, centerWidth = 0, 0, usable - rightWidth
					materialsX, materialsY, materialsWidth = width - rightWidth, 0, rightWidth
					self.workspace.Size = UDim2.new(1, 0, 0, height)
				end
				local topHeight = height - GAP - 226
				self.browser.Position, self.browser.Size =
					UDim2.fromOffset(centerX, centerY), UDim2.fromOffset(centerWidth, topHeight)
				self.details.Position, self.details.Size =
					UDim2.fromOffset(centerX, centerY + topHeight + GAP),
					UDim2.fromOffset(centerWidth, height - topHeight - GAP)
				self.materials.Position, self.materials.Size =
					UDim2.fromOffset(materialsX, materialsY),
					UDim2.fromOffset(materialsWidth, if compact then 220 else height)
				local narrow = centerWidth < 320
				self.detailContent.Size = UDim2.new(1, -24, 0, 176)
				self.craftButton.Position = if narrow then UDim2.fromOffset(0, 120) else UDim2.new(1, -104, 0, 104)
				self.craftButton.Size = if narrow then UDim2.new(1, 0, 0, 30) else UDim2.fromOffset(104, 32)
				self.summary.Position = UDim2.fromOffset(0, if narrow then 96 else 102)
				self.summary.Size = UDim2.new(1, if narrow then 0 else -116, 0, if narrow then 18 else 36)
				self.summary.TextWrapped = not narrow
				self.status.Position, self.status.Size =
					UDim2.fromOffset(0, if narrow then 156 else 144), UDim2.new(1, 0, 0, 20)
				self:_fitMaterials()
				for _, row in self.materialRows do
					row:Resize(materialsWidth - 19)
				end
				local gridWidth = math.max(1, centerWidth - 23)
				local columns = if gridWidth >= 352 then 3 elseif gridWidth >= 232 then 2 else 1
				local cellWidth = math.floor((gridWidth - (columns - 1) * 8) / columns)
				self.recipeGrid.CellSize = UDim2.fromOffset(cellWidth, 104)
				self.recipeGrid.FillDirectionMaxCells = columns
				for _, row in self.rows do
					row:Resize(cellWidth)
				end
			end

			return Crafting
		end

		-- Components/Display
		loaders[nodes["Components/Display"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Icons = require(Core.Icons)
			local Util = require(Core.Util)
			local Control = require(script.Parent.Control)
			local AnimatedImage = require(script.Parent.AnimatedImage)

			local Display = {}

			local BADGE_TOKENS = {
				Neutral = { "SurfaceActive", "TextSecondary" },
				Success = { "Success", "Success" },
				Warning = { "Warning", "Warning" },
				Danger = { "Danger", "Danger" },
				Accent = { "Accent", "Accent" },
			}

			function Display.badge(text: string, kind: string?): Frame
				local tokens = BADGE_TOKENS[kind or "Neutral"] or BADGE_TOKENS.Neutral
				local tinted = kind ~= nil and kind ~= "Neutral"
				local badge = Factory.new("Frame", {
					Name = "Badge",
					Size = UDim2.fromOffset(0, 20),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = if tinted then 0.84 else 0,
					Theme = { BackgroundColor3 = tokens[1] },
				}, {
					Factory.corner(6),
					Factory.padding(0, 7),
				})
				Factory.text({
					Name = "Label",
					Text = text,
					Typography = "Hint",
					Size = UDim2.fromScale(0, 1),
					AutomaticSize = Enum.AutomaticSize.X,
					TextTruncate = Enum.TextTruncate.None,
					Parent = badge,
					Theme = { TextColor3 = tokens[2] },
				})
				return badge
			end

			-- Label: title + optional value on the right.
			local Label = Control.extend("Label")
			Display.Label = Label

			function Label.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options), Label)
				self.valueLabel = Factory.text({
					Text = options.Value or "",
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					TextTruncate = Enum.TextTruncate.None,
					Visible = options.Value ~= nil,
					Parent = self.widget,
					Theme = { TextColor3 = "TextSecondary" },
				})
				return self
			end

			function Label:SetValue(value: any)
				self.valueLabel.Text = tostring(value)
				self.valueLabel.Visible = value ~= nil
			end

			function Label:GetValue()
				return self.valueLabel.Text
			end

			-- Paragraph: wrapped body copy.
			local Paragraph = Control.extend("Paragraph")
			Display.Paragraph = Paragraph

			function Paragraph.new(ctx, parent, options)
				local self = setmetatable(
					Control.new(ctx, parent, {
						Title = options.Title,
						LayoutOrder = options.LayoutOrder,
						Description = options.Content or options.Text or "",
					}, true),
					Paragraph
				)
				self.options = options
				self.widget.Visible = false
				return self
			end

			function Paragraph:SetValue(text: string)
				self:SetDescription(text)
			end

			function Paragraph:GetValue()
				return self.options.Description or self.options.Content or self.options.Text
			end

			-- Divider
			local Divider = Control.extend("Divider")
			Display.Divider = Divider

			function Divider.new(_ctx, parent, options)
				local self =
					setmetatable({ options = options, visible = true, cleanup = require(Core.Cleanup).new() }, Divider)
				self.Instance = self.cleanup:add(Factory.new("Frame", {
					Name = "Divider",
					Size = UDim2.new(1, 0, 0, 1),
					LayoutOrder = options.LayoutOrder or 0,
					Parent = parent,
					Theme = { BackgroundColor3 = "Border" },
				}))
				self.Instance.BackgroundTransparency = 0.4
				return self
			end

			function Divider:GetValue()
				return nil
			end

			-- Status badge row
			local Status = Control.extend("Status")
			Display.Status = Status

			function Status.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options), Status)
				self:SetValue(options.Value or "Idle", options.Kind)
				return self
			end

			function Status:SetValue(text: string, kind: string?)
				if self.badge then
					self.badge:Destroy()
				end
				self.text, self.kind = text, kind or self.kind
				self.badge = Display.badge(text, self.kind)
				self.badge.Parent = self.widget
			end

			function Status:GetValue()
				return self.text
			end

			function Status:stateText()
				return self.text
			end

			-- Progress bar: Value 0..1 or nil for an indeterminate shimmer.
			local Progress = Control.extend("Progress")
			Display.Progress = Progress

			function Progress.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options), Progress)

				self.percent = Factory.text({
					Size = UDim2.fromOffset(40, 18),
					Typography = "Description",
					TextXAlignment = Enum.TextXAlignment.Right,
					LayoutOrder = 1,
					Parent = self.widget,
					Theme = { TextColor3 = "TextSecondary" },
				})
				local rail = Factory.new("Frame", {
					Size = UDim2.fromOffset(options.Width or 150, 4),
					LayoutOrder = 2,
					ClipsDescendants = true,
					Parent = self.widget,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(2) })
				self.fill = Factory.new("Frame", {
					Size = UDim2.fromScale(0, 1),
					Parent = rail,
					Theme = { BackgroundColor3 = options.Color or "Accent" },
				}, { Factory.corner(2) })
				self:SetValue(options.Value)
				return self
			end

			function Progress:SetValue(value: number?)
				if self.stopShimmer then
					self.stopShimmer()
					self.stopShimmer = nil
				end
				self.value = value
				if value == nil then
					self.percent.Text = ""
					self.fill.Size = UDim2.fromScale(0.3, 1)
					self.fill.Position = UDim2.fromScale(-0.3, 0)
					local tween = game:GetService("TweenService"):Create(
						self.fill,
						TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1),
						{ Position = UDim2.fromScale(1, 0) }
					)
					if not Animations.reducedMotion then
						tween:Play()
					end
					self.stopShimmer = function()
						tween:Cancel()
						self.fill.Position = UDim2.new()
					end
					self.cleanup:add(self.stopShimmer)
					return
				end
				local alpha = math.clamp(value, 0, 1)
				self.percent.Text = `{math.round(alpha * 100)}%`
				self.fill.Position = UDim2.new()
				Animations.tween(self.fill, { Size = UDim2.fromScale(alpha, 1) }, Theme.Motion.Toggle)
			end

			function Progress:GetValue()
				return self.value
			end

			function Progress:stateText()
				return if self.value then `{math.round(self.value * 100)}%` else nil
			end

			-- Image preview or animated sprite sheet.
			local Image = Control.extend("Image")
			Display.Image = Image

			function Image.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options, true), Image)
				local height = options.Height or 140

				local frame = Factory.new("Frame", {
					Size = UDim2.new(1, 0, 0, height),
					ClipsDescendants = true,
					Parent = self.widget,
					Theme = { BackgroundColor3 = "Background" },
				}, { Factory.corner(10) })

				if options.Columns and options.Frames then
					self.animation = AnimatedImage.new({
						Image = options.Image,
						FrameSize = options.FrameSize,
						Columns = options.Columns,
						Frames = options.Frames,
						FPS = options.FPS,
						Loop = options.Loop,
						Autoplay = options.Autoplay,
						Speed = options.Speed,
						Size = UDim2.fromScale(1, 1),
					})
					self.animation.Instance.Parent = frame
					self.cleanup:add(self.animation)
				else
					Factory.new("ImageLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Image = options.Image or "",
						ScaleType = options.ScaleType or Enum.ScaleType.Fit,
						Parent = frame,
					})
				end
				return self
			end

			function Image:Play()
				if self.animation then
					self.animation:Play()
				end
			end

			function Image:Pause()
				if self.animation then
					self.animation:Pause()
				end
			end

			function Image:GetValue()
				return self.options.Image
			end

			-- Tooltip: hover a GuiObject to show text in the overlay layer.
			function Display.tooltip(popups, target: GuiObject, text: string): () -> ()
				local open
				local token = 0
				local enter = target.MouseEnter:Connect(function()
					token += 1
					local mine = token
					task.delay(0.45, function()
						if mine ~= token or open or not target:IsDescendantOf(game) then
							return
						end
						local tip = Factory.new("Frame", {
							Size = UDim2.fromOffset(0, 24),
							AutomaticSize = Enum.AutomaticSize.X,
							Theme = { BackgroundColor3 = "SurfaceActive" },
						}, {
							Factory.corner(6),
							Factory.stroke("PaletteBorder"),
							Factory.padding(0, 8),
							Factory.new("UISizeConstraint", { MaxSize = Vector2.new(260, 24) }),
						})
						Factory.text({
							Text = text,
							Typography = "Hint",
							Size = UDim2.fromScale(0, 1),
							AutomaticSize = Enum.AutomaticSize.X,
							Parent = tip,
						})
						open = popups:open({
							content = tip,
							anchor = target,
							gap = 6,
							onClose = function()
								open = nil
							end,
						})
					end)
				end)
				local leave = target.MouseLeave:Connect(function()
					token += 1
					if open then
						open.close()
					end
				end)
				return function()
					enter:Disconnect()
					leave:Disconnect()
					if open then
						open.close()
					end
				end
			end

			-- Icon button used in headers.
			function Display.iconButton(icon: any, size: number?, callback: (() -> ())?): TextButton
				local box = size or 26
				local button = Factory.button({
					Name = if type(icon) == "string" then icon else "IconButton",
					Size = UDim2.fromOffset(box, box),
					BackgroundTransparency = 1,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, { Factory.corner(7) })
				local glyph = Icons.create(icon, math.round(box * 0.62), {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = button,
				})
				button.MouseEnter:Connect(function()
					Animations.tween(button, { BackgroundTransparency = 0 }, Theme.Motion.Hover)
					if type(icon) == "string" then
						Icons.tint(glyph, "TextPrimary")
					end
				end)
				button.MouseLeave:Connect(function()
					Animations.tween(button, { BackgroundTransparency = 1 }, Theme.Motion.Hover)
					if type(icon) == "string" then
						Icons.tint(glyph, "TextSecondary")
					end
				end)
				if callback then
					button.Activated:Connect(function()
						Util.safeCall(callback)
					end)
				end
				return button
			end

			return Display
		end

		-- Components/Dropdown
		loaders[nodes["Components/Dropdown"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Overlays = script.Parent.Parent.Overlays
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Icons = require(Core.Icons)
			local Input = require(Core.Input)
			local PopupManager = require(Overlays.PopupManager)
			local Control = require(script.Parent.Control)

			local ROW = 30
			local MAX_ROWS = 8

			local Dropdown = Control.extend("Dropdown")

			local function label(option: any): string
				return if type(option) == "table" then option.Label or tostring(option.Value) else tostring(option)
			end

			local function valueOf(option: any): any
				return if type(option) == "table" then option.Value else option
			end

			function Dropdown.new(ctx, parent, options)
				local compact = options._CompactGrid == true
				local self = setmetatable(Control.new(ctx, parent, options, compact), Dropdown)
				self.items = options.Options or {}
				self.multi = options.Multi == true
				if compact then
					self.Instance.AutomaticSize = Enum.AutomaticSize.None
					self.Instance.Size = UDim2.new(1, 0, 0, 54)
					self.Instance:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 6)
					self.widget.AutomaticSize = Enum.AutomaticSize.None
					self.widget.Size = UDim2.new(1, 0, 0, 32)
					if self.titleLabel then
						self.titleLabel.Size = UDim2.new(1, 0, 0, 16)
						self.titleLabel.FontFace = Theme.Typography.Hint.FontFace
						self.titleLabel.TextSize = Theme.Typography.Hint.TextSize
						Theme.bind(self.titleLabel, { TextColor3 = "TextMuted" })
						self.descriptionLabel.Visible = false
					end
				end

				local field = Factory.button({
					Name = "Field",
					Size = if compact then UDim2.new(1, 0, 0, 32) else UDim2.fromOffset(options.Width or 160, 28),
					BackgroundTransparency = 0,
					LayoutOrder = 1,
					Parent = self.widget,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, {
					Factory.corner(Theme.get("RadiusControl") - 1),
					Factory.padding(0, 8, 0, 10),
				})
				self.field = field

				self.valueLabel = Factory.text({
					Size = UDim2.new(1, -20, 1, 0),
					Parent = field,
				})

				Icons.create("down", 16, {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Parent = field,
				})

				self.cleanup:connect(field.MouseEnter, function()
					Theme.bind(field, { BackgroundColor3 = "SurfaceHover" })
				end)
				self.cleanup:connect(field.MouseLeave, function()
					Theme.bind(field, { BackgroundColor3 = "SurfaceActive" })
				end)

				local default = options.Default
				if self.multi then
					default = if type(default) == "table" then table.clone(default) else {}
				elseif default == nil and self.items[1] ~= nil then
					default = valueOf(self.items[1])
				end
				self:bind(default, function()
					self:_renderValue()
					if self.renderList then
						self.renderList()
					end
				end)

				self.cleanup:connect(field.Activated, function()
					if self.popup then
						self:Close()
					elseif not self.disabled then
						self:Open()
					end
				end)
				self.cleanup:add(function()
					self:Close()
				end)

				self:register("dropdown select")
				return self
			end

			function Dropdown:_isSelected(value: any): boolean
				local current = self:GetValue()
				if self.multi then
					return table.find(current, value) ~= nil
				end
				return current == value
			end

			function Dropdown:_renderValue()
				self.valueLabel.Text = self:stateText() or "Select"
				Theme.bind(self.valueLabel, { TextColor3 = if self:stateText() then "TextPrimary" else "TextMuted" })
			end

			function Dropdown:stateText(): string?
				local current = self:GetValue()
				if self.multi then
					if #current == 0 then
						return nil
					end
					local names = {}
					for _, item in self.items do
						if table.find(current, valueOf(item)) then
							table.insert(names, label(item))
						end
					end
					return table.concat(names, ", ")
				end
				for _, item in self.items do
					if valueOf(item) == current then
						return label(item)
					end
				end
				return if current ~= nil then tostring(current) else nil
			end

			function Dropdown:normalize(value)
				if self.multi then
					local out = {}
					for _, v in if type(value) == "table" then value else { value } do
						if not table.find(out, v) then
							table.insert(out, v)
						end
					end
					return out
				end
				return value
			end

			function Dropdown:_choose(item: any)
				local value = valueOf(item)
				if self.multi then
					local current = table.clone(self:GetValue())
					local index = table.find(current, value)
					if index then
						table.remove(current, index)
					else
						table.insert(current, value)
					end
					self:SetValue(current)
				else
					self:SetValue(value)
					self:Close()
				end
			end

			function Dropdown:Open()
				if self.popup then
					return
				end
				local options = self.options
				local searchable = options.Searchable == true or #self.items > 10
				local width =
					math.max(self.field.AbsoluteSize.X / self.ctx.popups.scale, if options._CompactGrid then 1 else 200)
				local surface = PopupManager.surface(width, { Name = "DropdownMenu" })
				Factory.list(0).Parent = surface

				local query
				if searchable then
					local bar = Factory.new("Frame", {
						Size = UDim2.new(1, 0, 0, 38),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						Parent = surface,
					}, { Factory.padding(0, 12) })
					query = Factory.text({
						ClassName = "TextBox",
						Size = UDim2.fromScale(1, 1),
						Text = "",
						PlaceholderText = "Search options...",
						ClearTextOnFocus = false,
						TextTruncate = Enum.TextTruncate.None,
						Parent = bar,
						Theme = { PlaceholderColor3 = "TextMuted" },
					})
					Factory.new("Frame", {
						Size = UDim2.new(1, 0, 0, 1),
						LayoutOrder = 2,
						Parent = surface,
						Theme = { BackgroundColor3 = "Border" },
					})
				end

				local list = Factory.new("ScrollingFrame", {
					Size = UDim2.new(1, 0, 0, ROW),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 3,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					LayoutOrder = 3,
					Parent = surface,
					Theme = { ScrollBarImageColor3 = "Border" },
				}, {
					Factory.list(2),
					Factory.padding(6),
				})

				local rows, shown = {}, {}
				local selected = 1

				local function highlight(index: number)
					selected = index
					for i, row in rows do
						if row:IsA("TextButton") then
							Animations.tween(
								row,
								{ BackgroundTransparency = if i == index then 0 else 1 },
								Theme.Motion.Hover
							)
						end
					end
					-- Keep the highlighted row visible. Absolute values are on-screen pixels; CanvasPosition is unscaled.
					local row = rows[index]
					if row then
						local ratio = self.ctx.popups.scale
						local rowTop = (row.AbsolutePosition.Y - list.AbsolutePosition.Y) / ratio
						local rowBottom = rowTop + row.AbsoluteSize.Y / ratio
						local view = list.AbsoluteWindowSize.Y / ratio
						if rowTop < 0 then
							list.CanvasPosition -= Vector2.new(0, -rowTop + 6)
						elseif rowBottom > view then
							list.CanvasPosition += Vector2.new(0, rowBottom - view + 6)
						end
					end
				end

				local function render()
					for _, row in rows do
						row:Destroy()
					end
					table.clear(rows)
					table.clear(shown)

					local text = if query then string.lower(query.Text) else ""
					for _, item in self.items do
						if text == "" or string.find(string.lower(label(item)), text, 1, true) then
							table.insert(shown, item)
						end
					end

					for i, item in shown do
						local row = Factory.button({
							Size = UDim2.new(1, 0, 0, ROW),
							BackgroundTransparency = 1,
							LayoutOrder = i,
							Parent = list,
							Theme = { BackgroundColor3 = "PaletteSelected" },
						}, {
							Factory.corner(7),
							Factory.padding(0, 10),
						})
						Factory.text({
							Text = label(item),
							Size = UDim2.new(1, -22, 1, 0),
							Parent = row,
						})
						if self:_isSelected(valueOf(item)) then
							Icons.create({ Icon = "check", Color = "Accent" }, 16, {
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.fromScale(1, 0.5),
								Parent = row,
							})
						end
						row.MouseEnter:Connect(function()
							highlight(i)
						end)
						row.Activated:Connect(function()
							self:_choose(item)
						end)
						rows[i] = row
					end

					if #shown == 0 then
						rows[1] = Factory.text({
							Text = "No matching options",
							Size = UDim2.new(1, 0, 0, ROW),
							Parent = list,
							Theme = { TextColor3 = "TextMuted" },
						}, { Factory.padding(0, 10) })
					end

					list.Size = UDim2.new(1, 0, 0, math.min(math.max(#shown, 1), MAX_ROWS) * (ROW + 2) + 10)
					highlight(math.clamp(selected, 1, math.max(#shown, 1)))
				end
				self.renderList = render

				for i, item in self.items do
					if self:_isSelected(valueOf(item)) then
						selected = i
						break
					end
				end
				render()

				local stopKeys = Input.listen(function(input)
					if input.KeyCode == Enum.KeyCode.Down then
						highlight(math.min(selected + 1, #shown))
						return true
					elseif input.KeyCode == Enum.KeyCode.Up then
						highlight(math.max(selected - 1, 1))
						return true
					elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
						if shown[selected] then
							self:_choose(shown[selected])
						end
						if self.multi and query then
							task.defer(function()
								if query.Parent then
									query:CaptureFocus()
								end
							end)
						end
						return true
					end
					return false
				end)

				if query then
					query:GetPropertyChangedSignal("Text"):Connect(function()
						selected = 1
						render()
					end)
					task.defer(function()
						if query.Parent then
							query:CaptureFocus()
						end
					end)
				end

				local followWidth
				if options._CompactGrid then
					followWidth = self.field:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
						surface.Size = UDim2.fromOffset(
							math.max(1, math.round(self.field.AbsoluteSize.X / self.ctx.popups.scale)),
							0
						)
					end)
				end
				self.popup = self.ctx.popups:open({
					content = surface,
					anchor = self.field,
					align = "right",
					onClose = function()
						if followWidth then
							followWidth:Disconnect()
						end
						stopKeys()
						self.popup = nil
						self.renderList = nil
					end,
				})
			end

			function Dropdown:Close()
				if self.popup then
					self.popup.close()
				end
			end

			function Dropdown:SetOptions(items: { any }, keepValue: boolean?)
				self.items = items
				if not keepValue then
					if self.multi then
						local kept = {}
						for _, value in self:GetValue() do
							for _, item in items do
								if valueOf(item) == value then
									table.insert(kept, value)
								end
							end
						end
						self:SetValue(kept)
					else
						local found = false
						for _, item in items do
							if valueOf(item) == self:GetValue() then
								found = true
							end
						end
						if not found then
							self:SetValue(if items[1] ~= nil then valueOf(items[1]) else nil)
						end
					end
				end
				self:_renderValue()
				if self.renderList then
					self.renderList()
				end
			end

			function Dropdown:GetOptions()
				return self.items
			end

			return Dropdown
		end

		-- Components/Input
		loaders[nodes["Components/Input"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Icons = require(Core.Icons)
			local Util = require(Core.Util)
			local Control = require(script.Parent.Control)

			local TextInput = Control.extend("Input")

			function TextInput.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options), TextInput)

				local box = Factory.new("Frame", {
					Name = "Box",
					Size = UDim2.fromOffset(options.Width or 190, 28),
					LayoutOrder = 1,
					Parent = self.widget,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, {
					Factory.corner(Theme.get("RadiusControl") - 1),
					Factory.padding(0, 6, 0, 10),
				})
				local stroke = Factory.stroke("Accent", 1)
				stroke.Parent = box

				local field = Factory.text({
					ClassName = "TextBox",
					Size = UDim2.new(1, if options.Clearable == false then 0 else -22, 1, 0),
					Text = "",
					PlaceholderText = options.Placeholder or "",
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.None,
					ClipsDescendants = true,
					Parent = box,
					Theme = { PlaceholderColor3 = "TextMuted" },
				})
				self.field = field

				local clear
				if options.Clearable ~= false then
					clear = Factory.button({
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(18, 18),
						Visible = false,
						Parent = box,
					})
					Icons.create({ Icon = "x", Color = "TextMuted" }, 14, {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Parent = clear,
					})
					self.cleanup:connect(clear.Activated, function()
						field.Text = ""
						self:_commit("")
					end)
				end

				self.error = Factory.text({
					Typography = "Description",
					Size = UDim2.fromOffset(190, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					TextWrapped = true,
					Visible = false,
					LayoutOrder = 2,
					Parent = self.widget,
					Theme = { TextColor3 = "Danger" },
				})
				self.widget:FindFirstChildOfClass("UIListLayout").FillDirection = Enum.FillDirection.Vertical
				self.widget:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 4)

				self:bind(options.Default or "", function(value)
					if not field:IsFocused() then
						field.Text = value
					end
					if clear then
						clear.Visible = value ~= ""
					end
				end)

				self.cleanup:connect(field.Focused, function()
					Animations.tween(stroke, { Transparency = 0.4 }, Theme.Motion.Hover)
				end)
				self.cleanup:connect(field:GetPropertyChangedSignal("Text"), function()
					if clear then
						clear.Visible = field.Text ~= ""
					end
					if options.Live then
						self:_commit(field.Text)
					end
				end)
				self.cleanup:connect(field.FocusLost, function(enter)
					Animations.tween(stroke, { Transparency = 1 }, Theme.Motion.Hover)
					if enter or not options.SubmitOnEnter then
						self:_commit(field.Text)
					else
						field.Text = self:GetValue()
					end
					if enter then
						Util.safeCall(options.OnSubmit, self:GetValue())
					end
				end)

				self:register("input text")
				return self
			end

			function TextInput:_commit(text: string)
				local validate = self.options.Validate
				if validate then
					local ok, result = pcall(validate, text)
					local message = if ok
						then (if result == true or result == nil
							then nil
							else (if type(result) == "string" then result else "Invalid value"))
						else "Invalid value"
					self.error.Text = message or ""
					self.error.Visible = message ~= nil
					if message then
						return
					end
				end
				self:SetValue(text)
			end

			function TextInput:normalize(value)
				return tostring(value or "")
			end

			function TextInput:stateText()
				local value = self:GetValue()
				return if value ~= "" then value else nil
			end

			function TextInput:Focus()
				self.field:CaptureFocus()
			end

			return TextInput
		end

		-- Components/Keybind
		loaders[nodes["Components/Keybind"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Input = require(Core.Input)
			local Util = require(Core.Util)
			local Control = require(script.Parent.Control)

			local IGNORED = {
				[Enum.KeyCode.Unknown] = true,
				[Enum.KeyCode.Escape] = true,
				[Enum.KeyCode.Backspace] = true,
				[Enum.KeyCode.Delete] = true,
			}

			local Keybind = Control.extend("Keybind")

			function Keybind.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options), Keybind)
				self.listening = false

				local chip = Factory.button({
					Name = "Key",
					Size = UDim2.fromOffset(0, 26),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 0,
					LayoutOrder = 1,
					Parent = self.widget,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, {
					Factory.corner(7),
					Factory.padding(0, 10),
					Factory.new("UISizeConstraint", { MinSize = Vector2.new(54, 26) }),
				})
				self.chip = chip

				self.chipLabel = Factory.text({
					Size = UDim2.fromScale(1, 1),
					AutomaticSize = Enum.AutomaticSize.X,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextTruncate = Enum.TextTruncate.None,
					Parent = chip,
				})

				local default = options.Default
				if typeof(default) ~= "EnumItem" then
					default = Enum.KeyCode.Unknown
				end
				self:bind(default, function()
					self:_render()
				end)

				self.cleanup:connect(chip.Activated, function()
					if not self.disabled then
						self:_listen(not self.listening)
					end
				end)

				self.cleanup:add(Input.listen(function(input, processed)
					if self.listening then
						if input.UserInputType ~= Enum.UserInputType.Keyboard then
							if Input.isPointer(input) and not Input.inside(self.chip, Input.position(input)) then
								self:_listen(false)
							end
							return false
						end
						local key = input.KeyCode
						if key == Enum.KeyCode.Escape then
							self:_listen(false)
						elseif key == Enum.KeyCode.Backspace or key == Enum.KeyCode.Delete then
							self:_listen(false)
							self:SetValue(Enum.KeyCode.Unknown)
						elseif not IGNORED[key] then
							local reserved = ctx.isReserved and ctx.isReserved(key, self)
							if reserved then
								ctx.notify({
									Title = "Key unavailable",
									Content = `{Input.keyName(key)} is used by {reserved}.`,
									Kind = "warning",
								})
							else
								self:_listen(false)
								self:SetValue(key)
							end
						end
						return true
					end

					local key = self:GetValue()
					if not processed and key ~= Enum.KeyCode.Unknown and input.KeyCode == key and options.OnPress then
						Util.safeCall(options.OnPress, key)
					end
					return false
				end))

				self:register("keybind key shortcut")
				return self
			end

			function Keybind:_listen(on: boolean)
				self.listening = on
				self:_render()
			end

			function Keybind:_render()
				local key = self:GetValue()
				if self.listening then
					self.chipLabel.Text = "Press a key"
					Theme.bind(self.chipLabel, { TextColor3 = "Accent" })
				else
					self.chipLabel.Text = if key == Enum.KeyCode.Unknown then "None" else Input.keyName(key)
					Theme.bind(
						self.chipLabel,
						{ TextColor3 = if key == Enum.KeyCode.Unknown then "TextMuted" else "TextPrimary" }
					)
				end
			end

			function Keybind:normalize(value)
				if typeof(value) == "EnumItem" then
					return value
				end
				if type(value) == "string" then
					local ok, item = pcall(function()
						return Enum.KeyCode[value]
					end)
					if ok then
						return item
					end
				end
				return Enum.KeyCode.Unknown
			end

			function Keybind:stateText()
				local key = self:GetValue()
				return if key == Enum.KeyCode.Unknown then nil else Input.keyName(key)
			end

			return Keybind
		end

		-- Components/PrioritySelector
		loaders[nodes["Components/PrioritySelector"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Cleanup = require(Core.Cleanup)
			local Icons = require(Core.Icons)
			local Input = require(Core.Input)
			local Util = require(Core.Util)
			local Control = require(script.Parent.Control)
			local PopupManager = require(script.Parent.Parent.Overlays.PopupManager)
			local GuiService = game:GetService("GuiService")

			local PrioritySelector = Control.extend("PrioritySelector")

			export type Item = { Id: string, Label: string }
			export type Options = {
				Id: string?,
				Title: string?,
				Description: string?,
				Items: { Item | string },
				Default: { string }?,
				Columns: ("Auto" | number)?,
				OnChanged: (({ string }) -> ())?,
				Callback: (({ string }) -> ())?,
				LayoutOrder: number?,
				Searchable: boolean?,
				Keywords: string?,
				Aliases: (string | { string })?,
			}

			local function same(a, b)
				if #a ~= #b then
					return false
				end
				for i, id in a do
					if b[i] ~= id then
						return false
					end
				end
				return true
			end

			local function array(value)
				assert(type(value) == "table", "Expected an array")
				for key in value do
					assert(
						type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #value,
						"Expected a dense array"
					)
				end
				for i = 1, #value do
					assert(value[i] ~= nil, "Expected a dense array")
				end
			end

			local function itemsOf(items)
				array(items)
				local list, byId = {}, {}
				for _, item in items do
					local id = if type(item) == "string" then item else type(item) == "table" and item.Id
					local label = if type(item) == "string" then item else type(item) == "table" and item.Label
					assert(
						type(id) == "string" and id ~= "" and type(label) == "string",
						"Items need a non-empty Id and string Label"
					)
					assert(not byId[id], `Duplicate item id "{id}"`)
					local entry = { Id = id, Label = label }
					byId[id] = entry
					table.insert(list, entry)
				end
				return list, byId
			end

			function PrioritySelector:_reconcile(order, strict)
				if strict then
					array(order)
				end
				local result, seen = {}, {}
				for _, id in if type(order) == "table" then order else {} do
					local valid = type(id) == "string" and self.byId[id] ~= nil and not seen[id]
					assert(not strict or valid, `Unknown or duplicate item id "{tostring(id)}"`)
					if valid then
						seen[id] = true
						table.insert(result, id)
					end
				end
				for _, item in self.items do
					if not seen[item.Id] then
						table.insert(result, item.Id)
					end
				end
				return result
			end

			function PrioritySelector.new(ctx, parent, options: Options)
				options = table.clone(options or {})
				assert(
					options.Columns == nil
						or options.Columns == "Auto"
						or options.Columns == 1
						or options.Columns == 2
						or options.Columns == 3,
					"Columns must be Auto, 1, 2 or 3"
				)
				options.Columns = options.Columns or 2
				for _, key in { "Callback", "OnChanged" } do
					assert(options[key] == nil or type(options[key]) == "function", `{key} must be a function`)
				end
				local items, byId = itemsOf(if options.Items == nil then {} else options.Items)
				local default = PrioritySelector._reconcile(
					{ items = items, byId = byId },
					if options.Default == nil then {} else options.Default,
					true
				)
				assert(
					options.Id == nil or (type(options.Id) == "string" and options.Id ~= ""),
					"Id must be a non-empty string"
				)
				assert(
					not (ctx.store.defined and ctx.store.defined[options.Id]),
					"PrioritySelector Id already exists in this window"
				)
				local self = setmetatable(Control.new(ctx, parent, options, true), PrioritySelector)
				self.items, self.byId, self.order = items, byId, {}
				self.itemCleanup = self.cleanup:add(Cleanup.new())
				self.pickerCleanup = self.cleanup:add(Cleanup.new())
				self.cleanup:add(function()
					if self.stopGesture then
						self.stopGesture()
					end
				end)
				self.Instance:SetAttribute("NoWindowDrag", true)
				self.widget:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Left
				if self.titleLabel then
					self.titleLabel.FontFace = Theme.Typography.Section.FontFace
					self.titleLabel.TextSize = Theme.Typography.Section.TextSize
				end
				self.grid = Factory.new("Frame", {
					Name = "RankChips",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = self.widget,
				})
				self.gridLayout = Factory.new("UIGridLayout", {
					CellSize = UDim2.fromOffset(180, 38),
					CellPadding = UDim2.fromOffset(Theme.get("SpacingSmall"), Theme.get("SpacingSmall")),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = self.grid,
				})
				self.gridLayout.FillDirectionMaxCells = if type(options.Columns) == "number" then options.Columns else 2
				self.cleanup:connect(self.grid:GetPropertyChangedSignal("AbsoluteSize"), function()
					self:_fit()
				end)
				local id, loaded = ctx.store:define(options.Id, default, function(value)
					return self:_reconcile(value, false)
				end)
				self.id, self.order = id, table.clone(loaded)
				self.cleanup:add(function()
					ctx.store:remove(id)
				end)
				self.cleanup:add(ctx.store:observe(id, function(value)
					if same(value, self.order) then
						return
					end
					self.order = table.clone(value)
					self:_render()
					if not self.silent then
						Util.safeCall(options.OnChanged or options.Callback, self:GetOrder())
					end
				end))
				if not self:_buildItems() then
					error("Priority selector initialization cancelled.")
				end
				self:register("priority order rank")
				return self
			end

			function PrioritySelector:_dismiss(restoreFocus)
				if self.destroyed then
					return
				end
				self.restoreFocus = restoreFocus
				if self.popup then
					self.popup.close()
				end
			end

			function PrioritySelector:_select(itemId)
				if self.selectedItemId == itemId then
					self:_dismiss(true)
					return
				end
				self:_dismiss(false)
				self.selectedItemId = itemId
				self:_buildPicker()
				self:_render()
				self.restoreFocus = nil
				self.popup = self.ctx.popups:open({
					content = self.panel,
					anchor = self.chips[itemId].button,
					regions = { self.Instance },
					onClose = function()
						local focused = GuiService.SelectedObject
						local hadFocus = focused
							and (focused:IsDescendantOf(self.panel) or focused:IsDescendantOf(self.Instance))
						local restore = self.restoreFocus ~= false and hadFocus
						self.popup, self.selectedItemId = nil, nil
						self.panel, self.positions, self.positionLayout = nil, nil, nil
						self.positionButtons, self.panelTitle, self.dismissButton = nil, nil, nil
						self.pickerCleanup:clean()
						if self.stopGesture then
							self.stopGesture()
						end
						self.gestureScrolls = nil
						self:_render()
						if restore and self.chips[itemId] and self.chips[itemId].button.Parent then
							GuiService.SelectedObject = self.chips[itemId].button
						end
					end,
				})
				self.pickerCleanup:connect(self.popup.uiScale:GetPropertyChangedSignal("Scale"), function()
					self:_fitPicker()
				end)
			end

			function PrioritySelector:_trackPress(button, cleanup)
				(cleanup or self.itemCleanup):connect(button.InputBegan, function(input)
					if self.disabled or not Input.isPointer(input) then
						return
					end
					if self.stopGesture then
						self.stopGesture()
					end
					self.gestureBlocked = false
					self.gestureScrolls = {}
					local ancestor = button.Parent
					while ancestor do
						if ancestor:IsA("ScrollingFrame") then
							table.insert(self.gestureScrolls, { frame = ancestor, position = ancestor.CanvasPosition })
						end
						ancestor = ancestor.Parent
					end
					local origin = Input.position(input)
					self.stopGesture = Input.drag(input, function(point)
						if (point - origin).Magnitude >= 8 then
							self.gestureBlocked = true
						end
					end, function()
						self.stopGesture = nil
					end)
				end)
			end

			function PrioritySelector:_canActivate(input)
				if self.disabled then
					return false
				end
				if input and Input.isPointer(input) then
					if self.gestureBlocked then
						return false
					end
					for _, scroll in self.gestureScrolls or {} do
						if not scroll.frame.Parent or scroll.frame.CanvasPosition ~= scroll.position then
							return false
						end
					end
				end
				return true
			end

			function PrioritySelector:_buildPicker()
				local padding, gap = Theme.get("SpacingMedium"), Theme.get("SpacingSmall")
				self.panel = PopupManager.surface(220, { Name = "PriorityPositionPicker" })
				self.panel:SetAttribute("ItemId", self.selectedItemId)
				self.panel:SetAttribute("NoWindowDrag", true)
				Factory.padding(padding).Parent = self.panel
				Factory.list(gap).Parent = self.panel
				local header = Factory.new("Frame", {
					Name = "Header",
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = self.panel,
				})
				self.panelTitle = Factory.text({
					Text = "Move to position",
					Typography = "Description",
					Size = UDim2.new(1, -32, 1, 0),
					Parent = header,
					Theme = { TextColor3 = "TextSecondary" },
				})
				self.dismissButton = Factory.button({
					Name = "DismissPositionPicker",
					Size = UDim2.fromOffset(28, 28),
					Selectable = true,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Parent = header,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, { Factory.corner(Theme.get("RadiusControl") - 1) })
				Icons.create({ Icon = "x", Color = "TextMuted" }, 12, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = self.dismissButton,
				})
				self:_trackPress(self.dismissButton, self.pickerCleanup)
				self.pickerCleanup:connect(self.dismissButton.Activated, function(input)
					if self:_canActivate(input) then
						self:_dismiss(true)
					end
				end)
				self.positions = Factory.new("ScrollingFrame", {
					Name = "Positions",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 3,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ClipsDescendants = true,
					LayoutOrder = 2,
					Parent = self.panel,
					Theme = { ScrollBarImageColor3 = "TextMuted" },
				})
				self.positionLayout = Factory.new("UIGridLayout", {
					CellSize = UDim2.fromOffset(40, 30),
					CellPadding = UDim2.fromOffset(gap, gap),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = self.positions,
				})
				self.positionButtons = {}
				for index = 1, #self.order do
					local position = Factory.button({
						Name = `Position{index}`,
						LayoutOrder = index,
						Selectable = true,
						Parent = self.positions,
						BackgroundTransparency = 0,
						Theme = { BackgroundColor3 = "SurfaceHover" },
					}, { Factory.corner(Theme.get("RadiusControl") - 1) })
					local label = Factory.text({
						Text = string.format("%02d", index),
						Typography = "Hint",
						Size = UDim2.fromScale(1, 1),
						TextXAlignment = Enum.TextXAlignment.Center,
						Parent = position,
					})
					self:_trackPress(position, self.pickerCleanup)
					self.pickerCleanup:connect(position.Activated, function(input)
						if self:_canActivate(input) and self.selectedItemId then
							self:Move(self.selectedItemId, index)
							self:_dismiss(true)
						end
					end)
					self.pickerCleanup:connect(position:GetPropertyChangedSignal("GuiState"), function()
						self:_paintPosition(index)
					end)
					self.positionButtons[index] = { button = position, label = label }
				end
				self.pickerCleanup:connect(self.ctx.popups.layer:GetPropertyChangedSignal("AbsoluteSize"), function()
					self:_fitPicker()
				end)
				self:_fitPicker()
			end

			function PrioritySelector:_fitPicker()
				if not self.panel then
					return
				end
				local padding, gap = Theme.get("SpacingMedium"), Theme.get("SpacingSmall")
				local count, scale = #self.order, self.ctx.popups.scale
				local bounds = self.ctx.popups.layer.AbsoluteSize
				local preferred =
					math.max(1, if count <= 4 then count elseif count <= 10 then math.ceil(count / 2) else 5)
				local desired = math.clamp(preferred * 40 + (preferred - 1) * gap + padding * 2, 200, 260)
				local width = math.max(1, math.floor(math.min(desired, (bounds.X - 16) / scale)))
				local inner = math.max(1, width - padding * 2)
				local columns = math.min(preferred, math.max(1, math.floor((inner + gap) / (40 + gap))))
				local rows = math.ceil(count / columns)
				local available = math.max(0, (bounds.Y - 16) / scale - padding * 2 - 28 - gap)
				local height = math.min(math.min(rows, 3) * 30 + math.max(0, math.min(rows, 3) - 1) * gap, available)
				self.positions.ScrollingEnabled = height < rows * 30 + math.max(0, rows - 1) * gap
				local reserve = if self.positions.ScrollingEnabled then 6 else 0
				local cell = if count <= 4
					then math.min(40, inner)
					else math.max(1, math.floor((inner - gap * (columns - 1) - reserve) / columns))
				self.panel.Size = UDim2.fromOffset(width, 0)
				self.positionLayout.CellSize = UDim2.fromOffset(cell, 30)
				self.positionLayout.FillDirectionMaxCells = columns
				self.positions.Size = UDim2.new(1, 0, 0, math.floor(height))
			end

			function PrioritySelector:_fit()
				local width = math.floor(self.grid.AbsoluteSize.X / self.ctx.scale() + 0.001)
				if width > 0 then
					local columns = if width >= 590 then 3 elseif width >= 370 then 2 else 1
					if self.columns == 3 and width >= 588 then
						columns = 3
					elseif self.columns == 2 and width >= 368 and width < 590 then
						columns = 2
					end
					if type(self.options.Columns) == "number" then
						columns = math.min(columns, self.options.Columns)
					end
					self.columns = columns
					self.gridLayout.FillDirectionMaxCells = columns
					local gap = Theme.get("SpacingSmall")
					local cell = math.max(1, math.floor((width - gap * (columns - 1)) / columns))
					if self.cell ~= cell then
						self.cell = cell
						self.gridLayout.CellSize = UDim2.fromOffset(cell, 38)
					end
				end
				self:_syncHeight()
				if self.panel then
					self:_fitPicker()
				end
			end

			function PrioritySelector:_syncHeight()
				local columns = math.max(1, self.columns or (if type(self.options.Columns) == "number" then self.options.Columns else 2))
				local rows = math.ceil(#self.items / columns)
				local height = rows * 38 + math.max(0, rows - 1) * Theme.get("SpacingSmall")
				if self.grid.Size.Y.Offset ~= height then
					self.grid.Size = UDim2.new(1, 0, 0, height)
				end
			end

			function PrioritySelector:_buildItems()
				self.buildVersion = (self.buildVersion or 0) + 1
				local version = self.buildVersion
				self.itemCleanup:clean()
				self.chips = {}
				local rankWidth = math.max(22, #tostring(#self.items) * 7)
				for index, item in ipairs(self.items) do
					-- Yield during large lists so slow/obfuscated startup does not monopolize a frame.
					if index > 1 and (index - 1) % 6 == 0 then
						task.wait()
						if self.destroyed or self.buildVersion ~= version or not self.Instance.Parent then
							return false
						end
					end
					local chip = self.itemCleanup:add(Factory.button({
						Name = item.Id,
						Selectable = true,
						Parent = self.grid,
						BackgroundTransparency = 0,
						Theme = { BackgroundColor3 = "SurfaceHover" },
					}, {
						Factory.corner(Theme.get("RadiusControl") - 1),
						Factory.padding(0, Theme.get("SpacingMedium")),
					}))
					local border = Factory.stroke("Border", 0.6)
					border.Parent = chip
					local badge = Factory.new("Frame", {
						Name = "RankBadge",
						Size = UDim2.fromOffset(rankWidth, 22),
						BackgroundTransparency = 0.25,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
						Parent = chip,
						Theme = { BackgroundColor3 = "SurfaceActive" },
					}, { Factory.corner(Theme.get("SpacingSmall")) })
					local rank = Factory.text({
						Name = "Rank",
						Size = UDim2.fromScale(1, 1),
						Typography = "Hint",
						Parent = badge,
						TextXAlignment = Enum.TextXAlignment.Center,
						Theme = { TextColor3 = "TextMuted" },
					})
					Factory.text({
						Text = item.Label,
						Typography = "Control",
						Position = UDim2.fromOffset(rankWidth + 8, 0),
						Size = UDim2.new(1, -rankWidth - 28, 1, 0),
						Parent = chip,
					})
					local chevron = Icons.create({ Icon = "chevron-small-down", Color = "TextMuted" }, 12, {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Parent = chip,
					})
					self:_trackPress(chip)
					self.itemCleanup:connect(chip.Activated, function(input)
						if self:_canActivate(input) then
							self:_select(item.Id)
						end
					end)
					self.itemCleanup:connect(chip:GetPropertyChangedSignal("GuiState"), function()
						self:_paintChip(item.Id)
					end)
					self.chips[item.Id] = { button = chip, rank = rank, border = border, chevron = chevron }
				end
				self:_fit()
				self:_render()
				if self.disabled then
					Control.SetDisabled(self, true)
				end
				return true
			end

			function PrioritySelector:_paintChip(id)
				local chip = self.chips[id]
				if not chip then return end
				local selected = id == self.selectedItemId
				local state = chip.button.GuiState
				local color = if selected then "SurfaceActive" else "SurfaceHover"
				if not self.disabled then
					if state == Enum.GuiState.Press then
						color = "PaletteSelected"
					elseif state == Enum.GuiState.Hover then
						color = "SurfaceActive"
					end
				end
				Theme.bind(chip.button, { BackgroundColor3 = color })
				Theme.bind(chip.rank, { TextColor3 = if selected then "Accent" else "TextMuted" })
				chip.border.Transparency = if selected then 0.4 else 0.6
				chip.chevron.Rotation = if selected then 180 else 0
			end

			function PrioritySelector:_paintPosition(index)
				local position = self.positionButtons[index]
				local current = self.selectedItemId and self.order[index] == self.selectedItemId
				local state = position.button.GuiState
				local color = if current then "SurfaceActive" else "SurfaceHover"
				if not self.disabled then
					if state == Enum.GuiState.Press then
						color = "PaletteSelected"
					elseif state == Enum.GuiState.Hover then
						color = "SurfaceActive"
					end
				end
				Theme.bind(position.button, { BackgroundColor3 = color })
				Theme.bind(position.label, { TextColor3 = if current then "Accent" else "TextPrimary" })
			end

			function PrioritySelector:_render()
				self:_fit()
				for index, id in self.order do
					local chip = self.chips and self.chips[id]
					if chip then
						chip.button.LayoutOrder = index
						chip.rank.Text = string.format("%02d", index)
						self:_paintChip(id)
					end
				end
				for index in self.positionButtons or {} do
					self:_paintPosition(index)
				end
			end

			function PrioritySelector:GetOrder(): { string }
				return table.clone(self.order)
			end

			function PrioritySelector:SetOrder(order: { string }, options: { Silent: boolean }?)
				assert(
					options == nil
						or (type(options) == "table" and (options.Silent == nil or type(options.Silent) == "boolean")),
					"SetOrder options need a boolean Silent"
				)
				local nextOrder = self:_reconcile(order, true)
				if same(nextOrder, self.order) then
					return
				end
				self.silent = options and options.Silent == true
				self.ctx.store:set(self.id, nextOrder)
				self.silent = false
			end

			function PrioritySelector:Move(itemId: string, targetIndex: number)
				assert(self.byId[itemId], "Unknown item Id")
				assert(
					type(targetIndex) == "number"
						and targetIndex % 1 == 0
						and targetIndex >= 1
						and targetIndex <= #self.order,
					"Target position is out of range"
				)
				local order = self:GetOrder()
				local from = table.find(order, itemId)
				if from == targetIndex then
					return
				end
				table.remove(order, from)
				table.insert(order, targetIndex, itemId)
				self:SetOrder(order)
			end

			function PrioritySelector:SetItems(items: { Item | string })
				local list, byId = itemsOf(items)
				local selected = self.selectedItemId
				self:_dismiss(false)
				self.items, self.byId = list, byId
				local order = self:_reconcile(self.order, false)
				if not self:_buildItems() then return end
				self:SetOrder(order)
				if selected and byId[selected] and not self.destroyed then
					self:_select(selected)
				end
			end

			function PrioritySelector:SetVisible(visible)
				if not visible then
					self:_dismiss(false)
				end
				Control.SetVisible(self, visible)
			end

			function PrioritySelector:SetDisabled(disabled)
				if disabled then
					self:_dismiss(false)
				end
				Control.SetDisabled(self, disabled)
				self:_render()
			end

			function PrioritySelector:Destroy()
				if self.destroyed then
					return
				end
				self:_dismiss(false)
				Control.Destroy(self)
			end

			function PrioritySelector:stateText(): string
				local labels = {}
				for _, id in self.order do
					if self.byId[id] then
						table.insert(labels, self.byId[id].Label)
					end
				end
				return table.concat(labels, ", ")
			end

			PrioritySelector.GetValue = PrioritySelector.GetOrder
			PrioritySelector.SetValue = PrioritySelector.SetOrder

			return PrioritySelector
		end

		-- Components/Slider
		loaders[nodes["Components/Slider"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Input = require(Core.Input)
			local Util = require(Core.Util)
			local Control = require(script.Parent.Control)

			local TRACK_WIDTH = 150

			local Slider = Control.extend("Slider")

			function Slider.new(ctx, parent, options)
				local min, max = options.Min or 0, options.Max or 100
				assert(max > min, "Slider Max must be greater than Min")
				local step = options.Step or 1
				local suffix = options.Suffix or ""

				local self = setmetatable(Control.new(ctx, parent, options), Slider)
				self.min, self.max, self.step = min, max, step

				local value = Factory.text({
					Name = "Value",
					TextXAlignment = Enum.TextXAlignment.Right,
					Size = UDim2.fromOffset(44, 20),
					LayoutOrder = 1,
					Parent = self.widget,
					Theme = { TextColor3 = "TextSecondary" },
				})

				local hit = Factory.button({
					Name = "Track",
					Size = UDim2.fromOffset(TRACK_WIDTH, 20),
					LayoutOrder = 2,
					Parent = self.widget,
				})

				local rail = Factory.new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.new(1, 0, 0, 4),
					Parent = hit,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(2) })

				local fill = Factory.new("Frame", {
					Size = UDim2.fromScale(0, 1),
					Parent = rail,
					Theme = { BackgroundColor3 = options.Color or "Accent" },
				}, { Factory.corner(2) })

				local thumb = Factory.new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromOffset(14, 14),
					Parent = hit,
					Theme = { BackgroundColor3 = "Knob" },
				}, { Factory.corner(7), Factory.stroke("Border", 0.3) })

				local dragging = false
				local function render(v: number)
					local alpha = (v - min) / (max - min)
					local duration = if dragging then 0 else Theme.Motion.Toggle
					Animations.tween(fill, { Size = UDim2.fromScale(alpha, 1) }, duration)
					Animations.tween(thumb, { Position = UDim2.fromScale(alpha, 0.5) }, duration)
					value.Text = Util.format(v, step) .. suffix
				end

				self:bind(Util.snap(options.Default or min, min, max, step), render)

				local function fromPoint(point: Vector2)
					local alpha = math.clamp((point.X - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1)
					self:SetValue(min + alpha * (max - min))
				end

				self.cleanup:connect(hit.InputBegan, function(input)
					if self.disabled or not Input.isPointer(input) then
						return
					end
					if self.stopDrag then
						self.stopDrag()
					end
					dragging = true
					Animations.tween(thumb, { Size = UDim2.fromOffset(16, 16) }, Theme.Motion.Hover)
					self.stopDrag = Input.drag(input, fromPoint, function()
						dragging = false
						Animations.tween(thumb, { Size = UDim2.fromOffset(14, 14) }, Theme.Motion.Hover)
					end)
				end)
				self.cleanup:add(function()
					if self.stopDrag then
						self.stopDrag()
					end
				end)

				self:register("slider number")
				return self
			end

			function Slider:normalize(value)
				return Util.snap(tonumber(value) or self.min, self.min, self.max, self.step)
			end

			function Slider:stateText()
				return Util.format(self:GetValue(), self.step) .. (self.options.Suffix or "")
			end

			return Slider
		end

		-- Components/Toggle
		loaders[nodes["Components/Toggle"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Control = require(script.Parent.Control)

			local WIDTH, HEIGHT, KNOB = 34, 20, 16

			local Toggle = Control.extend("Toggle")

			-- Bare switch, reused by card headers. Returns the button and a render(on) function.
			function Toggle.switch(colors: { On: any?, Off: any? }?)
				local onToken = colors and colors.On or "Accent"
				local offToken = colors and colors.Off or "SurfaceActive"

				local track = Factory.button({
					Name = "Switch",
					Size = UDim2.fromOffset(WIDTH, HEIGHT),
					BackgroundTransparency = 0,
					Theme = { BackgroundColor3 = offToken },
				}, { Factory.corner(HEIGHT // 2) })

				local knob = Factory.new("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 2, 0.5, 0),
					Size = UDim2.fromOffset(KNOB, KNOB),
					Parent = track,
					Theme = { BackgroundColor3 = "Knob" },
				}, { Factory.corner(KNOB // 2) })

				local first = true
				local function render(on: boolean)
					local duration = if first then 0 else Theme.Motion.Toggle
					first = false
					local old = track.BackgroundColor3
					Theme.bind(track, { BackgroundColor3 = if on then onToken else offToken })
					local target = track.BackgroundColor3
					track.BackgroundColor3 = old
					Animations.tween(track, { BackgroundColor3 = target }, duration)
					Animations.tween(knob, {
						Position = if on then UDim2.new(1, -KNOB - 2, 0.5, 0) else UDim2.new(0, 2, 0.5, 0),
					}, duration, Enum.EasingStyle.Quart)
				end
				return track, render
			end

			function Toggle.new(ctx, parent, options)
				local self = setmetatable(Control.new(ctx, parent, options), Toggle)

				local track, render = Toggle.switch({ On = options.OnColor, Off = options.OffColor })
				track.Parent = self.widget
				self.track = track

				self:bind(options.Default == true, render)
				self.cleanup:connect(track.Activated, function()
					if not self.disabled then
						self:SetValue(not self:GetValue())
					end
				end)

				self:register("toggle switch")
				return self
			end

			function Toggle:normalize(value)
				return value == true
			end

			function Toggle:stateText()
				return if self:GetValue() then "On" else "Off"
			end

			return Toggle
		end

		-- Components/Traits
		loaders[nodes["Components/Traits"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Factory = require(Core.Factory)
			local Theme = require(Core.Theme)
			local Animations = require(Core.Animations)
			local Icons = require(Core.Icons)
			local Store = require(Core.Store)
			local Util = require(Core.Util)
			local Control = require(script.Parent.Control)
			local Toggle = require(script.Parent.Toggle)
			local Dropdown = require(script.Parent.Dropdown)

			local Traits = Control.extend("Traits")

			local function unitData(unit)
				if unit == nil then
					return nil
				end
				assert(type(unit) == "table", "SelectedUnit must be a table")
				for _, key in { "UnitId", "Name" } do
					assert(type(unit[key]) == "string" and unit[key]:match("%S"), `{key} must be a non-empty string`)
				end
				for _, key in { "CurrentTrait", "Rarity" } do
					assert(unit[key] == nil or type(unit[key]) == "string", `{key} must be a string`)
				end
				local count = unit.RerollCount
				assert(
					count == nil
						or type(count) == "number" and count >= 0 and count <= 9007199254740991 and count % 1 == 0,
					"RerollCount must be a nonnegative finite integer"
				)
				local asset = unit.ImageAssetId
				if type(asset) == "number" then
					asset = if asset > 0
							and asset <= 9007199254740991
							and asset % 1 == 0
						then string.format("%.0f", asset)
						else nil
				end
				local digits = if type(asset) == "string"
					then asset:match("^rbxassetid://(%d+)$") or asset:match("^(%d+)$")
					else nil
				return {
					UnitId = unit.UnitId,
					Name = unit.Name,
					RerollCount = count,
					CurrentTrait = unit.CurrentTrait,
					Rarity = unit.Rarity,
					ImageAssetId = if digits and digits:match("[1-9]") then "rbxassetid://" .. digits else nil,
				}
			end

			local function choices(items, name)
				assert(type(items) == "table", `{name} must be an array`)
				local seen, count = {}, 0
				for key, item in items do
					count += 1
					assert(
						type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #items,
						`{name} must be a dense array`
					)
					assert(
						type(item) == "string" and item:match("%S") and not seen[item],
						`{name} must contain unique non-empty strings`
					)
					seen[item] = true
				end
				assert(count == #items, `{name} must be a dense array`)
				return table.clone(items)
			end

			function Traits.new(ctx, parent, options)
				options = table.clone(options or {})
				local unit = unitData(options.SelectedUnit)
				local targets = choices(options.TargetTraits or {}, "TargetTraits")
				local tokens = choices(options.RerollTokens or {}, "RerollTokens")
				for _, key in { "OnRoll", "OnAutoRollChanged", "OnSettingsChanged" } do
					assert(options[key] == nil or type(options[key]) == "function", `{key} must be a function`)
				end
				assert(options.AutoRoll == nil or type(options.AutoRoll) == "boolean", "AutoRoll must be a boolean")
				local self = setmetatable(Control.new(ctx, parent, { LayoutOrder = options.LayoutOrder }, true), Traits)
				self.options, self.revision, self.tweens, self.fields = options, 0, {}, {}
				self.Instance.Name = options.Id or "Traits"
				self.Instance:SetAttribute("NoWindowDrag", true)
				self.widget:FindFirstChildOfClass("UIListLayout").HorizontalAlignment = Enum.HorizontalAlignment.Center
				self.cleanup:add(function()
					for _, tween in self.tweens do
						tween:Cancel()
					end
					table.clear(self.tweens)
				end)
				self.body = Factory.new("Frame", {
					Name = "RerollStation",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = self.widget,
				}, { Factory.list(10), Factory.new("UISizeConstraint", { MaxSize = Vector2.new(760, math.huge) }) })
				local header = Factory.new(
					"Frame",
					{ Name = "Actions", Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = self.body }
				)
				self.header = header
				self.advancedButton = Factory.button({
					Name = "Advanced",
					Size = UDim2.fromOffset(96, 28),
					Parent = header,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(6) })
				self.advancedLabel = Factory.text({
					Text = "Advanced",
					Typography = "Description",
					Position = UDim2.fromOffset(8, 0),
					Size = UDim2.new(1, -28, 1, 0),
					Parent = self.advancedButton,
					Theme = { TextColor3 = "TextSecondary" },
				})
				self.chevron =
					Icons.create("down", 14, { Position = UDim2.fromOffset(76, 7), Parent = self.advancedButton })
				self:_buttonMotion(self.advancedButton, function(hovered, pressed)
					return { BackgroundTransparency = if pressed then 0.35 elseif hovered then 0.65 else 1 }
				end)
				local editCtx = setmetatable({ store = Store.new() }, { __index = ctx })
				self.autoToggle = self.cleanup:add(Toggle.new(editCtx, header, {
					Id = "AutoRoll",
					Title = "Auto Roll Trait",
					Default = options.AutoRoll == true,
					Searchable = false,
					Callback = function(enabled)
						self:SetAdvancedExpanded(enabled, true)
						Util.safeCall(options.OnAutoRollChanged, enabled, self:GetSettings())
					end,
				}))
				self.autoToggle.Instance.AutomaticSize = Enum.AutomaticSize.None
				self.autoToggle.Instance.AnchorPoint = Vector2.new(1, 0)
				self.autoToggle.Instance.Position, self.autoToggle.Instance.Size =
					UDim2.fromScale(1, 0), UDim2.fromOffset(174, 28)
				self.card = Factory.new("Frame", {
					Name = "SelectedUnit",
					LayoutOrder = 1,
					BackgroundTransparency = 0.04,
					Parent = self.body,
					Theme = { BackgroundColor3 = "Surface" },
				}, { Factory.corner(Theme.get("RadiusCard")), Factory.stroke("Border", 0.65) })
				self.portrait = Factory.new("Frame", {
					Name = "Portrait",
					BackgroundTransparency = 0.45,
					Parent = self.card,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(12) })
				self.fallback = Icons.create({ Icon = "person", Color = "TextMuted" }, 40, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = self.portrait,
				})
				self.image = Factory.new("ImageLabel", {
					Name = "UnitImage",
					BackgroundTransparency = 1,
					Image = "",
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(1, 1),
					Parent = self.portrait,
				}, { Factory.corner(12) })
				self.nameLabel = Factory.text({ Text = "", Typography = "Feature", Parent = self.card })
				self.traitLabel = Factory.text({
					Text = "",
					Typography = "Description",
					Parent = self.card,
					Theme = { TextColor3 = "TextSecondary" },
				})
				self.action =
					Factory.new("Frame", { Name = "RollAction", BackgroundTransparency = 1, Parent = self.card })
				self.countLabel = Factory.text({
					Text = "Current rerolls",
					Typography = "Description",
					Size = UDim2.new(1, 0, 0, 18),
					Parent = self.action,
					Theme = { TextColor3 = "TextSecondary" },
				})
				self.countValue = Factory.text({
					Text = "—",
					Typography = "WindowTitle",
					TextSize = 32,
					Position = UDim2.fromOffset(0, 22),
					Size = UDim2.new(1, 0, 0, 44),
					Parent = self.action,
				})
				self.rollButton = Factory.button({
					Name = "Roll",
					Position = UDim2.fromOffset(0, 84),
					Size = UDim2.new(1, 0, 0, 40),
					Parent = self.action,
					Theme = { BackgroundColor3 = "Accent" },
				}, { Factory.corner(Theme.get("RadiusControl")) })
				self.rollLabel = Factory.text({
					Text = "Roll",
					Typography = "Feature",
					Size = UDim2.fromScale(1, 1),
					TextXAlignment = Enum.TextXAlignment.Center,
					Parent = self.rollButton,
					Theme = { TextColor3 = "OnAccent" },
				})
				self.paintRoll = self:_buttonMotion(self.rollButton, function(hovered, pressed)
					return {
						BackgroundTransparency = if not self.rollButton.Interactable
							then 0.6
							elseif pressed then 0.3
							elseif hovered then 0.12
							else 0,
					}
				end)
				self.status = Factory.text({
					Text = "",
					Typography = "Description",
					Position = UDim2.fromOffset(0, 138),
					Size = UDim2.new(1, 0, 0, 44),
					TextWrapped = true,
					TextTruncate = Enum.TextTruncate.None,
					TextYAlignment = Enum.TextYAlignment.Top,
					Parent = self.action,
					Theme = { TextColor3 = "TextMuted" },
				})
				self.advanced = Factory.new("Frame", {
					Name = "Advanced",
					LayoutOrder = 2,
					Visible = false,
					Size = UDim2.new(1, 0, 0, 0),
					ClipsDescendants = true,
					BackgroundTransparency = 0.1,
					Parent = self.body,
					Theme = { BackgroundColor3 = "Surface" },
				}, { Factory.corner(Theme.get("RadiusCard")) })
				local advancedContent = Factory.new("Frame", {
					Name = "Options",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = self.advanced,
				}, { Factory.list(10), Factory.padding(12) })
				self.advancedLayout = advancedContent:FindFirstChildOfClass("UIListLayout")
				local function field(class, key, title, items, default)
					self.fields[key] = self.cleanup:add(class.new(editCtx, advancedContent, {
						Id = key,
						Title = title,
						Options = items,
						Multi = key == "TargetTraits",
						Default = default,
						_CompactGrid = class == Dropdown,
						Searchable = false,
						LayoutOrder = #advancedContent:GetChildren(),
						Callback = function()
							Util.safeCall(options.OnSettingsChanged, self:GetSettings())
						end,
					}))
				end
				if #targets > 0 then
					field(Dropdown, "TargetTraits", "Target traits", targets, {})
					field(Toggle, "StopOnTarget", "Stop on target", nil, true)
				end
				if #tokens > 0 then
					field(Dropdown, "RerollToken", "Reroll token", tokens)
					field(Toggle, "UseItem", "Use item", nil, false)
				end
				if next(self.fields) == nil then
					Factory.text({
						Text = "Supply TargetTraits or RerollTokens to configure Auto Roll.",
						Typography = "Description",
						TextWrapped = true,
						Size = UDim2.new(1, 0, 0, 36),
						Parent = advancedContent,
						Theme = { TextColor3 = "TextMuted" },
					})
				end
				self.cleanup:connect(self.advancedButton.Activated, function()
					if not self.disabled then
						self:SetAdvancedExpanded(not self.advancedExpanded, true)
					end
				end)
				self.cleanup:connect(self.rollButton.Activated, function()
					self:Roll()
				end)
				self.cleanup:connect(self.image:GetPropertyChangedSignal("IsLoaded"), function()
					self:_imageState()
				end)
				self.cleanup:connect(self.body:GetPropertyChangedSignal("AbsoluteSize"), function()
					if self.lastWidth ~= self.body.AbsoluteSize.X then
						self:_fit()
					end
				end)
				self.cleanup:connect(self.advancedLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					self:SetAdvancedExpanded(self.advancedExpanded == true)
				end)
				self.cleanup:add(Theme.onChanged(function()
					self:_render()
				end))
				self:SetUnit(unit)
				self:SetAdvancedExpanded(options.AutoRoll == true)
				self:_fit()
				return self
			end

			function Traits:_animate(inst, goal, duration)
				if self.tweens[inst] then
					self.tweens[inst]:Cancel()
				end
				self.tweens[inst] = Animations.tween(inst, goal, duration, Enum.EasingStyle.Quad)
			end

			function Traits:_buttonMotion(button, goal)
				local hovered = false
				local function paint(duration, pressed)
					self:_animate(button, goal(hovered, pressed), duration)
				end
				self.cleanup:connect(button.MouseEnter, function()
					hovered = true
					paint(0.12)
				end)
				self.cleanup:connect(button.MouseLeave, function()
					hovered = false
					paint(0.12)
				end)
				self.cleanup:connect(button:GetPropertyChangedSignal("GuiState"), function()
					paint(
						if button.GuiState == Enum.GuiState.Press then nil else 0.1,
						button.GuiState == Enum.GuiState.Press
					)
				end)
				return paint
			end

			function Traits:_imageState()
				self.fallback.Visible = self.image.Image == "" or not self.image.IsLoaded
			end

			function Traits:GetSelectedUnit()
				return if self.unit then table.clone(self.unit) else nil
			end

			function Traits:SetUnit(unit)
				local value = unitData(unit)
				self.unit, self.revision = value, self.revision + 1
				self:_render()
				for _, label in { self.nameLabel, self.traitLabel, self.countValue } do
					if not Animations.reducedMotion then
						label.TextTransparency = 0.35
					end
					self:_animate(label, { TextTransparency = 0 }, 0.18)
				end
			end

			function Traits:GetSettings()
				local settings = { AutoRoll = self.autoToggle:GetValue() }
				for key, field in self.fields do
					local value = field:GetValue()
					settings[key] = if type(value) == "table" then table.clone(value) else value
				end
				return settings
			end

			function Traits:SetAutoRoll(enabled)
				assert(type(enabled) == "boolean", "AutoRoll must be a boolean")
				self.autoToggle:SetValue(enabled)
			end

			function Traits:SetAdvancedExpanded(expanded, animate)
				self.advancedExpanded = expanded == true
				self.advanced.Visible = self.advancedExpanded
				local height = if self.advancedExpanded
					then math.ceil(self.advancedLayout.AbsoluteContentSize.Y / self.ctx.scale()) + 24
					else 0
				if animate and self.advancedExpanded then
					self.advanced.Size = UDim2.new(1, 0, 0, 0)
				end
				self:_animate(self.advanced, { Size = UDim2.new(1, 0, 0, height) }, if animate then 0.18 else nil)
				self:_animate(
					self.chevron,
					{ Rotation = if self.advancedExpanded then 180 else 0 },
					if animate then 0.18 else nil
				)
				if not self.advancedExpanded then
					for _, field in self.fields do
						if field.Close then
							field:Close()
						end
					end
				end
			end

			function Traits:_render()
				local unit = self.unit
				self.nameLabel.Text = if unit then unit.Name else "Select a unit"
				self.traitLabel.Text = if unit
					then (unit.CurrentTrait or "No trait") .. (if unit.Rarity then ` · {unit.Rarity}` else "")
					else "Choose a unit in your game."
				self.countValue.Text = if unit and unit.RerollCount ~= nil then tostring(unit.RerollCount) else "—"
				self.image.Image = if unit then unit.ImageAssetId or "" else ""
				self:_imageState()
				self.rollButton.Interactable = not self.disabled
					and not self.busy
					and unit ~= nil
					and (unit.RerollCount or 0) > 0
					and self.options.OnRoll ~= nil
				Theme.bind(
					self.rollButton,
					{ BackgroundColor3 = if self.rollButton.Interactable then "Accent" else "SurfaceActive" }
				)
				Theme.bind(
					self.rollLabel,
					{ TextColor3 = if self.rollButton.Interactable then "OnAccent" else "TextMuted" }
				)
				self.rollLabel.Text = if self.busy then "Rolling…" else "Roll"
				self.paintRoll()
				self.status.Text = if self.busy
					then "Waiting for game response."
					elseif not unit then "Select a unit to roll."
					elseif unit.RerollCount == nil then "Reroll count unavailable."
					elseif unit.RerollCount == 0 then "No rerolls available."
					elseif not self.options.OnRoll then "Preview only. Connect OnRoll to enable rolling."
					else ""
			end

			function Traits:Roll()
				if not self.rollButton.Interactable then
					return
				end
				local revision, unit, settings = self.revision, self:GetSelectedUnit(), self:GetSettings()
				self.busy = true
				self:_render()
				task.spawn(function()
					if self.destroyed then
						return
					end
					local ok, result, message = pcall(self.options.OnRoll, unit, settings)
					if self.destroyed then
						return
					end
					self.busy = false
					self:_render()
					if self.revision ~= revision then
						return
					end
					if ok and type(result) == "table" then
						ok, message = pcall(function()
							assert(result.UnitId == unit.UnitId, "Roll result must belong to the selected unit")
							self:SetUnit(result)
						end)
						if not ok then
							self.status.Text = "Invalid roll response."
						end
					else
						self.status.Text = if not ok
							then "Roll request failed."
							elseif result == false then tostring(message or "Roll declined.")
							else "Roll request sent."
					end
					if not ok then
						warn(`[MacUI Traits] Roll failed: {message or result}`)
					end
				end)
			end

			function Traits:SetDisabled(disabled)
				Control.SetDisabled(self, disabled)
				self.autoToggle:SetDisabled(disabled)
				for _, field in self.fields do
					field:SetDisabled(disabled)
				end
				self:_render()
			end

			function Traits:_fit()
				local width = math.floor(self.body.AbsoluteSize.X / self.ctx.scale())
				if width <= 0 then
					return
				end
				self.lastWidth = self.body.AbsoluteSize.X
				local compact = width < 480
				self.header.Size = UDim2.new(1, 0, 0, if width < 300 then 62 else 28)
				self.advancedButton.Position = UDim2.fromOffset(0, if width < 300 then 34 else 0)
				local imageSize = if compact then 104 else 144
				local leftWidth = if compact then width - 40 else math.floor(width * 0.5) - 40
				local imageX = if compact then math.floor((width - imageSize) / 2) else 24
				self.card.Size = UDim2.new(1, 0, 0, if compact then 352 else 252)
				self.portrait.Position, self.portrait.Size =
					UDim2.fromOffset(imageX, if compact then 16 else 24), UDim2.fromOffset(imageSize, imageSize)
				self.nameLabel.Position = UDim2.fromOffset(if compact then 20 else 24, if compact then 132 else 180)
				self.nameLabel.Size = UDim2.fromOffset(leftWidth, 22)
				self.traitLabel.Position = UDim2.fromOffset(if compact then 20 else 24, if compact then 156 else 206)
				self.traitLabel.Size = UDim2.fromOffset(leftWidth, 18)
				self.action.Position =
					UDim2.fromOffset(if compact then 20 else math.floor(width * 0.5), if compact then 188 else 36)
				self.action.Size =
					UDim2.new(if compact then 1 else 0.5, if compact then -40 else -24, 0, if compact then 148 else 192)
				self.countValue.Position = UDim2.fromOffset(0, if compact then 18 else 22)
				self.rollButton.Position = UDim2.fromOffset(0, if compact then 62 else 84)
				self.status.Position = UDim2.fromOffset(0, if compact then 108 else 138)
				self.status.Size = UDim2.new(1, 0, 0, if compact then 36 else 44)
				for _, label in { self.nameLabel, self.traitLabel, self.countLabel, self.countValue, self.status } do
					label.TextXAlignment = if compact then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
				end
			end

			return Traits
		end

		-- Components/UpdateLog
		loaders[nodes["Components/UpdateLog"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Cleanup = require(Core.Cleanup)
			local Control = require(script.Parent.Control)
			local Icons = require(Core.Icons)

			local UpdateLog = Control.extend("UpdateLog")
			local STATUS = {
				added = { "Added", "+", "UpdateAdded" },
				fixed = { "Fixed", "~", "UpdateFixed" },
				removed = { "Removed", "−", "UpdateRemoved" },
			}

			export type Entry = { Id: number, Type: string, Text: string }
			export type Options = {
				Id: string?,
				Title: string?,
				Version: string?,
				Date: string?,
				InitialVisibleCount: number?,
				Expandable: boolean?,
				LayoutOrder: number?,
			}

			local function optionalText(value, name)
				assert(value == nil or type(value) == "string", `{name} must be a string`)
			end

			function UpdateLog.new(ctx, parent, options: Options)
				options = table.clone(options or {})
				optionalText(options.Title, "Title")
				optionalText(options.Version, "Version")
				optionalText(options.Date, "Date")
				optionalText(options.Id, "Id")
				local limit = if options.InitialVisibleCount == nil then 5 else options.InitialVisibleCount
				assert(
					type(limit) == "number" and limit % 1 == 0 and limit >= 1 and limit < math.huge,
					"InitialVisibleCount must be a positive integer"
				)
				assert(
					options.Expandable == nil or type(options.Expandable) == "boolean",
					"Expandable must be a boolean"
				)
				local self =
					setmetatable(Control.new(ctx, parent, { LayoutOrder = options.LayoutOrder }, true), UpdateLog)
				self.options, self.limit = options, limit
				self.entries, self.rows, self.sequence = {}, {}, 0
				self.expanded = false
				self.rowCleanup = self.cleanup:add(Cleanup.new())
				self.Instance.Name = options.Id or "UpdateLog"
				self.Instance:SetAttribute("NoWindowDrag", true)
				local gap = Theme.get("SpacingSmall")
				self.widget:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, gap)
				local header = Factory.new("Frame", {
					Name = "Header",
					Size = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					LayoutOrder = 1,
					Parent = self.widget,
				}, { Factory.list(gap, true) })
				self.titleLabel = Factory.text({
					Text = options.Title or "Update Logs",
					Typography = "Section",
					Size = UDim2.fromScale(0, 1),
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = 1,
					Parent = header,
				}, { Factory.new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink }) })
				self.countLabel = Factory.text({
					Name = "Count",
					Typography = "Hint",
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					TextTruncate = Enum.TextTruncate.None,
					BackgroundTransparency = 0.4,
					LayoutOrder = 2,
					Parent = header,
					Theme = { TextColor3 = "TextSecondary", BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(5), Factory.padding(0, 5) })
				Factory.new("Frame", {
					Size = UDim2.fromScale(0, 1),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Parent = header,
				}, { Factory.fill() })
				self.metadata = Factory.text({
					Name = "Metadata",
					Typography = "Hint",
					Size = UDim2.fromScale(0, 1),
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = 4,
					Parent = header,
					Theme = { TextColor3 = "TextMuted" },
				}, { Factory.new("UISizeConstraint", { MaxSize = Vector2.new(150, math.huge) }) })
				self.expandButton = Factory.button({
					Name = "ExpandUpdates",
					Size = UDim2.fromOffset(76, 28),
					LayoutOrder = 5,
					Selectable = true,
					Parent = header,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, { Factory.corner(Theme.get("RadiusControl") - 1) })
				self.expandLabel = Factory.text({
					Text = "View all",
					Typography = "Hint",
					Size = UDim2.new(1, -16, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					Parent = self.expandButton,
					Theme = { TextColor3 = "TextSecondary" },
				})
				Icons.create({ Icon = "chevron-small-right", Color = "TextMuted" }, 12, {
					Name = "Chevron",
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Parent = self.expandButton,
				})
				self.cleanup:connect(self.expandButton.Activated, function()
					if not self.disabled then
						self:SetExpanded(not self.expanded)
					end
				end)
				self.cleanup:connect(self.expandButton.MouseEnter, function()
					if not self.disabled then
						self.expandButton.BackgroundTransparency = 0
					end
				end)
				self.cleanup:connect(self.expandButton.MouseLeave, function()
					self.expandButton.BackgroundTransparency = 1
				end)
				Factory.new("Frame", {
					Name = "HeaderDivider",
					Size = UDim2.new(1, 0, 0, 1),
					BackgroundTransparency = 0.6,
					LayoutOrder = 2,
					Parent = self.widget,
					Theme = { BackgroundColor3 = "Border" },
				})
				self.list = Factory.new("Frame", {
					Name = "Entries",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Parent = self.widget,
				}, { Factory.list(0) })
				self.empty = Factory.text({
					Text = "No updates yet.",
					Typography = "Description",
					Size = UDim2.new(1, 0, 0, 34),
					Parent = self.list,
					Theme = { TextColor3 = "TextMuted" },
				})
				self:_refresh()
				return self
			end

			function UpdateLog:_refresh()
				local count = #self.entries
				for index, row in self.rows do
					row.Visible = self.expanded or index <= self.limit
				end
				self.empty.Visible = count == 0
				self.expandButton.Visible = self.options.Expandable ~= false and count > self.limit
				self.expandLabel.Text = if self.expanded then "Show less" else "View all"
				self.countLabel.Text = tostring(count)
				self.countLabel.Visible = count > 0
				local metadata = {}
				for _, key in { "Version", "Date" } do
					if self.options[key] and self.options[key] ~= "" then
						table.insert(metadata, self.options[key])
					end
				end
				self.metadata.Text = table.concat(metadata, " · ")
				self.metadata.Visible = #metadata > 0
			end

			function UpdateLog:_row(parent, entry, cleanup)
				local status = STATUS[entry.Type]
				local row = cleanup:add(Factory.new("Frame", {
					Name = `Entry{entry.Id}`,
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundTransparency = 1,
					LayoutOrder = entry.Id,
					Parent = parent,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, {
					Factory.list(8, true),
					Factory.padding(6, 0),
				}))
				row:SetAttribute("EntryId", entry.Id)
				row:SetAttribute("Status", status[1])
				local marker = Factory.new("Frame", {
					Name = "Marker",
					Size = UDim2.fromOffset(22, 22),
					BackgroundTransparency = 0.9,
					LayoutOrder = 1,
					Parent = row,
					Theme = { BackgroundColor3 = status[3] },
				}, { Factory.corner(6) })
				Factory.text({
					Name = "Symbol",
					Text = status[2],
					Typography = "Control",
					Size = UDim2.fromScale(1, 1),
					TextXAlignment = Enum.TextXAlignment.Center,
					Parent = marker,
					Theme = { TextColor3 = status[3] },
				})
				Factory.text({
					Name = "Description",
					Text = entry.Text,
					Typography = "Control",
					Size = UDim2.fromScale(0, 1),
					TextWrapped = false,
					RichText = false,
					TextTruncate = Enum.TextTruncate.AtEnd,
					LayoutOrder = 2,
					Parent = row,
					Theme = { TextColor3 = "UpdateText" },
				}, { Factory.fill() })
				cleanup:connect(row.MouseEnter, function()
					row.BackgroundTransparency = 0.6
				end)
				cleanup:connect(row.MouseLeave, function()
					row.BackgroundTransparency = 1
				end)
				return row
			end

			function UpdateLog:AddEntry(kind: string, text: string): number
				assert(not self.destroyed, "UpdateLog is destroyed")
				assert(STATUS[kind], "Entry type must be added, fixed or removed")
				assert(type(text) == "string" and string.find(text, "%S"), "Entry text must be a non-empty string")
				self.sequence += 1
				local entry = { Id = self.sequence, Type = kind, Text = text }
				table.insert(self.entries, entry)
				table.insert(self.rows, self:_row(self.list, entry, self.rowCleanup))
				self:_refresh()
				if self.disabled then
					Control.SetDisabled(self, true)
				end
				return self.sequence
			end

			function UpdateLog:GetWriters()
				return function(text)
					return self:AddEntry("added", text)
				end, function(text)
					return self:AddEntry("fixed", text)
				end, function(text)
					return self:AddEntry("removed", text)
				end
			end

			function UpdateLog:GetEntries(): { Entry }
				local result = {}
				for _, entry in self.entries do
					table.insert(result, table.clone(entry))
				end
				return result
			end

			function UpdateLog:Clear()
				assert(not self.destroyed, "UpdateLog is destroyed")
				self:SetExpanded(false)
				self.rowCleanup:clean()
				table.clear(self.entries)
				table.clear(self.rows)
				self:_refresh()
			end

			function UpdateLog:SetVersion(version: string?)
				assert(not self.destroyed, "UpdateLog is destroyed")
				optionalText(version, "Version")
				self.options.Version = version
				self:_refresh()
			end

			function UpdateLog:SetExpanded(expanded: boolean)
				assert(not self.destroyed, "UpdateLog is destroyed")
				assert(type(expanded) == "boolean", "Expanded must be a boolean")
				if expanded and self.disabled then
					return
				end
				self.expanded = expanded
				self:_refresh()
			end

			function UpdateLog:IsExpanded(): boolean
				return self.expanded
			end

			function UpdateLog:SetTitle(title: string)
				assert(type(title) == "string", "Title must be a string")
				Control.SetTitle(self, title)
				self:_refresh()
			end

			return UpdateLog
		end

		-- Core/Animations
		loaders[nodes["Core/Animations"]] = function(script, require)
			local TweenService = game:GetService("TweenService")

			local Animations = { reducedMotion = false }

			local running = setmetatable({}, { __mode = "k" })

			local function cancel(inst: Instance, goal: { [string]: any })
				local props = running[inst]
				if not props then
					return
				end
				for prop in goal do
					local tween = props[prop]
					if tween then
						tween:Cancel()
						props[prop] = nil
					end
				end
			end

			function Animations.tween(
				inst: Instance,
				goal: { [string]: any },
				duration: number?,
				style: Enum.EasingStyle?
			): Tween?
				cancel(inst, goal)
				if Animations.reducedMotion or not duration or duration <= 0 then
					for prop, value in goal do
						inst[prop] = value
					end
					return nil
				end

				local tween = TweenService:Create(
					inst,
					TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					goal
				)
				local props = running[inst] or {}
				running[inst] = props
				for prop in goal do
					props[prop] = tween
				end
				tween:Play()
				return tween
			end

			function Animations.spin(inst: GuiObject): () -> ()
				if Animations.reducedMotion then
					return function() end
				end
				inst.Rotation = 0
				local tween = TweenService:Create(
					inst,
					TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
					{ Rotation = 360 }
				)
				tween:Play()
				return function()
					tween:Cancel()
					inst.Rotation = 0
				end
			end

			return Animations
		end

		-- Core/Blur
		loaders[nodes["Core/Blur"]] = function(script, require)
			local Lighting = game:GetService("Lighting")

			local Animations = require(script.Parent.Animations)

			-- One shared BlurEffect for every window; each owner asks for a size and the largest wins.
			local NAME = "UILibraryBlur"

			local Blur = {}

			local owners = {}
			local effect: BlurEffect?
			local created = false
			local originalSize = 0
			local originalEnabled = false

			local function target(): number
				local size = if originalEnabled then originalSize else 0
				for _, s in owners do
					size = math.max(size, s)
				end
				return size
			end

			local function ensure(): BlurEffect
				if effect and effect.Parent then
					return effect
				end
				local found = Lighting:FindFirstChild(NAME)
				if found and found:IsA("BlurEffect") then
					effect = found
					created = false
					originalSize, originalEnabled = found.Size, found.Enabled
				else
					effect = Instance.new("BlurEffect")
					effect.Name = NAME
					effect.Size = 0
					effect.Parent = Lighting
					created = true
					originalSize, originalEnabled = 0, false
				end
				return effect :: BlurEffect
			end

			function Blur.set(owner: any, size: number, duration: number?)
				assert(
					type(size) == "number" and size == size and math.abs(size) < math.huge,
					"BlurSize must be a finite number"
				)
				local current = ensure()
				owners[owner] = math.clamp(size, 0, 56)
				current.Enabled = true
				Animations.tween(current, { Size = target() }, duration, Enum.EasingStyle.Quad)
			end

			function Blur.release(owner: any, duration: number?)
				if owners[owner] == nil and next(owners) ~= nil then
					return
				end
				owners[owner] = nil
				local current = effect
				if not current or not current.Parent then
					return
				end
				if next(owners) ~= nil then
					Animations.tween(current, { Size = target() }, duration, Enum.EasingStyle.Quad)
					return
				end
				local function done()
					if next(owners) == nil and effect == current then
						effect = nil
						if created then
							current:Destroy()
						else
							current.Size, current.Enabled = originalSize, originalEnabled
						end
					end
				end
				local tween = Animations.tween(
					current,
					{ Size = if originalEnabled then originalSize else 0 },
					duration,
					Enum.EasingStyle.Quad
				)
				if tween then
					tween.Completed:Once(function(state)
						if state == Enum.PlaybackState.Completed then
							done()
						end
					end)
				else
					done()
				end
			end

			function Blur.instanceCount(): number
				local count = 0
				for _, child in Lighting:GetChildren() do
					if child.Name == NAME then
						count += 1
					end
				end
				return count
			end

			return Blur
		end

		-- Core/Cleanup
		loaders[nodes["Core/Cleanup"]] = function(script, require)
			local Cleanup = {}
			Cleanup.__index = Cleanup

			export type Task = RBXScriptConnection | Instance | (() -> ()) | { Destroy: (any) -> () }

			function Cleanup.new()
				return setmetatable({ tasks = {} }, Cleanup)
			end

			function Cleanup:add(task)
				table.insert(self.tasks, task)
				return task
			end

			function Cleanup:connect(signal: RBXScriptSignal, fn: (...any) -> ()): RBXScriptConnection
				return self:add(signal:Connect(fn))
			end

			function Cleanup:count(): number
				return #self.tasks
			end

			function Cleanup:clean()
				local tasks = self.tasks
				for i = #tasks, 1, -1 do
					local task = tasks[i]
					tasks[i] = nil
					local kind = typeof(task)
					if kind == "RBXScriptConnection" then
						task:Disconnect()
					elseif kind == "Instance" then
						task:Destroy()
					elseif kind == "function" then
						task()
					elseif kind == "table" and task.Destroy then
						task:Destroy()
					end
				end
			end

			Cleanup.Destroy = Cleanup.clean

			return Cleanup
		end

		-- Core/Factory
		loaders[nodes["Core/Factory"]] = function(script, require)
			local Theme = require(script.Parent.Theme)

			local Factory = {}

			function Factory.new(className: string, props: { [string]: any }?, children: { Instance }?): any
				local inst = Instance.new(className)
				if inst:IsA("GuiObject") then
					inst.BorderSizePixel = 0
				end

				local parent
				for key, value in props or {} do
					if key == "Parent" then
						parent = value
					elseif key == "Theme" then
						Theme.bind(inst, value)
					else
						inst[key] = value
					end
				end

				for _, child in children or {} do
					child.Parent = inst
				end
				inst.Parent = parent
				return inst
			end

			function Factory.text(props: { [string]: any }, children: { Instance }?): any
				local typography = Theme.Typography[props.Typography or "Control"]
				assert(typography, `Unknown typography "{props.Typography}"`)
				local theme = { TextColor3 = "TextPrimary" }
				for key, value in props.Theme or {} do
					theme[key] = value
				end

				local merged = {
					BackgroundTransparency = 1,
					FontFace = typography.FontFace,
					TextSize = typography.TextSize,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextWrapped = false,
					TextTransparency = 0,
				}
				for key, value in props do
					if key ~= "ClassName" and key ~= "Typography" then
						merged[key] = value
					end
				end
				merged.Theme = theme
				merged.TextScaled = false
				merged.TextSize = math.max(1, math.round(merged.TextSize))

				return Factory.new(props.ClassName or "TextLabel", merged, children)
			end

			function Factory.button(props: { [string]: any }?, children: { Instance }?): TextButton
				local merged = { AutoButtonColor = false, Text = "", BackgroundTransparency = 1 }
				for key, value in props or {} do
					merged[key] = value
				end
				return Factory.new("TextButton", merged, children)
			end

			function Factory.corner(radius: number): UICorner
				return Factory.new("UICorner", { CornerRadius = UDim.new(0, radius) })
			end

			function Factory.stroke(token: any?, transparency: number?): UIStroke
				return Factory.new("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Thickness = 1,
					Transparency = transparency or 0,
					Theme = { Color = token or "Border" },
				})
			end

			function Factory.padding(top: number, right: number?, bottom: number?, left: number?): UIPadding
				right = right or top
				return Factory.new("UIPadding", {
					PaddingTop = UDim.new(0, top),
					PaddingRight = UDim.new(0, right),
					PaddingBottom = UDim.new(0, bottom or top),
					PaddingLeft = UDim.new(0, left or right),
				})
			end

			function Factory.list(gap: number?, horizontal: boolean?, props: { [string]: any }?): UIListLayout
				local merged = {
					Padding = UDim.new(0, gap or 0),
					FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = if horizontal
						then Enum.VerticalAlignment.Center
						else Enum.VerticalAlignment.Top,
				}
				for key, value in props or {} do
					merged[key] = value
				end
				return Factory.new("UIListLayout", merged)
			end

			function Factory.fill(): UIFlexItem
				return Factory.new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill })
			end

			return Factory
		end

		-- Core/Icons
		loaders[nodes["Core/Icons"]] = function(script, require)
			local Theme = require(script.Parent.Theme)
			local Factory = require(script.Parent.Factory)

			-- Builder Icons ships with every Roblox client; icons render as font ligatures.
			local FAMILY = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"

			local Icons = {}

			Icons.Font = {
				Regular = Font.new(FAMILY, Enum.FontWeight.Regular),
				Filled = Font.new(FAMILY, Enum.FontWeight.Bold),
			}

			Icons.Aliases = {
				settings = "gear",
				general = "gear",
				search = "magnifying-glass",
				home = "house",
				dashboard = "four-squares-grid",
				automation = "two-arrows-loop-clockwise",
				combat = "sword",
				movement = "person-running",
				visuals = "eye",
				misc = "three-dots-horizontal",
				back = "chevron-large-left",
				forward = "chevron-large-right",
				down = "chevron-small-down",
				right = "chevron-small-right",
				close = "x",
				add = "plus-small",
				remove = "minus",
				info = "circle-i",
				success = "circle-check",
				warning = "triangle-exclamation",
				error = "circle-x",
				reset = "arrow-rotate-right",
				delete = "trash-can",
				edit = "pencil",
				color = "paint-brush",
				keybind = "keyboard",
				sidebar = "sidebar",
				maximize = "dual-arrows-to-corners",
				minimize = "minus",
				check = "check-small",
				clear = "circle-x",
				workspace = "three-stacked-squares-tilted",
			}

			function Icons.name(icon: string): string
				local alias = Icons.Aliases[string.lower(icon)]
				if alias then
					return alias
				end
				if string.find(icon, "%u") then
					local kebab = string.gsub(icon, "(%l)(%u)", "%1-%2")
					kebab = string.gsub(kebab, "(%d)(%u)", "%1-%2")
					kebab = string.gsub(kebab, "_", "-")
					return string.lower(kebab)
				end
				return icon
			end

			function Icons.spec(icon: any): { [string]: any }
				if type(icon) == "table" then
					return icon
				end
				return { Icon = icon or "circle", Color = "TextSecondary" }
			end

			-- Sets an icon's tint whether it rendered as a font glyph or an image.
			function Icons.tint(inst: GuiObject, token: any)
				if inst:IsA("TextLabel") then
					Theme.bind(inst, { TextColor3 = token })
				elseif inst:IsA("ImageLabel") then
					Theme.bind(inst, { ImageColor3 = token })
				end
			end

			function Icons.isImage(icon: any): boolean
				return type(icon) == "string"
					and (
						string.find(icon, "^rbxasset") ~= nil
						or string.find(icon, "^rbxthumb") ~= nil
						or string.find(icon, "^http") ~= nil
					)
			end

			-- spec: "gear" | "rbxassetid://..." | { Icon = "gear", Color = Color3|token, Tile = Color3|token, Filled = bool }
			function Icons.create(spec: any, size: number, props: { [string]: any }?): GuiObject
				local options = if type(spec) == "table" then spec else { Icon = spec }
				local icon = options.Icon or options.Image
				local color = options.Color or "TextSecondary"

				local inst
				if Icons.isImage(icon) then
					inst = Factory.new("ImageLabel", {
						Size = UDim2.fromOffset(size, size),
						BackgroundTransparency = 1,
						Image = icon,
						ScaleType = Enum.ScaleType.Fit,
						Theme = if options.Tint then { ImageColor3 = color } else nil,
					})
				else
					inst = Factory.new("TextLabel", {
						Size = UDim2.fromOffset(size, size),
						BackgroundTransparency = 1,
						FontFace = if options.Filled then Icons.Font.Filled else Icons.Font.Regular,
						Text = Icons.name(icon or "circle"),
						TextSize = size,
						TextScaled = false,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
						Theme = { TextColor3 = color },
					})
				end

				if options.Tile then
					local tile = Factory.new("Frame", {
						Size = UDim2.fromOffset(size + 8, size + 8),
						Theme = { BackgroundColor3 = options.Tile },
					}, { Factory.corner(math.round((size + 8) * 0.26)) })
					inst.AnchorPoint = Vector2.new(0.5, 0.5)
					inst.Position = UDim2.fromScale(0.5, 0.5)
					if not options.Color then
						Theme.bind(
							inst,
							{ [if inst:IsA("TextLabel") then "TextColor3" else "ImageColor3"] = Color3.new(1, 1, 1) }
						)
					end
					inst.Parent = tile
					inst = tile
				end

				for key, value in props or {} do
					if key == "Parent" then
						continue
					end
					inst[key] = value
				end
				if props and props.Parent then
					inst.Parent = props.Parent
				end
				return inst
			end

			return Icons
		end

		-- Core/Input
		loaders[nodes["Core/Input"]] = function(script, require)
			local UserInputService = game:GetService("UserInputService")

			local Input = {}

			local NAMES = {
				LeftShift = "Left Shift",
				RightShift = "Right Shift",
				LeftControl = "Left Ctrl",
				RightControl = "Right Ctrl",
				LeftAlt = "Left Alt",
				RightAlt = "Right Alt",
				Return = "Enter",
				Backspace = "Backspace",
				Space = "Space",
				Escape = "Esc",
				Comma = ",",
				Period = ".",
				Slash = "/",
				Semicolon = ";",
				Quote = "'",
				LeftBracket = "[",
				RightBracket = "]",
				BackSlash = "\\",
				Minus = "-",
				Equals = "=",
				Backquote = "`",
				Up = "↑",
				Down = "↓",
				Left = "←",
				Right = "→",
				MouseButton1 = "Mouse 1",
				MouseButton2 = "Mouse 2",
				MouseButton3 = "Mouse 3",
			}

			for i = 0, 9 do
				local names = { "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine" }
				NAMES[names[i + 1]] = tostring(i)
			end

			function Input.keyName(key: EnumItem?): string
				if not key then
					return "None"
				end
				return NAMES[key.Name] or key.Name
			end

			function Input.ctrlDown(): boolean
				return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
					or UserInputService:IsKeyDown(Enum.KeyCode.LeftSuper)
					or UserInputService:IsKeyDown(Enum.KeyCode.RightSuper)
			end

			function Input.isPointer(input: InputObject): boolean
				return input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
			end

			function Input.isMove(input: InputObject): boolean
				return input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
			end

			-- InputObject.Position and AbsolutePosition already use screen pixels; do not add the inset twice.
			function Input.position(input: InputObject): Vector2
				return Vector2.new(input.Position.X, input.Position.Y)
			end

			function Input.inside(gui: GuiObject, point: Vector2): boolean
				local pos, size = gui.AbsolutePosition, gui.AbsoluteSize
				return point.X >= pos.X and point.X <= pos.X + size.X and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
			end

			-- Calls onMove(position) until the pointer is released. Returns a stop function.
			function Input.drag(start: InputObject, onMove: (Vector2) -> (), onEnd: (() -> ())?): () -> ()
				local moved, ended, unfocused
				local function stop()
					if moved then
						moved:Disconnect()
						ended:Disconnect()
						unfocused:Disconnect()
						moved = nil
						if onEnd then
							onEnd()
						end
					end
				end

				moved = UserInputService.InputChanged:Connect(function(input)
					if
						(start.UserInputType == Enum.UserInputType.Touch and input == start)
						or (
							start.UserInputType == Enum.UserInputType.MouseButton1
							and input.UserInputType == Enum.UserInputType.MouseMovement
						)
					then
						if input.UserInputState == Enum.UserInputState.Cancel then
							stop()
							return
						end
						onMove(Input.position(input))
					end
				end)
				ended = UserInputService.InputEnded:Connect(function(input)
					if
						input == start
						or (
							start.UserInputType ~= Enum.UserInputType.Touch
							and input.UserInputType == Enum.UserInputType.MouseButton1
						)
					then
						stop()
					end
				end)
				unfocused = UserInputService.WindowFocusReleased:Connect(stop)
				onMove(Input.position(start))
				return stop
			end

			-- One shared InputBegan connection; handlers run newest-first and may return true to consume.
			local handlers = {}
			local connection

			function Input.listen(fn: (InputObject, boolean) -> boolean?): () -> ()
				table.insert(handlers, fn)
				if not connection then
					connection = UserInputService.InputBegan:Connect(function(input, processed)
						for i = #handlers, 1, -1 do
							local handler = handlers[i]
							if handler and handler(input, processed) then
								return
							end
						end
					end)
				end
				return function()
					local index = table.find(handlers, fn)
					if index then
						table.remove(handlers, index)
					end
					if #handlers == 0 and connection then
						connection:Disconnect()
						connection = nil
					end
				end
			end

			function Input.handlerCount(): number
				return #handlers
			end

			return Input
		end

		-- Core/Registry
		loaders[nodes["Core/Registry"]] = function(script, require)
			local Registry = {}
			Registry.__index = Registry

			export type Entry = {
				id: string,
				kind: "page" | "card" | "control",
				title: string,
				subtitle: string?,
				keywords: string?,
				aliases: (string | { string })?,
				icon: any?,
				state: (() -> string?)?,
				shortcut: string?,
				activate: () -> (),
				visible: (() -> boolean)?,
			}

			function Registry.new()
				return setmetatable({ entries = {}, order = {}, counter = 0 }, Registry)
			end

			function Registry:add(entry: Entry): () -> ()
				assert(
					type(entry.id) == "string"
						and entry.id ~= ""
						and type(entry.title) == "string"
						and type(entry.activate) == "function",
					"Search entries need an id, title and activate callback"
				)
				self:remove(entry.id)
				self.counter += 1
				local record = {
					entry = entry,
					index = self.counter,
					title = string.lower(entry.title),
					haystack = "",
				}
				self.entries[entry.id] = record
				table.insert(self.order, record)
				self:update(entry.id, {})
				return function()
					if self.entries[entry.id] == record then
						self:remove(entry.id)
					end
				end
			end

			function Registry:remove(id: string)
				local record = self.entries[id]
				if record then
					self.entries[id] = nil
					local index = table.find(self.order, record)
					if index then
						table.remove(self.order, index)
					end
				end
			end

			function Registry:update(id: string, fields: { [string]: any })
				local record = self.entries[id]
				if not record then
					return
				end
				for key, value in fields do
					record.entry[key] = value
				end
				local entry = record.entry
				record.title = string.lower(entry.title)
				local aliases = if type(entry.aliases) == "table"
					then table.concat(entry.aliases, " ")
					else entry.aliases or ""
				record.haystack = string.lower(`{entry.title} {entry.subtitle or ""} {entry.keywords or ""} {aliases}`)
			end

			function Registry:get(id: string): Entry?
				local record = self.entries[id]
				return record and record.entry
			end

			function Registry:count(): number
				return #self.order
			end

			local KIND_BONUS = { page = 30, card = 20, control = 0 }

			local function score(record, terms: { string }): number?
				local total = KIND_BONUS[record.entry.kind] or 0
				local phrase = table.concat(terms, " ")
				if record.title == phrase then
					total += 1000
				elseif string.sub(record.title, 1, #phrase) == phrase then
					total += 500
				end
				for i, term in terms do
					local at = string.find(record.haystack, term, 1, true)
					if not at then
						return nil
					end
					if i == 1 and string.sub(record.title, 1, #term) == term then
						total += 100
					elseif string.find(record.title, " " .. term, 1, true) then
						total += 60
					elseif string.find(record.title, term, 1, true) then
						total += 40
					else
						total += 10
					end
				end
				return total - #record.title * 0.1
			end

			function Registry:search(query: string, limit: number?): { Entry }
				local terms = string.split(string.lower(query), " ")
				for i = #terms, 1, -1 do
					if terms[i] == "" then
						table.remove(terms, i)
					end
				end

				local hits = {}
				for _, record in self.order do
					local visible = record.entry.visible
					if visible and not visible() then
						continue
					end
					local value = if #terms == 0 then 0 else score(record, terms)
					if value then
						table.insert(hits, { record = record, score = value })
					end
				end

				table.sort(hits, function(a, b)
					if a.score ~= b.score then
						return a.score > b.score
					end
					return a.record.index < b.record.index
				end)

				local out = {}
				for i = 1, math.min(#hits, limit or 50) do
					out[i] = hits[i].record.entry
				end
				return out
			end

			return Registry
		end

		-- Core/Store
		loaders[nodes["Core/Store"]] = function(script, require)
			local Store = {}
			Store.__index = Store

			export type Adapter = {
				Load: (() -> { [string]: any }?)?,
				Save: (({ [string]: any }) -> ())?,
				Delay: number?,
			}

			local function encode(value: any): any
				local kind = typeof(value)
				if kind == "Color3" then
					return { __color = value:ToHex() }
				elseif kind == "EnumItem" then
					return { __enum = tostring(value.EnumType), name = value.Name }
				elseif kind == "table" then
					local out = {}
					for key, item in value do
						out[key] = encode(item)
					end
					return out
				end
				return value
			end

			local function decode(value: any): any
				if type(value) ~= "table" then
					return value
				end
				if value.__color then
					local ok, color = pcall(Color3.fromHex, value.__color)
					return if ok then color else nil
				end
				if value.__enum then
					local ok, item = pcall(function()
						return Enum[value.__enum][value.name]
					end)
					return if ok then item else nil
				end
				local out = {}
				for key, item in value do
					out[key] = decode(item)
				end
				return out
			end

			Store.encode = encode
			Store.decode = decode

			function Store.new(adapter: Adapter?)
				local self = setmetatable({
					values = {},
					listeners = {},
					saved = {},
					defined = {},
					normalizers = {},
					adapter = adapter,
					auto = 0,
				}, Store)
				if adapter and adapter.Load then
					local ok, data = pcall(adapter.Load)
					if ok and type(data) == "table" then
						self.saved = data
					elseif not ok then
						warn(`[MacUI] settings failed to load: {data}`)
					end
				end
				return self
			end

			function Store:define(id: string?, default: any, normalize: ((any) -> any)?): (string, any)
				if id == nil then
					repeat
						self.auto += 1
						id = `_auto{self.auto}`
					until not self.defined[id]
				end
				assert(type(id) == "string" and id ~= "", "Flag Id must be a non-empty string")
				assert(not self.defined[id], `Flag id "{id}" already exists in this window`)

				local value = default
				local raw = self.saved[id]
				if raw ~= nil then
					local decoded = decode(raw)
					if decoded ~= nil and typeof(decoded) == typeof(default) then
						value = decoded
					end
				end
				if normalize then
					value = normalize(value)
				end
				self.defined[id] = true
				self.normalizers[id] = normalize
				self.values[id] = value
				return id, value
			end

			function Store:get(id: string): any
				return self.values[id]
			end

			function Store:set(id: string, value: any): boolean
				if self.normalizers[id] then
					value = self.normalizers[id](value)
				end
				local old = self.values[id]
				if old == value and type(value) ~= "table" then
					return false
				end
				self.values[id] = value
				local list = self.listeners[id]
				if list then
					for _, fn in table.clone(list) do
						fn(value, old)
					end
				end
				self:_queueSave()
				return true
			end

			function Store:observe(id: string, fn: (any, any) -> ()): () -> ()
				local list = self.listeners[id]
				if not list then
					list = {}
					self.listeners[id] = list
				end
				table.insert(list, fn)
				return function()
					local index = table.find(list, fn)
					if index then
						table.remove(list, index)
					end
				end
			end

			-- Drops the value only; other subscribers (e.g. Window:OnFlagChanged) keep their listeners.
			function Store:remove(id: string)
				self.values[id] = nil
				self.defined[id] = nil
				self.normalizers[id] = nil
			end

			function Store:snapshot(): { [string]: any }
				local out = {}
				for id, value in self.values do
					if string.sub(id, 1, 1) ~= "_" then
						out[id] = encode(value)
					end
				end
				return out
			end

			function Store:_queueSave()
				local adapter = self.adapter
				if not (adapter and adapter.Save) or self.pending then
					return
				end
				self.pending = true
				task.delay(adapter.Delay or 2, function()
					self.pending = false
					local ok, err = pcall(adapter.Save, self:snapshot())
					if not ok then
						warn(`[MacUI] settings failed to save: {err}`)
					end
				end)
			end

			return Store
		end

		-- Core/Theme
		loaders[nodes["Core/Theme"]] = function(script, require)
			local FAMILY = "rbxasset://fonts/families/Roboto.json"

			local Theme = {}

			Theme.Fonts = {
				Regular = Font.new(FAMILY, Enum.FontWeight.Regular),
				Medium = Font.new(FAMILY, Enum.FontWeight.Medium),
				-- ponytail: bundled Roboto resolves 600 to a nearby face; upload a family for exact SemiBold.
				SemiBold = Font.new(FAMILY, Enum.FontWeight.SemiBold),
			}

			Theme.TextSize = { Body = 13, Small = 12, Title = 18, Section = 13 }

			Theme.Typography = {
				WindowTitle = { FontFace = Theme.Fonts.SemiBold, TextSize = 18 },
				Navigation = { FontFace = Theme.Fonts.Medium, TextSize = 14 },
				Feature = { FontFace = Theme.Fonts.Medium, TextSize = 14 },
				Section = { FontFace = Theme.Fonts.Medium, TextSize = 13 },
				Control = { FontFace = Theme.Fonts.Regular, TextSize = 13 },
				Description = { FontFace = Theme.Fonts.Regular, TextSize = 12 },
				Hint = { FontFace = Theme.Fonts.Medium, TextSize = 11 },
				Search = { FontFace = Theme.Fonts.Regular, TextSize = 14 },
			}

			Theme.Motion = {
				Hover = 0.12,
				Select = 0.15,
				Page = 0.22,
				Toggle = 0.18,
				Expand = 0.2,
				Dropdown = 0.15,
				Popup = 0.18,
				Notify = 0.22,
				Minimize = 0.25,
			}

			local Dark = {
				Background = Color3.fromRGB(16, 16, 18),
				Sidebar = Color3.fromRGB(29, 29, 31),
				Surface = Color3.fromRGB(25, 25, 27),
				SurfaceHover = Color3.fromRGB(39, 39, 41),
				SurfaceActive = Color3.fromRGB(51, 51, 53),
				Border = Color3.fromRGB(60, 60, 64),
				Shadow = Color3.fromRGB(0, 0, 0),
				Sheen = Color3.fromRGB(255, 255, 255),

				TextPrimary = Color3.fromRGB(245, 245, 247),
				TextSecondary = Color3.fromRGB(178, 178, 184),
				TextMuted = Color3.fromRGB(143, 143, 151),
				TextDisabled = Color3.fromRGB(111, 111, 119),

				Accent = Color3.fromRGB(110, 168, 255),
				Success = Color3.fromRGB(48, 209, 88),
				Warning = Color3.fromRGB(255, 159, 10),
				Danger = Color3.fromRGB(255, 69, 58),
				UpdateAdded = Color3.fromRGB(96, 202, 139),
				UpdateFixed = Color3.fromRGB(239, 164, 94),
				UpdateRemoved = Color3.fromRGB(240, 120, 121),
				UpdateText = Color3.fromRGB(219, 219, 224),
				CraftingReady = Color3.fromRGB(123, 181, 145),
				CraftingMissing = Color3.fromRGB(205, 162, 106),

				Palette = Color3.fromRGB(27, 27, 29),
				PaletteBorder = Color3.fromRGB(69, 69, 72),
				PaletteSelected = Color3.fromRGB(50, 50, 53),
				PaletteDivider = Color3.fromRGB(54, 54, 56),
				PalettePlaceholder = Color3.fromRGB(146, 146, 151),
				Knob = Color3.fromRGB(255, 255, 255),
				OnAccent = Color3.fromRGB(255, 255, 255),
				Scrim = Color3.fromRGB(0, 0, 0),

				RadiusWindow = 22,
				RadiusCard = 12,
				RadiusControl = 9,

				SpacingSmall = 6,
				SpacingMedium = 12,
				SpacingLarge = 18,
			}

			local Light = setmetatable({
				Background = Color3.fromRGB(246, 246, 247),
				Sidebar = Color3.fromRGB(236, 236, 238),
				Surface = Color3.fromRGB(255, 255, 255),
				SurfaceHover = Color3.fromRGB(240, 240, 242),
				SurfaceActive = Color3.fromRGB(226, 226, 229),
				Border = Color3.fromRGB(212, 212, 216),

				TextPrimary = Color3.fromRGB(28, 28, 30),
				TextSecondary = Color3.fromRGB(99, 99, 104),
				TextMuted = Color3.fromRGB(142, 142, 147),
				TextDisabled = Color3.fromRGB(142, 142, 147),

				Accent = Color3.fromRGB(0, 122, 255),
				Success = Color3.fromRGB(40, 167, 69),
				Warning = Color3.fromRGB(230, 140, 0),
				Danger = Color3.fromRGB(230, 57, 47),
				UpdateAdded = Color3.fromRGB(28, 121, 72),
				UpdateFixed = Color3.fromRGB(155, 79, 24),
				UpdateRemoved = Color3.fromRGB(183, 45, 45),
				UpdateText = Color3.fromRGB(28, 28, 30),
				CraftingReady = Color3.fromRGB(45, 125, 75),
				CraftingMissing = Color3.fromRGB(143, 95, 34),

				Palette = Color3.fromRGB(252, 252, 253),
				PaletteBorder = Color3.fromRGB(208, 208, 212),
				PaletteSelected = Color3.fromRGB(230, 230, 233),
				PaletteDivider = Color3.fromRGB(212, 212, 216),
				PalettePlaceholder = Color3.fromRGB(115, 115, 122),
			}, { __index = Dark })

			Theme.Presets = { Dark = Dark, Light = Light }
			Theme.name = "Dark"

			local current = Dark
			local bindings = {}
			local listeners = {}
			local disabledText = setmetatable({}, { __mode = "k" })

			local function resolve(token)
				if type(token) == "function" then
					token = token()
				end
				if typeof(token) == "Color3" then
					return token
				end
				return current[token]
			end

			local function apply(inst, prop, token)
				inst[prop] = if prop == "TextColor3" and disabledText[inst]
					then current.TextDisabled
					else resolve(token)
			end

			function Theme.get(token: string): any
				return current[token]
			end

			-- map: { Property = "Token" | () -> "Token" | Color3 }
			function Theme.bind(inst: Instance, map: { [string]: any })
				local existing = bindings[inst]
				if not existing then
					existing = {}
					bindings[inst] = existing
					inst.Destroying:Once(function()
						bindings[inst] = nil
					end)
				end
				for prop, token in map do
					existing[prop] = token
					apply(inst, prop, token)
				end
			end

			-- Keep the original color binding so enabling restores semantic/custom colors.
			function Theme.setTextDisabled(inst: TextLabel | TextButton | TextBox, disabled: boolean)
				if not bindings[inst] or bindings[inst].TextColor3 == nil then
					Theme.bind(inst, { TextColor3 = inst.TextColor3 })
				end
				disabledText[inst] = disabled or nil
				inst.TextTransparency = 0
				apply(inst, "TextColor3", bindings[inst].TextColor3)
			end

			function Theme.resolve(inst: Instance, prop: string): any
				local map = bindings[inst]
				return map and map[prop] and resolve(map[prop])
			end

			function Theme.bindingCount(): number
				local count = 0
				for _ in bindings do
					count += 1
				end
				return count
			end

			function Theme.onChanged(fn: () -> ()): () -> ()
				table.insert(listeners, fn)
				return function()
					local index = table.find(listeners, fn)
					if index then
						table.remove(listeners, index)
					end
				end
			end

			function Theme.register(name: string, tokens: { [string]: any })
				Theme.Presets[name] = setmetatable(tokens, { __index = Dark })
			end

			function Theme.set(name: string)
				local preset = Theme.Presets[name]
				assert(preset, `Unknown theme "{name}"`)
				current = preset
				Theme.name = name
				for inst, map in bindings do
					for prop, token in map do
						apply(inst, prop, token)
					end
				end
				for _, fn in table.clone(listeners) do
					fn()
				end
			end

			return Theme
		end

		-- Core/Util
		loaders[nodes["Core/Util"]] = function(script, require)
			local Util = {}

			function Util.safeCall(fn: ((...any) -> ())?, ...: any)
				if not fn then
					return
				end
				task.spawn(function(...)
					local ok, err = xpcall(fn, debug.traceback, ...)
					if not ok then
						warn(`[MacUI] callback error: {err}`)
					end
				end, ...)
			end

			function Util.decimals(step: number): number
				local text = tostring(step)
				local dot = string.find(text, ".", 1, true)
				return if dot then #text - dot else 0
			end

			function Util.snap(value: number, min: number, max: number, step: number?): number
				local size = if step and step > 0 then step else 1
				local snapped = math.clamp(min + math.round((value - min) / size) * size, min, max)
				local factor = 10 ^ Util.decimals(size)
				return math.round(snapped * factor) / factor
			end

			function Util.format(value: number, step: number?): string
				return string.format(`%.{Util.decimals(step or 1)}f`, value)
			end

			function Util.merge(base: { [any]: any }, extra: { [any]: any }?): { [any]: any }
				local out = table.clone(base)
				for key, value in extra or {} do
					out[key] = value
				end
				return out
			end

			function Util.trim(text: string): string
				return (string.gsub(text, "^%s*(.-)%s*$", "%1"))
			end

			return Util
		end

		-- Data/UpdateLogs
		loaders[nodes["Data/UpdateLogs"]] = function(script, require)
			return function(add, fix, remove)
				fix("CHECK CHALLENGE NOW RETURNS TO LOBBY AT RESET")
				fix("BATTLE PASS LEVEL AND EXP IN RESULT WEBHOOK")
				fix("PLAY MACRO TOGGLE NOT SAVING")
				fix("MACRO RESTARTS AFTER NEXT, REPLAY OR LEAVE")
			end
		end

		-- Overlays/CommandPalette
		loaders[nodes["Overlays/CommandPalette"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Icons = require(Core.Icons)
			local Input = require(Core.Input)
			local Cleanup = require(Core.Cleanup)

			local HEADER, FOOTER, ROW, GAP, PAD = 52, 30, 42, 2, 6
			local MOTION = 0.16

			local CommandPalette = {}
			CommandPalette.__index = CommandPalette

			-- All geometry uses the foreground's safe viewport, at native pixel scale.
			function CommandPalette.layout(area: Vector2, count: number)
				local width = math.min(560, math.floor(area.X * 0.9))
				local rows = math.clamp(count, 1, 7)
				local margin = math.min(12, math.floor(area.Y / 2))
				local height =
					math.min(420, area.Y - margin * 2, HEADER + FOOTER + 2 + PAD * 2 + rows * ROW + (rows - 1) * GAP)
				return {
					width = width,
					height = height,
					listHeight = math.max(0, height - HEADER - FOOTER - 2),
					x = math.round((area.X - width) / 2),
					y = math.clamp(math.round(area.Y * 0.18), margin, math.max(margin, area.Y - height - margin)),
				}
			end

			function CommandPalette.new(window)
				return setmetatable({ window = window, lastQuery = "" }, CommandPalette)
			end

			function CommandPalette:isOpen(): boolean
				return self.popup ~= nil
			end

			function CommandPalette:refresh()
				if self.closing then
					self.closing.finish()
				end
				if self.session then
					self.session.refresh()
				end
			end

			function CommandPalette:toggle()
				if self.popup then
					self.popup.close()
				else
					self:open()
				end
			end

			-- Window's existing shared listener handles keys; opening adds no global listener.
			function CommandPalette:handleInput(input): boolean
				local session = self.session
				if not self.popup or not session then
					return false
				end
				local key = input.KeyCode
				if key == Enum.KeyCode.Escape then
					self.popup.close()
				elseif key == Enum.KeyCode.Down or (key == Enum.KeyCode.Tab and not Input.ctrlDown()) then
					session.highlight(math.min(session.selected + 1, #session.results), true)
				elseif key == Enum.KeyCode.Up then
					session.highlight(math.max(session.selected - 1, 1), true)
				elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter then
					session.activate(session.selected)
				else
					return false
				end
				return true
			end

			function CommandPalette:open(initial: string?)
				if self.destroyed then
					return
				end
				if self.popup then
					if initial ~= nil then
						self.session.query.Text = initial
					end
					self.session.query:CaptureFocus()
					return
				end
				if self.closing then
					self.closing.finish()
				end
				local window = self.window
				window:_buildAll()
				window.ctx.popups:closeAll()
				local registry = window.ctx.registry
				local cleanup = Cleanup.new()
				local session = { cleanup = cleanup, rows = {}, results = {}, selected = 0, open = true }
				self.session = session

				-- Dimming covers the visual viewport; controls respect CoreGui/device safe insets.
				local backdropGui = cleanup:add(Factory.new("ScreenGui", {
					Name = "CommandPaletteBackdrop",
					ResetOnSpawn = false,
					ScreenInsets = Enum.ScreenInsets.None,
					ClipToDeviceSafeArea = false,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					DisplayOrder = window.gui.DisplayOrder + 1,
					Parent = window.gui.Parent,
				}))
				local dim = Factory.new("Frame", {
					Name = "Dim",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Active = false,
					Interactable = false,
					Parent = backdropGui,
					Theme = { BackgroundColor3 = "Scrim" },
				})
				local foregroundGui = cleanup:add(Factory.new("ScreenGui", {
					Name = "CommandPaletteOverlay",
					ResetOnSpawn = false,
					ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					DisplayOrder = window.gui.DisplayOrder + 2,
					Parent = window.gui.Parent,
				}))
				local layer = Factory.new("Frame", {
					Name = "SafeArea",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Parent = foregroundGui,
				})
				session.layer, session.backdrop = layer, dim
				local position = Factory.new("Frame", {
					Name = "PalettePosition",
					BackgroundTransparency = 1,
					Active = true,
				})
				local surface = Factory.new("Frame", {
					Name = "CommandPalette",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 0.03,
					ClipsDescendants = true,
					Active = true,
					Parent = position,
					Theme = { BackgroundColor3 = "Palette" },
				}, { Factory.corner(15), Factory.stroke("PaletteBorder", 0.2) })
				session.surface = surface

				Icons.create({ Icon = "magnifying-glass", Color = "TextSecondary" }, 18, {
					Position = UDim2.fromOffset(16, 17),
					Parent = surface,
				})
				local query = Factory.text({
					Name = "Query",
					ClassName = "TextBox",
					Position = UDim2.fromOffset(44, 0),
					Size = UDim2.new(1, -106, 0, HEADER),
					Text = initial or (if window.options.PalettePreserveQuery then self.lastQuery else ""),
					Typography = "Search",
					PlaceholderText = "Search features, settings and pages...",
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.None,
					ClipsDescendants = true,
					Parent = surface,
					Theme = { PlaceholderColor3 = "PalettePlaceholder" },
				})
				session.query = query
				Factory.text({
					Text = "ESC",
					Typography = "Hint",
					TextXAlignment = Enum.TextXAlignment.Center,
					Position = UDim2.new(1, -48, 0, 16),
					Size = UDim2.fromOffset(32, 20),
					BackgroundTransparency = 0,
					Parent = surface,
					Theme = { TextColor3 = "TextSecondary", BackgroundColor3 = "SurfaceHover" },
				}, { Factory.corner(5) })
				Factory.new("Frame", {
					Position = UDim2.fromOffset(0, HEADER),
					Size = UDim2.new(1, 0, 0, 1),
					Parent = surface,
					Theme = { BackgroundColor3 = "PaletteDivider" },
				})
				local list = Factory.new("ScrollingFrame", {
					Name = "Results",
					Position = UDim2.fromOffset(0, HEADER + 1),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 3,
					VerticalScrollBarInset = Enum.ScrollBarInset.None,
					ClipsDescendants = true,
					Parent = surface,
					Theme = { ScrollBarImageColor3 = "Border" },
				})
				session.list = list
				Factory.new("Frame", {
					Position = UDim2.new(0, 0, 1, -FOOTER - 1),
					Size = UDim2.new(1, 0, 0, 1),
					Parent = surface,
					Theme = { BackgroundColor3 = "PaletteDivider" },
				})
				Factory.text({
					Text = "↑↓  Navigate     ↵  Open     Esc  Close",
					Typography = "Hint",
					TextXAlignment = Enum.TextXAlignment.Center,
					Position = UDim2.new(0, 8, 1, -FOOTER),
					Size = UDim2.new(1, -16, 0, FOOTER),
					Parent = surface,
					Theme = { TextColor3 = "TextSecondary" },
				})

				local function place()
					local geometry = CommandPalette.layout(layer.AbsoluteSize, #session.results)
					position.Size = UDim2.fromOffset(geometry.width, geometry.height)
					position.Position = UDim2.fromOffset(geometry.x, geometry.y)
					list.Size = UDim2.new(1, 0, 0, geometry.listHeight)
					for _, row in session.rows do
						if row:IsA("TextButton") then
							local available =
								math.max(0, geometry.width - PAD * 2 - 54 - row:GetAttribute("StatusWidth"))
							local titleWidth = math.floor(available * 0.55)
							row.Title.Size = UDim2.fromOffset(titleWidth, ROW)
							row.Path.Position = UDim2.fromOffset(42 + titleWidth + 8, 0)
							row.Path.Size = UDim2.fromOffset(math.max(0, available - titleWidth - 8), ROW)
						end
					end
				end
				session.highlight = function(index: number, scroll: boolean?)
					session.selected = if #session.results == 0 then 0 else math.clamp(index, 1, #session.results)
					for i, row in session.rows do
						if row:IsA("TextButton") then
							Animations.tween(
								row,
								{ BackgroundTransparency = if i == session.selected then 0 else 1 },
								0.08
							)
						end
					end
					if scroll and session.selected > 0 then
						local top = PAD + (session.selected - 1) * (ROW + GAP)
						local y, view = list.CanvasPosition.Y, list.AbsoluteWindowSize.Y
						if top < y then
							list.CanvasPosition = Vector2.new(0, top)
						elseif top + ROW > y + view then
							list.CanvasPosition = Vector2.new(0, math.max(0, top + ROW - view))
						end
					end
				end
				session.activate = function(index: number)
					local entry = session.results[index]
					if entry and self.popup then
						self.popup.close()
						entry.activate()
					end
				end
				local function render()
					for _, row in session.rows do
						row:Destroy()
					end
					table.clear(session.rows)
					session.results = registry:search(query.Text, registry:count())
					for i, entry in session.results do
						local row = Factory.button({
							Name = "Result",
							Position = UDim2.fromOffset(PAD, PAD + (i - 1) * (ROW + GAP)),
							Size = UDim2.new(1, -PAD * 2, 0, ROW),
							Parent = list,
							Theme = { BackgroundColor3 = "PaletteSelected" },
						}, { Factory.corner(8) })
						Icons.create(Icons.spec(entry.icon), 18, { Position = UDim2.fromOffset(12, 12), Parent = row })
						Factory.text({
							Name = "Title",
							Text = entry.title,
							Typography = "Feature",
							Position = UDim2.fromOffset(42, 0),
							Parent = row,
						})
						Factory.text({
							Name = "Path",
							Text = entry.subtitle or "",
							Typography = "Description",
							Parent = row,
							Theme = { TextColor3 = "TextSecondary" },
						})
						local state = entry.state and entry.state()
						local status = state or entry.shortcut
						row:SetAttribute("StatusWidth", if status then 64 else 0)
						if status then
							Factory.text({
								Text = status,
								Typography = "Description",
								TextXAlignment = Enum.TextXAlignment.Right,
								Position = UDim2.new(1, -72, 0, 0),
								Size = UDim2.fromOffset(60, ROW),
								Parent = row,
								Theme = { TextColor3 = "TextSecondary" },
							})
						end
						row.MouseEnter:Connect(function()
							if session.open then
								session.highlight(i)
							end
						end)
						row.Activated:Connect(function()
							session.activate(i)
						end)
						session.rows[i] = row
					end
					if #session.results == 0 then
						session.rows[1] = Factory.text({
							Text = "No matching features",
							TextXAlignment = Enum.TextXAlignment.Center,
							Position = UDim2.fromOffset(PAD, PAD),
							Size = UDim2.new(1, -PAD * 2, 0, ROW),
							Parent = list,
							Theme = { TextColor3 = "TextSecondary" },
						})
					end
					local count = math.max(1, #session.results)
					list.CanvasSize = UDim2.fromOffset(0, PAD * 2 + count * ROW + (count - 1) * GAP)
					place()
					list.CanvasPosition = Vector2.zero
					session.highlight(1)
				end
				session.refresh = render
				local changed = cleanup:connect(query:GetPropertyChangedSignal("Text"), render)
				render()

				local group
				local function fadeGroup()
					if not group then
						group = Factory.new("CanvasGroup", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Parent = position,
						}, { Factory.corner(15) })
						surface.Parent = group
					end
					return group
				end
				local managerFinish
				session.finish = function()
					if session.finished then
						return
					end
					session.finished = true
					if managerFinish then
						managerFinish()
					end
					cleanup:clean()
					if self.closing == session then
						self.closing = nil
					end
				end
				self.popup = window.ctx.popups:open({
					content = position,
					layer = layer,
					backdrop = dim,
					scale = 1,
					modal = true,
					place = place,
					onClose = function()
						session.open = false
						self.lastQuery = query.Text
						changed:Disconnect()
						query:ReleaseFocus()
						self.popup, self.session = nil, nil
						self.closing = session
						-- Retiring visuals must stop intercepting input before the fade ends.
						for _, inst in foregroundGui:GetDescendants() do
							if inst:IsA("GuiObject") then
								inst.Interactable = false
							end
						end
					end,
					onClosing = function(finish)
						managerFinish = finish
						if self.destroyed or window.destroyed or Animations.reducedMotion then
							session.finish()
							return
						end
						local fade = fadeGroup()
						Animations.tween(dim, { BackgroundTransparency = 1 }, MOTION)
						local tween = Animations.tween(fade, { GroupTransparency = 1 }, MOTION)
						cleanup:connect(tween.Completed, function(state)
							if state == Enum.PlaybackState.Completed then
								session.finish()
							end
						end)
					end,
				})
				if not Animations.reducedMotion then
					local fade = fadeGroup()
					fade.GroupTransparency = 1
					fade.Position = UDim2.fromOffset(0, 8)
					Animations.tween(fade, { Position = UDim2.new() }, MOTION)
					local tween = Animations.tween(fade, { GroupTransparency = 0 }, MOTION)
					cleanup:connect(tween.Completed, function(state)
						if state == Enum.PlaybackState.Completed and session.open then
							surface.Parent = position
							group:Destroy()
							group = nil
						end
					end)
				end
				task.defer(function()
					if session.open then
						query:CaptureFocus()
						query.CursorPosition = #query.Text + 1
					end
				end)
			end

			function CommandPalette:Destroy()
				self.destroyed = true
				if self.popup then
					self.popup.close()
				end
				if self.closing then
					self.closing.finish()
				end
			end

			return CommandPalette
		end

		-- Overlays/Dialog
		loaders[nodes["Overlays/Dialog"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Util = require(Core.Util)
			local PopupManager = require(script.Parent.PopupManager)
			local Button = require(script.Parent.Parent.Components.Button)

			local Dialog = {}

			export type Options = {
				Title: string,
				Content: string?,
				ConfirmText: string?,
				CancelText: string?,
				Destructive: boolean?,
				OnConfirm: (() -> ())?,
				OnCancel: (() -> ())?,
			}

			function Dialog.confirm(popups, within: GuiObject, options: Options)
				local surface = PopupManager.surface(360, { Name = "Dialog" })
				surface:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 15)
				Factory.list(6).Parent = surface
				Factory.padding(18).Parent = surface

				Factory.text({
					Text = options.Title,
					Typography = "WindowTitle",
					Size = UDim2.new(1, 0, 0, 24),
					LayoutOrder = 1,
					Parent = surface,
				})
				if options.Content then
					Factory.text({
						Text = options.Content,
						TextWrapped = true,
						TextTruncate = Enum.TextTruncate.None,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 2,
						Parent = surface,
						Theme = { TextColor3 = "TextSecondary" },
					})
				end

				local actions = Factory.new("Frame", {
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Parent = surface,
				}, {
					Factory.padding(12, 0, 0, 0),
					Factory.list(8, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right }),
				})

				local popup
				local decided = false
				local function finish(confirmed: boolean)
					if decided then
						return
					end
					decided = true
					popup.close()
					Util.safeCall(if confirmed then options.OnConfirm else options.OnCancel)
				end

				local cancel =
					Button.make({ Text = options.CancelText or "Cancel", Variant = "Ghost", LayoutOrder = 1 })
				cancel.Parent = actions
				cancel.Activated:Connect(function()
					finish(false)
				end)

				local confirm = Button.make({
					Text = options.ConfirmText or "Confirm",
					Variant = if options.Destructive then "Destructive" else "Primary",
					LayoutOrder = 2,
				})
				confirm.Parent = actions
				confirm.Activated:Connect(function()
					finish(true)
				end)

				popup = popups:open({
					content = surface,
					within = within,
					placement = "center",
					modal = true,
					onClose = function()
						if not decided then
							decided = true
							Util.safeCall(options.OnCancel)
						end
					end,
				})
				return popup
			end

			return Dialog
		end

		-- Overlays/Notifications
		loaders[nodes["Overlays/Notifications"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Icons = require(Core.Icons)
			local Cleanup = require(Core.Cleanup)
			local Util = require(Core.Util)

			local WIDTH = 320
			local MAX_VISIBLE = 4

			local KINDS = {
				info = { "circle-i", "Accent" },
				success = { "circle-check", "Success" },
				warning = { "triangle-exclamation", "Warning" },
				error = { "circle-x", "Danger" },
			}

			local Notifications = {}
			Notifications.__index = Notifications

			export type Options = {
				Title: string,
				Content: string?,
				Duration: number?,
				Kind: ("info" | "success" | "warning" | "error")?,
				Actions: { { Text: string, Callback: (() -> ())? } }?,
			}

			function Notifications.new(gui: ScreenGui)
				local self = setmetatable({ cleanup = Cleanup.new(), active = {} }, Notifications)
				self.holder = self.cleanup:add(Factory.new("Frame", {
					Name = "Notifications",
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -16, 1, -16),
					Size = UDim2.fromOffset(WIDTH, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 100,
					Parent = gui,
				}, {
					Factory.list(8, false, { VerticalAlignment = Enum.VerticalAlignment.Bottom }),
				}))
				self.uiScale = Factory.new("UIScale", { Parent = self.holder })
				return self
			end

			function Notifications:setScale(scale: number)
				self.uiScale.Scale = scale
			end

			function Notifications:notify(options: Options)
				local kind = KINDS[string.lower(options.Kind or "info")] or KINDS.info
				local order = (self.counter or 0) + 1
				self.counter = order

				local slot = Factory.new("Frame", {
					Name = "ToastRoot",
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					LayoutOrder = order,
					Parent = self.holder,
				})

				local card = Factory.new("Frame", {
					Name = "Surface",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Position = UDim2.fromOffset(WIDTH + 24, 0),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Parent = slot,
					Theme = { BackgroundColor3 = "Palette" },
				}, {
					Factory.corner(12),
					Factory.new("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						BorderStrokePosition = Enum.BorderStrokePosition.Inner,
						Thickness = 1,
						Theme = { Color = "PaletteBorder" },
					}),
					Factory.padding(12, 14),
				})

				Icons.create(
					{ Icon = kind[1], Color = kind[2] },
					18,
					{ Position = UDim2.fromOffset(0, 1), Parent = card }
				)
				local text = Factory.new("Frame", {
					Position = UDim2.fromOffset(28, 0),
					Size = UDim2.new(1, -52, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = card,
				}, { Factory.list(3) })
				Factory.text({
					Text = options.Title,
					Typography = "Section",
					Size = UDim2.new(1, 0, 0, 18),
					Parent = text,
				})
				if options.Content then
					Factory.text({
						Text = options.Content,
						Typography = "Description",
						TextWrapped = true,
						TextTruncate = Enum.TextTruncate.None,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 2,
						Parent = text,
						Theme = { TextColor3 = "TextSecondary" },
					})
				end

				local closed = false
				local function close()
					if closed then
						return
					end
					closed = true
					local index = table.find(self.active, close)
					if index then
						table.remove(self.active, index)
					end
					local height = math.round(slot.AbsoluteSize.Y / math.max(self.uiScale.Scale, 0.01))
					slot.AutomaticSize = Enum.AutomaticSize.None
					slot.Size = UDim2.new(1, 0, 0, height)
					Animations.tween(
						card,
						{ Position = UDim2.fromOffset(WIDTH + 24, 0) },
						Theme.Motion.Notify,
						Enum.EasingStyle.Quad
					)
					local tween = Animations.tween(slot, { Size = UDim2.new(1, 0, 0, 0) }, Theme.Motion.Notify)
					if tween then
						tween.Completed:Once(function()
							slot:Destroy()
						end)
					else
						slot:Destroy()
					end
				end

				if options.Actions then
					local row = Factory.new("Frame", {
						Size = UDim2.new(1, 0, 0, 26),
						BackgroundTransparency = 1,
						LayoutOrder = 3,
						Parent = text,
					}, { Factory.list(6, true), Factory.padding(6, 0, 0, 0) })
					row.AutomaticSize = Enum.AutomaticSize.Y
					for i, action in options.Actions do
						local button = require(script.Parent.Parent.Components.Button).make({
							Text = action.Text,
							Variant = if i == 1 then "Primary" else "Secondary",
							Height = 24,
							LayoutOrder = i,
						})
						button.Parent = row
						button.Activated:Connect(function()
							Util.safeCall(action.Callback)
							close()
						end)
					end
				end

				local closeButton = Factory.button({
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(18, 18),
					Parent = card,
				})
				Icons.create({ Icon = "x", Color = "TextMuted" }, 14, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = closeButton,
				})
				closeButton.Activated:Connect(close)

				task.defer(function()
					if closed then
						return
					end
					local height = math.round(card.AbsoluteSize.Y / math.max(self.uiScale.Scale, 0.01))
					local tween = Animations.tween(slot, { Size = UDim2.new(1, 0, 0, height) }, Theme.Motion.Notify)
					Animations.tween(
						card,
						{ Position = UDim2.fromOffset(0, 0) },
						Theme.Motion.Notify,
						Enum.EasingStyle.Quint
					)
					local function fit()
						if not closed then
							slot.AutomaticSize = Enum.AutomaticSize.Y
							slot.Size = UDim2.new(1, 0, 0, 0)
						end
					end
					if tween then
						tween.Completed:Once(fit)
					else
						fit()
					end
				end)

				table.insert(self.active, close)
				while #self.active > MAX_VISIBLE do
					self.active[1]()
				end

				local duration = options.Duration or 4
				if duration > 0 then
					task.delay(duration, close)
				end
				return close
			end

			function Notifications:count(): number
				return #self.active
			end

			function Notifications:Destroy()
				self.cleanup:clean()
			end

			return Notifications
		end

		-- Overlays/PopupManager
		loaders[nodes["Overlays/PopupManager"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Input = require(Core.Input)
			local Cleanup = require(Core.Cleanup)

			local MARGIN = 8

			local PopupManager = {}
			PopupManager.__index = PopupManager

			export type Policy = {
				OpenOn: "Click"?,
				CloseOnOutsideClick: boolean?,
				CloseOnEscape: boolean?,
				CloseOnMouseLeave: false?,
				CloseOnInteraction: false?,
			}

			export type Options = {
				content: GuiObject,
				anchor: GuiObject?,
				within: GuiObject?,
				align: "left" | "right" | nil,
				placement: "below" | "center" | nil,
				gap: number?,
				modal: boolean?,
				dismissible: boolean?,
				onClose: (() -> ())?,
				layer: GuiObject?,
				backdrop: GuiObject?,
				scale: number?,
				place: ((any) -> ())?,
				onClosing: ((() -> ()) -> ())?,
				owner: any?,
				group: string?,
				regions: { GuiObject }?,
				policy: Policy?,
			}

			function PopupManager.new(gui: ScreenGui)
				local self = setmetatable({
					stack = {},
					closing = {},
					scale = 1,
					cleanup = Cleanup.new(),
				}, PopupManager)

				self.layer = self.cleanup:add(Factory.new("Frame", {
					Name = "Overlay",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					ZIndex = 50,
					Parent = gui,
				}))

				self.cleanup:add(Input.listen(function(input)
					return self:_input(input)
				end))
				return self
			end

			function PopupManager:_input(input: InputObject): boolean
				local top = self.stack[#self.stack]
				if not top then
					return false
				end

				if input.KeyCode == Enum.KeyCode.Escape then
					if top.closeOnEscape then
						top.close()
					end
					return true
				end

				if Input.isPointer(input) then
					local point = Input.position(input)
					-- Use the stack at InputBegan; callbacks may open/close overlays during this input.
					local stack = table.clone(self.stack)
					for i = #stack, 1, -1 do
						local popup = stack[i]
						if not popup.open then
							continue
						end
						local inside = Input.inside(popup.frame, point)
							or (popup.anchor and Input.inside(popup.anchor, point))
						for _, region in popup.regions do
							inside = inside or (region.Parent ~= nil and Input.inside(region, point))
						end
						if inside or not popup.closeOnOutsideClick then
							break
						end
						popup.close()
						if popup.modal then
							break
						end
					end
				end
				return false
			end

			function PopupManager:_place(popup)
				local frame, layer = popup.frame, popup.layer
				local size = frame.AbsoluteSize
				local bounds = layer.AbsoluteSize
				local x, y

				if popup.placement == "center" then
					local within = popup.within or layer
					local pos, area = within.AbsolutePosition - layer.AbsolutePosition, within.AbsoluteSize
					x = pos.X + (area.X - size.X) / 2
					y = pos.Y + math.min(area.Y * 0.16, math.max(area.Y - size.Y, 0) / 2)
				elseif popup.anchor then
					local pos, area = popup.anchor.AbsolutePosition - layer.AbsolutePosition, popup.anchor.AbsoluteSize
					local gap = (popup.gap or 6) * self.scale
					x = if popup.align == "right" then pos.X + area.X - size.X else pos.X
					y = pos.Y + area.Y + gap
					if y + size.Y > bounds.Y - MARGIN and pos.Y - gap - size.Y >= MARGIN then
						y = pos.Y - gap - size.Y
					end
				else
					x, y = (bounds.X - size.X) / 2, (bounds.Y - size.Y) / 2
				end

				x = math.clamp(x, MARGIN, math.max(MARGIN, bounds.X - size.X - MARGIN))
				y = math.clamp(y, MARGIN, math.max(MARGIN, bounds.Y - size.Y - MARGIN))
				frame.Position = UDim2.fromOffset(math.round(x), math.round(y))
			end

			function PopupManager:open(options: Options)
				local policy = options.policy or {}
				-- ponytail: feature popovers are click-only; hover/interaction dismissal needs a separate policy.
				assert(policy.OpenOn == nil or policy.OpenOn == "Click", "Popover.OpenOn must be Click")
				assert(
					policy.CloseOnMouseLeave == nil or policy.CloseOnMouseLeave == false,
					"Popovers stay open on mouse leave"
				)
				assert(
					policy.CloseOnInteraction == nil or policy.CloseOnInteraction == false,
					"Popovers stay open during interaction"
				)
				for _, key in { "CloseOnOutsideClick", "CloseOnEscape" } do
					assert(policy[key] == nil or type(policy[key]) == "boolean", `Popover.{key} must be a boolean`)
				end
				local owner = options.owner
				if not owner and options.anchor then
					for i = #self.stack, 1, -1 do
						if options.anchor:IsDescendantOf(self.stack[i].frame) then
							owner = self.stack[i]
							break
						end
					end
				end
				if options.group then
					for _, existing in table.clone(self.stack) do
						if existing.group == options.group then
							existing.close()
						end
					end
				end
				local cleanup = Cleanup.new()
				local frame = options.content
				local popup = {
					frame = frame,
					anchor = options.anchor,
					within = options.within,
					align = options.align,
					placement = options.placement,
					gap = options.gap,
					modal = options.modal == true,
					dismissible = options.dismissible ~= false,
					closeOnOutsideClick = options.dismissible ~= false and policy.CloseOnOutsideClick ~= false,
					closeOnEscape = options.dismissible ~= false and policy.CloseOnEscape ~= false,
					owner = owner,
					group = options.group,
					regions = options.regions or {},
					open = true,
				}

				local layer = options.layer or self.layer
				popup.layer = layer
				local parent = layer
				if popup.modal then
					local scrim = cleanup:add(Factory.button({
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ZIndex = 1,
						Parent = layer,
						Theme = { BackgroundColor3 = "Scrim" },
					}))
					Animations.tween(options.backdrop or scrim, { BackgroundTransparency = 0.55 }, Theme.Motion.Popup)
					-- Dismiss only on InputBegan through the manager, never on a drag's release.
					parent = scrim
				end

				local scale = options.scale or self.scale
				local uiScale =
					Factory.new("UIScale", { Scale = if options.scale then scale else scale * 0.97, Parent = frame })
				popup.uiScale = uiScale
				popup.fixedScale = options.scale ~= nil
				frame.AnchorPoint = Vector2.zero
				frame.ZIndex = 2
				frame.Parent = parent
				cleanup:add(frame)

				local function place()
					if popup.open then
						if options.place then
							options.place(popup)
						else
							self:_place(popup)
						end
					end
				end
				cleanup:connect(frame:GetPropertyChangedSignal("AbsoluteSize"), place)
				cleanup:connect(layer:GetPropertyChangedSignal("AbsoluteSize"), place)
				cleanup:connect(layer:GetPropertyChangedSignal("AbsolutePosition"), place)
				if popup.anchor then
					cleanup:connect(popup.anchor:GetPropertyChangedSignal("AbsolutePosition"), place)
					cleanup:connect(popup.anchor:GetPropertyChangedSignal("AbsoluteSize"), place)
				end
				if popup.within then
					cleanup:connect(popup.within:GetPropertyChangedSignal("AbsolutePosition"), place)
					cleanup:connect(popup.within:GetPropertyChangedSignal("AbsoluteSize"), place)
				end
				place()
				if not popup.fixedScale then
					Animations.tween(uiScale, { Scale = scale }, Theme.Motion.Popup)
				end

				function popup.close()
					if not popup.open then
						return
					end
					popup.open = false
					for _, child in table.clone(self.stack) do
						if child.owner == popup then
							child.close()
						end
					end
					local index = table.find(self.stack, popup)
					if index then
						table.remove(self.stack, index)
					end
					if options.onClose then
						options.onClose()
					end
					local function finish()
						self.closing[popup] = nil
						cleanup:clean()
					end
					if options.onClosing then
						self.closing[popup] = finish
						options.onClosing(finish)
					else
						finish()
					end
				end

				table.insert(self.stack, popup)
				if popup.anchor then
					local function checkAnchor()
						local node = popup.anchor
						while node do
							if
								(node:IsA("GuiObject") and not node.Visible)
								or (node:IsA("ScreenGui") and not node.Enabled)
							then
								popup.close()
								return
							end
							node = node.Parent
						end
						if not popup.anchor:IsDescendantOf(game) then
							popup.close()
						end
					end
					cleanup:connect(popup.anchor.AncestryChanged, checkAnchor)
					local node = popup.anchor
					while node do
						if node:IsA("GuiObject") then
							cleanup:connect(node:GetPropertyChangedSignal("Visible"), checkAnchor)
						elseif node:IsA("ScreenGui") then
							cleanup:connect(node:GetPropertyChangedSignal("Enabled"), checkAnchor)
						end
						node = node.Parent
					end
				end
				return popup
			end

			function PopupManager:setScale(scale: number)
				self.scale = scale
				for _, popup in self.stack do
					if not popup.fixedScale then
						Animations.tween(popup.uiScale, { Scale = scale })
					end
				end
			end

			function PopupManager:closeAll()
				for i = #self.stack, 1, -1 do
					local popup = self.stack[i]
					if popup then
						popup.close()
					end
				end
			end

			function PopupManager:isOpen(): boolean
				return #self.stack > 0
			end

			-- A floating surface with the palette styling, used by dropdowns, inspectors and dialogs.
			function PopupManager.surface(width: number, props: { [string]: any }?): Frame
				local frame = Factory.new("Frame", {
					Size = UDim2.fromOffset(width, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Active = true,
					Theme = { BackgroundColor3 = "Palette" },
				}, {
					Factory.corner(12),
					Factory.stroke("PaletteBorder"),
				})
				for key, value in props or {} do
					frame[key] = value
				end
				return frame
			end

			function PopupManager:Destroy()
				self:closeAll()
				for _, finish in table.clone(self.closing) do
					finish()
				end
				self.cleanup:clean()
			end

			return PopupManager
		end

		-- Window/Account
		loaders[nodes["Window/Account"]] = function(script, require)
			local Players = game:GetService("Players")
			local Core = script.Parent.Parent.Core
			local Factory = require(Core.Factory)
			local Icons = require(Core.Icons)

			local Account = {}

			export type Options = {
				Enabled: boolean?,
				-- Legacy identity overrides are accepted; the active Roblox player stays authoritative.
				UseLocalPlayer: boolean?,
				DisplayName: string?,
				Subtitle: string?,
			}

			function Account.resolve(options)
				assert(options.Account == nil or type(options.Account) == "table", "Account must be a table")
				local config = options.Account or {}
				for _, key in { "Enabled", "UseLocalPlayer" } do
					assert(config[key] == nil or type(config[key]) == "boolean", `Account.{key} must be a boolean`)
				end
				for _, key in { "DisplayName", "Subtitle" } do
					assert(config[key] == nil or type(config[key]) == "string", `Account.{key} must be a string`)
				end
				assert(options.Title == nil or type(options.Title) == "string", "Title must be a string")
				assert(options.Subtitle == nil or type(options.Subtitle) == "string", "Subtitle must be a string")
				local player = Players.LocalPlayer
				return {
					enabled = config.Enabled ~= false,
					player = player,
					username = if player then player.Name else nil,
					displayName = if player then player.DisplayName else nil,
					userId = if player then player.UserId else nil,
					subtitle = "Account",
					avatars = {},
					listeners = {},
				}
			end

			-- Only presentation values belong in profile UI or its search metadata.
			function Account.presentation(window)
				local account = window.account
				local censored = account.censored ~= false
				local username = if account.username then `@{account.username}` else "Unavailable in this session"
				return {
					censored = censored,
					title = if censored then "Hidden User" else account.username or "Account",
					displayName = if censored then "Hidden User" else account.displayName or "Account unavailable",
					username = if censored then "@hidden" else username,
					userId = if censored
						then "Hidden"
						elseif account.userId then tostring(account.userId)
						else "Unavailable in this session",
					subtitle = "Account",
					sessionDescription = if censored
						then "Account"
						elseif account.username then `Signed in as {username}`
						else "Open Play mode to view your account",
					image = if censored then "" else account.thumbnail or "",
				}
			end

			function Account.observe(window, fn)
				local listeners = window.account.listeners
				table.insert(listeners, fn)
				fn(Account.presentation(window))
				return function()
					local index = table.find(listeners, fn)
					if index then
						table.remove(listeners, index)
					end
				end
			end

			function Account.refresh(window, refreshSearch: boolean?)
				local data = Account.presentation(window)
				for avatar in window.account.avatars do
					avatar.Image = data.image
					avatar.Fallback.Visible = data.image == ""
				end
				for _, fn in table.clone(window.account.listeners) do
					fn(data)
				end
				-- Refresh after bindings have updated the searchable profile cards.
				if refreshSearch then
					if window.sidebar then
						window.sidebar:_filter(window.sidebar.query.Text)
					end
					if window.palette then
						window.palette:refresh()
					end
				end
			end

			function Account.initialize(window, store)
				local _, enabled = store:define("AutoCensorUser", true)
				window.account.censored = enabled
				window.cleanup:add(store:observe("AutoCensorUser", function(value)
					window.account.censored = value ~= false
					Account.refresh(window, true)
				end))
				window.cleanup:add(function()
					table.clear(window.account.listeners)
				end)
			end

			-- Shared player portrait for the sidebar and account page.
			function Account.avatar(window, size: number, cleanup)
				local account = window.account
				local avatar = Factory.new("ImageLabel", {
					Name = "Avatar",
					Size = UDim2.fromOffset(size, size),
					Image = Account.presentation(window).image,
					ScaleType = Enum.ScaleType.Crop,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
				Icons.create({ Icon = "person", Color = "TextPrimary" }, math.floor(size / 2), {
					Name = "Fallback",
					Visible = avatar.Image == "",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = avatar,
				})
				account.avatars[avatar] = true
				cleanup:add(function()
					account.avatars[avatar] = nil
				end)
				return avatar
			end

			function Account.loadThumbnail(window)
				local account = window.account
				if not account.userId or account.userId <= 0 then
					return
				end
				task.spawn(function()
					local ok, content, ready = pcall(
						Players.GetUserThumbnailAsync,
						Players,
						account.userId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size420x420
					)
					if window.destroyed or not ok or not ready or type(content) ~= "string" or content == "" then
						return
					end
					account.thumbnail = content
					Account.refresh(window)
				end)
			end

			function Account.build(page)
				local window = page.window
				page.empty.Visible = false
				local hero = Factory.new("Frame", {
					Name = "AccountIdentity",
					Size = UDim2.new(1, 0, 0, 154),
					BackgroundTransparency = 1,
					LayoutOrder = 0,
					Parent = page.content,
				}, {
					Factory.list(6, false, { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
					Factory.padding(10, 0, 10, 0),
				})
				local avatar = Account.avatar(window, 80, page.cleanup)
				avatar.LayoutOrder = 1
				avatar.Parent = hero
				local name = Factory.text({
					Name = "DisplayName",
					Typography = "WindowTitle",
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.new(1, 0, 0, 24),
					LayoutOrder = 2,
					Parent = hero,
				})
				local identifier = Factory.text({
					Name = "Identifier",
					Typography = "Description",
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.new(1, 0, 0, 18),
					LayoutOrder = 3,
					Parent = hero,
					Theme = { TextColor3 = "TextSecondary" },
				})
				local profile = page:AddSection({ Title = "Profile" })
				local values = {}
				local rows = { { "Display name", "displayName" }, { "Username", "username" }, { "User ID", "userId" } }
				for i, data in rows do
					local row = Factory.new("Frame", {
						Name = data[1],
						Size = UDim2.new(1, 0, 0, 44),
						BackgroundTransparency = 1,
						LayoutOrder = i,
						Parent = profile.container,
					})
					local fields = Factory.new(
						"Frame",
						{ Name = "Fields", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = row },
						{ Factory.padding(0, 14), Factory.list(12, true) }
					)
					Factory.text(
						{ Text = data[1], Size = UDim2.new(0, 0, 1, 0), Parent = fields, LayoutOrder = 1 },
						{ Factory.fill() }
					)
					values[data[2]] = Factory.text({
						Name = "Value",
						Typography = "Description",
						TextXAlignment = Enum.TextXAlignment.Right,
						Size = UDim2.new(0.6, 0, 1, 0),
						Parent = fields,
						LayoutOrder = 2,
						Theme = { TextColor3 = "TextSecondary" },
					})
					if i > 1 then
						Factory.new("Frame", {
							Name = "Divider",
							Position = UDim2.fromOffset(14, 0),
							Size = UDim2.new(1, -28, 0, 1),
							BackgroundTransparency = 0.45,
							Parent = row,
							Theme = { BackgroundColor3 = "Border" },
						})
					end
				end
				page.cleanup:add(Account.observe(window, function(data)
					name.Text, identifier.Text = data.title, data.username
					for key, label in values do
						label.Text = data[key]
					end
				end))
			end

			return Account
		end

		-- Window/DragResize
		loaders[nodes["Window/DragResize"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Factory = require(Core.Factory)
			local Input = require(Core.Input)
			local Icons = require(Core.Icons)
			local UserInputService = game:GetService("UserInputService")

			local DragResize = {}

			-- Query the rendered stack in screen pixels, in the same space as InputObject.Position.
			function DragResize.target(window, point: Vector2): GuiObject?
				local container = window.gui:FindFirstAncestorWhichIsA("BasePlayerGui")
				if not container then
					return nil
				end
				for _, hit in container:GetGuiObjectsAtPosition(math.round(point.X), math.round(point.Y)) do
					if hit == window.frame or hit:IsDescendantOf(window.frame) then
						return hit
					end
					-- Ignore inert, transparent layout wrappers, but never drag through another visible surface.
					if
						hit.Active
						or hit.BackgroundTransparency < 1
						or hit:IsA("GuiButton")
						or hit:IsA("TextBox")
						or hit:IsA("TextLabel")
						or hit:IsA("ImageLabel")
						or hit:GetAttribute("NoWindowDrag")
						or hit:GetAttribute("DragBlock")
					then
						return nil
					end
				end
				return nil
			end

			function DragResize.canDrag(window, target: GuiObject?, point: Vector2, touch: boolean): boolean
				if not target or (target ~= window.frame and not target:IsDescendantOf(window.frame)) then
					return false
				end
				local node = target
				while node do
					if
						node:GetAttribute("NoWindowDrag")
						or node:GetAttribute("DragBlock")
						or node:IsA("TextBox")
						or (node:IsA("GuiButton") and (touch or node:GetAttribute("NoWindowDrag") ~= false))
					then
						return false
					end
					if node:IsA("ScrollingFrame") and node.ScrollingEnabled then
						-- Touch pans content; mouse may drag blank content, except the scrollbar gutter.
						if touch then
							return false
						end
						local pos, size = node.AbsolutePosition, node.AbsoluteSize
						local thickness = node.ScrollBarThickness * window.scale
						local vertical = node.AbsoluteCanvasSize.Y > node.AbsoluteWindowSize.Y
						local horizontal = node.AbsoluteCanvasSize.X > node.AbsoluteWindowSize.X
						local left = node.VerticalScrollBarPosition == Enum.VerticalScrollBarPosition.Left
						if
							(
								vertical
								and (
									if left then point.X < pos.X + thickness else point.X >= pos.X + size.X - thickness
								)
							) or (horizontal and point.Y >= pos.Y + size.Y - thickness)
						then
							return false
						end
					end
					if node == window.frame then
						return true
					end
					node = node.Parent
				end
				return false
			end

			-- One controller per window; permanent listeners are never re-created by a gesture or page change.
			function DragResize.drag(window)
				local controller = {}
				function controller.stop()
					controller.candidate = nil
					if window.stopDrag == controller.stop then
						window.stopDrag = nil
					end
				end
				function controller:begin(input)
					if
						window.destroyed
						or not window.options.Draggable
						or not window.visible
						or window.maximized
						or window.stopDrag
						or not Input.isPointer(input)
					then
						return false
					end
					local point = Input.position(input)
					local touch = input.UserInputType == Enum.UserInputType.Touch
					if touch and window.options.MobileTouchDrag == false then
						return false
					end
					local target = DragResize.target(window, point)
					if not DragResize.canDrag(window, target, point, touch) then
						return false
					end
					-- Root UIScale changes size; only scaled ancestors change Position units.
					local root, parentScale = window.root, Vector2.new(1, 1)
					local logical = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset) * window.uiScale.Scale
					if logical.X > 0 and logical.Y > 0 and root.AbsoluteSize.X > 0 and root.AbsoluteSize.Y > 0 then
						parentScale = root.AbsoluteSize / logical
					end
					self.candidate = {
						input = input,
						point = point,
						position = window.position,
						parentScale = parentScale,
						threshold = if touch then 8 else 4,
						dragging = false,
					}
					window.stopDrag = controller.stop
					return false
				end
				function controller:move(input)
					local drag = self.candidate
					if
						not drag
						or (
							if drag.input.UserInputType == Enum.UserInputType.Touch
								then input ~= drag.input
								else input.UserInputType ~= Enum.UserInputType.MouseMovement
						)
					then
						return
					end
					if input.UserInputState == Enum.UserInputState.Cancel then
						controller.stop()
						return
					end
					local point = Input.position(input)
					if not drag.dragging and (point - drag.point).Magnitude < drag.threshold then
						return
					end
					drag.dragging = true
					window.position = drag.position + (point - drag.point) / drag.parentScale
					window:_apply(false)
				end
				function controller:finish(input)
					local drag = self.candidate
					if
						not drag
						or (
							input ~= drag.input
							and not (
								drag.input.UserInputType == Enum.UserInputType.MouseButton1
								and input.UserInputType == Enum.UserInputType.MouseButton1
							)
						)
					then
						return
					end
					controller.stop()
				end
				window.cleanup:add(Input.listen(function(input)
					if input.UserInputType ~= Enum.UserInputType.Touch then
						return controller:begin(input)
					end
					return false
				end))
				window.cleanup:connect(UserInputService.TouchStarted, function(input)
					controller:begin(input)
				end)
				window.cleanup:connect(UserInputService.InputChanged, function(input)
					controller:move(input)
				end)
				window.cleanup:connect(UserInputService.InputEnded, function(input)
					controller:finish(input)
				end)
				window.cleanup:connect(UserInputService.WindowFocusReleased, controller.stop)
				window.cleanup:add(controller.stop)
				return controller
			end

			function DragResize.resize(window, frame: GuiObject)
				local grip = Factory.button({
					Name = "ResizeGrip",
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -1, 1, -1),
					Size = UDim2.fromOffset(24, 24),
					ZIndex = 20,
					Parent = frame,
				})
				grip:SetAttribute("NoWindowDrag", true)
				Icons.create({ Icon = "square-corner-line-small", Color = "TextMuted" }, 14, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Rotation = 90,
					TextTransparency = 0.4,
					Parent = grip,
				})

				window.cleanup:connect(grip.InputBegan, function(input)
					if
						window.destroyed
						or not window.visible
						or not window.options.Resizable
						or window.maximized
						or window.minimized
						or not grip.Visible
						or not Input.isPointer(input)
					then
						return
					end
					if window.stopDrag then
						local candidate = window.dragController and window.dragController.candidate
						if not candidate or candidate.input ~= input then
							return
						end
						window.stopDrag() -- The grip owns this input, even if the window listener ran first.
					end
					local startPoint = Input.position(input)
					local root = window.root
					local startSize = Vector2.new(root.Size.X.Offset, root.Size.Y.Offset)
					local actual = root.AbsoluteSize
					if startSize.X <= 0 or startSize.Y <= 0 or actual.X <= 0 or actual.Y <= 0 then
						return
					end
					local scale = actual / startSize -- Includes root UIScale and any scaled ancestors, exactly once.
					local startPos, anchor = window.position, root.AnchorPoint
					local ownScale = window.uiScale.Scale
					window.stopDrag = Input.drag(input, function(point)
						local size = startSize + (point - startPoint) / scale
						window.size = Vector2.new(
							math.round(math.max(window.minSize.X, size.X)),
							math.round(math.max(window.minSize.Y, size.Y))
						)
						window.position = startPos + (window.size - startSize) * anchor * ownScale
						window:_apply(false)
					end, function()
						window.stopDrag = nil
					end)
				end)
				window.cleanup:add(function()
					if window.stopDrag then
						window.stopDrag()
					end
				end)
				return grip
			end

			return DragResize
		end

		-- Window/MobileLauncher
		loaders[nodes["Window/MobileLauncher"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Factory = require(Core.Factory)
			local Icons = require(Core.Icons)
			local Theme = require(Core.Theme)
			local Animations = require(Core.Animations)
			local Cleanup = require(Core.Cleanup)
			local Input = require(Core.Input)

			local SIZE, MARGIN = 48, 12
			local MobileLauncher = {}
			MobileLauncher.__index = MobileLauncher

			function MobileLauncher.new(window)
				local self = setmetatable({ window = window, cleanup = Cleanup.new() }, MobileLauncher)
				self.gui = self.cleanup:add(Factory.new("ScreenGui", {
					Name = "MacUILauncher",
					ResetOnSpawn = false,
					ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					DisplayOrder = window.gui.DisplayOrder + 3,
					Parent = window.gui.Parent,
				}))
				self.area = Factory.new(
					"Frame",
					{ Name = "SafeArea", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = self.gui }
				)
				self.root = Factory.new("Frame", {
					Name = "Launcher",
					Size = UDim2.fromOffset(SIZE, SIZE),
					BackgroundTransparency = 1,
					Parent = self.area,
				})
				for _, spread in { 4, 8 } do
					Factory.new("Frame", {
						Name = "Shadow",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.new(0.5, 0, 0.5, 3),
						Size = UDim2.fromOffset(SIZE + spread, SIZE + spread),
						BackgroundTransparency = 0.94,
						Interactable = false,
						Parent = self.root,
						Theme = { BackgroundColor3 = "Shadow" },
					}, { Factory.new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
				end
				local button = Factory.button({
					Name = "ToggleMacUI",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 0.08,
					ZIndex = 2,
					Parent = self.root,
					Theme = { BackgroundColor3 = "Palette" },
				}, {
					Factory.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Factory.stroke("PaletteBorder", 0.2),
				})
				self.button = button
				self.icon = Icons.create({ Icon = "sidebar", Color = "TextPrimary" }, 22, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = button,
				})
				self.cleanup:connect(button.InputBegan, function(input)
					if self.stopDrag or not Input.isPointer(input) then
						return
					end
					self.pointer, self.suppressActivation = input, false
					local origin = Input.position(input)
					local position = Vector2.new(self.root.Position.X.Offset, self.root.Position.Y.Offset)
					self.stopDrag = Input.drag(input, function(point)
						local delta = point - origin
						if not self.suppressActivation and delta.Magnitude < 8 then
							return
						end
						self.suppressActivation = true
						self:_move(position + delta)
					end, function()
						if input.UserInputState ~= Enum.UserInputState.End then
							self.suppressActivation = true
						end
						self.stopDrag = nil
					end)
				end)
				self.cleanup:connect(button.Activated, function(input)
					if input and input.UserInputType == Enum.UserInputType.Touch and input ~= self.pointer then
						return
					end
					if self.suppressActivation and (not input or Input.isPointer(input)) then
						return
					end
					window:Toggle()
				end)
				self.cleanup:add(function()
					if self.stopDrag then
						self.stopDrag()
					end
				end)
				self.cleanup:connect(button:GetPropertyChangedSignal("GuiState"), function()
					Theme.bind(button, {
						BackgroundColor3 = if button.GuiState == Enum.GuiState.Press
							then "SurfaceActive"
							elseif button.GuiState == Enum.GuiState.Hover then "SurfaceHover"
							else "Palette",
					})
					Animations.tween(
						button,
						{ BackgroundTransparency = if button.GuiState == Enum.GuiState.Idle then 0.08 else 0 },
						Theme.Motion.Hover
					)
				end)
				local function viewportChanged()
					if self.stopDrag then
						self.stopDrag()
					end
					self:_place()
				end
				self.cleanup:connect(self.area:GetPropertyChangedSignal("AbsoluteSize"), viewportChanged)
				self.cleanup:connect(self.area:GetPropertyChangedSignal("AbsolutePosition"), viewportChanged)
				self.cleanup:connect(window.root:GetPropertyChangedSignal("AbsoluteSize"), function()
					self:_place()
				end)
				self:_place()
				self:refresh()
				return self
			end

			function MobileLauncher:_move(position: Vector2)
				local size = self.area.AbsoluteSize
				local x = math.round(math.clamp(position.X, 0, math.max(0, size.X - SIZE)))
				local y = math.round(math.clamp(position.Y, 0, math.max(0, size.Y - SIZE)))
				self.offset = Vector2.new(x, y)
				self.root.Position = UDim2.fromOffset(x, y)
			end

			function MobileLauncher:_place()
				local area, window = self.area, self.window
				local size = area.AbsoluteSize
				if size.X < SIZE or size.Y < SIZE then
					return
				end
				if self.offset then
					self:_move(self.offset)
					return
				end
				local marginX, marginY = math.min(MARGIN, (size.X - SIZE) / 2), math.min(MARGIN, (size.Y - SIZE) / 2)
				local left, right = marginX, size.X - SIZE - marginX
				local preferred = if window.options.MobileTogglePosition == "Left" then left else right
				local other = if preferred == left then right else left
				local pos, bounds = window.root.AbsolutePosition - area.AbsolutePosition, window.root.AbsoluteSize
				local selected
				for _, fraction in { 0.5, 0.25, 0.75 } do
					local y = math.clamp(math.round(size.Y * fraction - SIZE / 2), marginY, size.Y - SIZE - marginY)
					for _, x in { preferred, other } do
						local candidate = Vector2.new(math.round(x), math.round(y))
						selected = selected or candidate
						if x + SIZE <= pos.X or x >= pos.X + bounds.X or y + SIZE <= pos.Y or y >= pos.Y + bounds.Y then
							self.root.Position = UDim2.fromOffset(candidate.X, candidate.Y)
							return
						end
					end
				end
				-- If the window fills the viewport, the higher DisplayOrder keeps the launcher reachable.
				self.root.Position = UDim2.fromOffset(selected.X, selected.Y)
			end

			function MobileLauncher:refresh()
				self.button:SetAttribute("WindowVisible", self.window.visible)
				Icons.tint(self.icon, if self.window.visible then "TextPrimary" else "TextSecondary")
			end

			function MobileLauncher:Destroy()
				self.cleanup:clean()
			end

			return MobileLauncher
		end

		-- Window/Page
		loaders[nodes["Window/Page"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Cleanup = require(Core.Cleanup)
			local Section = require(script.Parent.Section)

			local Page = {}
			Page.__index = Page

			export type Options = {
				Id: string?,
				Title: string,
				Description: string?,
				Icon: any?,
				Badge: string?,
				Group: number?,
				Keywords: string?,
				Aliases: (string | { string })?,
				Build: ((any) -> ())?,
				Sidebar: boolean?,
			}

			function Page.new(window, options: Options)
				local self = setmetatable({
					window = window,
					options = options,
					id = options.Id or string.lower(options.Title),
					sections = {},
					order = 0,
					cleanup = Cleanup.new(),
				}, Page)

				self.ctx = setmetatable({
					searchId = `page:{self.id}`,
					searchPath = options.Title,
					pageTitle = options.Title,
					locate = function(target: GuiObject, after: (() -> ())?)
						window:SelectPage(self.id)
						task.defer(function()
							self:ScrollTo(target)
							if after then
								after()
							end
						end)
					end,
				}, { __index = window.ctx })

				self.scroller = self.cleanup:add(Factory.new("ScrollingFrame", {
					Name = self.id,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 4,
					ScrollBarImageTransparency = 0.3,
					VerticalScrollBarInset = Enum.ScrollBarInset.Always,
					Visible = false,
					Parent = window.body,
					Theme = { ScrollBarImageColor3 = "Border" },
				}))

				self.content = Factory.new("Frame", {
					Name = "Content",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent = self.scroller,
				}, {
					Factory.list(12),
					Factory.padding(4, 12, 16, 12),
				})

				self.empty = Factory.text({
					Text = "Nothing here yet.",
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.new(1, 0, 0, 120),
					LayoutOrder = 100000,
					Parent = self.content,
					Theme = { TextColor3 = "TextMuted" },
				})

				self.cleanup:add(window.ctx.registry:add({
					id = `page:{self.id}`,
					kind = "page",
					title = options.Title,
					subtitle = "Page",
					keywords = `{options.Description or ""} {options.Keywords or ""}`,
					aliases = options.Aliases,
					icon = options.Icon or "circle",
					activate = function()
						window:SelectPage(self.id)
					end,
				}))

				return self
			end

			function Page:AddSection(options: Section.Options?)
				if self.ctx.buildYield then self.ctx.buildYield("section " .. tostring(options and options.Title or "")) end
				self.empty.Visible = false
				local section = Section.new(self, options or {})
				table.insert(self.sections, section)
				return section
			end

			function Page:GetSections()
				return table.clone(self.sections)
			end

			function Page:CardCount(): number
				local count = 0
				for _, section in self.sections do
					count += #section.cards
				end
				return count
			end

			function Page:ScrollTo(target: GuiObject)
				local scroller = self.scroller
				local scale = self.window.ctx.scale()
				local offset = (target.AbsolutePosition.Y - scroller.AbsolutePosition.Y) / scale
				local goal = math.max(0, scroller.CanvasPosition.Y + offset - 24)
				local maxY = math.max(0, (scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y) / scale)
				Animations.tween(
					scroller,
					{ CanvasPosition = Vector2.new(0, math.min(goal, maxY)) },
					Theme.Motion.Expand
				)
			end

			-- Lazy pages pass Build = function(page) ... end; it runs once, on first open or first search.
			function Page:EnsureBuilt()
				local build = self.options.Build
				if build and not self.built then
					self.built = true
					local ok, err = xpcall(build, debug.traceback, self)
					if not ok then
						warn(`[MacUI] page "{self.id}" failed to build: {err}`)
					end
				end
			end

			function Page:_show(visible: boolean)
				if visible then
					self:EnsureBuilt()
				end
				self.scroller.Visible = visible
				Animations.tween(
					self.scroller,
					{ Position = UDim2.fromOffset(0, if visible and not Animations.reducedMotion then 12 else 0) }
				)
				if visible then
					Animations.tween(self.scroller, { Position = UDim2.new() }, Theme.Motion.Page)
				end
			end

			function Page:SetTitle(title: string)
				self.options.Title = title
				self.ctx.pageTitle = title
				self.ctx.searchPath = title
				for _, section in self.sections do
					section.ctx.searchPath = if section.options.Title
						then `{title} › {section.options.Title}`
						else title
					for _, card in section.cards do
						card:SetTitle(card.options.Title)
						self.window.ctx.registry:update(card.registryKey, { subtitle = section.ctx.searchPath })
					end
				end
				self.window.ctx.registry:update(`page:{self.id}`, { title = title })
				self.window:_pageChanged(self)
			end

			function Page:SetBadge(text: string?)
				self.options.Badge = text
				self.window:_pageChanged(self)
			end

			function Page:Destroy()
				for i = #self.sections, 1, -1 do
					self.sections[i]:Destroy()
				end
				self.cleanup:clean()
				self.window:_removePage(self)
			end

			return Page
		end

		-- Window/Section
		loaders[nodes["Window/Section"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Cleanup = require(Core.Cleanup)
			local Card = require(script.Parent.Parent.Components.Card)

			local GRID_GAP = 10
			local MIN_TILE = 220
			local TILE_HEIGHT = 104

			local Section = {}
			Section.__index = Section

			export type Options = {
				Title: string?,
				Description: string?,
				Layout: "List" | "Grid" | nil,
				Columns: number?,
			}

			function Section.new(page, options: Options)
				local self = setmetatable({
					page = page,
					ctx = page.ctx,
					options = options,
					cards = {},
					order = 0,
					grid = options.Layout == "Grid",
					cleanup = Cleanup.new(),
					visible = true,
				}, Section)

				page.order += 1
				self.ctx = setmetatable({
					searchId = `{page.ctx.searchId}/section:{page.order}`,
					searchPath = if options.Title
						then `{page.ctx.searchPath} › {options.Title}`
						else page.ctx.searchPath,
				}, { __index = page.ctx })
				self.Instance = self.cleanup:add(Factory.new("Frame", {
					Name = options.Title or "Section",
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = page.order,
					Parent = page.content,
				}, { Factory.list(8) }))

				if options.Title or options.Description then
					local head = Factory.new("Frame", {
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 1,
						Parent = self.Instance,
					}, { Factory.list(2), Factory.padding(4, 2, 0, 2) })

					if options.Title then
						self.titleLabel = Factory.text({
							Text = options.Title,
							Typography = "Section",
							Size = UDim2.new(1, 0, 0, 18),
							LayoutOrder = 1,
							Parent = head,
						})
					end
					if options.Description then
						Factory.text({
							Text = options.Description,
							Typography = "Description",
							TextWrapped = true,
							TextTruncate = Enum.TextTruncate.None,
							Size = UDim2.fromScale(1, 0),
							AutomaticSize = Enum.AutomaticSize.Y,
							LayoutOrder = 2,
							Parent = head,
							Theme = { TextColor3 = "TextSecondary" },
						})
					end
				end

				if self.grid then
					self.container = Factory.new("Frame", {
						Name = "Grid",
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						Parent = self.Instance,
					})
					self.gridLayout = Factory.new("UIGridLayout", {
						CellPadding = UDim2.fromOffset(GRID_GAP, GRID_GAP),
						CellSize = UDim2.fromOffset(MIN_TILE, TILE_HEIGHT),
						SortOrder = Enum.SortOrder.LayoutOrder,
						Parent = self.container,
					})
					self.cleanup:connect(self.container:GetPropertyChangedSignal("AbsoluteSize"), function()
						self:_fitGrid()
					end)
					self:_fitGrid()
				else
					self.container = Factory.new("Frame", {
						Name = "Group",
						Size = UDim2.fromScale(1, 0),
						BackgroundTransparency = 0.04,
						AutomaticSize = Enum.AutomaticSize.Y,
						LayoutOrder = 2,
						Parent = self.Instance,
						Theme = { BackgroundColor3 = "Surface" },
					}, {
						Factory.corner(Theme.get("RadiusCard")),
						Factory.list(0),
					})
				end

				return self
			end

			function Section:_fitGrid()
				local scale = self.ctx.scale()
				local width = self.container.AbsoluteSize.X / scale
				if width <= 0 then
					return
				end
				local columns = self.options.Columns
					or math.clamp(math.floor((width + GRID_GAP) / (MIN_TILE + GRID_GAP)), 1, 3)
				local cell = math.floor((width - GRID_GAP * (columns - 1)) / columns)
				self.gridLayout.CellSize = UDim2.fromOffset(cell, TILE_HEIGHT)
			end

			-- Rebuilds row dividers so only visible neighbours are separated.
			function Section:_refresh()
				if self.grid then
					return
				end
				local shown = 0
				for _, card in self.cards do
					local line = card.Instance:FindFirstChild("RowDivider")
					if card.visible then
						shown += 1
					end
					if card.visible and shown > 1 then
						if not line then
							Factory.new("Frame", {
								Name = "RowDivider",
								AnchorPoint = Vector2.new(0.5, 0),
								Position = UDim2.fromScale(0.5, 0),
								Size = UDim2.new(1, -32, 0, 1),
								BackgroundTransparency = 0.45,
								LayoutOrder = 0,
								Parent = card.Instance,
								Theme = { BackgroundColor3 = "Border" },
							})
						end
					elseif line then
						line:Destroy()
					end
				end
				self.container.Visible = shown > 0
			end

			function Section:AddCard(options): any
				if self.ctx.buildYield then self.ctx.buildYield("card " .. tostring(options and options.Title or "")) end
				local card = Card.new(self, options)
				table.insert(self.cards, card)
				self:_refresh()
				return card
			end

			function Section:AddToggleDropdownGroup(options): any
				if self.ctx.buildYield then self.ctx.buildYield("dropdown group") end
				local group = Card.newDropdownGroup(self, options)
				table.insert(self.cards, group)
				self:_refresh()
				return group
			end

			function Section:AddPrioritySelector(options): any
				options = table.clone(options or {})
				local host = self:AddCard({ Title = options.Title or "Priority", Searchable = false })
				host.header.Visible = false
				host.content:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, Theme.get("SpacingMedium"))
				local ok, element = pcall(host.AddPrioritySelector, host, options)
				if not ok then
					host:Destroy()
					error(element, 2)
				end
				local setVisible, onDestroy = element.SetVisible, element.onDestroy
				element.SetVisible = function(control, visible)
					setVisible(control, visible)
					host:SetVisible(visible)
				end
				element.onDestroy = function(control)
					onDestroy(control)
					host:Destroy()
				end
				return element
			end

			function Section:AddUpdateLog(options): any
				options = table.clone(options or {})
				local host = self:AddCard({ Title = options.Title or "Update Logs", Searchable = false })
				host.header.Visible = false
				host.content:FindFirstChildOfClass("UIPadding").PaddingTop = UDim.new(0, Theme.get("SpacingMedium"))
				local ok, element = pcall(host.AddUpdateLog, host, options)
				if not ok then
					host:Destroy()
					error(element, 2)
				end
				local setVisible, onDestroy = element.SetVisible, element.onDestroy
				element.SetVisible = function(control, visible)
					setVisible(control, visible)
					host:SetVisible(visible)
				end
				element.onDestroy = function(control)
					onDestroy(control)
					host:Destroy()
				end
				return element
			end

			function Section:_forget(card)
				local index = table.find(self.cards, card)
				if index then
					table.remove(self.cards, index)
				end
				self:_refresh()
			end

			function Section:GetCards()
				return table.clone(self.cards)
			end

			function Section:SetVisible(visible: boolean)
				self.visible = visible
				self.Instance.Visible = visible
			end

			function Section:Destroy()
				for i = #self.cards, 1, -1 do
					self.cards[i]:Destroy()
				end
				self.cleanup:clean()
				local index = table.find(self.page.sections, self)
				if index then
					table.remove(self.page.sections, index)
				end
			end

			return Section
		end

		-- Window/Sidebar
		loaders[nodes["Window/Sidebar"]] = function(script, require)
			local Core = script.Parent.Parent.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Cleanup = require(Core.Cleanup)
			local Icons = require(Core.Icons)
			local Account = require(script.Parent.Account)
			local Display = require(script.Parent.Parent.Components.Display)

			local ROW = 36
			local INSET = 8
			local ROW_PADDING = 12
			local ICON = 16
			local GAP = 12
			local PROFILE_ICON = 32
			local LIGHT = 13
			local SEARCH_Y = 40
			local PROFILE_Y = 78
			local NAV_Y = PROFILE_Y + 48 + 8

			local Sidebar = {}
			Sidebar.__index = Sidebar

			local function navigationRow(parent, name, order)
				return Factory.button({
					Name = name,
					Size = UDim2.new(1, 0, 0, ROW),
					LayoutOrder = order,
					Parent = parent,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, {
					Factory.corner(Theme.get("RadiusControl") - 1),
					Factory.padding(0, ROW_PADDING),
					Factory.list(GAP, true, { HorizontalAlignment = Enum.HorizontalAlignment.Right }),
				})
			end

			function Sidebar.new(window, parent: GuiObject, options)
				local self = setmetatable({
					window = window,
					rows = {},
					cleanup = Cleanup.new(),
					selected = nil,
					results = {},
					resultIndex = 0,
				}, Sidebar)

				-- Keep corners rounded when the settled window renders outside the fade CanvasGroup.
				local panel = self.cleanup:add(Factory.new("Frame", {
					Name = "Sidebar",
					Size = UDim2.new(0, options.Width, 1, 0),
					BackgroundTransparency = options.Transparency or 0,
					Parent = parent,
					Theme = { BackgroundColor3 = "Sidebar" },
				}, { Factory.corner(Theme.get("RadiusWindow")) }))
				self.Instance = panel
				Factory.new("Frame", {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.new(0, Theme.get("RadiusWindow"), 1, 0),
					BackgroundTransparency = options.Transparency or 0,
					Parent = panel,
					Theme = { BackgroundColor3 = "Sidebar" },
				})

				Factory.new("Frame", {
					Name = "Divider",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.new(0, 1, 1, 0),
					BackgroundTransparency = 0.3,
					ZIndex = 2,
					Parent = panel,
					Theme = { BackgroundColor3 = "Border" },
				})

				self.dragZone = Factory.new("Frame", {
					Name = "DragZone",
					Position = UDim2.fromOffset(80, 0),
					Size = UDim2.new(1, -80, 0, SEARCH_Y - 4),
					BackgroundTransparency = 1,
					Active = true,
					Parent = panel,
				})

				self:_buildLights(panel)
				self:_buildSearch(panel)
				self:_buildProfile(panel, options)

				self.list = Factory.new("ScrollingFrame", {
					Name = "Navigation",
					Position = UDim2.fromOffset(0, NAV_Y),
					Size = UDim2.new(1, 0, 1, -NAV_Y - 6),
					BackgroundTransparency = 1,
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					ScrollBarThickness = 0,
					Parent = panel,
				}, {
					Factory.list(1),
					Factory.padding(0, INSET, INSET, INSET),
				})

				-- Shared highlight that slides between rows on page change. Lives behind the list, outside its layout.
				self.pillLayer = Factory.new("Frame", {
					Name = "SelectionLayer",
					Position = self.list.Position,
					Size = self.list.Size,
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Parent = panel,
				})
				self.list.ZIndex = 2
				self.pill = Factory.new("Frame", {
					Name = "Selection",
					Size = UDim2.new(1, -INSET * 2, 0, ROW),
					Position = UDim2.fromOffset(INSET, 0),
					Visible = false,
					Parent = self.pillLayer,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(Theme.get("RadiusControl") - 1) })
				self.cleanup:connect(self.list:GetPropertyChangedSignal("CanvasPosition"), function()
					self:_placePill(false)
				end)
				self.cleanup:connect(self.list:GetPropertyChangedSignal("AbsoluteSize"), function()
					self:_placePill(false)
				end)
				local function updateScrolling()
					-- A fitted nav list is background between rows, not a touch scrolling surface.
					self.list.ScrollingEnabled = self.list.AbsoluteCanvasSize.Y > self.list.AbsoluteWindowSize.Y
				end
				self.cleanup:connect(self.list:GetPropertyChangedSignal("AbsoluteCanvasSize"), updateScrolling)
				self.cleanup:connect(self.list:GetPropertyChangedSignal("AbsoluteWindowSize"), updateScrolling)
				updateScrolling()
				self.cleanup:connect(
					self.list:FindFirstChildOfClass("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"),
					function()
						self:_placePill(false)
					end
				)

				self.noResults = Factory.text({
					Text = "No matches",
					Size = UDim2.new(1, 0, 0, ROW),
					Visible = false,
					LayoutOrder = 1e6,
					Parent = self.list,
					Theme = { TextColor3 = "TextMuted" },
				}, { Factory.padding(0, ROW_PADDING) })

				return self
			end

			function Sidebar:_buildLights(panel: Frame)
				local holder = Factory.new("Frame", {
					Name = "WindowControls",
					Position = UDim2.fromOffset(16, 15),
					Size = UDim2.fromOffset(LIGHT * 3 + 16, LIGHT),
					BackgroundTransparency = 1,
					Active = true,
					Parent = panel,
				}, { Factory.list(8, true) })
				self.windowControls = holder
				holder:SetAttribute("Hovered", false)

				local specs = {
					{
						"Close",
						Color3.fromRGB(255, 95, 87),
						Color3.fromRGB(106, 31, 25),
						{
							{ 0, 3, 7, 1, 45 },
							{ 0, 3, 7, 1, -45 },
						},
						function()
							self.window:Hide()
						end,
					},
					{
						"Minimize",
						Color3.fromRGB(254, 188, 46),
						Color3.fromRGB(132, 88, 0),
						{
							{ 0, 3, 7, 1, 0 },
						},
						function()
							self.window:SetMinimized(not self.window.minimized)
						end,
					},
					{
						"Maximize",
						Color3.fromRGB(40, 200, 64),
						Color3.fromRGB(0, 99, 19),
						{
							-- Mirrored arrowheads and short shafts, with a clear gap between arrows.
							{ 0, 0, 3, 1, 0 },
							{ 0, 0, 1, 3, 0 },
							{ 0, 1, 3, 1, 45 },
							{ 4, 6, 3, 1, 0 },
							{ 6, 4, 1, 3, 0 },
							{ 4, 5, 3, 1, 45 },
						},
						function()
							self.window:ToggleMaximize()
						end,
					},
				}

				local symbols = {}
				for i, spec in specs do
					local light = Factory.button({
						Name = spec[1],
						Size = UDim2.fromOffset(LIGHT, LIGHT),
						BackgroundTransparency = 0,
						BackgroundColor3 = spec[2],
						LayoutOrder = i,
						Parent = holder,
					}, {
						Factory.new("UICorner", { CornerRadius = UDim.new(1, 0) }),
					})
					local symbol = Factory.new("Frame", {
						Name = "Symbol",
						Position = UDim2.fromOffset(3, 3),
						Size = UDim2.fromOffset(7, 7),
						BackgroundTransparency = 1,
						Visible = false,
						Parent = light,
					})
					for _, line in spec[4] do
						Factory.new("Frame", {
							Size = UDim2.fromOffset(line[3], line[4]),
							Position = UDim2.fromOffset(line[1], line[2]),
							Rotation = line[5],
							BackgroundColor3 = spec[3],
							Parent = symbol,
						})
					end
					table.insert(symbols, symbol)
					if i == 3 then
						light.Visible = self.window.options.Maximizable == true
					end
					self.cleanup:connect(light:GetPropertyChangedSignal("GuiState"), function()
						local color = if light.GuiState == Enum.GuiState.Press
							then spec[2]:Lerp(Color3.new(), 0.15)
							else spec[2]
						Animations.tween(light, { BackgroundColor3 = color }, Theme.Motion.Hover / 2)
					end)
					self.cleanup:connect(light.Activated, spec[5])
				end

				self.cleanup:connect(holder:GetAttributeChangedSignal("Hovered"), function()
					for _, symbol in symbols do
						symbol.Visible = holder:GetAttribute("Hovered") == true
					end
				end)
				self.cleanup:connect(holder.MouseEnter, function()
					holder:SetAttribute("Hovered", true)
				end)
				self.cleanup:connect(holder.MouseLeave, function()
					holder:SetAttribute("Hovered", false)
				end)
				self.cleanup:connect(self.window.root:GetPropertyChangedSignal("Visible"), function()
					if not self.window.root.Visible then
						holder:SetAttribute("Hovered", false)
					end
				end)
			end

			function Sidebar:_buildSearch(panel: Frame)
				local box = Factory.new("Frame", {
					Name = "Search",
					Position = UDim2.fromOffset(10, SEARCH_Y),
					Size = UDim2.new(1, -20, 0, 32),
					Parent = panel,
					Theme = { BackgroundColor3 = "SurfaceActive" },
				}, { Factory.corner(10) })
				box.BackgroundTransparency = 0.35
				local stroke = Factory.stroke("Border", 1)
				stroke.Parent = box

				Icons.create({ Icon = "magnifying-glass", Color = "TextMuted" }, 15, {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					Parent = box,
				})

				local query = Factory.text({
					ClassName = "TextBox",
					Name = "Query",
					Position = UDim2.fromOffset(32, 0),
					Size = UDim2.new(1, -40, 1, 0),
					Text = "",
					PlaceholderText = self.window.options.SearchPlaceholder or "Search features...",
					ClearTextOnFocus = false,
					TextTruncate = Enum.TextTruncate.None,
					ClipsDescendants = true,
					Parent = box,
					Theme = { PlaceholderColor3 = "TextMuted" },
				})
				self.query = query

				self.cleanup:connect(query.Focused, function()
					Animations.tween(stroke, { Transparency = 0.2 }, Theme.Motion.Hover)
				end)
				self.cleanup:connect(query.FocusLost, function(enter)
					Animations.tween(stroke, { Transparency = 1 }, Theme.Motion.Hover)
					if enter then
						local entry = self.results[self.resultIndex]
						if entry then
							entry.activate()
							query.Text = ""
						end
					end
				end)
				self.cleanup:connect(query:GetPropertyChangedSignal("Text"), function()
					self:_filter(query.Text)
				end)
			end

			function Sidebar:_buildProfile(panel: Frame, options)
				local row = Factory.button({
					Name = "AccountProfile",
					Position = UDim2.fromOffset(INSET, PROFILE_Y),
					Size = UDim2.new(1, -INSET * 2, 0, 48),
					BackgroundTransparency = 0.25,
					Interactable = self.window.account.enabled,
					Selectable = self.window.account.enabled,
					Parent = panel,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, {
					Factory.corner(8),
					-- Larger identity icon shares the navigation icon center and text column.
					Factory.padding(0, ROW_PADDING, 0, ROW_PADDING - (PROFILE_ICON - ICON) / 2),
					Factory.list(GAP - (PROFILE_ICON - ICON) / 2, true),
				})

				self.profile = row
				row:SetAttribute("Selected", false)
				local avatar = Account.avatar(self.window, PROFILE_ICON, self.cleanup)
				avatar.Name = "Avatar"
				avatar.LayoutOrder = 1
				avatar.Parent = row

				local text = Factory.new("Frame", {
					Name = "ProfileText",
					Size = UDim2.fromOffset(0, 32),
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Parent = row,
				}, { Factory.fill(), Factory.list(0) })
				self.titleLabel = Factory.text({
					Text = options.Title,
					Typography = "Feature",
					Size = UDim2.new(1, 0, 0, 18),
					LayoutOrder = 1,
					Parent = text,
				})
				self.subtitleLabel = Factory.text({
					Text = options.Subtitle or "",
					Typography = "Description",
					Size = UDim2.new(1, 0, 0, 14),
					LayoutOrder = 2,
					Parent = text,
					Theme = { TextColor3 = "TextMuted" },
				})
				self.cleanup:add(Account.observe(self.window, function(data)
					self.titleLabel.Text, self.subtitleLabel.Text = data.title, data.subtitle
				end))
				self.cleanup:connect(row.Activated, function()
					self.window:SelectPage("account")
				end)
				self.cleanup:connect(row:GetPropertyChangedSignal("GuiState"), function()
					self:_renderProfile()
				end)
			end

			function Sidebar:_renderProfile()
				local row = self.profile
				local selected = self.selected ~= nil and self.selected.id == "account"
				local pressed = row.GuiState == Enum.GuiState.Press
				row:SetAttribute("Selected", selected)
				Theme.bind(row, {
					BackgroundColor3 = if pressed then "Border" elseif selected then "SurfaceActive" else "SurfaceHover",
				})
				Animations.tween(row, {
					BackgroundTransparency = if selected or pressed
						then 0
						elseif row.GuiState == Enum.GuiState.Hover then 0.05
						else 0.25,
				}, Theme.Motion.Hover)
			end

			function Sidebar:addPage(page)
				local options = page.options
				local group = options.Group or 1
				local count = #self.rows + 1

				local spacer
				local previous = self.rows[#self.rows]
				if previous and previous.group ~= group then
					spacer = Factory.new("Frame", {
						Name = "GroupGap",
						Size = UDim2.new(1, 0, 0, 10),
						BackgroundTransparency = 1,
						LayoutOrder = count * 2 - 1,
						Parent = self.list,
					})
				end

				local button = navigationRow(self.list, page.id, count * 2)

				local iconSpec = options.Icon or "circle"
				if type(iconSpec) == "string" then
					iconSpec = { Icon = iconSpec, Color = "TextSecondary" }
				end
				local icon = Icons.create(iconSpec, ICON, {
					Size = UDim2.fromOffset(ICON, ICON),
					LayoutOrder = 1,
					Parent = button,
				})

				local label = Factory.text({
					Text = options.Title,
					Typography = "Navigation",
					Size = UDim2.new(0, 0, 1, 0),
					LayoutOrder = 2,
					Parent = button,
				}, { Factory.fill() })

				local row = {
					page = page,
					group = group,
					button = button,
					label = label,
					icon = icon,
					spacer = spacer,
				}
				self:_setBadge(row, options.Badge)

				self.cleanup:connect(button.MouseEnter, function()
					if self.selected ~= page then
						Animations.tween(button, { BackgroundTransparency = 0.7 }, Theme.Motion.Hover)
					end
				end)
				self.cleanup:connect(button.MouseLeave, function()
					if self.selected ~= page then
						Animations.tween(button, { BackgroundTransparency = 1 }, Theme.Motion.Hover)
					end
				end)
				self.cleanup:connect(button.Activated, function()
					self.window:SelectPage(page.id)
				end)

				table.insert(self.rows, row)
				return row
			end

			function Sidebar:_setBadge(row, text: string?)
				if row.badge then
					row.badge:Destroy()
					row.badge = nil
				end
				if text then
					row.badge = Display.badge(text)
					row.badge.Size = UDim2.fromOffset(0, 18)
					row.badge.BackgroundTransparency = 0.25
					Theme.bind(row.badge, { BackgroundColor3 = "SurfaceHover" })
					row.badge:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0, 4)
					local padding = row.badge:FindFirstChildOfClass("UIPadding")
					padding.PaddingLeft = UDim.new(0, 5)
					padding.PaddingRight = UDim.new(0, 5)
					row.badge.Label.TextXAlignment = Enum.TextXAlignment.Center
					Factory.new("UISizeConstraint", { MinSize = Vector2.new(22, 18), Parent = row.badge })
					row.badge.LayoutOrder = 3
					row.badge.Parent = row.button
				end
			end

			function Sidebar:updatePage(page)
				for _, row in self.rows do
					if row.page == page then
						row.label.Text = page.options.Title
						self:_setBadge(row, page.options.Badge)
					end
				end
			end

			function Sidebar:removePage(page)
				for i, row in self.rows do
					if row.page == page then
						row.button:Destroy()
						if row.spacer then
							row.spacer:Destroy()
						end
						table.remove(self.rows, i)
						break
					end
				end
				task.defer(function()
					self:_placePill(false)
				end)
			end

			function Sidebar:relayout()
				self:_placePill(false)
			end

			function Sidebar:_selectedRow()
				for _, row in self.rows do
					if row.page == self.selected then
						return row
					end
				end
				return nil
			end

			function Sidebar:_placePill(animate: boolean)
				if self.window.destroyed or not self.Instance.Parent then
					return
				end
				local row = self:_selectedRow()
				local pill = self.pill
				if not row or not row.button.Visible then
					pill.Visible = false
					return
				end
				local scale = self.Instance.AbsoluteSize.X / self.Instance.Size.X.Offset
				if scale <= 0 then
					return
				end
				local offset = (row.button.AbsolutePosition - self.pillLayer.AbsolutePosition) / scale
				pill.Size = UDim2.fromOffset(math.round(row.button.AbsoluteSize.X / scale), ROW)
				local goal = UDim2.fromOffset(math.round(offset.X), math.round(offset.Y))
				if animate and pill.Visible then
					Animations.tween(pill, { Position = goal }, Theme.Motion.Page, Enum.EasingStyle.Quint)
				else
					Animations.tween(pill, { Position = goal })
				end
				pill.Visible = true
			end

			function Sidebar:select(page)
				self.selected = page
				self:_renderProfile()
				for _, row in self.rows do
					local active = row.page == page
					Animations.tween(row.button, { BackgroundTransparency = 1 }, Theme.Motion.Hover)
					Theme.bind(row.label, { TextColor3 = if active then "TextPrimary" else "TextSecondary" })
					if row.icon:IsA("TextLabel") and type(row.page.options.Icon) ~= "table" then
						Theme.bind(row.icon, { TextColor3 = if active then "TextPrimary" else "TextSecondary" })
					end
				end
				task.defer(function()
					self:_placePill(true)
				end)
			end

			-- Typing searches pages, cards and controls; results replace the nav list until cleared.
			function Sidebar:_filter(text: string)
				for _, result in self.resultRows or {} do
					result:Destroy()
				end
				self.resultRows = {}
				self.results = {}
				self.resultIndex = 0

				local searching = string.gsub(text, "%s", "") ~= ""
				for _, row in self.rows do
					row.button.Visible = not searching
					if row.spacer then
						row.spacer.Visible = not searching
					end
				end
				self.noResults.Visible = false
				if not searching then
					task.defer(function()
						self:_placePill(false)
					end)
					return
				end
				self.pill.Visible = false

				self.window:_buildAll()
				local results = self.window.ctx.registry:search(text, 30)
				self.results = results
				self.noResults.Visible = #results == 0

				for i, entry in results do
					local button = navigationRow(self.list, "SearchResult", 1000 + i)
					Icons.create(Icons.spec(entry.icon), ICON, {
						Size = UDim2.fromOffset(ICON, ICON),
						LayoutOrder = 1,
						Parent = button,
					})
					local text = Factory.new("Frame", {
						Size = UDim2.fromScale(0, 1),
						BackgroundTransparency = 1,
						LayoutOrder = 2,
						Parent = button,
					}, {
						Factory.fill(),
						Factory.list(0, false, { VerticalAlignment = Enum.VerticalAlignment.Center }),
					})
					Factory.text({
						Text = entry.title,
						Size = UDim2.new(1, 0, 0, 20),
						Typography = "Feature",
						Parent = text,
					})
					Factory.text({
						Text = entry.subtitle or "",
						Size = UDim2.new(1, 0, 0, 14),
						Typography = "Hint",
						LayoutOrder = 2,
						Parent = text,
						Theme = { TextColor3 = "TextMuted" },
					})
					button.MouseEnter:Connect(function()
						self:_highlight(i)
					end)
					button.Activated:Connect(function()
						entry.activate()
						self.query.Text = ""
					end)
					self.resultRows[i] = button
				end
				self:_highlight(1)
			end

			function Sidebar:_highlight(index: number)
				self.resultIndex = index
				for i, row in self.resultRows or {} do
					row.BackgroundTransparency = if i == index then 0.3 else 1
				end
			end

			function Sidebar:moveResult(step: number): boolean
				if not self.query:IsFocused() or #self.results == 0 then
					return false
				end
				self:_highlight(math.clamp(self.resultIndex + step, 1, #self.results))
				return true
			end

			function Sidebar:setIdentity(title: string?, subtitle: string?)
				-- Keep the legacy setter callable without replacing Roblox account identity.
				local data = Account.presentation(self.window)
				self.titleLabel.Text, self.subtitleLabel.Text = data.title, data.subtitle
			end

			function Sidebar:Destroy()
				self.cleanup:clean()
			end

			return Sidebar
		end

		-- Window/Window
		loaders[nodes["Window/Window"]] = function(script, require)
			local Players = game:GetService("Players")
			local UserInputService = game:GetService("UserInputService")

			local Library = script.Parent.Parent
			local Core = Library.Core
			local Theme = require(Core.Theme)
			local Factory = require(Core.Factory)
			local Animations = require(Core.Animations)
			local Cleanup = require(Core.Cleanup)
			local Icons = require(Core.Icons)
			local Input = require(Core.Input)
			local Store = require(Core.Store)
			local Registry = require(Core.Registry)
			local Util = require(Core.Util)
			local Blur = require(Core.Blur)
			local PopupManager = require(Library.Overlays.PopupManager)
			local Notifications = require(Library.Overlays.Notifications)
			local CommandPalette = require(Library.Overlays.CommandPalette)
			local Dialog = require(Library.Overlays.Dialog)
			local Display = require(Library.Components.Display)
			local Sidebar = require(script.Parent.Sidebar)
			local Account = require(script.Parent.Account)
			local Page = require(script.Parent.Page)
			local DragResize = require(script.Parent.DragResize)
			local MobileLauncher = require(script.Parent.MobileLauncher)

			local HEADER = 48
			local MARGIN = 12
			local NARROW = 680
			local MIN_SCALE = 0.95

			local Window = {}
			Window.__index = Window

			export type Options = {
				Title: string?,
				Subtitle: string?,
				Icon: any?,
				AnimatedIcon: { [string]: any }?,
				Account: Account.Options?,
				Theme: string?,
				Size: UDim2?,
				MinSize: Vector2?,
				ToggleKey: Enum.KeyCode?,
				MaximizeKey: Enum.KeyCode?, -- Ctrl+Shift+key; Unknown disables the recovery shortcut.
				Resizable: boolean?,
				Draggable: boolean?,
				MobileTouchDrag: boolean?,
				MobileToggleButton: boolean?,
				MobileTogglePosition: "Left" | "Right"?,
				Maximizable: boolean?,
				Scale: number?,
				AutoScale: boolean?,
				BlurEnabled: boolean?,
				BlurSize: number?,
				BlurTweenTime: number?,
				Acrylic: boolean?,
				BackgroundTransparency: number?,
				ReducedMotion: boolean?,
				Persistence: Store.Adapter?,
				SearchPlaceholder: string?,
				PalettePreserveQuery: boolean?,
				Parent: Instance?,
				DisplayOrder: number?,
			}

			function Window.new(options: Options)
				options = Util.merge({
					Subtitle = "Account",
					Resizable = true,
					Draggable = true,
					MobileTouchDrag = true,
					MobileToggleButton = true,
					MobileTogglePosition = "Right",
					Maximizable = true,
					ToggleKey = Enum.KeyCode.RightShift,
					AutoScale = true,
					BlurEnabled = true,
					BlurSize = 14,
					BlurTweenTime = 0.18,
					Acrylic = true,
					BackgroundTransparency = 0.1,
				}, options)
				local account = Account.resolve(options)
				for _, key in { "MobileTouchDrag", "MobileToggleButton" } do
					assert(type(options[key]) == "boolean", `{key} must be a boolean`)
				end
				assert(
					options.MobileTogglePosition == "Left" or options.MobileTogglePosition == "Right",
					"MobileTogglePosition must be Left or Right"
				)
				options.MaximizeKey = options.MaximizeKey
					or (if options.ToggleKey == Enum.KeyCode.M then Enum.KeyCode.F10 else Enum.KeyCode.M)
				assert(
					typeof(options.MaximizeKey) == "EnumItem" and options.MaximizeKey.EnumType == Enum.KeyCode,
					"MaximizeKey must be a KeyCode"
				)
				assert(
					options.MaximizeKey == Enum.KeyCode.Unknown
						or (options.MaximizeKey ~= options.ToggleKey and options.MaximizeKey ~= Enum.KeyCode.K),
					"MaximizeKey conflicts with an existing window shortcut"
				)
				for _, key in { "Scale", "BlurSize", "BlurTweenTime", "BackgroundTransparency" } do
					local value = options[key]
					assert(
						value == nil or (type(value) == "number" and value == value and math.abs(value) < math.huge),
						`{key} must be a finite number`
					)
				end
				options.Scale = math.clamp(options.Scale or 1, 0.6, 1.5)
				options.BackgroundTransparency = math.clamp(options.BackgroundTransparency, 0, 1)

				if options.Theme then
					Theme.set(options.Theme)
				end
				if options.ReducedMotion ~= nil then
					Animations.reducedMotion = options.ReducedMotion
				end

				local requested = options.Size or UDim2.fromOffset(860, 520)
				local self = setmetatable({
					options = options,
					account = account,
					cleanup = Cleanup.new(),
					pages = {},
					pageOrder = {},
					history = {},
					historyIndex = 0,
					size = Vector2.new(requested.X.Offset, requested.Y.Offset),
					minSize = options.MinSize or Vector2.new(720, 440),
					scale = 1,
					visible = false,
					minimized = false,
					maximized = false,
					narrow = false,
					toggleKey = options.ToggleKey,
				}, Window)
				local store = Store.new(options.Persistence)
				Account.initialize(self, store)
				local identity = Account.presentation(self)
				options.Title, options.Subtitle = identity.title, identity.subtitle

				local parent = options.Parent
				if not parent then
					local player = Players.LocalPlayer
					assert(player, "CreateWindow must run on the client (LocalScript) or pass Parent")
					parent = player:WaitForChild("PlayerGui")
				end

				self.gui = self.cleanup:add(Factory.new("ScreenGui", {
					Name = "MacUI",
					ResetOnSpawn = false,
					ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
					ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
					DisplayOrder = options.DisplayOrder or 50,
					Parent = parent,
				}))
				self.safeArea = Factory.new("Frame", {
					Name = "SafeArea",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Parent = self.gui,
				})

				local registry = Registry.new()
				self.popups = self.cleanup:add(PopupManager.new(self.gui))
				self.notifications = self.cleanup:add(Notifications.new(self.gui))
				self.ctx = {
					store = store,
					registry = registry,
					popups = self.popups,
					scale = function()
						return self.scale
					end,
					notify = function(n)
						return self:Notify(n)
					end,
					isReserved = function(key)
						if key == self.toggleKey then
							return "the window toggle"
						end
						if key == self.options.MaximizeKey then
							return "the window maximize shortcut"
						end
						return nil
					end,
				}
				self.Flags = store.values

				self:_buildFrame()
				self.palette = self.cleanup:add(CommandPalette.new(self))
				self:_bindInput()

				self.cleanup:connect(self.safeArea:GetPropertyChangedSignal("AbsoluteSize"), function()
					self:_apply(false)
				end)
				self.position = Vector2.zero
				self:_apply(false)
				local actual = self.size * self.scale
				self.position = (self.safeArea.AbsoluteSize - actual) / 2
				self:_apply(false)
				self.cleanup:add(function()
					Blur.release(self, 0)
				end)
				if options.MobileToggleButton then
					self.mobileLauncher = self.cleanup:add(MobileLauncher.new(self))
				end
				self:Show()
				if account.enabled then
					self:AddPage({
						Id = "account",
						Title = "Account",
						Icon = "person",
						Sidebar = false,
						Keywords = "profile username user",
						Build = Account.build,
					})
				end
				Account.loadThumbnail(self)

				return self
			end

			-- The fade group is temporary; the settled window renders directly beside its bounded shadow.
			function Window:_buildFrame()
				local options = self.options
				local radius = Theme.get("RadiusWindow")
				local alpha = if options.Acrylic then options.BackgroundTransparency else 0

				self.root = Factory.new("Frame", {
					Name = "WindowRoot",
					BackgroundTransparency = 1,
					Visible = false,
					Parent = self.safeArea,
				})
				self.uiScale = Factory.new("UIScale", { Parent = self.root })
				self.fade = Factory.new("CanvasGroup", {
					Name = "Fade",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					GroupTransparency = 1,
					ClipsDescendants = true,
					ZIndex = 2,
					Parent = self.root,
				}, { Factory.corner(radius) })

				self.shadow = Factory.new("CanvasGroup", {
					Name = "Shadow",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 6),
					Size = UDim2.new(1, 32, 1, 32),
					BackgroundTransparency = 1,
					GroupTransparency = 1,
					Parent = self.root,
				})
				for _, inset in { 0, 6, 12 } do
					Factory.new("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
						BackgroundTransparency = 0.96,
						Parent = self.shadow,
						Theme = { BackgroundColor3 = "Shadow" },
					}, { Factory.corner(radius + 16 - inset) })
				end

				self.frame = Factory.new("Frame", {
					Name = "Window",
					Active = true,
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = alpha,
					ClipsDescendants = true,
					ZIndex = 2,
					Parent = self.fade,
					Theme = { BackgroundColor3 = "Background" },
				}, {
					Factory.corner(radius),
					Factory.stroke("Border", 0.15),
				})

				if options.Acrylic then
					Factory.new("Frame", {
						Name = "Sheen",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 0.965,
						ZIndex = 0,
						Parent = self.frame,
						Theme = { BackgroundColor3 = "Sheen" },
					}, {
						Factory.corner(radius),
						Factory.new("UIGradient", {
							Rotation = 90,
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0),
								NumberSequenceKeypoint.new(0.35, 0.85),
								NumberSequenceKeypoint.new(1, 1),
							}),
						}),
					})
				end

				self.sidebar = self.cleanup:add(Sidebar.new(self, self.frame, {
					Width = 232,
					Transparency = if options.Acrylic then math.max(0, alpha - 0.1) else 0,
					Title = options.Title,
					Subtitle = options.Subtitle,
					Icon = options.Icon,
					AnimatedIcon = options.AnimatedIcon,
				}))

				local main = Factory.new("Frame", {
					Name = "Main",
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Parent = self.frame,
				})
				self.main = main

				local header = Factory.new("Frame", {
					Name = "Header",
					Size = UDim2.new(1, 0, 0, HEADER),
					BackgroundTransparency = 1,
					Active = true,
					Parent = main,
				}, {
					Factory.padding(0, 12),
					Factory.list(8, true, { HorizontalFlex = Enum.UIFlexAlignment.None }),
				})
				self.header = header

				self.menuButton = Display.iconButton("sidebar", 28, function()
					self:_toggleDrawer()
				end)
				self.menuButton.LayoutOrder = 0
				self.menuButton.Visible = false
				self.menuButton.Parent = header

				local nav = Factory.new("Frame", {
					Name = "History",
					Size = UDim2.fromOffset(65, 28),
					LayoutOrder = 1,
					Parent = header,
					Theme = { BackgroundColor3 = "Sidebar" },
				}, {
					Factory.corner(14),
					Factory.stroke("Border", 0.35),
				})
				local function navButton(icon: string, x: number)
					local button = Factory.button({
						Position = UDim2.fromOffset(x, 0),
						Size = UDim2.fromOffset(32, 28),
						Parent = nav,
					})
					local glyph = Icons.create({ Icon = icon, Color = "TextPrimary" }, 18, {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Parent = button,
					})
					return button, glyph
				end
				local back, backGlyph = navButton("chevron-large-left", 0)
				local forward, forwardGlyph = navButton("chevron-large-right", 33)
				Factory.new("Frame", {
					Position = UDim2.new(0, 32, 0.25, 0),
					Size = UDim2.new(0, 1, 0.5, 0),
					Parent = nav,
					Theme = { BackgroundColor3 = "Border" },
				})
				self.backGlyph, self.forwardGlyph = backGlyph, forwardGlyph
				self.cleanup:connect(back.Activated, function()
					self:Back()
				end)
				self.cleanup:connect(forward.Activated, function()
					self:Forward()
				end)

				local titles = Factory.new("Frame", {
					Name = "HeaderDragRegion",
					Size = UDim2.fromScale(0, 1),
					BackgroundTransparency = 1,
					Active = true,
					LayoutOrder = 2,
					Parent = header,
				}, {
					Factory.fill(),
					Factory.list(10, true),
				})
				self.titleLabel = Factory.text({
					Text = "",
					Typography = "WindowTitle",
					Size = UDim2.fromOffset(0, 24),
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = 1,
					Parent = titles,
				}, { Factory.new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Shrink }) })
				self.descriptionLabel = Factory.text({
					Text = "",
					Typography = "Description",
					Size = UDim2.new(0, 0, 0, 20),
					LayoutOrder = 2,
					Parent = titles,
					Theme = { TextColor3 = "TextMuted" },
				}, { Factory.fill() })

				self.headerActions = Factory.new("Frame", {
					Size = UDim2.fromScale(0, 1),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Parent = header,
				}, { Factory.list(4, true) })

				local searchButton = Display.iconButton("magnifying-glass", 28, function()
					self.palette:open()
				end)
				searchButton.LayoutOrder = 100
				searchButton.Parent = self.headerActions
				self.cleanup:add(Display.tooltip(self.popups, searchButton, "Search everything  (Ctrl+K)"))
				self.optionsButton = Display.iconButton("three-dots-horizontal", 28, function()
					self:_toggleOptions()
				end)
				self.optionsButton.Name = "Options"
				self.optionsButton.LayoutOrder = 101
				self.optionsButton.Parent = self.headerActions

				self.body = Factory.new("Frame", {
					Name = "Body",
					Position = UDim2.fromOffset(0, HEADER),
					Size = UDim2.new(1, 0, 1, -HEADER),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Parent = main,
				})

				self.emptyState = Factory.text({
					Text = "Add a page with Window:AddPage() to get started.",
					TextXAlignment = Enum.TextXAlignment.Center,
					Size = UDim2.fromScale(1, 1),
					Parent = self.body,
					Theme = { TextColor3 = "TextMuted" },
				})

				self.scrim = Factory.button({
					Name = "DrawerScrim",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Visible = false,
					ZIndex = 5,
					Parent = self.frame,
					Theme = { BackgroundColor3 = "Scrim" },
				})
				self.cleanup:connect(self.scrim.Activated, function()
					self:_toggleDrawer(false)
				end)

				self.dragController = DragResize.drag(self)
				if options.Resizable then
					self.grip = DragResize.resize(self, self.frame)
				end
				self:_updateHistoryButtons()
			end

			function Window:_toggleOptions()
				if self.optionsPopup then
					self.optionsPopup.close()
					return
				end
				local cleanup = Cleanup.new()
				local menu = PopupManager.surface(212, { Name = "WindowOptions" })
				Factory.padding(4).Parent = menu
				local row = Factory.button({
					Name = "AutoCensorUser",
					Size = UDim2.fromOffset(204, 32),
					Parent = menu,
					Theme = { BackgroundColor3 = "SurfaceHover" },
				}, { Factory.corner(6) })
				local check = Icons.create("check", 16, { Position = UDim2.fromOffset(8, 8), Parent = row })
				Factory.text({
					Text = "Auto Censor User",
					Position = UDim2.fromOffset(32, 0),
					Size = UDim2.new(1, -40, 1, 0),
					Parent = row,
				})
				cleanup:add(self:ObserveAccount(function(data)
					check.Visible = data.censored
					row:SetAttribute("Checked", data.censored)
				end))
				cleanup:connect(row.MouseEnter, function()
					Animations.tween(row, { BackgroundTransparency = 0 }, Theme.Motion.Hover)
				end)
				cleanup:connect(row.MouseLeave, function()
					Animations.tween(row, { BackgroundTransparency = 1 }, Theme.Motion.Hover)
				end)
				cleanup:connect(row.Activated, function()
					self:SetAutoCensorUser(not self:GetAccountPresentation().censored)
				end)
				self.optionsPopup = self.popups:open({
					content = menu,
					anchor = self.optionsButton,
					align = "right",
					onClose = function()
						self.optionsPopup = nil
						cleanup:clean()
					end,
				})
			end

			function Window:GetAccountPresentation()
				return Account.presentation(self)
			end

			-- Immediately delivers current presentation; returns an unsubscribe function.
			function Window:ObserveAccount(fn)
				assert(type(fn) == "function", "ObserveAccount requires a callback")
				return Account.observe(self, fn)
			end

			function Window:SetAutoCensorUser(enabled: boolean)
				assert(type(enabled) == "boolean", "AutoCensorUser must be a boolean")
				self.ctx.store:set("AutoCensorUser", enabled)
			end

			function Window:_bindInput()
				self.cleanup:add(Input.listen(function(input, processed)
					local key = input.KeyCode
					if key == self.toggleKey and not processed and self.toggleKey ~= Enum.KeyCode.Unknown then
						self:Toggle()
						return true
					end
					if not self.visible then
						return false
					end
					if
						self.options.Maximizable
						and key == self.options.MaximizeKey
						and key ~= Enum.KeyCode.Unknown
						and not processed
						and not UserInputService:GetFocusedTextBox()
						and Input.ctrlDown()
						and (
							UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
							or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
						)
					then
						self:ToggleMaximize()
						return true
					end
					if self.palette:handleInput(input) then
						return true
					end
					if key == Enum.KeyCode.K and Input.ctrlDown() then
						self.palette:toggle()
						return true
					end
					if key == Enum.KeyCode.Down and self.sidebar:moveResult(1) then
						return true
					end
					if key == Enum.KeyCode.Up and self.sidebar:moveResult(-1) then
						return true
					end
					return false
				end))
				self.cleanup:add(function()
					if self.stopDrag then
						self.stopDrag()
					end
				end)
			end

			function Window:_fitScale(vp: Vector2): number
				if not self.options.AutoScale then
					return self.options.Scale
				end
				if UserInputService.TouchEnabled and math.min(vp.X, vp.Y) <= 600 then
					-- Fit the requested size, not the resized window: free resize must still change its visible size.
					local requested = self.options.Size or UDim2.fromOffset(860, 520)
					return math.min(
						self.options.Scale,
						0.7,
						(vp.X - MARGIN * 2) / math.max(requested.X.Offset, self.minSize.X),
						(vp.Y - MARGIN * 2) / math.max(requested.Y.Offset, self.minSize.Y)
					)
				end
				local fit = math.min((vp.X - MARGIN * 2) / self.minSize.X, (vp.Y - MARGIN * 2) / self.minSize.Y)
				return math.min(self.options.Scale, math.max(MIN_SCALE, fit))
			end

			function Window:_apply(animate: boolean?)
				if self.destroyed then
					return
				end
				local vp = self.safeArea.AbsoluteSize
				if vp.X <= MARGIN * 2 or vp.Y <= MARGIN * 2 then
					return
				end
				local scale = self:_fitScale(vp)
				self.scale = scale
				local room =
					Vector2.new(math.floor((vp.X - MARGIN * 2) / scale), math.floor((vp.Y - MARGIN * 2) / scale))

				if self.maximized then
					self.size = room
					self.position = Vector2.new(MARGIN, MARGIN)
				else
					self.size = Vector2.new(
						math.round(math.max(self.size.X, self.minSize.X)),
						math.round(math.max(self.size.Y, self.minSize.Y))
					)
				end

				local height = if self.minimized then HEADER else self.size.Y

				Animations.tween(self.uiScale, { Scale = scale })
				self.root.Position = UDim2.fromOffset(math.round(self.position.X), math.round(self.position.Y))
				local target = UDim2.fromOffset(math.round(self.size.X), math.round(height))
				Animations.tween(self.root, { Size = target }, if animate then Theme.Motion.Minimize else nil)

				local narrow = self.size.X < NARROW
				local sidebarWidth = if narrow
					then math.min(232, self.size.X)
					else math.clamp(math.round(self.size.X * 0.27), 220, 240)
				self.sidebarWidth = sidebarWidth
				self.sidebar.Instance.Size = UDim2.new(0, sidebarWidth, 1, 0)
				if narrow ~= self.narrow then
					self.narrow = narrow
					self.drawerOpen = false
				end
				self:_layoutDrawer()
				self.sidebar:relayout()

				self.popups:setScale(scale)
				self.notifications:setScale(scale)
				if self.grip then
					self.grip.Visible = self.options.Resizable and not self.minimized and not self.maximized
				end
			end

			function Window:_layoutDrawer()
				local sidebar = self.sidebar.Instance
				local controls = self.sidebar.windowControls
				local controlsParent = if self.narrow then self.header else sidebar
				if controls.Parent ~= controlsParent then
					controls.Parent = controlsParent
					controls.LayoutOrder = -1
					controls.Position = UDim2.fromOffset(16, 15)
				end
				self.menuButton.Visible = self.narrow
				if self.narrow then
					self.main.Position = UDim2.new()
					self.main.Size = UDim2.fromScale(1, 1)
					sidebar.ZIndex = 6
					self.scrim.Visible = self.drawerOpen == true
					Animations.tween(
						self.scrim,
						{ BackgroundTransparency = if self.drawerOpen then 0.5 else 1 },
						Theme.Motion.Select
					)
					Animations.tween(sidebar, {
						Position = UDim2.fromOffset(if self.drawerOpen then 0 else -self.sidebarWidth - 2, 0),
					}, Theme.Motion.Expand)
				else
					self.scrim.Visible = false
					sidebar.ZIndex = 1
					sidebar.Position = UDim2.new()
					self.main.Position = UDim2.fromOffset(self.sidebarWidth, 0)
					self.main.Size = UDim2.new(1, -self.sidebarWidth, 1, 0)
				end
			end

			function Window:_toggleDrawer(open: boolean?)
				if not self.narrow then
					return
				end
				if open == nil then
					open = not self.drawerOpen
				end
				self.drawerOpen = open
				self:_layoutDrawer()
			end

			-- Pages

			function Window:AddPage(options: Page.Options)
				if self.ctx.buildYield then self.ctx.buildYield("page " .. tostring(options and options.Title or "")) end
				assert(type(options) == "table" and options.Title, "AddPage needs a Title")
				local id = options.Id or string.lower(options.Title)
				assert(self.pages[id] == nil, `Page id "{id}" already exists`)
				local page = Page.new(self, options)
				self.pages[page.id] = page
				table.insert(self.pageOrder, page)
				if options.Sidebar ~= false then
					self.sidebar:addPage(page)
				end
				if not self.current and options.Sidebar ~= false then
					self:SelectPage(page.id)
				end
				return page
			end

			function Window:GetPage(id: string)
				return self.pages[id]
			end

			function Window:_pageChanged(page)
				self.sidebar:updatePage(page)
				if self.current == page then
					self.titleLabel.Text = page.options.Title
				end
			end

			function Window:_removePage(page)
				self.pages[page.id] = nil
				local index = table.find(self.pageOrder, page)
				if index then
					table.remove(self.pageOrder, index)
				end
				self.sidebar:removePage(page)
				for i = #self.history, 1, -1 do
					if self.history[i] == page.id then
						table.remove(self.history, i)
						if self.historyIndex >= i then
							self.historyIndex -= 1
						end
					end
				end
				if self.current == page then
					self.current = nil
					local first = self.pageOrder[1]
					if first then
						self:SelectPage(first.id, true)
					else
						self.titleLabel.Text = ""
						self.emptyState.Visible = true
					end
				end
				self:_updateHistoryButtons()
			end

			function Window:_buildAll()
				for _, page in self.pageOrder do
					page:EnsureBuilt()
				end
			end

			function Window:SelectPage(id: string, skipHistory: boolean?)
				local page = self.pages[id]
				if not page then
					warn(`[MacUI] no page "{id}"`)
					return
				end
				if self.current ~= page then
					self.emptyState.Visible = false
					if self.current then
						self.current:_show(false)
					end
					self.current = page
					page:_show(true)
					self.titleLabel.Text = page.options.Title
					self.descriptionLabel.Text = page.options.Description or ""
					for _, label in { self.titleLabel, self.descriptionLabel } do
						Animations.tween(label, { TextTransparency = if Animations.reducedMotion then 0 else 1 })
						Animations.tween(label, { TextTransparency = 0 }, Theme.Motion.Page)
					end
					self.sidebar:select(page)
					self.popups:closeAll()

					if not skipHistory then
						for i = #self.history, self.historyIndex + 1, -1 do
							self.history[i] = nil
						end
						table.insert(self.history, id)
						if #self.history > 50 then
							table.remove(self.history, 1)
						end
						self.historyIndex = #self.history
					end
					self:_updateHistoryButtons()
				end
				if self.narrow then
					self:_toggleDrawer(false)
				end
			end

			function Window:_updateHistoryButtons()
				Theme.bind(
					self.backGlyph,
					{ TextColor3 = if self.historyIndex > 1 then "TextPrimary" else "TextMuted" }
				)
				Theme.bind(
					self.forwardGlyph,
					{ TextColor3 = if self.historyIndex < #self.history then "TextPrimary" else "TextMuted" }
				)
			end

			function Window:Back()
				if self.historyIndex > 1 then
					self.historyIndex -= 1
					self:SelectPage(self.history[self.historyIndex], true)
				end
			end

			function Window:Forward()
				if self.historyIndex < #self.history then
					self.historyIndex += 1
					self:SelectPage(self.history[self.historyIndex], true)
				end
			end

			-- Visibility

			function Window:_syncLoadingAnimations()
				for _, page in self.pageOrder do
					for _, section in page.sections do
						for _, card in section.cards do
							if card.spinner.Visible then
								card:SetLoading(true)
							end
						end
					end
				end
			end

			function Window:_setBlur(visible: boolean)
				if visible and self.options.BlurEnabled then
					Blur.set(self, self.options.BlurSize, self.options.BlurTweenTime)
				else
					Blur.release(self, self.options.BlurTweenTime)
				end
			end

			function Window:Show()
				if self.destroyed or self.visible then
					return
				end
				self.visible = true
				self:_syncLoadingAnimations()
				if self.mobileLauncher then
					self.mobileLauncher:refresh()
				end
				self.root.Visible = true
				self:_apply(false)
				self.frame.Parent = self.fade
				local tween = Animations.tween(self.fade, { GroupTransparency = 0 }, Theme.Motion.Popup)
				-- Render text directly once the fade ends; persistent CanvasGroups resample glyphs.
				local function finish()
					if not self.destroyed and self.visible then
						self.frame.Parent = self.root
					end
				end
				if tween then
					tween.Completed:Once(function(state)
						if state == Enum.PlaybackState.Completed then
							finish()
						end
					end)
				else
					finish()
				end
				Animations.tween(self.shadow, { GroupTransparency = 0 }, Theme.Motion.Popup)
				self:_setBlur(true)
			end

			function Window:Hide()
				if self.destroyed or not self.visible then
					return
				end
				self.visible = false
				self:_syncLoadingAnimations()
				if self.mobileLauncher then
					self.mobileLauncher:refresh()
				end
				if self.stopDrag then
					self.stopDrag()
				end
				self.popups:closeAll()
				self:_setBlur(false)
				self.frame.Parent = self.fade
				local tween = Animations.tween(self.fade, { GroupTransparency = 1 }, Theme.Motion.Popup)
				Animations.tween(self.shadow, { GroupTransparency = 1 }, Theme.Motion.Popup)
				local function finish()
					if not self.destroyed and not self.visible then
						self.root.Visible = false
					end
				end
				if tween then
					tween.Completed:Once(function(state)
						if state == Enum.PlaybackState.Completed then
							finish()
						end
					end)
				else
					finish()
				end
			end

			function Window:Toggle()
				if self.visible then
					self:Hide()
				else
					self:Show()
				end
			end

			function Window:IsVisible(): boolean
				return self.visible
			end

			function Window:SetMinimized(minimized: boolean)
				assert(type(minimized) == "boolean", "SetMinimized needs a boolean")
				if self.destroyed or self.minimized == minimized then
					return
				end
				if self.stopDrag then
					self.stopDrag()
				end
				self.minimized = minimized
				self.popups:closeAll()
				self:_apply(true)
			end

			function Window:SetMaximized(maximized: boolean)
				assert(type(maximized) == "boolean", "SetMaximized needs a boolean")
				if self.destroyed or (self.maximized == maximized and not self.minimized) then
					return
				end
				if self.stopDrag then
					self.stopDrag()
				end
				if maximized and not self.maximized then
					self.restore = { size = self.size, position = self.position }
				elseif not maximized and self.maximized and self.restore then
					self.size, self.position = self.restore.size, self.restore.position
				end
				self.maximized = maximized
				self.minimized = false
				self:_apply(false)
			end

			function Window:Maximize()
				self:SetMaximized(true)
			end

			function Window:Restore()
				self:SetMaximized(false)
			end

			function Window:ToggleMaximize()
				self:SetMaximized(not self.maximized)
			end

			function Window:SetToggleKey(key: Enum.KeyCode)
				self.toggleKey = key
			end

			function Window:SetTitle(title: string?, subtitle: string?)
				self.sidebar:setIdentity(title, subtitle)
			end

			function Window:SetTheme(name: string)
				Theme.set(name)
			end

			function Window:SetReducedMotion(reduced: boolean)
				Animations.reducedMotion = reduced
			end

			function Window:SetScale(scale: number)
				assert(
					type(scale) == "number" and scale == scale and math.abs(scale) < math.huge,
					"Scale must be a finite number"
				)
				self.options.Scale = math.clamp(scale, 0.6, 1.5)
				self:_apply(false)
			end

			-- Overlays

			function Window:Notify(options: Notifications.Options)
				return self.notifications:notify(options)
			end

			function Window:Confirm(options: Dialog.Options)
				return Dialog.confirm(self.popups, self.frame, options)
			end

			function Window:OpenCommandPalette(query: string?)
				self.palette:open(query)
			end

			function Window:AddHeaderAction(options: { Icon: string, Tooltip: string?, Callback: () -> () })
				local button = Display.iconButton(options.Icon, 30, options.Callback)
				button.Parent = self.headerActions
				if options.Tooltip then
					self.cleanup:add(Display.tooltip(self.popups, button, options.Tooltip))
				end
				return button
			end

			-- State

			function Window:GetFlag(id: string): any
				return self.ctx.store:get(id)
			end

			function Window:SetFlag(id: string, value: any)
				if id == "AutoCensorUser" then
					assert(type(value) == "boolean", "AutoCensorUser must be a boolean")
				end
				self.ctx.store:set(id, value)
			end

			function Window:OnFlagChanged(id: string, fn: (any, any) -> ()): () -> ()
				return self.ctx.store:observe(id, fn)
			end

			function Window:ExportConfig(): { [string]: any }
				return self.ctx.store:snapshot()
			end

			function Window:ImportConfig(data: { [string]: any })
				local store = self.ctx.store
				for id, raw in data do
					local current = store:get(id)
					local value = Store.decode(raw)
					if current ~= nil and typeof(value) == typeof(current) then
						store:set(id, value)
					end
				end
			end

			function Window:Destroy()
				if self.destroyed then
					return
				end
				self.destroyed = true
				for i = #self.pageOrder, 1, -1 do
					local page = self.pageOrder[i]
					for j = #page.sections, 1, -1 do
						page.sections[j]:Destroy()
					end
					page.cleanup:clean()
				end
				table.clear(self.pages)
				table.clear(self.pageOrder)
				self.cleanup:clean()
			end

			return Window
		end

		-- init
		loaders[nodes[""]] = function(script, require)
			local Theme = require(script.Core.Theme)
			local Animations = require(script.Core.Animations)
			local Icons = require(script.Core.Icons)
			local Window = require(script.Window.Window)
			local AnimatedImage = require(script.Components.AnimatedImage)

			local MacUI = {
				Name = "MacUI",
				Version = "1.0.0",
				Theme = Theme,
				Icons = Icons,
				AnimatedImage = AnimatedImage,
				UpdateLogs = require(script.Data.UpdateLogs),
			}

			function MacUI:CreateWindow(options: Window.Options?)
				return Window.new(options or {})
			end

			function MacUI:SetTheme(name: string)
				Theme.set(name)
			end

			function MacUI:RegisterTheme(name: string, tokens: { [string]: any })
				Theme.register(name, tokens)
			end

			function MacUI:SetReducedMotion(reduced: boolean)
				Animations.reducedMotion = reduced
			end

			return MacUI
		end
		local function load(module)
			if cache[module] ~= nil then
				return cache[module]
			end
			assert(loaders[module], "MacUI: unknown module")
			assert(not loading[module], "MacUI: circular module dependency")
			loading[module] = true
			local ok, value = pcall(loaders[module], module, load)
			loading[module] = nil
			if not ok then
				error("MacUI / " .. module.Name .. ": " .. tostring(value), 2)
			end
			cache[module] = value
			return value
		end
		local MacUI = load(nodes[""])
		MacUI.UnitSettings = load(nodes["Components/AutoPlayFeature/UnitSettingsStore"])
		local createWindow = MacUI.CreateWindow
		function MacUI:CreateWindow(options)
			options = table.clone(options or {})
			if not options.Parent and type(gethui) == "function" then
				local ok, parent = pcall(gethui)
				if ok and typeof(parent) == "Instance" then
					options.Parent = parent
				end
			end
			return createWindow(self, options)
		end
		return MacUI
	end)()

	-- Auto Play runtime. Kept separate from rendering so scheduling can be checked without Roblox UI.
	local function createAutoPlayRuntime(cfg, notify, save)
		local RS = game:GetService("ReplicatedStorage")
		local LP = Players.LocalPlayer
		local UserInputService = game:GetService("UserInputService")
		local self = {
			on = false,
			dead = false,
			rules = {},
			timers = {},
			attempts = {},
			upgradeAttempts = {},
			spots = {},
			statuses = {},
			version = 0,
		}
		local inv, units, levelData, levelMap, levelUnits
		local spots = self.spots
		local farms =
			{ bulma = true, bulma_battle = true, speedwagon = true, speedwagon_evolved = true, nami_evolved = true }
		local function finite(n)
			return type(n) == "number" and n == n and math.abs(n) < math.huge
		end
		local function val(parent, name, default)
			local item = parent and parent:FindFirstChild(name)
			return if item then item.Value else default
		end
		local function frame(text)
			assert(type(text) == "string", "Position missing")
			local nums = string.split(text, ",")
			assert(#nums == 12, "Invalid saved position")
			for i, n in nums do
				nums[i] = tonumber(n)
				assert(finite(nums[i]), "Invalid position component")
			end
			return CFrame.new(table.unpack(nums))
		end
		local function owned()
			if not inv then
				assert(RS:FindFirstChild("src"), "Waiting for game data")
				local loader = require(RS.src.Loader)
				units = require(RS.src.Data.Units)
				inv = loader.load_client_service(script, "ItemInventoryServiceClient")
			end
			assert(inv and inv.session and inv.session.collection, "Waiting for inventory")
			local session = inv and inv.session
			local collection = session and session.collection
			local profile = collection and collection.collection_profile_data
			assert(profile and type(profile.owned_units) == "table", "Waiting for inventory")
			return profile.owned_units
		end
		local function slots()
			local out = {}
			for _, unit in pairs(owned()) do
				local slot = tonumber(unit.equipped_slot)
				if slot and slot % 1 == 0 and slot >= 1 and slot <= 6 and units[unit.unit_id] then
					out[slot] = { uuid = unit.uuid, id = unit.unit_id, data = units[unit.unit_id], owned = unit }
				end
			end
			return out
		end
		local function match()
			local map, folder = workspace:FindFirstChild("_MAP_CONFIG"), workspace:FindFirstChild("_UNITS")
			assert(map and not val(map, "IsLobby", true) and folder, "Join a match first")
			return folder, map
		end
		local function level()
			local folder, map = match()
			if levelData and levelMap == map and levelUnits == folder then
				return levelData
			end
			local obj = map:FindFirstChild("GetLevelData")
			assert(obj, "Waiting for map data")
			local result = obj:InvokeServer()
			assert(type(result) == "table" and type(result.map) == "string", "Invalid map data")
			levelData, levelMap, levelUnits = result, map, folder
			return result
		end
		local function mine(unit)
			local stats = unit:FindFirstChild("_stats")
			return if stats and val(stats, "player") == LP then stats else nil
		end
		local function remote(name, ...)
			if
				self.dead
				or not self.on
				or self.paused
				or self.teamBusy
				or self.selecting
				or self.activeVersion ~= self.version
			then
				return false
			end
			local folder, map = match()
			if
				folder ~= self.folder
				or map ~= self.map
				or val(workspace, "_wave_num", 0) < self.wave
				or val(workspace:FindFirstChild("_DATA"), "GameFinished", false)
			then
				return false
			end
			local root = RS:FindFirstChild("endpoints")
			root = root and root:FindFirstChild("client_to_server")
			local event = root and root:FindFirstChild(name)
			assert(event and event:IsA("RemoteFunction"), "Missing remote: " .. name)
			local result = event:InvokeServer(...)
			assert(result ~= false, "Server rejected " .. name)
			return not self.dead and self.on
		end
		function self:Report(message)
			if self.lastError ~= message or os.clock() - (self.errorAt or 0) >= 15 then
				self.lastError, self.errorAt = message, os.clock()
				notify(message, true)
			end
		end
		function self:SetUnits(units)
			self.units = UI.UnitSettings.normalize(units)
			self.rules, self.byId = {}, {}
			table.clear(spots)
			for _, unit in self.units do
				self.byId[unit.UnitId] = unit
				for _, action in { "Place", "Upgrade" } do
					table.insert(self.rules, {
						StepId = unit.UnitId .. ":" .. action,
						UnitId = unit.UnitId,
						Action = action,
						Enabled = true,
						Count = unit.PlaceCap,
						TargetLevel = unit.UpgradeCap,
						FocusFarm = unit.FocusFarm,
						Wave = unit[action .. "Wave"],
						Delay = unit[action .. "Delay"],
					})
				end
			end
			local ordered = {}
			for _, rule in ipairs(self.rules) do
				if rule.Action == "Upgrade" and rule.FocusFarm then ordered[#ordered + 1] = rule end
			end
			for _, rule in ipairs(self.rules) do
				if not (rule.Action == "Upgrade" and rule.FocusFarm) then ordered[#ordered + 1] = rule end
			end
			self.rules = ordered
			self.version += 1
			self.timers, self.statuses, self.upgradeAttempts = {}, {}, {}
		end
		function self:SetPaused(paused)
			paused = paused == true
			if self.paused ~= paused then
				self.paused = paused
				self.version += 1
				if paused then
					self:CancelPick()
				end
			end
		end
		function self:EquipTeam(value)
			assert(type(value) == "string" and value:match("^[1-6]$"), "Invalid team")
			assert(not self.dead and not self.teamBusy, "Team switch unavailable")
			self.teamBusy = true
			self.version += 1
			self:CancelPick()
			local ok, err = pcall(function()
				local root = RS:FindFirstChild("endpoints")
				root = root and root:FindFirstChild("client_to_server")
				local event = root and root:FindFirstChild("load_team_loadout")
				assert(event and event:IsA("RemoteFunction"), "Missing remote: load_team_loadout")
				assert(event:InvokeServer(value) ~= false, "Server rejected load_team_loadout")
			end)
			self.version += 1
			self.teamBusy = false
			self.timers, self.attempts, self.upgradeAttempts = {}, {}, {}
			self.refreshAt = 0
			table.clear(spots)
			assert(ok, tostring(err))
		end
		function self:SetRunning(on)
			self.on = on == true
			self.version += 1
			self.timers = {}
			if not self.on then
				self:CancelPick()
			end
		end
		local function ray(pos, root, depth)
			if not root then
				return
			end
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { root }
			params.IgnoreWater = true
			return workspace:Raycast(pos, Vector3.new(0, -depth, 0), params)
		end

		local points = {
			namek = Vector3.new(-2943.1494140625, 91.80620574951172, -735.087890625),
			hill_namek = Vector3.new(-2948.95458984375, 94.41859436035156, -720.9224853515625),
			aot = Vector3.new(-3013.39966, 33.72612, -681.26825),
			hill_aot = Vector3.new(-2989.929931640625, 39.0062141418457, -725.5681762695312),
		}
		local function offset(n)
			if n == 0 then
				return Vector3.new(0, 0, 0)
			end

			local layer = math.ceil((math.sqrt(n + 1) - 1) / 2)
			local start = (2 * layer - 1) ^ 2 + 1
			local at, size = n + 1 - start, layer * 2
			local x, z
			if at < size then
				x, z = layer, -layer + at
			elseif at < size * 2 then
				x, z = layer - (at - size), layer
			elseif at < size * 3 then
				x, z = -layer, layer - (at - size * 2)
			else
				x, z = -layer + (at - size * 3), -layer
			end
			return Vector3.new(x, 0, z)
		end

		local function placement(info, key)
			local settings = self.byId and self.byId[info.uuid]
			local value = settings and settings[(key:gsub(" ", ""))]
			return if value ~= nil then value else cfg[key]
		end
		local function pathAt(lane, info)
			assert(lane, "Map path not ready.")
			local nodes, length = {}, 0
			for _, part in ipairs(lane:GetChildren()) do
				if part:IsA("BasePart") and tonumber(part.Name) then
					nodes[#nodes + 1] = part
				end
			end
			table.sort(nodes, function(a, b)
				return tonumber(a.Name) < tonumber(b.Name)
			end)
			assert(nodes[1], "Map path has no waypoints.")
			for i = 2, #nodes do
				length += (nodes[i].Position - nodes[i - 1].Position).Magnitude
			end
			local distance = length * placement(info, "Path Position") / 100
			for i = 2, #nodes do
				local a, b = nodes[i - 1].Position, nodes[i].Position
				local size = (b - a).Magnitude
				if size > 0 and distance <= size then
					return a:Lerp(b, distance / size)
				end
				distance -= size
			end
			return nodes[#nodes].Position
		end

		local function pathPoint(info)
			local bases = workspace:FindFirstChild("_BASES")
			local lanes = bases and bases:FindFirstChild("pve")
			lanes = lanes and lanes:FindFirstChild("LANES")
			assert(lanes, "Map path not ready.")
			local a, b = lanes:FindFirstChild("1"), lanes:FindFirstChild("2")
			if placement(info, "Path Target") == "Path 2" then
				return pathAt(b or a, info)
			end
			local point = pathAt(a or b, info)
			return placement(info, "Path Target") == "Between Paths" and a and b and point:Lerp(pathAt(b, info), 0.5)
				or point
		end

		local function skyPositionEnabled(data)
			if not cfg["Auto Position Sky Island"] or data.map ~= "skypiea" then return false end
			local mode = type(data._gamemode) == "string" and data._gamemode:lower() or ""
			local id = type(data.id) == "string" and data.id:lower() or ""
			local kind
			if type(data._dungeon) == "table" or data._dungeon == true or mode == "dungeon" then kind = "Dungeon"
			elseif (tonumber(data.floor_num) or 0) > 0 or mode == "infinite_tower" then kind = "Infinity Castle"
			elseif id == "summer2_event" or data.portal_group == "summer2" then kind = "Summer"
			elseif (tonumber(data._portal_depth) or 0) > 0 or (type(data.portal_group) == "string" and data.portal_group ~= "" and data.portal_group ~= "nil") or data._is_map_or_portal_level == true then kind = "Portal"
			else
				local challenge = data._challenge or data._challengename or data._is_challenge or data.is_challenge or data.challenge_uuid or data._challenge_uuid or data._is_daily_challenge or data.is_daily_challenge
				if mode:find("challenge", 1, true) or id:find("challenge", 1, true) or (challenge ~= nil and challenge ~= false and challenge ~= 0 and challenge ~= "" and challenge ~= "nil") then kind = "Challenge"
				elseif mode == "raid" then kind = "Raid"
				elseif mode == "infinite" or (mode == "" and (data.infinite == true or id:match("_infinite$"))) then kind = "Infinite"
				elseif mode == "story" or ((mode == "" or mode == "normal") and (tonumber(data.story_level_rank) or id:match("_level_%d+$"))) then kind = "Story"
				else kind = "Other" end
			end
			return type(cfg["Sky Island Modes"]) == "table" and table.find(cfg["Sky Island Modes"], kind) ~= nil
		end

		local function circlePlace(index, n, info)
			local data = level()
			local skyPosition = skyPositionEnabled(data)
			local hill = info.data.hill_unit or (skyPosition and info.data.hybrid_placement)
			local stored = cfg.AutoPlacePositions[data.map]
			local text = type(stored) == "table" and (stored["Unit" .. index] or stored.Center)
			if not skyPosition and placement(info, "Position Mode") == "Shared Position" then
				text = type(stored) == "table" and stored.Center
				assert(text, "Use Set Pos for this map first.")
			end
			local id = data.id and data.id:match("^[^_]+") or data.map
			local point = skyPosition and Vector3.new(-1910.7, 186.3, -310.4)
				or placement(info, "Position Mode") == "Path" and pathPoint(info)
				or text and frame(text).Position
				or points[(hill and "hill_" or "") .. id]
			local terrain = workspace:FindFirstChild("_terrain")
			assert(terrain, "Map terrain not ready.")
			if not point then
				local bases = workspace:FindFirstChild("_BASES")
				local lane = bases and bases:FindFirstChild("pve")
				lane = lane and lane:FindFirstChild("LANES")
				lane = lane and lane:FindFirstChild("1")
				assert(lane, "Map lanes not ready. Use Set Pos first.")
				local first
				for _, part in ipairs(lane:GetChildren()) do
					local num = tonumber(part.Name)
					if num and (not first or num < tonumber(first.Name)) then
						first = part
					end
				end
				assert(first, "No placement point. Use Set Pos first.")
				point = first.Position
			end
			local farm = farms[info.id] or tostring(info.id):match("^speedwagon") or tostring(info.id):match("^bulma")
			local want = point + offset(farm and n + 9 or n) * (farm and 2 or 1)
			local folder = workspace:FindFirstChild("_UNITS")
			local function clear(pos)
				for _, unit in ipairs(folder and folder:GetChildren() or {}) do
					local shadow = unit:FindFirstChild("_shadow")
					if shadow then
						local delta = shadow.Position - pos
						if delta.X ^ 2 + delta.Z ^ 2 < 1 and math.abs(delta.Y) < 4 then
							return false
						end
					end
				end
				return true
			end
			local surface = terrain:FindFirstChild(hill and "hill" or "ground")
			local hit = ray(want + Vector3.new(0, 128, 0), surface, 256)
			if hit and clear(hit.Position) then
				return CFrame.new(hit.Position)
			end
			if
				not hill
				and (not info.data.hybrid_placement or (data.map == "skypiea" and not skyPosition))
				and placement(info, "Position Mode") ~= "Path"
			then
				return
			end
			surface = terrain:FindFirstChild(
				placement(info, "Position Mode") == "Path" and not hill and "ground" or "hill"
			)
			if not surface then
				return
			end
			if not spots[surface] then
				local parts = {}
				if surface:IsA("BasePart") then
					table.insert(parts, surface)
				end
				for _, part in ipairs(surface:GetDescendants()) do
					if part:IsA("BasePart") then
						table.insert(parts, part)
					end
				end
				spots[surface] = parts
			end
			local candidates = {}
			local function add(grid, dx, dz)
				local key = dx .. ":" .. dz
				if
					grid.seen[key]
					or dx < math.floor((-grid.x - grid.p.X))
					or dx > math.ceil((grid.x - grid.p.X))
					or dz < math.floor((-grid.z - grid.p.Z))
					or dz > math.ceil((grid.z - grid.p.Z))
				then
					return
				end
				grid.seen[key] = true
				local pos = grid.part.CFrame:PointToWorldSpace(
					Vector3.new(
						math.clamp(grid.p.X + dx, -grid.x, grid.x),
						grid.part.Size.Y / 2,
						math.clamp(grid.p.Z + dz, -grid.z, grid.z)
					)
				)
				table.insert(candidates, { grid = grid, x = dx, z = dz, pos = pos, dist = (pos - want).Magnitude })
			end
			for _, part in ipairs(spots[surface]) do
				local p = part.CFrame:PointToObjectSpace(want)
				local x, z = math.max(0, part.Size.X / 2 - 0.25), math.max(0, part.Size.Z / 2 - 0.25)
				add({
					part = part,
					p = Vector3.new(math.clamp(p.X, -x, x), 0, math.clamp(p.Z, -z, z)),
					x = x,
					z = z,
					seen = {},
				}, 0, 0)
			end
			while #candidates > 0 do
				table.sort(candidates, function(a, b)
					return a.dist > b.dist
				end)
				local row = table.remove(candidates)
				hit = ray(row.pos + Vector3.new(0, 4, 0), surface, 8)
				if hit and clear(hit.Position) then
					return CFrame.new(hit.Position)
				end
				add(row.grid, row.x + 1, row.z)
				add(row.grid, row.x - 1, row.z)
				add(row.grid, row.x, row.z + 1)
				add(row.grid, row.x, row.z - 1)
			end
		end

		local function smartPlace(index, n, info)
			if
				skyPositionEnabled(level())
				or placement(info, "Placement Mode") == "Circle"
				or placement(info, "Position Mode") == "Shared Position"
				or placement(info, "Position Mode") == "Path"
			then
				return circlePlace(index, n, info)
			end
			local map = level().map
			local stored = cfg.AutoPlacePositions[map]
			local cap = math.min(info.data.spawn_cap or 5, (self.placeCaps[index] or 4))
			if stored and stored["Unit" .. index] then
				return frame(stored["Unit" .. index]) + offset(n)
			end
			local id = level().id and level().id:match("^[^_]+") or map
			local point = points[(info.data.hill_unit and "hill_" or "") .. id]
			if point then
				return CFrame.new(point + offset(n))
			end
			local terrain = workspace:FindFirstChild("_terrain")
			assert(terrain, "Map terrain not ready.")
			if not spots[index] then
				local bases = workspace:FindFirstChild("_BASES")
				local lane = bases and bases:FindFirstChild("pve") and bases.pve:FindFirstChild("LANES")
				lane = lane and lane:FindFirstChild("1")
				assert(lane, "Map lanes not ready. Set unit positions manually.")
				local points = {}
				for _, part in ipairs(lane:GetChildren()) do
					if tonumber(part.Name) then
						table.insert(points, part)
					end
				end
				table.sort(points, function(a, b)
					return tonumber(a.Name) < tonumber(b.Name)
				end)
				local anchor = points[math.min(index, #points)]
				assert(anchor, "No placement point. Set unit position manually.")
				local candidates = {}
				if info.data.hill_unit then
					local hill = terrain:FindFirstChild("hill")
					for _, part in ipairs(hill and hill:GetDescendants() or {}) do
						if part:IsA("BasePart") then
							table.insert(candidates, part.Position + Vector3.new(0, part.Size.Y / 2, 0))
						end
					end
					table.sort(candidates, function(a, b)
						return (a - anchor.Position).Magnitude < (b - anchor.Position).Magnitude
					end)
				else
					for _, part in ipairs(points) do
						table.insert(candidates, part.Position)
					end
				end
				for _, point in ipairs(candidates) do
					local validPoint = true
					for other, pos in pairs(spots) do
						if type(other) == "number" and other ~= index and (pos - point).Magnitude < 5 then
							validPoint = false
							break
						end
					end
					for j = 0, cap - 1 do
						if
							not validPoint
							or not ray(
								point + offset(j) + Vector3.new(0, 12, 0),
								terrain:FindFirstChild(info.data.hill_unit and "hill" or "ground"),
								20
							)
						then
							validPoint = false
							break
						end
					end
					if validPoint then
						spots[index] = point
						break
					end
				end
			end
			assert(spots[index], "No safe point for slot " .. index .. ". Set position manually.")
			local hit = ray(
				spots[index] + offset(n) + Vector3.new(0, 12, 0),
				terrain:FindFirstChild(info.data.hill_unit and "hill" or "ground"),
				20
			)
			assert(hit, "Placement surface missing. Reset position for slot " .. index)
			return CFrame.new(hit.Position)
		end


		local function imageUri(value)
			if type(value) == "number" and finite(value) and value > 0 and value % 1 == 0 then
				value = string.format("%.0f", value)
			end
			if type(value) ~= "string" then
				return nil
			end
			local id = value:match("^rbxassetid://(%d+)$") or value:match("^(%d+)$") or value:match("[?&]id=(%d+)")
			return if id and id:match("[1-9]") then "rbxassetid://" .. id else nil
		end
		local function portrait(info, slot)
			-- Only explicit portraits qualify; animation/mesh/texture IDs are not unit pictures.
			for _, key in { "ImageAssetId", "image", "image_id", "thumbnail", "icon" } do
				local uri = imageUri(info.data[key])
				if uri then
					return uri
				end
			end
			local packages = RS:FindFirstChild("packages")
			local assets = packages and packages:FindFirstChild("assets")
			local gui = assets and assets:FindFirstChild("gui")
			for _, root in { assets, gui } do
				if not root then
					continue
				end
				for _, name in { "UnitIcons", "_UnitIcons", "UnitImages", "_OverrideUnitIcons" } do
					local bank = root:FindFirstChild(name)
					local icon = bank and bank:FindFirstChild(info.id)
					if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
						local uri = imageUri(icon.Image)
						if uri then
							return uri
						end
					end
				end
			end
			local playerGui = LP:FindFirstChild("PlayerGui")
			local spawn = playerGui and playerGui:FindFirstChild("spawn_units")
			-- Match owned UUID before slot. Never borrow another unit's picture or a trait icon.
			local lives = spawn and spawn:FindFirstChild("Lives")
			local panel = lives and lives:FindFirstChild("Frame")
			local bar = panel and panel:FindFirstChild("Units")
			local card = bar and bar:FindFirstChild(tostring(slot))
			if card then
				local icon = card:FindFirstChild("UnitImage", true) or card:FindFirstChild("Portrait", true)
				if icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) then
					local uri = imageUri(icon.Image)
					if uri then
						return uri
					end
				end
				return nil, card:FindFirstChildWhichIsA("ViewportFrame", true)
			end
		end
		function self:Catalog()
			local result = {}
			self.equipped = slots()
			for slot = 1, 6 do
				local info = self.equipped[slot]
				if not info then
					continue
				end
				local image, viewport = portrait(info, slot)
				table.insert(result, {
					UnitId = info.uuid,
					Name = info.data.name or info.id,
					Slot = slot,
					Rarity = info.data.rarity,
					IsFarm = info.data._show_as_farm_unit == true or farms[info.id] == true,
					ImageAssetId = image,
					ViewportSource = viewport,
					MaxPlace = info.data.spawn_cap or 5,
					MaxUpgrade = if type(info.data.upgrade) == "table" then #info.data.upgrade else nil,
				})
			end
			return result
		end
		function self:Defaults(old)
			local result, eq = {}, slots()
			for slot = 1, 6 do
				local info = eq[slot]
				if not info then
					continue
				end
				local key = tostring(slot)
				table.insert(result, {
					UnitId = info.uuid,
					PlaceCap = tonumber(old.AutoPlacesCap and old.AutoPlacesCap[key])
						or math.min(4, info.data.spawn_cap or 5),
					UpgradeCap = tonumber(old.AutoUpgradesCap and old.AutoUpgradesCap[key])
						or (if type(info.data.upgrade) == "table" then #info.data.upgrade else 0),
					PlaceWave = tonumber(old.AutoPlaceWaves and old.AutoPlaceWaves[key]) or 1,
					UpgradeWave = tonumber(old.AutoUpgradeWaves and old.AutoUpgradeWaves[key]) or 1,
					PlacementMode = cfg["Placement Mode"],
					PositionMode = cfg["Position Mode"],
					PathTarget = cfg["Path Target"],
					PathPosition = cfg["Path Position"],
				})
			end
			return UI.UnitSettings.normalize(result)
		end
		function self:Tick()
			if self.dead then
				return
			end
			local folder, map = workspace:FindFirstChild("_UNITS"), workspace:FindFirstChild("_MAP_CONFIG")
			local wave = val(workspace, "_wave_num", 0)
			local data = workspace:FindFirstChild("_DATA")
			local finished = val(data, "GameFinished", false)
			if map ~= self.map or folder ~= self.folder or finished ~= self.finished or wave < (self.wave or 0) then
				self.map, self.folder, self.finished = map, folder, finished
				self.timers, self.attempts, self.statuses, self.upgradeAttempts = {}, {}, {}, {}
				levelData = nil
				table.clear(spots)
			end
			self.wave = wave
			if
				self.selecting
				and (
					self.selecting.map ~= map
					or self.selecting.folder ~= folder
					or finished
					or wave < self.selecting.wave
				)
			then
				self:CancelPick()
			end
			if self.paused or self.teamBusy then
				return
			end
			if not self.on then
				self.status = "Stopped"
				return
			end
			if not map or val(map, "IsLobby", true) or not folder then
				self.status = "Waiting for a match"
				return
			end
			if finished then
				self.status = "Match finished"
				return
			end
			if self.selecting then
				self.status = "Choosing position"
				return
			end
			local eq = slots()
			local money = val(LP:FindFirstChild("_stats"), "resource", 0)
			local scale = val(data and data:FindFirstChild("LevelModifiers"), "player_cost_scale", 1)
			assert(finite(money) and finite(scale) and scale > 0, "Waiting for valid resource data")
			self.activeVersion = self.version
			local children, count, best = folder:GetChildren(), 0, nil
			for _, unit in children do
				if mine(unit) then
					count += 1
				end
			end
			self.placeCaps = {}
			self.status = "Wave " .. wave .. " · Waiting for units, waves or Yen"
			local placeSlot
			if cfg["Auto Place Mode"] == "Slots by Slots" and count < 50 then
				for _, rule in ipairs(self.rules) do
					if rule.Action ~= "Place" or not rule.Enabled or rule.Count <= 0 then continue end
					for slot, info in pairs(eq) do
						if info.uuid ~= rule.UnitId or (rule.TargetSlot and tonumber(rule.TargetSlot) ~= slot)
							or (self.AllowAction and not self:AllowAction(info)) then continue end
						local placed, total = 0, 0
						for _, unit in ipairs(children) do
							local stats = unit:FindFirstChild("_stats")
							if val(stats, "id") == info.id then
								total += 1
								if mine(unit) and val(stats, "uuid") == info.uuid then placed += 1 end
							end
						end
						if placed < math.min(rule.Count, info.data.spawn_cap or 5)
							and (not info.data.global_spawn_cap or total < info.data.global_spawn_cap)
							and (not placeSlot or slot < placeSlot) then placeSlot = slot end
					end
				end
			end
			for _, rule in self.rules do
				local status, info, slot = "Off", nil, nil
				for i, unit in pairs(eq) do
					if unit.uuid == rule.UnitId and (not rule.TargetSlot or tonumber(rule.TargetSlot) == i) then
						info, slot = unit, i
						break
					end
				end
				local place = rule.Action == "Place"
				local cap = if place then rule.Count else rule.TargetLevel
				local id = rule.StepId
				if not info then
					status = "Not equipped"
				elseif rule.Enabled and cap > 0 and (not self.AllowAction or self:AllowAction(info)) then
					if wave < (rule.Wave or 1) then
						status = "Waiting for wave"
						self.timers[id] = nil
					else
						self.timers[id] = self.timers[id] or os.clock()
						if os.clock() - self.timers[id] < (rule.Delay or 0) then
							status = "Delay"
						elseif place then
							if best and best.focus then continue end
							if placeSlot and slot ~= placeSlot then
								self.statuses[id] = "Waiting for slot " .. placeSlot
								continue
							end
							local placed, total = 0, 0
							for _, unit in children do
								local stats = unit:FindFirstChild("_stats")
								if val(stats, "id") == info.id then
									total += 1
									if mine(unit) and val(stats, "uuid") == info.uuid then
										placed += 1
									end
								end
							end
							cap = math.min(cap, info.data.spawn_cap or 5)
							self.placeCaps[slot] = cap
							local cost = (info.data.cost or math.huge) * scale
							if placed >= cap then
								status = "Placed " .. placed .. "/" .. cap
							elseif
								count >= 50 or info.data.global_spawn_cap and total >= info.data.global_spawn_cap
							then
								status = "Spawn limit"
							elseif not finite(cost) or cost < 0 then
								status = "Invalid cost"
							elseif money < cost then
								status = "Waiting for Yen"
							else
								local n = self.attempts[slot] or placed
								self.attempts[slot] = n + 1
								self.timers[id] = os.clock()
								local ok, cf = pcall(smartPlace, slot, n, info)
								if ok and cf then
									if remote("spawn_unit", info.uuid, cf) then
										self.statuses[id], self.status =
											"Placing", "Placing " .. (info.data.name or info.id)
										return
									end
								else
									status = "Set position"
									if not ok then
										self:Report(tostring(cf))
									end
								end
							end
						else
							status = "No placed unit"
							for _, unit in children do
								local stats = mine(unit)
								if not stats or val(stats, "uuid") ~= info.uuid or val(stats, "id") ~= info.id then
									continue
								end
								local n = val(stats, "upgrade", 0)
								local known = type(info.data.upgrade) == "table"
								local nextUpgrade = known and info.data.upgrade[n + 1]
								if n >= cap or known and not nextUpgrade then
									status = "At cap"
									continue
								end
								-- ponytail: missing upgrade data uses the manual cap and server validation; use price ordering when metadata becomes available.
								if not known and os.clock() - (self.upgradeAttempts[unit] or -math.huge) < 2 then
									continue
								end
								local cost = if known
									then nextUpgrade.cost * val(stats, "upgrade_cost_multiplier", 1) * scale
									else money
								if not finite(cost) or cost < 0 then
									status = "Invalid cost"
									continue
								end
								status = if cost > money then "Waiting for Yen" else "Ready"
								local focus = rule.FocusFarm
									and (info.data._show_as_farm_unit == true or farms[info.id] == true)
								if cost > money and not focus and cfg["Upgrade Mode"] == "Default" then
									continue
								end
								local rank = cfg["Upgrade Mode"] == "Slot by Slot" and slot
									or cfg["Upgrade Mode"] == "Balanced" and n or 0
								local levelRank = cfg["Upgrade Mode"] == "Default" and 0 or n
								if not best or focus and not best.focus or focus == best.focus and
									(rank < best.rank or rank == best.rank and (levelRank < best.level
										or levelRank == best.level and cost < best.cost)) then
									best = {
										unit = unit,
										cost = cost,
										manual = not known,
										focus = focus,
										rank = rank,
										level = levelRank,
										rule = rule,
										name = info.data.name or info.id,
									}
								end
							end
						end
					end
				end
				self.statuses[id] = status
			end
			if best and best.cost <= money then
				self.timers[best.rule.StepId] = os.clock()
				if best.manual then
					self.upgradeAttempts[best.unit] = os.clock()
				end
				if remote("upgrade_unit_ingame", best.unit) then
					self.statuses[best.rule.StepId], self.status = "Upgrading", "Upgrading " .. best.name
				end
			end
		end
		function self:CancelPick()
			local pick = self.selecting
			self.selecting = nil
			if pick then
				for _, connection in pick.connections do
					connection:Disconnect()
				end
				for _, part in pick.parts do
					part:Destroy()
				end
			end
		end
		function self:PickPosition(slot, shared)
			local folder, mapInstance = match()
			self:CancelPick()
			local info, map = slots()[slot], level().map
			assert(info, "Equip a unit in slot " .. slot)
			local terrain = workspace:FindFirstChild("_terrain")
			local surface = terrain and terrain:FindFirstChild(info.data.hill_unit and "hill" or "ground")
			assert(surface, "Placement terrain not ready")
			local mouse = LP:GetMouse()
			local pick = {
				connections = {},
				parts = {},
				map = mapInstance,
				folder = folder,
				wave = val(workspace, "_wave_num", 0),
			}
			self.selecting = pick
			local marker = Instance.new("Part")
			marker.Name, marker.Anchored, marker.CanCollide, marker.CanTouch, marker.CanQuery =
				"BocchiPosition", true, false, false, false
			marker.Size, marker.Transparency, marker.Color =
				Vector3.new(1.5, 0.15, 1.5), 1, Color3.fromRGB(110, 168, 255)
			marker.Parent = workspace
			table.insert(pick.parts, marker)
			local function aim(point)
				local r = if point then workspace.CurrentCamera:ScreenPointToRay(point.X, point.Y) else mouse.UnitRay
				local params = RaycastParams.new()
				params.FilterDescendantsInstances, params.FilterType = { surface }, Enum.RaycastFilterType.Include
				local hit = workspace:Raycast(r.Origin, r.Direction * 1000, params)
				pick.pos, marker.Transparency = if hit then hit.Position else nil, if hit then 0.3 else 1
				if hit then
					marker.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.1, 0))
				end
			end
			table.insert(
				pick.connections,
				RunService.RenderStepped:Connect(function()
					aim()
				end)
			)
			table.insert(
				pick.connections,
				UserInputService.InputBegan:Connect(function(input, processed)
					if input.KeyCode == Enum.KeyCode.Escape then
						self:CancelPick()
						return
					end
					if processed then
						return
					end
					if
						input.UserInputType ~= Enum.UserInputType.MouseButton1
						and input.UserInputType ~= Enum.UserInputType.Touch
					then
						return
					end
					aim(if input.UserInputType == Enum.UserInputType.Touch then input.Position else nil)
					if not pick.pos then
						return
					end
					cfg.AutoPlacePositions[map] = cfg.AutoPlacePositions[map] or {}
					cfg.AutoPlacePositions[map][if shared then "Center" else "Unit" .. slot] =
						tostring(CFrame.new(pick.pos))
					table.clear(spots)
					save()
					self:CancelPick()
					notify("Position saved for " .. (if shared then "all slots" else "slot " .. slot))
				end)
			)
			notify("Click terrain for " .. (if shared then "shared position" else "slot " .. slot) .. ". Esc cancels.")
		end
		function self:ClearPosition(slot, shared)
			local stored = cfg.AutoPlacePositions[level().map]
			if stored then
				stored[if shared then "Center" else "Unit" .. slot] = nil
			end
			table.clear(spots)
			save()
		end
		function self:Destroy()
			self.dead, self.on = true, false
			self:CancelPick()
		end
		return self
	end
	-- End Auto Play runtime.

	-- Card priority scoring.
	local CardPriority = (function()
		local Priority = {
			Tiers = { "I", "II", "III", "IV", "V" },
			Buffs = {
				{ "range", "+ Range I–V" },
				{ "damage", "+ Attack Damage I–V" },
				{ "attack_cooldown", "- Cooldown Time I–V" },
				{ "active_attack_cooldown", "- Active Cooldown Time" },
				{ "boss_damage", "+ Boss Damage I–V" },
				{ "flying_damage", "+ Damage vs Flying" },
				{ "unit_cost", "- Placement/Upgrade Cost" },
				{ "secret_drop", "+ Secret Drop Rate" },
				{ "physical_crit_chance", "+ Phys Crit Chance" },
				{ "magic_crit_chance", "+ Magic Crit Chance" },
				{ "_dmg_mul_physical", "+ Phys Damage" },
				{ "_dmg_mul_magic", "+ Magic Damage" },
				{ "_dmg_mul_true_damage", "+ True Damage" },
				{ "enemy_amp_specific", "+ Element Damage Taken" },
				{ "random_blessings", "Gain Random Blessings" },
				{ "resource_gain", "+ Yen" },
			},
			Curses = {
				{ "enemy_speedup", "+ Enemy Speed I–V" },
				{ "enemy_health", "+ Enemy Health I–V" },
				{ "enemy_resistance", "+ Resistant Enemies (Physical + Magic) I–V" },
				{ "enemy_physical_resistance", "+ Physical Resist I–V" },
				{ "enemy_magic_resistance", "+ Magic Resist I–V" },
				{ "elemental_resistance", "+ Elemental Resistances I–V" },
				{ "enemy_shield", "+ Enemy Shields I–V" },
				{ "enemy_regen", "+ Enemy Regen I–V" },
				{ "enemy_bomb", "+ Explosive Deaths" },
				{ "new_path", "+ New Path / Extra Lanes" },
				{ "high_cost", "+ High Cost I–V" },
				{ "armor", "+ Armored Enemies" },
				{ "flying", "+ Flying Enemies" },
				{ "infested", "+ Infested I–V" },
				{ "random_curses", "Gain Random Curses" },
			},
			Weather = {
				{ "meteor_shower", "Starfall", "Star Golems drop Star Remnants." },
				{ "clear", "Clear", "No negative weather modifiers." },
				{ "underwater", "Flooded", "Enemies gain Burst: high initial speed that decays over distance." },
				{ "mana", "Magical", "+150 enemy Physical Resist; enemies take +25% Magic Damage." },
				{ "downpour", "Stormy", "-30% unit range; lightning stuns the most expensive unit for 3s every 10s." },
				{ "windy", "Windy", "20% of enemies become airborne; moving with the wind grants up to +75% speed." },
				{
					"sandstorm",
					"Sandstorm",
					"Enemies are invulnerable for the first 20% of the lane; +75 Magic Resist, +25% Physical Damage Taken.",
				},
				{ "rain", "Rainy", "+20% enemy speed." },
				{ "fire", "Inferno", "+50% enemy speed, immune to stuns/slows; burning tiles block placement." },
				{ "snow", "Blizzard", "Half of enemies are covered in ice; only Fire deals full damage to them." },
			},
		}
		local labels, groups = {}, {}
		for _, group in ipairs({ "Buffs", "Curses", "Weather" }) do
			groups[group] = {}
			for _, row in ipairs(Priority[group]) do
				labels[row[1]], groups[group][row[1]] = row[2], true
			end
		end
		Priority.Labels = labels

		local entries, known =
			{ Buffs = {}, Curses = {}, Cards = {}, Special = {} }, { Buffs = {}, Curses = {}, Cards = {}, Special = {} }
		for _, group in ipairs({ "Buffs", "Curses" }) do
			local function add(id, label)
				entries[group][#entries[group] + 1], known[group][id], labels[id] = id, true, label
				entries.Cards[#entries.Cards + 1], known.Cards[id] = id, true
			end
			for _, row in ipairs(Priority[group]) do
				if row[2]:find("I–V", 1, true) then
					for _, tier in ipairs(Priority.Tiers) do
						add(row[1] .. ":" .. tier, (row[2]:gsub("I–V", tier)))
					end
				else
					add(row[1], row[2])
				end
			end
		end
		for _, row in ipairs(Priority.Weather) do
			local id = "weather:" .. row[1]
			entries.Special[#entries.Special + 1], known.Special[id], labels[id] = id, true, row[2]
		end

		function Priority.tier(card)
			local title = type(card.title) == "string" and card.title:gsub("<[^>]+>", "") or ""
			local printed = title:upper():match("%s+([IV]+)%s*$")
			if table.find(Priority.Tiers, printed) then
				return printed
			end
			local value = card.tier or title:match("[Tt]ier%s+([1-5])%s*$") or title:match("%s+([1-5])%s*$")
			if type(value) == "string" and table.find(Priority.Tiers, value:upper()) then
				return value:upper()
			end
			local number = (type(value) == "string" or type(value) == "number") and tonumber(value)
			if number and number % 1 == 0 and Priority.Tiers[number] then
				return Priority.Tiers[number]
			end
			-- ponytail: missing tier defaults to I; prefer an explicit server tier when available.
			return "I"
		end

		function Priority.order(group, saved)
			local out, seen = {}, {}
			local function add(id)
				if known[group][id] and not seen[id] then
					out[#out + 1], seen[id] = id, true
				end
			end
			for _, id in ipairs(type(saved) == "table" and saved or {}) do
				if type(id) ~= "string" then
					continue
				end
				add(id)
				for _, tier in ipairs(Priority.Tiers) do
					add(id .. ":" .. tier)
				end
			end
			for _, id in ipairs(entries[group]) do
				add(id)
			end
			return out
		end

		function Priority.migrate(group, config)
			if group == "Cards" then
				if type(config["Summer Pick Priority"]) == "table" then
					return Priority.order(group, config["Summer Pick Priority"])
				end
				-- ponytail: old lists have no cross-category order; retain Buffs then Curses until reordered together.
				local combined = Priority.migrate("Buffs", config)
				for _, id in ipairs(Priority.migrate("Curses", config)) do
					combined[#combined + 1] = id
				end
				return Priority.order(group, combined)
			end
			if group == "Special" then
				local combined = {}
				for _, key in ipairs({
					"Summer Special Priority",
					"Summer Buff Priority",
					"Summer Curse Priority",
					"Summer Weather Priority",
				}) do
					for _, id in ipairs(type(config[key]) == "table" and config[key] or {}) do
						if type(id) ~= "string" then
							continue
						end
						if known.Special[id] then
							combined[#combined + 1] = id
						else
							for _, row in ipairs(Priority.Weather) do
								if id == row[1] or id == row[2] then
									combined[#combined + 1] = "weather:" .. row[1]
									break
								end
							end
						end
					end
				end
				return Priority.order(group, combined)
			end
			local base = group == "Buffs" and "Summer Buff Priority" or "Summer Curse Priority"
			local saved = type(config[base]) == "table" and config[base] or {}
			for _, id in ipairs(saved) do
				if type(id) == "string" and known[group][id] and id:find(":", 1, true) then
					return Priority.order(group, saved)
				end
			end
			local combined, hasTiers = {}, false
			for _, tier in ipairs(Priority.Tiers) do
				local list = config[base .. " " .. tier]
				if type(list) == "table" then
					hasTiers = true
					for _, id in ipairs(list) do
						if type(id) == "string" then
							combined[#combined + 1] = known[group][id .. ":" .. tier] and id .. ":" .. tier or id
						end
					end
				end
			end
			if not hasTiers then
				combined = table.clone(saved)
			end
			return Priority.order(group, combined)
		end

		function Priority.normalizeTitle(value)
			if type(value) ~= "string" then return "" end
			local title = value:gsub("<[^>]+>", ""):gsub("️", ""):gsub("‍", "")
			title = title:match("^%s*(.-)%s*$")
			for _, icon in ipairs({ "🏜", "🌧", "❄", "🌬", "🔥", "✨", "🌊" }) do
				title = title:gsub("^" .. icon .. "%s*", "")
			end
			return title:gsub("%s+", " "):lower()
		end
		function Priority.rank(list, name)
			for i, id in ipairs(list or {}) do
				if type(id) == "string" and type(name) == "string" and id:lower() == name:lower() then
					return #list - i + 1
				end
			end
			local normalized = Priority.normalizeTitle(name)
			if normalized ~= "" then
				for i, id in ipairs(list or {}) do
					if Priority.normalizeTitle(id) == normalized then return #list - i + 1 end
				end
			end
			return 0
		end

		local function finite(value)
			return type(value) == "number" and value == value and math.abs(value) < math.huge
		end

		function Priority.analyze(card)
			local found, score, reward = {}, finite(card.displayScore) and card.displayScore or 0, 0
			local function add(id, points)
				found[id] = true
				score += points
			end
			local function metadata(data)
				local mods = type(data.game_mods) == "table" and data.game_mods or data.type == "game_mods" and data
				if mods and finite(mods.player_cost_scale) and mods.player_cost_scale > 1 then
					add("high_cost", -(mods.player_cost_scale - 1) * 120)
				end
				local enemies = type(data.enemy_modifiers) == "table" and data.enemy_modifiers
					or data.type == "enemy_modifiers" and data
				if enemies then
					if enemies.Armor == true then
						add("armor", -60)
					end
					if enemies.Flying == true then
						add("flying", -80)
					end
				end
				if finite(data.inf_amt_mul) and data.inf_amt_mul > 0 then
					add("infested", -data.inf_amt_mul * 120)
				end
			end
			metadata(card)
			-- ponytail: these are fallback weights; the BETA team picker adjusts damage exposure separately.
			for _, effect in pairs(type(card.effects) == "table" and card.effects or {}) do
				if type(effect) ~= "table" then
					continue
				end
				metadata(effect)
				local kind, amount, stat = effect.type, effect.amount, effect.stat
				if kind == "new_path" then
					add("new_path", -120 * math.max(1, type(effect.new_lanes) == "table" and #effect.new_lanes or 1))
				elseif kind == "random_effects" then
					local strength = (finite(amount) and math.max(0, amount) or 1)
						* (finite(effect.tier) and math.max(1, effect.tier) or 1)
					if effect._type == "Good" then
						add("random_blessings", strength * 10)
					elseif effect._type == "Bad" then
						add("random_curses", -strength * 10)
					end
				elseif finite(amount) then
					if kind == "stat_mul" or kind == "stat_mul_real" then
						if kind == "stat_mul_real" then
							amount -= 1
						end
						if stat == "damage" or stat == "range" then
							if amount > 0 then
								found[stat] = true
							end
							score += amount * (stat == "damage" and 100 or 60)
						elseif stat == "attack_cooldown" or stat == "active_attack_cooldown" then
							if amount < 0 then
								found[stat] = true
							end
							score -= amount * 120
						end
					elseif kind == "stat_add" or kind == "stat_attr_add" then
						if groups.Buffs[stat] then
							if amount > 0 then
								found[stat] = true
							end
							score += amount * 100
						end
					elseif kind == "enemy_resistance_specific" then
						if amount > 0 then
							found[effect.damage_type == "physical" and "enemy_physical_resistance" or effect.damage_type == "magic" and "enemy_magic_resistance" or "elemental_resistance"] =
								true
						end
						score -= amount
					elseif kind == "enemy_stat_mul" and stat == "health" then
						if amount > 0 then
							found.enemy_health = true
						end
						score -= amount * 120
					elseif kind == "candy_multiplier" or kind == "secret_drop" then
						if kind == "secret_drop" and amount > 0 then
							found.secret_drop = true
						end
						reward += amount * 200
						score += amount * 8
					elseif kind == "unit_cost" then
						if amount < 0 then
							found.unit_cost = true
						elseif amount > 0 then
							found.high_cost = true
						end
						score -= amount * 120
					elseif
						kind == "enemy_speedup"
						or kind == "enemy_shield"
						or kind == "enemy_regen"
						or kind == "enemy_bomb"
					then
						if amount > 0 then
							found[kind] = true
						end
						local weight = kind == "enemy_shield" and 3
							or kind == "enemy_regen" and 10000
							or kind == "enemy_bomb" and 10
							or 120
						score -= amount * weight
					elseif kind == "inf_amt_mul" then
						if amount > 0 then
							add("infested", -amount * 120)
						end
					elseif kind == "resource_gain" then
						if amount > 0 then
							found.resource_gain = true
						end
						score += amount / 150
					elseif kind == "boss_damage" or kind == "flying_damage" or kind == "enemy_amp_specific" then
						if amount > 0 then
							found[kind] = true
						end
						score += amount * 100
					end
				end
			end
			if found.enemy_physical_resistance and found.enemy_magic_resistance then
				found.enemy_physical_resistance, found.enemy_magic_resistance, found.enemy_resistance = nil, nil, true
			end
			return found, score, reward
		end

		function Priority.score(card, config)
			if type(card) ~= "table" or type(card.title) ~= "string" then
				return nil
			end
			local title = card.title:gsub("<[^>]+>", "")
			local exact = Priority.rank(config["Summer Card Priority"], title)
			local weatherId
			for _, row in ipairs(Priority.Weather) do
				local text = title:lower()
				if
					card.weather == row[1]
					or text == row[1]
					or text == row[2]:lower()
					or text:find("weather", 1, true) and text:find(row[2]:lower(), 1, true)
				then
					weatherId = row[1]
					break
				end
			end
			local found, score, reward = Priority.analyze(card)
			local good, family = card.option_type == "Good", 0
			if card.option_type ~= "Good" and card.option_type ~= "Bad" then
				for id in pairs(found) do
					if groups.Buffs[id] then
						good = true
						break
					end
				end
			end
			if
				card.option_type ~= "Good"
				and card.option_type ~= "Bad"
				and (weatherId == "meteor_shower" or weatherId == "clear")
			then
				good = true
			end
			local list = config["Summer Pick Priority"]
			local tier = Priority.tier(card)
			local special = weatherId and Priority.rank(config["Summer Special Priority"], "weather:" .. weatherId) or 0
			for id in pairs(found) do
				local item = known.Cards[id .. ":" .. tier] and id .. ":" .. tier or id
				family = math.max(family, Priority.rank(list, item))
			end
			if config["Summer Card Strategy"] == "Priority only" then
				if family == 0 and special == 0 then
					return nil
				end
				return 0, special, family
			end
			score += (good and 100000 or 0) + family * 1000
			if config["Summer Card Strategy"] == "Rewards" then
				score += reward * 1000000
			end
			return exact, special, score
		end

		local damageTypes = {
			physical = true,
			magic = true,
			true_damage = true,
			fire_damage = true,
			water_damage = true,
			lightning_damage = true,
			air_damage = true,
			ice_damage = true,
			light_damage = true,
			dark_damage = true,
		}
		local numericEffects = {
			stat_mul = true,
			stat_mul_real = true,
			stat_add = true,
			stat_attr_add = true,
			enemy_stat_mul = true,
			enemy_resistance_specific = true,
			enemy_amp_specific = true,
			enemy_speedup = true,
			enemy_shield = true,
			enemy_regen = true,
			enemy_bomb = true,
			candy_multiplier = true,
			secret_drop = true,
			unit_cost = true,
			inf_amt_mul = true,
			resource_gain = true,
			boss_damage = true,
			flying_damage = true,
			golem_chance = true,
			weather_flying_chance = true,
			weather_soaring_share = true,
			burst_speed = true,
			lightning_strikes = true,
			enemy_passive_chance = true,
		}

		function Priority.team(rows, attacks)
			if type(rows) ~= "table" or type(attacks) ~= "table" then
				return nil
			end
			local team = { total = 0, largest = 0, hill = 0, air = 0, types = {} }
			for _, data in ipairs(rows) do
				if type(data) ~= "table" or not finite(data.damage) then
					return nil
				end
				if data.damage <= 0 then
					continue
				end
				if not finite(data.attack_cooldown) or data.attack_cooldown <= 0 then
					return nil
				end
				local base = data._base_damage_type
				if base ~= "physical" and base ~= "magic" and base ~= "true_damage" then
					return nil
				end
				local types, antiAir, seen, invalid = { [base] = true }, data.hill_unit == true, {}, false
				local function scan(value)
					if type(value) ~= "table" or seen[value] then
						return
					end
					seen[value] = true
					if value._base_damage_type ~= nil then
						if not damageTypes[value._base_damage_type] then
							invalid = true
						else
							types[value._base_damage_type] = true
						end
					end
					if value._secondary_damage_types ~= nil and type(value._secondary_damage_types) ~= "table" then
						invalid = true
					end
					for kind, on in
						pairs(type(value._secondary_damage_types) == "table" and value._secondary_damage_types or {})
					do
						if on == true then
							if not damageTypes[kind] then
								invalid = true
							else
								types[kind] = true
							end
						end
					end
					antiAir = antiAir or value.targets_flying == true or value.hits_flying == true
					for key, child in pairs(value) do
						if type(child) == "table" and key ~= "upgrade" then
							scan(child)
						end
					end
				end
				scan({ _secondary_damage_types = data._secondary_damage_types })
				for _, id in ipairs({
					data.primary_attack or data.primary_attack_no_upgrades or false,
					data.active_attack or false,
				}) do
					if id then
						if type(attacks[id]) ~= "table" then
							return nil
						end
						scan(attacks[id])
					end
				end
				if invalid then
					return nil
				end
				-- ponytail: damage / cooldown estimates exposure, not exact DPS; hit counts, uptime and resistance math need live validation.
				local weight = data.damage / data.attack_cooldown
				if not finite(weight) then
					return nil
				end
				team.total += weight
				team.largest = math.max(team.largest, weight)
				if data.hill_unit then
					team.hill += weight
				end
				if antiAir then
					team.air += weight
				end
				for kind in pairs(types) do
					team.types[kind] = (team.types[kind] or 0) + weight
				end
			end
			return finite(team.total) and team.total > 0 and team or nil
		end

		function Priority.snapshot(data)
			if
				type(data) ~= "table"
				or data.candy_multiplier ~= nil and not finite(data.candy_multiplier)
				or data.persistent_effects ~= nil and type(data.persistent_effects) ~= "table"
			then
				return nil
			end
			local snapshot = { candy_multiplier = data.candy_multiplier, persistent_effects = {} }
			for key, effect in pairs(data.persistent_effects or {}) do
				if
					type(key) ~= "string"
					or type(effect) ~= "table"
					or type(effect.type) ~= "string"
					or effect.amount ~= nil and not finite(effect.amount)
				then
					return nil
				end
				snapshot.persistent_effects[key] = {
					type = effect.type,
					amount = effect.amount,
					stat = type(effect.stat) == "string" and effect.stat or nil,
					damage_type = type(effect.damage_type) == "string" and effect.damage_type or nil,
				}
			end
			return snapshot
		end

		return Priority
	end)()
	-- End Card priority scoring.

	local shared = type(getgenv) == "function" and getgenv() or _G
	for _, store in ipairs({ shared, _G }) do
		for _, key in ipairs({ "__BocchiReworkedCleanup", "__CyndralDevCleanup" }) do
			local close = store[key]
			store[key] = nil
			if type(close) == "function" then
				pcall(close)
			end
		end
		local win = store.__BocchiReworkedWindow
		store.__BocchiReworkedWindow = nil
		if win then
			pcall(function()
				win:Destroy()
			end)
		end
	end
	local runId = {}
	shared.__BocchiReworkedRun = runId
	local BANNER_WEBHOOK_URL = ""

	local function service(name)
		local obj = game:GetService(name)
		if type(cloneref) == "function" then
			local ok, ref = pcall(cloneref, obj)
			if ok and ref then
				return ref
			end
		end
		return obj
	end

	local HttpService = service("HttpService")
	local Players = service("Players")
	local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local MacUI = UI

	local function boot(parent)
		local RS = service("ReplicatedStorage")
		if shared.__BocchiReworkedRun ~= runId then
			return
		end
		local context = {
			get = getthreadidentity or getidentity or (syn and syn.get_thread_identity),
			set = setthreadidentity or setidentity or (syn and syn.set_thread_identity),
		}
		if type(context.get) == "function" and type(context.set) == "function" then
			local ok, id = pcall(context.get)
			if ok then
				context.id = id
			end
		end
		local function restoreUI()
			if context.id then
				context.set(context.id)
			end
		end
		local win = MacUI:CreateWindow({
			Title = "Bocchi",
			Account = { Enabled = false },
			Parent = parent,
			Size = UDim2.fromOffset(920, 650),
			ToggleKey = Enum.KeyCode.RightShift,
			Resizable = true,
			Draggable = true,
			Theme = "Dark",
		})
		if shared.__BocchiReworkedRun ~= runId then
			win:Destroy()
			return
		end
		shared.__BocchiReworkedWindow = win
		_G.__BocchiReworkedWindow = win
		do
			local theme, tweenService = MacUI.Theme, game:GetService("TweenService")
			local overlay = Instance.new("TextButton")
			overlay.Name, overlay.Text, overlay.AutoButtonColor = "LoadingOverlay", "", false
			overlay.BackgroundColor3, overlay.BorderSizePixel = theme.get("Background"), 0
			overlay.Size, overlay.ZIndex, overlay.Parent = UDim2.fromScale(1, 1), 100, win.frame
			overlay.ClipsDescendants = true
			local loadingCorner = Instance.new("UICorner")
			loadingCorner.CornerRadius, loadingCorner.Parent = UDim.new(0, theme.get("RadiusWindow")), overlay
			win.cleanup:add(overlay)
			local content = Instance.new("CanvasGroup")
			content.Name, content.BackgroundTransparency, content.Size = "LoadingContent", 1, UDim2.fromScale(1, 1)
			content.ZIndex, content.Parent = 101, overlay

			local center = Instance.new("Frame")
			center.Name, center.BackgroundTransparency, center.AnchorPoint = "LoadingCenter", 1, Vector2.new(0.5, 0.5)
			center.Position, center.Size, center.ZIndex, center.Parent = UDim2.fromScale(0.5, 0.5), UDim2.new(1, -48, 0, 260), 102, content
			local limit = Instance.new("UISizeConstraint")
			limit.MaxSize, limit.Parent = Vector2.new(520, 260), center
			local title = Instance.new("TextLabel")
			title.BackgroundTransparency, title.Size, title.Position = 1, UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 0)
			title.FontFace, title.TextSize, title.TextColor3 = theme.Typography.WindowTitle.FontFace, 22, theme.get("TextPrimary")
			title.Text, title.ZIndex, title.Parent = "Loading...", 103, center
			local detail = Instance.new("TextLabel")
			detail.Name, detail.BackgroundTransparency, detail.Position, detail.Size = "Detail", 1, UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 32)
			detail.FontFace, detail.TextSize, detail.TextColor3 = theme.Typography.Description.FontFace, 13, theme.get("TextSecondary")
			detail.TextWrapped, detail.Text, detail.ZIndex, detail.Parent = true, "Preparing your settings", 103, center

			-- A small vector-style guitarist; all pieces are local GUI objects.
			local figure = Instance.new("Frame")
			figure.Name, figure.BackgroundTransparency, figure.AnchorPoint = "Guitarist", 1, Vector2.new(0.5, 0)
			figure.Position, figure.Size, figure.ZIndex, figure.Parent = UDim2.new(0.5, 0, 0, 75), UDim2.fromOffset(122, 116), 103, center
			local function shape(name, x, y, w, h, color, rotation, radius, z)
				local part = Instance.new("Frame")
				part.Name, part.Position, part.Size = name, UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
				part.BackgroundColor3, part.BorderSizePixel, part.Rotation = color, 0, rotation or 0
				part.ZIndex, part.Parent = z or 104, figure
				if radius then local c = Instance.new("UICorner"); c.CornerRadius, c.Parent = UDim.new(0, radius), part end
				return part
			end
			local ink, accent, light = theme.get("TextSecondary"), theme.get("Accent"), theme.get("TextPrimary")
			shape("LeftLeg", 42, 76, 10, 37, ink, 9, 5)
			shape("RightLeg", 60, 76, 10, 37, ink, -12, 5)
			shape("Body", 38, 30, 38, 52, ink, -5, 12)
			shape("Head", 43, 2, 28, 28, light, 0, 14)
			shape("Hair", 42, 1, 30, 12, accent, -8, 6, 105)
			shape("GuitarNeck", 68, 50, 48, 7, accent, -24, 3, 106)
			shape("GuitarBody", 35, 57, 44, 27, accent, -12, 12, 106)
			shape("Pickup", 52, 65, 13, 3, theme.get("Background"), -12, 1, 107)
			local arm = shape("StrummingArm", 47, 42, 10, 35, light, -35, 5, 108)
			local armTween = tweenService:Create(arm, TweenInfo.new(0.24, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = -65 })
			local sway = tweenService:Create(figure, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 3 })
			armTween:Play(); sway:Play()
			-- 13 frames from the supplied GIF, stored as a local sprite sheet.
			-- Executors without custom asset support keep the built-in guitarist.
			task.defer(function()
				local assetFn = getcustomasset or getsynasset
				if type(assetFn) ~= "function" or type(writefile) ~= "function" then return end
				local path = "bocchi_loading_guitar_v2.png"
				local ok, asset = pcall(function()
					if not isfile or not isfile(path) then
						local encoded = [=[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]=]
						local decode = crypt and crypt.base64 and crypt.base64.decode
							or crypt and crypt.base64decode or base64_decode
						local bytes
						if type(decode) == "function" then
							bytes = decode(encoded)
						else
							local alphabet, lookup = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", {}
							for i = 1, #alphabet do lookup[alphabet:sub(i, i)] = i - 1 end
							bytes = encoded:gsub("....", function(chunk)
								local a, b = lookup[chunk:sub(1, 1)], lookup[chunk:sub(2, 2)]
								local c, d = lookup[chunk:sub(3, 3)], lookup[chunk:sub(4, 4)]
								local n = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
								local first = string.char(math.floor(n / 65536) % 256)
								local second = c and string.char(math.floor(n / 256) % 256) or ""
								local third = d and string.char(n % 256) or ""
								return first .. second .. third
							end)
						end
						writefile(path, bytes)
					end
					return assetFn(path)
				end)
				if not ok or type(asset) ~= "string" or win._loadingOverlay ~= overlay then return end
				local sprite = Instance.new("ImageLabel")
				sprite.Name, sprite.BackgroundTransparency, sprite.AnchorPoint = "BocchiGif", 1, Vector2.new(0.5, 0.5)
				sprite.Position, sprite.Size, sprite.ZIndex = UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(112, 115), 110
				sprite.Image, sprite.ImageRectSize, sprite.Parent = asset, Vector2.new(200, 206), figure
				local loaded = os.clock()
				while sprite.Parent and not sprite.IsLoaded and os.clock() - loaded < 3 do task.wait(0.05) end
				if not sprite.Parent or not sprite.IsLoaded or win._loadingOverlay ~= overlay then sprite:Destroy(); return end
				for _, child in ipairs(figure:GetChildren()) do
					if child:IsA("Frame") then child.Visible = false end
				end
				armTween:Cancel(); sway:Cancel(); figure.Rotation = 0
				local start = os.clock()
				while sprite.Parent and win._loadingOverlay == overlay do
					local frame = math.floor((os.clock() - start) / 0.08) % 13
					sprite.ImageRectOffset = Vector2.new((frame % 4) * 200, math.floor(frame / 4) * 206)
					task.wait(0.04)
				end
			end)

			local track = Instance.new("Frame")
			track.Name, track.AnchorPoint, track.Position = "ProgressTrack", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 220)
			track.Size, track.BackgroundColor3, track.ClipsDescendants = UDim2.new(1, 0, 0, 4), theme.get("SurfaceActive"), true
			track.BorderSizePixel, track.ZIndex, track.Parent = 0, 103, center
			local trackCorner = Instance.new("UICorner"); trackCorner.CornerRadius, trackCorner.Parent = UDim.new(1, 0), track
			local bar = Instance.new("Frame")
			bar.Name, bar.Size, bar.BackgroundColor3 = "Progress", UDim2.fromScale(0, 1), accent
			bar.BorderSizePixel, bar.ZIndex, bar.Parent = 0, 104, track
			local barCorner = Instance.new("UICorner"); barCorner.CornerRadius, barCorner.Parent = UDim.new(1, 0), bar
			local percent = Instance.new("TextLabel")
			percent.BackgroundTransparency, percent.Position, percent.Size = 1, UDim2.new(0, 0, 0, 230), UDim2.new(1, 0, 0, 20)
			percent.FontFace, percent.TextSize, percent.TextColor3 = theme.Typography.Description.FontFace, 12, theme.get("TextSecondary")
			percent.Text, percent.ZIndex, percent.Parent = "0%", 103, center
			win._loadingOverlay, win._loadingDetail = overlay, detail
			local completing, progressTween = false, nil
			local progress = Instance.new("NumberValue")
			progress.Name, progress.Value, progress.Parent = "LoadingProgress", 0, content
			progress:GetPropertyChangedSignal("Value"):Connect(function()
				local value = math.clamp(progress.Value, 0, 100)
				percent.Text = tostring(math.floor(value + 0.5)) .. "%"
				bar.Size = UDim2.fromScale(value / 100, 1)
			end)
			win.finishBocchiLoading = function()
				if win._loadingOverlay ~= overlay or completing then return end
				local completed = (win._uiLoaded and 1 or 0) + (win._dataLoaded and 1 or 0)
				local value = completed * 50
				if progressTween then progressTween:Cancel() end
				progressTween = tweenService:Create(progress, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = value })
				progressTween:Play()
				if completed == 2 then
					completing = true
					task.delay(1.5, function()
						if win._loadingOverlay ~= overlay then return end
						win._loadingOverlay, win._loadingDetail = nil, nil
						armTween:Cancel(); sway:Cancel()
						tweenService:Create(overlay, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
						local fade = tweenService:Create(content, TweenInfo.new(0.22), { GroupTransparency = 1 })
						fade.Completed:Once(function() overlay:Destroy() end)
						fade:Play()
					end)
				end
			end
		end
		win.ctx.buildYield = function(stage)
			win._buildStage = stage
			win._buildCount = (win._buildCount or 0) + 1
			if win._buildCount % 3 == 0 then
				task.wait()
				if win.destroyed or shared.__BocchiReworkedRun ~= runId then
					error("UI initialization cancelled", 0)
				end
			end
		end
		if win.mobileLauncher then
			local launcher = win.mobileLauncher
			launcher.icon:Destroy()
			launcher.icon = MacUI.Icons.create("rbxassetid://89594789758695", 36, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Parent = launcher.button,
			})
		end
		local pages = {}
		for _, row in ipairs({
			{ "Dashboard", "Version 1.0.16", "four-squares-grid" },
			{ "Teleport", "Choose a map and join a lobby.", "location-pin" },
			{ "Portals", "Open, start and filter portals.", "globe" },
			{ "Dungeon", "Rooms, shrine offers and shops.", "map" },
			{ "Summer Event", "Solo or matchmaking Summer Hunt, card priority and event inventory.", "gift-box" },
			{ "Gameplay", "Units, placement, upgrades and buffs.", "sword" },
			{ "Unit", "Sell units and manage skins.", "person" },
			{ "Macro", "Record a run or replay a saved macro.", "play" },
			{ "Match", "Start, replay and leave matches.", "flag" },
			{ "Rewards", "Quest rewards and capsules.", "gift-box" },
			{ "Misc", "Privacy and world visibility.", "eye" },
			{ "Config", "Save and share configurations.", "folder" },
		}) do
			pages[row[1]] = win:AddPage({
				Id = row[1],
				Title = row[1],
				Description = row[2],
				Icon = row[3],
				Group = (row[1] == "Misc" or row[1] == "Config") and 2 or 1,
			})
		end
		local function section(page, title, description, layout)
			return pages[page]:AddSection({ Title = title, Description = description, Layout = layout })
		end
		do
			local log = section("Dashboard", "Updates"):AddUpdateLog({
				Id = "feature-updates", Title = "Update Logs", InitialVisibleCount = 5, Expandable = true,
			})
			UI.UpdateLogs(log:GetWriters())
		end
		local macroSec = section("Macro", "Record / Play")
		local run = macroSec:AddCard({ Id = "macro-status", Title = "Macro status", Icon = "chart-line" })
		local files = section("Macro", "Library"):AddCard({
			Id = "macro-files",
			Title = "Macro files",
			Description = "Choose, create or manage a saved run.",
			Icon = "folder",
			Collapsible = true,
			DefaultExpanded = true,
		})
		local maps
		local dir = "bocchi reworked/Anime Adventures/"
		local cfgPath = "bocchi reworked/Settings_" .. LP.Name .. ".json"
		local profiles = {
			root = dir .. "Configs/",
			dir = dir .. "Configs/General/",
			mode = "General",
			activeMode = "General",
			modes = {
				"General",
				"Story",
				"Infinite",
				"Legend",
				"Raid",
				"Portal",
				"Dungeon",
				"Summer Hunt",
				"Infinite Castle",
				"Challenge",
			},
			index = "bocchi reworked/CurrentConfig_" .. LP.Name .. ".json",
			name = "Default",
			default = cfgPath,
		}
		local cfg = {
			["Play Macro"] = false,
			["Selected Macro"] = "",
			["Step Delay"] = 0.4,
			["Selected Macro Map"] = {},
		}
		local mode, inv, units, rem, rec, play, pick, links, mapLink, clean, unload
		local playedMap, playedUnits, modeMenu, gameplayFlush, gameplaySave
		local macroWaitForResult = false
		local seq, sync, dead = 0, false, false
		local cons = {}
		local draft = _G.__MacroDraft
		local kinds = {
			spawn_unit = "Spawn",
			upgrade_unit_ingame = "Upgrade",
			sell_unit_ingame = "Sell",
			cycle_priority = "Priority",
			vote_wave_skip = "Skip Wave",
		}

		local status = run:AddStatus({ Title = "State", Value = "Idle", Kind = "Neutral" })
		local action = run:AddParagraph({ Content = "Action: -" })
		local info = files:AddParagraph({ Content = "Units: -" })

		local function notify(err)
			if not dead then
				pcall(function()
					win:Notify({ Title = "bocchi reworked.", Content = tostring(err), Kind = "error" })
				end)
			end
		end

		local function check(fn)
			if dead then
				return false
			end
			local ok, err = pcall(fn)
			if not ok then
				notify(err)
			end
			return ok
		end

		do
			local dashboard = section("Dashboard", "bocchi reworked\\Anime Adventures")
			local discord = dashboard:AddCard({
				Id = "dashboard-discord",
				Title = "Discord",
				Description = "Click the invite to copy.",
				Icon = "rbxthumb://type=Asset&id=10367063084&w=150&h=150",
			})
			discord:AddButton({
				Title = "https://discord.gg/pGmepY6TC",
				Callback = function()
					check(function()
						assert(type(setclipboard) == "function", "Executor clipboard unavailable.")
						setclipboard("https://discord.gg/pGmepY6TC")
						win:Notify({ Title = "Discord", Content = "Invite copied.", Kind = "success" })
					end)
				end,
			})
		end
		local function valid(name)
			return type(name) == "string"
				and #name > 0
				and #name <= 80
				and name:find("%S")
				and not name:find('[\\/:*?"<>|%c]')
				and not name:find("[. ]$")
		end

		local function path(name)
			assert(valid(name), "Choose a valid macro name.")
			if isfile(dir .. name .. ".json") then
				return dir .. name .. ".json"
			end
			if isfile(dir .. name) then
				return dir .. name
			end
			error("Macro not found: " .. name)
		end

		local function finite(n)
			return type(n) == "number" and n == n and math.abs(n) < math.huge
		end

		local function frame(text)
			assert(type(text) == "string", "Missing macro position.")
			local nums = string.split(text, ",")
			assert(#nums == 12, "Invalid macro CFrame.")
			for i, v in ipairs(nums) do
				nums[i] = tonumber(v)
				assert(finite(nums[i]), "Invalid macro CFrame component.")
			end
			return CFrame.new(table.unpack(nums))
		end

		local function readrows(data)
			assert(type(data) == "table", "Invalid macro data.")
			local rows = {}
			for key, row in pairs(data) do
				local n = tonumber(key)
				assert(finite(n) and n >= 1 and n % 1 == 0, "Invalid step number.")
				assert(type(row) == "table" and kinds[row.type], "Unknown macro action.")
				assert(finite(row.money) and row.money >= 0, "Invalid step cost.")
				assert(row.wave == nil or (finite(row.wave) and row.wave >= 0), "Invalid step wave.")
				if row.type == "spawn_unit" then
					assert(type(row.unit) == "string" and row.unit ~= "", "Missing spawn unit.")
				end
				if row.type ~= "vote_wave_skip" then
					row.cf = frame(row.type == "spawn_unit" and row.cframe or row.pos)
				end
				table.insert(rows, { n = n, row = row })
			end
			table.sort(rows, function(a, b)
				return a.n < b.n
			end)
			local out = {}
			for _, v in ipairs(rows) do
				table.insert(out, v.row)
			end
			return out
		end

		local function read(name)
			return readrows(HttpService:JSONDecode(readfile(path(name))))
		end

		local function settings(data)
			assert(type(data) == "table", "Invalid config data.")
			if data.Format ~= nil then
				assert(
					data.Format == "bocchi reworked.config" and data.Version == 1 and type(data.Settings) == "table",
					"Unsupported config format."
				)
				data = data.Settings
				for _, key in ipairs({
					"Discord Url",
					"Discord UserID",
					"Result Webhook",
					"Auto Execute",
					"Execute Source",
				}) do
					data[key] = nil
				end
			end
			for _, key in ipairs({
				"Auto Place Units",
				"Auto Upgrade",
				"Auto Use Skill",
				"Auto Summer Quests",
				"Auto Summer Bingo",
				"Auto Open Sunny Stars",
			}) do
				data[key] = nil
			end
			return data
		end
		function profiles.folder(value)
			assert(table.find(profiles.modes, value), "Choose a valid config gamemode.")
			return profiles.root .. value .. "/"
		end
		function profiles.path(value, gamemode)
			assert(valid(value), "Enter a valid config name.")
			assert(value ~= "Settings_" .. LP.Name, "This filename is reserved for the default config.")
			return profiles.folder(gamemode or profiles.mode)
				.. (value == "Default" and ("Settings_" .. LP.Name) or value)
				.. ".json"
		end
		local ready = check(function()
			assert(
				isfolder and makefolder and isfile and readfile and writefile and listfiles and delfile,
				"Executor needs file functions to use macros."
			)
			if not isfolder("bocchi reworked") then
				makefolder("bocchi reworked")
			end
			if not isfolder(dir) then
				makefolder(dir)
			end
			if not isfolder(profiles.root) then
				makefolder(profiles.root)
			end
			for _, gamemode in ipairs(profiles.modes) do
				local folder = profiles.folder(gamemode)
				if not isfolder(folder) then
					makefolder(folder)
				end
			end
			local old = "cyndral.dev/"
			if isfolder(old .. "Anime Adventures/") then
				for _, file in ipairs(listfiles(old .. "Anime Adventures/")) do
					local name = file:match("[^/\\]+$")
					if name and valid(name) and not isfolder(file) and not isfile(dir .. name) then
						writefile(dir .. name, readfile(file))
					end
				end
			end
			local previous = old .. "Settings_" .. LP.Name .. ".json"
			if not isfile(cfgPath) and isfile(previous) then
				writefile(cfgPath, readfile(previous))
			end
			local function copy(old, target)
				if isfile(old) and not isfile(target) then
					local text = readfile(old)
					local ok, err = pcall(function()
						writefile(target, text)
						assert(readfile(target) == text, "Config migration write failed.")
					end)
					if not ok then
						pcall(delfile, target)
						error(err, 0)
					end
				end
			end
			local marker = profiles.root .. ".gamemode-folders"
			if not isfile(marker) then
				local function copyFolder(source, target)
					if not isfolder(source) then
						return
					end
					for _, file in ipairs(listfiles(source)) do
						local parent, name = file:gsub("\\", "/"):match("^(.-)([^/]+)%.json$")
						if
							parent
							and parent:sub(-#source) == source
							and valid(name)
							and name ~= "Default"
							and not isfolder(file)
						then
							copy(file, target .. name .. ".json")
						end
					end
				end
				local oldConfigs = "bocchi reworked/Configs/"
				for _, gamemode in ipairs(profiles.modes) do
					copyFolder(oldConfigs .. gamemode .. "/", profiles.folder(gamemode))
				end
				if not isfile(oldConfigs .. ".gamemode-folders") then
					copyFolder(oldConfigs, profiles.folder("General"))
				end
				copyFolder(profiles.root, profiles.folder("General"))
				writefile(marker, "1")
			end
			copy(cfgPath, profiles.path("Default"))
			if isfile(profiles.index) then
				local ok, selection = pcall(function()
					return HttpService:JSONDecode(readfile(profiles.index))
				end)
				local gamemode = type(selection) == "table" and selection.Mode or "General"
				local name = type(selection) == "table" and selection.Name or selection
				if
					ok
					and table.find(profiles.modes, gamemode)
					and valid(name)
					and name ~= "Settings_" .. LP.Name
					and isfile(profiles.path(name, gamemode))
				then
					profiles.mode, profiles.activeMode, profiles.name = gamemode, gamemode, name
				end
			end
			profiles.dir = profiles.folder(profiles.mode)
			profiles.default = profiles.path("Default")
			cfgPath = profiles.path(profiles.name)
			if isfile(cfgPath) then
				local data = settings(HttpService:JSONDecode(readfile(cfgPath)))
				assert(type(data) == "table", "Invalid macro settings.")
				for key, value in pairs(data) do
					cfg[key] = value
				end
			else
				writefile(cfgPath, HttpService:JSONEncode(cfg))
			end
		end)
		if not valid(cfg["Selected Macro"]) then
			cfg["Selected Macro"] = ""
		end
		cfg["Play Macro"] = cfg["Play Macro"] == true
		local delay = tonumber(cfg["Step Delay"])
		cfg["Step Delay"] = finite(delay) and math.clamp(delay, 0.2, 10) or 0.4
		if type(cfg["Selected Macro Map"]) ~= "table" then
			cfg["Selected Macro Map"] = {}
		end
		for _, group in ipairs({ "Main", "Tower", "Raid", "Portal", "Other" }) do
			if type(cfg["Selected Macro Map"][group]) ~= "table" then
				cfg["Selected Macro Map"][group] = {}
			end
		end

		local autoPlayStorage = { root = dir .. "AutoPlay/", separated = false }
		function autoPlayStorage.path(file)
			file = file or cfgPath
			assert(file:sub(1, #profiles.root) == profiles.root, "Invalid Auto Play config path.")
			return autoPlayStorage.root .. file:sub(#profiles.root + 1)
		end
		function autoPlayStorage.document(value)
			assert(
				type(value) == "table" and (value.Version == 1 or value.Version == 2 or value.Version == 3),
				"Invalid Auto Play config."
			)
			assert(value.Settings == nil or type(value.Settings) == "table", "Invalid Auto Play settings.")
			local positions = value.Settings and value.Settings.AutoPlacePositions or {}
			assert(type(positions) == "table", "Invalid Auto Play positions.")
			for map, slots in pairs(positions) do
				assert(type(map) == "string" and type(slots) == "table", "Invalid Auto Play map positions.")
				for slot, cf in pairs(slots) do
					assert(
						type(slot) == "string" and (slot == "Center" or slot:match("^Unit[1-6]$")),
						"Invalid Auto Play position slot."
					)
					frame(cf)
				end
			end
			return {
				Version = 3,
				Editor = UI.UnitSettings.normalizeState(value.Editor),
				Settings = { AutoPlacePositions = positions },
			}
		end
		function autoPlayStorage.read(file)
			local raw = readfile(file)
			assert(#raw <= 2097152, "Auto Play config exceeds 2 MB.")
			return autoPlayStorage.document(HttpService:JSONDecode(raw))
		end
		local function mainSettings(value)
			local out = table.clone(value)
			if autoPlayStorage.separated then
				out.AutoPlayEditor, out.AutoPlacePositions = nil, nil
			end
			return out
		end
		local function saveCfg()
			if not ready then
				return false
			end
			return check(function()
				local raw = HttpService:JSONEncode(mainSettings(cfg))
				if isfile(cfgPath) then
					local previous = readfile(cfgPath)
					assert(
						type(HttpService:JSONDecode(previous)) == "table",
						"Existing config is invalid; preserved without overwriting."
					)
					writefile(cfgPath .. ".bak", previous)
				end
				writefile(cfgPath, raw)
				assert(readfile(cfgPath) == raw, "Config write verification failed; previous config retained in .bak")
			end)
		end
		local transfer = { dir = "bocchi reworked/Exports/" }
		function transfer.name(folder, name)
			local out, n = name, 1
			while isfile(folder .. out .. ".json") or isfile(folder .. out) do
				n += 1
				assert(n <= 1000, "Too many files with this name.")
				out = name .. " (" .. n .. ")"
			end
			assert(valid(out), "Filename is too long.")
			return out
		end
		function transfer.write(file, text)
			assert(ready and not dead, "Executor file functions unavailable.")
			assert(not isfile(file), "File already exists.")
			local ok, err = pcall(function()
				writefile(file, text)
				assert(readfile(file) == text, "File write failed.")
			end)
			if not ok then
				pcall(delfile, file)
				error(err, 0)
			end
		end
		function transfer.saved(file)
			win:Notify({ Title = "Sharing", Content = "Saved as " .. file, Kind = "success" })
		end
		function transfer.export(name, text, gamemode)
			assert(ready, "Executor file functions unavailable.")
			if not isfolder(transfer.dir) then
				makefolder(transfer.dir)
			end
			local folder = transfer.dir
			if gamemode then
				assert(table.find(profiles.modes, gamemode), "Choose a valid config gamemode.")
				folder ..= "Configs/"
				if not isfolder(folder) then
					makefolder(folder)
				end
				folder ..= gamemode .. "/"
				if not isfolder(folder) then
					makefolder(folder)
				end
			end
			local file = folder .. transfer.name(folder, name) .. ".json"
			transfer.write(file, text)
			transfer.saved(file)
		end

		local function cdnFetch(url)
			assert(type(url) == "string", "Paste a Discord CDN attachment link.")
			url = url:match("^%s*(.-)%s*$")
			local host, path = url:match("^https://([^/]+)(/[^%s#]+)$")
			local filename = path and path:match("^/attachments/%d+/%d+/([^/?]+)%??[^/]*$")
			assert(
				(host == "cdn.discordapp.com" or host == "media.discordapp.net") and #url <= 4096 and filename,
				"Paste a Discord CDN attachment link."
			)
			filename = filename:gsub("%%(%x%x)", function(hex)
				return string.char(tonumber(hex, 16))
			end)
			assert(
				filename:lower():match("%.json$") or filename:lower():match("%.txt$"),
				"Attachment must be a JSON or TXT file."
			)
			local send = http_request or request or (syn and syn.request) or (http and http.request)
			assert(type(send) == "function", "Executor HTTP request API unavailable.")
			local response = send({ Url = url, Method = "GET", Timeout = 20 })
			assert(
				type(response) == "table" and tonumber(response.StatusCode) == 200,
				"Download failed (HTTP "
					.. tostring(type(response) == "table" and response.StatusCode or "no response")
					.. "). Copy a fresh Discord attachment link."
			)
			assert(
				type(response.Body) == "string" and #response.Body <= 1048576,
				"Invalid or oversized attachment response."
			)
			return response.Body, (filename:gsub("%.%w+$", ""))
		end

		local function owned()
			if not inv then
				assert(RS and RS:FindFirstChild("src"), "Game data not ready.")
				local loader = require(RS.src.Loader)
				inv = loader.load_client_service(script, "ItemInventoryServiceClient")
				units = require(RS.src.Data.Units)
			end
			local session = inv and inv.session
			local collection = session and session.collection
			local profile = collection and collection.collection_profile_data
			assert(profile and type(profile.owned_units) == "table", "Waiting for inventory")
			return profile.owned_units
		end

		local function equipped()
			local out, slots = {}, {}
			for _, unit in pairs(owned()) do
				local slot = unit.equipped_slot
				if slot and (not slots[unit.unit_id] or slot < slots[unit.unit_id]) then
					out[unit.unit_id], slots[unit.unit_id] = unit.uuid, slot
				end
			end
			return out
		end

		local function getRemote(name)
			if not rem then
				local root = RS and RS:FindFirstChild("endpoints")
				rem = root and root:FindFirstChild("client_to_server")
			end
			local obj = rem and rem:FindFirstChild(name)
			assert(obj and obj:IsA("RemoteFunction"), "Missing remote: " .. name)
			return obj
		end

		local function remote(name, ...)
			assert(not dead, "bocchi reworked. is unloaded.")
			local result = getRemote(name):InvokeServer(...)
			if dead then
				if name == "request_join_lobby" then
					local args = { ... }
					pcall(function()
						getRemote("request_leave_lobby"):InvokeServer(args[1])
					end)
				end
				error("Automation cancelled.")
			end
			assert(result ~= false, "Remote rejected: " .. name)
			return result
		end

		local function match()
			local map = workspace:FindFirstChild("_MAP_CONFIG")
			assert(map and map:FindFirstChild("IsLobby") and not map.IsLobby.Value, "Join a match first.")
			local folder = workspace:FindFirstChild("_UNITS")
			assert(folder, "Unit folder not ready.")
			return folder, map
		end

		local function active(id)
			local data = workspace:FindFirstChild("_DATA")
			local done = data and data:FindFirstChild("GameFinished")
			if
				mode == "play"
				and (
					workspace:FindFirstChild("_MAP_CONFIG") ~= playedMap
					or workspace:FindFirstChild("_UNITS") ~= playedUnits
				)
			then
				return false
			end
			return not dead and seq == id and not (done and done.Value)
		end

		local function toggles()
			sync = true
			rec:SetEnabled(mode == "record")
			play:SetEnabled(cfg["Play Macro"])
			sync = false
		end

		local function saveDraft()
			if not draft then
				return true
			end
			local ok = check(function()
				if next(draft.rows) then
					if not draft.backed and isfile(draft.path) then
						writefile(draft.path .. ".bak", readfile(draft.path))
						draft.backed = true
					end
					writefile(draft.path, HttpService:JSONEncode(draft.rows))
				end
			end)
			if ok then
				draft = nil
			end
			_G.__MacroDraft = draft
			return ok
		end

		local function stop(text, keep)
			seq += 1
			mode = nil
			if not keep and cfg["Play Macro"] then
				cfg["Play Macro"] = false
				saveCfg()
			end
			for _, con in ipairs(cons) do
				con:Disconnect()
			end
			table.clear(cons)
			local ok = saveDraft()
			if not dead then
				toggles()
				status:SetValue(
					ok and (text or "Stopped") or "Save failed - Retry Save",
					(not ok or text == "Error") and "Danger" or text == "Ended" and "Success" or "Neutral"
				)
			end
		end

		local function resetMacroForNextMatch(waitForResult)
			if mode == "play" then stop("Waiting for match", true) end
			playedMap, playedUnits = nil, nil
			macroWaitForResult = waitForResult == true
		end

		local function idle()
			assert(not mode, "Stop current macro operation first.")
			assert(not draft, "Save pending recording first.")
			assert(ready and not dead, "Macro unavailable.")
		end

		local function show(row, n, total)
			local text = string.format(
				"Action: %d%s | %s | %s | $%s",
				n,
				total and ("/" .. total) or "",
				kinds[row.type],
				row.unit or "-",
				tostring(row.money)
			)
			action:SetValue(text)
		end

		local function record()
			idle()
			local folder = match()
			local file = path(cfg["Selected Macro"])
			local eq = {}
			for _, unit in pairs(owned()) do
				if unit.equipped_slot then
					eq[unit.uuid] = unit.unit_id
				end
			end
			idle()
			seq += 1
			local id = seq
			if cfg["Play Macro"] then
				cfg["Play Macro"] = false
				saveCfg()
			end
			mode = "record"
			draft = { path = file, rows = {} }
			_G.__MacroDraft = draft
			local rows, seen, count = draft.rows, {}, 0
			local function add(row)
				if not active(id) or mode ~= "record" then
					return
				end
				count += 1
				rows[tostring(count)] = row
				show(row, count)
			end
			local function watch(unit, spawn)
				local stats = unit:WaitForChild("_stats", 5)
				if not stats then
					return
				end
				for _, name in ipairs({ "player", "id", "uuid", "total_spent", "priority" }) do
					if not stats:WaitForChild(name, 5) then
						return
					end
				end
				local shadow = unit:WaitForChild("_shadow", 5)
				if not active(id) or mode ~= "record" or not shadow or unit.Parent ~= folder or seen[unit] then
					return
				end
				local name = stats.id.Value
				if stats.player.Value ~= LP or eq[stats.uuid.Value] ~= name then
					return
				end
				local spent = stats.total_spent.Value
				local entry = { name = name, pos = shadow.CFrame, cons = {} }
				seen[unit] = entry
				if spawn then
					local cf = shadow.CFrame
					local terrain = workspace:FindFirstChild("_terrain")
					if terrain then
						local filter = {}
						for _, part in ipairs({ "ground", "hill" }) do
							local obj = terrain:FindFirstChild(part)
							if obj then
								table.insert(filter, obj)
							end
						end
						local params = RaycastParams.new()
						params.FilterType = Enum.RaycastFilterType.Include
						params.FilterDescendantsInstances = filter
						params.IgnoreWater = true
						local hit = workspace:Raycast(cf.Position, Vector3.new(0, -10, 0), params)
						if hit then
							cf = CFrame.new(hit.Position) * cf.Rotation
						end
					end
					add({ type = "spawn_unit", money = spent, unit = name, cframe = tostring(cf) })
				end
				local function listen(signal, fn)
					local con = signal:Connect(fn)
					table.insert(cons, con)
					table.insert(entry.cons, con)
				end
				listen(stats.total_spent.Changed, function(value)
					local cost = value - spent
					spent = value
					if cost <= 0 then
						return
					end
					entry.pos = shadow.CFrame
					add({
						type = "upgrade_unit_ingame",
						money = cost,
						unit = name,
						pos = tostring(entry.pos),
					})
				end)
				listen(stats.priority.Changed, function()
					entry.pos = shadow.CFrame
					add({ type = "cycle_priority", money = 0, unit = name, pos = tostring(entry.pos) })
				end)
			end
			local function track(unit, spawn)
				local ok, err = pcall(watch, unit, spawn)
				if not ok and seq == id and not dead then
					stop("Error")
					notify(err)
				end
			end
			table.insert(
				cons,
				folder.ChildAdded:Connect(function(unit)
					track(unit, true)
				end)
			)
			table.insert(
				cons,
				folder.ChildRemoved:Connect(function(unit)
					local entry = seen[unit]
					if not entry then
						return
					end
					local shadow = unit:FindFirstChild("_shadow")
					-- ponytail: ChildRemoved coi la ban; them xac nhan remote neu game co chet/thu hoi unit.
					add({
						type = "sell_unit_ingame",
						money = 0,
						unit = entry.name,
						pos = tostring(shadow and shadow.CFrame or entry.pos),
					})
					for _, con in ipairs(entry.cons) do
						con:Disconnect()
					end
					seen[unit] = nil
				end)
			)
			for _, unit in ipairs(folder:GetChildren()) do
				task.spawn(track, unit, false)
			end
			status:SetValue("Recording", "Accent")
			action:SetValue("Action: 0")
			toggles()
			task.spawn(function()
				while active(id) do
					task.wait(0.2)
				end
				if seq == id and not dead then
					stop("Recorded")
				end
			end)
		end

		local function mapName(map)
			local obj = map:FindFirstChild("GetLevelData")
			assert(obj, "Map data not ready.")
			local data = obj:InvokeServer()
			assert(type(data) == "table", "Invalid map data.")
			local list = cfg["Selected Macro Map"]
			local name
			if data.floor_num then
				name = list.Tower[data._location_name]
			elseif data._is_map_or_portal_level then
				name = list.Portal[data._location_name]
			else
				name = list.Raid[data._location_name] or list.Other[data._location_name] or list.Other[data.name]
				if not name and data._gamemode ~= "raid" then
					name = list.Main[data._location_name]
				end
			end
			return valid(name) and name or cfg["Selected Macro"]
		end

		local function findUnit(folder, row, ignore)
			local best, dist = nil, 10
			for _, unit in ipairs(folder:GetChildren()) do
				if ignore and ignore[unit] then
					continue
				end
				local stats, shadow = unit:FindFirstChild("_stats"), unit:FindFirstChild("_shadow")
				if not stats or not shadow or not stats:FindFirstChild("player") or stats.player.Value ~= LP then
					continue
				end
				if row.unit and (not stats:FindFirstChild("id") or stats.id.Value ~= row.unit) then
					continue
				end
				local d = (shadow.Position - row.cf.Position).Magnitude
				if d <= dist then
					best, dist = unit, d
				end
			end
			return best
		end

		local function playback(id)
			local folder, map = match()
			local name = mapName(map)
			if not active(id) then
				return
			end
			local rows, eq = read(name), equipped()
			assert(#rows > 0, "Macro is empty.")
			for _, row in ipairs(rows) do
				if row.type == "spawn_unit" then
					assert(eq[row.unit], "Unit not equipped: " .. row.unit)
				end
			end
			if not active(id) then
				return
			end
			status:SetValue("Playing " .. name, "Accent")
			for i, row in ipairs(rows) do
				if not active(id) then
					return
				end
				show(row, i, #rows)
				repeat
					if not active(id) then
						return
					end
					local stats = LP:FindFirstChild("_stats")
					local money = stats and stats:FindFirstChild("resource")
					local wave = workspace:FindFirstChild("_wave_num")
					local paid = row.type == "sell_unit_ingame"
						or row.type == "vote_wave_skip"
						or (money and money.Value >= row.money)
					if paid and (not row.wave or (wave and wave.Value >= row.wave)) then
						break
					end
					task.wait(0.1)
				until false
				if row.type == "spawn_unit" then
					local before = {}
					for _, unit in ipairs(folder:GetChildren()) do
						before[unit] = true
					end
					remote(row.type, eq[row.unit], row.cf)
					local untilAt = os.clock() + 2.5
					repeat
						if not active(id) then
							return
						end
						if findUnit(folder, row, before) then
							break
						end
						task.wait(0.1)
					until os.clock() >= untilAt
					assert(findUnit(folder, row, before), "Spawn not confirmed at step " .. i)
				elseif row.type == "vote_wave_skip" then
					remote(row.type)
				else
					local unit = findUnit(folder, row)
					assert(unit, "Placed unit missing at step " .. i)
					local stats = unit._stats
					local data = stats:FindFirstChild("id") and units[stats.id.Value]
					local capped = row.type == "upgrade_unit_ingame"
						and data
						and data.upgrade
						and stats:FindFirstChild("upgrade")
						and stats.upgrade.Value >= #data.upgrade
					if not capped then
						remote(row.type, unit)
					end
				end
				local untilAt = os.clock() + cfg["Step Delay"]
				while active(id) and os.clock() < untilAt do
					task.wait(0.05)
				end
			end
		end

		local function startPlay()
			if modeMenu and modeMenu() then
				return
			end
			idle()
			playedUnits, playedMap = match()
			if not cfg["Play Macro"] then
				cfg["Play Macro"] = true
				saveCfg()
			end
			seq += 1
			local id = seq
			mode = "play"
			toggles()
			task.spawn(function()
				local ok, err = pcall(playback, id)
				if seq ~= id or dead then
					return
				end
				-- Playback errors stop this run, but do not change the saved toggle.
				stop(ok and "Ended" or "Error", true)
				if not ok then
					notify(err)
				end
			end)
		end

		local function playTick()
			local map = workspace:FindFirstChild("_MAP_CONFIG")
			local lobby = map and map:FindFirstChild("IsLobby")
			local folder = workspace:FindFirstChild("_UNITS")
			local data = workspace:FindFirstChild("_DATA")
			local done = data and data:FindFirstChild("GameFinished")
			if macroWaitForResult then
				if lobby and lobby.Value then
					macroWaitForResult = false
				elseif not done or done.Value then
					return
				else
					macroWaitForResult = false
				end
			end
			if not lobby or lobby.Value or not folder or not done or done.Value then
				playedMap, playedUnits = nil, nil
				if mode == "play" then
					stop("Waiting for match", true)
				end
			elseif mode == "play" and (playedMap ~= map or playedUnits ~= folder) then
				stop("Waiting for match", true)
			elseif
				cfg["Play Macro"]
				and not mode
				and not draft
				and not (modeMenu and modeMenu())
				and (playedMap ~= map or playedUnits ~= folder)
			then
				if not map:FindFirstChild("GetLevelData") or not pcall(equipped) then
					return
				end
				if not check(startPlay) then
					-- Avoid retrying a broken macro continuously in the same match.
					playedMap, playedUnits = map, folder
					stop("Error", true)
				end
			end
		end

		local function preview()
			info:SetValue("Units: -")
			if cfg["Selected Macro"] == "" then
				return
			end
			local rows = read(cfg["Selected Macro"])
			local names, seen = {}, {}
			for _, row in ipairs(rows) do
				if row.type == "spawn_unit" and not seen[row.unit] then
					seen[row.unit] = true
					table.insert(names, row.unit)
				end
			end
			info:SetValue("Units: " .. (#names > 0 and table.concat(names, ", ") or "-"))
		end

		pick = files:AddDropdown({
			Title = "Selected Macro",
			Options = {},
			Searchable = true,
			Callback = function(name)
				if sync then
					return
				end
				if mode or draft then
					sync = true
					pick:SetValue(cfg["Selected Macro"])
					sync = false
					return
				end
				cfg["Selected Macro"] = name or ""
				saveCfg()
				check(preview)
			end,
		})
		local input = files:AddInput({
			Title = "New Macro",
			Placeholder = "Macro name",
			Validate = function(text)
				return #text <= 80 or "Use at most 80 characters."
			end,
		})

		local function refresh()
			if not ready then
				return
			end
			local names, seen = {}, {}
			for _, file in ipairs(listfiles(dir)) do
				local name = file:gsub("\\", "/"):match("/Anime Adventures/([^/]+)$")
				if isfolder(file) or not name or name:match("%.bak$") then
					continue
				end
				name = name:gsub("%.json$", "")
				if valid(name) and not seen[name] then
					seen[name] = true
					table.insert(names, name)
				end
			end
			table.sort(names)
			sync = true
			pick:SetOptions(names, true)
			if not seen[cfg["Selected Macro"]] then
				cfg["Selected Macro"] = ""
			end
			pick:SetValue(cfg["Selected Macro"])
			if links then
				local options = table.clone(names)
				table.insert(options, 1, "None")
				links:SetOptions(options, true)
				mapLink()
			end
			sync = false
			saveCfg()
			preview()
		end
		do
			local share = section("Macro", "Sharing"):AddCard({
				Id = "macro-sharing",
				Title = "Sharing",
				Icon = "two-arrows-loop-clockwise",
			})
			share:AddButton({
				Title = "Export Macro",
				Callback = function()
					check(function()
						idle()
						local name = cfg["Selected Macro"]
						read(name)
						transfer.export(name, readfile(path(name)))
					end)
				end,
			})
			local link = share:AddInput({
				Title = "Macro Discord Link",
				Default = "",
				Placeholder = "https://cdn.discordapp.com/attachments/.../macro.json",
			})
			share:AddButton({
				Title = "Import Macro",
				Callback = function()
					check(function()
						idle()
						local text, name = cdnFetch(link:GetValue())
						readrows(HttpService:JSONDecode(text))
						name = transfer.name(dir, name)
						transfer.write(dir .. name .. ".json", text)
						cfg["Selected Macro"] = name
						refresh()
						win:Notify({ Title = "Sharing", Content = "Imported macro " .. name, Kind = "success" })
					end)
				end,
			})
		end

		files:AddParagraph({ Content = "Macro folder: " .. dir })
		files:AddButton({
			Title = "Load Macro",
			Callback = function()
				check(function()
					idle()
					read(cfg["Selected Macro"])
					preview()
					win:Notify({
						Title = "Macro",
						Content = "Loaded " .. cfg["Selected Macro"],
						Kind = "success",
					})
				end)
			end,
		})
		files:AddButton({
			Title = "Create Macro",
			Callback = function()
				check(function()
					idle()
					local name = input:GetValue():match("^%s*(.-)%s*$")
					assert(valid(name) and name ~= "None", "Invalid macro name.")
					assert(not isfile(dir .. name) and not isfile(dir .. name .. ".json"), "Macro already exists.")
					writefile(dir .. name .. ".json", "{}")
					cfg["Selected Macro"] = name
					refresh()
				end)
			end,
		})
		files:AddButton({
			Title = "Refresh List",
			Callback = function()
				check(function()
					idle()
					refresh()
				end)
			end,
		})
		files:AddButton({
			Title = "Delete Macro",
			Variant = "Destructive",
			Callback = function()
				check(function()
					idle()
					local name = cfg["Selected Macro"]
					local file = path(name)
					win:Confirm({
						Title = "Delete Macro",
						Content = "Delete " .. name .. "?",
						ConfirmText = "Delete",
						Destructive = true,
						OnConfirm = function()
							check(function()
								idle()
								delfile(file)
								for _, group in pairs(cfg["Selected Macro Map"]) do
									for map, item in pairs(group) do
										if item == name then
											group[map] = nil
										end
									end
								end
								cfg["Selected Macro"] = ""
								refresh()
							end)
						end,
					})
				end)
			end,
		})
		files:AddButton({
			Title = "Equip Macro Units",
			Callback = function()
				check(function()
					idle()
					local rows, pool, need, ids = read(cfg["Selected Macro"]), owned(), {}, {}
					for _, row in ipairs(rows) do
						if row.type ~= "spawn_unit" or need[row.unit] then
							continue
						end
						local uuid
						for _, unit in pairs(pool) do
							if unit.unit_id == row.unit then
								uuid = unit.uuid
								break
							end
						end
						assert(uuid, "Unit not owned: " .. row.unit)
						need[row.unit] = true
						table.insert(ids, uuid)
					end
					assert(#ids > 0 and #ids <= 6, "Macro must use 1 to 6 distinct units.")
					getRemote("unequip_all")
					getRemote("equip_unit")
					idle()
					seq += 1
					local id = seq
					mode = "equip"
					status:SetValue("Equipping")
					task.spawn(function()
						local ok, err = pcall(function()
							if not active(id) then
								return
							end
							remote("unequip_all")
							for _, uuid in ipairs(ids) do
								if not active(id) then
									return
								end
								remote("equip_unit", uuid)
								task.wait(0.5)
							end
						end)
						if seq ~= id or dead then
							return
						end
						stop(ok and "Equipped" or "Error")
						if not ok then
							notify(err)
						end
					end)
				end)
			end,
		})

		rec = macroSec:AddCard({
			Id = "Record Macro",
			Title = "Record Macro",
			Description = "Capture your unit actions into the selected file.",
			Icon = "circle",
			Toggle = true,
			Collapsible = true,
			Default = false,
			Callback = function(on)
				if sync or dead then
					return
				end
				if on then
					if not check(record) then
						if mode == "record" then
							stop("Error")
						else
							toggles()
						end
					end
				elseif mode == "record" then
					stop("Recorded")
					check(preview)
				end
			end,
		})
		play = macroSec:AddCard({
			Id = "Play Macro",
			Title = "Play Macro",
			Description = "Play once per match; stay enabled for the next run.",
			Icon = "play",
			Toggle = true,
			Collapsible = true,
			DefaultExpanded = true,
			Default = cfg["Play Macro"],
			Callback = function(on)
				if sync or dead then
					return
				end
				if on then
					if not check(idle) then
						toggles()
						return
					end
					cfg["Play Macro"] = true
					if not saveCfg() then
						cfg["Play Macro"] = false
						toggles()
						return
					end
					playedMap, playedUnits = nil, nil
					status:SetValue("Waiting for match", "Warning")
					playTick()
				else
					cfg["Play Macro"] = false
					saveCfg()
					if mode == "play" then
						stop()
					else
						toggles()
					end
				end
			end,
		})
		play:AddSlider({
			Title = "Step Delay",
			Min = 0.2,
			Max = 10,
			Default = cfg["Step Delay"],
			Step = 0.01,
			Suffix = "s",
			Callback = function(value)
				cfg["Step Delay"] = value
				saveCfg()
			end,
		})
		run:AddButton({
			Title = "Stop",
			Callback = function()
				stop()
			end,
		})
		run:AddButton({
			Title = "Retry Save",
			Callback = function()
				if mode then
					return
				end
				if saveDraft() then
					status:SetValue("Saved")
					check(preview)
				end
			end,
		})
		rec:AddParagraph({
			Content = "Recording replaces the selected file. Previous data is saved as .bak.",
		})
		play:AddParagraph({
			Content = "Wave skip playback only. Turn this switch off or press Stop to cancel.",
		})

		-- Map names from the game data; runtime data below extends this list after updates.
		local gameMapNames = {
			"Adventurer Town",
			"Alien Spaceship",
			"Alien Spaceship (Final)",
			"Alien Spaceship (Underwater)",
			"Anniversary Island",
			"Ant Kingdom",
			"Ant Kingdom (Midnight)",
			"Ant Kingdom (Summer)",
			"Assassin Park",
			"Cursed Festival",
			"Dungeon Throne",
			"Fabled Kingdom",
			"Fabled Kingdom (Cube)",
			"Fabled Kingdom (Generals)",
			"Fabled Kingdom (Summer)",
			"Fiend City",
			"Fiend City (Winter)",
			"Frozen Abyss",
			"Frozen Abyss (Six Realms)",
			"Future City",
			"Future City (Tyrant's Invasion)",
			"Haunted Academy",
			"Haunted Academy (Frozen)",
			"Haunted Academy (Summer)",
			"Haunted Mansion",
			"Hellish City",
			"Magic Hills",
			"Magic Hills (Demonic)",
			"Magic Hills (Elf Invasion)",
			"Magic Town",
			"Magic Town (Haunted)",
			"Magic Town (Snow)",
			"Mountain Temple",
			"Navy Bay",
			"Navy Bay (Midnight)",
			"Nightmare Train",
			"Otherwordly Plane",
			"Planet Greenie",
			"Planet Greenie (Frozen)",
			"Planet Greenie (Haunted)",
			"Planet Greenie (Summer)",
			"Power Contest",
			"Puppet Island",
			"Puppet Island (Summer)",
			"Puppet Island (Threads)",
			"Rain Village",
			"Ruined City",
			"Ruined City (Midnight)",
			"Sacred Planet",
			"Sand Village",
			"Sand Village (Snow)",
			"Shibuya District",
			"Sky Aircraft",
			"Sky Island",
			"Snowy Kingdom",
			"Snowy Town",
			"Space Center",
			"Space Center (New Moon)",
			"Spirit Town",
			"Spirit Town (Frozen)",
			"Spirit World",
			"Storm Hideout",
			"Storm Hideout (Final)",
			"Strange Town",
			"Strange Town (Haunted)",
			"Virtual Dungeon",
			"Virtual Dungeon (Bosses)",
			"Walled City",
			"Walled City (Midnight)",
			"Walled City (Summer)",
			"Walled City (Winter)",
			"Wish City",
		}
		local mapList = {
			Main = {
				"Fabled Kingdom",
				"Planet Namak",
				"Shiganshinu District",
				"Windhym",
				"Hollow World",
				"Clover Kingdom",
				"Magic Town",
				"Ant Kingdom",
				"Cursed Academy",
				"Cape Canaveral",
				"Marine's Ford",
				"Hero City",
				"Hidden Sand Village",
				"Alien Spaceship",
				"Snowy Town",
				"Virtual Dungeon",
				"Ghoul City",
				"Puppet Island",
				"Undead Tomb",
			},
			Tower = {
				"Thriller Park",
				"Entertainment District",
				"Karakora Town",
				"Storm Hideout",
				"Infinity Train",
			},
			Raid = {
				"Fabled Kingdom (Commandments)",
				"Karakora Town",
				"Entertainment District",
				"Clover Kingdom (Elf Invasion)",
				"Cape Canaveral",
				"Hero City (Midnight)",
				"Infinity Train",
				"Virtual Dungeon (Bosses)",
				"Storm Hideout",
				"Storm Hideout (Final)",
				"West City",
				"Bizzare Town",
				"Hidden Sand Village",
				"Shiganshinu District",
				"Undead Tomb",
			},
			Portal = {
				"Puppet Island (Summer)",
				"Shiganshinu District (Summer)",
				"Fabled Kingdom (Summer)",
				"Alien Spaceship (Underwater)",
				"Planet Namak (Summer)",
				"Ant Kingdom (Summer)",
				"Cursed Academy (Summer)",
				"Fabled Kingdom (Cube)",
				"The Eclipse",
				"Alien Spaceship (Final)",
				"Puppet Island (Birdcage)",
			},
			Other = { "Cursed Womb" },
		}
		for _, list in pairs(mapList) do
			for _, name in ipairs(gameMapNames) do
				if not table.find(list, name) then table.insert(list, name) end
			end
		end
		local group, map = "Main", mapList.Main[1]
		local mapPick
		mapLink = function()
			sync = true
			links:SetValue(cfg["Selected Macro Map"][group][map] or "None")
			sync = false
		end
		maps = section("Macro", "Map bindings"):AddCard({
			Id = "macro-maps",
			Title = "Macros by map",
			Description = "Use a different saved run for each map.",
			Icon = "map",
			Collapsible = true,
		})
		maps:AddDropdown({
			Title = "Mode",
			Options = { "Main", "Tower", "Raid", "Portal", "Other" },
			Default = "Main",
			Callback = function(value)
				group = value
				map = mapList[group][1]
				mapPick:SetOptions(mapList[group], true)
				mapPick:SetValue(map)
				mapLink()
			end,
		})
		mapPick = maps:AddDropdown({
			Title = "Map",
			Options = mapList.Main,
			Default = mapList.Main[1],
			Searchable = true,
			Callback = function(value)
				map = value
				mapLink()
			end,
		})
		links = maps:AddDropdown({
			Title = "Macro For Map",
			Options = { "None" },
			Callback = function(value)
				if sync then
					return
				end
				cfg["Selected Macro Map"][group][map] = value ~= "None" and value or nil
				saveCfg()
			end,
		})

		local function setup()
			local flags, picks, hooks, errors = {}, {}, {}, {}
			local legacyUnits = {}
			for _, key in ipairs({ "AutoPlacesCap", "AutoUpgradesCap", "AutoPlaceWaves", "AutoUpgradeWaves" }) do
				if type(cfg[key]) == "table" then
					legacyUnits[key] = table.clone(cfg[key])
				end
			end
			local D, baseline, levelData, updateData = {}, nil, nil, nil
			local levelMap, levelUnits
			local started, voted, ended, sent = os.clock(), false, nil, false
			local report = {}
			local lock, epoch = false, 0
			local saved, groups, tracked, nextSkill, buffs = {}, {}, {}, {}, {}
			local modes = {}
			local summer = {
				seen = setmetatable({}, { __mode = "k" }),
				cardKind = {},
				cardEffects = {},
				allCards = {
					-- Bad (enemy) cards
					"+ Enemy Speed I",
					"+ Enemy Speed II",
					"+ Enemy Speed III",
					"+ Enemy Speed IV",
					"+ Enemy Speed V",
					"+ Enemy Health I",
					"+ Enemy Health II",
					"+ Enemy Health III",
					"+ Enemy Health IV",
					"+ Enemy Health V",
					"+ Resistant Enemies I",
					"+ Resistant Enemies II",
					"+ Resistant Enemies III",
					"+ Resistant Enemies IV",
					"+ Resistant Enemies V",
					"+ Elemental Resistances I",
					"+ Elemental Resistances II",
					"+ Elemental Resistances III",
					"+ Elemental Resistances IV",
					"+ Elemental Resistances V",
					"+ Enemy Shields I",
					"+ Enemy Shields II",
					"+ Enemy Shields III",
					"+ Enemy Shields IV",
					"+ Enemy Shields V",
					"+ Enemy Regen I",
					"+ Enemy Regen II",
					"+ Enemy Regen III",
					"+ Enemy Regen IV",
					"+ Enemy Regen V",
					"+ Explosive Deaths",
					"+ New Path",
					"+ High Cost I",
					"+ High Cost II",
					"+ High Cost III",
					"+ High Cost IV",
					"+ High Cost V",
					"+ Armored Enemies",
					"+ Flying Enemies",
					"+ Infested I",
					"+ Infested II",
					"+ Infested III",
					"+ Infested IV",
					"+ Infested V",
					"Gain Random Curses",
					-- Good (player) cards
					"+ Range I",
					"+ Range II",
					"+ Range III",
					"+ Range IV",
					"+ Range V",
					"+ Attack Damage I",
					"+ Attack Damage II",
					"+ Attack Damage III",
					"+ Attack Damage IV",
					"+ Attack Damage V",
					"- Cooldown Time I",
					"- Cooldown Time II",
					"- Cooldown Time III",
					"- Cooldown Time IV",
					"- Cooldown Time V",
					"- Active Cooldown Time",
					"+ Boss Damage I",
					"+ Boss Damage II",
					"+ Boss Damage III",
					"+ Boss Damage IV",
					"+ Boss Damage V",
					"+ Damage vs Flying",
					"- Placement/Upgrade Cost",
					"+ Secret Drop Rate",
					"+ Phys Crit Chance",
					"+ Magic Crit Chance",
					"+ Phys Damage",
					"+ Magic Damage",
					"+ True Damage",
					"Gain Random Blessings",
				},
			}

			-- Card names and classifications collected from in-game card effects.
			for _, entry in ipairs({
				{ "+ Attack I", "Buff", { { type = "stat_mul", amount = 0.12, stat = "damage" } } },
				{ "+ Attack II", "Buff", { { type = "stat_mul", amount = 0.25, stat = "damage" } } },
				{ "+ Attack III", "Buff", { { type = "stat_mul", amount = 0.4, stat = "damage" } } },
				{ "+ Boss Damage I", "Buff", { { type = "boss_damage", amount = 0.35 } } },
				{ "+ Double Attack, Double Cooldown", "Mixed", { { type = "stat_mul", stat = "damage", amount = 1 }, { type = "stat_mul", stat = "attack_cooldown", amount = 1 } } },
				{ "+ Double Attack, Half Range", "Mixed", { { type = "stat_mul", stat = "damage", amount = 1 }, { type = "stat_mul", stat = "range", amount = -0.5 } } },
				{ "+ Enemy Health I", "Debuff", { { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Enemy Health II", "Debuff", { { type = "enemy_stat_mul", amount = 0.8, stat = "health" }, { type = "secret_drop", amount = 0.25 }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Enemy Health III", "Debuff", { { type = "enemy_stat_mul", amount = 2.0, stat = "health" }, { type = "secret_drop", amount = 0.5 }, { type = "candy_multiplier", amount = 1.5 } } },
				{ "+ Enemy Regen I", "Debuff", { { type = "enemy_regen", amount = 0.005 }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Enemy Regen II", "Debuff", { { type = "enemy_regen", amount = 0.02 }, { type = "secret_drop", amount = 0.25 }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Enemy Regen III", "Debuff", { { type = "enemy_regen", amount = 0.05 }, { type = "secret_drop", amount = 0.5 }, { type = "candy_multiplier", amount = 1.5 } } },
				{ "+ Enemy Shield I", "Debuff", { { type = "enemy_shield", amount = 3.0 }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Enemy Shield II", "Debuff", { { type = "enemy_shield", amount = 6.0 }, { type = "secret_drop", amount = 0.25 }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Enemy Speed I", "Debuff", { { type = "enemy_speedup", amount = 0.25 }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Enemy Speed II", "Debuff", { { type = "enemy_speedup", amount = 0.5 }, { type = "secret_drop", amount = 0.25 }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Enemy Speed III", "Debuff", { { type = "enemy_speedup", amount = 1.0 }, { type = "secret_drop", amount = 0.5 }, { type = "candy_multiplier", amount = 1.5 } } },
				{ "+ Explosive Deaths I", "Debuff", { { type = "enemy_bomb", amount = 6.0 }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Explosive Deaths II", "Debuff", { { type = "enemy_bomb", amount = 12.0 }, { type = "secret_drop", amount = 0.25 }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Explosive Deaths III", "Debuff", { { type = "enemy_bomb", amount = 24.0 }, { type = "secret_drop", amount = 0.5 }, { type = "candy_multiplier", amount = 1.5 } } },
				{ "+ Plated Enemies I", "Debuff", { { type = "enemy_resistance_specific", amount = 75.0, damage_type = "physical" }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Plated Enemies II", "Debuff", { { type = "enemy_resistance_specific", amount = 150.0, damage_type = "physical" }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Random Blessings I", "Buff", { { type = "random_effects", amount = 2, tier = 1, _type = "Good" } } },
				{ "+ Random Curses I", "Debuff", { { type = "random_effects", amount = 2, tier = 1, _type = "Bad" }, { type = "secret_drop", amount = 0.25 }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Random Curses II", "Debuff", { { type = "random_effects", amount = 2, tier = 2, _type = "Bad" }, { type = "secret_drop", amount = 0.5 }, { type = "candy_multiplier", amount = 1.5 } } },
				{ "+ Range I", "Buff", { { type = "stat_mul", amount = 0.15, stat = "range" } } },
				{ "+ Range II", "Buff", { { type = "stat_mul", amount = 0.25, stat = "range" } } },
				{ "+ Range III", "Buff", { { type = "stat_mul", amount = 0.35, stat = "range" } } },
				{ "+ Resistant Enemies I", "Debuff", { { type = "enemy_resistance_specific", amount = 50.0, damage_type = "physical" }, { type = "enemy_resistance_specific", amount = 50.0, damage_type = "magic" }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Resistant Enemies II", "Debuff", { { type = "enemy_resistance_specific", amount = 100.0, damage_type = "physical" }, { type = "enemy_resistance_specific", amount = 100.0, damage_type = "magic" }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Resistant Enemies III", "Debuff", { { type = "enemy_resistance_specific", amount = 200.0, damage_type = "physical" }, { type = "enemy_resistance_specific", amount = 200.0, damage_type = "magic" }, { type = "secret_drop", amount = 0.5 }, { type = "candy_multiplier", amount = 1.5 } } },
				{ "+ Spellproof Enemies I", "Debuff", { { type = "enemy_resistance_specific", amount = 75.0, damage_type = "magic" }, { type = "candy_multiplier", amount = 0.3 } } },
				{ "+ Spellproof Enemies II", "Debuff", { { type = "enemy_resistance_specific", amount = 150.0, damage_type = "magic" }, { type = "candy_multiplier", amount = 0.7 } } },
				{ "+ Spellproof Enemies III", "Debuff", { { type = "enemy_resistance_specific", amount = 300.0, damage_type = "magic" }, { type = "secret_drop", amount = 0.5 }, { type = "candy_multiplier", amount = 1.5 } } },
				{ "+ Yen I", "Buff", { { type = "resource_gain", amount = 3000.0 } } },
				{ "+ Yen II", "Buff", { { type = "resource_gain", amount = 6000.0 } } },
				{ "+ Yen III", "Buff", { { type = "resource_gain", amount = 12000.0 } } },
				{ "- Active Cooldown I", "Buff", { { type = "stat_mul", amount = -0.2, stat = "active_attack_cooldown" } } },
				{ "- Active Cooldown II", "Buff", { { type = "stat_mul", amount = -0.3, stat = "active_attack_cooldown" } } },
				{ "- Cooldown I", "Buff", { { type = "stat_mul", amount = -0.05, stat = "attack_cooldown" } } },
				{ "- Cooldown II", "Buff", { { type = "stat_mul", amount = -0.1, stat = "attack_cooldown" } } },
				{ "- Cooldown III", "Buff", { { type = "stat_mul", amount = -0.15, stat = "attack_cooldown" } } },
				{ "✨ Arcane Storm", "Debuff", { { type = "enemy_resistance_specific", amount = 150.0, damage_type = "physical" }, { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 1.0 } } },
				{ "✨ Arcane Ward", "Debuff", { { type = "enemy_resistance_specific", amount = 75.0, damage_type = "physical" }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "✨ Dispel", "Buff", { { type = "enemy_resistance_specific", amount = -110.0, damage_type = "physical" } } },
				{ "✨ Leyline", "Buff", { { type = "stat_mul", amount = -0.15, stat = "attack_cooldown" } } },
				{ "✨ Mana Shield", "Debuff", { { type = "enemy_shield", amount = 3.0 }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "✨ Mana Surge", "Buff", { { type = "enemy_amp_specific", amount = 0.4, damage_type = "magic" } } },
				{ "❄️ Bonfire", "Buff", { { type = "enemy_amp_specific", amount = 0.75, damage_type = "fire_damage" } } },
				{ "❄️ Frostbite", "Buff", { { type = "enemy_speedup", amount = -0.3 } } },
				{ "❄️ Hailstorm", "Debuff", { { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "❄️ Ice Breaker", "Buff", { { type = "boss_damage", amount = 0.5 } } },
				{ "❄️ Permafrost", "Debuff", { { type = "enemy_shield", amount = 3.0 }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "❄️ Whiteout", "Debuff", { { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "stat_mul", amount = -0.15, stat = "range" }, { type = "candy_multiplier", amount = 1.0 } } },
				{ "🌊 Low Tide", "Buff", { { type = "enemy_speedup", amount = -0.25 } } },
				{ "🌊 Rising Tide", "Debuff", { { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🌊 Salvage", "Buff", { { type = "resource_gain", amount = 6000.0 } } },
				{ "🌊 Tidal Surge", "Debuff", { { type = "burst_speed", amount = 0.5 }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🌊 Tsunami", "Debuff", { { type = "enemy_speedup", amount = 0.5 }, { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 1.0 } } },
				{ "🌧️ Flash Flood", "Debuff", { { type = "enemy_speedup", amount = 0.25 }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🌧️ Mud", "Buff", { { type = "enemy_speedup", amount = -0.25 } } },
				{ "🌧️ Rain Barrel", "Buff", { { type = "resource_gain", amount = 6000.0 } } },
				{ "🌧️ Torrent", "Debuff", { { type = "enemy_speedup", amount = 0.5 }, { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 1.0 } } },
				{ "🌧️ Washout", "Debuff", { { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🌬️ Crosswind", "Debuff", { { type = "stat_mul", amount = 0.15, stat = "attack_cooldown" }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🌬️ Cyclone", "Debuff", { { type = "weather_flying_chance", amount = 0.3 }, { type = "enemy_speedup", amount = 0.25 }, { type = "candy_multiplier", amount = 1.0 } } },
				{ "🌬️ Gale", "Debuff", { { type = "weather_flying_chance", amount = 0.15 }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🌬️ Grounded", "Buff", { { type = "weather_flying_chance", amount = -0.2 } } },
				{ "🌬️ Kite Strings", "Buff", { { type = "flying_damage", amount = 0.75 } } },
				{ "🏜️ Buried Treasure", "Buff", { { type = "resource_gain", amount = 6000.0 } } },
				{ "🏜️ Clear Skies", "Buff", { { type = "enemy_resistance_specific", amount = -55.0, damage_type = "magic" } } },
				{ "🏜️ Dust Devil", "Debuff", { { type = "enemy_resistance_specific", amount = 40.0, damage_type = "magic" }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🏜️ Haboob", "Debuff", { { type = "enemy_resistance_specific", amount = 75.0, damage_type = "magic" }, { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "candy_multiplier", amount = 1.0 } } },
				{ "🏜️ Sand Armor", "Debuff", { { type = "enemy_shield", amount = 3.0 }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🏜️ Sandblast", "Buff", { { type = "enemy_amp_specific", amount = 0.4, damage_type = "physical" } } },
				{ "🔥 Cinders", "Buff", { { type = "boss_damage", amount = 0.5 } } },
				{ "🔥 Firebreak", "Buff", { { type = "enemy_speedup", amount = -0.3 } } },
				{ "🔥 Heatwave", "Debuff", { { type = "enemy_speedup", amount = 0.25 }, { type = "candy_multiplier", amount = 0.5 } } },
				{ "🔥 Phoenix", "Debuff", { { type = "enemy_stat_mul", amount = 0.5, stat = "health" }, { type = "enemy_speedup", amount = 0.25 }, { type = "candy_multiplier", amount = 1.0 } } },
				{ "🔥 Scorch", "Debuff", { { type = "stat_mul", amount = 0.15, stat = "attack_cooldown" }, { type = "candy_multiplier", amount = 0.5 } } },
			}) do
				if not table.find(summer.allCards, entry[1]) then
					summer.allCards[#summer.allCards + 1] = entry[1]
				end
				summer.cardKind[entry[1]] = entry[2]
				summer.cardEffects[CardPriority.normalizeTitle(entry[1])] = entry[3]
			end
			function summer.kind(title)
				if summer.cardKind[title] and summer.cardKind[title] ~= "" then return summer.cardKind[title] end
				local text = CardPriority.normalizeTitle(title)
				if text:find("enemy", 1, true) or text:find("enemies", 1, true)
					or text:find("curse", 1, true) or text:find("high cost", 1, true)
					or text:find("infested", 1, true) or text:find("explosive death", 1, true)
					or text:find("new path", 1, true) or text:find("resistances", 1, true) then
					return "Debuff"
				end
				if text:sub(1, 1) == "+" or text:find("cooldown", 1, true)
					or text:find("blessing", 1, true) or text:find("placement/upgrade cost", 1, true) then
					return "Buff"
				end
				return ""
			end

			local roll = {}
			local autoPlay
			local routeKeys = {
				"Auto Find Match",
				"Auto Daily Challenge",
				"Auto Summer Hunt",
				"Auto Join Story/INF",
				"Auto Infinity Castle",
				"Auto Challenge",
				"Auto Use",
				"Auto Dungeon",
			}
			local defaults = {
				["Ignored Capsules"] = {},
				["Delete Skins"] = {},
				["Delete Skin Rarities"] = {},
				["Selected Portal Difficulties Delete"] = {},
				["Selected Tiers Delete"] = {},
				["Selected Portals Delete"] = {},
				["Ignore Worlds Delete"] = {},
				["Ignore Bonus Delete"] = {},
				["PortalUSE Portals"] = {},
				["PortalUSE Tiers"] = {},
				["PortalUSE Difficulties Ignore"] = {},
				["PortalUSE Worlds Ignore"] = {},
				["PortalUSE Bonus Ignore"] = {},
				["PortalUSE Start After Time"] = 1,
				["PortalUSE Star After Players"] = 1,
				["Challenge_IgnoreWorlds"] = {},
				["Challenge_IgnoreDifficulties"] = {},
				["Challenge_IgnoreRewards"] = {},
				["Join Priority"] = { "Auto Challenge", "Auto Join Story/INF", "Auto Infinity Castle", "Auto Dungeon" },
				["End Action Priority"] = {},
				AutoPlacePositions = {},
				AutoPlacesCap = {},
				AutoPlaceWaves = {},
				AutoUpgradesCap = {},
				AutoUpgradeWaves = {},
				AutoJoinCastleMaxRoom = 500,
				AutoLeaveOnWave = 1,
				AutoSkillWave = 1,
				AutoSkillUnits = {},
				["Auto Use Ability"] = false,
				["Ability Units"] = {},
				["Ability Mode"] = "Always",
				AutoSellUnitsWave = 1,
				AutoSellFarmsWave = 1,
				AutoPlaceUnitsWave = 1,
				AutoUpgradeWave = 1,
				["Auto Summer Hunt"] = false,
				["Summer Leave Low Level"] = false,
				["Summer Low Level Count"] = "3",
				["Summer Minimum Level"] = 50,
				["Auto Daily Challenge"] = false,
				["Run Auto Play"] = false,
				["Auto Position Sky Island"] = false,
				["Sky Island Modes"] = { "Story", "Infinite", "Dungeon", "Challenge", "Summer", "Portal", "Infinity Castle", "Raid", "Other" },
				["Join High Story"] = false,
				["Dungeon Ignore Maps"] = {},
				["Summer Hunt Mode"] = "Solo",
				["Summer Pick Priority"] = {},
				["Summer Special Priority"] = {},
				["Summer Hunt Start After Time"] = 1,
				["Summer Card Priority"] = {},
				["Summer Weather Priority"] = { "Starfall", "Clear" },
				["Summer Card Strategy"] = "Buffs",
				["Summer Item"] = "",
				["Auto Summer Cards"] = false,
				["Auto Summer Bingo"] = false,
				["Auto Summer Quests"] = false,
				["Auto Open Sunny Stars"] = false,
				["Place At Wave"] = true,
				["Upgrade At Wave"] = true,
				["Placement Mode"] = "Default",
				["Auto Place Mode"] = "Place When Affordable",
				["Position Mode"] = "Per Slot",
				["Path Target"] = "Path 1",
				["Path Position"] = 50,
				["Upgrade Mode"] = "Default",
				["Auto Roll Trait"] = false,
				["Auto Summon Banner"] = false,
				["Auto Buy Merchant"] = false,
				["Merchant Items"] = {},
				["Summon Banner"] = "EventClover",
				["Summon Amount"] = "10",
				["Summon Keep Gems"] = 0,
				["Trait Unit"] = "",
				["Trait Targets"] = {},
				["Trait Item"] = "Reroll Token",
				["Discord Url"] = "",
				["Discord UserID"] = "",
				StoryInf_World = "",
				StoryInf_Level = "",
				["Hide Key"] = "U",
				Theme = "Dark",
				["UI Scale"] = 1,
				["Auto Hide UI On Execute"] = false,
				["Anti AFK"] = true,
				["FPS Boost"] = false,
				["Hide Other Players Units"] = false,
				["Matchmaking Map"] = "",
				["Auto Vote Lose"] = false,
				["Vote Lose Wave"] = 6,
				["Vote Lose Modes"] = {},
				["Find Match Delay"] = 5,
				["Story Join Delay"] = 5,
				["Castle Join Delay"] = 5,
				["Challenge Join Delay"] = 5,
				["Dungeon Join Delay"] = 5,
				["Portal Join Delay"] = 5,
				["Summer Hunt Join Delay"] = 5,
			}
			for key, value in pairs(defaults) do
				if type(cfg[key]) ~= type(value) then
					cfg[key] = value
				end
			end
			cfg.FPS_LIMIT = nil
			cfg["Execute Source"] = nil
			cfg.Kaitun, cfg.KaitunPortals = nil, nil
			if cfg["Placement Mode"] ~= "Default" and cfg["Placement Mode"] ~= "Circle" then
				cfg["Placement Mode"] = "Default"
			end
			if cfg["Auto Place Mode"] ~= "Slots by Slots" and cfg["Auto Place Mode"] ~= "Place When Affordable" then
				cfg["Auto Place Mode"] = "Place When Affordable"
			end
			if not table.find({ "Per Slot", "Shared Position", "Path" }, cfg["Position Mode"]) then
				cfg["Position Mode"] = "Per Slot"
			end
			if not table.find({ "Path 1", "Path 2", "Between Paths" }, cfg["Path Target"]) then
				cfg["Path Target"] = "Path 1"
			end
			if not table.find({ "Reroll Token", "Star Remnant", "Star Remnant Limited" }, cfg["Trait Item"]) then
				cfg["Trait Item"] = "Reroll Token"
			end
			if
				cfg["Upgrade Mode"] ~= "Default"
				and cfg["Upgrade Mode"] ~= "Balanced"
				and cfg["Upgrade Mode"] ~= "Slot by Slot"
			then
				cfg["Upgrade Mode"] = "Default"
			end
			if not table.find({ "Always", "When boss spawn", "When in range" }, cfg["Ability Mode"]) then
				cfg["Ability Mode"] = "Always"
			end
			if cfg.Theme ~= "Dark" and cfg.Theme ~= "Light" then
				cfg.Theme = "Dark"
			end
			cfg["UI Scale"] = finite(cfg["UI Scale"]) and math.clamp(cfg["UI Scale"], 0.8, 1.2) or 1
			for key, bounds in pairs({
				AutoJoinCastleMaxRoom = { 1, 10000 },
				AutoLeaveOnWave = { 1, 100000 },
				AutoSkillWave = { 1, 100000 },
				AutoSellUnitsWave = { 1, 100000 },
				AutoSellFarmsWave = { 1, 100000 },
				AutoPlaceUnitsWave = { 1, 100000 },
				AutoUpgradeWave = { 1, 100000 },
				["Path Position"] = { 0, 100 },
				["PortalUSE Start After Time"] = { 0, 70 },
				["PortalUSE Star After Players"] = { 1, 6 },
				["Summer Hunt Start After Time"] = { 0, 70 },
				["Summer Minimum Level"] = { 1, 100000 },
				["Vote Lose Wave"] = { 1, 100000 },
				["Find Match Delay"] = { 0, 60 },
				["Story Join Delay"] = { 0, 300 },
				["Castle Join Delay"] = { 0, 300 },
				["Challenge Join Delay"] = { 0, 300 },
				["Dungeon Join Delay"] = { 0, 300 },
				["Portal Join Delay"] = { 0, 300 },
				["Summer Hunt Join Delay"] = { 0, 300 },
			}) do
				local n = tonumber(cfg[key])
				cfg[key] = finite(n) and math.clamp(math.floor(n), bounds[1], bounds[2]) or defaults[key]
			end
			if not table.find({ "Buffs", "Rewards", "Priority only" }, cfg["Summer Card Strategy"]) then
				cfg["Summer Card Strategy"] = "Buffs"
			end

			if not table.find({ "1", "2", "3", "4", "5", "6" }, cfg["Summer Low Level Count"]) then
				cfg["Summer Low Level Count"] = "3"
			end
			if not table.find({ "Solo", "Matchmaking" }, cfg["Summer Hunt Mode"]) then
				cfg["Summer Hunt Mode"] = "Solo"
			end

			cfg["Summer Pick Priority"] = CardPriority.migrate("Cards", cfg)
			cfg["Summer Special Priority"] = CardPriority.migrate("Special", cfg)
			for i, value in ipairs(cfg["Delete Skins"]) do
				cfg["Delete Skins"][i] = tostring(value):gsub("<[^>]+>", "")
			end
			for i = 1, 6 do
				local key = tostring(i)
				local place, upgrade = tonumber(cfg.AutoPlacesCap[key]), tonumber(cfg.AutoUpgradesCap[key])
				cfg.AutoPlacesCap[key] = finite(place) and math.clamp(math.floor(place), 0, 6) or 4
				for _, waves in ipairs({ cfg.AutoPlaceWaves, cfg.AutoUpgradeWaves }) do
					local wave = tonumber(waves[key])
					waves[key] = finite(wave) and math.clamp(math.floor(wave), 1, 100000) or 1
				end
				cfg.AutoUpgradesCap[key] = finite(upgrade) and math.clamp(math.floor(upgrade), 0, 15) or 10
			end
			if not cfg["After Match"] then
				cfg["After Match"] = cfg["Auto Leave"] and "Leave"
					or cfg["Auto Next Portal"] and "Next Portal"
					or cfg["Auto Next Level"] and "Next Level"
					or cfg["Auto Retry"] and "Replay"
					or "Stay"
			end
			if not cfg["End Action Priority"] or #cfg["End Action Priority"] == 0 then
				cfg["End Action Priority"] = { "Next", "Replay", "Leave", "Stay" }
			end
			if cfg["Auto Start Match"] == nil then
				cfg["Auto Start Match"] = true
			end
			cfg["Auto Delete Portals"], cfg["Auto Delete Skins"] = false, false
			cfg["Auto Summer Quests"], cfg["Auto Open Sunny Stars"] = nil, nil
			cfg["Auto Place Units"], cfg["Auto Upgrade"], cfg["Auto Use Skill"] = nil, nil, nil
			for i = 1, 6 do
				local key = "Summer Team " .. i
				if type(cfg[key]) ~= "table" then cfg[key] = {} end
			end
			-- Join/End action priority lists: keep only known keys, drop duplicates.
			local joinPriorityKeys = { "Auto Challenge", "Auto Join Story/INF", "Auto Infinity Castle", "Auto Dungeon", "Auto Use", "Auto Find Match", "Auto Daily Challenge", "Auto Summer Hunt" }
			local function cleanPriority(key, allowed)
				local out, seen = {}, {}
				for _, v in ipairs(type(cfg[key]) == "table" and cfg[key] or {}) do
					if table.find(allowed, v) and not seen[v] then
						seen[v] = true
						table.insert(out, v)
					end
				end
				cfg[key] = out
			end
			-- Migrate legacy "Next Level"/"Next Portal" entries to the merged "Next".
			if type(cfg["End Action Priority"]) == "table" then
				for i, v in ipairs(cfg["End Action Priority"]) do
					if v == "Next Level" or v == "Next Portal" then
						cfg["End Action Priority"][i] = "Next"
					end
				end
			end
			cleanPriority("Join Priority", joinPriorityKeys)
			for _, key in ipairs(joinPriorityKeys) do
				if not table.find(cfg["Join Priority"], key) then table.insert(cfg["Join Priority"], key) end
			end
			cleanPriority("End Action Priority", { "Stay", "Leave", "Replay", "Next" })
			local routeOn = false
			for _, key in ipairs(routeKeys) do
				if cfg[key] then
					if table.find(joinPriorityKeys, key) then
						continue -- priority routes may all stay on together
					elseif routeOn then
						cfg[key] = false
					else
						routeOn = true
					end
				end
			end
			local diff = {
				double_cost = "High Cost",
				fast_enemies = "Fast Enemies",
				tank_enemies = "Tank Enemies",
				shield_enemies = "Shield Enemies",
				regen_enemies = "Regen Enemies",
				short_range = "Short Range",
			}
			local bonus = {
				physical = "Physical",
				magic = "Magic",
				dark_damage = "Dark",
				ice_damage = "Storm",
				water_damage = "Aqua",
				fire_damage = "Fire",
				light_damage = "Light",
				air_damage = "Air",
			}
			local worlds = {
				dressrosa_infinite = "Puppet Island (Summer)",
				aot_infinite = "Shiganshinu District (Summer)",
				jjk_infinite = "Cursed Academy (Summer)",
				namek_infinite = "Planet Namak (Summer)",
				["7ds_infinite"] = "Fabled Kingdom (Summer)",
				hxhant_infinite = "Ant Kingdom (Summer)",
				opm_infinite = "Alien Spaceship (Underwater)",
				eclipse_portal = "The Eclipse",
			}
			-- Portal pool is auto-collected from game data; defined after refreshPick.
			local portals = {}
			local refreshPortals
			local farms = { speedwagon = true, bulma = true, nami_evolved = true }
			local colors = {
				Color3.fromRGB(40, 120, 255),
				Color3.fromRGB(255, 70, 70),
				Color3.fromRGB(60, 220, 100),
				Color3.fromRGB(255, 210, 50),
				Color3.fromRGB(220, 70, 255),
				Color3.fromRGB(40, 220, 220),
			}

			local function val(obj, key, fallback)
				local child = obj and obj:FindFirstChild(key)
				if child then
					return child.Value
				end
				return fallback
			end

			local function has(list, value)
				for _, item in ipairs(list or {}) do
					if tostring(item) == tostring(value) then
						return true
					end
				end
				return false
			end

			local function names(list)
				local out = {}
				for _, value in pairs(list) do
					table.insert(out, tostring(value))
				end
				table.sort(out)
				return out
			end

			local function enabled(key)
				if
					key == "Auto Summer Quests"
					or key == "Auto Open Sunny Stars"
					or key == "Auto Use Skill"
				then
					return false
				end
				return not dead and cfg[key] == true
			end
			local function set(key, value)
				if dead then
					return
				end
				cfg[key] = value
				saveCfg()
			end
			modes.joinDelayKeys = {
				["Auto Find Match"] = "Find Match Delay",
				["Auto Daily Challenge"] = "Challenge Join Delay",
				["Auto Join Story/INF"] = "Story Join Delay",
				["Auto Infinity Castle"] = "Castle Join Delay",
				["Auto Challenge"] = "Challenge Join Delay",
				["Auto Dungeon"] = "Dungeon Join Delay",
				["Auto Use"] = "Portal Join Delay",
				["Auto Summer Hunt"] = "Summer Hunt Join Delay",
			}
			modes.joinTimes = {}
			function modes.joinReady(key)
				local times = modes.joinTimes
				times[key] = times[key] or os.clock()
				return os.clock() - times[key] >= (cfg[modes.joinDelayKeys[key]] or 5)
			end
			function modes.resetJoin(key)
				modes.joinTimes[key] = nil
			end
			local function lobby()
				local map = workspace:FindFirstChild("_MAP_CONFIG")
				return game.PlaceId == 8304191830 or val(map, "IsLobby", true)
			end

			local function level(fresh)
				local folder, map = match()
				if levelData and not fresh and map == levelMap and folder == levelUnits then
					return levelData
				end
				local obj = map:FindFirstChild("GetLevelData")
				assert(obj, "Map data not ready.")
				levelData = obj:InvokeServer()
				assert(type(levelData) == "table", "Map data not ready.")
				levelMap, levelUnits = map, folder
				return levelData
			end

			local function pause(seconds)
				local untilAt = os.clock() + seconds
				repeat
					if dead then
						return false
					end
					task.wait(0.1)
				until os.clock() >= untilAt
				return not dead
			end

			local function toggle(sec, key, label, fn, description, icon, details)
				cfg[key] = cfg[key] == true
				local obj = sec:AddCard({
					Id = key,
					Title = label or key,
					Description = description,
					Icon = icon,
					Toggle = true,
					Collapsible = details == true,
					Default = cfg[key] == true,
					Callback = function(on)
						if lock or dead then
							return
						end
						if fn and not check(function()
							fn(on)
						end) then
							lock = true
							flags[key]:SetEnabled(cfg[key] == true)
							lock = false
							return
						end
						set(key, on)
					end,
				})
				flags[key] = obj
				return obj
			end

			local function option(card, key, label)
				cfg[key] = cfg[key] == true
				return card:AddToggle({
					Id = key,
					Title = label or key,
					Default = cfg[key] == true,
					Callback = function(on)
						if not lock and not dead then
							set(key, on)
						end
					end,
				})
			end

			local function number(sec, key, label, min, max)
				local obj
				obj = sec:AddInput({
					Title = label,
					Default = tostring(cfg[key]),
					Validate = function(text)
						return text:match("^%d+$") ~= nil or "Use digits only."
					end,
					Callback = function(text)
						if lock or dead then
							return
						end
						local n = tonumber(text)
						if not finite(n) or n % 1 ~= 0 or n < min or n > max then
							notify(label .. " must be " .. min .. " to " .. max .. ".")
							return
						end
						set(key, n)
					end,
				})
				return obj
			end

			local function choice(sec, key, label, list, fn)
				local obj = sec:AddDropdown({
					Title = label,
					Options = list,
					Default = cfg[key],
					Searchable = true,
					Callback = function(value)
						if lock or dead or not value then
							return
						end
						set(key, value)
						if fn then
							check(fn)
						end
					end,
				})
				picks[key] = obj
				return obj
			end

			local function multi(sec, key, label, list, onChange)
				local selected = {}
				for _, v in ipairs(cfg[key]) do
					table.insert(selected, tostring(v))
				end
				local obj = sec:AddDropdown({
					Title = label,
					Options = list,
					Default = selected,
					Multi = true,
					Searchable = true,
					Callback = function(values)
						if lock or dead then
							return
						end
						local out = {}
						for _, value in ipairs(values) do
							table.insert(out, value)
						end
						table.sort(out)
						set(key, out)
						if onChange then
							onChange()
						end
					end,
				})
				picks[key] = obj
				return obj
			end

			local function button(sec, name, fn, variant)
				return sec:AddButton({
					Title = name,
					Variant = variant,
					Callback = function()
						if not dead then
							check(fn)
						end
					end,
				})
			end

			local function defs(name)
				local root = RS.src.Data:FindFirstChild(name)
				local out = {}
				if not root then
					return out
				end
				local function add(obj)
					local data = require(obj)
					if type(data) ~= "table" then
						return
					end
					for id, row in pairs(data) do
						if type(row) == "table" then
							out[id] = row
						end
					end
				end
				if root:IsA("ModuleScript") then
					add(root)
				end
				if not next(out) then
					for _, obj in ipairs(root:GetDescendants()) do
						if obj:IsA("ModuleScript") then
							add(obj)
						end
					end
				end
				return out
			end

			local function inventory()
				owned()
				return inv.session.inventory.inventory_profile_data
			end

			local function counts()
				local data, out = inventory(), {}
				for id, amount in pairs(data.normal_items) do
					out[id] = amount
				end
				for _, item in pairs(data.unique_items) do
					out[item.item_id] = (out[item.item_id] or 0) + 1
				end
				for _, unit in pairs(owned()) do
					out[unit.unit_id] = (out[unit.unit_id] or 0) + 1
				end
				local gui = LP:FindFirstChild("PlayerGui")
				local screen = gui and gui:FindFirstChild("DungeonUI")
				if screen and (screen.Enabled or (levelData and levelData._dungeon)) then
					local money = screen
					for _, key in ipairs({ "Main", "Main", "Outer", "MainHolder", "Money" }) do
						money = money and money:FindFirstChild(key)
					end
					for id, key in pairs({
						dungeon_treasure__MOCK = "TitleTreasure",
						dungeon_treasure_gold__MOCK = "TitleTreasureGold",
						dungeon_money__MOCK = "TitleMoney",
					}) do
						local text = money and money:FindFirstChild(key)
						local amount = text and tonumber((text.Text:gsub(",", "")):match("%d+"))
						if amount then
							out[id] = math.max(out[id] or 0, amount)
						end
					end
				end
				return out
			end

			local resourceKeys = {
				XP = "player_xp",
				Gems = "gem_amount",
				Gold = "gold_amount",
				Candies = "candies_amount",
				["Summer Pearls"] = "_resourceSummerPearls",
			}
			local function resources()
				local out = {}
				local stats = LP:FindFirstChild("_stats")
				for name, key in pairs(resourceKeys) do
					out[name] = val(stats, key, 0)
				end
				return out
			end

			local function loadData()
				owned()
				D.items, D.worlds, D.levels, D.maps = defs("Items"), defs("Worlds"), defs("Levels"), defs("Maps")
				D.quests, D.passes = defs("QuestsEvent"), defs("BattlePass")
				-- BattlePass is a container of modules; do not rely on the container's
				-- own exports to include every pass definition.
				local passRoot = RS.src.Data:FindFirstChild("BattlePass")
				for _, module in ipairs(passRoot and passRoot:GetChildren() or {}) do
					if module:IsA("ModuleScript") then
						local ok, passes = pcall(require, module)
						if ok and type(passes) == "table" then
							for id, pass in pairs(passes) do
								if type(pass) == "table" and type(pass.tiers) == "table" then D.passes[id] = pass end
							end
						end
					end
				end
				local root = RS.src.Data:FindFirstChild("ChallengeAndRewards")
				local challengeData = root and require(root) or {}
				D.rewards = table.clone(type(challengeData.rewards) == "table" and challengeData.rewards or {})
				for _, reward in ipairs(type(challengeData.star_fruit_chances) == "table" and challengeData.star_fruit_chances or {}) do
					local item = reward.id and D.items[reward.id]
					if item and item.name and not D.rewards[reward.id] then
						D.rewards[reward.id] = { name = item.name }
					end
				end
				if dead then
					return
				end
				for id, row in pairs(units) do
					D.items[id] = row
				end
				D.ready = true
				refreshPortals()
				if not baseline then
					baseline = { items = counts(), stats = resources() }
				end
				if updateData then
					updateData()
				end
			end

			local function ensure()
				if not D.ready then
					loadData()
				end
			end
			local function label(id)
				return D.items and D.items[id] and D.items[id].name or id
			end
			-- ==== BANNER WEBHOOK + CHALLENGE (helpers) ====
			-- Banner data comes from RS.src.Data.Banners, which ships in both places.
			-- Lobby reads workspace._LOBBIES._DATA._CHALLENGE directly; in-game the
			-- workspace carries no challenge data, so we probe the get_normal_challenge
			-- remote (present in both places, throttled to 45s per call).
			local chall = {
				pending = nil, -- uuid queued to run even while running another dungeon
				uuid = nil, -- last known challenge uuid
				at = 0, -- snapshot timestamp
				run = nil, -- challenge the bot is currently running
				start = nil, -- os.clock() on room join, keeps a 30s self-exit guard
				exitAt = 0, -- exit-to-lobby throttle (10s)
				checkAt = -60, -- half-hour boundary teleport throttle
				joinAt = 0, -- challenge join attempt throttle (5s)
				dailyAt = 0, -- daily matchmaking throttle (5s)
				probeAt = 0, -- get_normal_challenge throttle (45s)
				sent = nil, -- last webhook payload key
				sentAt = nil,
				notified = nil,
				hookErr = nil,
			}
			local bannerDB, bannerFailAt = nil, -60 -- negative: first attempt fires immediately
			local function loadBannerData()
				if bannerDB then
					return bannerDB
				end
				if os.clock() - bannerFailAt < 60 then
					return nil -- fail fast inside the retry window
				end
				local ok, data = pcall(function()
					local src = RS and RS:FindFirstChild("src")
					local folder = src and src:FindFirstChild("Data")
					return require(folder and folder:FindFirstChild("Banners"))
				end)
				if ok and type(data) == "table" then
					bannerDB = data
					return bannerDB
				end
				bannerFailAt = os.clock()
				return nil -- retried after 60s in case storage replicated late
			end

			local function getActiveBannerList()
				local banners = loadBannerData()
				local list = {}
				for id, banner in pairs(type(banners) == "table" and banners or {}) do
					if type(banner) == "table" and banner.active then
						table.insert(list, id)
					end
				end
				table.sort(list)
				return list
			end

			modes.summon = { refreshAt = 0 }
			function modes.summonTick()
				local state = modes.summon
				if os.clock() >= state.refreshAt then
					state.refreshAt = os.clock() + 30
					local list, banners = {}, loadBannerData()
					local names = { EventClover = "Featured Banner", Legacy = "Legacy Banner", Summer2026 = "Summer Banner" }
					for _, id in ipairs(getActiveBannerList()) do
						local data = banners and banners[id] or {}
						local name = data.display_name or data.displayName or data.name or data.title or names[id]
						if type(name) ~= "string" or name == "" then
							name = id:gsub("_", " "):gsub("(%l)(%u)", "%1 %2")
						end
						list[#list + 1] = { Value = id, Label = name }
					end
					if #list > 0 and picks["Summon Banner"] then
						picks["Summon Banner"]:SetOptions(list, true)
					end
				end
				if not enabled("Auto Summon Banner") then
					state.pending = nil
					return
				end
				if not lobby() then return end
				local id = cfg["Summon Banner"]
				local banners = loadBannerData()
				local banner = banners and banners[id]
				if type(banner) ~= "table" or not banner.active then return end
				if id ~= "EventClover" and id ~= "Summer2026" then return end
				local amount = cfg["Summon Amount"] == "10" and 10 or 1
				local summerBanner = id == "Summer2026"
				local resourceCost = type(banner.resource_cost) == "table" and banner.resource_cost or nil
				if summerBanner and (not resourceCost or resourceCost.id ~= "SummerPearls") then return end
				local cost = tonumber(summerBanner and resourceCost.amount or banner.gem_cost)
				local stats = LP:FindFirstChild("_stats")
				local currencyKey = summerBanner and "_resourceSummerPearls" or "gem_amount"
				local balance = tonumber(val(stats, currencyKey, nil))
				local keep = math.max(0, tonumber(cfg["Summon Keep Gems"]) or 0)
				if not cost or cost <= 0 or not balance then return end
				state.pending = state.pending or {}
				local pending = state.pending[currencyKey]
				if pending then
					if balance ~= pending.balance or os.clock() >= pending.expires then
						state.pending[currencyKey] = nil
					else
						return
					end
				end
				if balance - cost * amount < keep then return end
				state.retryAt = state.retryAt or 0
				if os.clock() < state.retryAt then return end
				state.retryAt = os.clock() + 3
				local ok = pcall(remote, "buy_from_banner", id, amount == 10 and "gems10" or "gems")
				if ok then state.pending[currencyKey] = { balance = balance, expires = os.clock() + 8 } end
			end

			-- rateup_units is keyed by tier (One/Two/...); each tier carries rarity,
			-- rateup_chance and possible_units_set ("all" or { unitId = { chance } }).
			-- Tier order follows rateup_config_show_order, ids sorted for stability.
			local function featuredLines(banner)
				local tiers = type(banner.rateup_units) == "table" and banner.rateup_units or nil
				if not tiers then
					return nil
				end
				local lines, known = {}, {}
				for _, tier in
					ipairs(type(banner.rateup_config_show_order) == "table" and banner.rateup_config_show_order or {})
				do
					known[tier] = true
					local info = tiers[tier]
					if type(info) == "table" then
						local rarity = tostring(info.rarity or tier)
						local chance = tonumber(info.rateup_chance) or 0
						local set = info.possible_units_set
						if chance > 0 and set == "all" then
							table.insert(lines, string.format("(%.2f%%) ★ %s: any %s", chance * 100, rarity, rarity))
						elseif chance > 0 and type(set) == "table" then
							local ids = {}
							for unitId in pairs(set) do
								table.insert(ids, tostring(unitId))
							end
							table.sort(ids)
							for _, unitId in ipairs(ids) do
								local slot = type(set[unitId]) == "table" and set[unitId] or {}
								local share = tonumber(slot.chance) or 1
								table.insert(
									lines,
									string.format("(%.2f%%) ★ %s: %s", chance * share * 100, rarity, label(unitId))
								)
							end
						end
					end
				end
				-- Tiers missing from show_order are appended in sorted id order.
				local extras = {}
				for tierId in pairs(tiers) do
					if not known[tierId] and type(tierId) ~= "number" then
						table.insert(extras, tostring(tierId))
					end
				end
				table.sort(extras)
				for _, tierId in ipairs(extras) do
					local info = tiers[tierId]
					if type(info) == "table" then
						local chance = tonumber(info.rateup_chance) or 0
						if chance > 0 then
							table.insert(
								lines,
								string.format(
									"(%.2f%%) ★ %s: featured pool",
									chance * 100,
									tostring(info.rarity or tierId)
								)
							)
						end
					end
				end
				return #lines > 0 and lines or nil
			end

			-- One embed field per active banner: non-rateup-legacy events first
			-- under "Special", the Legacy pool last, matching the community format.
			local function bannerSections()
				local banners = loadBannerData()
				local active = getActiveBannerList()
				if type(banners) ~= "table" or #active == 0 then
					return nil
				end
				local legacy, specials = nil, {}
				for _, id in ipairs(active) do
					if tostring(id):lower():find("legacy", 1, true) then
						legacy = id
					else
						table.insert(specials, id)
					end
				end
				local fields = {}
				local function push(header, id)
					local lines = featuredLines(banners[id])
					if not lines then
						lines = { "- Featured pool rotates with the hatch schedule" }
					end
					local value = table.concat(lines, "\n")
					if #value > 1000 then
						value = value:sub(1, 1000)
					end
					table.insert(fields, {
						["name"] = header,
						["value"] = value,
						["inline"] = false,
					})
				end
				for _, id in ipairs(specials) do
					push(#specials == 1 and "Special" or ("Special: " .. tostring(id)), id)
				end
				if legacy then
					push("Legacy", legacy)
				end
				return #fields > 0 and fields or nil
			end

			-- Travelling Merchant lineup from RS.src.Data.ItemsForSale (priced only).
			local function merchantField()
				local ok, source = pcall(function()
					local src = RS and RS:FindFirstChild("src")
					local folder = src and src:FindFirstChild("Data")
					return require(folder and folder:FindFirstChild("ItemsForSale"))
				end)
				if not ok or type(source) ~= "table" then
					return nil
				end
				local ids = {}
				for id, item in pairs(source) do
					if type(item) == "table" and not item.associated_devproduct then
						table.insert(ids, tostring(id))
					end
				end
				table.sort(ids)
				local lines = {}
				for _, id in ipairs(ids) do
					local item = source[id]
					local price = nil
					if type(item.gem_cost) == "number" then
						price = tostring(item.gem_cost) .. " Gems"
					elseif type(item.gold_cost) == "number" then
						price = tostring(item.gold_cost) .. " Gold"
					end
					if price then
						table.insert(lines, label(id) .. " [" .. price .. "]")
					end
				end
				if #lines == 0 then
					return nil
				end
				local value = table.concat(lines, ", ")
				if #value > 1000 then
					value = value:sub(1, 1000)
				end
				return {
					["name"] = "Travelling Merchant",
					["value"] = value,
					["inline"] = false,
				}
			end

			-- Lobby challenge boards are SurfaceGuis under PlayerGui, refreshed by
			-- the client services: LevelTitle is "Current Challenge" or "Daily
			-- Challenge", LevelInfo carries the labels, ChallengeCleared the flag.
			local function scanSigns()
				local gui = LP and LP:FindFirstChild("PlayerGui")
				if not gui then
					return nil
				end
				local found = nil
				for _, surface in ipairs(gui:GetChildren()) do
					if surface:IsA("SurfaceGui") then
						local title = surface:FindFirstChild("LevelTitle")
						local text = title and title:IsA("TextLabel") and tostring(title.Text) or nil
						local kind = text == "Current Challenge" and "challenge"
							or text == "Daily Challenge" and "daily"
							or nil
						if kind then
							local info = surface:FindFirstChild("LevelInfo")
							local function labelOf(name)
								local obj = info and info:FindFirstChild(name)
								return obj and obj:IsA("TextLabel") and tostring(obj.Text) or nil
							end
							local cleared = surface:FindFirstChild("ChallengeCleared")
							local clearedState
							if cleared then
								clearedState = cleared.Visible == true
							end
							found = found or {}
							found[kind] = {
								map = labelOf("MapName"),
								level = labelOf("LevelName"),
								modifier = labelOf("Difficulty"),
								desc = labelOf("DifficultyDesc"),
								reward = labelOf("Reward"),
								cleared = clearedState,
							}
						end
					end
				end
				return found
			end

			local function rewardName(value)
				if type(value) ~= "string" then return nil end
				local row = (D.rewards or {})[value] or (D.items or {})[value]
				value = row and row.name or value
				return tostring(value):gsub("<[^>]+>", ""):gsub("^[Rr]ewards?%s*:%s*", "")
					:gsub("%s+[xX]%s*%d+%s*$", ""):match("^%s*(.-)%s*$")
			end
			local function rewardIgnored(value)
				local name = rewardName(value)
				if not name or name == "" then return false end
				for _, selected in ipairs(cfg.Challenge_IgnoreRewards) do
					local wanted = rewardName(tostring(selected))
					if wanted and wanted:lower() == name:lower() then return true end
				end
				return false
			end
			-- Ignore lists store display names; the sign already renders them.
			local function signWanted(info)
				if info.map and has(cfg.Challenge_IgnoreWorlds, info.map) then
					return false
				end
				if info.modifier and has(cfg.Challenge_IgnoreDifficulties, info.modifier) then
					return false
				end
				if rewardIgnored(info.reward) then return false end
				return true
			end

			-- get_normal_challenge response shape is not public, so accept plain uuid
			-- strings, flat tables, single-level wrappers and one-element lists.
			local function parseChallengeRemote(result)
				if type(result) == "string" then
					return { uuid = result }
				end
				if type(result) ~= "table" then
					return nil
				end
				local src = result
				for _, key in ipairs({
					"data",
					"challenge",
					"current_challenge",
					"normal_challenge",
					"result",
					"payload",
				}) do
					if type(src[key]) == "table" then
						src = src[key]
						break
					end
				end
				local uuid = src.uuid or src.current_challenge_uuid or src.challenge_uuid
				if not uuid and type(src[1]) == "table" then
					src = src[1]
					uuid = src.uuid or src.current_challenge_uuid
				end
				if not uuid then
					return nil
				end
				if type(uuid) == "table" then
					return {
						uuid = uuid.uuid or uuid.id,
						id = uuid.challenge or src.challenge,
						level = uuid.level_id or src.level_id,
						reward = uuid.reward or src.reward,
					}
				end
				return {
					uuid = uuid,
					id = src.challenge or src.current_challenge,
					level = src.level_id or src.current_level_id,
					reward = src.reward or src.current_reward,
				}
			end

			-- Normalized challenge table for both places. The lobby workspace
			-- snapshot wins when populated; _CHALLENGE is server-spawned, so an
			-- empty or missing folder falls back to the remote probe everywhere.
			local function challengeDataLive()
				if lobby() then
					local root = workspace:FindFirstChild("_LOBBIES")
					local fill = root and root:FindFirstChild("_DATA")
					local obj = fill and fill:FindFirstChild("_CHALLENGE")
					if not obj and fill then
						-- newer builds may reparent the challenge values; run a
						-- bounded descendant scan instead of giving up right away
						local descendants = fill:GetDescendants()
						for i = 1, math.min(#descendants, 500) do
							if descendants[i].Name == "current_challenge_uuid" then
								obj = descendants[i].Parent
								break
							end
						end
					end
					local uuid = obj and val(obj, "current_challenge_uuid") or nil
					if uuid and uuid ~= "" then
						return {
							uuid = uuid,
							id = val(obj, "current_challenge"),
							level = val(obj, "current_level_id"),
							reward = val(obj, "current_reward"),
						}
					end
				end
				if os.clock() - chall.probeAt < 45 then
					return nil
				end
				chall.probeAt = os.clock()
				local endpoints = RS and RS:FindFirstChild("endpoints")
				endpoints = endpoints and endpoints:FindFirstChild("client_to_server")
				local call = endpoints and endpoints:FindFirstChild("get_normal_challenge")
				if not (call and call:IsA("RemoteFunction")) then
					return nil
				end
				local ok, result = pcall(call.InvokeServer, call)
				if not ok or not result then
					return nil
				end
				local data = parseChallengeRemote(result)
				if data and data.uuid then
					return data
				end
				return nil
			end

			local function challDoneUUID()
				local ok, result = pcall(function()
					local session = inv and inv.session
					return session and session.profile_data and session.profile_data.last_completed_challenge_uuid
						or nil
				end)
				if ok then
					return result
				end
				return nil
			end
			-- Persist the reset cycle across place teleports, separately for each account.
			chall.cachePath = dir .. "ChallengeCheck_" .. tostring(LP.UserId) .. ".json"
			chall.cache = {}
			if ready then
				local ok, data = pcall(function()
					if isfile(chall.cachePath) then return HttpService:JSONDecode(readfile(chall.cachePath)) end
				end)
				if ok and type(data) == "table" then chall.cache = data end
			end
			function chall.cycle()
				local ok, now = pcall(os.time)
				if not ok or type(now) ~= "number" then return nil end
				local dateOk, date = pcall(os.date, "*t", now)
				if not dateOk or type(date) ~= "table" then return nil end
				return now - (date.min % 30) * 60 - date.sec
			end
			function chall.save(state, cycle, uuid)
				local old = chall.cache
				if old.state == state and old.cycle == cycle and old.uuid == uuid then return end
				chall.cache = { state = state, cycle = cycle, uuid = uuid, updated_at = os.time(),
					updated_time = os.date("%Y-%m-%d %H:%M:%S"), previous_uuid = old.previous_uuid }
				if ready then pcall(function() writefile(chall.cachePath, HttpService:JSONEncode(chall.cache)) end) end
			end
			function chall.inChallenge()
				local ok, data = pcall(level)
				if not ok or type(data) ~= "table" then return nil end
				if type(data._dungeon) == "table" or data._dungeon == true or data._gamemode == "dungeon" or data.floor_num
					or data._portal_depth or data.portal_group or data._is_map_or_portal_level or data.id == "summer2_event" then return false end
				if chall.run then return true end
				local gameMode = tostring(data._gamemode or ""):lower()
				local id = tostring(data.id or ""):lower()
				local marker = data._challenge or data._is_challenge or data.is_challenge or data.challenge_uuid or data._challenge_uuid
				return gameMode:find("challenge", 1, true) ~= nil or id:find("challenge", 1, true) ~= nil
					or (marker ~= nil and marker ~= false and marker ~= "" and marker ~= "nil")
			end
			-- A story map is unlocked when the requirements for its first act are met.
			-- nil means the map or profile could not be verified yet.
			local function challengeMapUnlocked(levelId, mapName)
				if not D.ready or type(D.worlds) ~= "table" or type(D.levels) ~= "table" then return nil, "world data not ready" end
				local profile = inv and inv.session and inv.session.profile_data
				local completed = profile and profile.level_data and profile.level_data.completed_story_levels
				if type(completed) ~= "table" then return nil, "story progress not ready" end
				local function normalized(value)
					return type(value) == "string" and value:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$"):lower() or nil
				end
				local levelData = type(levelId) == "string" and D.levels[levelId] or nil
				local worldId = type(levelData) == "table" and levelData.world or nil
				local wantedMap = normalized(mapName)
				local found
				for id, world in pairs(D.worlds) do
					if type(world) ~= "table" or world.legend_stage or world.raid_world or type(world.levels) ~= "table" then continue end
					local matches = worldId and id == worldId
					if not matches and type(levelId) == "string" then
						for _, stage in pairs(world.levels) do
							if (type(stage) == "table" and stage.id or stage) == levelId then matches = true break end
						end
						if type(world.infinite) == "table" and world.infinite.id == levelId then matches = true end
					end
					local mapRow = D.maps and D.maps[world.map]
					if not matches and not worldId and wantedMap then
						matches = normalized(world.name) == wantedMap or normalized(id) == wantedMap
							or normalized(world.map) == wantedMap or (mapRow and normalized(mapRow.name) == wantedMap)
					end
					if matches then
						if found and found ~= world then return nil, "map matches multiple worlds" end
						found = world
					end
				end
				if not found then return nil, "map not found in story data" end
				-- A completed act directly proves that this story world was unlocked,
				-- including accounts that unlocked it without the usual prerequisite chain.
				for _, stage in pairs(found.levels) do
					local stageId = type(stage) == "table" and stage.id or stage
					if type(stageId) == "string" and completed[stageId] then return true end
				end
				local first = found.levels["1"] or found.levels[1]
				local firstId = type(first) == "table" and first.id or first
				local firstLevel = type(firstId) == "string" and D.levels[firstId]
				if type(firstLevel) ~= "table" then return nil, "first story act not found" end
				if firstLevel.requirements == nil then return true end
				if type(firstLevel.requirements) ~= "table" or type(firstLevel.requirements.required_levels) ~= "table" then return nil, "unlock requirements unavailable" end
				for _, prerequisite in pairs(firstLevel.requirements.required_levels) do
					if type(prerequisite) ~= "string" then return nil, "invalid unlock requirement" end
					if not completed[prerequisite] then return false, "locked: requires " .. prerequisite end
				end
				return true
			end

			-- Keeps the original lobbyTick filter semantics: challenges whose level
			-- falls into Challenge_IgnoreWorlds, or flagged reward/difficulty, are skipped.
			local function challWanted(data)
				if not data or not data.uuid then
					return false, "challenge UUID missing"
				end
				if challDoneUUID() == data.uuid then
					return false, "completed UUID matches current challenge"
				end
				if not D.ready then
					pcall(ensure)
				end
				if not D.ready then
					return nil, "world data not ready"
				end
				local unlocked, unlockReason = challengeMapUnlocked(data.level, data.map)
				if unlocked ~= true then return unlocked, unlockReason end
				if
					has(cfg.Challenge_IgnoreDifficulties, diff[data.id] or data.id)
					or rewardIgnored(data.reward)
				then
					return false, "reward or modifier ignored"
				end
				for _, world in pairs(D.worlds or {}) do
					if has(cfg.Challenge_IgnoreWorlds, world.name) then
						for _, stage in pairs(world.levels or {}) do
							if (type(stage) == "table" and stage.id or stage) == data.level then
								return false, "world ignored: " .. tostring(world.name)
							end
						end
					end
				end
				return true, "ready"
			end

			local function webhookPost(payload)
				local send = http_request or request or (syn and syn.request) or (http and http.request)
				if not send then
					return false
				end
				local ok = pcall(function()
					send({
						Url = BANNER_WEBHOOK_URL,
						Method = "POST",
						Headers = { ["Content-Type"] = "application/json" },
						Body = HttpService:JSONEncode(payload),
					})
				end)
				return ok
			end

			-- Reference layout rows for a challenge board snapshot.
			local function challengeRows(info)
				local head = "MAP: " .. tostring(info.map or "?")
				if info.level and info.level ~= "" and info.level ~= info.map then
					head = head .. " - " .. tostring(info.level)
				end
				return {
					head,
					"MODIFIER: " .. tostring(info.modifier or info.desc or "?"),
					"REWARDS: " .. tostring(info.reward or "?"),
					"STATUS: " .. (info.cleared and "Cleared this cycle" or "Not cleared yet"),
				}
			end

			-- Reads one kind ("challenge"/"daily") off the PlayerGui boards.
			local function signField(kind, header)
				local ok, signs = pcall(scanSigns)
				local info = ok and signs and signs[kind] or nil
				if not info or not info.map or info.map == "" then
					return nil
				end
				local value = table.concat(challengeRows(info), "\n")
				if #value > 1000 then
					value = value:sub(1, 1000)
				end
				return {
					["name"] = header,
					["value"] = value,
					["inline"] = false,
				}
			end

			-- Fallback chain when the boards are empty: workspace snapshot, then
			-- the throttled get_normal_challenge probe.
			local function challengeField()
				local field = signField("challenge", "Current Challenge")
				if field then
					return field
				end
				local ok, data = pcall(challengeDataLive)
				if not ok or not data or not data.uuid then
					return nil
				end
				chall.uuid = data.uuid
				local levelName = tostring(data.level or "?")
				if D.levels and data.level and D.levels[data.level] then
					levelName = tostring(D.levels[data.level].name or levelName)
				end
				local wanted = challWanted(data)
				local state = wanted == true and "Pending (not run yet)"
					or wanted == false and "Completed or filtered out"
					or "Unknown (loading data)"
				return {
					["name"] = "Current Challenge",
					["value"] = table.concat({
						"- UUID: " .. tostring(data.uuid or "?"),
						"- Modifier: " .. tostring(diff[data.id] or data.id or "?"),
						"- Level: " .. levelName,
						"- Status: " .. state,
					}, "\n"),
					["inline"] = false,
				}
			end

			local function bannerHookTick()
				if type(BANNER_WEBHOOK_URL) ~= "string" or BANNER_WEBHOOK_URL == "" then
					return
				end
				local fields = {}
				local okBanners, sections = pcall(bannerSections)
				if okBanners and sections then
					for _, field in ipairs(sections) do
						table.insert(fields, field)
					end
				end
				if #fields == 0 then
					table.insert(fields, {
						["name"] = "Banners",
						["value"] = "Banner data not ready (retries every 60s).",
						["inline"] = false,
					})
				end
				local okMerchant, merchant = pcall(merchantField)
				if okMerchant and merchant then
					table.insert(fields, merchant)
				end
				local okChall, challField = pcall(challengeField)
				if okChall and challField then
					table.insert(fields, challField)
				else
					table.insert(fields, {
						["name"] = "Current Challenge",
						["value"] = "Waiting for the lobby board to populate.",
						["inline"] = false,
					})
				end
				local okDaily, dailyFieldV = pcall(signField, "daily", "Daily Challenge")
				if okDaily and dailyFieldV then
					table.insert(fields, dailyFieldV)
				end
				local key = ""
				for _, field in ipairs(fields) do
					key = key .. "|" .. tostring(field.name) .. "=" .. tostring(field.value)
				end
				local now = os.clock()
				if key ~= chall.sent and chall.sentAt and now - chall.sentAt < 90 then
					return -- changed content waits for the 90s spacing
				end
				if key == chall.sent and now - (chall.sentAt or 0) < 86400 then
					return -- unchanged content re-reports once a day
				end
				if
					webhookPost({
						["username"] = "Bocchi Banner Watch",
						["embeds"] = {
							{
								["title"] = "Anime Adventures Banner",
								["type"] = "rich",
								["color"] = 15732626,
								["fields"] = fields,
								["footer"] = {
									["text"] = "bocchi reworked - " .. os.date("%Y-%m-%d %H:%M:%S"),
								},
							},
						},
					})
				then
					chall.sent, chall.sentAt, chall.hookErr = key, os.clock(), nil
				elseif not chall.hookErr or os.clock() - chall.hookErr >= 300 then
					chall.hookErr = os.clock()
					print("[Bocchi] Banner webhook failed to send (check BANNER_WEBHOOK_URL).")
				end
			end
			local function goLobby()
				local ok, result = pcall(function()
					return RS.endpoints.client_to_server.teleport_back_to_lobby:InvokeServer("leave")
				end)
				if not ok or result == false then
					warn("[Bocchi] GoLobby failed: " .. tostring(result))
					return false
				end
				return true
			end
			local function challInterrupt()
				if not enabled("Auto Challenge") then
					return
				end
				if chall.cache.state == "fight" then return end
				if enabled("Auto Dungeon") then
					local ok, current = pcall(level)
					if not ok or type(current._dungeon) == "table" then return end
				end
				if chall.pending and os.clock() - chall.at > 1800 then
					chall.pending = nil -- ~30 min old snapshot, treat as expired
				end
				if not chall.pending then
					local ok, data = pcall(challengeDataLive)
					if ok and data then
						chall.uuid = data.uuid
						if chall.run and chall.run ~= data.uuid then
							chall.run = nil
						end
						local wanted = challWanted(data)
						if wanted then
							chall.pending, chall.uuid, chall.at = data.uuid, data.uuid, os.clock()
						end
					end
				end
				if chall.run and (not chall.pending or chall.run == chall.pending) then
					return -- the running challenge itself, do not self-exit
				end
				if chall.run then chall.run = nil end
				if not chall.pending then
					return
				end
				if challDoneUUID() == chall.pending then
					chall.pending = nil -- profile already recorded this challenge as complete
					return
				end
				if os.clock() - chall.exitAt < 10 then
					return -- 10s throttle, one exit chain per round
				end
				chall.exitAt = os.clock()
				goLobby()
			end

			-- 30-minute challenge reset watch: challenge data is only readable in
			-- the lobby (the workspace snapshot spawns there), so at every :00 and
			-- :30 the client teleports back to pick up the fresh snapshot. Same
			-- clock alignment bocchinewupd ships with its Return Lobby option.
			local function challengeTick()
				if not enabled("Check Challenge") or lobby() then return end
				local cycle = chall.cycle()
				if not cycle then return end
				if chall.cache.cycle ~= cycle then
					chall.cache.previous_uuid = chall.cache.uuid
					chall.save("check lobby", cycle, nil)
					chall.checkAt = nil -- The new cycle must not inherit the previous retry delay.
				end
				-- Never interrupt a challenge in progress; stale fight state from an
				-- earlier cycle must not block the next scheduled check.
				local inChallenge = chall.inChallenge()
				if inChallenge ~= false then return end
				if chall.cache.state == "fight" then chall.save("check lobby", cycle, nil) end
				if chall.cache.state ~= "check lobby" then return end
				if os.clock() - (chall.checkAt or -math.huge) < 10 then return end
				chall.checkAt = os.clock()
				if not goLobby() then
					local ok, data = pcall(level)
					if ok and type(data) == "table" and (type(data._dungeon) == "table" or data._dungeon == true or data._gamemode == "dungeon") then
						pcall(function() getRemote("dungeon_quit"):InvokeServer() end)
					end
				end
			end

			-- ==== BANNER WEBHOOK + CHALLENGE (end) ====

			local function skin(item)
				if type(item.item_id) ~= "string" or not item.item_id:find("skin", 1, true) then
					return
				end
				local data = D.items[item.item_id]
				return data and type(data.rarity) == "string" and data.rarity or nil
			end

			local function portal(item, deleting)
				local data = item._unique_item_data and item._unique_item_data._unique_portal_data
				if not data then
					return false
				end
				local key = deleting and "Selected Portals Delete" or "PortalUSE Portals"
				if not has(cfg[key], label(item.item_id)) then
					return false
				end
				key = deleting and "Selected Tiers Delete" or "PortalUSE Tiers"
				if data.portal_depth and data.portal_depth >= 1 and not has(cfg[key], data.portal_depth) then
					return false
				end
				if deleting then
					if
						data.challenge
						and not has(cfg["Selected Portal Difficulties Delete"], diff[data.challenge] or data.challenge)
					then
						return false
					end
				elseif has(cfg["PortalUSE Difficulties Ignore"], diff[data.challenge] or data.challenge) then
					return false
				end
				local weak = data._weak_against and data._weak_against[1]
				if
					weak
					and has(
						cfg[deleting and "Ignore Bonus Delete" or "PortalUSE Bonus Ignore"],
						bonus[weak.damage_type] or weak.damage_type
					)
				then
					return false
				end
				return not has(
					cfg[deleting and "Ignore Worlds Delete" or "PortalUSE Worlds Ignore"],
					worlds[data.level_id] or data.level_id
				)
			end

			local function nextPortal()
				ensure()
				for _, item in pairs(inventory().unique_items) do
					if portal(item, false) then
						return item.uuid
					end
				end
			end


			local function room(folder)
				if not folder then
					return
				end
				for _, obj in ipairs(folder:GetChildren()) do
					local players = obj:FindFirstChild("Players")
					if players and #players:GetChildren() == 0 and not val(obj, "Active", false) then
						return obj
					end
				end
			end

			local function join(obj, key)
				remote("request_join_lobby", obj.Name)
				if not enabled(key) then
					if not dead then
						remote("request_leave_lobby", obj.Name)
					end
					return false
				end
				if LP.Character then
					LP.Character:PivotTo(CFrame.new(255.16964721679688, 196.8419189453125, -820.8120727539062))
				end
				return true
			end

			-- Keep the selected room until the match starts or the attempt times out.
			local function continueChallenge()
				local obj = chall.room
				if not obj then return false end
				if not obj.Parent then chall.room = nil return false end
				local players = obj:FindFirstChild("Players")
				local present = players and players:FindFirstChild(LP.Name) ~= nil
				for _, entry in ipairs(players and players:GetChildren() or {}) do
					if entry:IsA("ObjectValue") and entry.Value == LP then present = true break end
					if entry:IsA("StringValue") and (entry.Value == LP.Name or entry.Value == tostring(LP.UserId)) then present = true break end
				end
				if not present then
					if os.clock() - chall.roomAt < 8 then return true end
					chall.room = nil
					return false
				end
				if os.clock() - chall.roomAt >= 45 then
					pcall(remote, "request_leave_lobby", obj.Name)
					chall.room, chall.run = nil, nil
					return false
				end
				if os.clock() >= (chall.nextStart or 0) then
					chall.nextStart = os.clock() + 5
					local ok = pcall(remote, "request_start_game", obj.Name)
					if ok then
						chall.pending, chall.run, chall.start = nil, chall.roomToken, os.clock()
						if enabled("Check Challenge") then chall.save("fight", chall.cycle(), chall.roomToken) end
					end
				end
				return true
			end

			local function joinAttempt(token, key)
				if os.clock() - chall.joinAt < 5 then
					return true -- hold the route while waiting to retry
				end
				chall.joinAt = os.clock()
				if chall.notified ~= token then
					chall.notified = token
				end
				chall.uuid, chall.at, chall.pending = token, os.clock(), token
				local rooms = workspace:FindFirstChild("_CHALLENGES")
				local obj = room(rooms and rooms:FindFirstChild("Challenges"))
				if not obj then
					return true
				end
				local ok, joined = pcall(join, obj, key)
				if not ok then
					return true
				end
				if joined then
					chall.room, chall.roomToken, chall.roomAt, chall.nextStart = obj, token, os.clock(), os.clock() + 1
					return true
				end
				-- Wait for a free room instead of joining an unverified occupied template.
				return true
			end

			local function selectedWorld()
				local text = cfg.StoryInf_World:gsub("<[^>]+>", "")
				local legend = text:find(" %[Legend%]$") or cfg.StoryInf_World:find("<font")
				text = text:gsub(" %[Legend%]$", "")
				for id, world in pairs(D.worlds or {}) do
					if
						cfg.StoryInf_World == id
						or (world.name == text and (world.legend_stage == true) == (legend ~= nil))
					then
						return world
					end
				end
			end

			local function challengeRoute(root)
				if continueChallenge() then return true end
				local ready = pcall(ensure)
				if not ready then return true end
				chall.pending = nil -- recompute wanted from scratch each pass
				local okSign, signs = pcall(scanSigns)
				local normal = okSign and signs and signs.challenge or nil
				local data = root and root:FindFirstChild("_DATA")
				local challenge = data and data:FindFirstChild("_CHALLENGE")
				local id = challenge and val(challenge, "current_challenge_uuid")
				local live = id
						and id ~= ""
						and {
							uuid = id,
							id = val(challenge, "current_challenge"),
							level = val(challenge, "current_level_id"),
							reward = val(challenge, "current_reward"),
						}
					or nil
				if not live then
					local ok, result = pcall(challengeDataLive)
					live = ok and result or nil
				end
				if live and normal then live.map = normal.map end
				-- Bocchi checks the board; UltraHub also checks the completed UUID.
				-- A missing board flag is unknown, rather than a cleared challenge.
				local wanted, reason
				if live then wanted, reason = challWanted(live) end
				if normal and normal.cleared == true then wanted, reason = false, "board says cleared" end
				if normal and not signWanted(normal) then wanted, reason = false, "board matches an ignore filter" end
				if not live and normal then
					if normal.cleared == true then
						wanted, reason = false, "board says cleared"
					elseif normal.cleared == false and signWanted(normal) then
						wanted, reason = challengeMapUnlocked(nil, normal.map)
					end
				end
				if wanted == true and live then
					chall.routeWait = nil
					if not modes.joinReady("Auto Challenge") then return true end
					modes.resetJoin("Auto Challenge")
					return joinAttempt(tostring(live.uuid), "Auto Challenge")
				elseif wanted == true and normal and not live then
					chall.routeWait = nil
					if not modes.joinReady("Auto Challenge") then return true end
					modes.resetJoin("Auto Challenge")
					return joinAttempt(tostring(normal.map or "challenge"), "Auto Challenge")
				end
				if wanted == nil then
					chall.routeWait = chall.routeWait or os.clock()
					if os.clock() - chall.routeWait < 12 then return true end
				else
					chall.routeWait = nil
				end
				modes.resetJoin("Auto Challenge")
				return false
			end

			local function storyRoute(root)
				ensure()
				local world, highStage
				if cfg["Join High Story"] then
					local order = require(RS.src.Data.WorldLevelOrder).WORLD_ORDER
					local profile = inv.session and inv.session.profile_data
					local progress = profile and profile.level_data and profile.level_data.completed_story_levels
					assert(type(progress) == "table", "Story progress not ready.")
					local stages, highest = {}, 0
					for _, worldId in ipairs(order) do
						local candidate = D.worlds[worldId]
						for act = 1, 100 do
							local row = candidate and candidate.levels and (candidate.levels[tostring(act)] or candidate.levels[act])
							if not row then break end
							local id = type(row) == "table" and row.id or row
							if id and D.levels[id] then
								stages[#stages + 1] = { world = candidate, id = id }
								if progress[id] then highest = #stages end
							end
						end
					end
					local target = stages[math.min(highest + 1, #stages)]
					assert(target, "Story stages not ready.")
					world, highStage = target.world, target.id
				else
					world = selectedWorld()
				end
				assert(world, "Choose a world in Teleport.")
				local name, stage = cfg.StoryInf_Level, highStage
				local inf = world.infinite and world.infinite.id
				if
					not highStage and inf
					and (name == inf or name == "Infinite Mode" or (D.levels[inf] and D.levels[inf].name == name))
				then
					stage = inf
				end
				if not stage then
					for _, row in pairs(world.levels or {}) do
						local id = type(row) == "table" and row.id or row
						if D.levels[id] and (id == name or D.levels[id].name == name) then
							stage = id
							break
						end
					end
				end
				assert(stage and D.levels[stage], "Choose a stage for selected world in Teleport.")
				local obj = room(root and root:FindFirstChild("Story"))
				if not obj then
					return false
				end
				if not modes.joinReady("Auto Join Story/INF") then return true end
				modes.resetJoin("Auto Join Story/INF")
				if not join(obj, "Auto Join Story/INF") then return false end
				if not pause(1) or not enabled("Auto Join Story/INF") then
					return true
				end
				local hard = cfg.Hard_StoryInf or world.legend_stage or (world.infinite and world.infinite.id == stage)
				remote("request_lock_level", obj.Name, stage, true, hard and "Hard" or "Normal")
				if pause(1) and enabled("Auto Join Story/INF") then
					remote("request_start_game", obj.Name)
					pause(10)
				end
				return true
			end

			local function castleRoute()
				ensure()
				local data = inv.session.profile_data.level_data.infinite_tower
				local floor = data and data.floor_reached or 1
				if floor < cfg.AutoJoinCastleMaxRoom then
					if not modes.joinReady("Auto Infinity Castle") then return true end
					modes.resetJoin("Auto Infinity Castle")
					remote(
						"request_start_infinite_tower",
						floor,
						(cfg["Hard Difficulty"] or floor > 100) and "Hard" or "Normal"
					)
					pause(5)
					return true
				end
				return false
			end
			local dungeonHold = { visiting = false, failed = false, start = nil, retryAt = 0 }
			local function dungeonRoute()
				if mode then return false end
				if dungeonHold.failed then
					if os.clock() < dungeonHold.retryAt then return false end
					if modes.retryDungeon then modes.retryDungeon() end
					dungeonHold.failed, dungeonHold.start = false, nil
					modes.resetJoin("Auto Dungeon")
				end
				if not modes.joinReady("Auto Dungeon") then return true end
				-- Keep ownership after the join delay so modes.tick can open the menu.
				dungeonHold.start = dungeonHold.start or os.clock()
				if os.clock() - dungeonHold.start > 90 then
					dungeonHold.failed, dungeonHold.retryAt = true, os.clock() + 10
					notify("Auto Dungeon: retrying after a stalled start.")
					return false
				end
				return true
			end

			local localRoutes = {
				["Auto Challenge"] = challengeRoute,
				["Auto Join Story/INF"] = storyRoute,
				["Auto Infinity Castle"] = castleRoute,
				["Auto Dungeon"] = dungeonRoute,
				["Auto Find Match"] = function() return not mode end,
				["Auto Daily Challenge"] = function()
					if mode then return false end
					local ok, signs = pcall(scanSigns)
					return not (ok and signs and signs.daily and signs.daily.cleared == true)
				end,
				["Auto Use"] = function()
					if mode then return false end
					local portalsRoot = workspace:FindFirstChild("_PORTALS")
					local lobbies = portalsRoot and portalsRoot:FindFirstChild("Lobbies")
					local obj
					for _, item in ipairs(lobbies and lobbies:GetChildren() or {}) do
						if val(item, "Owner") == LP then obj = item break end
					end
					if not obj then
						local uuid = nextPortal()
						if not uuid then modes.resetJoin("Auto Use") return false end
						if not modes.joinReady("Auto Use") then return true end
						modes.resetJoin("Auto Use")
						remote("use_portal", uuid, cfg["Only Friends"] and { friends_only = true } or nil)
					elseif enabled("Auto Start") and obj:FindFirstChild("Players")
						and #obj.Players:GetChildren() >= cfg["PortalUSE Star After Players"]
						and 70 - val(obj, "Timer", 70) >= cfg["PortalUSE Start After Time"] then
						remote("request_start_game", obj.Name)
						pause(10)
					end
					return true
				end,
				["Auto Summer Hunt"] = function()
					if mode then return false end
					if cfg["Summer Hunt Mode"] == "Matchmaking" then return true end
					local root = workspace:FindFirstChild("_PORTALS")
					local lobbies = root and root:FindFirstChild("Lobbies")
					local obj
					for _, item in ipairs(lobbies and lobbies:GetChildren() or {}) do
						if val(item, "Owner") == LP then obj = item break end
					end
					if not obj then
						if not modes.joinReady("Auto Summer Hunt") then return true end
						modes.resetJoin("Auto Summer Hunt")
						remote("open_event_portal", "summer2_event", { difficulty = "Hard" })
						pause(1)
					else
						modes.room = obj.Name
						if 70 - val(obj, "Timer", 70) >= cfg["Summer Hunt Start After Time"] then
							remote("request_start_game", obj.Name)
							pause(10)
						end
					end
					return true
				end,
			}
			local function lobbyTick()
				if not lobby() then
					if modes.wasLobby ~= false then table.clear(modes.joinTimes) end
					modes.wasLobby = false
					chall.routeWait = nil
					chall.room = nil
					dungeonHold.failed, dungeonHold.start, dungeonHold.visiting = false, nil, false
					challInterrupt()
					return
				end
				if modes.wasLobby ~= true then
					table.clear(modes.joinTimes)
					chall.run, chall.room = nil, nil
					if modes.resetDungeonCache then modes.resetDungeonCache() end
				end
				modes.wasLobby = true
				if enabled("Check Challenge") then
					local cycle = chall.cycle()
					if cycle and chall.cache.cycle ~= cycle then
						chall.cache.previous_uuid = chall.cache.uuid
						chall.save("check lobby", cycle, nil)
					end
					if cycle and (chall.cache.state == "check lobby" or (chall.cache.state == "fight" and not chall.room)) then
						local okData, data = pcall(challengeDataLive)
						local okSign, signs = pcall(scanSigns)
						local board = okSign and signs and signs.challenge
						local uuid = okData and data and data.uuid
						local stale = chall.cache.state == "check lobby" and uuid and uuid == chall.cache.previous_uuid
							and os.time() - cycle < 30
						if stale or (not uuid and not (board and board.map and board.cleared ~= nil)) then return end
						if board and board.cleared == true or (uuid and challDoneUUID() == uuid) then
							chall.save("clear", cycle, uuid)
						else
							chall.save("checked", cycle, uuid)
						end
					end
				end
				if not dungeonHold.visiting then
					dungeonHold.visiting = true
					dungeonHold.failed = false
					dungeonHold.start = nil
				end
				chall.notified = nil
				local gui = LP:FindFirstChild("PlayerGui")
				local screen = gui and gui:FindFirstChild("DungeonUI")
				local treasure = screen and screen:FindFirstChild("OpenTreasure", true)
				if enabled("Auto Dungeon") and screen and screen.Enabled and treasure and treasure.Visible then
					if modes.queue then
						pcall(function() getRemote("leave_matchmaking"):InvokeServer() end)
						modes.queue, modes.findQueued, modes.queueKey = nil, nil, nil
					end
					if dungeonHold.failed and os.clock() >= dungeonHold.retryAt then
						if modes.retryDungeon then modes.retryDungeon() end
						dungeonHold.failed = false
					end
					dungeonHold.start = nil
					modes.priorityRoute = "Auto Dungeon"
					return
				end
				if modes.queue and modes.queueKey and enabled(modes.queueKey) then
					modes.priorityRoute = modes.queueKey
					return
				end
				local root = workspace:FindFirstChild("_LOBBIES")
				for _, key in ipairs(cfg["Join Priority"]) do
					modes.priorityRoute = key
					if enabled(key) and localRoutes[key] and localRoutes[key](root) then
						if key ~= "Auto Dungeon" then dungeonHold.start = nil end
						return
					end
				end
				modes.priorityRoute = nil

			end

			local function inventoryTick()
				if not lobby() then
					return
				end
				if
					not (
						enabled("Auto Open Capsules")
						or enabled("Auto Delete Skins")
						or enabled("Auto Delete Portals")
					)
				then
					return
				end
				ensure()
				local data = inventory()
				if enabled("Auto Open Capsules") then
					for id, amount in pairs(data.normal_items) do
						if not enabled("Auto Open Capsules") then
							break
						end
						if
							amount > 0
							and type(id) == "string" and id:lower():find("capsule", 1, true)
							and not has(cfg["Ignored Capsules"], label(id))
						then
							remote("use_item", id, { use10 = amount >= 10 })
							if not pause(0.15) then
								return
							end
						end
					end
				end
				local skins, portalsToDelete = {}, {}
				for _, item in pairs(data.unique_items) do
					if enabled("Auto Delete Skins") and has(cfg["Delete Skin Rarities"], skin(item)) then
						table.insert(skins, item.uuid)
					end
					if enabled("Auto Delete Portals") and portal(item, true) then
						table.insert(portalsToDelete, item.uuid)
					end
				end
				if enabled("Auto Delete Skins") and #skins > 0 then
					remote("delete_unique_items", skins)
				end
				if enabled("Auto Delete Portals") and #portalsToDelete > 0 then
					remote("delete_unique_items", portalsToDelete)
				end
			end

			local function questTick()
				if not lobby() then
					return
				end
				if
					not (
						enabled("Auto Claim Quests")
						or enabled("Auto Take Daily Quests")
						or enabled("Auto Take Nami Quests")
					)
				then
					return
				end
				ensure()
				local data = inv.session.quest_handler.quest_profile_data
				if enabled("Auto Claim Quests") then
					for id, quest in pairs(data.quests) do
						if not enabled("Auto Claim Quests") then
							break
						end
						local info = quest.quest_info
						local done = not quest.quest_progress
							or (
								info
								and info.quest_class
								and quest.quest_progress.amount
								and quest.quest_progress.amount >= (info.quest_class.amount or math.huge)
								and (not info.expiry_time or info.expiry_time > os.time())
							)
						if done then
							remote("redeem_quest", id)
							if not pause(0.15) then
								return
							end
						end
					end
				end
				for id, quest in pairs(D.quests) do
					if dead then
						return
					end
					if
						enabled("Auto Take Daily Quests")
						and quest._EVENT_EXPIRED == false
						and quest._AVAILABLE_NPC_QUEST
					then
						local accepted = data.quests_cooldown_last_accept[quest.id or id]
						if not accepted or os.time() - accepted >= 86400 then
							remote("accept_npc_quest", quest.id or id)
						end
					end
					if
						enabled("Auto Take Nami Quests")
						and quest._event_repeatable_quest
						and quest._AVAILABLE_NPC_QUEST == false
					then
						local key = "mha 12.0.0_dailymission_" .. id
						local missions = inv.session.profile_data.dailymissions_data
						if not missions.claimed_missions[key] then
							remote("request_claim_dailymission", key)
						end
					end
				end
				if enabled("Auto Take Nami Quests") then
					remote("request_claim_dailymission", "mha 12.0.0_dailymission_opm_daily")
				end
			end

			local function mine(unit)
				local stats = unit:FindFirstChild("_stats")
				return stats and val(stats, "player") == LP and stats or nil
			end

			local function combatTick()
				if lobby() or mode or (modeMenu and modeMenu()) then
					return
				end
				if not (enabled("Auto Sell Units") or enabled("Auto Sell Farms")) then
					return
				end
				owned()
				local folder = match()
				if val(workspace:FindFirstChild("_DATA"), "GameFinished", false) then
					return
				end
				local wave = val(workspace, "_wave_num", 0)
				local sellAll = enabled("Auto Sell Units") and wave >= cfg.AutoSellUnitsWave
				local sellFarm = enabled("Auto Sell Farms") and wave >= cfg.AutoSellFarmsWave
				for _, unit in ipairs(folder:GetChildren()) do
					if mode or dead then
						return
					end
					local stats = mine(unit)
					local id = stats and val(stats, "id")
					local def = id and units[id]
					if def and not def.unsellable and (sellAll or sellFarm and farms[id]) then
						remote("sell_unit_ingame", unit)
						return
					end
				end
			end

			local function skillsTick()
				local wanted = {
					erwin = "Auto Buff Erwin 100%",
					wendy = "Auto Buff Wenda 100%",
					leafa_evolved = "Auto Buff Leafy 100%",
					rukia_bankai = "Auto Buff Rukia",
				}
				if lobby() or mode or (modeMenu and modeMenu()) then
					return
				end
				local auto = enabled("Auto Use Ability") and #cfg["Ability Units"] > 0
				if
					not auto
					and not enabled("Auto Sacrifice Griffin")
					and not enabled(wanted.erwin)
					and not enabled(wanted.wendy)
					and not enabled(wanted.leafa_evolved)
					and not enabled(wanted.rukia_bankai)
				then
					return
				end
				local folder = match()
				if val(workspace:FindFirstChild("_DATA"), "GameFinished", false) then
					return
				end
				local list, enemies, bossAlive = {}, {}, false
				local children = folder:GetChildren()
				if auto and cfg["Ability Mode"] ~= "Always" then
					for _, candidate in ipairs(children) do
						-- Match UltraHub's bossIndicator detection; enemy player values and tags vary.
						if candidate:IsA("Model") and candidate:FindFirstChild("bossIndicator", true) then
							bossAlive = true
							local part = candidate.PrimaryPart or candidate:FindFirstChild("_hitbox") or candidate:FindFirstChild("_shadow")
							if part and part:IsA("BasePart") then enemies[#enemies + 1] = part end
						end
					end
				end
				for _, unit in ipairs(children) do
					if mode or dead then
						return
					end
					local stats = mine(unit)
					if not stats then
						continue
					end
					local id = val(stats, "id")
					if type(id) == "string" and id:match("^rukia_bankai") then
						id = "rukia_bankai"
					end
					if wanted[id] and enabled(wanted[id]) then
						list[id] = list[id] or {}
						table.insert(list[id], unit)
						continue
					end
					local use = (id == "femto_egg" and enabled("Auto Sacrifice Griffin"))
						or (auto and not wanted[id] and id ~= "femto_egg" and has(cfg["Ability Units"], id))
					local activeAttack = val(stats, "active_attack")
					if not use or not activeAttack or activeAttack == "nil" or (nextSkill[unit] or 0) > os.clock() then
						continue
					end
					if auto and id ~= "femto_egg" and cfg["Ability Mode"] == "When boss spawn" and not bossAlive then
						continue
					end
					if auto and id ~= "femto_egg" and cfg["Ability Mode"] == "When in range" then
						local near = false
						local hitbox = unit:FindFirstChild("_hitbox") or unit:FindFirstChild("_shadow")
						for _, enemy in ipairs(enemies) do
							if hitbox and hitbox:IsA("BasePart") and (enemy.Position - hitbox.Position).Magnitude <= val(stats, "range", 0) then
								near = true
								break
							end
						end
						if not near then
							continue
						end
					end
					-- A yielding remote for one unit must not stop the other abilities.
					nextSkill[unit] = math.huge
					task.spawn(function()
						local ok = pcall(remote, "use_active_attack", unit)
						local cooldown = tonumber(val(stats, "active_attack_cooldown", 1)) or 1
						if cooldown ~= cooldown or cooldown == math.huge then cooldown = 1 end
						if unit.Parent == folder then
							nextSkill[unit] = os.clock() + (ok and math.max(0.5, cooldown) or 1)
						else
							nextSkill[unit] = nil
						end
					end)
				end
				if not list.rukia_bankai then
					buffs.rukia_bankai = nil
				end
				for id, group in pairs(list) do
					if mode or dead then
						return
					end
					if not enabled(wanted[id]) then
						buffs[id] = nil
						continue
					end
					local full = id == "rukia_bankai" and 3 or 4
					if #group < full then
						-- Rotate only once every buff unit is placed; early casts desync inf buff timing.
						buffs[id] = nil
						continue
					end
					local count = math.min(full, #group)
					local buff = buffs[id]
					if not buff or (id == "rukia_bankai" and buff.folder ~= folder) then
						buff = { n = 1, at = 0, folder = folder }
					end
					buffs[id] = buff
					if os.clock() < buff.at then
						continue
					end
					buff.n = (buff.n - 1) % count + 1
					local unit = group[id ~= "rukia_bankai" and count == 4 and ({ 1, 3, 2, 4 })[buff.n] or buff.n]
					remote("use_active_attack", unit)
					buff.n = buff.n % count + 1
					buff.at = os.clock()
						+ (
							id == "rukia_bankai" and 21
							or math.clamp(val(unit._stats, "active_attack_cooldown", 61.6) / 4 + 0.1, 15.4, 60)
						)
				end
				for unit in pairs(nextSkill) do
					if unit.Parent ~= folder then
						nextSkill[unit] = nil
					end
				end
			end

			local function resultText()
				local gui = LP:FindFirstChild("PlayerGui")
				local result = gui and gui:FindFirstChild("ResultsUI")
				local holder = result and result:FindFirstChild("Holder")
				local title = holder and holder:FindFirstChild("Title")
				return title and title.Text or "Finished", result and result.Enabled
			end

			local function postWebhook(body, contentType)
				local url = cfg["Discord Url"]
				assert(
					url:match("^https://discord%.com/api/webhooks/%d+/[%w_-]+$")
						or url:match("^https://discordapp%.com/api/webhooks/%d+/[%w_-]+$"),
					"Enter a Discord webhook URL in Config > Results."
				)
				local send = http_request or request or (syn and syn.request) or (http and http.request)
				assert(type(send) == "function", "Executor has no HTTP request API.")
				local response = send({
					Url = url,
					Method = "POST",
					Headers = { ["Content-Type"] = contentType },
					Body = body,
				})
				assert(
					response and response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300,
					"Webhook request failed (HTTP "
						.. tostring(response and response.StatusCode or "no response")
						.. ")."
				)
			end

			local function webImages(rows)
				local ids = {
					Brand = "102756005269012",
					Gems = "71405874061254",
					Gold = "111024034557835",
					Candies = "86604477859167",
					["Summer Pearls"] = "14026621261",
					dungeon_treasure__MOCK = "137900807085800",
					dungeon_money__MOCK = "94325974712248",
					dungeon_treasure_gold__MOCK = "80609037866964",
				}
				local bank = RS:FindFirstChild("packages")
				for _, name in ipairs({ "assets", "gui", "_OverrideItemIcons" }) do
					bank = bank and bank:FindFirstChild(name)
				end
				local pending, seen, out = {}, {}, {}
				D.webImages = D.webImages or {}
				for _, row in ipairs(rows) do
					local icon = bank and bank:FindFirstChild(row.id)
					local image = icon and (icon:IsA("ImageLabel") or icon:IsA("ImageButton")) and icon.Image
					ids[row.id] = image and (image:match("rbxassetid://(%d+)") or image:match("[?&]id=(%d+)"))
						or ids[row.id]
					local id = ids[row.id]
					if id and not D.webImages[id] and not seen[id] then
						seen[id] = true
						pending[#pending + 1] = id
					end
				end
				if #pending > 0 then
					pcall(function()
						local send = http_request or request or (syn and syn.request) or (http and http.request)
						local response = send({
							Url = "https://thumbnails.roblox.com/v1/assets?assetIds="
								.. table.concat(pending, ",")
								.. "&size=150x150&format=Png&isCircular=false",
							Method = "GET",
							Timeout = 10,
						})
						if not response or response.StatusCode ~= 200 then
							return
						end
						for _, row in ipairs(HttpService:JSONDecode(response.Body).data or {}) do
							if
								row.state == "Completed"
								and type(row.targetId) == "number"
								and type(row.imageUrl) == "string"
								and row.imageUrl:match("^https://[%w.-]+%.rbxcdn%.com/")
							then
								D.webImages[string.format("%.0f", row.targetId)] = row.imageUrl
							end
						end
					end)
				end
				for _, row in ipairs(rows) do
					out[row.id] = D.webImages[ids[row.id]]
				end
				return out
			end

			local function webhook(test)
				ensure()
				local function num(value)
					return (
						string
							.format("%.0f", math.floor(value))
							:reverse()
							:gsub("(%d%d%d)", "%1,")
							:reverse()
							:gsub("^,", "")
					)
				end
				local function block(text)
					return "```\n" .. text:gsub("`", ""):sub(1, 1000) .. "\n```"
				end
				local function line(name, value)
					return string.format("%-13s : %s", name, value)
				end
				local text = resultText()
				if not test then
					text = report.title or text
				end
				local ping = cfg["Ping User"] or (cfg["Ping On Defeat"] and text:find("DEFEAT"))
				local rewards, totals, secret = {}, {}, {}
				local current = counts()
				for id in pairs(report.gains or {}) do
					current[id] = current[id] or 0
				end
				for id, amount in pairs(current) do
					local gain = math.max(amount - (baseline.items[id] or 0), (report.gains or {})[id] or 0)
					if gain <= 0 then
						continue
					end
					table.insert(rewards, "+" .. num(gain) .. " " .. label(id) .. " [" .. num(amount) .. "]")
					if D.items[id] and D.items[id].rarity == "Secret" then
						table.insert(secret, label(id))
					end
				end
				local stats = resources()
				for _, name in ipairs({ "Gems", "Gold", "XP", "Candies", "Summer Pearls" }) do
					local amount = stats[name]
					table.insert(totals, line(name, num(amount)))
					local gain = amount - (baseline.stats[name] or 0)
					if gain > 0 then
						table.insert(rewards, "+" .. num(gain) .. " " .. name .. " [" .. num(amount) .. "]")
					end
				end
				local settingsModule = RS.src.Data:FindFirstChild("GameplaySettings")
				local okSettings, settings = pcall(function() return require(settingsModule) end)
				local passId = okSettings and type(settings) == "table" and settings.CURRENT_BATTLEPASS
				local profile = inv and inv.session and inv.session.profile_data
				local data = profile and profile.battlepass_data
				local pass = passId and D.passes[passId]
				local entry = type(data) == "table" and passId and data[passId]
				local xp = type(entry) == "table" and tonumber(entry.xp)
				if xp == nil and type(data) == "table" and passId and entry == nil then xp = 0 end
				if xp and pass and type(pass.tiers) == "table" then
					local tier, reachedXP, nextXP = 0, 0, nil
					for n, row in pairs(pass.tiers) do
						local number, required = tonumber(n), type(row) == "table" and tonumber(row.xp_required)
						if number and required then
							if required <= xp and number > tier then tier, reachedXP = number, required end
						end
					end
					local nextTier = pass.tiers[tostring(tier + 1)] or pass.tiers[tier + 1]
					nextXP = type(nextTier) == "table" and tonumber(nextTier.xp_required)
					local progress = nextXP and (num(xp - reachedXP) .. "/" .. num(nextXP - reachedXP)) or "MAX"
					table.insert(totals, line("Battle Pass", "Level " .. tier .. " | EXP " .. num(xp) .. " (" .. progress .. ")"))
				elseif xp then
					table.insert(totals, line("Battle Pass", "EXP " .. num(xp) .. " | Level unavailable"))
				else
					table.insert(totals, line("Battle Pass", "Data unavailable"))
				end
				if cfg["Ping On Secret Drop"] and #secret > 0 then
					ping = true
				end
				local user = cfg["Discord UserID"]
				local mention = ping and user:match("^%d+$") and ("<@" .. user .. ">") or ""
				local map = not lobby() and level() or {}
				local floor = not test and report.floor
					or (type(map._dungeon) == "table" and tonumber(map._dungeon.depth))
				local dungeon = floor or type(map._dungeon) == "table"
				local kind = dungeon and "Dungeon"
					or map.floor_num and "Infinite Castle"
					or map._portal_depth and "Portal"
					or (map._gamemode or "Lobby"):gsub("_", " "):gsub("^%l", string.upper)
				local elapsed = math.max(0, math.floor((ended or os.clock()) - started))
				local title = test and "Test notification"
					or text:find("DEFEAT") and "Defeat"
					or text:find("VICTORY") and "Victory"
					or "Match complete"
				local result = table.concat({
					line("Result", title),
					line("Mode", kind),
					line("Map", map._location_name or "Lobby"),
					line("Wave", val(workspace, "_wave_num", 0)),
					line("Time", string.format("%02dm %02ds", math.floor(elapsed / 60), elapsed % 60)),
				}, "\n")
				if map.floor_num then
					result ..= "\n" .. line("Floor", map.floor_num)
				end
				if map._portal_depth then
					result ..= "\n" .. line("Portal tier", map._portal_depth)
				end
				table.sort(rewards)
				local payload = {
					username = "bocchi reworked.",
					content = (#secret > 0 and ("Secret: " .. table.concat(secret, ", ") .. " ") or "") .. mention,
					allowed_mentions = { parse = {}, users = mention ~= "" and { user } or {} },
					embeds = {
						{
							title = "Anime Adventures",
							description = "||" .. LP.Name .. " (@" .. LP.DisplayName .. ")||",
							color = 0x153E75,
							timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
							footer = { text = "bocchi reworked." },
							fields = {
								{
									name = "Run Details",
									value = block(result),
									inline = true,
								},
								{
									name = "Rewards",
									value = block(#rewards > 0 and table.concat(rewards, "\n") or "No new rewards."),
									inline = false,
								},
								{
									name = "Player Stats",
									value = block(table.concat(totals, "\n")),
									inline = true,
								},
							},
						},
					},
				}
				if dungeon then
					local progress = "Unknown"
					if finite(floor) then
						local step = math.clamp(math.floor(floor / 2), 0, 10)
						progress = line("Floor", floor .. " / 20")
							.. "\n["
							.. string.rep("#", step)
							.. string.rep("-", 10 - step)
							.. "] "
							.. math.clamp(floor * 5, 0, 100)
							.. "%"
					end
					table.insert(payload.embeds[1].fields, 2, {
						name = "Dungeon Floor",
						value = block(progress),
						inline = true,
					})
				end
				local images = webImages({ { id = "Brand" } })
				if images.Brand then
					payload.embeds[1].thumbnail = { url = images.Brand }
				end
				postWebhook(HttpService:JSONEncode(payload), "application/json")
			end

			local function sampleRewards()
				ensure()
				local map, units = workspace:FindFirstChild("_MAP_CONFIG"), workspace:FindFirstChild("_UNITS")
				local finished = val(workspace:FindFirstChild("_DATA"), "GameFinished", false)
				if finished and not report.finished then
					report.ended_action_done = nil
					report.shown = nil
					modes.dungeonWebhookReady, modes.dungeonWebhookAt = false, nil
				end
				local data = level(report.map ~= map or report.units ~= units or (finished and not report.finished))
				local current, stats = counts(), resources()
				if
					(report.map and (report.map ~= map or report.units ~= units))
					or (report.finished and not finished)
				then
					baseline = { items = current, stats = stats }
					started, voted, ended, sent = os.clock(), false, nil, false
					report = {}
					modes.dungeonWebhookReady, modes.dungeonWebhookAt = false, nil
					errors.Webhook = nil
				end
				if not report.finished or not report.floor then
					local floor = type(data._dungeon) == "table" and tonumber(data._dungeon.depth)
					report.floor = finite(floor) and math.floor(floor) or nil
				end
				report.map, report.units, report.finished = map, units, finished
				report.gains = report.gains or {}
				for id, amount in pairs(current) do
					local gain = amount - ((report.last or baseline.items)[id] or 0)
					if gain > 0 then
						report.gains[id] = (report.gains[id] or 0) + gain
						report.changed = os.clock()
					end
				end
				report.last = current
				for name, amount in pairs(stats) do
					if amount ~= (report.stats or baseline.stats)[name] then
						report.changed = os.clock()
					end
				end
				report.stats = stats
				return finished
			end

			local function challengeMatch(data)
				if type(data) ~= "table" then return false end
				local mode = type(data._gamemode) == "string" and data._gamemode:lower() or ""
				local id = type(data.id) == "string" and data.id:lower() or ""
				if type(data._dungeon) == "table" or data._dungeon == true or data.floor_num
					or data._portal_depth or data.portal_group or data._is_map_or_portal_level or id == "summer2_event" then
					return false
				end
				local marker = data._challenge or data._is_challenge or data.is_challenge
					or data.challenge_uuid or data._challenge_uuid or data._is_daily_challenge or data.is_daily_challenge
				return chall.run ~= nil or mode:find("challenge", 1, true) ~= nil
					or id:find("challenge", 1, true) ~= nil
					or (marker ~= nil and marker ~= false and marker ~= "" and marker ~= "nil")
			end
			local function runEndAction()
				local function dungeonOwnsResult()
					if not enabled("Auto Dungeon") then return false end
					local ok, data = pcall(level)
					return not ok or not challengeMatch(data)
				end
				if report.ended_action_done or dungeonOwnsResult() then
					return
				end
				task.spawn(function()
					report.ended_action_done = true
					local macroReset = false
					local function prepareMacro()
						if not macroReset then
							macroReset = true
							resetMacroForNextMatch(true)
						end
					end
					while
						not dead
						and not dungeonOwnsResult()
						and game.PlaceId ~= 8304191830
						and val(workspace:FindFirstChild("_DATA"), "GameFinished", false)
					do
						local okMode, modeData = pcall(level)
						if not (okMode and challengeMatch(modeData)) and (enabled("Auto Find Match") or (enabled("Auto Summer Hunt") and cfg["Summer Hunt Mode"] == "Matchmaking")) then
							prepareMacro()
							pcall(goLobby)
							if not pause(3) then return end
							continue
						end
						local priority = cfg["End Action Priority"]
						if type(priority) ~= "table" or #priority == 0 then
							pcall(function()
								win:Notify({
									Title = "End Action",
									Content = "Empty priority, fallback Leave",
									Kind = "warning",
								})
							end)
							if cfg["After Match"] == "Leave" then
								prepareMacro()
								goLobby()
							end
						else
							local ok, data = pcall(level)
							data = ok and data or nil
							local result = (resultText and resultText()) or "Finished"
							if type(result) ~= "string" then
								result = "Finished"
							end
							local acted = false
							for _, action in ipairs(priority) do
								if action == "Stay" then
									pcall(function()
										win:Notify({
											Title = "End Action",
											Content = "Stay -> no action",
											Kind = "info",
										})
									end)
									return
								elseif action == "Leave" then
									pcall(function()
										win:Notify({ Title = "End Action", Content = "Leave -> goLobby", Kind = "info" })
									end)
									prepareMacro()
									goLobby()
									break
								elseif action == "Replay" then
									prepareMacro()
									pcall(function()
										win:Notify({ Title = "End Action", Content = "Replay", Kind = "info" })
									end)
									if data and data.floor_num then
										local ok2, err = pcall(remote, "request_start_infinite_tower_from_game")
										if not ok2 then
											pcall(function()
												win:Notify({
													Title = "End Action",
													Content = "Replay err: " .. tostring(err),
													Kind = "warning",
												})
											end)
										end
									else
										local ok2, err = pcall(remote, "set_game_finished_vote", "replay")
										if not ok2 then
											pcall(function()
												win:Notify({
													Title = "End Action",
													Content = "Replay err: " .. tostring(err),
													Kind = "warning",
												})
											end)
										end
									end
									acted = true
									break
								elseif action == "Next" and not (result:find("DEFEAT")) then
									prepareMacro()
									pcall(function()
										win:Notify({ Title = "End Action", Content = "Next", Kind = "info" })
									end)
									local uuid = data and data._is_map_or_portal_level and nextPortal()
									if uuid then
										local ok2, err =
											pcall(remote, "set_game_finished_vote", "replay", { item_uuid = uuid })
										if not ok2 then
											pcall(function()
												win:Notify({
													Title = "End Action",
													Content = "Next err: " .. tostring(err),
													Kind = "warning",
												})
											end)
										end
									elseif data and data.floor_num then
										local ok2, err =
											pcall(remote, "request_start_infinite_tower_from_game", "NextRetry")
										if not ok2 then
											pcall(function()
												win:Notify({
													Title = "End Action",
													Content = "Next err: " .. tostring(err),
													Kind = "warning",
												})
											end)
										end
									else
										local ok2, err = pcall(remote, "set_game_finished_vote", "next_story")
										if not ok2 then
											pcall(function()
												win:Notify({
													Title = "End Action",
													Content = "Next err: " .. tostring(err),
													Kind = "warning",
												})
											end)
										end
									end
									acted = true
									break
								end
							end
							if not acted and result:find("DEFEAT") and cfg["Auto Retry"] then
								prepareMacro()
								pcall(function()
									win:Notify({ Title = "End Action", Content = "Defeat retry", Kind = "info" })
								end)
								if data and data.floor_num then
									pcall(remote, "request_start_infinite_tower_from_game")
								else
									pcall(remote, "set_game_finished_vote", "replay")
								end
							end
						end
						task.wait(3)
					end
				end)
			end
			local function voteLoseMode(data)
				if type(data) ~= "table" then return nil end
				local mode = type(data._gamemode) == "string" and data._gamemode:lower() or ""
				local id = type(data.id) == "string" and data.id:lower() or ""
				if type(data._dungeon) == "table" or data._dungeon == true or mode == "dungeon" then return "Dungeon" end
				if (tonumber(data.floor_num) or 0) > 0 or mode == "infinite_tower" then return nil end
				if id == "summer2_event" then return "Summer" end
				if (tonumber(data._portal_depth) or 0) > 0
					or (type(data.portal_group) == "string" and data.portal_group ~= "" and data.portal_group ~= "nil")
					or data._is_map_or_portal_level == true then return "Portal" end
				local challenge = data._challenge or data._challengename or data._is_challenge or data.is_challenge
					or data.challenge_uuid or data._challenge_uuid or data._is_daily_challenge or data.is_daily_challenge
				if mode:find("challenge", 1, true) or id:find("challenge", 1, true)
					or (challenge ~= nil and challenge ~= false and challenge ~= 0 and challenge ~= "" and challenge ~= "nil") then
					return "Challenge"
				end
				if mode == "infinite" or (mode == "" and (data.infinite == true or id:match("_infinite$"))) then return "Infinite" end
				if mode == "story" then return "Story" end
				-- Bocchi also identifies story by its level id when _gamemode is absent.
				if (mode == "" or mode == "normal") and (tonumber(data.story_level_rank) or id:match("_level_%d+$")) then return "Story" end
				return nil
			end
			modes.voteLoseState = {}
			function modes.voteLoseTick()
				local state = modes.voteLoseState
				if not enabled("Auto Vote Lose") then
					return
				end
				if #(cfg["Vote Lose Modes"] or {}) == 0 then
					return
				end
				if lobby() then
					state.map, state.units, state.done = nil, nil, nil
					return
				end
				local map, units = workspace:FindFirstChild("_MAP_CONFIG"), workspace:FindFirstChild("_UNITS")
				local wave = tonumber(val(workspace, "_wave_num", 0)) or 0
				if state.map ~= map or state.units ~= units or (state.wave and wave < state.wave) then
					state.map, state.units, state.done, state.retry = map, units, nil, nil
				end
				state.wave = wave
				if val(workspace:FindFirstChild("_DATA"), "GameFinished", false) then
					return
				end
				local ok, data = pcall(level)
				local current = ok and voteLoseMode(data)
				if not current then
					return
				end
				if not has(cfg["Vote Lose Modes"], current) then
					return
				end
				local target = tonumber(cfg["Vote Lose Wave"]) or 6
				if not state.done and wave >= target and os.clock() >= (state.retry or 0) then
					state.retry = os.clock() + 3
					local sent = pcall(remote, "vote_lose_game", true)
					if sent then state.done = true end
				end
			end
			local function matchTick()
				if lobby() then
					return
				end
				local finished = sampleRewards()
				local dataOk, currentData = pcall(level)
				local isChallenge = dataOk and challengeMatch(currentData)
				-- GameFinished fallback: triggers end action even if ResultsUI never shows.
				if finished then
					report.finishedAt = report.finishedAt or os.clock()
					if not isChallenge and not enabled("Auto Dungeon") and not report.ended_action_done and os.clock() - report.finishedAt >= 7 then
						pcall(runEndAction)
					end
				else
					report.finishedAt = nil
				end
				if enabled("Auto Start Match") and not voted and not (modeMenu and modeMenu()) then
					remote("vote_start")
					voted = true
				end
				local routed = enabled("Auto Dungeon") and not isChallenge
				if
					not routed
					and enabled("AutoLeave_WAVE")
					and val(workspace, "_wave_num", 0) >= cfg.AutoLeaveOnWave
				then
					goLobby()
					return
				end
				if not finished and not (report.shown and os.clock() - report.shown < 60) then
					return
				end
				ended = ended or os.clock()
				local result, shown = resultText()
				if shown then
					report.shown, report.title = report.shown or os.clock(), result
					ended = ended or os.clock()
				end
				shown = shown or (report.shown and os.clock() - report.shown < 30)
				result = result or report.title or "Finished"
				local dungeon = routed
				local gui = LP:FindFirstChild("PlayerGui")
				local screen = gui and gui:FindFirstChild("DungeonUI")
				local ready = report.shown and os.clock() - report.shown >= 3
				if dungeon then
					ready = modes.dungeonWebhookReady and not modes.rewardWaiting and not modes.openingChests
						and os.clock() - (modes.dungeonWebhookAt or os.clock()) >= 2
				else
					ready = ready and os.clock() - (report.changed or ended) >= 2
					ready = ready or (report.shown and os.clock() - report.shown >= 10)
				end
				if
					cfg["Result Webhook"]
					and not sent
					and ready
					and (not errors.Webhook or os.clock() - errors.Webhook >= 15)
				then
					local ok, err = pcall(webhook, false)
					sent = ok
					if not ok then
						errors.Webhook = os.clock()
						notify(err)
					end
				end
				if isChallenge and finished then
					if not report.shown then return end
					local outcome = tostring(report.title or result or ""):gsub("<[^>]+>", ""):upper()
					if outcome:find("VICTORY", 1, true) then
						if cfg["Result Webhook"] and not sent and not errors.Webhook then return end
						if os.clock() >= (report.challengeLeaveAt or 0) then
							report.challengeLeaveAt = os.clock() + 5
							pcall(goLobby)
						end
						return
					elseif not outcome:find("DEFEAT", 1, true) then
						return -- Wait for a result; finishing alone does not mean victory.
					end
				end
				if routed then
					return
				end
				if cfg["Auto Leave [LATE]"] and os.clock() - ended >= 180 then
					goLobby()
					return
				end
				local priority = cfg["End Action Priority"]
				local after = cfg["After Match"]
				if not shown or report.ended_action_done or (#priority == 0 and after == "Stay") then
					return
				end
				-- Wait for the webhook before acting; flag must stay unset or end action dies here.
				if cfg["Result Webhook"] and not sent and not errors.Webhook then
					return
				end
				pcall(runEndAction)
				return
			end

			local function change(group, obj, key, value)
				saved[group] = saved[group] or {}
				local data = saved[group]
				data[obj] = data[obj] or {}
				if not data[obj][key] then
					data[obj][key] = { value = obj[key] }
				end
				obj[key] = value
			end

			local function restore(group)
				for obj, props in pairs(saved[group] or {}) do
					for key, row in pairs(props) do
						pcall(function()
							obj[key] = row.value
						end)
					end
				end
				saved[group] = nil
			end

			-- FPS Boost uses the tested standalone logic; unit hiding remains separate.
			local boost = {}
			function boost.set(on)
				if on and boost.stop then return end
				if not on then
					if boost.stop then boost.stop(); boost.stop = nil end
					return
				end
				boost.stop = (function()
					local Players = game:GetService("Players")
					local Lighting = game:GetService("Lighting")
					local RunService = game:GetService("RunService")
					local player = Players.LocalPlayer
					local active = true
					local connections = {}
					local originals = {}
					local animators = setmetatable({}, { __mode = "k" })
					local watched = setmetatable({}, { __mode = "k" })
					local resetting = setmetatable({}, { __mode = "k" })
					local queue, queued = {}, setmetatable({}, { __mode = "k" })
					local head = 1

					local function connect(signal, fn)
						local connection = signal:Connect(fn)
						connections[#connections + 1] = connection
						return connection
					end

					local function set(object, property, value)
						local ok, old = pcall(function() return object[property] end)
						if not ok then return end
						local values = originals[object]
						if not values then values = {}; originals[object] = values end
						if values[property] == nil then values[property] = { value = old } end
						if old ~= value then pcall(function() object[property] = value end) end
					end

					local function disable(object)
						set(object, "Enabled", false)
						if object:IsA("ParticleEmitter") then
							set(object, "Rate", 0)
							-- Emit() can create particles even when Enabled is false and Rate is 0.
							set(object, "Transparency", NumberSequence.new(1))
							pcall(function() object:Clear() end)
						end
						if not watched[object] then
							watched[object] = true
							local ok, signal = pcall(function() return object:GetPropertyChangedSignal("Enabled") end)
							if ok then connect(signal, function()
								if active and object.Enabled then set(object, "Enabled", false) end
							end) end
							if object:IsA("ParticleEmitter") then
								connect(object:GetPropertyChangedSignal("Transparency"), function()
									local hidden = true
									for _, point in ipairs(object.Transparency.Keypoints) do
										if point.Value ~= 1 or point.Envelope ~= 0 then hidden = false; break end
									end
									if active and not hidden and not resetting[object] then
										resetting[object] = true
										set(object, "Transparency", NumberSequence.new(1))
										resetting[object] = nil
									end
								end)
							end
						end
					end

					local function effectPart(object)
						local ignored = workspace:FindFirstChild("ignore")
						if ignored and object:IsDescendantOf(ignored) then
							local branch = object
							while branch and branch.Parent ~= ignored do branch = branch.Parent end
							if branch and branch.Name ~= "_bounds" and branch.Name ~= "_placement" then return true end
						end
						local current = object
						while current and current ~= workspace do
							local name = current.Name:lower()
							if name:find("aura", 1, true) or name:find("_effect", 1, true)
								or name:find("_vfx", 1, true) or name:find("_fx", 1, true)
								or name == "effects" or name == "vfx" then return true end
							current = current.Parent
						end
						return false
					end

					local function stopAnimator(animator)
						if animators[animator] then return end
						animators[animator] = true
						pcall(function()
							for _, track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
						end)
						connect(animator.AnimationPlayed, function(track)
							if active then pcall(function() track:Stop(0) end) end
						end)
					end

					local function process(object)
						if not active or not object.Parent then return end
						if object:IsA("BasePart") then
							set(object, "Material", Enum.Material.SmoothPlastic)
							set(object, "Reflectance", 0)
							set(object, "CastShadow", false)
							if object:IsA("MeshPart") then set(object, "TextureID", "") end
							local accessory = object:FindFirstAncestorWhichIsA("Accessory")
							if effectPart(object) or accessory then set(object, "LocalTransparencyModifier", 1) end
						elseif object:IsA("Decal") or object:IsA("Texture") then
							set(object, "Transparency", 1)
						elseif object:IsA("SpecialMesh") then
							set(object, "TextureId", "")
						elseif object:IsA("SurfaceAppearance") then
							-- Preserve the instance for restoration while removing its rendered textures.
							set(object, "Parent", nil)
						elseif object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam")
							or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles")
							or object:IsA("Light") or object:IsA("Highlight") or object:IsA("PostEffect") then
							disable(object)
						elseif object:IsA("Animator") then
							stopAnimator(object)
						end
					end

					local function enqueue(object)
						if active and object and not queued[object] then
							queued[object] = true
							queue[#queue + 1] = object
						end
					end

					local function enqueueTree(root)
						if not root then return end
						enqueue(root)
						for _, object in ipairs(root:GetDescendants()) do enqueue(object) end
					end

					-- Queue additions rather than rescanning the entire map on every frame.
					connect(workspace.DescendantAdded, function(object)
						-- Handle short-lived attacks immediately; a queued scan can arrive too late.
						if object:IsA("ParticleEmitter") or object:IsA("Trail") or object:IsA("Beam") then
							pcall(disable, object)
						elseif object:IsA("BasePart") and effectPart(object) then
							set(object, "LocalTransparencyModifier", 1)
						end
						enqueue(object)
						if object:IsA("Humanoid") and object.Parent then enqueueTree(object.Parent) end
					end)
					connect(Lighting.DescendantAdded, enqueue)
					connect(RunService.Heartbeat, function()
						local limit = 350
						while active and head <= #queue and limit > 0 do
							local object = queue[head]
							queue[head] = false
							head += 1
							queued[object] = nil
							local ok, err = pcall(process, object)
							if not ok then warn("[FPS Boost]", err) end
							limit -= 1
						end
						if head > #queue then queue, head = {}, 1 end
					end)


					set(Lighting, "GlobalShadows", false)
					for _, object in ipairs(Lighting:GetDescendants()) do
						if object:IsA("PostEffect") then disable(object) end
					end
					enqueueTree(workspace)
					enqueueTree(Lighting)


					return function()
						if not active then return end
						active = false
						for _, connection in ipairs(connections) do connection:Disconnect() end
						for object, values in pairs(originals) do
							for property, saved in pairs(values) do
								pcall(function() object[property] = saved.value end)
							end
						end
						print("[FPS Boost] Disabled. Visual properties restored; stopped animations restart when the game plays them again.")
					end
				end)()
			end

			local hideUnits = {}
			function hideUnits.set(on)
				if on and hideUnits.stop then return end
				if not on then
					if hideUnits.stop then hideUnits.stop(); hideUnits.stop = nil end
					return
				end
				local active = true
				local originals = setmetatable({}, { __mode = "k" })
				local trackedUnits = setmetatable({}, { __mode = "k" })
				local connections = {}
				local function hide(object)
					local property = object:IsA("BasePart") and "LocalTransparencyModifier"
						or (object:IsA("BillboardGui") or object:IsA("SurfaceGui")) and "Enabled"
					if not property or originals[object] then return end
					local ok, value = pcall(function() return object[property] end)
					if ok then
						originals[object] = { property = property, value = value }
						pcall(function()
							if property == "Enabled" then object[property] = false else object[property] = 1 end
						end)
					end
				end
				local function scan()
					local folder = workspace:FindFirstChild("_UNITS")
					if not folder then return end
					for _, unit in ipairs(folder:GetChildren()) do
						if trackedUnits[unit] then continue end
						local stats = unit:FindFirstChild("_stats")
						local owner = stats and stats:FindFirstChild("player")
						if owner and owner:IsA("ObjectValue") and owner.Value and owner.Value ~= LP then
							trackedUnits[unit] = true
							for _, object in ipairs(unit:GetDescendants()) do hide(object) end
							connections[#connections + 1] = unit.DescendantAdded:Connect(function(object)
								if active and owner.Value and owner.Value ~= LP then hide(object) end
							end)
						end
					end
				end
				scan()
				task.spawn(function()
					while active do task.wait(1); if active then scan() end end
				end)
				hideUnits.stop = function()
					active = false
					for _, connection in ipairs(connections) do connection:Disconnect() end
					for object, row in pairs(originals) do
						pcall(function() object[row.property] = row.value end)
					end
				end
			end

			local function track(unit)
				local stats = unit:WaitForChild("_stats", 5)
				if not stats or not stats:WaitForChild("player", 5) or not stats:WaitForChild("uuid", 5) then
					return
				end
				if dead or not mine(unit) or tracked[unit] or unit.Parent ~= workspace:FindFirstChild("_UNITS") then
					return
				end
				local uuid = val(stats, "uuid")
				if not uuid then
					return
				end
				if not groups[uuid] then
					for _, own in pairs(owned()) do
						if own.uuid == uuid then
							groups[uuid] = {
								takes = own.total_takedowns or 0,
								luck = own.stat_luck or 0,
								slot = own.equipped_slot or 1,
							}
							break
						end
					end
				end
				if not groups[uuid] then
					return
				end
				tracked[unit] = { uuid = uuid, stats = stats, takes = 0, luck = 0 }
			end

			local trackedFolder
			local function counters()
				local folder = workspace:FindFirstChild("_UNITS")
				if not folder or lobby() then
					return
				end
				if trackedFolder ~= folder then
					trackedFolder = folder
					table.insert(
						hooks,
						folder.ChildAdded:Connect(function(unit)
							task.spawn(function()
								check(function()
									track(unit)
								end)
							end)
						end)
					)
					table.insert(
						hooks,
						folder.ChildRemoved:Connect(function(unit)
							local entry = tracked[unit]
							if not entry then
								return
							end
							local group = groups[entry.uuid]
							group.takes += val(entry.stats, "takedown_count", entry.takes)
							group.luck += val(entry.stats, "stat_luck", entry.luck)
							if entry.gui then
								entry.gui:Destroy()
							end
							tracked[unit] = nil
						end)
					)
					for _, unit in ipairs(folder:GetChildren()) do
						task.spawn(function()
							check(function()
								track(unit)
							end)
						end)
					end
				end
				local totals = {}
				for uuid, group in pairs(groups) do
					totals[uuid] = { takes = group.takes, luck = group.luck }
				end
				for unit, entry in pairs(tracked) do
					if unit.Parent ~= folder then
						continue
					end
					entry.takes, entry.luck = val(entry.stats, "takedown_count", 0), val(entry.stats, "stat_luck", 0)
					local total = totals[entry.uuid]
					total.takes += entry.takes
					total.luck += entry.luck
				end
				for unit, entry in pairs(tracked) do
					if not enabled("Show Takedowns") then
						if entry.gui then
							entry.gui:Destroy()
							entry.gui = nil
						end
						continue
					end
					local hitbox = unit:FindFirstChild("_hitbox") or unit:FindFirstChild("_shadow")
					if not hitbox then
						continue
					end
					if not entry.gui then
						entry.gui = Instance.new("BillboardGui")
						entry.gui.Name, entry.gui.Size, entry.gui.StudsOffset =
							"BocchiReworkedTakedowns", UDim2.fromOffset(180, 50), Vector3.new(0, 3, 0)
						entry.gui.AlwaysOnTop, entry.gui.Parent = true, hitbox
						entry.text = Instance.new("TextLabel")
						entry.text.Size, entry.text.BackgroundTransparency, entry.text.TextStrokeTransparency =
							UDim2.fromScale(1, 1), 1, 0.5
						entry.text.TextSize, entry.text.Parent = 16, entry.gui
					end
					local total = totals[entry.uuid]
					entry.text.Text = string.format("T: %d\nW: %.2f%%", total.takes, math.clamp(total.luck, 0, 100))
					entry.text.TextColor3 = cfg["Colored Takedowns"] and (colors[groups[entry.uuid].slot] or colors[1])
						or Color3.new(1, 1, 1)
				end
			end

			local function visualsTick()
				local character = LP.Character
				if cfg["Hide Name"] then
					local head = character and character:FindFirstChild("Head")
					local overhead = head and head:FindFirstChild("_overhead")
					if overhead then
						change("name", overhead, "Enabled", false)
					end
					local gui = LP:FindFirstChild("PlayerGui")
					local spawn = gui and gui:FindFirstChild("spawn_units")
					local lives = spawn and spawn:FindFirstChild("Lives")
					local main = lives and lives:FindFirstChild("Main")
					local desc = main and main:FindFirstChild("Desc")
					if desc then
						change("name", desc, "Visible", false)
					end
					for _, root in pairs({
						units = workspace:FindFirstChild("_UNITS"),
						ignore = workspace:FindFirstChild("ignore"),
					}) do
						for _, unit in ipairs(root:GetChildren()) do
							if root.Name == "_UNITS" and not mine(unit) then
								continue
							end
							for _, text in ipairs(unit:GetDescendants()) do
								if
									text:IsA("TextLabel")
									and text.Name == "Owner"
									and (mine(unit) or text.Text == LP.DisplayName or text.Text == LP.Name)
								then
									change("name", text, "Visible", false)
								end
							end
						end
					end
				else
					restore("name")
				end
				if cfg["Hide Tab"] then
					local core = service("CoreGui")
					local list = core and core:FindFirstChild("PlayerList")
					for _, obj in ipairs(list and list:GetDescendants() or {}) do
						if
							obj:IsA("TextLabel")
							and obj.Name == "PlayerName"
							and obj:FindFirstAncestor("p_" .. LP.UserId)
						then
							change("tab", obj, "Text", "bocchi reworked.")
						end
					end
				else
					restore("tab")
				end
				if cfg["Fake Outfit"] and character then
					local head = character:FindFirstChild("Head")
					local face = head and head:FindFirstChild("face")
					if face then
						change("outfit", face, "Transparency", 1)
					end
					local body = character:FindFirstChildOfClass("BodyColors")
					if body and not (saved.outfit and saved.outfit[body]) then
						for _, key in ipairs({
							"HeadColor3",
							"LeftArmColor3",
							"RightArmColor3",
							"LeftLegColor3",
							"RightLegColor3",
							"TorsoColor3",
						}) do
							change(
								"outfit",
								body,
								key,
								Color3.fromRGB(math.random(255), math.random(255), math.random(255))
							)
						end
					end
					for _, obj in ipairs(character:GetChildren()) do
						if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") then
							change("outfit", obj, "Parent", nil)
						end
					end
				elseif not cfg["Fake Outfit"] then
					restore("outfit")
				end
				if cfg["Hide Map"] and not lobby() and not workspace:FindFirstChild("_npcs") then
					local terrain = workspace:FindFirstChild("_terrain")
					for _, root in pairs({
						map = workspace:FindFirstChild("_map"),
						terrain = terrain and terrain:FindFirstChild("terrain"),
					}) do
						for _, obj in ipairs(root:GetChildren()) do
							if obj.Name ~= "Union" then
								change("map", obj, "Parent", nil)
							end
						end
					end
				else
					restore("map")
				end
				if cfg["Place In Red Zones"] and not lobby() then
					local ignore = workspace:FindFirstChild("ignore")
					local bounds = ignore and ignore:FindFirstChild("_bounds")
					for _, obj in ipairs(bounds and bounds:GetDescendants() or {}) do
						if obj:IsA("BasePart") then
							change("red", obj, "Parent", nil)
						end
					end
				else
					restore("red")
				end
			end

			local function arm(sec, key, validate)
				local ticket = 0
				flags[key] = sec:AddCard({
					Id = key,
					Title = key,
					Description = "Only matched items are deleted. Confirmation required.",
					Icon = "trash",
					Toggle = true,
					Collapsible = true,
					Default = false,
					Callback = function(on)
						if lock or dead then
							return
						end
						ticket += 1
						local id = ticket
						local stamp = epoch
						set(key, false)
						lock = true
						flags[key]:SetEnabled(false)
						lock = false
						if not on then
							return
						end
						check(function()
							validate()
							win:Confirm({
								Title = key,
								Content = "Matched items will be permanently deleted. Check filters before enabling.",
								ConfirmText = "Enable",
								Destructive = true,
								OnConfirm = function()
									if dead or ticket ~= id or epoch ~= stamp then
										return
									end
									check(function()
										validate()
										set(key, true)
										lock = true
										flags[key]:SetEnabled(true)
										lock = false
									end)
								end,
							})
						end)
					end,
				})
				return flags[key]
			end

			local function route(sec, key, label, description)
				local card = toggle(sec, key, label, function(on)
					if modes.reset then
						modes.reset()
					end
					if not on then
						return
					end
					-- Priority routes coexist; the Join Priority list picks the winner.
					if table.find(joinPriorityKeys, key) then
						return
					end
					lock = true
					for _, other in ipairs(routeKeys) do
						if other ~= key and not table.find(joinPriorityKeys, other) then
							cfg[other] = false
							if flags[other] then
								flags[other]:SetEnabled(false)
							end
						end
					end
					lock = false
				end, description, "two-arrows-loop-clockwise", true)
				local delayKey = modes.joinDelayKeys[key]
				if delayKey then number(card, delayKey, "Join Delay (seconds)", 0, key == "Auto Find Match" and 60 or 300) end
				return card
			end

			local function refreshPick(key, list)
				local obj = picks[key]
				if not obj then
					return
				end
				local previous = obj:GetOptions()
				local changed = #previous ~= #list
				if not changed then
					for i, value in ipairs(list) do
						local old = previous[i]
						if type(value) == "table" then
							if type(old) ~= "table" or old.Value ~= value.Value or old.Label ~= value.Label then changed = true break end
						elseif old ~= value then changed = true break end
					end
				end
				if changed then obj:SetOptions(list, true) end
				if type(cfg[key]) == "table" then
					local selected = {}
					for _, value in ipairs(cfg[key]) do
						table.insert(selected, tostring(value))
					end
					local current = obj:GetValue()
					local different = type(current) ~= "table" or #current ~= #selected
					if not different then
						for i, value in ipairs(selected) do if current[i] ~= value then different = true break end end
					end
					if different then obj:SetValue(selected) end
				else
					if obj:GetValue() ~= cfg[key] then obj:SetValue(cfg[key]) end
				end
			end

			refreshPortals = function()
				table.clear(portals)
				if not D.ready then
					return
				end
				local seen = {}
				for id, row in pairs(D.items or {}) do
					if type(row) ~= "table" then
						continue
					end
					local name = row.name or row.label
					if row.item_group == "Portals" and name and not seen[name] then
						seen[name] = true
						table.insert(portals, name)
					end
				end
				table.sort(portals)
				for _, key in ipairs({ "PortalUSE Portals", "Selected Portals Delete" }) do
					if picks[key] and #portals > 0 then
						local expanded = table.clone(portals)
						for _, id in ipairs(cfg[key]) do
							if not has(expanded, id) then
								table.insert(expanded, id)
							end
						end
						table.sort(expanded)
						refreshPick(key, expanded)
					end
				end
			end

			-- Gameplay editor host.
			do
				local editor, signature
				local initial = {
					Version = 3,
					Editor = cfg.AutoPlayEditor or { Units = {}, Presets = {} },
					Settings = { AutoPlacePositions = cfg.AutoPlacePositions },
				}
				if ready then
					local file = autoPlayStorage.path()
					local legacy = autoPlayStorage.root .. "Settings_" .. LP.Name .. ".json"
					if isfile(file) then
						initial = autoPlayStorage.read(file)
					elseif
						cfg.AutoPlayEditor == nil
						and profiles.name == "Default"
						and profiles.activeMode == "General"
						and isfile(legacy)
					then
						initial = autoPlayStorage.read(legacy)
					end
				end
				initial = autoPlayStorage.document(initial)
				cfg.AutoPlacePositions = initial.Settings.AutoPlacePositions
				local function persist(target)
					if not ready then
						return
					end
					local file = autoPlayStorage.path(target)
					if target then
						assert(not isfile(file), "Auto Play config already exists.")
					end
					if not isfolder(autoPlayStorage.root) then
						makefolder(autoPlayStorage.root)
					end
					local folder = file:match("^(.*)/[^/]+$")
					if not isfolder(folder) then
						makefolder(folder)
					end
					local value = autoPlayStorage.document({
						Version = 3,
						Editor = editor and editor:GetValue() or initial.Editor,
						Settings = { AutoPlacePositions = cfg.AutoPlacePositions },
					})
					local raw = HttpService:JSONEncode(value)
					local previous = isfile(file) and readfile(file) or nil
					if previous then
						autoPlayStorage.read(file)
						writefile(file .. ".bak", previous)
						assert(readfile(file .. ".bak") == previous, "Auto Play backup could not be saved.")
					end
					local ok, err = pcall(function()
						writefile(file, raw)
						assert(readfile(file) == raw, "Auto Play write verification failed.")
					end)
					if not ok then
						if previous then
							pcall(writefile, file, previous)
						else
							pcall(delfile, file)
						end
						error(err, 0)
					end
					if not target then
						autoPlayStorage.separated = true
						cfg.AutoPlayEditor = nil
					end
				end
				gameplaySave = persist
				autoPlay = createAutoPlayRuntime(cfg, notify, persist)
				local run = pages.Gameplay:AddSection({}):AddCard({
					Id = "run",
					Title = "Run Auto Play",
					Icon = "play",
					Toggle = true,
					Default = cfg["Run Auto Play"],
					Description = "Automatically places and upgrades all equipped units using their settings.",
					Callback = function(on)
						autoPlay:SetRunning(on)
						set("Run Auto Play", on)
					end,
				})
				flags["Run Auto Play"] = run
				run:SetEnabled(cfg["Run Auto Play"])
				autoPlay:SetRunning(cfg["Run Auto Play"])
				choice(pages.Gameplay:AddSection({}):AddCard({
					Id = "auto-play-upgrade-mode", Title = "Upgrade strategy", Collapsible = true,
				}), "Upgrade Mode", "Upgrade Mode", { "Default", "Balanced", "Slot by Slot" })
				local host =
					pages.Gameplay:AddSection({}):AddCard({ Id = "editor", Title = "Auto Play", Searchable = false })
				host.header.Visible = false
				editor = host:AddAutoPlay({
					Id = "auto-play-unit-settings",
					UnitCatalog = {},
					PlacementDefaults = {
						PlacementMode = cfg["Placement Mode"],
						PositionMode = cfg["Position Mode"],
						PathTarget = cfg["Path Target"],
						PathPosition = cfg["Path Position"],
					},
					PlaceMode = cfg["Auto Place Mode"],
					OnPlaceMode = function(value)
						set("Auto Place Mode", value)
					end,
					Callback = function(records)
						autoPlay:SetUnits(records)
						if editor then
							check(persist)
						end
					end,
					OnTeam = function(value)
						assert(
							not dead and not mode and not draft,
							"Stop the macro and save its recording before switching team."
						)
						autoPlay:EquipTeam(value)
						if not dead then
							signature = nil
						end
					end,
					OnPosition = function(unit, clear)
						assert(not mode, "Stop the macro before setting positions.")
						local record = editor:_getUnit(unit.UnitId)
						local sharedPosition = (record and record.PositionMode or cfg["Position Mode"])
							== "Shared Position"
						if clear then
							autoPlay:ClearPosition(unit.Slot, sharedPosition)
						else
							autoPlay:PickPosition(unit.Slot, sharedPosition)
						end
					end,
				})
				assert(
					check(function()
						editor:SetValue(initial.Editor)
					end),
					"Invalid Auto Play editor config; original preserved."
				)
				persist()
				assert(not ready or saveCfg(), "Config migration could not be saved.")
				autoPlay:SetUnits(editor:GetUnitSettings())
				gameplayFlush = function()
					if not editor.destroyed then
						editor:_commitInputs()
					end
					persist()
					assert(not ready or saveCfg(), "Config could not be saved.")
				end
				local destroy = win.Destroy
				function win:Destroy()
					if not self.destroyed and not dead and not profiles.reloading then
						pcall(gameplayFlush)
					end
					destroy(self)
				end
				function autoPlay:AllowAction(info)
					local wave = val(workspace, "_wave_num", 0)
					return not (enabled("Auto Sell Units") and wave >= cfg.AutoSellUnitsWave)
						and not (enabled("Auto Sell Farms") and wave >= cfg.AutoSellFarmsWave and farms[info.id])
				end
				function autoPlay:RefreshCatalog()
					local records, keys = self:Catalog(), {}
					if dead then
						return
					end
					for _, unit in ipairs(records) do
						local view = unit.ViewportSource
						local world = view and view:FindFirstChildWhichIsA("WorldModel")
						local model = world and world:FindFirstChildWhichIsA("Model")
						keys[#keys + 1] = unit.Slot
							.. ":"
							.. unit.UnitId
							.. ":"
							.. tostring(unit.ImageAssetId)
							.. ":"
							.. tostring(view)
							.. ":"
							.. tostring(model)
							.. ":"
							.. tostring(unit.MaxPlace)
							.. ":"
							.. tostring(unit.MaxUpgrade)
							.. ":"
							.. tostring(unit.IsFarm)
					end
					local nextSignature = table.concat(keys, "|")
					if nextSignature ~= signature then
						editor:SetCatalog(records, self:Defaults(legacyUnits))
						signature = nextSignature
					end
				end
				local share = section("Gameplay", "Auto Play Sharing"):AddCard({
					Id = "auto-play-sharing", Title = "Auto Play Config Sharing",
					Description = "Share the current team settings by slot, including saved map positions.",
					Icon = "two-arrows-loop-clockwise", Collapsible = true,
				})
				local shareName = share:AddInput({ Title = "Config Name", Default = "", Placeholder = "Optional name" })
				local shareLink = share:AddInput({ Title = "Discord Link", Default = "", Placeholder = "https://cdn.discordapp.com/attachments/.../config.json" })
				button(share, "Export Auto Play Config", function()
					assert(ready, "Executor file functions unavailable.")
					editor:_commitInputs()
					local value, slots = editor:GetValue(), {}
					for _, item in ipairs(editor.catalog.units) do
						local settings = editor:_getUnit(item.UnitId)
						if settings and type(item.Slot) == "number" and item.Slot >= 1 and item.Slot <= 6 then
							local record = table.clone(settings)
							record.UnitId = nil
							slots[#slots + 1] = { Slot = item.Slot, Settings = record }
						end
					end
					assert(#slots > 0, "Equip units before exporting.")
					local name = shareName:GetValue():match("^%s*(.-)%s*$")
					if name == "" then name = value.ActivePreset or "Auto Play Config" end
					assert(valid(name), "Enter a valid config name.")
					transfer.export(name, HttpService:JSONEncode({ Format = "bocchi reworked.autoplay", Version = 1,
						Slots = slots, Positions = cfg.AutoPlacePositions }))
				end)
				button(share, "Import Auto Play Config", function()
					assert(not mode and not draft, "Stop the macro before importing.")
					local raw, filename = cdnFetch(shareLink:GetValue())
					local data = HttpService:JSONDecode(raw)
					assert(type(data) == "table" and data.Format == "bocchi reworked.autoplay" and data.Version == 1
						and type(data.Slots) == "table", "Invalid Auto Play sharing file.")
					local imported, count = {}, 0
					for index, row in ipairs(data.Slots) do
						assert(index <= 6 and type(row) == "table" and type(row.Settings) == "table"
							and type(row.Slot) == "number" and row.Slot % 1 == 0 and row.Slot >= 1 and row.Slot <= 6
							and not imported[row.Slot], "Invalid or duplicate slot.")
						local record = table.clone(row.Settings)
						record.UnitId = "slot_" .. row.Slot
						imported[row.Slot] = UI.UnitSettings.normalize({ record })[1]
						count += 1
					end
					assert(count > 0, "No slots in Auto Play config.")
					local checked = autoPlayStorage.document({ Version = 3, Editor = { Units = {}, Presets = {} },
						Settings = { AutoPlacePositions = data.Positions or {} } })
					local name = shareName:GetValue():match("^%s*(.-)%s*$")
					if name == "" then name = filename end
					assert(valid(name), "Enter a valid config name.")
					editor:_commitInputs()
					local value, applied = editor:GetValue(), 0
					local byId = {}
					for _, unit in ipairs(value.Units) do byId[unit.UnitId] = unit end
					for _, item in ipairs(editor.catalog.units) do
						local source, target = imported[item.Slot], byId[item.UnitId]
						if source and target then
							for key, field in pairs(source) do if key ~= "UnitId" then target[key] = field end end
							if item.MaxPlace then target.PlaceCap = math.min(target.PlaceCap, item.MaxPlace) end
							if item.MaxUpgrade then target.UpgradeCap = math.min(target.UpgradeCap, item.MaxUpgrade) end
							if not item.IsFarm then target.FocusFarm = false end
							applied += 1
						end
					end
					assert(applied > 0, "Equip units in the imported slots first.")
					local base, suffix = name, 1
					while value.Presets[name] do
						suffix += 1
						name = base .. " (" .. suffix .. ")"
						assert(suffix <= 1000 and valid(name), "Too many configs with this name.")
					end
					for map, positions in pairs(checked.Settings.AutoPlacePositions) do
						cfg.AutoPlacePositions[map] = cfg.AutoPlacePositions[map] or {}
						for key, position in pairs(positions) do cfg.AutoPlacePositions[map][key] = position end
					end
					value.Presets[name] = UI.UnitSettings.normalize(value.Units)
					value.ActivePreset = name
					editor:SetValue(value)
					win:Notify({ Title = "Auto Play", Content = "Imported " .. name .. " for " .. applied .. " slots.", Kind = "success" })
				end)
				autoPlay.Editor = editor
				win.cleanup:add(function()
					autoPlay:Destroy()
				end)
				run.cleanup:add(function()
					autoPlay:Destroy()
				end)
			end
			-- End Gameplay editor host.

			local function setupModes()
				local imported = {}
				if type(getgenv) == "function" then
					local ok, env = pcall(getgenv)
					if ok and type(env) == "table" and type(env.Config) == "table" then
						imported = env.Config
					end
				end
				local shrine = type(imported.Shrine) == "table" and imported.Shrine or {}
				local shop = type(imported.Shop) == "table" and imported.Shop or {}
				local function list(key, source, fallback)
					local values = type(cfg[key]) == "table" and cfg[key]
						or type(source) == "table" and source
						or fallback
					local out, seen = {}, {}
					for i, id in ipairs(values) do
						if i > 100 then
							break
						end
						if type(id) == "string" and #id <= 80 and id:match("^[%w_]+$") and not seen[id] then
							out[#out + 1], seen[id] = id, true
						end
					end
					cfg[key] = out
				end
				list("Dungeon Rooms", imported["Priority Item Join Dungeon"], {
					"bossfinal",
					"shrine",
					"treasure_gold",
					"treasure",
					"shop",
					"money",
					"Curse",
					"chestopen",
				})
				list("Dungeon Accept", shrine.Accept, {
					"_curse_explode",
					"_curse_fly",
					"_curse_health",
					"_curse_money",
					"_curse_random",
					"_curse_shield",
					"_curse_shop",
					"_curse_speed",
					"_curse_super_armored",
					"_curse_super_burst",
					"_curse_super_chaos",
					"_curse_super_explode",
					"_curse_super_health",
					"_curse_super_regen",
					"_curse_super_speed",
				})
				list("Dungeon Deny", shrine.Deny, { "_curse_regen" })
				list("Dungeon Buy", shop["Buy Priority"], {
					"gold_branch",
					"gold_mask",
					"gold_shroom",
					"hammer_legendary",
					"hook",
					"hook2",
					"icebane",
					"mage_coat",
					"moon_fragment",
					"philospher_stone",
					"scythe",
					"stormbringer",
					"sword1",
					"sword2",
					"sword3",
					"tome",
					"axe",
					"axe_legendary",
					"belt",
					"boots",
					"bow3",
					"bow_legendary",
					"celestial_blade",
					"chest_mock_item",
					"cloak",
					"deathcap",
					"fire_axe",
					"frost_axe",
					"genie_lamp",
				})
				list("Dungeon Ignore", shop["Ignored Buy"], { "bow2" })
				cfg["Dungeon Chests"] = cfg["Dungeon Chests"] == "Open at checkpoints" and "Open at checkpoints"
					or cfg["Dungeon Chests"] == "Open at floor" and "Open at floor"
					or "Open at end"
				local n = tonumber(cfg["Dungeon Chest Floor"])
				cfg["Dungeon Chest Floor"] = finite(n) and n % 1 == 0 and n >= 1 and n <= 20 and n or 20
				for _, key in ipairs({ "Dungeon Shop", "Dungeon Shrine", "Dungeon Restart" }) do
					if cfg[key] == nil then
						cfg[key] = true
					end
				end
				local titles = {
					treasure_gold = "Rare chest",
					treasure = "Treasure chest",
					money = "Hoard",
					shop = "Shop",
					shrine = "Shrine",
					Curse = "Curse",
					bossfinal = "Boss",
					chestopen = "Open chests",
				}
				local function title(id)
					return titles[id] or id:gsub("^_curse_", ""):gsub("_", " "):gsub("^%l", string.upper)
				end
				local function at(obj, path)
					for _, name in ipairs(string.split(path, ".")) do
						obj = obj and obj:FindFirstChild(name)
					end
					return obj
				end
				local function text(obj, path)
					local label = at(obj, path)
					return label and label.Text:gsub("<[^>]+>", "") or ""
				end
				local function shown(obj)
					if not obj or not obj.Parent then
						return false
					end
					repeat
						if
							obj:IsA("Configuration")
							or (obj:IsA("GuiObject") and not obj.Visible)
							or (obj:IsA("ScreenGui") and not obj.Enabled)
						then
							return false
						end
						obj = obj.Parent
					until not obj
					return true
				end
				local function live(obj, root)
					while obj and obj ~= root do
						if obj:IsA("Configuration") then
							return false
						end
						obj = obj.Parent
					end
					return obj == root
				end
				local function portalWindows(gui)
					local root = at(gui, "NotificationWindows.Popups")
					local out = {}
					for _, popup in ipairs(root and root:GetChildren() or {}) do
						local window = popup.Name == "OpenPortalWindow" and popup
							or popup:FindFirstChild("OpenPortalWindow")
						if shown(window) then
							out[#out + 1] = window
						end
					end
					return out
				end
				local state, generation, busy, opened = {}, 0, false, {}
				local reward = {}
				local function dungeonPanel(screen)
					local outer = at(screen, "Main.Main.Outer")
					local holder = at(outer, "MainHolder.Outer")
					for _, pair in ipairs({
						{ outer, "StartHolder" },
						{ holder, "YouDied" },
						{ holder, "ShopSelection" },
						{ holder, "ShrineRoom" },
						{ holder, "OpenTreasure" },
						{ outer, "LevelInfo" },
						{ holder, "LevelSelection" },
					}) do
						local obj = pair[1] and pair[1]:FindFirstChild(pair[2])
						if shown(obj) then
							return obj, pair[2]
						end
					end
				end
				modeMenu = function()
					if not cfg["Auto Dungeon"] and not enabled("Auto Summer Hunt") then
						return false
					end
					if busy then
						return true
					end
					local gui = LP:FindFirstChild("PlayerGui")
					if cfg["Auto Dungeon"] then
						return dungeonPanel(gui and gui:FindFirstChild("DungeonUI")) ~= nil
					end
					return lobby() or val(workspace:FindFirstChild("_DATA"), "GameFinished", false)
				end
				function modes.reset()
					generation += 1
					dungeonHold.failed, dungeonHold.start = false, nil
					table.clear(modes.joinTimes)
					modes.pathScan = nil
					reward = {}
					modes.rewardWaiting, modes.openingChests, modes.chestsAt = nil, nil, nil
					modes.findAt, modes.findQueued = nil, nil
					state = {}
					opened = {}
					if summer and summer.resetRun then
						summer.resetRun()
					end
					modes.err = nil
					modes.opening, modes.portals, modes.popups, modes.confirmed = nil, nil, nil, nil
					if modes.queue then
						modes.queue, modes.queueKey = nil, nil
						pcall(function()
							getRemote("leave_matchmaking"):InvokeServer()
						end)
					end
					if modes.room then
						local room = modes.room
						modes.room = nil
						pcall(function()
							getRemote("request_leave_lobby"):InvokeServer(room)
						end)
					end
				end
				function modes.retryDungeon()
					generation += 1
					state, opened = {}, {}
					modes.err, modes.pathPreviewOpen = nil, nil
				end
				local function phase(panel, mark)
					if state.panel ~= panel or state.mark ~= mark then
						state = { panel = panel, mark = mark, seen = setmetatable({}, { __mode = "k" }) }
					end
				end
				local function callbacks(obj)
					assert(type(getconnections) == "function", "This executor needs getconnections for mode controls.")
					for _, signal in ipairs({ obj.Activated, obj.MouseButton1Click }) do
						local out = {}
						for _, con in ipairs(getconnections(signal)) do
							if con.Enabled ~= false and type(con.Function) == "function" then
								out[#out + 1] = con.Function
							end
						end
						if #out > 0 then
							return out
						end
					end
					return nil
				end
				local function act(key, token, fn)
					assert(enabled(key) and not mode, "Enable " .. key .. " and stop the macro first.")
					if busy or (state.seen and state.seen[token]) then
						return false
					end
					local stamp, run = generation, epoch
					local function valid()
						return stamp == generation and run == epoch and enabled(key) and not mode
					end
					state.seen = state.seen or setmetatable({}, { __mode = "k" })
					state.seen[token] = true
					busy = true
					task.spawn(function()
						local ok, err = pcall(function()
							if valid() then
								fn(valid)
							end
						end)
						if not ok and stamp == generation and run == epoch then
							modes.err = tostring(err)
						end
						busy, modes.openingChests = false, false
					end)
					return true
				end
				local function press(obj, key, after)
					if busy or not shown(obj) or not obj:IsA("GuiButton") or (state.seen and state.seen[obj]) then
						return false
					end
					local handlers = callbacks(obj)
					if not handlers then
						return false
					end
					return act(key, obj, function(valid)
						for _, fn in ipairs(handlers) do
							if not valid() then
								return
							end
							fn()
						end
						if after and valid() then
							restoreUI()
							after(valid)
						end
					end)
				end
				local function dungeonTry(name, ...)
					if not enabled("Auto Dungeon") or mode then
						return false
					end
					local ok, err = pcall(remote, name, ...)
					if not ok and (not errors.Dungeon or os.clock() - errors.Dungeon >= 15) then
						errors.Dungeon = os.clock()
						notify("Auto Dungeon: " .. tostring(err))
					end
					return ok
				end
				local function dungeonRecover()
					if lobby() or os.clock() < (state.exitAt or 0) then
						return
					end
					state.exitAt, state.exits = os.clock() + 5, (state.exits or 0) + 1
					state.seen = state.seen or {}
					state.seen["recover"] = nil
					act("Auto Dungeon", "recover", function(valid)
						if state.exits < 3 and (dungeonTry("teleport_back_to_lobby") or dungeonTry("dungeon_quit")) then
							return
						end
						if valid() then
							goLobby()
						end
					end)
				end
				local function dungeonCall(token, name, ...)
					local args = table.pack(...)
					return act("Auto Dungeon", token, function(valid)
						if name == "dungeon_continue_shop" then
							local continued = dungeonTry(name, table.unpack(args, 1, args.n))
							if not continued then
								state.seen[token] = nil
								pause(2)
								return
							end
							local result = tostring(report.title or resultText()):upper()
							local finalClear = finite(report.floor) and report.floor >= 20 and result:find("VICTORY", 1, true)
							if continued and not finalClear and not lobby() and report.finished and cfg["Result Webhook"] and not sent and valid() then
								if not pause(2) or not valid() then return end
								local ok, err = pcall(webhook, false)
								sent = ok
								if not ok then
									errors.Webhook = os.clock()
									notify(err)
								end
							end
						else
							remote(name, table.unpack(args, 1, args.n))
						end
					end)
				end
				function modes.matchMaps()
					modes.matches = { ["Daily Challenge"] = "__DAILY_CHALLENGE", ["Summer Event"] = "summer2_event" }
					local list = { "Daily Challenge", "Summer Event" }
					for id, row in pairs(D.levels or {}) do
						if row._MATCHMAKING then
							local name = (row.name or id):gsub("<[^>]+>", "") .. " [" .. id .. "]"
							modes.matches[name] = id
							list[#list + 1] = name
						end
					end
					table.sort(list)
					refreshPick("Matchmaking Map", list)
				end
				function modes.find()
					if not lobby() then
						modes.queue, modes.findQueued, modes.queueKey = nil, nil, nil
						return
					end
					local key = modes.priorityRoute
					local summerQueue = key == "Auto Summer Hunt" and cfg["Summer Hunt Mode"] == "Matchmaking"
					if mode or not enabled(key) or not (summerQueue or key == "Auto Find Match" or key == "Auto Daily Challenge") then return end
					if modes.err then
						local err = modes.err
						modes.err = nil
						error(err, 0)
					end
					if busy then
						return
					end
					local gui = LP:FindFirstChild("PlayerGui")
					local popups = at(gui, "NotificationWindows.Popups")
					for _, popup in ipairs(popups and popups:GetChildren() or {}) do
						local panel = popup.Name == "CaptchaWindow" and popup or popup:FindFirstChild("CaptchaWindow")
						if shown(panel) and modes.queue then
							local code = text(panel, "Captcha"):match("^%s*(.-)%s*$")
							local input, yes = at(panel, "TypeBox"), at(panel, "ButtonHolder.Yes")
							if code ~= "" and #code <= 100 and input then
								phase(panel, code)
								input.Text = code
								if not shown(at(yes, "Locked")) then
									press(yes, key)
								end
							end
							return
						end
					end
					if
						shown(at(gui, "MatchmakingUI"))
						or modes.findQueued or modes.queue
					then
						return
					end
					ensure()
					local id = summerQueue and "summer2_event" or key == "Auto Daily Challenge" and "__DAILY_CHALLENGE"
						or modes.matches and modes.matches[cfg["Matchmaking Map"]]
					assert(id, "Choose a matchmaking map in Teleport.")
					if not modes.joinReady(key) then return end
					modes.resetJoin(key)
					act(key, {}, function(valid)
						modes.queue, modes.queueKey = true, key
						local ok, err = pcall(remote, "request_matchmaking", id)
						if not ok then modes.queue, modes.queueKey = nil, nil error(err, 0) end
						if not valid() then
							getRemote("leave_matchmaking"):InvokeServer()
							modes.queue, modes.queueKey = nil, nil
						end
					end)
				end
				local endpoints = RS:FindFirstChild("endpoints")
				local events = endpoints and endpoints:FindFirstChild("server_to_client")
				for _, name in ipairs({ "matchmaking_started", "matchmaking_ended" }) do
					local event = events and events:FindFirstChild(name)
					if event then
						table.insert(
							hooks,
							event.OnClientEvent:Connect(function()
								if modes.queue then
									modes.findQueued = name == "matchmaking_started"
									if not modes.findQueued then
										modes.queue, modes.queueKey = nil, nil
										modes.resetJoin("Auto Find Match")
										modes.resetJoin("Auto Daily Challenge")
										modes.resetJoin("Auto Summer Hunt")
									end
								end
							end)
						)
					end
				end
				local function openMenu(gui, screen, key)
					if not screen then
						return false
					end
					if shown(at(screen, "Main")) and dungeonPanel(screen) then
						return true
					end
					if opened[screen] and os.clock() - opened[screen] < 5 then
						return false
					end
					local btn = at(gui, "LeftUI_test.Buttons.Dungeon")
					if not shown(btn) then
						return false
					end
					if screen.Enabled then
						screen.Enabled = false
					end
					if not busy and state.seen then
						state.seen[btn] = nil
					end
					if press(btn, key) then
						opened[screen] = os.clock()
					end
					return false
				end
				local dungeonSection = section("Dungeon", "Run")
				local dungeon = route(dungeonSection, "Auto Dungeon", nil, "Continue your dungeon run.")
				multi(dungeon, "Dungeon Ignore Maps", "Ignore Maps", gameMapNames)
				local skySection = section("Gameplay", "Auto Position Sky Island")
				local skyCard = toggle(skySection, "Auto Position Sky Island", nil, nil,
					"When enabled, Auto Play uses a fixed Sky Island placement center only in the selected modes. When disabled, normal placement settings apply.", "location-pin", true)
				multi(skyCard, "Sky Island Modes", "Modes", { "Story", "Infinite", "Dungeon", "Challenge", "Summer", "Portal", "Infinity Castle", "Raid", "Other" })
				local floor
				choice(
					dungeon,
					"Dungeon Chests",
					"Open Chests",
					{ "Open at end", "Open at checkpoints", "Open at floor" },
					function()
						if floor then
							floor:SetVisible(cfg["Dungeon Chests"] == "Open at floor")
						end
					end
				)
				floor = number(dungeon, "Dungeon Chest Floor", "Chest floor", 1, 20)
				floor:SetVisible(cfg["Dungeon Chests"] == "Open at floor")
				local function options(ids)
					local out = {}
					for _, id in ipairs(ids) do
						out[#out + 1] = { Value = id, Label = title(id) }
					end
					return out
				end
				local function priority(sec, key, label)
					local items = {}
					for _, id in ipairs(cfg[key]) do
						items[#items + 1] = { Id = id, Label = title(id) }
					end
					return sec:AddPrioritySelector({
						Id = key,
						Title = label,
						Items = items,
						Default = cfg[key],
						Columns = 2,
						OnChanged = function(order)
							if not lock and not dead then
								set(key, table.clone(order))
							end
						end,
					})
				end
				priority(
					section("Dungeon", "Rooms"):AddCard({
						Id = "dungeon-priority",
						Title = "Room priority",
						Collapsible = true,
					}),
					"Dungeon Rooms",
					"Room order"
				)
				local curse =
					toggle(section("Dungeon", "Shrine"), "Dungeon Shrine", "Auto Shrine", nil, nil, "flag", true)
				local curseIds = table.clone(cfg["Dungeon Accept"])
				for _, id in ipairs(cfg["Dungeon Deny"]) do
					if not table.find(curseIds, id) then
						curseIds[#curseIds + 1] = id
					end
				end
				multi(curse, "Dungeon Accept", "Accepted Curses", options(curseIds))
				multi(curse, "Dungeon Deny", "Denied Curses", options(curseIds))
				local buying =
					toggle(section("Dungeon", "Shop"), "Dungeon Shop", "Auto Dungeon Shop", nil, nil, "backpack", true)
				priority(buying, "Dungeon Buy", "Item order")

				local hunt = toggle(
					section("Summer Event", "Summer Hunt"),
					"Auto Summer Hunt",
					"Auto Summer Hunt",
					function(on)
						if modes.reset then
							modes.reset()
						end
					end,
					"Open a solo room or queue with other players.",
					"sparkles",
					true
				)
				hunt:SetExpanded(false, true)
				number(hunt, "Summer Hunt Join Delay", "Join Delay (seconds)", 0, 300)
				local startDelay
				choice(hunt, "Summer Hunt Mode", "Mode", { "Solo", "Matchmaking" }, function()
					modes.reset()
					startDelay:SetVisible(cfg["Summer Hunt Mode"] == "Solo")
				end)
				startDelay = number(hunt, "Summer Hunt Start After Time", "Start After Time", 0, 70)
				startDelay:SetVisible(cfg["Summer Hunt Mode"] == "Solo")
				local lowLevel = toggle(section("Summer Event", "Auto Leave"), "Summer Leave Low Level",
					"Auto Leave Low-Level Players", nil,
					"Return to lobby if enough other players are below the minimum level.", "door", true)
				choice(lowLevel, "Summer Low Level Count", "Low-Level Players", { "1", "2", "3", "4", "5", "6" })
				number(lowLevel, "Summer Minimum Level", "Minimum Player Level", 1, 100000)
				local switchTeam = section("Summer Event", "Switch Team"):AddCard({
					Id = "summer-team-switch", Title = "Switch Team",
					Description = "Choose which weather uses each team. The first matching team is used.",
					Icon = "users", Collapsible = true,
				})
				local weatherNames = { "Clear", "Blizzard", "Rainy", "Stormy", "Windy", "Magical", "Inferno", "Flooded", "Sandstorm", "Starfall" }
				for team = 1, 6 do
					multi(switchTeam, "Summer Team " .. team, "Team " .. team, weatherNames)
				end
				local cardSection = section("Summer Event", "Cards")
				toggle(section("Summer Event", "Bingo"), "Auto Summer Bingo", "Claim Visible Bingo Rewards", nil,
					"Claim available rewards on the open Summer Bingo board.", "gift-box")
				local cards = toggle(
					cardSection,
					"Auto Summer Cards",
					"Auto Vote Cards",
					nil,
					"Vote once per offer in Summer Hunt and Sky Portals.",
					"sparkles",
					true
				)
				cards:SetExpanded(false, true)

				local function buildCardPriorityItems()
					local items = {}
					for _, title in ipairs(summer.allCards) do
						local kind = summer.kind(title)
						items[#items + 1] =
							{ Id = title, Label = kind ~= "" and (title .. " [" .. kind .. "]") or title }
					end
					return items
				end
				local cardItems = buildCardPriorityItems()
				local validCards, seenCards, savedCardOrder = {}, {}, {}
				for _, item in ipairs(cardItems) do
					validCards[item.Id] = true
				end
				for _, id in ipairs(type(cfg["Summer Card Priority"]) == "table" and cfg["Summer Card Priority"] or {}) do
					if type(id) == "string" and validCards[id] and not seenCards[id] then
						seenCards[id] = true
						savedCardOrder[#savedCardOrder + 1] = id
					end
				end
				cfg["Summer Card Priority"] = savedCardOrder
				summer.cardPriorityCtrl = cards:AddPrioritySelector({
					Id = "Summer Card Priority",
					Title = "Card priority",
					Items = cardItems,
					Default = cfg["Summer Card Priority"],
					Columns = 2,
					OnChanged = function(order)
						if not lock and not dead then
							set("Summer Card Priority", table.clone(order))
						end
					end,
				})
				cfg["Summer Card Priority"] = summer.cardPriorityCtrl:GetOrder()
				function summer.rebuildCardPriority()
					if summer.cardPriorityCtrl then
						summer.cardPriorityCtrl:SetItems(buildCardPriorityItems())
					end
				end
				summer.status = cards:AddParagraph({ Content = "Waiting for a Summer match." })
				local items = section("Summer Event", "Artifacts, Charms and Compass"):AddCard({
					Id = "summer-inventory",
					Title = "Summer inventory",
					Icon = "backpack",
					Collapsible = true,
					DefaultExpanded = true,
				})
				choice(items, "Summer Item", "Owned Item", {}, function()
					if summer.describeItem then
						summer.describeItem()
					end
				end)
				summer.itemInfo =
					items:AddParagraph({ Content = "Refresh to list owned Artifacts, Charms and Celestial Compasses." })
				function summer.describeItem()
					local item = summer.items and summer.items[cfg["Summer Item"]]
					if not item then
						if summer.itemInfo and summer.itemInfo.SetValue then
							summer.itemInfo:SetValue("Select an owned item.")
						end
						return
					end
					local row = D.items and D.items[item.item_id] or {}
					local details = (row.description or ""):gsub("<[^>]+>", "")
					if row.artifact_data then
						for _, unit in pairs(owned()) do
							if unit.unit_id == row.artifact_data.unit_id then
								details = details .. "\nCompatible: " .. label(unit.unit_id) .. " [" .. unit.uuid .. "]"
							end
						end
					end
					if item._unique_item_data then
						local ok, data = pcall(function()
							return game:GetService("HttpService"):JSONEncode(item._unique_item_data)
						end)
						if ok then
							details = details .. "\nRoll: " .. data
						end
					end
					if summer.itemInfo and summer.itemInfo.SetValue then
						summer.itemInfo:SetValue(
							details .. "\nID: " .. item.item_id .. (item.uuid and "\nUUID: " .. item.uuid or "")
						)
					end
				end
				function summer.refreshItems()
					ensure()
					summer.items = {}
					local list, data = {}, inventory()
					for _, item in pairs(data.unique_items or {}) do
						local row = D.items and D.items[item.item_id]
						if
							row
							and (row.artifact_data or (row.usage and row.usage.type == "equip_charm"))
							and type(item.uuid) == "string"
						then
							local name = (row.name or item.item_id):gsub("<[^>]+>", "")
								.. (row.tier and " T" .. row.tier or "")
								.. " ["
								.. item.uuid
								.. "]"
							summer.items[name], list[#list + 1] = item, name
						end
					end
					for id, amount in pairs(data.normal_items or {}) do
						local row = D.items and D.items[id]
						if amount > 0 and row and row._celestial_compass then
							local name = (row.name or id) .. " x" .. amount
							summer.items[name], list[#list + 1] = { item_id = id }, name
						end
					end
					table.sort(list)
					refreshPick("Summer Item", list)
					summer.describeItem()
				end
				button(items, "Refresh Summer Inventory", summer.refreshItems)
				button(items, "Select In Game Inventory", function()
					local item = summer.items and summer.items[cfg["Summer Item"]]
					assert(item, "Refresh and choose an owned item first.")
					local gui = LP:FindFirstChild("PlayerGui")
					local matches = {}
					for _, screen in ipairs(gui and gui:GetChildren() or {}) do
						if tostring(screen.Name):lower():find("inventory", 1, true) and summer.visible(screen) then
							for _, obj in ipairs(screen:GetDescendants()) do
								if
									obj.Name == (item.uuid or item.item_id)
									and obj:IsA("GuiButton")
									and summer.visible(obj)
								then
									matches[#matches + 1] = obj
								end
							end
						end
					end
					assert(
						#matches == 1,
						"Open the game inventory and show the selected item. Its exact item button must be visible."
					)
					summer.activate(matches[1])
				end)
				local buyIds = table.clone(cfg["Dungeon Buy"])
				for _, id in ipairs(cfg["Dungeon Ignore"]) do
					if not table.find(buyIds, id) then
						buyIds[#buyIds + 1] = id
					end
				end
				multi(buying, "Dungeon Ignore", "Ignored Items", options(buyIds))
				local dungeonSec = section("Dungeon", "Current choices")
				local dungeonCards = {}
				local function render(sec, cards, rows, key, prefix)
					for i, row in ipairs(rows) do
						local card = cards[i]
						if not card then
							card = sec:AddCard({ Id = prefix .. i, Title = row.title, Icon = "map" })
							cards[i] = card
							button(card, "Choose", function()
								assert(card.row and shown(card.row.button), "Choice expired. Refresh choices.")
								if card.row.choose then
									card.row.choose()
								else
									press(card.row.button, key)
								end
							end)
						end
						card.row = row
						card:SetTitle(row.title)
						card:SetDescription(row.description)
						card:SetVisible(true)
					end
					for i = #rows + 1, #cards do
						cards[i].row = nil
						cards[i]:SetVisible(false)
					end
				end
				local images, known = {}, {}
				local function imageKey(icon)
					return icon.Image .. ":" .. tostring(icon.ImageRectOffset) .. ":" .. tostring(icon.ImageRectSize)
				end
				local function catalog()
					local bank = at(RS, "packages.assets.gui.DungeonItems")
					for _, icon in ipairs(bank and bank:GetDescendants() or {}) do
						if icon:IsA("ImageLabel") then
							known[icon.Name] = true
						end
						if icon:IsA("ImageLabel") and icon.Image ~= "" then
							local key = imageKey(icon)
							local previous = images[key]
							images[key] = previous == nil and icon.Name or previous == icon.Name and previous or false
						end
					end
					for _, key in ipairs({
						"Dungeon Accept",
						"Dungeon Deny",
						"Dungeon Buy",
						"Dungeon Ignore",
					}) do
						for _, id in ipairs(cfg[key]) do
							known[id] = true
						end
					end
				end
				local function itemId(obj)
					local ids = {}
					for _, part in ipairs(obj:GetDescendants()) do
						if known[part.Name] then
							ids[part.Name] = true
						end
						if part:IsA("ImageLabel") and images[imageKey(part)] then
							ids[images[imageKey(part)]] = true
						end
					end
					local id = next(ids)
					return id and not next(ids, id) and id or nil
				end
				-- A floor number or GUI instance is not a room identity: the game can reuse frames.
				-- Reuse only explicit room UUIDs scoped to the current dungeon run.
				modes.dungeonPathCache = {
					session = HttpService:GenerateGUID(false),
					entries = {},
					uuids = {},
				}
				function modes.resetDungeonCache()
					modes.dungeonPathCache = { session = HttpService:GenerateGUID(false), entries = {}, uuids = {} }
				end
				function modes.validDungeonUuid(value)
					return type(value) == "string" and value:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
				end
				function modes.dungeonNodeUuid(node)
					for _, key in ipairs({ "room_uuid", "node_uuid", "roomUuid", "nodeUuid", "RoomUUID", "NodeUUID" }) do
						local value = node:GetAttribute(key)
						local child = node:FindFirstChild(key)
						if type(value) ~= "string" and child and child:IsA("StringValue") then value = child.Value end
						if modes.validDungeonUuid(value) then return value:lower() end
					end
				end
				function modes.cachedDungeonRoom(node)
					local cache = modes.dungeonPathCache
					local uuid = modes.dungeonNodeUuid(node)
					return uuid and cache.uuids[uuid] or nil
				end
				function modes.identifyDungeonCache()
					local cache = modes.dungeonPathCache
					if cache.scopeChecked or lobby() then return end
					local ok, data = pcall(level)
					if not ok or type(data._dungeon) ~= "table" then return end
					cache.scopeChecked = true
					local run = data._dungeon.run_uuid or data._dungeon.dungeon_uuid
					if not modes.validDungeonUuid(run) then return end
					cache.session = run:lower()
					if not ready then return end
					local file = dir .. "Cache/DungeonPathCache_" .. cache.session .. ".json"
					local loaded, previous = pcall(function()
						if not isfile(file) then return nil end
						return HttpService:JSONDecode(readfile(file))
					end)
					if not loaded or type(previous) ~= "table" or previous.session ~= cache.session or type(previous.rooms) ~= "table" then return end
					for _, record in ipairs(previous.rooms) do
						if type(record) == "table" and type(record.map) == "string" and #record.map <= 200
							and finite(record.floor) and record.floor >= 1 and record.floor % 1 == 0
							and modes.validDungeonUuid(record.nodeUuid) then
							local uuid = record.nodeUuid:lower()
							local existing = cache.uuids[uuid]
							if existing == false or (existing and (existing.map ~= record.map or existing.floor ~= record.floor)) then
								cache.uuids[uuid] = false
							else
								cache.uuids[uuid] = record
							end
							cache.entries[#cache.entries + 1] = record
						end
					end
				end
				function modes.saveDungeonRoom(node, name, floor, pathIndex, source)
					if not finite(floor) or floor < 1 or floor % 1 ~= 0 then return end
					local cache = modes.dungeonPathCache
					local uuid = modes.dungeonNodeUuid(node)
					local record = { map = name, floor = floor, path = pathIndex, source = source, nodeUuid = uuid }
					if uuid then
						local previous = cache.uuids[uuid]
						if previous == false or (previous and (previous.map ~= name or previous.floor ~= floor)) then
							cache.uuids[uuid] = false
						else
							cache.uuids[uuid] = record
						end
					end
					cache.entries[#cache.entries + 1] = record
				end
				function modes.writeDungeonCache()
					if not ready then return end
					local cache = modes.dungeonPathCache
					local ok, err = pcall(function()
						local folder = dir .. "Cache/"
						if not isfolder(folder) then makefolder(folder) end
						writefile(folder .. "DungeonPathCache_" .. cache.session .. ".json", HttpService:JSONEncode({
							version = 1, session = cache.session, rooms = cache.entries,
						}))
					end)
					if not ok and not cache.warned then
						cache.warned = true
						notify("Dungeon path cache could not be saved: " .. tostring(err))
					end
				end
				local function scanDungeonPaths(screen, panel, marker, rows)
					modes.identifyDungeonCache()
					local scan = { panel = panel, marker = marker, frames = {}, maps = {} }
					for _, row in ipairs(rows) do scan.frames[row.index] = row.frame end
					modes.pathScan = scan
					state.seen = state.seen or {}
					state.seen["path-map-preview"] = nil
					act("Auto Dungeon", "path-map-preview", function(valid)
						local info = at(screen, "Main.Main.Outer.LevelInfo")
						local close = at(info, "Main.Close")
						local mapLabel = at(info, "Main.Scrolling.MapName")
						local depthLabel = at(info, "Main.Scrolling.Depth")
						local function invoke(button)
							assert(button and button:IsA("GuiButton") and shown(button), "Dungeon preview button unavailable.")
							local handlers = callbacks(button)
							assert(handlers and #handlers > 0, "Dungeon preview button has no callable handler.")
							for _, fn in ipairs(handlers) do
								assert(valid(), "Dungeon preview cancelled.")
								fn()
							end
						end
						local function closePreview()
							if not shown(info) then modes.pathPreviewOpen = nil return end
							invoke(close)
							local deadline = os.clock() + 3
							while valid() and shown(info) and os.clock() < deadline do task.wait(0.1) end
							assert(valid() and not shown(info), "Dungeon preview did not close.")
							modes.pathPreviewOpen = nil
						end
						local function readPreview(node, button, pathIndex, source)
							local cached = modes.cachedDungeonRoom(node)
							if cached then
								scan.cacheHits = (scan.cacheHits or 0) + 1
								return cached.map
							end
							scan.previewCount = (scan.previewCount or 0) + 1
							closePreview()
							local availableUntil = os.clock() + 3
							while valid() and not shown(button) and os.clock() < availableUntil do task.wait(0.1) end
							modes.pathPreviewOpen = true
							invoke(button)
							local deadline = os.clock() + 3
							while valid() and not shown(info) and os.clock() < deadline do task.wait(0.1) end
							assert(valid() and shown(info), "Dungeon preview did not open.")
							assert(pause(0.15) and valid(), "Dungeon preview cancelled.")
							local name = mapLabel and mapLabel.Text:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
							assert(name and name ~= "", "Dungeon preview map name is missing.")
							local depth = depthLabel and tonumber(depthLabel.Text:match("%d+"))
							modes.saveDungeonRoom(node, name, depth, pathIndex, source)
							closePreview()
							return name
						end
						local ok, err = pcall(function()
							assert(info and close and mapLabel, "Dungeon LevelInfo preview is unavailable.")
							for _, row in ipairs(rows) do
								assert(valid() and row.frame.Parent, "Dungeon paths changed during preview.")
								local maps = { readPreview(row.frame, row.button, row.index, "current") }
								local readyUntil = os.clock() + 3
								while valid() and not shown(row.frame) and os.clock() < readyUntil do task.wait(0.1) end
								assert(valid() and shown(row.frame), "Dungeon path list did not reopen after preview.")
								local top = row.frame:FindFirstChild("FrameTop")
								for _, future in ipairs(top and top:GetChildren() or {}) do
									local button = future:IsA("Frame") and future:FindFirstChild("ImageButton")
									if button and button:IsA("GuiButton") and shown(button) then
										maps[#maps + 1] = readPreview(future, button, row.index, "next")
									end
								end
								scan.maps[row.index] = maps
							end
						end)
						modes.writeDungeonCache()
						if not ok then
							pcall(closePreview)
							scan.failed, scan.retryAt = tostring(err), os.clock() + 10
							if valid() then
								notify("Auto Dungeon: cannot inspect map previews; retrying. " .. tostring(err))
							end
						elseif valid() then
							scan.done = true
						end
					end)
				end
				local function dungeonTick(screen)
					local outer = at(screen, "Main.Main.Outer")
					local holder = at(outer, "MainHolder.Outer")
					local rows = {}
					local panel, name = dungeonPanel(screen)
					phase(panel, text(holder, "LevelSelection.FurthestRoom.V"))
					if not panel then
						return rows
					end
					if name == "StartHolder" then
						if state.startAt then
							if os.clock() < state.startAt then
								return rows
							end
							state.seen[panel] = nil
						end
						act("Auto Dungeon", panel, function(valid)
							if not state.keysBought then
								for _ = 1, 3 do
									if not valid() then
										return
									end
									pcall(remote, "buy_madoka_shop_item", "dungeon_key", "1")
								end
								state.keysBought = true
							end
							if pause(2) and valid() then
								if shown(at(screen.Parent, "UnitInfo.holder.info1.SkipLabel")) then
									state.seen[panel] = nil
									return
								end
								state.startAt = os.clock() + 5
								dungeonTry("dungeon_start")
							end
						end)
					elseif name == "YouDied" then
						if os.clock() >= (state.deathContinueAt or 0) then
							state.deathContinueAt = os.clock() + 4
							state.seen[panel] = nil
							act("Auto Dungeon", panel, function(valid)
								if valid() and not lobby() then goLobby() end
							end)
						end
					elseif name == "LevelInfo" then
						if modes.pathPreviewOpen then
							press(at(panel, "Main.Close"), "Auto Dungeon", function()
								modes.pathPreviewOpen = nil
							end)
						else
							press(at(panel, "Main.Scrolling.Enter"), "Auto Dungeon")
						end
					elseif name == "LevelSelection" then
						if not lobby() and report.finished then
							local result = tostring(report.title or resultText()):upper()
							if finite(report.floor) and report.floor >= 20 and result:find("VICTORY", 1, true) then
								return rows -- Final reward must be opened before leaving.
							end
							if not modes.dungeonWebhookReady then
								modes.dungeonWebhookReady, modes.dungeonWebhookAt = true, os.clock()
							end
							if cfg["Result Webhook"] and not sent and not errors.Webhook then return rows end
						end
						local root = at(panel, "Inset.MainRow")
						local index = 0
						local function score(attrs)
							local total, labels = 0, {}
							for _, icon in ipairs(attrs and attrs:GetChildren() or {}) do
								local rank = table.find(cfg["Dungeon Rooms"], icon.Name)
								if icon:IsA("ImageLabel") and icon.Visible and rank then
									total += #cfg["Dungeon Rooms"] - rank + 1
									labels[#labels + 1] = title(icon.Name)
								end
							end
							return total, labels
						end
						for _, frame in ipairs(root and root:GetChildren() or {}) do
							if
								not frame:IsA("Frame")
								or frame.Name ~= "Frame"
								or frame:FindFirstChild("Configuration")
							then
								continue
							end
							index += 1
							local slot = index
							local main, btn = frame:FindFirstChild("Main"), frame:FindFirstChild("ImageButton")
							local attrs, unavailable =
								main and main:FindFirstChild("LevelAttributes"),
								main and main:FindFirstChild("Unavailable")
							if not attrs or not shown(btn) or (unavailable and shown(unavailable)) then
								continue
							end
							local total, labels = score(attrs)
							local preview = score(at(frame, "FrameTop.Frame.Main.LevelAttributes"))
							rows[#rows + 1] = {
								title = #labels > 0 and table.concat(labels, ", ") or "Room",
								score = total + preview,
								ignored = false,
								index = slot,
								frame = frame,
								button = btn,
								choose = function()
									dungeonCall("room", "dungeon_enter_room", tostring(slot))
								end,
							}
						end
						if #rows > 1 then
							local marker = text(holder, "LevelSelection.FurthestRoom.V") .. ":" .. tostring(report.floor)
							local scan = modes.pathScan
							local same = scan and scan.panel == panel and scan.marker == marker
							if same then
								local count = 0
								for _, row in ipairs(rows) do
									count += 1
									if scan.frames[row.index] ~= row.frame then same = false break end
								end
								if count ~= (scan.count or count) then same = false end
							end
							if not same or (scan.failed and os.clock() >= scan.retryAt) then
								scanDungeonPaths(screen, panel, marker, rows)
								if modes.pathScan then modes.pathScan.count = #rows end
								return rows
							end
							if not scan.done then return rows end
							for _, row in ipairs(rows) do
								for _, name in ipairs(scan.maps[row.index] or {}) do
									for _, ignored in ipairs(cfg["Dungeon Ignore Maps"]) do
										if name:lower() == tostring(ignored):lower() then row.ignored = true break end
									end
									if row.ignored then break end
								end
							end
						end
						table.sort(rows, function(a, b)
							if a.ignored ~= b.ignored then return not a.ignored end
							return a.score > b.score or (a.score == b.score and a.index < b.index)
						end)
						if rows[1] and (not rows[1].ignored or #rows == 1) then
							if not modes.joinReady("Auto Dungeon") then return rows end
							modes.resetJoin("Auto Dungeon")
							rows[1].choose()
						end
					elseif name == "ShopSelection" then
						local scroll = at(panel, "Inset.ItemsRows.Scroll")
						local money = tonumber((text(outer, "MainHolder.Money.TitleMoney"):gsub(",", "")))
						if money then
							state.money = math.min(state.money or money, money)
						end
						local index = 0
						for _, frame in ipairs(scroll and scroll:GetChildren() or {}) do
							if
								not frame:IsA("Frame")
								or frame.Name ~= "SellFrame"
								or frame:FindFirstChild("Configuration")
							then
								continue
							end
							index += 1
							local slot = index
							local btn = at(frame, "Main.Buy")
							if not shown(btn) then
								continue
							end
							local id = itemId(frame)
							local price = tonumber((text(btn, "Main.Money.Title"):gsub(",", "")))
							local rank = id
								and not has(cfg["Dungeon Ignore"], id)
								and (table.find(cfg["Dungeon Buy"], id) or #cfg["Dungeon Buy"] + 1)
							rows[#rows + 1] = {
								title = text(frame, "Main.ItemInformation.ItemName"),
								button = btn,
								description = text(frame, "Main.ItemInformation.ItemDescription"),
								rank = rank or math.huge,
								price = price,
								index = slot,
								token = frame,
								choose = function()
									if dungeonCall(frame, "dungeon_buy_shop", slot) and state.money and price then
										state.money -= price
									end
								end,
							}
						end
						table.sort(rows, function(a, b)
							return a.rank < b.rank or (a.rank == b.rank and a.index < b.index)
						end)
						if cfg["Dungeon Shop"] then
							if not money then
								return rows
							end
							for _, row in ipairs(rows) do
								if
									row.rank < math.huge
									and money
									and row.price
									and row.price >= 0
									and state.money >= row.price
									and not state.seen[row.token]
								then
									row.choose()
									return rows
								end
							end
						end
						dungeonCall(panel, "dungeon_continue_shop")
					elseif name == "ShrineRoom" then
						local yes, no = at(panel, "Inset.Bottom.Yes"), at(panel, "Inset.Bottom.No")
						rows = {
							{
								title = "Accept shrine",
								button = yes,
								choose = function()
									dungeonCall(panel, "dungeon_shrine_accept")
								end,
							},
							{
								title = "Deny shrine",
								button = no,
								choose = function()
									dungeonCall(panel, "dungeon_continue_shop")
								end,
							},
						}
						if not cfg["Dungeon Shrine"] then
							return rows
						end
						local scroll = at(panel, "Inset.ItemsRows.Scroll")
						local accept, count = false, 0
						local function prefix(ids, id)
							for _, value in ipairs(ids) do
								if id:sub(1, #value) == value then
									return true
								end
							end
							return false
						end
						for _, frame in ipairs(scroll and scroll:GetChildren() or {}) do
							if not shown(frame) or not frame:IsA("Frame") or frame:FindFirstChild("Configuration") then
								continue
							end
							count += 1
							local id = itemId(frame)
							if
								id
								and id:match("^_curse")
								and prefix(cfg["Dungeon Accept"], id)
								and not prefix(cfg["Dungeon Deny"], id)
							then
								accept = true
							end
						end
						if count == 0 then
							return rows
						end
						dungeonCall(panel, accept and "dungeon_shrine_accept" or "dungeon_continue_shop")
					elseif name == "OpenTreasure" then
						if state.chestsDone then
							if os.clock() >= state.continueAt then
								state.seen[panel] = nil
								state.continueAt = os.clock() + 2
								dungeonTry("dungeon_continue_shop")
							end
							return rows
						end
						local result = tostring(report.title or resultText()):upper()
						local victory = result:find("VICTORY", 1, true) ~= nil
						local finish = not lobby() and victory and (state.depth or 0) >= 20
						if not finish and not lobby() then
							if not state.depth then
								local ok, data = pcall(level, true)
								state.depth = ok and type(data._dungeon) == "table" and tonumber(data._dungeon.depth)
									or report.floor
							end
							if not finite(state.depth) then
								state.depth = report.floor
							end
							if finite(state.depth) then
								finish = victory and state.depth >= 20
							end
						end
						if not finish and not lobby() and not finite(state.depth) then
							return rows
						end
						local chests = {}
						for _, key in ipairs({ "ChestFrameNormal", "ChestFrameRare" }) do
							local frame = at(panel, "Inset.ItemsRows.Scroll." .. key)
							local amount = tonumber(text(frame, "Main.ItemHolder.Amount"):match("%d+")) or 0
							chests[#chests + 1] = { count = amount, rare = key == "ChestFrameRare" }
						end
						act("Auto Dungeon", panel, function(valid)
							if not lobby() then
								-- Final map data may disappear before the treasure UI closes.
								pcall(sampleRewards)
							end
							modes.openingChests = true
							if
								lobby() or finish
								or cfg["Dungeon Chests"] == "Open at checkpoints"
								or (
									cfg["Dungeon Chests"] == "Open at floor"
									and state.depth >= cfg["Dungeon Chest Floor"]
								)
							then
								for _, chest in ipairs(chests) do
									for _ = 1, chest.count do
										if not valid() then
											return
										end
										if chest.rare then
											remote("dungeon_open_chest", true)
										else
											remote("dungeon_open_chest")
										end
										if not pause(0.1) then
											return
										end
									end
								end
							end
							modes.openingChests, modes.chestsAt = false, os.clock()
							if finish then
								-- Floor 20+ clear: wait for webhook, then exit to lobby.
								modes.dungeonWebhookReady, modes.dungeonWebhookAt = true, os.clock()
								while
									cfg["Result Webhook"]
									and not sent
									and not errors.Webhook
									and not lobby()
									and valid()
								do
									if not pause(0.2) then
										break
									end
								end
								state.chestsDone, state.continueAt = true, math.huge
								if valid() and not lobby() then pcall(goLobby) end
								return
							end
							dungeonTry("dungeon_continue_shop")
							state.chestsDone, state.continueAt = true, os.clock() + 2
						end)
					end
					return rows
				end
				function modes.tick()
					if not lobby() then
						local ok, current = pcall(level)
						if ok and challengeMatch(current) then return end
					end
					if lobby() and modes.priorityRoute ~= "Auto Dungeon" then
						return
					end
					if lobby() and dungeonHold.failed then return end
					if lobby() and not modes.joinReady("Auto Dungeon") then return end
					local gui = LP:FindFirstChild("PlayerGui")
					local done = val(workspace:FindFirstChild("_DATA"), "GameFinished", false)
					local rows = {}
					local key = enabled("Auto Dungeon") and "Auto Dungeon"
					if not key then
						return
					end
					local screen = gui and gui:FindFirstChild("DungeonUI")
					local death = at(screen, "Main.Main.Outer.MainHolder.Outer.YouDied")
					if not lobby() and shown(death) then
						-- Death must take priority over stale menu state, popups and ongoing actions.
						if os.clock() >= (modes.deathExitAt or 0) then
							modes.deathExitAt = os.clock() + 5
							task.spawn(function()
								if enabled("Auto Dungeon") and not lobby() and shown(death) then
									if not goLobby() then
										pcall(function() getRemote("dungeon_quit"):InvokeServer() end)
									end
								end
							end)
						end
						return
					end
					local panel, panelName = dungeonPanel(screen)
					if modes.pathPreviewOpen and not busy and not shown(at(screen, "Main.Main.Outer.LevelInfo")) then
						modes.pathPreviewOpen = nil
					end
					local popup = shown(at(gui, "UnitInfo.holder.info1.SkipLabel"))
					local waiting = false
					if popup or (not lobby() and done and panelName ~= "YouDied") then
						local map, units = workspace:FindFirstChild("_MAP_CONFIG"), workspace:FindFirstChild("_UNITS")
						if reward.map ~= map or reward.units ~= units then
							reward = { map = map, units = units, count = 0, at = 0, started = os.clock() }
							state.failed, modes.err = nil, nil
						end
						if not mode and popup and os.clock() >= reward.at then
							local input = service("VirtualInputManager")
							local camera = workspace.CurrentCamera
							local size = camera and camera.ViewportSize
							local x, y = size and math.floor(size.X / 2) or 0, size and math.floor(size.Y / 2) or 0
							input:SendMouseButtonEvent(x, y, 0, true, game, 0)
							input:SendMouseButtonEvent(x, y, 0, false, game, 0)
							reward.count += 1
							reward.at = os.clock() + 1
						end
						waiting = popup
					elseif not done then
						reward = {}
					end
					modes.rewardWaiting = waiting
					if popup then
						return
					end
					if modes.err then
						local err = modes.err
						modes.err = nil
						state.failed = true
						if lobby() then dungeonHold.failed, dungeonHold.retryAt = true, os.clock() + 10 end
						error(err, 0)
					end
					if state.failed or busy or mode then
						return
					end
					if key == "Auto Dungeon" and not lobby() and done and not panel then
						if screen and shown(at(gui, "LeftUI_test.Buttons.Dungeon")) then
							openMenu(gui, screen, key)
							return
						end
						local result = gui and gui:FindFirstChild("ResultsUI")
						if not shown(result) then
							if not waiting then
								openMenu(gui, screen, key)
							end
							return
						end
						phase(result, "Results")
						local button = at(result, "Holder.Buttons.Next")
						if not shown(button) then
							if waiting then
								return
							end
							local retry = at(result, "Finished.NextRetry")
							local floor = report.floor
							if not floor and not shown(retry) then
								local ok, data = pcall(level, true)
								floor = ok and type(data._dungeon) == "table" and tonumber(data._dungeon.depth)
							end
							if floor and floor >= 20 and resultText():find("VICTORY") then
								button = shown(retry) and retry or at(result, "Finished.Next")
							else
								button = retry
							end
						end
						if shown(button) and (button ~= state.resultButton or os.clock() >= state.resultAt) then
							state.seen[button] = nil
							if press(button, key) then
								state.resultButton, state.resultAt = button, os.clock() + 1
							end
						end
						return
					end
					if waiting then
						return
					end
					if not screen then
						return
					end
					if not lobby() then
						modes.queue, modes.room, modes.opening, modes.portals, modes.popups, modes.confirmed =
							nil, nil, nil, nil, nil, nil
					end
					if not lobby() and not done and not screen.Enabled then
						modes.pathScan = nil
						opened[screen] = nil
						phase(nil, "Playing")
						return
					end
					if (lobby() or done) and not openMenu(gui, screen, key) then
						return
					end
					if not screen.Enabled then
						return
					end
					catalog()
					local rows = dungeonTick(screen)
					render(dungeonSec, dungeonCards, rows, key, "dungeon-choice-")
				end
				function modes.fail()
					state.failed = true
				end
			end
			setupModes()
			local function stages()
				local out, world = {}, selectedWorld()
				if not world then
					return out
				end
				if world.infinite then
					table.insert(
						out,
						D.levels[world.infinite.id] and D.levels[world.infinite.id].name or "Infinite Mode"
					)
				end
				local keys = {}
				for key in pairs(world.levels or {}) do keys[#keys + 1] = key end
				table.sort(keys, function(a, b)
					local x, y = tonumber(a), tonumber(b)
					if x and y then return x < y end
					if x then return true end
					if y then return false end
					return tostring(a) < tostring(b)
				end)
				for _, key in ipairs(keys) do
					local row = world.levels[key]
					local id = type(row) == "table" and row.id or row
					if D.levels[id] then
						table.insert(out, D.levels[id].name)
					end
				end
				return out
			end

			local routes = section(
				"Teleport",
				"Lobby routes",
				"Enabled routes follow the Join priority list."
			)
			do
				local find = route(routes, "Auto Find Match")
				choice(find, "Matchmaking Map", "Matchmaking Map", {}, function()
					if enabled("Auto Find Match") then
						modes.reset()
					end
				end)
			end
			local joinSec = route(
				routes,
				"Auto Join Story/INF",
				"Auto Join Story / Infinite",
				"Choose a world and stage, then join automatically."
			)
			choice(joinSec, "StoryInf_World", "World", {}, function()
				cfg.StoryInf_Level = ""
				lock = true
				refreshPick("StoryInf_Level", stages())
				lock = false
				saveCfg()
			end)
			choice(joinSec, "StoryInf_Level", "Stage", {})
			option(joinSec, "Join High Story", "Join High Story")
			option(joinSec, "Hard_StoryInf", "Hard Difficulty")
			local castle = route(routes, "Auto Infinity Castle", nil, "Climb until the selected floor.")
			number(castle, "AutoJoinCastleMaxRoom", "Stop At Floor", 1, 10000)
			option(castle, "Hard Difficulty", "Hard Castle Difficulty")
			route(routes, "Auto Daily Challenge", nil, "Join the daily challenge through matchmaking.")
			local challenge = route(routes, "Auto Challenge", nil, "Join challenges that pass your filters.")
			option(challenge, "Check Challenge", "Check Challenge")
			multi(challenge, "Challenge_IgnoreWorlds", "Ignore Challenge Worlds", {})
			multi(challenge, "Challenge_IgnoreDifficulties", "Ignore Challenge Modifiers", names(diff))
			multi(challenge, "Challenge_IgnoreRewards", "Ignore Challenge Rewards", {})
			button(challenge, "Refresh Game Data", loadData)
			section("Teleport", "Priority teleport")
				:AddCard({
					Id = "join-priority",
					Title = "Join priority",
					Description = "Top enabled route wins; routing repeats after every visit to the lobby.",
					Collapsible = true,
				})
				:AddPrioritySelector({
					Id = "Join Priority",
					Items = {
						{ Id = "Auto Join Story/INF", Label = "Auto Join Story / Inf" },
						{ Id = "Auto Challenge", Label = "Auto Join Challenge" },
						{ Id = "Auto Dungeon", Label = "Auto Join Dungeon" },
						{ Id = "Auto Infinity Castle", Label = "Auto Infinity Castle" },
						{ Id = "Auto Use", Label = "Auto Open Portal" },
						{ Id = "Auto Find Match", Label = "Auto Find Match" },
						{ Id = "Auto Daily Challenge", Label = "Auto Daily Challenge" },
						{ Id = "Auto Summer Hunt", Label = "Auto Summer Hunt" },
					},
					Default = cfg["Join Priority"],
					Columns = 2,
					OnChanged = function(order)
						if not lock and not dead then
							set("Join Priority", table.clone(order))
						end
					end,
				})

			local portalSec = route(
				section("Portals", "Opening"),
				"Auto Use",
				"Auto Open Portal",
				"Open an owned portal that matches these filters."
			)
			multi(portalSec, "PortalUSE Portals", "Portal Types", portals)
			local tiers = {}
			for i = 1, 15 do
				table.insert(tiers, tostring(i))
			end
			multi(portalSec, "PortalUSE Tiers", "Portal Tiers", tiers)
			multi(portalSec, "PortalUSE Difficulties Ignore", "Ignore Portal Modifiers", names(diff))
			multi(portalSec, "PortalUSE Bonus Ignore", "Ignore Damage Bonuses", names(bonus))
			multi(portalSec, "PortalUSE Worlds Ignore", "Ignore Portal Worlds", names(worlds))
			option(portalSec, "Only Friends")
			local startSec = toggle(
				section("Portals", "Starting"),
				"Auto Start",
				"Auto Start Portal",
				nil,
				"Start when enough players join or the timer reaches your limit.",
				"play",
				true
			)
			number(startSec, "PortalUSE Start After Time", "Wait Seconds", 0, 70)
			number(startSec, "PortalUSE Star After Players", "Minimum Players", 1, 6)
			startSec:AddParagraph({ Content = "Next Portal in Match uses the opening filters above." })
			local deleteSec = arm(section("Portals", "Cleanup"), "Auto Delete Portals", function()
				assert(
					#cfg["Selected Portals Delete"] > 0
						and #cfg["Selected Tiers Delete"] > 0
						and #cfg["Selected Portal Difficulties Delete"] > 0,
					"Choose portal types, tiers and modifiers to delete first."
				)
			end)
			multi(deleteSec, "Selected Portals Delete", "Delete Portal Types", portals)
			multi(deleteSec, "Selected Tiers Delete", "Delete Portal Tiers", tiers)
			multi(deleteSec, "Selected Portal Difficulties Delete", "Delete Portal Modifiers", names(diff))
			multi(deleteSec, "Ignore Bonus Delete", "Keep Damage Bonuses", names(bonus))
			multi(deleteSec, "Ignore Worlds Delete", "Keep Portal Worlds", names(worlds))

			do
				roll.items = {
					["Reroll Token"] = "token",
					["Star Remnant"] = "star_remnant",
					["Star Remnant Limited"] = "star_remnant_limited",
				}
				function roll.reset()
					roll.rev = (roll.rev or 0) + 1
					roll.pending = nil
				end
				function roll.refresh()
					local list, traits = {}, {}
					roll.units, roll.traits = {}, {}
					for _, unit in pairs(owned()) do
						local name = label(unit.unit_id) .. " [" .. unit.uuid .. "]"
						roll.units[name] = unit.uuid
						list[#list + 1] = name
					end
					for id, data in pairs(defs("Traits")) do
						for tier in pairs(data.tiers or {}) do
							local name = data.name or id
							if not data.singular then
								name ..= " " .. (({ "I", "II", "III" })[tonumber(tier)] or tostring(tier))
							end
							roll.traits[name] = { id = id, tier = tonumber(tier) }
							traits[#traits + 1] = name
						end
					end
					table.sort(list)
					table.sort(traits)
					local prev = lock
					lock = true
					refreshPick("Trait Unit", list)
					refreshPick("Trait Targets", traits)
					lock = prev
				end
				function roll.unit()
					local uuid = roll.units and roll.units[cfg["Trait Unit"]]
					for _, unit in pairs(owned()) do
						if unit.uuid == uuid then
							return unit
						end
					end
					error("Choose an owned unit for trait rerolls.")
				end
				function roll.validate()
					assert(lobby(), "Trait rerolls are available in the lobby.")
					assert(roll.items[cfg["Trait Item"]], "Choose a trait reroll item.")
					assert(#cfg["Trait Targets"] > 0, "Choose at least one target trait.")
					for _, name in ipairs(cfg["Trait Targets"]) do
						assert(roll.traits and roll.traits[name], "Unknown target trait: " .. tostring(name))
					end
					return roll.unit()
				end
				function roll.stop(message)
					roll.reset()
					set("Auto Roll Trait", false)
					local prev = lock
					lock = true
					flags["Auto Roll Trait"]:SetEnabled(false)
					lock = prev
					notify(message)
				end
				function roll.key(traits)
					local list = {}
					for _, trait in pairs(traits or {}) do
						list[#list + 1] = tostring(trait.trait) .. ":" .. tostring(trait.tier or 1)
					end
					table.sort(list)
					return table.concat(list, ",")
				end
				function roll.step()
					local unit = roll.validate()
					local current = roll.pending and roll.pending.result or unit.traits or {}
					for _, trait in pairs(current) do
						for _, name in ipairs(cfg["Trait Targets"]) do
							local want = roll.traits[name]
							if trait.trait == want.id and (tonumber(trait.tier) or 1) == want.tier then
								roll.stop("Trait found: " .. name)
								return
							end
						end
					end
					local pending = roll.pending
					if pending then
						if os.clock() - pending.at < 1 then
							return
						end
						if
							not pending.result
							and unit.traits == pending.traits
							and roll.key(unit.traits) == pending.key
						then
							assert(os.clock() - pending.at < 10, "Trait update not confirmed; rerolls stopped.")
							return
						end
					end
					local item = roll.items[cfg["Trait Item"]]
					if item ~= "token" then
						assert((inventory().normal_items[item] or 0) > 0, "No " .. cfg["Trait Item"] .. " remaining.")
					end
					roll.pending = {
						uuid = unit.uuid,
						traits = unit.traits,
						key = roll.key(unit.traits),
						at = os.clock(),
					}
					if item == "token" then
						remote("request_token_trait_reroll", unit.uuid)
					else
						remote("use_item", item, { unit_uuid = unit.uuid })
					end
				end
				function roll.tick()
					if not enabled("Auto Roll Trait") or mode or not lobby() then
						return
					end
					local rev = roll.rev
					local ok, err = pcall(roll.step)
					if not ok and not dead and enabled("Auto Roll Trait") and rev == roll.rev then
						roll.stop(tostring(err))
					end
				end
				local endpoints = RS:FindFirstChild("endpoints")
				local events = endpoints and endpoints:FindFirstChild("server_to_client")
				local event = events and events:FindFirstChild("unit_traits_changed")
				if event then
					hooks[#hooks + 1] = event.OnClientEvent:Connect(function(uuid, traits)
						local pending = roll.pending
						if pending and pending.uuid == uuid then
							if type(traits) == "table" and next(traits) then
								for _, trait in pairs(traits) do
									if type(trait) ~= "table" or type(trait.trait) ~= "string" then
										return
									end
								end
								pending.result = traits
							end
						end
					end)
				end
				local card = toggle(section("Unit", "Traits"), "Auto Roll Trait", nil, function(on)
					if on then
						ensure()
						roll.validate()
					end
					roll.reset()
				end, nil, "sparkles", true)
				choice(card, "Trait Unit", "Trait Unit", {}, roll.reset)
				multi(card, "Trait Targets", "Target Traits", {})
				choice(
					card,
					"Trait Item",
					"Use Item",
					{ "Reroll Token", "Star Remnant", "Star Remnant Limited" },
					roll.reset
				)
				button(card, "Refresh Trait Units", roll.refresh)
			end
			do
				local card = toggle(section("Unit", "Summon Banner"), "Auto Summon Banner", "Auto Summon", function(on)
					if not on then modes.summon.pending = nil end
				end,
					"Summon from the selected banner while in the lobby.", "sparkles", true)
				choice(card, "Summon Banner", "Banner", {})
				choice(card, "Summon Amount", "Summons per request", { "1", "10" })
				number(card, "Summon Keep Gems", "Keep Gems / Summer Pearls", 0, 1000000000)
			end
			do
				local card = toggle(section("Unit", "Travelling Merchant"), "Auto Buy Merchant", nil, nil,
					"Buy selected items once per merchant visit while in the lobby.", "shopping-cart", true)
				multi(card, "Merchant Items", "Items to buy", {})
			end
			local selling = section("Unit", "Selling")
			do
				local sellSec = toggle(
					selling,
					"Auto Sell Units",
					nil,
					nil,
					"Sell your placed units at the selected wave.",
					"wallet",
					true
				)
				number(sellSec, "AutoSellUnitsWave", "Sell Units On Wave", 1, 100000)
				local sellFarms = toggle(
					selling,
					"Auto Sell Farms",
					nil,
					nil,
					"Sell income units at the selected wave.",
					"wheat",
					true
				)
				number(sellFarms, "AutoSellFarmsWave", "Sell Farms On Wave", 1, 100000)
				local buffSec = section("Gameplay", "Buffs and sacrifice", "Rotate buffs across matching owned units.")
				for _, key in ipairs({
					"Auto Buff Erwin 100%",
					"Auto Buff Wenda 100%",
					"Auto Buff Leafy 100%",
					"Auto Sacrifice Griffin",
				}) do
					toggle(
						buffSec,
						key,
						nil,
						nil,
						key == "Auto Sacrifice Griffin" and "Perform Griffin's sacrifice when ready."
							or "Rotate buffs across four units.",
						"sparkles"
					)
				end
				toggle(buffSec, "Auto Buff Rukia", nil, function()
					buffs.rukia_bankai = nil
				end, "rotate buffs accross 4 units", "sparkles")
				local ability = toggle(section("Gameplay", "Auto use ability"), "Auto Use Ability", "Auto Use Ability", nil,
					"Use selected unit abilities when the chosen condition is met.", "sparkles", true)
				multi(ability, "Ability Units", "Units", {})
				choice(ability, "Ability Mode", "Mode", { "When boss spawn", "When in range", "Always" })
			end
			toggle(
				section("Gameplay", "Dupe"),
				"Dupe Vegito",
				nil,
				nil,
				"Use the active attack on Vegito fusion units.",
				"sparkles"
			)

			local dupeFolders = {}
			local dupeActive = {}
			local function startDupe(child, folder, name)
				local stats = mine(child)
				local id = val(stats, "id", child.Name)
				if not enabled("Dupe Vegito") or not stats or dupeActive[child]
					or (id ~= "goku_ssj3_evolved" and id ~= "vegeta_majin_evolved") then return end
				dupeActive[child] = true
				task.spawn(function()
					while enabled("Dupe Vegito") and child.Parent == folder and workspace:FindFirstChild(name) == folder
						and mine(child) and not lobby() and not val(workspace:FindFirstChild("_DATA"), "GameFinished", false) do
						local ok, err = pcall(remote, "use_active_attack", child)
						if not ok and not dead and (not errors["Dupe Vegito"] or os.clock() - errors["Dupe Vegito"] >= 15) then
							errors["Dupe Vegito"] = os.clock()
							notify("Dupe Vegito: " .. tostring(err))
						end
						task.wait(ok and 0.2 or 1)
					end
					dupeActive[child] = nil
				end)
			end
			local function dupeTick()
				for _, name in ipairs({ "ignore", "_DEAD_UNITS" }) do
					local folder = workspace:FindFirstChild(name)
					local entry = dupeFolders[name]
					if not entry or entry.folder ~= folder then
						if entry then
							entry.connection:Disconnect()
						end
						dupeFolders[name] = nil
						if folder then
							local connection = folder.ChildAdded:Connect(function(child)
								startDupe(child, folder, name)
							end)
							dupeFolders[name] = { folder = folder, connection = connection }
							table.insert(hooks, connection)
						end
					end
					if folder and enabled("Dupe Vegito") then
						for _, child in ipairs(folder:GetChildren()) do startDupe(child, folder, name) end
					end
				end
			end

			do
				local start = section("Match", "Start")
				toggle(start, "Auto Start Match", nil, nil, "Vote to begin as soon as the map is ready.", "play")
				do
					local voteLose = section("Match", "Vote lose")
					local voteCard = toggle(
						voteLose,
						"Auto Vote Lose",
						"Vote Lose At Wave",
						nil,
						"Vote to lose at the chosen wave only in selected modes.",
						"flag",
						true
					)
					number(voteCard, "Vote Lose Wave", "Vote Lose Wave", 1, 100000)
					multi(voteCard, "Vote Lose Modes", "Modes", { "Challenge", "Story", "Infinite", "Dungeon", "Summer", "Portal" })
				end

				local ending = section("Match", "After a match")
				local endSec = ending:AddCard({
					Id = "match-result",
					Title = "End action",
					Description = "Choose the next step after results appear.",
					Icon = "two-arrows-loop-clockwise",
					Collapsible = true,
					DefaultExpanded = true,
				})
				option(endSec, "Auto Retry", "Replay If Defeated")
				ending
					:AddCard({
						Id = "end-action-priority",
						Title = "End action priority",
						Description = "Once arranged, the top entry that fits the result acts; fallback stays on Replay If Defeated.",
						Collapsible = true,
					})
					:AddPrioritySelector({
						Id = "End Action Priority",
						Items = {
							{ Id = "Next", Label = "Next" },
							{ Id = "Replay", Label = "Replay" },
							{ Id = "Leave", Label = "Leave" },
							{ Id = "Stay", Label = "Stay" },
						},
						Default = cfg["End Action Priority"],
						Columns = 2,
						OnChanged = function(order)
							if not lock and not dead then
								set("End Action Priority", table.clone(order))
							end
						end,
					})
				toggle(
					ending,
					"Auto Leave [LATE]",
					"Leave After 180 Seconds",
					nil,
					"Return to the lobby if results stay open for three minutes.",
					"clock"
				)
				local leave = toggle(
					ending,
					"AutoLeave_WAVE",
					"Auto Leave On Wave",
					nil,
					"Return to the lobby at a chosen wave.",
					"house",
					true
				)
				number(leave, "AutoLeaveOnWave", "Leave On Wave", 1, 100000)
				button(endSec, "Teleport To Lobby", goLobby)
			end
			local visualToggles = {}
			local function stopAll()
				if autoPlay then
					autoPlay:SetRunning(false)
					autoPlay:CancelPick()
				end
				epoch += 1
				hideUnits.set(false)
				boost.set(false)
				modes.reset()
				stop()
				if autoPlay then
					autoPlay:CancelPick()
				end
				lock = true
				for key, obj in pairs(flags) do
					cfg[key] = false
					obj:SetEnabled(false)
				end
				cfg["After Match"] = "Stay"
				for key, obj in pairs(visualToggles) do
					cfg[key] = false
					obj:SetValue(false)
				end
				lock = false
				for key in pairs(saved) do
					restore(key)
				end
				saveCfg()
				win:Notify({ Title = "Automation", Content = "All automation stopped." })
			end

			local quests = section("Rewards", "Quest rewards")
			for _, key in ipairs({
				"Auto Claim Quests",
				"Auto Take Daily Quests",
				"Auto Take Nami Quests",
			}) do
				toggle(quests, key, nil, nil, "Keep quest rewards and tasks up to date.", "gift-box")
			end
			local capsule = toggle(
				section("Rewards", "Capsules"),
				"Auto Open Capsules",
				nil,
				nil,
				"Open owned capsules except the types you keep.",
				"backpack",
				true
			)
			multi(capsule, "Ignored Capsules", "Keep Capsules", {})
			local skins = arm(section("Unit", "Skins"), "Auto Delete Skins", function()
				assert(#cfg["Delete Skin Rarities"] > 0, "Choose skin rarities to delete first.")
			end)
			multi(skins, "Delete Skin Rarities", "Skin Rarities To Delete", {})
			skins:AddParagraph({ Content = "Deletion switches start off each session." })
			button(skins, "Refresh Inventory Lists", loadData)

			local utilities = section("Misc", "Utilities")
			toggle(utilities, "Anti AFK", nil, nil, nil, "person")
			do
				local nextWalk, walking, walkingUntil = 0, nil, 0
				local function stopWalk()
					if walking and walking.Parent and os.clock() < walkingUntil then
						local root = walking.Parent:FindFirstChild("HumanoidRootPart")
						if root then
							walking:MoveTo(root.Position)
						end
					end
					walking, walkingUntil = nil, 0
				end
				toggle(utilities, "Walk Random", nil, function(on)
					if not on then
						stopWalk()
					end
					nextWalk = os.clock() + math.random(25, 50)
				end, "Occasionally walk to a nearby random position.", "person")
				modes.walkRandom = function()
					if
						not enabled("Walk Random")
						or (modeMenu and modeMenu())
						or mode
						or (autoPlay and (autoPlay.selecting or autoPlay.teamBusy))
						or os.clock() < nextWalk
					then
						return
					end
					nextWalk = os.clock() + math.random(25, 50)
					local character = LP.Character
					local humanoid = character and character:FindFirstChildOfClass("Humanoid")
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if not humanoid or humanoid.Health <= 0 or not root or humanoid.SeatPart then
						return
					end
					local angle, distance = math.random() * math.pi * 2, math.random(4, 10)
					local target = root.Position
						+ Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Exclude
					params.FilterDescendantsInstances = { character }
					local hit = workspace:Raycast(target + Vector3.new(0, 5, 0), Vector3.new(0, -15, 0), params)
					if hit and hit.Normal.Y >= 0.7 and math.abs(hit.Position.Y - root.Position.Y) <= 6 then
						walking, walkingUntil = humanoid, os.clock() + 4
						humanoid:MoveTo(hit.Position)
					end
				end
			end
			local visual = utilities:AddCard({
				Id = "visual-settings", Title = "Visual", Icon = "eye",
				Description = "Control visual effects and visibility.",
				Collapsible = true, DefaultExpanded = true,
			})
			for _, entry in ipairs({
				{ "FPS Boost", boost.set },
				{ "Hide Other Players Units", hideUnits.set },
				{ "Hide Map" },
			}) do
				local key, apply = entry[1], entry[2]
				cfg[key] = cfg[key] == true
				visualToggles[key] = visual:AddToggle({ Id = key, Title = key, Default = cfg[key] })
				local control = visualToggles[key]
				visual.cleanup:add(visual.ctx.store:observe(control.id, function(on)
					if lock or dead then return end
					local previous = cfg[key]
					cfg[key] = on
					if not saveCfg() then
						cfg[key] = previous
						lock = true; control:SetValue(previous); lock = false
						return
					end
					if apply and not check(function() apply(on) end) then
						cfg[key] = previous
						saveCfg()
						lock = true; control:SetValue(previous); lock = false
					end
				end))
				if cfg[key] and apply then check(function() apply(true) end) end
			end
			local privacy = section("Misc", "Privacy", "Changes restore when disabled or unloaded.")
			toggle(privacy, "Hide Name", nil, nil, "Hide your name in the game UI.", "person")
			toggle(
				privacy,
				"Hide Tab",
				"Hide Leaderboard Name",
				nil,
				"Hide your name in the leaderboard.",
				"list-bulleted"
			)
			toggle(privacy, "Fake Outfit", nil, nil, "Hide accessories and change character colours.", "person")
			local world = section("Misc", "World")
			toggle(world, "Place In Red Zones", nil, nil, "Remove local placement bounds.", "location-pin")
			local counterCard = toggle(
				section("Misc", "Counters"),
				"Show Takedowns",
				nil,
				nil,
				"Show unit takedowns and luck above your units.",
				"chart-line",
				true
			)
			option(counterCard, "Colored Takedowns")
			local web = toggle(
				section("Config", "Results"),
				"Result Webhook",
				nil,
				nil,
				"Send match results to your Discord webhook.",
				"bell",
				true
			)
			web:AddInput({
				Title = "Webhook URL",
				Default = cfg["Discord Url"],
				Validate = function(text)
					return #text <= 2048 or "URL must be at most 2048 characters."
				end,
				Callback = function(value)
					set("Discord Url", value:match("^%s*(.-)%s*$"))
				end,
			})
			web:AddInput({
				Title = "Discord User ID",
				Default = cfg["Discord UserID"],
				Validate = function(text)
					return (#text <= 25 and text:match("^%d*$") ~= nil) or "Use at most 25 digits."
				end,
				Callback = function(value)
					if value == "" or value:match("^%d+$") then
						set("Discord UserID", value)
					else
						notify("User ID must contain digits.")
					end
				end,
			})
			for _, key in ipairs({ "Ping User", "Ping On Secret Drop", "Ping On Defeat" }) do
				option(web, key)
			end
			button(web, "Test Webhook", function()
				webhook(true)
				win:Notify({ Title = "Webhook", Content = "Test webhook sent.", Kind = "success" })
			end)
			local appearance = section("Config", "Appearance"):AddCard({
				Id = "appearance",
				Title = "Appearance",
				Description = "Theme, motion and interface size.",
				Icon = "paint-brush",
				Collapsible = true,
				DefaultExpanded = true,
			})
			appearance:AddDropdown({
				Id = "theme",
				Title = "Theme",
				Options = { "Dark", "Light" },
				Default = cfg.Theme,
				Callback = function(value)
					win:SetTheme(value)
					set("Theme", value)
				end,
			})
			option(appearance, "Auto Hide UI On Execute")
			appearance:AddToggle({
				Id = "reduced-motion",
				Title = "Reduce motion",
				Default = cfg["Reduce Motion"] == true,
				Callback = function(on)
					win:SetReducedMotion(on)
					set("Reduce Motion", on)
				end,
			})
			appearance:AddSlider({
				Id = "ui-scale",
				Title = "Interface size",
				Min = 0.8,
				Max = 1.2,
				Step = 0.05,
				Default = cfg["UI Scale"],
				Callback = function(value)
					win:SetScale(value)
					set("UI Scale", value)
				end,
			})
			win:SetTheme(cfg.Theme)
			win:SetReducedMotion(cfg["Reduce Motion"] == true)
			win:SetScale(cfg["UI Scale"])
			local keys = section("Config", "Shortcuts"):AddCard({
				Id = "shortcuts",
				Title = "Window controls",
				Description = "Ctrl+K opens search.",
				Icon = "keyboard",
				Collapsible = true,
				DefaultExpanded = true,
			})
			local ok, key = pcall(function()
				return Enum.KeyCode[cfg["Hide Key"]]
			end)
			if not ok or not key then
				key = Enum.KeyCode.U
			end
			win:SetToggleKey(key)
			keys:AddKeybind({
				Title = "Menu Key",
				Default = key,
				Callback = function(value)
					win:SetToggleKey(value)
					set("Hide Key", value.Name)
				end,
			})
			keys:AddToggle({
				Title = "Large Window",
				Default = cfg["Large Window"] == true,
				Callback = function(on)
					win:SetMaximized(on)
					set("Large Window", on)
				end,
			})
			if cfg["Large Window"] then
				win:SetMaximized(true)
			end
			local data = section("Config", "Data"):AddCard({
				Id = "configuration",
				Title = "Configuration",
				Description = "Settings save automatically for this account.",
				Icon = "floppy-disk",
				Collapsible = true,
			})
			button(data, "Stop All Automation", stopAll, "Destructive")
			button(data, "Save Settings", function()
				assert(saveCfg(), "Settings could not be saved.")
				win:Notify({ Title = "Settings", Content = "Settings saved.", Kind = "success" })
			end, "Primary")
			button(data, "Unload bocchi reworked.", function()
				unload()
			end, "Destructive")
			do
				local card = section("Config", "Profiles"):AddCard({
					Id = "config-profiles",
					Title = "Configurations",
					Icon = "folder",
				})
				local name = card:AddInput({
					Title = "Config Name",
					Default = "",
					Placeholder = "New config name",
				})
				local pick, sharePick
				local private = {
					["Discord Url"] = true,
					["Discord UserID"] = true,
					["Result Webhook"] = true,
					["Auto Execute"] = true,
				}
				function profiles.validate(value, shared)
					assert(type(value) == "table", "Config must contain a JSON object.")
					local out, count = {}, 0
					local function scan(v, depth)
						count += 1
						assert(count <= 20000 and depth <= 8, "Config is too large.")
						if type(v) == "table" then
							for k, child in pairs(v) do
								assert(
									type(k) == "string" or (finite(k) and k >= 1 and k % 1 == 0),
									"Invalid config key."
								)
								scan(child, depth + 1)
							end
						else
							assert(
								type(v) == "boolean" or finite(v) or (type(v) == "string" and #v <= 8192),
								"Invalid config value."
							)
						end
					end
					scan(value, 0)
					for key, v in pairs(value) do
						assert(
							type(key) == "string"
								and (
									key == "AutoPlayEditor" and type(v) == "table"
									or cfg[key] ~= nil and type(v) == type(cfg[key])
								),
							"Unknown or invalid setting: " .. tostring(key)
						)
						if not shared or not private[key] then
							out[key] = v
						end
					end
					if out.AutoPlayEditor then
						out.AutoPlayEditor = UI.UnitSettings.normalizeState(out.AutoPlayEditor)
					end
					for map, pos in pairs(out.AutoPlacePositions or {}) do
						assert(type(map) == "string" and type(pos) == "table", "Invalid map positions.")
						for key, cf in pairs(pos) do
							assert(
								type(key) == "string" and (key == "Center" or key:match("^Unit[1-6]$")),
								"Invalid position slot."
							)
							frame(cf)
						end
					end
					for key, bounds in pairs({
						AutoPlacesCap = { 0, 6 },
						AutoUpgradesCap = { 0, 15 },
						AutoPlaceWaves = { 1, 100000 },
						AutoUpgradeWaves = { 1, 100000 },
					}) do
						for slot, cap in pairs(out[key] or {}) do
							assert(
								type(slot) == "string"
									and slot:match("^[1-6]$")
									and finite(cap)
									and cap % 1 == 0
									and cap >= bounds[1]
									and cap <= bounds[2],
								"Invalid unit slot setting."
							)
						end
					end
					for group, maps in pairs(out["Selected Macro Map"] or {}) do
						assert(
							has({ "Main", "Tower", "Raid", "Portal", "Other" }, group) and type(maps) == "table",
							"Invalid macro map group."
						)
						for map, macro in pairs(maps) do
							assert(type(map) == "string" and (macro == "" or valid(macro)), "Invalid macro map.")
						end
					end
					for key, list in pairs(out) do
						if
							type(list) == "table"
							and key ~= "AutoPlacePositions"
							and key ~= "AutoPlacesCap"
							and key ~= "AutoPlaceWaves"
							and key ~= "AutoUpgradeWaves"
							and key ~= "AutoUpgradesCap"
							and key ~= "Selected Macro Map"
							and key ~= "AutoPlayEditor"
						then
							local n = 0
							for i, v in pairs(list) do
								assert(
									finite(i) and i % 1 == 0 and i >= 1 and i <= #list and type(v) == "string",
									"Invalid list: " .. key
								)
								n += 1
							end
							assert(n == #list, "Invalid list: " .. key)
						end
					end
					return out
				end
				function profiles.refresh(value)
					local list = { "Default" }
					for _, file in ipairs(listfiles(profiles.dir)) do
						local value = file:match("([^/\\]+)%.json$")
						local relative = file:gsub("\\", "/"):match("/Configs/" .. profiles.mode .. "/([^/]+)$")
						if
							relative
							and valid(value)
							and value ~= "Default"
							and file:gsub("\\", "/") ~= profiles.default
							and not isfolder(file)
						then
							list[#list + 1] = value
						end
					end
					table.sort(list)
					lock = true
					pick:SetOptions(list, true)
					pick:SetValue(value or (has(list, pick:GetValue()) and pick:GetValue()) or "Default")
					if sharePick then
						sharePick:SetOptions(list, true)
						sharePick:SetValue(has(list, sharePick:GetValue()) and sharePick:GetValue() or "Default")
					end
					lock = false
				end
				function profiles.select(value)
					local path = profiles.path(value)
					writefile(profiles.index, HttpService:JSONEncode({ Mode = profiles.mode, Name = value }))
					local saved = HttpService:JSONDecode(readfile(profiles.index))
					assert(
						type(saved) == "table" and saved.Mode == profiles.mode and saved.Name == value,
						"Config selection could not be saved."
					)
					profiles.name, profiles.activeMode, cfgPath = value, profiles.mode, path
				end
				function profiles.load(value)
					local file = profiles.path(value)
					local fresh = value == "Default" and not isfile(file)
					if not fresh then
						profiles.validate(settings(HttpService:JSONDecode(readfile(file))))
					end
					local autoFile = autoPlayStorage.path(file)
					if isfile(autoFile) then
						autoPlayStorage.read(autoFile)
					end
					assert(not mode and not draft, "Stop the macro and save its recording before loading a config.")
					if file ~= cfgPath then
						assert(saveCfg(), "Current config could not be saved.")
					end
					if fresh then
						transfer.write(file, HttpService:JSONEncode({}))
					end
					if gameplayFlush then
						gameplayFlush()
					end
					profiles.select(value)
					profiles.reloading = true
					unload()
					task.spawn(boot)
				end
				function profiles.create(value, settings)
					local file = profiles.path(value)
					if settings == cfg and gameplayFlush then
						gameplayFlush()
					end
					transfer.write(file, HttpService:JSONEncode(mainSettings(settings)))
					if settings == cfg and gameplaySave then
						local ok, err = pcall(gameplaySave, file)
						if not ok then
							pcall(delfile, file)
							error(err, 0)
						end
					end
				end
				card:AddParagraph({
					Content = "Copy JSON files into the folder below, then Refresh Configs. Load Config applies your selection.",
				})
				local folder = card:AddLabel({ Title = "Config folder", Value = profiles.dir })
				card:AddDropdown({
					Title = "Config Gamemode",
					Options = profiles.modes,
					Default = profiles.mode,
					Callback = function(value)
						if lock or dead then
							return
						end
						check(function()
							local dir = profiles.folder(value)
							profiles.mode, profiles.dir = value, dir
							profiles.default = profiles.path("Default")
							folder:SetValue(dir)
							profiles.refresh("Default")
						end)
					end,
				})
				pick = card:AddDropdown({
					Title = "Selected Config",
					Options = { profiles.name },
					Default = profiles.name,
				})
				button(card, "Load Config", function()
					profiles.load(pick:GetValue())
				end)
				button(card, "Save As", function()
					local value = name:GetValue()
					profiles.create(value, cfg)
					profiles.select(value)
					profiles.refresh(value)
				end)
				button(card, "Rename Config", function()
					assert(profiles.mode == profiles.activeMode, "Choose the active config gamemode before renaming.")
					assert(profiles.name ~= "Default", "Use Save As to name the default config.")
					local old, value = cfgPath, name:GetValue()
					profiles.create(value, cfg)
					profiles.select(value)
					check(function()
						delfile(old)
						local autoFile = autoPlayStorage.path(old)
						if isfile(autoFile) then
							delfile(autoFile)
						end
					end)
					profiles.refresh(value)
				end)
				button(card, "Refresh Configs", profiles.refresh)
				local share = section("Config", "Sharing"):AddCard({
					Id = "config-sharing",
					Title = "Sharing",
					Icon = "two-arrows-loop-clockwise",
				})
				local importLink = share:AddInput({
					Title = "Config Discord Link",
					Default = "",
					Placeholder = "https://cdn.discordapp.com/attachments/.../config.json",
				})
				button(share, "Import Config", function()
					assert(ready, "Executor file functions unavailable.")
					local value = name:GetValue()
					assert(value == "" or valid(value), "Enter a valid config name.")
					local gamemode = profiles.mode
					local text, filename = cdnFetch(importLink:GetValue())
					if value == "" then
						value = filename
					end
					if value == "Default" or value == "Settings_" .. LP.Name then
						value ..= " Import"
					end
					assert(valid(value), "Enter a valid config name.")
					local data = profiles.validate(settings(HttpService:JSONDecode(text)), true)
					value = transfer.name(profiles.folder(gamemode), value)
					local file = profiles.path(value, gamemode)
					transfer.write(file, HttpService:JSONEncode(data))
					if profiles.mode == gamemode then
						profiles.refresh(value)
					end
					win:Notify({
						Title = "Configuration",
						Content = "Imported " .. file .. ". Use Load Config to apply.",
						Kind = "success",
					})
				end)
				sharePick = share:AddDropdown({
					Title = "Config to Send",
					Options = { profiles.name },
					Default = profiles.name,
					Searchable = true,
				})
				local function export(value)
					local name = profiles.name == "Default" and "Bocchi Config" or profiles.name
					local data = cfg
					if value then
						local file = profiles.path(value)
						name = file:match("([^/\\]+)%.json$")
						data = settings(HttpService:JSONDecode(readfile(file)))
					end
					assert(valid(name), "Enter a valid config name.")
					return name,
						HttpService:JSONEncode({
							Format = "bocchi reworked.config",
							Version = 1,
							Gamemode = value and profiles.mode or profiles.activeMode,
							Settings = mainSettings(profiles.validate(data, true)),
						})
				end
				button(share, "Export Config", function()
					local name, text = export()
					transfer.export(name, text, profiles.activeMode)
				end)
				button(share, "Send Config", function()
					local name, text = export(sharePick:GetValue())
					local file = name .. ".json"
					local boundary = "BocchiConfig" .. HttpService:GenerateGUID(false)
					local payload = HttpService:JSONEncode({
						username = "bocchi reworked.",
						allowed_mentions = { parse = {} },
						attachments = { { id = 0, filename = file } },
					})
					local body = table.concat({
						"--" .. boundary,
						'Content-Disposition: form-data; name="payload_json"',
						"Content-Type: application/json",
						"",
						payload,
						"--" .. boundary,
						'Content-Disposition: form-data; name="files[0]"; filename="' .. file .. '"',
						"Content-Type: application/json",
						"",
						text,
						"--" .. boundary .. "--",
						"",
					}, "\r\n")
					postWebhook(body, "multipart/form-data; boundary=" .. boundary)
					if not dead then
						win:Notify({
							Title = "Sharing",
							Content = "Sent " .. file .. " to Discord.",
							Kind = "success",
						})
					end
				end)
				if ready then
					check(profiles.refresh)
				end
			end
			do
				local queued = false
				local function api()
					local send = queue_on_teleport
						or queueonteleport
						or (syn and syn.queue_on_teleport)
						or (fluxus and fluxus.queue_on_teleport)
					assert(type(send) == "function", "Executor queue_on_teleport unavailable.")
					return send
				end
				toggle(utilities, "Auto Execute", nil, function(on)
					if on then
						api()
					end
				end, "Run again after teleport.", "play")
				if LP.OnTeleport then
					table.insert(
						hooks,
						LP.OnTeleport:Connect(function(state)
							if state == Enum.TeleportState.Failed then
								queued = false
								return
							end
							if
								queued
								or not enabled("Auto Execute")
								or (state ~= Enum.TeleportState.Started and state ~= Enum.TeleportState.InProgress)
							then
								return
							end
							check(function()
								if ready then
									assert(saveCfg(), "Config could not be saved before teleport.")
								end
								api()(
									'loadstring(game:HttpGet("https://raw.githubusercontent.com/Bocchi-World/Bocchi-Main/refs/heads/main/main.lua"))()'
								)
								queued = true
							end)
						end)
					)
				end
			end

			updateData = function()
				lock = true
				modes.matchMaps()
				roll.refresh()
				local world = selectedWorld()
				if world then
					cfg.StoryInf_World = world.name .. (world.legend_stage and " [Legend]" or "")
				end
				local worldNames, challengeWorlds, rewards, capsules, skinNames, skillNames = {}, {}, {}, {}, {}, {}
				local abilityOptions, knownAbility = {}, {}
				local dungeonMaps = table.clone(gameMapNames)
				for _, row in pairs(D.maps or {}) do
					if type(row.name) == "string" and row.name ~= "" and not table.find(dungeonMaps, row.name) then
						table.insert(dungeonMaps, row.name)
					end
				end
				local macroMapsChanged = false
				for _, name in ipairs(dungeonMaps) do
					for _, list in pairs(mapList) do
						if not table.find(list, name) then
							table.insert(list, name)
							if list == mapList[group] then macroMapsChanged = true end
						end
					end
				end
				table.sort(dungeonMaps)
				if macroMapsChanged then mapPick:SetOptions(mapList[group], true) end
				for _, world in pairs(D.worlds) do
					if world.name and (world.infinite or world.legend_stage or world.levels) then
						table.insert(worldNames, world.name .. (world.legend_stage and " [Legend]" or ""))
					end
				end
				local okOrder, order = pcall(function() return require(RS.src.Data.WorldLevelOrder).WORLD_ORDER end)
				if okOrder and type(order) == "table" then
					for _, id in ipairs(order) do
						local story = D.worlds[id]
						if type(story) == "table" and type(story.name) == "string" and story.name ~= ""
							and not story.raid_world and not story.legend_stage and not has(challengeWorlds, story.name) then
							challengeWorlds[#challengeWorlds + 1] = story.name
						end
					end
				end
				for _, row in pairs(D.rewards) do
					if row.name and not has(rewards, row.name) then
						table.insert(rewards, row.name)
					end
				end
				local okSigns, signs = pcall(scanSigns)
				local current = okSigns and signs and signs.challenge and rewardName(signs.challenge.reward)
				if current and current ~= "" and not has(rewards, current) then
					rewards[#rewards + 1] = current
				end
				for id, row in pairs(D.items) do
					if type(id) == "string" and id:lower():find("capsule", 1, true) and row.name then
						table.insert(capsules, row.name)
					end
				end
				local seen = {}
				for id in pairs(D.items) do
					local name = skin({ item_id = id })
					if name and not seen[name] then
						table.insert(skinNames, name)
						seen[name] = true
					end
				end
				for _, id in ipairs({
					"jotaro",
					"eren_final",
					"ainz_evolved",
					"kisuke_evolved",
					"yamamoto_evolved",
					"dio_heaven",
					"aki_evolved",
					"law_2_evolved",
					"brook_evolved",
					"gojo_evolved",
					"pucci_heaven",
					"jotaro_p6_evolved",
					"homura_evolved",
					"megumin_evolved",
					"megumi2_evolved",
					"diavolo",
					"armin",
				}) do
					if units[id] then
						knownAbility[id] = true
						table.insert(skillNames, label(id))
					end
				end
				for id, row in pairs(units) do
					if row.active_attack and not has(skillNames, label(id)) then
						table.insert(skillNames, label(id))
					end
					local active = knownAbility[id] or (type(row.active_attack) == "string" and row.active_attack ~= "" and row.active_attack ~= "nil")
					if not active and type(row.upgrade) == "table" then
						for _, upgrade in pairs(row.upgrade) do
							if type(upgrade) == "table" and type(upgrade.active_attack) == "string"
								and upgrade.active_attack ~= "" and upgrade.active_attack ~= "nil" then active = true break end
						end
					end
					if active and type(row.name) == "string" and row.name ~= ""
						and id ~= "erwin" and id ~= "wendy" and id ~= "leafa_evolved"
						and id ~= "femto_egg" and not tostring(id):match("^rukia_bankai") then
						abilityOptions[#abilityOptions + 1] = { Value = id, Label = row.name }
					end
				end
				table.sort(abilityOptions, function(a, b) return a.Label:lower() < b.Label:lower() end)
				for _, list in ipairs({ worldNames, challengeWorlds, rewards, capsules, skinNames, skillNames }) do
					table.sort(list)
				end
				refreshPick("StoryInf_World", worldNames)
				refreshPick("Dungeon Ignore Maps", dungeonMaps)
				if okOrder and type(order) == "table" then refreshPick("Challenge_IgnoreWorlds", challengeWorlds) end
				refreshPick("StoryInf_Level", stages())
				refreshPick("Challenge_IgnoreRewards", rewards)
				refreshPick("Ignored Capsules", capsules)
				refreshPick("Delete Skin Rarities", skinNames)
				refreshPick("AutoSkillUnits", skillNames)
				refreshPick("Ability Units", abilityOptions)
				do
					local options = {}
					local ok, items = pcall(function() return require(RS.src.Data.ItemsForSale) end)
					if ok and type(items) == "table" then
						for id, item in pairs(items) do
							if type(id) == "string" and type(item) == "table" and not item.associated_devproduct
								and (type(item.gem_cost) == "number" or type(item.gold_cost) == "number") then
								options[#options + 1] = { Value = id, Label = label(id) }
							end
						end
						table.sort(options, function(a, b) return a.Label:lower() < b.Label:lower() end)
						refreshPick("Merchant Items", options)
					end
				end
				lock = false
				refreshPortals()
			end

			local function loop(name, seconds, fn)
				task.spawn(function()
					while not dead do
						pcall(restoreUI)
						local ok, err = pcall(fn)
						pcall(restoreUI)
						if not ok and not dead then
							if name == "Modes" then
								pcall(modes.fail)
							end
							if name ~= "Modes" and (not errors[name] or os.clock() - errors[name] >= 15) then
								errors[name] = os.clock()
								notify(name .. ": " .. tostring(err))
							end
						end
						if not pause(seconds) then
							return
						end
					end
				end)
			end
			if LP.Idled then
				table.insert(
					hooks,
					LP.Idled:Connect(function()
						if dead or not cfg["Anti AFK"] or not workspace.CurrentCamera then
							return
						end
						local vu = service("VirtualUser")
						local cf = workspace.CurrentCamera.CFrame
						vu:Button2Down(Vector2.new(0, 0), cf)
						task.wait(1)
						vu:Button2Up(Vector2.new(0, 0), cf)
					end)
				)
			end
			local cap = setfpscap or setfpsmax
			if cap then
				check(function()
					cap(240)
				end)
			end
			local function setupSummer()
				local weather = {
					meteor_shower = "Starfall",
					clear = "Clear",
					rain = "Rainy",
					windy = "Windy",
					snow = "Blizzard",
					sandstorm = "Sandstorm",
					mana = "Magical",
					underwater = "Flooded",
					downpour = "Stormy",
					fire = "Inferno",
				}
				summer.weatherNames = weather
				function summer.visible(obj)
					if not obj or not obj.Parent then
						return false
					end
					repeat
						if
							obj:IsA("Configuration")
							or (obj:IsA("GuiObject") and not obj.Visible)
							or (obj:IsA("ScreenGui") and not obj.Enabled)
						then
							return false
						end
						obj = obj.Parent
					until not obj
					return true
				end
				function summer.activate(obj)
					assert(
						not dead and summer.visible(obj) and obj:IsA("GuiButton") and obj.Active,
						"Game button is unavailable."
					)
					assert(type(getconnections) == "function", "This executor needs getconnections for game controls.")
					for _, signal in ipairs({ obj.Activated, obj.MouseButton1Click }) do
						for _, con in ipairs(getconnections(signal)) do
							if con.Enabled ~= false and type(con.Function) == "function" then
								con.Function()
								return
							end
						end
					end
					error("Game button has no callable handler. Use the game's button directly.")
				end
				function summer.capture(duration, options)
					assert(not dead, "bocchi reworked. is unloaded.")
					local out = {}
					local newCards = false
					local untilAt = os.clock() + (finite(duration) and math.clamp(duration, 1, 120) or 15)
					for index, option in pairs(type(options) == "table" and options or {}) do
						if type(option) ~= "table" then
							continue
						end
						local slot = tonumber(option.index or index)
						if not finite(slot) or slot % 1 ~= 0 or slot < 1 or slot > 3 then
							continue
						end
						local title = tostring(option and option.title or "")
						local displayScore = tonumber(option and option.displayScore) or 0
						if title ~= "" then
							local card = table.clone(option)
							card.title, card.index = title, slot
							local fallbackEffects = summer.cardEffects[CardPriority.normalizeTitle(title)]
							if fallbackEffects and (type(card.effects) ~= "table" or not next(card.effects)
								or type(select(2, next(card.effects))) ~= "table") then
								card.effects = fallbackEffects
							end
							out[#out + 1] = card
							local known = false
							local normalized = CardPriority.normalizeTitle(title)
							for _, existing in ipairs(summer.allCards) do
								if CardPriority.normalizeTitle(existing) == normalized then known = true break end
							end
							if not known then
								summer.cardKind[title] = displayScore > 0 and "Buff"
									or (displayScore < 0 and "Debuff" or "")
								summer.allCards[#summer.allCards + 1] = title
								newCards = true
							end
						end
					end
					if newCards and summer.rebuildCardPriority then summer.rebuildCardPriority() end
					table.sort(out, function(a, b)
						return a.index < b.index
					end)
					summer.offer = { options = out, untilAt = untilAt }
				end
				function summer.rank(list, name)
					return CardPriority.rank(list, name)
				end
				function summer.cardScore(card)
					local rank = summer.rank(cfg["Summer Card Priority"], card.title)
					local weatherRank = 0
					if card.displayScore and card.displayScore ~= 0 then
						for w, name in pairs(weather) do
							if card.title:lower():find(w, 1, true) then
								weatherRank = summer.rank(cfg["Summer Weather Priority"], name)
								break
							end
						end
					end
					if cfg["Summer Card Strategy"] == "Priority only" and rank == 0 and weatherRank == 0 then
						return nil
					end
					local score = rank * 1000 + weatherRank * 100
					if card.displayScore and card.displayScore ~= 0 then
						local amount = math.abs(card.displayScore)
						score = score + amount * (cfg["Summer Card Strategy"] == "Rewards" and 200 or 8)
						if card.displayScore < 0 then
							score = score - 50
						end
					end
					return score
				end
				function summer.result(card, state)
					if dead then
						return
					end
					summer.offer = nil
					-- Vote-result supplies a snapshot, not a delta: replace it even when the same result arrives twice.
					summer.state = CardPriority.snapshot(state)
				end

				function summer.choose()
					local offer = summer.offer
					if not offer or offer.sent or offer.sending or mode or dead or os.clock() >= offer.untilAt or not enabled("Auto Summer Cards") then return end
					if summer.cardPriorityCtrl then cfg["Summer Card Priority"] = summer.cardPriorityCtrl:GetOrder() end
					local best, bestRank
					for _, card in ipairs(offer.options) do
						local rank = summer.rank(cfg["Summer Card Priority"], card.title)
						if rank ~= nil and (not best or rank > bestRank or rank == bestRank and card.index < best.index) then
							best, bestRank = card, rank
						end
					end
					if not best then return end
					offer.sending = true
					summer.lastVote = best.title
					local ok, err = pcall(remote, "select_roguelike_option", tostring(best.index))
					offer.sending = false
					if not ok then error(err, 0) end
					if summer.offer == offer then offer.sent = true end
				end
				function summer.resetRun()
					summer.offer, summer.replayPending, summer.state, summer.lastVote = nil, nil, nil, nil
					summer._busy = nil
					summer.teamSwitchDone, summer.teamSwitchRetry = nil, nil
				end
				local endpoints = RS:FindFirstChild("endpoints")
				local events = endpoints and endpoints:FindFirstChild("server_to_client")
				for name, fn in pairs({
					show_roguelike_options = summer.capture,
					show_roguelike_vote_result = summer.result,
					replay_started = function()
						if dead then
							return
						end
						summer.resetRun()
						resetMacroForNextMatch(false)
						levelData = nil
						autoPlay.version += 1
						autoPlay.timers, autoPlay.attempts, autoPlay.upgradeAttempts = {}, {}, {}
						if mode then
							pcall(stop, "Match restarted", true)
						end
					end,
				}) do
					local event = events and events:FindFirstChild(name)
					if event and event:IsA("RemoteEvent") then
						hooks[#hooks + 1] = event.OnClientEvent:Connect(fn)
					end
				end
			end

			function summer.lowLevelLeave()
				if not enabled("Summer Leave Low Level") or lobby() then return end
				local ok, data = pcall(level)
				if not ok or type(data) ~= "table" or data.id ~= "summer2_event" then return end
				if val(workspace:FindFirstChild("_DATA"), "GameFinished", false) then return end
				local low, minimum = 0, cfg["Summer Minimum Level"]
				for _, player in ipairs(Players:GetPlayers()) do
					if player == LP then continue end
					local character = player.Character
					local head = character and character:FindFirstChild("Head")
					local overhead = head and head:FindFirstChild("_overhead")
					local frame = overhead and overhead:FindFirstChild("Frame")
					local levelFrame = frame and frame:FindFirstChild("Level_Frame")
					local label = levelFrame and levelFrame:FindFirstChild("Level")
					local text = label and label:IsA("TextLabel") and label.Text
					local playerLevel = text and tonumber((text:gsub("<[^>]->", "")):match("%d+"))
					-- Missing nameplates are unknown and do not count as low level.
					if playerLevel and playerLevel < minimum then low += 1 end
				end
				if low >= tonumber(cfg["Summer Low Level Count"]) and os.clock() >= (summer.lowLevelLeaveAt or 0) then
					summer.lowLevelLeaveAt = os.clock() + 10
					goLobby()
				end
			end

			function summer.tick()
				if enabled("Auto Summer Bingo") and not summer.bingoScanning
					and os.clock() >= (summer.bingoAt or 0) then
					summer.bingoAt, summer.bingoScanning = os.clock() + 15, true
					task.spawn(function()
						pcall(function()
							local gui = LP:FindFirstChild("PlayerGui")
							for i, obj in ipairs(gui and gui:GetDescendants() or {}) do
								if dead or not enabled("Auto Summer Bingo") then break end
								if i % 100 == 0 then task.wait() end
								if (obj.Name == "Claim" or obj.Name == "Redeem") and obj:IsA("GuiButton")
									and obj.Active and summer.visible(obj)
									and not summer.visible(obj:FindFirstChild("Locked"))
									and not summer.visible(obj:FindFirstChild("Claimed")) then
									local parent = obj.Parent
									while parent and parent ~= gui do
										local name = parent.Name:lower()
										if name:find("bingo", 1, true) or name:find("mapboard", 1, true)
											or name:find("map_board", 1, true) then
											summer.activate(obj)
											return
										end
										parent = parent.Parent
									end
								end
							end
						end)
						summer.bingoScanning = false
					end)
				end
				-- Team selection works independently of both card-voting toggles.
				if not summer.teamSwitchDone and not mode and not lobby()
					and not val(workspace:FindFirstChild("_DATA"), "GameFinished", false)
					and os.clock() >= (summer.teamSwitchRetry or 0) then
					local configured = false
					for team = 1, 6 do
						if #cfg["Summer Team " .. team] > 0 then configured = true break end
					end
					if configured then
						local data = level()
						if data.id == "summer2_event" or data.portal_group == "summer2"
							or data.roguelike_multiplier_resource == "SummerPearls" then
							local id = data._weather or data.weather
							local name = type(id) == "string" and (summer.weatherNames[id:lower()] or id) or nil
							if name then
								for team = 1, 6 do
									if table.find(cfg["Summer Team " .. team], name) then
										summer.teamSwitchRetry = os.clock() + 10
										local ok, err = pcall(function() autoPlay:EquipTeam(tostring(team)) end)
										if ok then summer.teamSwitchDone = true
										else warn("[Bocchi] Weather team switch failed: " .. tostring(err)) end
										break
									end
								end
							end
						end
					end
				end
				if
					not enabled("Auto Summer Cards")
					or mode
					or lobby()
					or val(workspace:FindFirstChild("_DATA"), "GameFinished", false)
				then
					return
				end
				local data = level()
				if
					not data
					or (
						data.id ~= "summer2_event"
						and data.portal_group ~= "summer2"
						and data.roguelike_multiplier_resource ~= "SummerPearls"
					)
				then
					return
				end
				local rogue = workspace:FindFirstChild("_DATA")
				rogue = rogue and rogue:FindFirstChild("Roguelike")
				local waiting = rogue and rogue:FindFirstChild("WaitingForRoguelikeChoice")
				if waiting and not waiting.Value then
					summer.offer = nil
					return
				end
				if summer.offer then
					summer.choose()
					return
				end
				local gui = LP:FindFirstChild("PlayerGui")
				local screen = gui and gui:FindFirstChild("CardSelectRoguelike")
				if not (screen and screen.Enabled) then
					return
				end
				local main = screen:FindFirstChild("main")
				local pick = main and main:FindFirstChild("pick")
				local inner = pick and pick:FindFirstChild("inner")
				local pages = inner and inner:FindFirstChild("PageUI")
				if not pages then
					return
				end
				local rows = {}
				for _, page in ipairs(pages:GetChildren()) do
					local node = page:FindFirstChild("inner")
					node = node and node:FindFirstChild("Main")
					node = node and node:FindFirstChild("InfoFrame")
					node = node and node:FindFirstChild("inner")
					node = node and node:FindFirstChild("Header")
					local title = node and node:FindFirstChild("QuirkTitle")
					if title and title:IsA("TextLabel") then
						rows[#rows + 1] = { title = title.Text, x = page.AbsolutePosition.X }
					end
				end
				table.sort(rows, function(a, b)
					return a.x < b.x
				end)
				if #rows == 0 then
					return
				end
				summer.capture(120, rows)
				summer.choose()
			end

			setupSummer()
			do
				local dataRoot = RS:FindFirstChild("src") and RS.src:FindFirstChild("Data")
				if dataRoot then
					for _, signal in ipairs({ dataRoot.DescendantAdded, dataRoot.DescendantRemoving }) do
						table.insert(hooks, signal:Connect(function(obj)
							if obj:IsA("ModuleScript") then D.dataDirty = true end
						end))
					end
				end
			end

			loop("Summer Low Level Leave", 2, summer.lowLevelLeave)
			loop("Summer", 1, summer.tick)
			do
				local macroFiles, configFiles
				loop("Refresh file lists", 30, function()
					if not ready then return end
					local macros = listfiles(dir)
					table.sort(macros)
					local macroSignature = table.concat(macros, "\n")
					if macroSignature ~= macroFiles and not mode and not draft then
						refresh()
						macroFiles = macroSignature
					end
					if profiles.refresh and profiles.dir then
						local files = listfiles(profiles.dir)
						table.sort(files)
						local signature = profiles.dir .. "\n" .. table.concat(files, "\n")
						if signature ~= configFiles then
							profiles.refresh()
							configFiles = signature
						end
					end
				end)
			end
			loop("Refresh display data", 30, function()
				if not D.ready then return end
				local ok, err = pcall(function()
					if D.dataDirty then
						loadData()
						D.dataDirty = false
					else
						updateData()
					end
					if summer.refreshItems then summer.refreshItems() end
				end)
				lock = false
				if not ok then error(err, 0) end
			end)

			loop("Farm", 1, lobbyTick)
			loop("Webhook", 30, bannerHookTick)
			loop("Summon Banner", 2, modes.summonTick)
			do
				local bought, wasOpen = {}, false
				loop("Travelling Merchant", 15, function()
					if not lobby() then wasOpen = false return end
					local merchant = workspace:FindFirstChild("travelling_merchant")
					local open = merchant and merchant:FindFirstChild("is_open")
					if not open or not open.Value then wasOpen = false return end
					if not wasOpen then table.clear(bought) wasOpen = true end
					if not enabled("Auto Buy Merchant") then return end
					local stand = merchant:FindFirstChild("stand")
					local items = stand and stand:FindFirstChild("items")
					if not items then return end
					for _, item in ipairs(items:GetChildren()) do
						local id = item.Name
						if enabled("Auto Buy Merchant") and not bought[id] and table.find(cfg["Merchant Items"], id) then
							local ok = pcall(remote, "buy_travelling_merchant_item", id, "1")
							if ok then bought[id] = true end
							task.wait(0.5)
						end
					end
				end)
			end
			loop("CheckChallenge", 1, challengeTick)
			loop("Modes", 0.5, modes.tick)
			loop("Find Match", 0.5, modes.find)
			loop("Combat", 0.5, combatTick)
			loop("Auto Play", 0.5, function()
				autoPlay:SetPaused(mode ~= nil or (modeMenu and modeMenu()) == true)
				if autoPlay.teamBusy then
					return
				end
				if os.clock() >= (autoPlay.refreshAt or 0) then
					autoPlay.refreshAt = os.clock() + 2
					autoPlay:RefreshCatalog()
				end
				autoPlay:Tick()
			end)
			loop("Walk Random", 1, modes.walkRandom)
			loop("Dupe Vegito", 0.5, dupeTick)
			loop("Skills", 0.25, skillsTick)
			loop("Inventory", 2, inventoryTick)
			loop("Traits", 0.5, roll.tick)
			loop("Quests", 5, questTick)
			loop("Match", 1, matchTick)
			loop("Vote Lose", 1, modes.voteLoseTick)
			-- GameFinished is polled each Match tick; the old one-shot listener never
			-- connected when _DATA was missing in the first 30s (e.g. script started in lobby).
			loop("Macro", 0.2, playTick)
			loop("Display", 0.5, function()
				visualsTick()
				if inv then
					counters()
				end
			end)
			task.spawn(function()
				while not dead do
					local ok, err = pcall(loadData)
					if ok then
						if not dead and not win.destroyed then
							win._dataLoaded = true
							win.finishBocchiLoading()
						end
						break
					end
					D.ready = false
					win._dataRetry = true
					if win._loadingDetail then win._loadingDetail.Text = "Waiting for game data, retrying..." end
					warn("[bocchi reworked] Game data not ready: " .. tostring(err))
					if not pause(5) then break end
				end
			end)
			clean = function()
				if autoPlay then
					autoPlay:Destroy()
				end
				epoch += 1
				hideUnits.set(false)
				boost.set(false)
				modes.reset()
				if autoPlay then
					autoPlay:CancelPick()
				end
				for _, con in ipairs(hooks) do
					con:Disconnect()
				end
				for _, entry in pairs(tracked) do
					if entry.gui then
						entry.gui:Destroy()
					end
				end
				for key in pairs(saved) do
					restore(key)
				end
			end
		end
		unload = function()
			if dead then
				return
			end
			pcall(stop, nil, true)
			if gameplayFlush and not profiles.reloading and not win.destroyed then
				pcall(gameplayFlush)
			end
			dead = true
			if clean then
				pcall(clean)
			end
			win:Destroy()
			for _, store in ipairs({ shared, _G }) do
				if store.__BocchiReworkedCleanup == unload then
					store.__BocchiReworkedCleanup = nil
				end
				if store.__BocchiReworkedWindow == win then
					store.__BocchiReworkedWindow = nil
				end
			end
		end
		shared.__BocchiReworkedCleanup = unload
		_G.__BocchiReworkedCleanup = unload
		win.cleanup:add(unload)
		setup()
		win.ctx.buildYield = nil
		win:SelectPage("Dashboard")
		if ready then
			check(refresh)
			mapLink()
		end
		if draft then
			status:SetValue("Unsaved recording - Retry Save")
		end
		if cfg["Auto Hide UI On Execute"] then
			win:Hide()
		end
		win._uiLoaded = true
		if win._loadingDetail and not win._dataRetry then win._loadingDetail.Text = "Preparing game data" end
		win.finishBocchiLoading()
		return win
	end
	return function(parent)
		local ok, result = xpcall(function()
			return boot(parent)
		end, function(err)
			local message = tostring(err)
			if debug and type(debug.traceback) == "function" then
				local traced, trace = pcall(debug.traceback, message, 2)
				if traced then return trace end
			end
			return message
		end)
		if not ok then
			local win = shared.__BocchiReworkedRun == runId and shared.__BocchiReworkedWindow
			local stage = win and win._buildStage or "before UI creation"
			if win and win.ctx then win.ctx.buildYield = nil end
			if win and win._loadingOverlay then
				win._loadingOverlay:Destroy()
				win._loadingOverlay, win._loadingDetail = nil, nil
			end
			if win and not win.destroyed then
				pcall(function() win:Notify({ Title = "Loading failed", Content = "Check the console for details.", Kind = "warning" }) end)
			end
			warn("[Bocchi] UI initialization failed at " .. tostring(stage) .. ": " .. tostring(result))
			return nil
		end
		return result
	end
end)()
return MacUI()
