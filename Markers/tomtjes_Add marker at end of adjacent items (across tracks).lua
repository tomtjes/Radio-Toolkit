--[[
Name:
    Add marker at end of adjacent items (across tracks)
Screenshot:
    https://raw.githubusercontent.com/tomtjes/Radio-Toolkit/c65335dcfe5f6b5eef1c7ff218efc7a8da79cd90/Regions/tomtjes_Create%20regions%20from%20adjacent%20items%20across%20tracks.gif
Author:
    tomtjes
Donation:
    https://ko-fi.com/tomtjes
Links:
    Github https://github.com/tomtjes/Radio-Toolkit
License:
    GPL v3
Version:
    1.6-pre1 2024-07-06
Changelog:
    ~ move functions to separate package
About:
    # Add marker at end of adjacent items (across tracks)
    Finds all contiguous groups of items that are less than a
    given number of seconds (default: 1) apart from each other. At the end of the last item in
    each group, a red "cue out" marker is added. 

    Evaluates items on selected tracks or all items if no tracks are selected.

    ## Installation

    - optional: modify gap value and extend value in first lines of code

    ## Usage

    - select track or tracks (optional)
    - run script

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

--======= CONFIG =================================--
Gap = 1 -- minimum distance (seconds) between items before they're considered not adjacent
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
    local tracks = GetTracks()
    local items = GetItems(tracks)

    -- start from end of project
    items = SortAsc(items)

    -- get all contiguous groups of items and save start time
    local markers = {}
    while #items > 0 do
        local last_of_group
        _, last_of_group, items = FindContAsc(items,Gap)
        -- create marker
        AddMarker(last_of_group[1].endpos)
    end
end -- END MAIN

function AddMarker(sec)
    reaper.AddProjectMarker2( 0, false, sec, -1, "cue out", -1, reaper.ColorToNative(250,0,0)|0x1000000 ) -- add marker
end

--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Add marker at end of adjacent items (across tracks)", -1)