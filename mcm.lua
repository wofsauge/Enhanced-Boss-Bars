-- MOD CONFIG MENU Compatibility
local MCMLoaded, MCM = pcall(require, "scripts.modconfig")
HPBars.MCMLoaded = MCMLoaded
if MCMLoaded then
	function AnIndexOf(t, val)
		for k, v in ipairs(t) do
			if v == val then
				return k
			end
		end
		return 1
	end

    function HPBars:isMCMVisible()
        return MCM.IsVisible
    end

    local function addDummyBar()
		if not HPBars.currentBosses[GetPtrHash(Isaac.GetPlayer())] then
            HPBars:createNewBossBar(Isaac.GetPlayer())
        end
    end

	local mcmName = "Enhanced Boss Bars"
	---------------------------------------------------------------------------
	-----------------------------------Info------------------------------------
	MCM.AddSpace(mcmName, "Info")
	MCM.AddText(mcmName, "Info", function() return "Enhanced Boss Bars" end)
	MCM.AddSpace(mcmName, "Info")
	MCM.AddText(mcmName, "Info", function() return "Version "..HPBars.Version end)
	MCM.AddSpace(mcmName, "Info")
	MCM.AddText(mcmName, "Info", function() return "by Wofsauge & Blind" end)
	MCM.AddSpace(mcmName, "Info")

	---------------------------------------------------------------------------
	---------------------------------Presets-----------------------------------
	MCM.AddText(mcmName, "Presets", function() return "Apply a Preset configuration" end)
	MCM.AddSpace(mcmName, "Presets")

	
    local availablePresets = {}
    for k,v in pairs(HPBars.PresetConfigs) do
        table.insert(availablePresets,k)
    end
	local selectedPreset = 1
    table.sort(availablePresets)
	local presetTooltips = {
		["Default"] = {"Recommended settings", "Enhances the gameplay and adds a lot of QoL features"},
		["Vanilla"] = {"Vanilla experience", "Tries to emulate the exact behavior as it is in the main game"},
		["Antibirth"] = {"Antibirth experience", "Same as Vanilla, but the bar is on top of the screen"}
	}

    MCM.AddSetting(
        mcmName,
        "Presets",
        {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return AnIndexOf(availablePresets, selectedPreset)
            end,
            Minimum = 1,
            Maximum = #availablePresets,
            Display = function()
                return availablePresets[selectedPreset]
            end,
            OnChange = function(currentNum)
				selectedPreset = currentNum == selectedPreset and 1 or currentNum
            end,
            Info = function() return presetTooltips[availablePresets[selectedPreset]] end
        }
    )

	MCM.AddSpace(mcmName, "Presets")

	MCM.AddSetting(
		mcmName,
		"Presets",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function() return true end,
			Display = function() return "--> APPLY PRESET" end,
			OnChange = function(currentBool)
				HPBars.Config = HPBars.PresetConfigs[availablePresets[selectedPreset]]
			end,
			Info = {"Press SPACE to apply the changes"}
		}
	)

	---------------------------------------------------------------------------
	---------------------------------General-----------------------------------
    -- Bar Style
    local availableStyles = {}
    for k,v in pairs(HPBars.BarStyles) do
        table.insert(availableStyles,k)
    end
    table.sort(availableStyles)
    MCM.AddSetting(
        mcmName,
        "General",
        {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return AnIndexOf(availableStyles, HPBars.Config["BarStyle"])
            end,
            Minimum = 1,
            Maximum = #availableStyles,
            Display = function()
                addDummyBar()
                return "Style: " .. HPBars.Config["BarStyle"]
            end,
            OnChange = function(currentNum)
                HPBars:removeBarEntry(Isaac.GetPlayer())
                HPBars.Config["BarStyle"] = availableStyles[currentNum]
            end,
            Info = function() return {HPBars.BarStyles[HPBars.Config["BarStyle"]].tooltip or "", " ("..AnIndexOf(availableStyles, HPBars.Config["BarStyle"]).."/"..#availableStyles..")"} end
        }
    )
	-- Bar Positioning
	local positions = {"Bottom", "Top", "Left","Right"}
	MCM.AddSetting(
		mcmName,
		"General",
		{
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return AnIndexOf(positions, HPBars.Config["Position"])
			end,
			Minimum = 1,
			Maximum = #positions,
			Display = function()
				return "Position: " .. HPBars.Config["Position"]
			end,
			OnChange = function(currentNum)
                HPBars:removeBarEntry(Isaac.GetPlayer())
				HPBars.Config["Position"] = positions[currentNum]
			end,
			Info = {"General position of the boss bar"}
		}
	)
	-- Sorting mode
	local sortingModes = {"Segments", "Bosses", "Vanilla"}
	local sortingModesTooltips = {"Segments: Boss-segments have their own bars", "Bosses: Each boss has their own bar, segmented bosses only have one bar", "Vanilla: One bar for all bosses"}
	MCM.AddSetting(
		mcmName,
		"General",
		{
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return AnIndexOf(sortingModes, HPBars.Config["Sorting"])
			end,
			Minimum = 1,
			Maximum = #sortingModes,
			Display = function()
				return "Sorting: " .. HPBars.Config["Sorting"]
			end,
			OnChange = function(currentNum)
                HPBars:removeBarEntry(Isaac.GetPlayer())
				HPBars.Config["Sorting"] = sortingModes[currentNum]
			end,
			Info = function() return {"Sorting of the boss bars",sortingModesTooltips[AnIndexOf(sortingModes, HPBars.Config["Sorting"])]} end
		}
	)
	-- Toggle Notches
	MCM.AddSetting(
		mcmName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["ShowNotches"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["ShowNotches"] then
					onOff = "True"
				end
				return "Show notches: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["ShowNotches"] = currentBool
			end,
			Info = { "Toggle the display of notches on the boss bars"}
		}
	)
	-- Bar padding
	MCM.AddSetting(
        mcmName,
        "General",
		{
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return HPBars.Config["BarPadding"]
			end,
			Minimum = 0,
			Maximum = 100,
			Display = function()
				return "Bar padding: " .. HPBars.Config["BarPadding"]
			end,
			OnChange = function(currentNum)
				HPBars.Config["BarPadding"] = currentNum
			end,
			Info = {"Distance between two bars"}
		}
	)
	-- Screen padding
	MCM.AddSetting(
        mcmName,
        "General",
		{
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return HPBars.Config["ScreenPadding"]
			end,
			Minimum = 0,
			Maximum = 100,
			Display = function()
				return "Screen padding: " .. HPBars.Config["ScreenPadding"]
			end,
			OnChange = function(currentNum)
				HPBars.Config["ScreenPadding"] = currentNum
			end,
			Info = {"Distance between the bars and the screen"}
		}
	)
	-- Bars per Row
	MCM.AddSetting(
        mcmName,
        "General",
		{
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return HPBars.Config["BarsPerRow"]
			end,
			Minimum = 1,
			Maximum = 20,
			Display = function()
				return "Bars per row: " .. HPBars.Config["BarsPerRow"]
			end,
			OnChange = function(currentNum)
				HPBars.Config["BarsPerRow"] = currentNum
			end,
			Info = {"Number of bars per row displayed"}
		}
	)
	-- Enable Flashing
	MCM.AddSetting(
		mcmName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["EnableFlashing"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["EnableFlashing"] then
					onOff = "True"
				end
				return "Enable Flashing: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["EnableFlashing"] = currentBool
			end,
			Info = {"Enables / disables flashing of the bar when hit or healed"}
		}
	)
	-- Show with Spidermod
	MCM.AddSetting(
		mcmName,
		"General",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["DisplayWithSpidermod"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["DisplayWithSpidermod"] then
					onOff = "True"
				end
				return "Show with spidermod: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["DisplayWithSpidermod"] = currentBool
			end,
			Info = {"Enables / disables the bars, when the player has the spidermod item"}
		}
	)


	-- Text Mode
	local textModes = {"None", "Percent", "HPLeft"}
    MCM.AddSetting(
        mcmName,
        "General",
        {
            Type = ModConfigMenu.OptionType.NUMBER,
            CurrentSetting = function()
                return AnIndexOf(textModes, HPBars.Config["InfoText"])
            end,
            Minimum = 1,
            Maximum = #textModes,
            Display = function()
                return "Text Display: " .. HPBars.Config["InfoText"]
            end,
            OnChange = function(currentNum)
                HPBars.Config["InfoText"] = textModes[currentNum]
            end,
            Info = {"Mode that can display text-informations on the bar"}
        }
    )

	-- Text Transparency
	MCM.AddSetting(
        mcmName,
        "General",
		{
			Type = ModConfigMenu.OptionType.NUMBER,
			CurrentSetting = function()
				return HPBars.Config["TextTransparency"] * 10
			end,
			Minimum = 0,
			Maximum = 10,
			Display = function()
				return "Text Transparency: " .. HPBars.Config["TextTransparency"]
			end,
			OnChange = function(currentNum)
				HPBars.Config["TextTransparency"] = currentNum / 10
			end,
			Info = {"Changes the transparency of the info text"}
		}
	)

	---------------------------------------------------------------------------
	----------------------------------Icons------------------------------------

	-- Toggle icons
	MCM.AddSetting(
		mcmName,
		"Icons",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["ShowIcons"]
			end,
			Display = function()
                addDummyBar()
				local onOff = "False"
				if HPBars.Config["ShowIcons"] then
					onOff = "True"
				end
				return "Show Icons: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["ShowIcons"] = currentBool
			end,
		}
	)

	-- Toggle custom icons
	MCM.AddSetting(
		mcmName,
		"Icons",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["ShowCustomIcons"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["ShowCustomIcons"] then
					onOff = "True"
				end
				return "Show custom Icons: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["ShowCustomIcons"] = currentBool
			end,
			Info = { "Toggle if boss specific icons should be shown","Will display the vanilla icon otherwise"}
		}
	)

	-- Enable Champion coloring
	MCM.AddSetting(
		mcmName,
		"Icons",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["UseChampionColors"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["UseChampionColors"] then
					onOff = "True"
				end
				return "Use Champion coloring: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["UseChampionColors"] = currentBool
			end,
			Info = { "If enabled, applies the champion color of the boss to the boss bar icon"}
		}
	)

	---------------------------------------------------------------------------
	----------------------------------Bosses-----------------------------------

	-- Enable Beast Fight
	MCM.AddSetting(
		mcmName,
		"Bosses",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["ShowInBeastFight"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["ShowInBeastFight"] then
					onOff = "True"
				end
				return "Enable in Beast fight: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["ShowInBeastFight"] = currentBool
			end,
			Info = {"Enables / disables the bar for the Beast fight"}
		}
	)
	-- Enable Mother
	MCM.AddSetting(
		mcmName,
		"Bosses",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["ShowInMotherFight"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["ShowInMotherFight"] then
					onOff = "True"
				end
				return "Enable in Mother fight: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["ShowInMotherFight"] = currentBool
			end,
			Info = {"Enables / disables the bar for the Mother fight"}
		}
	)
	-- Enable Mega Satan
	MCM.AddSetting(
		mcmName,
		"Bosses",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["ShowMegaSatan"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["ShowMegaSatan"] then
					onOff = "True"
				end
				return "Enable Mega Satan: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["ShowMegaSatan"] = currentBool
			end,
			Info = {"Toggles the bars in the Mega Satan fight"}
		}
	)
	-- Toggle boss designs
	MCM.AddSetting(
		mcmName,
		"Bosses",
		{
			Type = ModConfigMenu.OptionType.BOOLEAN,
			CurrentSetting = function()
				return HPBars.Config["EnableSpecificBossbars"]
			end,
			Display = function()
				local onOff = "False"
				if HPBars.Config["EnableSpecificBossbars"] then
					onOff = "True"
				end
				return "Enable boss specific bars: " .. onOff
			end,
			OnChange = function(currentBool)
				HPBars.Config["EnableSpecificBossbars"] = currentBool
			end,
			Info = {"Allows some bosses to use their special boss bar designs"}
		}
	)
end
