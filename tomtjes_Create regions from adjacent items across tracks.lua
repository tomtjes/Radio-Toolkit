--[[
 * ReaScript Name: Create regions from adjacent items across tracks
 * Description: Creates regions that comprise all items that are less than a
                given number of seconds (default: 1) apart. The region render
                matrix gets adjusted to render the master track for the created
                regions. Regions are named and colored after track of first item
                in region.
 * Instructions: select track(s), run (modify gap value in first line if desired)
 * Screenshot URI:
 * Author: Thomas Reintjes
 * Author URI: https://reidio.io
 * Repository:
 * Repository URI: https://github.com/tomtjes/ReaScripts
 * File URI:
 * Licence: GPL v3
 * Forum Thread:
 * Forum Thread URl:
 * REAPER: 5.0
 * Extensions:
--]]

--[[
 * Changelog:
 * v1.0 (2020-09-11)
	+ Initial Release
--]]

--======= CONFIG =================================--
gap = 1 -- minimum distance (seconds) between items for a new region to be created
render = "master" -- options: "master", "tracks", "both"
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function main()
  local master, region, item, item_start, item_end
  local tracks = {}

  -- get master track
  master = reaper.GetMasterTrack( 0 )

  -- go to beginning of project
  reaper.SetEditCurPos2( 0, 0, false, false )

  -- get first item in project
  next_item = GetNextItem()
  next_item_start, _, next_item_end, track = StartLengthEndTrack(next_item)
  InitializeRegion()

  -- iterate over items until end of project
  while next_item ~= item do

    -- shift next item to item
    item, item_start, item_end = next_item, next_item_start, next_item_end

    -- if current item longer than region, extend region
    if region_end < item_end then
      region_end = item_end
    end

    if render == "tracks" or render == "both" then
    -- save track for render matrix
    tracks[track] = true
    end

    -- get next item
    next_item = GetNextItem()
    next_item_start, _, next_item_end, track = StartLengthEndTrack(next_item)

    -- reached end of project?
    if next_item == item then
      next_item_start = region_end + gap -- always create region for last item
    end

    -- create region now?
    if next_item_start - region_end >= gap then -- if gap to next item big enough
      region = reaper.AddProjectMarker2( 0, true, region_start, region_end, region_name, 0, region_color ) -- add region and save id

      -- adjust render matrix
      if render == "master" or render == "both" then
        reaper.SetRegionRenderMatrix( 0, region, master, 1 )
      end
      if render == "tracks" or render == "both" then
        for track, set in pairs(tracks) do
          if set == true then
            reaper.SetRegionRenderMatrix( 0, region, track, 1 )
            tracks[track]=false
          end
        end
      end

      -- start next region
      InitializeRegion()
    end
  end
end

function StartLengthEndTrack(item)
  local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local item_length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  local item_end = item_start + item_length
  local item_track = reaper.GetMediaItem_Track( item )
  return item_start, item_length, item_end, item_track
end

function InitializeRegion()
  region_start = next_item_start
  region_end = region_start
  _, region_name = reaper.GetTrackName( track )
  region_color = reaper.GetTrackColor( track )
end

function GetNextItem()
  reaper.Main_OnCommand(40417, 0) -- select next item
  local item = reaper.GetSelectedMediaItem( 0, 0 )
  return item
end

--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()

-- check # of tracks selected
local number_of_tracks_selected = reaper.CountSelectedTracks( 0 )
if number_of_tracks_selected == 0 then
  reaper.ShowMessageBox("No Tracks Selected.", "Error", 0)
  return
end

-- preserve edit cursor and selected items
local cursor = reaper.GetCursorPositionEx( 0 )
local selected_items = {}
local selected_items_count = reaper.CountSelectedMediaItems( 0 )
for i=1, selected_items_count do
  selected_items[i] = reaper.GetSelectedMediaItem( 0, i-1 )
end

main()

-- restore state
reaper.SetEditCurPos2(0, cursor, true, false)
for _,item in ipairs(selected_items) do
  reaper.SetMediaItemSelected( item, true )
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Create regions from adjacent items across tracks", -1)
