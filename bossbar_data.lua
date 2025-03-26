local path = HPBars.iconPath
local barPath = HPBars.barPath
local game = Game()

-- offset to the bottom screen center for the boss bar of Gideon
HPBars.GideonBarOffset = Vector(-22, -13.5)

HPBars.barSizes = {
	horizontal = {
		[1] = 120,
		[2] = 120,
		[3] = 60,
		[4] = 60,
		[5] = 30,
		[6] = 30,
		[7] = 30,
		[8] = 15,
		[9] = 15,
		[10] = 15
	},
	vertical = {
		[1] = 120,
		[2] = 60,
		[3] = 60,
		[4] = 30,
		[5] = 30,
		[6] = 15,
		[7] = 15,
		[8] = 15,
		[9] = 15,
		[10] = 15
	}
}

local function isDummyBarVisible(entity)
	return entity and HPBars.MCMLoaded and HPBars:isMCMVisible() and GetPtrHash(Isaac.GetPlayer()) == GetPtrHash(entity)
end

local function isAnimaSolaChained(entity)
    for _, chain in ipairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.ANIMA_CHAIN)) do
        if chain.Target and GetPtrHash(chain.Target) == GetPtrHash(entity) then
            return true
        end
    end
    return false
end

-- Stores which sprite should be rendered and what animation / frame to use. Usage: [Identifier] = {table}
--   condition = function used to determine if the effect should be rendered
--   animation = Name of the animation to play
--   frame = frame id to play
--   sprite = Sprite object to use (if nil, uses the default "HPBars.StatusIconSprite" sprite)
HPBars.StatusEffects = {
	["Burn"] = {
		condition = function(entity)
			return entity and entity:HasEntityFlags(EntityFlag.FLAG_BURN) or
				isDummyBarVisible(entity)
		end,
		animation = "idle",
		frame = 0,
	},
	["Charm"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_CHARM) end,
		animation = "idle",
		frame = 1,
	},
	["Confusion"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_CONFUSION) end,
		animation = "idle",
		frame = 2,
	},
	["Fear"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_FEAR) end,
		animation = "idle",
		frame = 3,
	},
	["Petrification"] = {
		condition = function(entity) return entity and (entity:HasEntityFlags(EntityFlag.FLAG_FREEZE) or entity:HasEntityFlags(EntityFlag.FLAG_MIDAS_FREEZE)) end,
		animation = "idle",
		frame = 4,
	},
	["Poison"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_POISON) end,
		animation = "idle",
		frame = 5,
	},
	["Slow"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_SLOW) end,
		animation = "idle",
		frame = 6,
	},
	["Friendly"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) end,
		animation = "idle",
		frame = 7,
	},
	["Shrink"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_SHRINK) end,
		animation = "idle",
		frame = 8,
	},
	["Bleed out"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_BLEED_OUT) end,
		animation = "idle",
		frame = 9,
	},
	["Baited"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_BAITED) end,
		animation = "idle",
		frame = 10,
	},
	["Chained"] = {
	 	condition = function(entity) return entity and isAnimaSolaChained(entity) end,
	 	animation = "idle",
	 	frame = 11,
	},
	["Freeze"] = {
		condition = function(entity) return entity and (entity:HasEntityFlags(EntityFlag.FLAG_ICE_FROZEN) or entity:HasEntityFlags(EntityFlag.FLAG_ICE)) end,
		animation = "idle",
		frame = 12,
	},
	["Magnetized"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_MAGNETIZED) end,
		animation = "idle",
		frame = 13,
	},
	["Brimstone Marked"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_BRIMSTONE_MARKED) end,
		animation = "idle",
		frame = 14,
	},
	["Weakness"] = {
		condition = function(entity) return entity and entity:HasEntityFlags(EntityFlag.FLAG_WEAKNESS) end,
		animation = "idle",
		frame = 15,
	},
}
-- table of condition macros used to alter the displayed boss icon
HPBars.Conditions = {
	["isHeadSegment"] = function(entity)
		return entity.Parent == nil and entity.Child ~= nil
	end,
	["isMiddleSegment"] = function(entity)
		return entity.Parent ~= nil and entity.Child ~= nil
	end,
	["isTailSegment"] = function(entity)
		return entity.Parent ~= nil and entity.Child == nil
	end,
	["isChild"] = function(entity)
		return entity.Parent ~= nil
	end,
	["isI1Equal"] = function(entity, args)
		return entity:ToNPC().I1 == args[1]
	end,
	["isI2Equal"] = function(entity, args)
		return entity:ToNPC().I2 == args[1]
	end,
	["isHPSmaller"] = function(entity, args)
		return entity.HitPoints < args[1]
	end,
	["isHPSmallerPercent"] = function(entity, args)
		return (entity.HitPoints / entity.MaxHitPoints) * 100 < args[1]
	end,
	["animationNameStartsWith"] = function(entity, args)
		return string.find(entity:GetSprite():GetAnimation(), "^" .. args[1])
	end,
	["animationNameEndsWith"] = function(entity, args)
		return string.find(entity:GetSprite():GetAnimation(), args[1] .. "$")
	end,
	["animationNameContains"] = function(entity, args)
		return string.find(entity:GetSprite():GetAnimation(), args[1])
	end,
	["animationNameEqual"] = function(entity, args)
		return entity:GetSprite():GetAnimation() == args[1]
	end,
	["isStageType"] = function(entity, args)
		return game:GetLevel():GetStageType() == args[1]
	end,
	["isAbsoluteStage"] = function(entity, args)
		return game:GetLevel():GetAbsoluteStage() == args[1]
	end
}

