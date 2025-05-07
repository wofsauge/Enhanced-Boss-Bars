HPBars = RegisterMod("Enhanced Boss bars", 1)
HPBars.Version = 1.34
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

HPBars.StatusIconSprite = Sprite()
HPBars.StatusIconSprite:Load(HPBars.iconPath .. "statuseffect_icon.anm2", true)

local gideonFont = Font() -- init font object
gideonFont:Load("font/pftempestasevencondensed.fnt")

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
function HPBars:getIconSprite(bossDefinition, tableEntry, barStyle)
	local iconSuffix = ""
	if tableEntry.bossColorIDx >= 0 and bossDefinition.bossColors then
		iconSuffix = bossDefinition.bossColors[tableEntry.bossColorIDx+1] or ""
	end

	local iconFile = HPBars:evaluateConditionals(bossDefinition, tableEntry) or bossDefinition.sprite or barStyle.defaultIcon
	return string.gsub(iconFile, ".png", iconSuffix..".png")
end

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

function HPBars:setBarStyle(bossEntry, barStyle)
	if not HPBars:isTableEqual(barStyle, bossEntry.currentStyle) then
		HPBars:applyBarStyle(bossEntry, barStyle)
		bossEntry.currentStyle = barStyle
	end
end

function HPBars:setIcon(bossEntry, iconToLoad, bossDefinition)
	if iconToLoad ~= bossEntry.currentIcon then
		if HPBars.Config.ShowCustomIcons then
			if bossDefinition.iconAnm2 then
				bossEntry.iconSprite:Load(bossDefinition.iconAnm2, true)
			end
			for i = 0, bossEntry.iconSprite:GetLayerCount() - 1 do
				bossEntry.iconSprite:ReplaceSpritesheet(i, iconToLoad)
			end
			bossEntry.iconSprite:LoadGraphics()

			if bossDefinition.iconAnimationType then
				bossEntry.iconSprite:Play(bossEntry.iconSprite:GetDefaultAnimation(), true)
				bossEntry.iconAnimationType = bossDefinition.iconAnimationType
			end
			bossEntry.iconOffset = bossDefinition.offset or bossEntry.iconOffset
		end

		if bossEntry.entityColor then
			local newColor = bossEntry.entityColor
			if newColor.R ~= 0.5 and newColor.G ~= 0.5 and newColor.B ~= 0.5 and newColor.RO >= 0.5 and newColor.RO < 0.9 then
				-- only apply if color is not the Hit coloring
				bossEntry.iconSprite.Color = newColor
			end
		end
		bossEntry.ignoreInvincible = bossDefinition.ignoreInvincible
		bossEntry.currentIcon = iconToLoad
	end
end

function HPBars:applyBarStyle(bossEntry, barStyle)
	if not barStyle or not bossEntry then
		return
	end
	local isVertical = HPBars:isVerticalLayout()
	local barAnm2 = isVertical and barStyle.verticalAnm2 or barStyle.barAnm2
	bossEntry.barSprite:Load(barAnm2, true)

	local overlayAnm2 = isVertical and barStyle.verticalOverlayAnm2 or barStyle.overlayAnm2
	if overlayAnm2 then
		bossEntry.barOverlaySprite = Sprite()
		bossEntry.barOverlaySprite:Load(overlayAnm2, true)
		if barStyle.overlaySprite then
			local overlaySprite = isVertical and barStyle.verticalOverlaySprite or barStyle.overlaySprite
			for i = 0, bossEntry.barOverlaySprite:GetLayerCount() - 1 do
				bossEntry.barOverlaySprite:ReplaceSpritesheet(i, overlaySprite)
			end
			bossEntry.barOverlaySprite:LoadGraphics()
		end
	end
	if barStyle.notchAnm2 and barStyle.notchAnm2 ~= "NONE" then
		bossEntry.notchSprite = Sprite()
		bossEntry.notchSprite:Load(barStyle.notchAnm2, true)
		if barStyle.notchSprite then
			for i = 0, bossEntry.notchSprite:GetLayerCount() - 1 do
				bossEntry.notchSprite:ReplaceSpritesheet(i, barStyle.notchSprite)
			end
			bossEntry.notchSprite:LoadGraphics()
		end
	end

	local barSprite = isVertical and barStyle.verticalSprite or barStyle.sprite
	if barStyle.sprite then
		for i = 0, bossEntry.barSprite:GetLayerCount() - 1 do
			bossEntry.barSprite:ReplaceSpritesheet(i, barSprite)
		end
	end
	bossEntry.barSprite:LoadGraphics()
	if barStyle.barAnimationType == "Animated" then
		bossEntry.barSprite:Play(bossEntry.barSprite:GetDefaultAnimation(), true)
	end
	if barStyle.overlayAnimationType == "Animated" then
		bossEntry.barOverlaySprite:Play(bossEntry.barOverlaySprite:GetDefaultAnimation(), true)
	end
	if barStyle.notchAnimationType == "Animated" then
		bossEntry.notchSprite:Play(bossEntry.notchSprite:GetDefaultAnimation(), true)
	end
	bossEntry.barStyle = barStyle
