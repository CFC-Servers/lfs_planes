local conflictingAddons = {
    ["3032439287"] = true, -- LFS "InDev" error spamming reupload
    ["2966480781"] = true, -- LFS outdated reupload
    ["3032130287"] = true, -- LFS reupload
    ["2973559699"] = true, -- Reupload
    ["3026434172"] = true, -- Reupload
    ["2930266401"] = true, -- Reupload
    ["2966734549"] = true, -- Starwars Reupload
    ["2966460842"] = true, -- Reupload
    ["2992466189"] = true, -- Reupload
    ["2926912443"] = true, -- Reupload
    ["1922346958"] = true, -- Reupload
    ["2966459642"] = true, -- Reupload
    ["3051150781"] = true, -- Reupload
    ["2945559308"] = true, -- Starwars reupload
    ["2888564559"] = true, -- Simfphys and LFS reupload
    ["2984271396"] = true, -- Reupload

    -- Found using https://gmod-archive.cheetah.cat/#/file_relations/ thanks to @cheetahdotcat
    -- Reuploads of lfs_basescript.lua and other crucial lfs files
    ["2829073644"] = true,
    ["2069109534"] = true,
    ["2269880345"] = true,
    ["2161114272"] = true,
    ["2151185391"] = true,
    ["2146084653"] = true,
    ["2707226213"] = true,
    ["2325614914"] = true,
    ["2903926541"] = true,
    ["2894186543"] = true,
    ["2889133221"] = true,
    ["2888564559"] = true,
    ["2888228306"] = true,
    ["2881549420"] = true,
    ["2880408560"] = true,
    ["2878863393"] = true,
    ["2877653550"] = true,
    ["2876376550"] = true,
    ["2873148626"] = true,
    ["1674191534"] = true,
    ["1922346958"] = true,
    ["2786936190"] = true,
    ["2904112707"] = true,
    ["2074073623"] = true,
    ["1933911949"] = true,
    ["1608143666"] = true,
    ["2002862434"] = true,
    ["2869147496"] = true,
    ["1975234016"] = true,
    ["1973950819"] = true,
    ["1997086471"] = true,
    ["1951516762"] = true,
    ["2637869858"] = true,
    ["2819083821"] = true,
    ["2662591369"] = true,
    --[""] = true,
}

local timer_Simple = timer.Simple
local engine_GetAddons = engine.GetAddons
local ipairs = ipairs
local chat_AddText = CLIENT and chat.AddText
local print = print

local colorRed = Color( 255, 0, 0 )
local colorWhite = Color( 255, 255, 255 )
local colorOrange = Color( 255, 122, 0 )

timer_Simple( 60, function()
    for _, addon in ipairs( engine_GetAddons() ) do
        local wsid = addon.wsid
        if conflictingAddons[wsid] then
            if CLIENT then
                chat_AddText( colorRed, "[LFS] ", colorWhite, "You have a conflicting addon installed please uninstall ", colorOrange, "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. wsid )
            else
                print( "[LFS] You have a conflicting addon installed please uninstall https://steamcommunity.com/sharedfiles/filedetails/?id=" .. wsid )
            end
        end
    end
end )
