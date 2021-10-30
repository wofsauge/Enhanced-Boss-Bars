HPBars = RegisterMod("Enhanced Boss bars", 1)
HPBars.Version = 1.0
HPBars.iconPath = "gfx/ui/bosshp_icons/"
HPBars.barPath = "gfx/ui/bosshp_bars/"

require("config")
HPBars.Config = HPBars.UserConfig
require("bossbar_data")
require("mcm")

local game = Game()
HPBars.currentBosses = {}
local currentBossesSorted = {}
local badload = false

local enableDebug = false

function HPBars:getScreenSize()
	local room = game:GetRoom()
	local pos = room:WorldToScreenPosition(Vector(0, 0)) - room:GetRenderScrollOffset() - game.ScreenShakeOffset

	local rx = pos.X + 60 * 26 / 40
	local ry = pos.Y + 140 * (26 / 40)

	return Vector(rx * 2 + 13 * 26, ry * 2 + 7 * 26)
end

if enableDebug then
	function HPBars:onDebugRender(entityNPC)
		local screenpos = Isaac.WorldToScreen(entityNPC.Position)
		local text = "anm: " .. entityNPC:GetSprite():GetAnimation()
		Isaac.RenderScaledText(text, screenpos.X + 15, screenpos.Y - 7, 0.5, 0.5, 1, 1, 1, 0.5)
		Isaac.RenderScaledText("I1: " .. entityNPC.I1, screenpos.X + 15, screenpos.Y, 0.5, 0.5, 1, 1, 1, 0.5)
		Isaac.RenderScaledText("I2: " .. entityNPC.I2, screenpos.X + 15, screenpos.Y + 7, 0.5, 0.5, 1, 1, 1, 0.5)
		Isaac.RenderScaledText("State: " .. entityNPC.State, screenpos.X + 15, screenpos.Y + 14, 0.5, 0.5, 1, 1, 1, 0.5)
		text = "id: " .. entityNPC.Type .. "." .. entityNPC.Variant .. "." .. entityNPC.SubType
		Isaac.RenderScaledText(text, screenpos.X + 15, screenpos.Y + 21, 0.5, 0.5, 1, 1, 1, 0.5)
		text = entityNPC.HitPoints .. " / " .. entityNPC.MaxHitPoints
		Isaac.RenderScaledText(text, screenpos.X + 15, screenpos.Y + 28, 0.5, 0.5, 1, 1, 1, 0.5)
	end
	HPBars:AddCallback(ModCallbacks.MC_POST_NPC_RENDER, HPBars.onDebugRender)
end

function HPBars:getEntityTypeString(entity)
	if entity == nil then
		return ""
	end
	return entity.Type .. "." .. entity.Variant .. "." .. entity.SubType
end

function HPBars:isTableEqual(table1, table2)
	if table2 == nil then
		return false
	end
	for k, v in pairs(table1) do
		if v ~= table2[k] then
			return false
		end
	end
	return true
end

function HPBars:copyColor(color)
	return Color(color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO)
end

---------------------------------------------------------------------------
-------------------------------Main Logic----------------------------------
function HPBars:evaluateConditionals(bossDefinition, tableEntry)
	if not bossDefinition.conditionalSprites then
		return nil
	end
	for i, conditionalSprite in ipairs(bossDefinition.conditionalSprites) do
		local args = conditionalSprite[3] or {}
		if type(conditionalSprite[1]) == "function" then
			if conditionalSprite[1](tableEntry.entity, args) then
				return conditionalSprite[2]
			end
		elseif HPBars.Conditions[conditionalSprite[1]] then
			if HPBars.Conditions[conditionalSprite[1]](tableEntry.entity, args) then
				return conditionalSprite[2]
			end
		end
	end
end

function HPBars:getBarStyle(barStyle)
	local defaultStyle = HPBars.BarStyles.Default
	local newStyle = type(barStyle) == "table" and barStyle or HPBars.BarStyles[barStyle] or {}
	local combinedStyle = {}
	for k, v in pairs(defaultStyle) do
		combinedStyle[k] = v
	end
	for k, v in pairs(newStyle) do
		combinedStyle[k] = v
	end
	return combinedStyle
end