-- A list of boss entities that should be ignored. if the entry contains or returns true, the boss entity will be ignored
HPBars.BossIgnoreList = {
	["28.0"] = function(entity) -- chub (Sub Segments)
		return entity.Parent ~= nil
	end,
	["28.1"] = function(entity) -- chad (Sub Segments)
		return entity.Parent ~= nil
	end,
	["28.2"] = function(entity) -- carrion queen (Sub Segments)
		return entity.Parent ~= nil
	end,
	["45.0"] = true, -- mom doors
	["62.0"] = function(entity) -- pin (Sub Segments)
		return entity.Parent ~= nil
	end,
	["62.1"] = function(entity) -- scolex (Sub Segments)
		return entity.Parent ~= nil
	end,
	["62.2"] = function(entity) -- frail (Sub Segments)
		return entity.Parent ~= nil
	end,
	["62.3"] = function(entity) -- Wormwood (Sub Segments)
		return entity.Parent ~= nil
	end,
	["65.1"] = function(entity) -- Conquest
		return entity.Parent ~= nil
	end,
	["84.0"] = function(entity) -- Satan Phase 0 and 1
		return entity:ToNPC().I1 <= 1
	end,
	["84.10"] = function(entity) -- Satan second leg
		return entity.Child == nil
	end,
	["101.0"] = function(entity) -- dady long legs multi leg attack
		return entity:ToNPC().I1 == 1
	end,
	["101.1"] = function(entity) -- triachnid multi leg attack
		return entity:ToNPC().I1 == 1
	end,
	["274.0"] = function(entity) -- Mega satan before activation
		return entity:ToNPC().State == 2 or not HPBars.Config.ShowMegaSatan
	end,
	["274.1"] = function(entity) -- Mega satan before activation
		return entity:ToNPC().State == 2 or not HPBars.Config.ShowMegaSatan
	end,
	["274.2"] = function(entity) -- Mega satan before activation
		return entity:ToNPC().State == 2 or not HPBars.Config.ShowMegaSatan
	end,
	["275.0"] = function(entity) -- Mega satan phase 2
		return not HPBars.Config.ShowMegaSatan
	end,
	["266.1"] = true, -- mama gurdy hand
	["266.2"] = true, -- mama gurdy hand
	["294.0"] = true, -- Ultra greed door
	["406.0"] = function(entity) -- Ultra greed dead
		local anm = entity:GetSprite():GetAnimation()
		return anm == "Final" or anm == "Death"
	end,
	["406.1"] = function(entity) -- Ultra greedier dead
		local anm = entity:GetSprite():GetAnimation()
		return anm == "Final" or anm == "Death"
	end,
	["411.1"] = true, -- big horn
	["412.0"] = function(entity) -- delirium spawned stuff
		return entity.Parent ~= nil
	end,
	["866.0"] = true, -- Dark Esau
	["867.0"] = true, -- Mothers shadow (knife piece 2 escape)
	["903.1"] = function(entity) -- The Mask
		return string.find(entity:GetSprite():GetAnimation(), "Stun")
	end,
	["905.0"] = function(entity) -- Heretic (fading dummy)
		return entity.SpawnerEntity ~= nil
	end,
	["906.1"] = true, -- hornfel decoy
	["912.0"] = function(entity) -- Mother Segments
		return entity.Parent ~= nil or entity:GetSprite():GetAnimation() == "Transition" or
			not HPBars.Config.ShowInMotherFight
	end,
	["912.10"] = function(entity) -- Mother phase 2
		return not HPBars.Config.ShowInMotherFight
	end,
	["912.30"] = true, -- Mother snake attacks
	["912.100"] = true, -- Mother ball attacks
	["918.0"] = function(entity) -- Turdlet (Sub Segments)
		return entity.Parent ~= nil
	end,
	["919.1"] = true, -- Raglich Arm
	["950.0"] = true, -- dogma invinsible baby
	["950.1"] = function(entity) -- dogma TV
		return string.find(entity:GetSprite():GetAnimation(), "Destroyed")
	end,
	["951.0"] = function(entity) -- Beast when not active
		return entity:GetSprite():GetAnimation() == "Idle" and entity:ToNPC().State == 16 or
			not HPBars.Config.ShowInBeastFight
	end,
	["951.10"] = function(entity) -- Ultra Famine
		return not HPBars.Config.ShowInBeastFight
	end,
	["951.20"] = function(entity) -- Ultra pestilence
		return not HPBars.Config.ShowInBeastFight
	end,
	["951.30"] = function(entity) -- Ultra War
		return not HPBars.Config.ShowInBeastFight
	end,
	["951.40"] = function(entity) -- Ultra Death
		return not HPBars.Config.ShowInBeastFight
	end,
	["951.100"] = true, -- Beast bg entity
	["951.101"] = true, -- Beast bg entity
	["951.102"] = true, -- Beast bg entity
	["951.103"] = true, -- Beast bg entity
	["951.104"] = true, -- Beast bg entity
	["964.0"] = true -- Dummy NPC
}

HPBars.BarColorings = {
	vanillaDefault = Color(0.8, 0, 0, 1, 0, 0, 0), -- red tint
	vanillaHit = Color(0.48, 0, 0, 1, 0, 0, 0), -- black coloring
	vanillaHeal = Color(0.87, 0.4, 0, 1, 0, 0, 0), -- orange coloring
	vanillaInvincible = Color(1, 1, 1, 0.5, 0.25, 0.25, 0.25), -- gray coloring
	white = Color(1, 1, 1, 1, 1, 1, 1), -- full white coloring
	none = Color(1, 1, 1, 1, 0, 0, 0), -- no coloring
	gideon = Color(0.2, 0.2, 0.2, 1, 0, 0, 0), -- special muted color for gideon boss bar
}

HPBars.ColoringFunctions = {
	["Vanilla"] = function(bossEntry)
		local curTime = game:GetFrameCount()
		if bossEntry.lastStateChangeFrame + 7 >= curTime and curTime % 2 == 1 and HPBars.Config.EnableFlashing then
			if bossEntry.hitState == "heal" then
				bossEntry.barSprite.Color = bossEntry.barStyle.healColoring
			elseif bossEntry.hitState == "damage" then
				bossEntry.barSprite.Color = bossEntry.barStyle.hitColoring
			end
		else
			if HPBars.Config.EnableInvicibilityIndication and HPBars:isInvincible(bossEntry) then
				bossEntry.barSprite.Color = bossEntry.barStyle.invincibleColoring
			else
				bossEntry.barSprite.Color = bossEntry.barStyle.idleColoring
			end
		end
	end,
	["WhiteToRed"] = function(bossEntry)
		local curTime = game:GetFrameCount()
		if bossEntry.lastStateChangeFrame + 7 >= curTime and curTime % 2 == 1 and HPBars.Config.EnableFlashing then
			if bossEntry.hitState == "heal" then
				bossEntry.barSprite.Color = bossEntry.barStyle.healColoring
			elseif bossEntry.hitState == "damage" then
				bossEntry.barSprite.Color = bossEntry.barStyle.hitColoring
			end
		else
			if HPBars.Config.EnableInvicibilityIndication and HPBars:isInvincible(bossEntry) then
				bossEntry.barSprite.Color = bossEntry.barStyle.invincibleColoring
			else
				local hpbarFill = math.ceil((bossEntry.hp / bossEntry.maxHP) * 100)
				bossEntry.barSprite.Color = Color(1, hpbarFill / 100, hpbarFill / 100, 1, 0, 0, 0)
			end
		end
	end
}

