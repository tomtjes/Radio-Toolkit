--[[
Name:
    Extend beginning of adjacent items (across tracks)
Screenshot:
    https://raw.githubusercontent.com/tomtjes/Radio-Toolkit/c65335dcfe5f6b5eef1c7ff218efc7a8da79cd90/Regions/tomtjes_Create%20regions%20from%20adjacent%20items%20across%20tracks.gif
Author:
    tomtjes
Donation:
    https://ko-fi.com/tomtjes
Links:
    Github https://github.com/tomtjes/Radio-Toolkit
Provides:
License:
    GPL v3
Version:
    1.3 2024-07-07
Changelog:
    ~ move functions to separate package
About:
    # Extend beginning of adjacent items (across tracks)

    Finds all contiguous groups of items that are less than a
    given number of seconds (default: 1) apart from each other. The first item in
    each group is then extended to the left by the given number of seconds (default: 2).

    Evaluates items on selected tracks or all items if no tracks are selected.

    ## Installation

    - optional: modify gap value and extend value in first lines of code

    ## Usage

    - select track or tracks (optional)
    - run script

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

--======= CONFIG =================================--
Gap = 1 -- maximum allowable distance (seconds) between items before they're considered not adjacent
Extend = 2 -- number of seconds to extend the first item of each group to the left
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--
local script_folder = debug.getinfo(1).source:match("@?(.*[\\/])")
script_folder = script_folder:match("^(.*[\\/])[^\\/]*[\\/]$") -- parent folder
local script_path = script_folder .. "Functions/tomtjes_Radio Toolkit Base.lua"

if reaper.file_exists(script_path) then
    dofile(script_path)
else
    reaper.MB("Missing base functions.\n Please install Radio Toolkit Base." .. script_path, "Error", 0)
    return
end

function Main()
    -- save original item selection
    local orig_items = GetSelectedItems()
    reaper.Main_OnCommand(40289, 0) -- clear item selection

    local tracks = GetTracks()
    local items = GetItems(tracks)
    items = SortDesc(items)
    while #items > 0 do
        local first_of_group
        first_of_group, _, items = FindContDesc(items,Gap)
        ExtendLeft(first_of_group,Extend)
    end

    -- restore item selection
    reaper.Main_OnCommand(40020, 0) -- clear time selection
    SetSelectedItems(orig_items)
end -- END MAIN

function ExtendLeft(items,sec)
    -- determine how much time to add
    local extmax = 0
    for _, item in ipairs(items) do
        extmax = math.max(extmax, item.offset) -- make sure take is long enough
    end
    extmax = math.min(extmax, sec)
    if extmax > 0.0001 then -- >0 doesn't work
        reaper.GetSet_LoopTimeRange2( 0, true, true, items[1].pos, items[1].pos+extmax, false )
        reaper.Main_OnCommand( 40200, 0 ) -- insert silence in time selection
        for _, item in ipairs(items) do
            local ext = math.min(extmax, item.offset)
            reaper.SetMediaItemSelected( item.item, true )
            reaper.SetEditCurPos2( 0, item.pos+extmax-ext, false, false )
            reaper.Main_OnCommand( 41305, 0 ) -- extend item left to cursor
            reaper.SetMediaItemSelected( item.item, false )
        end
    end
end

--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Extend beginning of adjacent items (across tracks)", -1)