function HPBars:applyBarStyle(tableEntry, barStyle)
	if not barStyle or not tableEntry then
		return
	end
	local isVertical = HPBars:isVerticalLayout()
	local barAnm2 = isVertical and barStyle.verticalAnm2 or barStyle.barAnm2
	tableEntry.barSprite:Load(barAnm2, true)

	local overlayAnm2 = isVertical and barStyle.verticalOverlayAnm2 or barStyle.overlayAnm2
	if overlayAnm2 then
		tableEntry.barOverlaySprite = Sprite()
		tableEntry.barOverlaySprite:Load(overlayAnm2, true)
		if barStyle.overlaySprite then
			local overlaySprite = isVertical and barStyle.verticalOverlaySprite or barStyle.overlaySprite
			for i = 0, tableEntry.barOverlaySprite:GetLayerCount() - 1 do
				tableEntry.barOverlaySprite:ReplaceSpritesheet(i, overlaySprite)
			end
			tableEntry.barOverlaySprite:LoadGraphics()
		end
	end
	if barStyle.notchAnm2 and barStyle.notchAnm2 ~= "NONE" then
		tableEntry.notchSprite = Sprite()
		tableEntry.notchSprite:Load(barStyle.notchAnm2, true)
		if barStyle.notchSprite then
			for i = 0, tableEntry.notchSprite:GetLayerCount() - 1 do
				tableEntry.notchSprite:ReplaceSpritesheet(i, barStyle.notchSprite)
			end
			tableEntry.notchSprite:LoadGraphics()
		end
	end

	local barSprite = isVertical and barStyle.verticalSprite or barStyle.sprite
	if barStyle.sprite then
		for i = 0, tableEntry.barSprite:GetLayerCount() - 1 do
			tableEntry.barSprite:ReplaceSpritesheet(i, barSprite)
		end
	end
	tableEntry.barSprite:LoadGraphics()
	if barStyle.barAnimationType == "Animated" then
		tableEntry.barSprite:Play(tableEntry.barSprite:GetDefaultAnimation(), true)
	end
	if barStyle.overlayAnimationType == "Animated" then
		tableEntry.barOverlaySprite:Play(tableEntry.barOverlaySprite:GetDefaultAnimation(), true)
	end
	if barStyle.notchAnimationType == "Animated" then
		tableEntry.notchSprite:Play(tableEntry.notchSprite:GetDefaultAnimation(), true)
	end
	tableEntry.barStyle = barStyle
end

function HPBars:updateSprites(tableEntry)
	local bossDefinition = HPBars.BossDefinitions[tableEntry.entity.Type .. "." .. tableEntry.entity.Variant]
	if bossDefinition == nil then
		bossDefinition = HPBars.BossDefinitions["UNDEFINED"]
	end

	local newStyle = HPBars.Config.EnableSpecificBossbars and bossDefinition.barStyle or tableEntry.barStyle
	barStyle = HPBars:getBarStyle(newStyle)
	if not HPBars:isTableEqual(barStyle, tableEntry.currentStyle) then
		HPBars:applyBarStyle(tableEntry, barStyle)
		tableEntry.currentStyle = barStyle
	end

	local iconToLoad =
		HPBars:evaluateConditionals(bossDefinition, tableEntry) or bossDefinition.sprite or barStyle.defaultIcon
	if iconToLoad ~= tableEntry.currentIcon then
		if HPBars.Config.ShowCustomIcons then
			if bossDefinition.iconAnm2 then
				tableEntry.iconSprite:Load(bossDefinition.iconAnm2, true)
			end
			for i = 0, tableEntry.iconSprite:GetLayerCount() - 1 do
				tableEntry.iconSprite:ReplaceSpritesheet(i, iconToLoad)
			end
			tableEntry.iconSprite:LoadGraphics()

			if bossDefinition.iconAnimationType then
				tableEntry.iconSprite:Play(tableEntry.iconSprite:GetDefaultAnimation(), true)
				tableEntry.iconAnimationType = bossDefinition.iconAnimationType
			end
			tableEntry.iconOffset = bossDefinition.offset or tableEntry.iconOffset
		end

		if tableEntry.entityColor then
			tableEntry.iconSprite.Color = tableEntry.entityColor
		end
		tableEntry.ignoreInvincible = bossDefinition.ignoreInvincible
		tableEntry.currentIcon = iconToLoad
	end
	tableEntry.iconSprite:Update()
	tableEntry.barSprite:Update()
	if tableEntry.barOverlaySprite then
		tableEntry.barOverlaySprite:Update()
	end
	if tableEntry.notchSprite then
		tableEntry.notchSprite:Update()
	end