end

function HPBars:getBossDefinition(bossEntity)
	local bossDefinition = HPBars.BossDefinitions[bossEntity.Type .. "." .. bossEntity.Variant]
	if bossDefinition == nil then
		bossDefinition = HPBars.BossDefinitions["UNDEFINED"]
	end
	return bossDefinition
end

function HPBars:updateSprites(bossEntry)
	local bossDefinition = HPBars:getBossDefinition(bossEntry.entity)
	local newStyle = HPBars.Config.EnableSpecificBossbars and bossDefinition.barStyle or bossEntry.barStyle
	local barStyle = HPBars:getBarStyle(newStyle)
	HPBars:setBarStyle(bossEntry, barStyle)

	local iconToLoad = HPBars:getIconSprite(bossDefinition, bossEntry, barStyle)

	HPBars:setIcon(bossEntry, iconToLoad, bossDefinition)
	bossEntry.sorting = bossDefinition.sorting
	bossEntry.iconSprite:Update()
	bossEntry.barSprite:Update()
	if bossEntry.barOverlaySprite then
		bossEntry.barOverlaySprite:Update()
	end
	if bossEntry.notchSprite then
		bossEntry.notchSprite:Update()
	end
end

function HPBars:evaluateEntityIgnore(entity)
	if entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) or entity:HasEntityFlags(EntityFlag.FLAG_DONT_COUNT_BOSS_HP) then
		return true
	end

	-- If main boss is delirium, dont apply any bar splitting or bar combinating operators
	local parent = entity.Parent
	local visitedEntities = {}
	while parent ~= nil do
		if parent.Type == 412 then
			return true
		end
		if visitedEntities[GetPtrHash(parent)] then
			break
		end
		visitedEntities[GetPtrHash(parent)] = true
		parent = parent.Parent
	end

	-- Apply boss specific custom ignore rules
	local entityString = entity.Type .. "." .. entity.Variant
	local ignoreEntry = HPBars.BossIgnoreList[entityString]
	if ignoreEntry then
		if type(ignoreEntry) == "function" then
			return ignoreEntry(entity)
		end
		return ignoreEntry
	end

	return false
end

