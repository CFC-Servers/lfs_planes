local conflictingAddons = {
    ["3032439287"] = true, -- LFS "InDev" error spamming reupload
    ["2966480781"] = true, -- LFS outdated reupload
    ["2608784717"] = true, -- LFS reupload, spams errors
}

timer.Simple( 60, function()
    for _, addon in ipairs( engine.GetAddons() ) do
        local wsid = addon.wsid
        if conflictingAddons[wsid] then
            if CLIENT then
                chat.AddText( Color( 255, 0, 0 ), "[LFS] ", Color( 255, 255, 255 ), "You have a conflicting addon installed please uninstall ", Color( 255, 122, 0 ), "https://steamcommunity.com/sharedfiles/filedetails/?id=" .. wsid )
            else
                print( "[LFS] You have a conflicting addon installed please uninstall https://steamcommunity.com/sharedfiles/filedetails/?id=" .. wsid )
            end
        end
    end
end )