end

function HPBars:evaluateEntityIgnore(entity)
	local entityString = entity.Type .. "." .. entity.Variant
	local ignoreEntry = HPBars.BossIgnoreList[entityString]
	if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
		return true
	end
	if ignoreEntry then
		if type(ignoreEntry) == "function" then
			return ignoreEntry(entity)
		end
		return ignoreEntry
	end
	return false
end

function HPBars:createNewBossBar(entity)
	local barStyle = HPBars:getBarStyle(HPBars.Config["BarStyle"])

	local icon = Sprite()
	icon:Load(HPBars.iconPath .. "bosshp_icon_32px.anm2", true)

	local bossHPsprite = Sprite()
	bossHPsprite:Load(barStyle.barAnm2, true)
	local entityNPC = entity:ToNPC()
	local championColor =
		entityNPC and HPBars.Config.UseChampionColors and
		(entityNPC:GetChampionColorIdx() >= 0 or entityNPC:GetBossColorIdx()) and
		HPBars:copyColor(entity:GetColor()) or
		nil

	local newEntry = {
		entity = entity,
		hp = entity.HitPoints or 0,
		maxHP = entity.MaxHitPoints or 0,
		entityColor = championColor,
		iconSprite = icon,
		iconOffset = Vector(-4, 0),
		iconAnimationType = "HP",
		ignoreInvincible = nil,
		currentIcon = nil,
		barSprite = bossHPsprite,
		barStyle = barStyle,
		barOverlaySprite = nil,
		notchSprite = nil,
		lastHP = entity.HitPoints,
		hitState = "",
		lastStateChangeFrame = 0,
		initialType = HPBars:getEntityTypeString(entity)
	}

	HPBars.currentBosses[GetPtrHash(entity)] = newEntry
	HPBars:updateSprites(newEntry)
end

function HPBars:removeBarEntry(entity)
	HPBars.currentBosses[GetPtrHash(entity)] = nil
end

function HPBars:isInvincible(bossEntry)
	return not bossEntry.ignoreInvincible and bossEntry.entity:IsEnemy() and
		(bossEntry.entity:IsInvincible() or not bossEntry.entity:IsVulnerableEnemy())
end

local lastUpdate = 0
function HPBars:updateRoomEntities()
	if lastUpdate == game:GetFrameCount() then
		return
	end
	for i, entity in ipairs(Isaac.GetRoomEntities()) do
		local entityHash = GetPtrHash(entity)
		local bossEntry = HPBars.currentBosses[entityHash]
		if entity:IsBoss() and not HPBars:evaluateEntityIgnore(entity) or bossEntry then
			if bossEntry == nil then
				HPBars:createNewBossBar(entity)
			else
				bossEntry.lastHP = bossEntry.hp
				bossEntry.hp = entity.HitPoints
				bossEntry.maxHP = entity.MaxHitPoints

				if bossEntry.lastHP > bossEntry.hp then
					bossEntry.lastStateChangeFrame = game:GetFrameCount()
					bossEntry.hitState = "damage"
				elseif bossEntry.lastHP < bossEntry.hp then
					bossEntry.lastStateChangeFrame = game:GetFrameCount()
					bossEntry.hitState = "heal"
				end
				HPBars:updateSprites(bossEntry)
			end
		end
	end
	lastUpdate = game:GetFrameCount()

	if HPBars.MCMLoaded and not HPBars:isMCMVisible() then
		HPBars:removeBarEntry(Isaac.GetPlayer())
	end

	local sortedBosses = {}
	for k, boss in pairs(HPBars.currentBosses) do
		if
			not boss.entity:Exists() or boss.entity:IsDead() or boss.initialType ~= HPBars:getEntityTypeString(boss.entity) or
				HPBars:evaluateEntityIgnore(boss.entity)
		 then
			HPBars.currentBosses[k] = nil
		else
			table.insert(sortedBosses, boss)
		end
	end
	table.sort(
		sortedBosses,
		function(a, b)
			return a.entity.Index < b.entity.Index
		end
	)

	currentBossesSorted = {}
	local visitedBosses = {}
	for i, boss in ipairs(sortedBosses) do
		local bossPtr = GetPtrHash(boss.entity)
		if boss.entity.Parent == nil and not visitedBosses[bossPtr] then
			-- add parent to sorted list
			table.insert(currentBossesSorted, boss)
			visitedBosses[bossPtr] = true
			-- add children to sorted list
			local curChild = boss.entity.Child
			while curChild ~= nil do
				local childPtr = GetPtrHash(curChild)
				if HPBars.currentBosses[childPtr] and not visitedBosses[childPtr] then
					visitedBosses[childPtr] = true
					table.insert(currentBossesSorted, HPBars.currentBosses[childPtr])
				else
					break
				end
				curChild = curChild.Child
			end
		end
	end
	-- add entries that where not handled from the loop aboth
	for k, boss in pairs(HPBars.currentBosses) do
		if not visitedBosses[k] then
			table.insert(currentBossesSorted, boss)
		end
	end