function HPBars:createNewBossBar(entity)
	if not entity then return end -- sanity check

	local barStyle = HPBars:getBarStyle(HPBars.Config["BarStyle"])

	local icon = Sprite()
	icon:Load(HPBars.iconPath .. "bosshp_icon_32px.anm2", true)

	local bossHPsprite = Sprite()
	bossHPsprite:Load(barStyle.barAnm2, true)
	local entityNPC = entity:ToNPC()
	local bossColor = entityNPC and entityNPC:GetBossColorIdx() or -1

	local championColor =
		entityNPC and HPBars.Config.UseChampionColors and
		(entityNPC:GetChampionColorIdx() >= 0 or bossColor >= 0) and
		HPBars:copyColor(entity:GetColor()) or
		nil

	local newEntry = {
		entity = entity,
		hp = entity.HitPoints or 0,
		maxHP = entity.MaxHitPoints or 0,
		entityColor = championColor,
		bossColorIDx = entityNPC and bossColor or -1,
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
	if not entity then return end -- sanity check
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
	for _, entity in ipairs(Isaac.GetRoomEntities()) do
		if type(entity) == "userdata" then -- sanity check
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

	if HPBars.Config.Sorting == "Vanilla" and #sortedBosses > 0 then
		local mainBoss = sortedBosses[1]
		mainBoss.sumMaxHP = 0
		mainBoss.sumHP = 0
		mainBoss.entityColor = HPBars.BarColorings.none
		if #sortedBosses > 1 then
			local barStyle = HPBars:getBarStyle(HPBars.Config["BarStyle"])
			HPBars:setBarStyle(mainBoss, barStyle)
			HPBars:setIcon(mainBoss, barStyle.defaultIcon, {})
		end

		for _, boss in ipairs(sortedBosses) do
			mainBoss.sumMaxHP = mainBoss.sumMaxHP + boss.maxHP
			mainBoss.sumHP = mainBoss.sumHP + boss.hp
			mainBoss.ignoreInvincible = mainBoss.ignoreInvincible or boss.ignoreInvincible
			if boss.lastStateChangeFrame > mainBoss.lastStateChangeFrame then
				mainBoss.lastStateChangeFrame = boss.lastStateChangeFrame
				mainBoss.hitState = boss.hitState
			end
		end
		table.insert(currentBossesSorted, mainBoss)
		return
	end

	local visitedBosses = {}
	for _, boss in ipairs(sortedBosses) do
		local bossPtr = GetPtrHash(boss.entity)
		boss.sumMaxHP = boss.maxHP
		boss.sumHP = boss.hp

		if boss.entity.Parent == nil and not visitedBosses[bossPtr] then
			-- add parent to sorted list
			visitedBosses[bossPtr] = true
			-- add children to sorted list
			local curChild = boss.entity.Child
			while curChild ~= nil do
				local childPtr = GetPtrHash(curChild)
				local childEntry = HPBars.currentBosses[childPtr]
				if childEntry and not visitedBosses[childPtr] then
					visitedBosses[childPtr] = true
					local bossDef = HPBars:getBossDefinition(boss.entity)
					if HPBars.Config.Sorting == "Segments" or bossDef.forceSegmentation then
						table.insert(currentBossesSorted, childEntry)
					else
						boss.sumMaxHP = boss.sumMaxHP + childEntry.maxHP
						boss.sumHP = boss.sumHP + childEntry.hp
						if childEntry.lastStateChangeFrame > boss.lastStateChangeFrame then
							boss.lastStateChangeFrame = childEntry.lastStateChangeFrame
							boss.hitState = childEntry.hitState
						end
					end
				else
					break
				end
				curChild = curChild.Child
			end
			table.insert(currentBossesSorted, boss)
		end
	end
	-- add entries that where not handled from the loop aboth
	for k, boss in pairs(HPBars.currentBosses) do
		if not visitedBosses[k] then
			table.insert(currentBossesSorted, boss)
		end
	end

	local len = #currentBossesSorted
	local sortFunctionGroups = {}
	-- apply custom sort funcs
	for i = len - 1, 1, -1 do
		local bossEntry = currentBossesSorted[i]
		if type(bossEntry.sorting) == "function" then
			local group = bossEntry.entity.Type .. "." .. bossEntry.entity.Variant
			if not sortFunctionGroups[group] then
				sortFunctionGroups[group] = {}
			end
			table.insert(sortFunctionGroups[group], table.remove(currentBossesSorted, i))
		end
	end
	for _, tableToSort in pairs(sortFunctionGroups) do
		table.sort(tableToSort,
			function(boss1, boss2) return boss1.sorting(boss1.entity, boss2.entity) end)
		for _, value in ipairs(tableToSort) do
			table.insert(currentBossesSorted, value)
		end
	end

	-- invert sorted table
	for i = len - 1, 1, -1 do
		currentBossesSorted[len] = table.remove(currentBossesSorted, i)
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
		text = math.ceil((bossEntry.sumHP / bossEntry.sumMaxHP) * 100) .. "%"
	elseif HPBars.Config.InfoText == "HPLeft" then
		text = math.ceil(bossEntry.sumHP * 10) / 10
	end
	local textSize = Isaac.GetTextWidth(text)
	local transparency = HPBars.Config.TextTransparency
	local textScale = HPBars.Config.TextSize
	if HPBars:isVerticalLayout() then
		Isaac.RenderScaledText(text, barPos.X - (textSize / 2) * textScale, barPos.Y - barSize / 2 - 6 * textScale, textScale, textScale, 1, 1, 1, transparency)
	else
		Isaac.RenderScaledText(text, barPos.X + barSize / 2 - (textSize / 2) * textScale, barPos.Y - 6 * textScale, textScale, textScale, 1, 1, 1, transparency)
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

function HPBars:renderStatusIcons(bossEntry, barPos)
	if HPBars.Config.ShowStatusEffects then
		local activeEffects = 0
		for _, effectEntry in pairs(HPBars.StatusEffects) do
			if effectEntry.condition(bossEntry.entity) then
				activeEffects = activeEffects + 1
				local sprite = effectEntry.sprite or HPBars.StatusIconSprite
				sprite:SetFrame(effectEntry.animation, effectEntry.frame)
				if HPBars:isVerticalLayout() then
					sprite:Render(barPos + Vector(-6, -activeEffects * 10), Vector.Zero, Vector.Zero)
				else
					sprite:Render(barPos + Vector(activeEffects * 10, -6), Vector.Zero, Vector.Zero)
				end
			end
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
		Isaac.RenderText("Enhanced Boss Bars could not load correctly!", 40, 40, 1, 0.5, 0.5, 1)
		Isaac.RenderText("This is caused either by changing the games language,", 40, 52, 1, 0.5, 0.5, 1)
		Isaac.RenderText("a conflicting mod or the first installation of this mod.", 40, 64, 1, 0.5, 0.5, 1)
		Isaac.RenderText("Please deactivate all other mods that alter the Boss bar sprites", 40, 76, 1, 0.5, 0.5, 1)
		Isaac.RenderText("and Restart your game!", 40, 88, 1, 0.5, 0.5, 1)
	end
end

function HPBars:getHPPercent(bossEntry)
	return math.max(0, math.ceil((bossEntry.sumHP / bossEntry.sumMaxHP) * 100))
end

function HPBars:hasSpiderMod()
	for i = 0, game:GetNumPlayers() - 1 do
		if Isaac.GetPlayer(i):HasCollectible(CollectibleType.COLLECTIBLE_SPIDER_MOD) then
			return true
		end
	end
end

function HPBars:isIgnoreMegaSatanFight()
	return not HPBars.Config.ShowMegaSatan and game:GetRoom():GetBossID() == 55
end

function HPBars:handleGideonBar()
	for _, boss in pairs(currentBossesSorted) do
		-- If gideon was detected, do special handling for its boss bar and dont render any other bars
		-- the game has a separate bar design for gideon, that is a black bar and a wave counter text. We cant remove the text via modding api,
		-- so we render our bar sprite at the original vanilla bar position
		-- the boss bar of gideon renders !!after!! HUD_RENDER and POST_RENDER, so we cant render over it
		if boss.entity.Type == 907 then
			local screenSize = HPBars:getScreenSize()
			local barPosition = Vector(screenSize.X / 2, screenSize.Y - 12 * Options.HUDOffset) + HPBars.GideonBarOffset

			local hpbarFill = 1
			local barSizePercent = math.floor(60 / 120 * 100) -- half sized bar is similar to original bar
			-- render bg
			if boss.barStyle.barAnimationType == "HP" then
				boss.barSprite:SetFrame("bg" .. barSizePercent, hpbarFill)
			else
				boss.barSprite:SetAnimation("bg" .. barSizePercent, false)
			end
			boss.barSprite:Render(barPosition, Vector.Zero, Vector.Zero)

			-- apply special color that changes the bar filling to act more like a background
			boss.barSprite.Color = HPBars.BarColorings.gideon

			-- render charge
			if boss.barStyle.barAnimationType == "HP" then
				boss.barSprite:SetFrame("charge" .. barSizePercent, hpbarFill)
			else
				boss.barSprite:SetAnimation("charge" .. barSizePercent, false)
			end

			local progress = 60 / 100 * hpbarFill
			boss.barSprite:Render(barPosition, Vector.Zero, Vector(1 + progress, 0))

			-- render end deco
			if boss.barStyle.barAnimationType == "HP" then
				boss.barSprite:SetFrame("endDeco", hpbarFill)
			else
				boss.barSprite:SetAnimation("endDeco", false)
			end

			boss.barSprite:Render(barPosition + Vector(60 - 1 - progress, 0), Vector.Zero, Vector.Zero)

			boss.barSprite.Color = Color(1, 1, 1, 1, 0, 0, 0)

			HPBars:renderOverlays(boss, barPosition, hpbarFill, barSizePercent)

			HPBars:renderIcon(boss, barPosition, hpbarFill)

			-- render wave counter again, because stageAPI without repentogon render callback is called after the vanilla gideon bar rendering
			if not REPENTOGON and StageAPI and StageAPI.Loaded and boss.sumHP >= 1 then
				local text = math.floor(boss.sumMaxHP - boss.sumHP + 1) .. "/" .. math.floor(boss.sumMaxHP)
				local textPos = Vector(screenSize.X / 2 - 3, screenSize.Y - 12 * Options.HUDOffset - 21)
				gideonFont:DrawString(text, textPos.X, textPos.Y, KColor(1, 1, 1, 1, 0, 0, 0), gideonFont:GetStringWidth(text), true)
			end

			return true
		end
	end
	return false
end

function HPBars:onRender()
	HPBars:handleBadLoad()
	HPBars:updateRoomEntities()
	local currentBossCount = #currentBossesSorted
	if currentBossCount <= 0 then
		return
	end
	if HPBars:isIgnoreMegaSatanFight() or not HPBars.Config.DisplayWithSpidermod and HPBars:hasSpiderMod() then
		return
	end

	if HPBars:handleGideonBar() then
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
			local hpbarFill = 100 - math.min(HPBars:getHPPercent(boss), 99)
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

			HPBars:renderStatusIcons(boss, barPos)

			HPBars:renderInfoText(boss, barPos, barSize)
		end
	end
end
if REPENTOGON then
	HPBars:AddCallback(ModCallbacks.MC_HUD_RENDER, HPBars.onRender)
elseif StageAPI and StageAPI.Loaded then
	StageAPI.AddCallback("EnhancedBossBars", "POST_HUD_RENDER", 1, HPBars.onRender)
else
	HPBars:AddCallback(ModCallbacks.MC_POST_RENDER, HPBars.onRender)
end

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
function HPBars:OnGameStart(isSave)
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
			if type(value) ~= type(HPBars.PresetConfigs.Default[key]) then
				print("Enhanced Boss Bar - Warning! : Config value '" .. key .. "' has wrong data-type. Resetting it to default...")
				HPBars.Config[key] = HPBars.PresetConfigs.Default[key]
			end
			if HPBars.PresetConfigs.Default[key] ~= value then
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
HPBars:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, HPBars.OnGameStart)

--Saving Moddata--
function HPBars:SaveGame()
	HPBars.SaveData(HPBars, json.encode(HPBars.Config))
end
HPBars:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, HPBars.SaveGame)
