--[[
  Name: Create regions from adjacent items on same track
  Screenshot: https://github.com/tomtjes/Radio-Toolkit/blob/master/Regions/tomtjes_Create%20regions%20from%20adjacent%20items%20on%20same%20track.gif
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  Provides:
    [data] toolbar_icons/tomtjes_toolbar_region_adjacent_items_same_track.png > toolbar_icons/tomtjes_toolbar_region_adjacent_items_same_track.png
  License: GPL v3
  Version: 1.1-pre2 2024-07-06
  Changelog:
    ~ move functions to separate package
  About:
    # Create regions from adjacent items on same track

    Creates regions that comprise all items on the same track that are 
    less than a given number of seconds (default: 1) apart. The region render
    matrix gets adjusted to render the respective tracks for the created
    regions and/or the master track (configurable). Regions are named and 
    colored after track of first item in region.

    Evaluates items on selected tracks or all items if no tracks are selected.

    ## Installation

    - optional: modify gap value and render setting in first lines of code
    - optional: add included icon to toolbar: `tomtjes_toolbar_region_adjacent_items_same_track.png`

    ## Usage

    - select track or tracks (optional)
    - run script

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

--======= CONFIG =================================--
Gap = 1 -- minimum distance (seconds) between items for a new region to be created
render = "tracks" -- options: "master", "tracks", "both"
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

  -- get items per track
  for track, _ in pairs(Tracks) do
    -- create sub-table with just one track
    local t = {}
    t[track] = Tracks[track]
    local items = GetItems(t)
    items = SortAsc(items)

    while #items > 0 do
      local first_of_group, last_of_group
      first_of_group, last_of_group, items, _ = FindContAsc(items,Gap)
      local region = AddRegion(first_of_group[1].pos, last_of_group[1].endpos, track)
      AdjustRenderMatrix(region, track)
    end
  end
end

function AddRegion(start,stop,track)
  -- region name and color defined by tracks in project order
  local name = Tracks[track].name
  local color = Tracks[track].color
  return reaper.AddProjectMarker2( 0, true, start, stop, name, 1, color ) -- add region and return id
end

function AdjustRenderMatrix(region, track)
  if Render == "master" or Render == "both" then
      local master = reaper.GetMasterTrack(0)
      reaper.SetRegionRenderMatrix( 0, region, master, 1 )
  end
  if Render == "tracks" or Render == "both" then
      reaper.SetRegionRenderMatrix( 0, region, track, 1 )
  end
end
--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Create regions from adjacent items on same track", -1)