HPBars.BarStyles = {
	["Default"] = {
		sprite = barPath .. "custom_bosshp_default.png",
		barAnm2 = barPath .. "custom_bosshp.anm2",
		barAnimationType = "HP",
		overlaySprite = nil,
		overlayAnm2 = nil,
		overlayAnimationType = "HP",
		defaultIcon = path .. "boss.png",
		verticalSprite = nil,
		verticalAnm2 = nil,
		verticalOverlaySprite = nil,
		verticalOverlayAnm2 = nil,
		notchSprite = barPath .. "bossbar_notches.png",
		notchAnm2 = barPath .. "default_overlay.anm2", -- set to NONE, if notches should not be visible
		notchAnimationType = "HP",
		idleColoring = HPBars.BarColorings.vanillaDefault,
		hitColoring = HPBars.BarColorings.vanillaHit,
		healColoring = HPBars.BarColorings.vanillaHeal,
		invincibleColoring = HPBars.BarColorings.vanillaInvincible,
		coloringFunction = HPBars.ColoringFunctions.Vanilla,
		tooltip = "Default bar visuals"
	},
	-- boss designs
	["Beast"] = {
		sprite = barPath .. "bosses/bossbar_beast.png",
		overlayAnm2 = barPath .. "bosses/beast_bosshp_overlay.anm2",
		overlayAnimationType = "Animated",
		idleColoring = HPBars.BarColorings.none,
		hitColoring = HPBars.BarColorings.white,
		tooltip = "'Beast' - Boss themed"
	},
	["Colostomia"] = {
		sprite = barPath .. "bosses/bossbar_colostomia.png",
		verticalSprite = barPath .. "bosses/bossbar_colostomia_vertical.png",
		barAnm2 = barPath .. "bosses/colostomia_bosshp.anm2",
		barAnimationType = "Animated",
		idleColoring = HPBars.BarColorings.none,
		hitColoring = HPBars.BarColorings.white,
		tooltip = "'Colostomia' - Boss themed"
	},
	["Dark Esau"] = {
		sprite = barPath .. "bosses/bossbar_darkesau.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Dark Esau' - themed"
	},
	["Delirium"] = {
		sprite = barPath .. "bosses/bossbar_delirium.png",
		barAnm2 = barPath .. "bosses/delirium_bosshp.anm2",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Delirium' - Boss themed"
	},
	["Dogma"] = {
		sprite = barPath .. "bosses/dogma_bar.png",
		barAnm2 = barPath .. "bosses/dogma_bosshp.anm2",
		barAnimationType = "Animated",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Dogma' - Boss themed"
	},
	["Hush"] = {
		sprite = barPath .. "bosses/bossbar_hush.png",
		idleColoring = HPBars.BarColorings.none,
		hitColoring = Color(0.227, 0.29, 0.407, 1, 0, 0, 0),
		invincibleColoring = Color(0, 0, 0, 0.75, 0.5, 0.5, 0.5),
		tooltip = "'Hush' - Boss themed"
	},
	["Mega Satan"] = {
		sprite = barPath .. "bosses/bossbar_mega_satan.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Mega Satan' - Boss themed"
	},
	["Mega Satan Phase 2"] = {
		sprite = barPath .. "bosses/bossbar_mega_satan_phase2.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Mega Satan Phase 2' - Boss themed"
	},
	["Mother"] = {
		sprite = barPath .. "bosses/bossbar_mother.png",
		overlayAnm2 = barPath .. "default_overlay.anm2",
		overlaySprite = barPath .. "bosses/bossbar_overlay_mother.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Mother' - Boss themed"
	},
	["Steven"] = {
		sprite = barPath .. "bosses/bossbar_steven.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Steven' - Boss themed"
	},
	["Ultra Greed"] = {
		sprite = barPath .. "bosses/bossbar_ultra_greed.png",
		idleColoring = HPBars.BarColorings.none,
		notchAnm2 = "NONE",
		tooltip = "'Ultra Greed' - Boss themed"
	},
	["Ultra Greedier"] = {
		sprite = barPath .. "bosses/bossbar_ultra_greedier.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "'Ultra Greedier' - Boss themed"
	},
	-- custom designs
	["Abyss"] = {
		sprite = barPath .. "bossbar_design_abyss.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble Abyss"
	},
	["Copper"] = {
		sprite = barPath .. "bossbar_design_copper.png",
		idleColoring = HPBars.BarColorings.none,
		notchAnm2 = "NONE",
		tooltip = "Styled to look like medival copper"
	},
	["Dots"] = {
		sprite = barPath .. "bossbar_design_dots.png",
		idleColoring = HPBars.BarColorings.none,
		notchAnm2 = "NONE",
		tooltip = "Styled to use cool dots"
	},
	["Enter the Gungeon"] = {
		sprite = barPath .. "bossbar_design_etg.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled like its in Enter the Gungeon"
	},
	["Flash"] = {
		sprite = barPath .. "bossbar_design_flash.png",
		defaultIcon = path .. "agnry_faic.png",
		tooltip = "Styled similar to the Flash version of Isaac"
	},
	["Flip"] = {
		sprite = barPath .. "bossbar_design_flip.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble Flip"
	},
	["Hearts"] = {
		sprite = barPath .. "bossbar_design_isaachearts.png",
		verticalSprite = barPath .. "bossbar_design_isaacheartsvertical.png",
		idleColoring = HPBars.BarColorings.none,
		notchAnm2 = "NONE",
		tooltip = "Styled to look like hearts"
	},
	["Lil' Portal"] = {
		sprite = barPath .. "bossbar_design_lilportal.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble Lil Portal"
	},
	["Magic Mushroom"] = {
		sprite = barPath .. "bossbar_design_magicmushroom.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble Magic Mushroom"
	},
	["Minimal"] = {
		sprite = barPath .. "bossbar_design_bw.png",
		notchAnm2 = "NONE",
		tooltip = "Styled to be minimal"
	},
	["Minecraft"] = {
		sprite = barPath .. "bossbar_design_minecraft.png",
		verticalSprite = barPath .. "bossbar_design_minecraftvertical.png",
		idleColoring = HPBars.BarColorings.none,
		notchAnm2 = "NONE",
		tooltip = "Styled to look like Minecrafts UI"
	},
	["Playdough Cookie"] = {
		sprite = barPath .. "bossbar_design_playdoughcookie.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble Playdough Cookie"
	},
	["Planetarium"] = {
		sprite = barPath .. "bossbar_design_planetarium.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble the Planetarium"
	},
	["Revelation"] = {
		sprite = barPath .. "bossbar_design_revelation.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble Revelation"
	},
	["Spin To Win"] = {
		sprite = barPath .. "bossbar_design_spintowin.png",
		idleColoring = HPBars.BarColorings.none,
		notchAnm2 = "NONE",
		tooltip = "Styled to resemble Spin To Win"
	},
	["Terraria"] = {
		sprite = barPath .. "bossbar_design_terraria.png",
		idleColoring = HPBars.BarColorings.none,
		notchSprite = barPath .. "bossbar_notches_terraria.png",
		hitColoring = Color(1, 1, 1, 1, 1, 0, 0),
		tooltip = "Styled like its in Terraria"
	},
	["TM Trainer"] = {
		sprite = barPath .. "bossbar_design_tmtrainer.png",
		barAnm2 = barPath .. "bosses/dogma_bosshp.anm2",
		barAnimationType = "Animated",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble TM Trainer"
	},
	["Void"] = {
		sprite = barPath .. "bossbar_design_void.png",
		idleColoring = HPBars.BarColorings.none,
		tooltip = "Styled to resemble Void"
	},
	-- Other mod designs
	["Design - Serious Max"] = {
		sprite = barPath .. "bossbar_design1(serious max).png",
		tooltip = "Boss bar mod by Serious Max"
	},
	["Design - Spyro"] = {
		sprite = barPath .. "bossbar_design2(Spyro).png",
		tooltip = "Boss bar mod by Spyro"
	},
	["Design - Hesitant Hatterene"] = {
		sprite = barPath .. "bossbar_design3(Hesitant Hatterene).png",
		tooltip = "Boss bar mod by Hesitant Hatterene"
	},
	["Design - TheSavageHybrid"] = {
		sprite = barPath .. "bossbar_design4(TheSavageHybrid).png",
		notchSprite = barPath .. "bossbar_notches_paper.png",
		tooltip = "Boss bar mod by TheSavageHybrid"
	}
}

