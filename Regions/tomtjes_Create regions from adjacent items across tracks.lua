--[[
Name:
    Create regions from adjacent items across tracks
Screenshot:
    https://raw.githubusercontent.com/tomtjes/Radio-Toolkit/c65335dcfe5f6b5eef1c7ff218efc7a8da79cd90/Regions/tomtjes_Create%20regions%20from%20adjacent%20items%20across%20tracks.gif
Author:
    tomtjes
Donation:
    https://ko-fi.com/tomtjes
Links:
    Github https://github.com/tomtjes/Radio-Toolkit
Provides:
    [data] toolbar_icons/tomtjes_toolbar_region_adjacent_items_across_tracks.png > toolbar_icons/tomtjes_toolbar_region_adjacent_items_across_tracks.png
License:
    GPL v3
Version:
    1.3 2024-07-07
Changelog:
    ~ move functions to separate package
About:
    # Create regions from adjacent items across tracks

    Creates regions that comprise all items that are less than a
    given number of seconds (default: 1) apart. The region render
    matrix gets adjusted to render the respective tracks for the created
    regions and/or the master track (configurable). Regions are colored after 
    the upmost track. Names are concatenated from all tracks that have items 
    in this region. 

    Evaluates items on selected tracks or all items if no tracks are selected.

    ## Installation

    - optional: modify Gap value and Render setting in first lines of code
    - optional: add included icon to toolbar: `tomtjes_toolbar_region_adjacent_items_across_tracks.png`

    ## Usage

    - select track or tracks (optional)
    - run script

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

--======= CONFIG =================================--
Gap = 1 -- maximum allowable distance (seconds) between items before a new region gets created
Render = "tracks" -- options: "master", "tracks", "both"
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
    Tracks = GetTracks()

    local items = GetItems(Tracks)
    items = SortAsc(items)

    while #items > 0 do
        local first_of_group, last_of_group, trks
        first_of_group, last_of_group, items, trks = FindContAsc(items,Gap)
        local region = AddRegion(first_of_group[1].pos, last_of_group[1].endpos, trks)
        AdjustRenderMatrix(region, trks)
    end
end -- END MAIN

function AddRegion(start,stop,tracks)
    -- region name and color defined by tracks in project order
    local name = ""
    local color = ""
    local trks = {}

    for t, _ in pairs(tracks) do -- make track table sortable/indexed
        trks[#trks+1] = t
    end
    -- lower track numbers should take precedence in color and name
    if #trks > 1 then
        table.sort(trks, function( a,b )
            if (Tracks[a].num < Tracks[b].num) then
                -- primary sort on position -> a before b
                return true
            else
                return false
            end
        end)
    end

    for _, trk in ipairs(trks) do
        name = name .. Tracks[trk].name
        if color == "" then
            color = Tracks[trk].color
        end
    end
    return reaper.AddProjectMarker2( 0, true, start, stop, name, 1, color ) -- add region and save id
end

function AdjustRenderMatrix(region, tracks)
    -- adjust render matrix
    if Render == "master" or Render == "both" then
        local master = reaper.GetMasterTrack(0)
        reaper.SetRegionRenderMatrix( 0, region, master, 1 )
    end
    for trk, _ in pairs(tracks) do
        if Render == "tracks" or Render == "both" then
            reaper.SetRegionRenderMatrix( 0, region, trk, 1 )
        end
    end
end

--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Create regions from adjacent items across tracks", -1)