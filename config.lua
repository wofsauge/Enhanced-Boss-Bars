HPBars.UserConfig = {
    -- Design the HP Bar should use.
    -- Look into the bossbar_data.lua file in the HPBars.BarStyles table for all possible options.
    -- Default value: "Default"
    ["BarStyle"] = "Default",
    -- Positioning of the bar on the screen.
    -- Possible Values: [Top, Bottom, Left, Right]
    -- Default value: "Bottom"
    ["Position"] = "Bottom",
    -- Sorting of the bar. This can have the following options:
    --      "Segments": Shows one bar for each boss and their segments
    --      "Bosses":   Shows one bar for each boss, but summarizes segmented bosses into one boss
    --      "Vanilla":  Shows only one bar and summarizes all bosses into that one bar
    -- Default value: "Segments"
    ["Sorting"] = "Segments",
    -- Toggle if icons should be shown at all
    -- Default value: true
    ["ShowIcons"] = true,
    -- Toggle if boss specific icons should be shown. If this option is set to false, it will display the vanilla icon
    -- Default value: true
    ["ShowCustomIcons"] = true,
    -- Toggle if status effects should be displayed
    -- Default value: true
    ["ShowStatusEffects"] = true,
    -- Allows some bosses to use their special boss bar designs
    -- Default value: true
    ["EnableSpecificBossbars"] = true,
    -- Shows additional notches on the bar
    -- Default value: false
    ["ShowNotches"] = false,
    -- Defines how many bars should be displayed per row
    -- Default value: 7
    ["BarsPerRow"] = 7,
    -- Defines the distance between two bars
    -- Default value: 15
    ["BarPadding"] = 15,
    -- Defines the distance the bar and the edge of the screen
    -- Default value: 17
    ["ScreenPadding"] = 17,
    -- Enables the flashing of the bars, when the enemy gets hit or heals itself
    -- Default value: true
    ["EnableFlashing"] = true,
    -- Enables a white coloring of the bars, when the enemy is invincible
    -- Default value: true
    ["EnableInvicibilityIndication"] = true,
    -- If the boss is a champion and this is enabled, the icon will be colored the same way as the boss
    -- Default value: true
    ["UseChampionColors"] = true,
    -- Disable bars when the player has the Spidermod item
    -- Default value: true
    ["DisplayWithSpidermod"] = true,

    ---------------------------------
    --------- Boss Specific ---------
    -- Shows the Hp bar for Beast and its companions
    -- Default value: true
    ["ShowInBeastFight"] = true,
    -- Shows the Hp bar for Mother
    -- Default value: true
    ["ShowInMotherFight"] = true,
    -- Shows the Hp bar for Mega Satan
    -- Default value: true
    ["ShowMegaSatan"] = true,

    ---------------------------------
    ----------- Info text -----------
    -- Allows some bosses to use their special boss bar designs
    -- Possible Values: [None, Percent, HPLeft]
    -- Default value: "None"
    ["InfoText"] = "None",
    -- Changes the transparency of the info text
    -- Possible Values between 0 and 1
    -- Default value: 1
    ["TextTransparency"] = 1,
    -- Changes the size of the info text
    -- Possible Values between 0 and 1
    -- Default value: 0.5
    ["TextSize"] = 0.5,
}


--END CONFIG--
-----------
-----------

--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
-------- DO NOT EDIT FROM THIS POINT!!!!! --------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------
--------------------------------------------------

HPBars.PresetConfigs = {}

HPBars.PresetConfigs.Default = {
    ["BarStyle"] = "Default",
    ["Position"] = "Bottom",
    ["Sorting"] = "Segments",
    ["EnableSpecificBossbars"] = true,
    ["ShowNotches"] = false,
    ["BarsPerRow"] = 7,
    ["BarPadding"] = 15,
    ["ScreenPadding"] = 17,
    ["EnableFlashing"] = true,
    ["EnableInvicibilityIndication"] = true,
    ["DisplayWithSpidermod"] = true,

    ["ShowIcons"] = true,
    ["ShowCustomIcons"] = true,
    ["UseChampionColors"] = true,
    ["ShowStatusEffects"] = true,

    ["ShowInBeastFight"] = true,
    ["ShowInMotherFight"] = true,
    ["ShowMegaSatan"] = true,

    ["InfoText"] = "None",
    ["TextTransparency"] = 1,
    ["TextSize"] = 0.5,

    ["_MCMTooltip"] = {"Recommended settings", "Enhances the gameplay and adds a lot of QoL features"},
}

HPBars.PresetConfigs.Vanilla = {
    ["BarStyle"] = "Default",
    ["Position"] = "Bottom",
    ["Sorting"] = "Vanilla",
    ["EnableSpecificBossbars"] = false,
    ["ShowNotches"] = false,
    ["BarsPerRow"] = 7,
    ["BarPadding"] = 15,
    ["ScreenPadding"] = 17,
    ["EnableFlashing"] = true,
    ["EnableInvicibilityIndication"] = false,
    ["DisplayWithSpidermod"] = true,

    ["ShowIcons"] = true,
    ["ShowCustomIcons"] = false,
    ["UseChampionColors"] = false,
    ["ShowStatusEffects"] = false,

    ["ShowInBeastFight"] = false,
    ["ShowInMotherFight"] = false,
    ["ShowMegaSatan"] = false,

    ["InfoText"] = "None",
    ["TextTransparency"] = 1,
    ["TextSize"] = 0.5,

    ["_MCMTooltip"] = {"Vanilla experience", "Tries to emulate the exact behavior as it is in the main game"},
}
HPBars.PresetConfigs.Antibirth = {
    ["BarStyle"] = "Default",
    ["Position"] = "Top",
    ["Sorting"] = "Vanilla",
    ["EnableSpecificBossbars"] = false,
    ["ShowNotches"] = false,
    ["BarsPerRow"] = 7,
    ["BarPadding"] = 15,
    ["ScreenPadding"] = 17,
    ["EnableFlashing"] = true,
    ["EnableInvicibilityIndication"] = false,
    ["DisplayWithSpidermod"] = true,

    ["ShowIcons"] = true,
    ["ShowCustomIcons"] = false,
    ["UseChampionColors"] = false,
    ["ShowStatusEffects"] = false,

    ["ShowInBeastFight"] = false,
    ["ShowInMotherFight"] = true,
    ["ShowMegaSatan"] = false,

    ["InfoText"] = "None",
    ["TextTransparency"] = 1,
    ["TextSize"] = 0.5,

    ["_MCMTooltip"] = {"Antibirth experience", "Same as Vanilla, but the bar is on top of the screen"},
}