HPBars.BossDefinitions = {
	--[[ Format: ["Type.Variant"] = {
		sprite = main sprite that this entity should use as its icon
		ignoreInvincible = if set to true, this will make the boss bar to not show invincible state
		iconAnm2 = Path to a .anm2 file this icon should use instead of the default one.
		iconAnimationType = Possible values: ["HP","Animated"]
				HP: 		DEFAULT. The given .anm2 file will render the animation frame based on the current boss HP in percent (0-99 Frames). This allows for custom animations based on the progress of damage you have dealt.
				Animated: 	the provided .anm2 file will be played as a normal animation, allowing for custom animated icons
		conditionalSprites = table containing subtables of conditional sprite objects, formatted as {ConditionFunction, SpritePath, optional table of args}. ConditionFunction can either be a function or the name of the macro condition from the HPBars.conditions table
		bossColors = Table of possible boss color suffix. Example: {"orange","black"} --> BosscolorIDx 0 = orange, IDx: 1 = black
		offset = offset of the icon sprite to the start of the bar, used to prevent overlapping of the last percents of the hp
		barSyle = Specific bar-style the boss should use. Value can either be the Name of the entry from the HPBars.BarStyles table or a new table formated the same as an entry in the HPBars.BarStyles table
		forceSegmentation = if set to true, this boss will ignore the boss grouping algorithm of the config option "sorting = bosses"
		sorting = function that can be used to define how entities of the same type should be sorted. the function should return true for when the first entity should be displayed before the second.
	}
	]] --
	["UNDEFINED"] = {},
	["19.0"] = {
		sprite = path .. "chapter1/larry jr.png",
		conditionalSprites = {
			{"isMiddleSegment", path .. "chapter1/larry jr_segment.png"},
			{"isTailSegment", path .. "chapter1/larry jr_segment.png"}
		},
		bossColors={ "_green", "_blue", },
		offset = Vector(-6, 0)
	},
	["19.1"] = {
		sprite = path .. "chapter2/the_hollow.png",
		conditionalSprites = {
			{"isMiddleSegment", path .. "chapter2/the_hollow_segment.png"},
			{"isTailSegment", path .. "chapter2/the_hollow_segment.png"}
		},
		bossColors={ "_green", "_black", "_yellow", },
		offset = Vector(-7, 0)
	},
	["19.2"] = {
		sprite = path .. "altpath/tuff_twin.png",
		conditionalSprites = {
			{
				function(entity)
					return entity.Parent == nil and entity.Child ~= nil and entity:ToNPC().I2 == 1
				end,
				path .. "altpath/tuff_twin_exposed.png"
			},
			{
				function(entity)
					return entity.Parent ~= nil and entity.Child ~= nil and entity:ToNPC().I2 == 1
				end,
				path .. "altpath/tuff_twin_segment_exposed.png"
			},
			{
				function(entity)
					return entity.Parent ~= nil and entity.Child == nil and entity:ToNPC().I2 == 1
				end,
				path .. "altpath/tuff_twin_segment_exposed_butt.png"
			},
			{"isMiddleSegment", path .. "altpath/tuff_twin_segment.png"},
			{"isTailSegment", path .. "altpath/tuff_twin_segment_butt.png"}
		},
		offset = Vector(-6, -2)
	},
	["19.3"] = {
		sprite = path .. "altpath/the_shell.png",
		conditionalSprites = {
			{"animationNameContains", path .. "altpath/the_shell_segment_exposed(butt).png", {"Butt"}},
			{"animationNameContains", path .. "altpath/the_shell_segment_exposed(face).png", {"Guts"}},
			{"isChild", path .. "altpath/the_shell_segment.png"}
		},
		offset = Vector(-6, -2)
	},
	["20.0"] = {sprite = path .. "chapter1/monstro.png", bossColors={ "_red", "_grey", }, ignoreInvincible = true, offset = Vector(-5, 0)},
	["28.0"] = {sprite = path .. "chapter2/chub.png",bossColors={ "_blue", "_orange", }, offset = Vector(-4, 0)},
	["28.1"] = {sprite = path .. "chapter2/chad.png", offset = Vector(-4, 0)},
	["28.2"] = {sprite = path .. "chapter2/carrion_queen.png",bossColors={ "_pink", }, offset = Vector(-4, 0)},
	["36.0"] = {sprite = path .. "chapter2/gurdy.png",bossColors={ "_green", }, offset = Vector(-6, -1)},
	["38.2"] = {sprite = path .. "minibosses/ultra_pride_florian.png", offset = Vector(-4, 0)},
	["43.0"] = {sprite = path .. "chapter3/monstro_two.png",bossColors={ "_red", }, offset = Vector(-4, 0)},
	["43.1"] = {sprite = path .. "chapter3/gish.png", offset = Vector(-5, 0)},
	["45.10"] = {
		sprite = path .. "final/mom.png",
		ignoreInvincible = true,
		conditionalSprites = {
			{"isStageType", path .. "final/mausoleum_mom.png", {StageType.STAGETYPE_REPENTANCE}},
			{"isStageType", path .. "final/mausoleum_mom.png", {StageType.STAGETYPE_REPENTANCE_B}}
		},
		bossColors={ "_blue", "_red", },
		offset = Vector(-9, 0)
	},
	["46.0"] = {sprite = path .. "minibosses/sloth.png", offset = Vector(-6, 0)},
	["46.1"] = {sprite = path .. "minibosses/super_sloth.png", offset = Vector(-8, 0)},
	["46.2"] = {sprite = path .. "minibosses/ultra_pride_ed.png", offset = Vector(-5, 0)},
	["47.0"] = {sprite = path .. "minibosses/lust.png", offset = Vector(-6, 0)},
	["47.1"] = {sprite = path .. "minibosses/super_lust.png", offset = Vector(-8, 0)},
	["48.0"] = {sprite = path .. "minibosses/wrath.png", offset = Vector(-5, 0)},
	["48.1"] = {sprite = path .. "minibosses/super_wrath.png", offset = Vector(-8, 0)},
	["49.0"] = {sprite = path .. "minibosses/gluttony.png", offset = Vector(-6, 0)},
	["49.1"] = {sprite = path .. "minibosses/super_gluttony.png", offset = Vector(-8, 0)},
	["50.0"] = {sprite = path .. "minibosses/greed.png", offset = Vector(-6, 0)},
	["50.1"] = {sprite = path .. "minibosses/super_greed.png", offset = Vector(-8, 0)},
	["51.0"] = {sprite = path .. "minibosses/envy_large.png", offset = Vector(-5, 0)},
	["51.1"] = {sprite = path .. "minibosses/super_envy_large.png", offset = Vector(-8, 0)},
	["52.0"] = {sprite = path .. "minibosses/pride.png", offset = Vector(-6, 0)},
	["52.1"] = {sprite = path .. "minibosses/super_pride.png", offset = Vector(-8, 0)},
	["51.10"] = {sprite = path .. "minibosses/envy_large.png", offset = Vector(-5, 0)},
	["51.11"] = {sprite = path .. "minibosses/super_envy_medium.png", offset = Vector(-5, 0)},
	["51.20"] = {sprite = path .. "minibosses/envy_medium.png", offset = Vector(-4, 0)},
	["51.21"] = {sprite = path .. "minibosses/super_envy_small.png", offset = Vector(-4, 0)},
	["51.30"] = {sprite = path .. "minibosses/envy_small.png", offset = Vector(-2, 0)},
	["51.31"] = {sprite = path .. "minibosses/super_envy_tiny.png", offset = Vector(-2, 0)},
	["62.0"] = {sprite = path .. "chapter1/pin.png", bossColors={ "_grey", }, offset = Vector(-5, 0)},
	["62.1"] = {sprite = path .. "chapter4/scolex.png", offset = Vector(-5, 0)},
	["62.2"] = {
		sprite = path .. "chapter2/the_frail.png",
		conditionalSprites = {
			{"isI2Equal", path .. "chapter2/the_frail_phase2.png", {1}}
		},
		bossColors={ "_black", },
		offset = Vector(-5, 0)
	},
	["62.3"] = {
		sprite = path .. "altpath/wormwood.png",
		conditionalSprites = {
			{"isAbsoluteStage", path .. "altpath/wormwood_corpse.png", {LevelStage.STAGE4_1}},
			{"isAbsoluteStage", path .. "altpath/wormwood_corpse.png", {LevelStage.STAGE4_2}},
			{"isStageType", path .. "altpath/wormwood_dross.png", {StageType.STAGETYPE_REPENTANCE_B}}
		},
		offset = Vector(-10, 0)
	},
	["63.0"] = {sprite = path .. "horsemen/famine.png", bossColors={ "_blue", }, offset = Vector(-6, 0)},
	["64.0"] = {
		sprite = path .. "horsemen/pestilence.png",
		conditionalSprites = {
			{"isI1Equal", path .. "horsemen/pestilence_phase2.png", {1}}
		},
		bossColors={ "_grey", },
		offset = Vector(-5, 0)
	},
	["65.0"] = {sprite = path .. "horsemen/war.png", bossColors={ "_grey", }, offset = Vector(-5, 0)},
	["65.10"] = {sprite = path .. "horsemen/war_phase2.png", bossColors={ "_grey", }, offset = Vector(-5, 0)},
	["65.1"] = {sprite = path .. "horsemen/conquest.png", offset = Vector(-7, 0)},
	["66.0"] = {
		sprite = path .. "horsemen/death.png",
		conditionalSprites = {
			{"isI1Equal", path .. "horsemen/death_horse.png", {1}}
		},
		bossColors={ "_black", },
		offset = Vector(-6, 0)
	},
	["66.20"] = {sprite = path .. "horsemen/death_horse.png", bossColors={ "_black", }, offset = Vector(-2, 0)},
	["66.30"] = {sprite = path .. "horsemen/death.png", bossColors={ "_black", }, offset = Vector(-5, 0)},
	["67.0"] = {sprite = path .. "chapter1/duke_of_flies.png", bossColors={ "_green", "_orange", }, offset = Vector(-6, 0)},
	["67.1"] = {sprite = path .. "chapter2/the_husk.png", bossColors={ "_black", "_red", }, offset = Vector(-6, 0)},
	["68.0"] = {
		sprite = path .. "chapter2/peep.png",
		conditionalSprites = {
			{"isI1Equal", path .. "chapter2/peep_one_eye.png", {1}},
			{"isI1Equal", path .. "chapter2/peep_no_eyes.png", {2}}
		},
		bossColors={ "_yellow", "_cyan", },
		offset = Vector(-4, 0)
	},
	["68.1"] = {sprite = path .. "chapter3/the_bloat.png", bossColors={ "_green", }, offset = Vector(-4, 0)},
	["69.0"] = {sprite = path .. "chapter3/loki.png", offset = Vector(-4, 0)},
	["69.1"] = {
		sprite = path .. "chapter4/lokii.png",
		conditionalSprites = {
			{"isI1Equal", path .. "chapter4/lokii_2.png", {2}}
		},
		sorting = function(entity1, entity2) return entity1:ToNPC().I1 == 2 end,
		offset = Vector(-3, 0)
	},
	["71.0"] = {sprite = path .. "chapter2/fistula_large.png", bossColors={ "_grey", }, offset = Vector(-7, 0)},
	["71.1"] = {sprite = path .. "chapter4/teratoma_large.png", offset = Vector(-6, 0)},
	["72.0"] = {sprite = path .. "chapter2/fistula_medium.png", bossColors={ "_grey", }, offset = Vector(-4, 0)},
	["72.1"] = {sprite = path .. "chapter4/teratoma_medium.png", offset = Vector(-7, 0)},
	["73.0"] = {sprite = path .. "chapter2/fistula_small.png", offset = Vector(-2, 0)},
	["73.1"] = {sprite = path .. "chapter4/teratoma_small.png", bossColors={ "_grey", }, offset = Vector(-3, 0)},
	["74.0"] = {sprite = path .. "chapter4/blastocyst_large.png", offset = Vector(-7, 0)},
	["75.0"] = {sprite = path .. "chapter4/blastocyst_medium.png", offset = Vector(-4, 0)},
	["76.0"] = {sprite = path .. "chapter4/blastocyst_small.png", offset = Vector(-3, 0)},
	["78.0"] = {sprite = path .. "final/moms_heart.png", offset = Vector(-6, 0)},
	["78.1"] = {sprite = path .. "final/it_lives.png", offset = Vector(-8, 0)},
	["79.0"] = {sprite = path .. "chapter1/gemini_contusion.png", bossColors={ "_green", "_blue", }, offset = Vector(-6, 0), forceSegmentation = true},
	["79.1"] = {sprite = path .. "chapter1/steven_big.png", barStyle = "Steven", offset = Vector(-5, 0), forceSegmentation = true},
	["79.2"] = {sprite = path .. "chapter1/blighted_ovum.png", offset = Vector(-4, 0), forceSegmentation = true},
	["79.10"] = {
		sprite = path .. "chapter1/gemini_suture.png",
		conditionalSprites = {
			{"animationNameEndsWith", path .. "chapter1/gemini_suture_angry.png", {"02"}}
		},
		bossColors={ "_green", "_blue", },
		offset = Vector(-5, 0),
		forceSegmentation = true
	},
	["79.11"] = {
		sprite = path .. "chapter1/steven_small.png",
		barStyle = "Steven",
		conditionalSprites = {
			{"animationNameEndsWith", path .. "chapter1/steven_small_angry.png", {"02"}}
		},
		offset = Vector(-3, 0),
		forceSegmentation = true
	},
	["81.0"] = {sprite = path .. "chapter1/the_fallen.png", offset = Vector(-7, 2)},
	["81.1"] = {sprite = path .. "minibosses/krampus.png", offset = Vector(-6, 0)},
	["82.0"] = {sprite = path .. "horsemen/headless_horsemen_body.png", offset = Vector(-4, 0)},
	["83.0"] = {sprite = path .. "horsemen/headless_horsemen_head.png", offset = Vector(-7, 0)},
	["84.0"] = {sprite = path .. "final/satan.png", offset = Vector(-9, 0)},
	["84.10"] = {sprite = path .. "final/satan_phase2.png", offset = Vector(-9, 0)},
	["97.0"] = {
		sprite = path .. "chapter3/mask_of_infamy.png",
		conditionalSprites = {
			{"animationNameStartsWith", path .. "chapter3/mask_of_infamy_phase2.png", {"Angry"}}
		},
		bossColors={ "_black", },
		offset = Vector(-4, 2),
		forceSegmentation = true
	},
	["98.0"] = {sprite = path .. "chapter3/heart_of_infamy.png", bossColors={ "_black", }, offset = Vector(-2, 0), forceSegmentation = true},
	["99.0"] = {sprite = path .. "chapter2/gurdy_jr.png", bossColors={ "_blue", "_yellow", }, offset = Vector(-5, 0)},
	["100.0"] = {sprite = path .. "chapter1/widow.png", bossColors={ "_black", "_pink", }, offset = Vector(-6, 0)},
	["100.1"] = {sprite = path .. "chapter2/the_wretched.png", offset = Vector(-6, 0)},
	["101.0"] = {sprite = path .. "chapter4/daddy_long_legs.png", offset = Vector(-6, 0)},
	["101.1"] = {sprite = path .. "chapter4/triachnid.png", offset = Vector(-6, 0)},
	["102.0"] = {
		sprite = path .. "final/isaac.png",
		conditionalSprites = {
			{"animationNameStartsWith", path .. "final/isaac_phase2.png", {"2"}},
			{"animationNameStartsWith", path .. "final/isaac_phase3.png", {"3"}}
		},
		offset = Vector(-5, 0)
	},
	["102.1"] = {
		sprite = path .. "final/blue_baby.png",
		conditionalSprites = {
			{"animationNameStartsWith", path .. "final/blue_baby_phase2.png", {"2"}},
			{"animationNameStartsWith", path .. "final/blue_baby_phase3.png", {"3"}}
		},
		offset = Vector(-5, 0)
	},
	["102.2"] = {
		sprite = path .. "final/hush_baby.png",
		conditionalSprites = {
			{"animationNameStartsWith", path .. "final/hush_phase1.png", {"2"}},
			{"animationNameStartsWith", path .. "final/hush_phase1.png", {"3"}}
		},
		barStyle = "Hush",
		offset = Vector(-4, 0)
	},
	["237.1"] = {sprite = path .. "chapter1/gurgling.png", bossColors={ "_yellow", "_black", }, offset = Vector(-7, 0)},
	["237.2"] = {sprite = path .. "chapter1/turdling.png", offset = Vector(-8, 0)},
	["260.0"] = {
		sprite = path .. "chapter1/the_haunt.png",
		conditionalSprites = {
			{"isI1Equal", path .. "chapter1/the_haunt_phase2.png", {0}}
		},
		bossColors={ "_black", "_pink", },
		offset = Vector(-5, 0)
	},
	["261.0"] = {sprite = path .. "chapter1/dingle.png", bossColors={ "_red", "_black", }, offset = Vector(-5, 0)},
	["261.1"] = {sprite = path .. "chapter1/dangle.png", offset = Vector(-7, 0)},
	["262.0"] = {sprite = path .. "chapter2/mega_maw.png", bossColors={ "_red", "_black", }, offset = Vector(-5, 0)},
	["263.0"] = {sprite = path .. "chapter3/the_gate.png", bossColors={ "_red", "_black", }, offset = Vector(-6, 0)},
	["264.0"] = {sprite = path .. "chapter2/mega_fatty.png", bossColors={ "_red", "_brown", }, offset = Vector(-7, 0)},
	["265.0"] = {sprite = path .. "chapter3/the_cage.png", bossColors={ "_green", "_pink", }, offset = Vector(-7, 0)},
	["266.0"] = {sprite = path .. "chapter4/mama_gurdy.png", offset = Vector(-7, 0)},
	["267.0"] = {sprite = path .. "chapter2/dark_one.png", offset = Vector(-5, -2)},
	["268.0"] = {sprite = path .. "chapter3/the_adversary.png", offset = Vector(-5, -2)},
	["269.0"] = {sprite = path .. "chapter2/polycephalus.png", bossColors={ "_red", "_pink", }, offset = Vector(-10, 0)},
	["269.1"] = {sprite = path .. "chapter3/the_pile.png", offset = Vector(-10, 0)},
	["270.0"] = {sprite = path .. "chapter4/mr_fred.png", offset = Vector(-6, 0)},
	["271.0"] = {sprite = path .. "minibosses/uriel.png", offset = Vector(-5, 0)},
	["271.1"] = {sprite = path .. "minibosses/fallen_uriel.png", offset = Vector(-5, 0)},
	["272.0"] = {sprite = path .. "minibosses/gabriel.png", offset = Vector(-5, 0)},
	["272.1"] = {sprite = path .. "minibosses/fallen_gabriel.png", offset = Vector(-5, 0)},
	["273.0"] = {sprite = path .. "final/the_lamb.png", offset = Vector(-6, 0)},
	["273.10"] = {sprite = path .. "final/the_lamb_body.png", offset = Vector(-9, 0)},
	["274.0"] = {
		sprite = path .. "final/mega_satan.png",
		iconAnm2 = path .. "bosshp_icon_64px.anm2",
		barStyle = "Mega Satan",
		offset = Vector(-9, 0)
	},
	["274.1"] = {
		sprite = path .. "final/mega_satan_righthand.png",
		barStyle = "Mega Satan",
		offset = Vector(-9, 0)
	},
	["274.2"] = {
		sprite = path .. "final/mega_satan_lefthand.png",
		barStyle = "Mega Satan",
		offset = Vector(-9, 0)
	},
	["275.0"] = {
		sprite = path .. "final/mega_satan_phase2.png",
		iconAnm2 = path .. "bosshp_icon_64px.anm2",
		barStyle = "Mega Satan Phase 2",
		offset = Vector(-9, -3)
	},
	["401.0"] = {sprite = path .. "chapter2/the_stain.png", bossColors={ "_grey", }, offset = Vector(-10, 0)},
	["402.0"] = {sprite = path .. "chapter3/brownie.png", bossColors={ "_black", }, offset = Vector(-8, 0)},
	["403.0"] = {sprite = path .. "chapter2/the_forsaken.png", bossColors={ "_black", }, offset = Vector(-6, 0)},
	["404.0"] = {sprite = path .. "chapter1/little_horn.png", offset = Vector(-5, 0), bossColors={ "_orange", "_black", },},
	["405.0"] = {sprite = path .. "chapter1/ragman.png", bossColors={ "_red", "_black", }, offset = Vector(-5, 0)},
	["406.0"] = {
		sprite = path .. "final/ultra_greed.png",
		barStyle = "Ultra Greed",
		offset = Vector(-8, 0)
	},
	["406.1"] = {
		sprite = path .. "final/ultra_greedier.png",
		barStyle = "Ultra Greedier",
		offset = Vector(-8, 0)
	},
	["407.0"] = {
		sprite = path .. "final/hush.png",
		barStyle = "Hush",
		offset = Vector(-9, 0)
	},
	["408.0"] = {sprite = path .. "unused/skinless_hush.png", offset = Vector(-8, 0)},
	["409.0"] = {sprite = path .. "chapter2/rag_mega.png", offset = Vector(-7, 0)},
	["410.0"] = {sprite = path .. "chapter3/sisters_vis.png", offset = Vector(-5, 0), forceSegmentation = true},
	["411.0"] = {sprite = path .. "chapter2/big_horn.png", ignoreInvincible = true, offset = Vector(-9, -2)},
	["412.0"] = {
		sprite = path .. "final/delirium.png",
		barStyle = "Delirium",
		offset = Vector(-7, 0)
	},
	["413.0"] = {sprite = path .. "chapter4/the_matriarch.png", offset = Vector(-10, 0)},
	["866.0"] = {
		sprite = path .. "minibosses/dark_esau.png",
		barStyle = "Dark Esau",
		offset = Vector(-6, 0)
	},
	["900.0"] = {
		sprite = path .. "chapter3/reap_creep.png",
		conditionalSprites = {
			{"animationNameContains", path .. "chapter3/reap_creep_phase2.png", {"2"}},
			{"animationNameContains", path .. "chapter3/reap_creep_phase3.png", {"3"}},
			{"animationNameContains", path .. "chapter3/reap_creep_phase3.png", {"Dash"}}
		},
		offset = Vector(-8, 0)
	},
	["901.0"] = {
		sprite = path .. "altpath/lil_blub.png",
		conditionalSprites = {
			{"isStageType", path .. "altpath/lil_blub_dross.png", {StageType.STAGETYPE_REPENTANCE_B}}
		},
		offset = Vector(-6, 0)
	},
	["902.0"] = {sprite = path .. "altpath/rainmaker.png", offset = Vector(-5, 0)},
	["903.0"] = {
		sprite = path .. "altpath/the_visage_heart.png",
		conditionalSprites = {
			{"animationNameContains", path .. "altpath/the_visage_heart_phase2.png", {"2"}},
			{"animationNameContains", path .. "chapter3/heart_of_infamy.png", {"3"}},
			{"animationNameContains", path .. "chapter3/heart_of_infamy.png", {"Attack"}}
		},
		offset = Vector(-3, 0),
		forceSegmentation = true
	},
	["903.1"] = {
		sprite = path .. "altpath/the_visage_mask.png",
		conditionalSprites = {
			{"animationNameContains", path .. "altpath/the_visage_mask_phase2.png", {"Angry"}},
			{"animationNameContains", path .. "altpath/the_visage_mask_phase2.png", {"2"}}
		},
		offset = Vector(-3, 0),
		forceSegmentation = true
	},
	["904.0"] = {sprite = path .. "altpath/siren.png", offset = Vector(-8, 0)},
	["905.0"] = {sprite = path .. "altpath/the_heretic.png", offset = Vector(-8, 0)},
	["906.0"] = {
		sprite = path .. "altpath/hornfel.png",
		conditionalSprites = {
			{"animationNameContains", path .. "altpath/hornfel_phase2.png", {"Run"}},
			{"animationNameContains", path .. "altpath/hornfel_phase2.png", {"Sad"}}
		},
		offset = Vector(-4, 0)
	},
	["907.0"] = {sprite = path .. "altpath/great_gideon.png", offset = Vector(-5, 0)}, -- Gideon: Game will render the bar, we render the icon. This entry stores path to boss icon/data
	["908.0"] = {sprite = path .. "chapter1/baby_plum.png", offset = Vector(-5, 0)},
	["909.0"] = {sprite = path .. "altpath/the_scourge.png", offset = Vector(-5, 0)},
	["910.0"] = {sprite = path .. "altpath/chimera_head.png", offset = Vector(-8, 0), forceSegmentation = true},
	["910.1"] = {sprite = path .. "altpath/chimera_body.png", offset = Vector(-8, 0), forceSegmentation = true},
	["910.2"] = {sprite = path .. "altpath/chimera_head.png", offset = Vector(-8, 0), forceSegmentation = true},
	["911.0"] = {sprite = path .. "altpath/rotgut_mouth.png", offset = Vector(-9, 0)},
	["911.1"] = {sprite = path .. "altpath/rotgut_maggot.png", offset = Vector(-5, 2)},
	["911.2"] = {sprite = path .. "altpath/rotgut_balls.png", offset = Vector(-4, 0)},
	["912.0"] = {
		sprite = path .. "final/mother.png",
		barStyle = "Mother",
		offset = Vector(-9, 0)
	},
	["912.10"] = {
		sprite = path .. "final/mother_phase2.png",
		barStyle = "Mother",
		offset = Vector(-8, 0)
	},
	["913.0"] = {
		sprite = path .. "altpath/min_min.png",
		conditionalSprites = {
			{"isI1Equal", path .. "altpath/min_min_phase2.png", {1}}
		},
		offset = Vector(-6, 0)
	},
	["914.0"] = {sprite = path .. "altpath/clog.png", offset = Vector(-7, 0)},
	["915.0"] = {sprite = path .. "altpath/singe.png", offset = Vector(-5, 0)},
	["916.0"] = {sprite = path .. "chapter2/bumbino.png", offset = Vector(-5, 0)},
	["917.0"] = {
		sprite = path .. "altpath/colostomia.png",
		barStyle = "Colostomia",
		conditionalSprites = {
			{"isHPSmallerPercent", path .. "altpath/colostomia_phase2.png", {40}}
		},
		offset = Vector(-8, -2)
	},
	["918.0"] = {sprite = path .. "altpath/turdlet.png", offset = Vector(-7, 0)},
	["919.0"] = {sprite = path .. "unused/raglich.png", offset = Vector(-5, 0)},
	["920.0"] = {sprite = path .. "altpath/horny_boys.png", offset = Vector(-5, -3)},
	["921.0"] = {
		sprite = path .. "altpath/clutch.png",
		conditionalSprites = {
			{"animationNameEqual", path .. "altpath/clutch_clicketyclack.png", {"Possess"}}
		},
		offset = Vector(-5, 0)
	},
	["922.0"] = {sprite = path .. "unused/cadavra.png", offset = Vector(-6, 0)},
	["950.1"] = {
		-- dogma tv phase
		sprite = path .. "final/dogma_tv.png",
		iconAnm2 = path .. "final/dogma_icon.anm2",
		iconAnimationType = "Animated",
		barStyle = "Dogma",
		offset = Vector(-10, 0)
	},
	["950.2"] = {
		-- dogma wing phase
		sprite = path .. "final/dogma_phase2.png",
		iconAnm2 = path .. "final/dogma_icon_64.anm2",
		iconAnimationType = "Animated",
		barStyle = "Dogma",
		offset = Vector(-3, 0)
	},
	["951.0"] = {
		sprite = path .. "final/beast.png",
		barStyle = "Beast",
		offset = Vector(-11, 0)
	},
	["951.10"] = {
		sprite = path .. "final/ultra_famine.png",
		iconAnm2 = path .. "bosshp_icon_64px.anm2",
		offset = Vector(-10, 0)
	},
	["951.20"] = {
		sprite = path .. "final/ultra_pestilence.png",
		iconAnm2 = path .. "bosshp_icon_64px.anm2",
		conditionalSprites = {
			{ "isHPSmallerPercent", path .. "final/ultra_pestilence_phase2.png", { 40 } }
		},
		offset = Vector(-10, 0)
	},
	["951.30"] = {
		sprite = path .. "final/ultra_war.png",
		iconAnm2 = path .. "bosshp_icon_64px.anm2",
		conditionalSprites = {
			{ "isHPSmallerPercent", path .. "final/ultra_war_phase2.png", { 50 } }
		},
		offset = Vector(-10, 0)
	},
	["951.40"] = {
		sprite = path .. "final/ultra_death.png",
		iconAnm2 = path .. "bosshp_icon_64px.anm2",
		offset = Vector(-10, 0)
	}
}
