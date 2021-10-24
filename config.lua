HPBars.UserConfig = {
    -- Design the HP Bar should use.
    -- Look into the bossbar_data.lua file in the HPBars.BarStyles table for all possible options.
    -- Default value: "Default"
    ["BarStyle"] = "Default",
    -- Positioning of the bar on the screen.
    -- Possible Values: [Top, Bottom, Left, Right]
    -- Default value: "Bottom"
    ["Position"] = "Bottom",
    -- Toggle if icons should be shown at all
    -- Default value: true
    ["ShowIcons"] = true,
    -- Allows some bosses to use their special boss bar designs
    -- Default value: true
    ["EnableSpecificBossbars"] = true,
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

    ---------------------------------
    --------- Boss Specific ---------
    -- Shows the Hp bar for Dark Esau ghost
    -- Default value: true
    ["ShowDarkEsau"] = true,
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


HPBars.DefaultConfig = {
    ["BarStyle"] = "Default",
    ["Position"] = "Bottom",
    ["ShowIcons"] = true,
    ["EnableSpecificBossbars"] = true,
    ["BarsPerRow"] = 7,    
    ["BarPadding"] = 15,
    ["ScreenPadding"] = 17,
    ["EnableFlashing"] = true,
    ["ShowDarkEsau"] = true,
    ["ShowInBeastFight"] = true,
    ["ShowInMotherFight"] = true,
    ["ShowMegaSatan"] = true,
    ["InfoText"] = "None",
    ["TextTransparency"] = 1,
}