end

function HPBars:getBarPosition(bossCount)
	local screenCenter = HPBars:getScreenSize()
	local barPadding = HPBars.Config.BarPadding
	if HPBars.Config.Position == "Bottom" then
		local barSize = HPBars.barSizes.horizontal[math.min(bossCount, 10)]
		return Vector(
			screenCenter.X / 2 - (bossCount * barSize) / 2 - ((bossCount - 1) * barPadding),
			screenCenter.Y - HPBars.Config.ScreenPadding
		)
	elseif HPBars.Config.Position == "Top" then
		local barSize = HPBars.barSizes.horizontal[math.min(bossCount, 10)]
		return Vector(
			screenCenter.X / 2 - (bossCount * barSize) / 2 - ((bossCount - 1) * barPadding),
			HPBars.Config.ScreenPadding
		)
	elseif HPBars.Config.Position == "Left" then
		local barSize = HPBars.barSizes.vertical[math.min(bossCount, 10)]
		return Vector(
			HPBars.Config.ScreenPadding * 2,
			screenCenter.Y / 2 + (bossCount * barSize) / 2 + ((bossCount - 1) * barPadding)
		)
	else
		local barSize = HPBars.barSizes.vertical[math.min(bossCount, 10)]
		return Vector(
			screenCenter.X - HPBars.Config.ScreenPadding * 2,
			screenCenter.Y / 2 + (bossCount * barSize) / 2 + ((bossCount - 1) * barPadding)
		)
	end
end

function HPBars:isVerticalLayout()
	return HPBars.Config.Position == "Left" or HPBars.Config.Position == "Right"
end

function HPBars:getRowOffset()
	return HPBars.Config.Position == "Left" and Vector(-20, 0) or HPBars.Config.Position == "Right" and Vector(20, 0) or
		HPBars.Config.Position == "Top" and Vector(0, -20) or
		Vector(0, 20)
end

function HPBars:renderInfoText(bossEntry, barPos, barSize)
	if HPBars.Config.InfoText == "None" then
		return
	end

	local text = ""
	if HPBars.Config.InfoText == "Percent" then
		text = math.ceil((bossEntry.hp / bossEntry.maxHP) * 100) .. "%"
	elseif HPBars.Config.InfoText == "HPLeft" then
		text = math.ceil(bossEntry.hp * 10) / 10
	end
	local textSize = Isaac.GetTextWidth(text)
	local transparency = HPBars.Config.TextTransparency
	if HPBars:isVerticalLayout() then
		Isaac.RenderScaledText(text, barPos.X - textSize / 4, barPos.Y - barSize / 2, 0.5, 0.5, 1, 1, 1, transparency)
	else
		Isaac.RenderScaledText(text, barPos.X + barSize / 2 - textSize / 2, barPos.Y - 3, 0.5, 0.5, 1, 1, 1, transparency)
	end
end

