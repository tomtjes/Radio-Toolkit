--[[
  Name: Create regions from adjacent items on same track
  Screenshot: https://github.com/tomtjes/ReaScripts/Regions/tomtjes_Create regions from adjacent items on same track.gif
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/ReaScripts
  Provides:
    [data] toolbar_icons/tomtjes_toolbar_region_adjacent_items_same_track.png > toolbar_icons/tomtjes_toolbar_region_adjacent_items_same_track.png
  License: GPL v3
  Version: 1.0.2 2022-01-28
  Changelog:
    ~ fix region numbering (start with 1 instead of 0)
    - remove requirement to select tracks, apply script to all tracks if none selected
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
gap = 1 -- minimum distance (seconds) between items for a new region to be created
render = "tracks" -- options: "master", "tracks", "both"
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function main()
  local region, region_start, region_end, region_name, region_color, number_of_items, item, item_start, item_end
  -- get master track
  local master = reaper.GetMasterTrack( 0 )

  -- check # of tracks selected
  local tracks = {}
  local number_of_tracks = reaper.CountSelectedTracks(0)
  if number_of_tracks == 0 then
    number_of_tracks = reaper.CountTracks(0)
    for i=1, number_of_tracks do
      tracks[i] = reaper.GetTrack(0, i-1)
    end
  else
    for i=1, number_of_tracks do
      tracks[i] = reaper.GetSelectedTrack( 0, i-1 )
    end
  end

  -- iterate over tracks
  for _,track in ipairs(tracks) do
  
    region_color = reaper.GetTrackColor( track )
    _, region_name = reaper.GetTrackName( track )

    number_of_items = reaper.CountTrackMediaItems( track )

    -- get first item on track
    item = reaper.GetTrackMediaItem( track, 0 )
    item_start, _, item_end = StartLengthEnd(item)

    -- start first region
    region_start = item_start
    region_end = item_end

    -- iterate over items on track
    for j=1, number_of_items do

      -- get next item on track
      item = reaper.GetTrackMediaItem( track, j )
      if item ~= nil then
        item_start, _, item_end = StartLengthEnd(item)
      else -- reached end of track
        item_start = region_end + gap + 1 -- always create region for last item
      end

      -- create region now?
      if item_start - region_end >= gap then -- if gap to next item big enough
        region = reaper.AddProjectMarker2( 0, true, region_start, region_end, region_name, 1, region_color ) -- add region and save id

        -- adjust render matrix
        if render == "master" or render == "both" then
          reaper.SetRegionRenderMatrix( 0, region, master, 1 )
        end
        if render == "tracks" or render == "both" then
          reaper.SetRegionRenderMatrix( 0, region, track, 1 )
        end

        -- start next region
        region_start = item_start
      end

      -- extend region?
      if item_end > region_end then
        region_end = item_end
      end
    end
  end
end

function StartLengthEnd(item)
  local item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local item_length = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  local item_end = item_start + item_length
  return item_start, item_length, item_end
end

--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()

main()

reaper.UpdateArrange()
reaper.Undo_EndBlock("Create regions from adjacent items on same track", -1)
