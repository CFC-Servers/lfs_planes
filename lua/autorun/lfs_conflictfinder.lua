local conflictingAddons = {
    ["3032439287"] = true, -- LFS "InDev" error spamming reupload
    ["2966480781"] = true, -- LFS outdated reupload
    ["2608784717"] = true, -- LFS reupload, spams errors
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
}

local timer_Simple = timer.Simple
local engine_GetAddons = engine.GetAddons
local ipairs = ipairs
local chat_AddText = chat.AddText
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