function HPBars:renderIcon(bossEntry, barPos, hpbarFill)
	if enableDebug then
		bossEntry.iconSprite.Color = Color(1, 1, 1, 0.5, 0, 0, 0)
	end

	if HPBars.Config.ShowIcons then
		if bossEntry.iconAnimationType == "HP" then
			bossEntry.iconSprite:SetFrame("idle", hpbarFill)
		end
		if HPBars:isVerticalLayout() then
			local flipOffset = Vector(bossEntry.iconOffset.Y, bossEntry.iconOffset.X)
			bossEntry.iconSprite:Render(barPos - flipOffset, Vector.Zero, Vector.Zero)
		else
			bossEntry.iconSprite:Render(barPos + bossEntry.iconOffset + Vector(-3, 0), Vector.Zero, Vector.Zero)
		end
	end
end

function HPBars:renderOverlays(bossEntry, barPos, hpbarFill, barSizePercent)
	local rotation = HPBars:isVerticalLayout() and -90 or 0

	if HPBars.Config.ShowNotches and bossEntry.notchSprite then
		bossEntry.notchSprite.Rotation = rotation
		if bossEntry.barStyle.notchAnimationType == "HP" then
			bossEntry.notchSprite:SetFrame("overlay" .. barSizePercent, hpbarFill)
		else
			bossEntry.notchSprite:SetAnimation("overlay" .. barSizePercent, false)
		end
		bossEntry.notchSprite:Render(barPos, Vector.Zero, Vector.Zero)
	end

	if bossEntry.barOverlaySprite then
		bossEntry.barOverlaySprite.Rotation = rotation
		if bossEntry.barStyle.overlayAnimationType == "HP" then
			bossEntry.barOverlaySprite:SetFrame("overlay" .. barSizePercent, hpbarFill)
		else
			bossEntry.barOverlaySprite:SetAnimation("overlay" .. barSizePercent, false)
		end
		bossEntry.barOverlaySprite:Render(barPos, Vector.Zero, Vector.Zero)
	end
end

function HPBars:handleBadLoad()
	if badload then
		Isaac.RenderText("Enhanced Boss Bars detected a conflicting mod or first installation!", 40, 30, 1, 0.5, 0.5, 1)
		Isaac.RenderText("Please deactivate all other mods that alter the Boss bar sprites and", 40, 40, 1, 0.5, 0.5, 1)
		Isaac.RenderText("Restart your game!", 40, 50, 1, 0.5, 0.5, 1)
		Isaac.RenderText("(This tends to happen when the mod is first installed, a conflicting", 40, 70, 1, 0.5, 0.5, 1)
		Isaac.RenderText("mod is enabled, or when the mod is re-enabled via the mod menu)", 40, 80, 1, 0.5, 0.5, 1)
	end
end

function HPBars:onRender()
	HPBars:handleBadLoad()
	HPBars:updateRoomEntities()
	local currentBossCount = #currentBossesSorted
	if currentBossCount <= 0 then
		return
	end
	local isVertical = HPBars:isVerticalLayout()
	local barSizesTable = isVertical and HPBars.barSizes.vertical or HPBars.barSizes.horizontal
	local rowOffset = HPBars:getRowOffset()
	local barsPerRow = isVertical and HPBars.Config.BarsPerRow - 1 or HPBars.Config.BarsPerRow
	local rowCount = math.ceil(currentBossCount / barsPerRow)
	--handle boss hp bar
	for row = 0, rowCount - 1 do
		local bossesInRow = math.min(currentBossCount - row * barsPerRow, barsPerRow)
		local barSize = barSizesTable[math.min(bossesInRow, barsPerRow, 10)]
		local barPositionStart = HPBars:getBarPosition(bossesInRow) - (rowCount - 1) * rowOffset + row * rowOffset
		local barSizePercent = math.floor(barSize / barSizesTable[1] * 100)

		local bossArrayStart = row * barsPerRow + 1
		for i = bossArrayStart, bossArrayStart + math.min(bossesInRow, barsPerRow) - 1 do
			local boss = currentBossesSorted[i]
			local padding = HPBars.Config.BarPadding * 2
			local slotInRow = i - bossArrayStart
			local barPos = barPositionStart + Vector(slotInRow * (barSize + padding), 0)
			if isVertical then
				barPos = barPositionStart - Vector(0, slotInRow * (barSize + padding))
			end
			local hpbarFill = 100 - math.min(math.ceil((boss.hp / boss.maxHP) * 100), 99)
			-- render bg
			boss.barSprite.Rotation = isVertical and -90 or 0
			if boss.barStyle.barAnimationType == "HP" then
				boss.barSprite:SetFrame("bg" .. barSizePercent, hpbarFill)
			else
				boss.barSprite:SetAnimation("bg" .. barSizePercent, false)
			end
			boss.barSprite:Render(barPos, Vector.Zero, Vector.Zero)
			-- render charge
			if boss.barStyle.barAnimationType == "HP" then
				boss.barSprite:SetFrame("charge" .. barSizePercent, hpbarFill)
			else
				boss.barSprite:SetAnimation("charge" .. barSizePercent, false)
			end

			boss.barStyle.coloringFunction(boss)

			local progress = barSize / 100 * hpbarFill
			boss.barSprite:Render(barPos, Vector.Zero, Vector(1 + progress, 0))
			-- render end deco
			if boss.barStyle.barAnimationType == "HP" then
				boss.barSprite:SetFrame("endDeco", hpbarFill)
			else
				boss.barSprite:SetAnimation("endDeco", false)
			end
			if isVertical then
				boss.barSprite:Render(barPos - Vector(0, barSize - 1 - progress), Vector.Zero, Vector.Zero)
			else
				boss.barSprite:Render(barPos + Vector(barSize - 1 - progress, 0), Vector.Zero, Vector.Zero)
			end
			boss.barSprite.Color = Color(1, 1, 1, 1, 0, 0, 0)

			HPBars:renderOverlays(boss, barPos, hpbarFill, barSizePercent)

			HPBars:renderIcon(boss, barPos, hpbarFill)

			HPBars:renderInfoText(boss, barPos, barSize)
		end
	end
end
HPBars:AddCallback(ModCallbacks.MC_POST_RENDER, HPBars.onRender)

--------------------------------
--------Handle Savadata---------
--------------------------------
function HPBars:evaluateBadLoad()
	local testSprite = Sprite()
	testSprite:Load(HPBars.barPath .. "custom_bosshp.anm2", true)
	testSprite:ReplaceSpritesheet(0, "gfx/ui/ui_bosshealthbar.png")
	testSprite:LoadGraphics()
	testSprite:Play("bg100")

	for x = -10, 10 do
		local qcolor = testSprite:GetTexel(Vector(x, 0), Vector.Zero, 1, 0)
		if qcolor.Red ~= 1 or qcolor.Green ~= 1 or qcolor.Blue ~= 1 or qcolor.Alpha ~= 1 then
			return true
		end
	end
	return false
end

local json = require("json")
function OnGameStart(_, isSave)
	badload = HPBars:evaluateBadLoad()
	HPBars.currentBosses = {}
	currentBossesSorted = {}
	--Loading Moddata--
	if not HPBars:HasData() then
		return
	end
	local savedConfig = json.decode(Isaac.LoadModData(HPBars))

	-- Only copy Saved config entries that exist in the save
	if savedConfig.Version == HPBars.Config.Version then
		local isDefaultConfig = true
		for key, value in pairs(HPBars.Config) do
			if type(value) ~= type(HPBars.DefaultConfig[key]) then
				print("Enhanced Boss Bar - Warning! : Config value '" .. key .. "' has wrong data-type. Resetting it to default...")
				HPBars.Config[key] = HPBars.DefaultConfig[key]
			end
			if HPBars.DefaultConfig[key] ~= value then
				isDefaultConfig = false
			end
		end
		if isDefaultConfig or HPBars.MCMLoaded then
			for key, value in pairs(HPBars.Config) do
				if savedConfig[key] ~= nil and type(value) == type(savedConfig[key]) then
					HPBars.Config[key] = savedConfig[key]
				end
			end
		end
	end
end
HPBars:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OnGameStart)

--Saving Moddata--
function SaveGame()
	HPBars.SaveData(HPBars, json.encode(HPBars.Config))
end
HPBars:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveGame)
