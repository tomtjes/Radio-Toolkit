--[[
 * ReaScript Name: Create regions from adjacent items on same track
 * Description: Creates regions that comprise all items on the same track that
                are less than a given number of seconds (default: 1) apart. The
                region render matrix gets adjusted to only render the respective
                tracks for the created regions. Regions are named and colored
                after their track.
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
render = "track" -- options: "master", "tracks", "both"
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function main()
  -- get master track
  local master = reaper.GetMasterTrack( 0 )

  -- iterate over tracks
  for _,track in ipairs(tracks) do
    local region, region_start, region_name, region_color, number_of_items, item, item_start, item_end, next_item, next_item_start, next_item_end

    reaper.SetOnlyTrackSelected( track )

    region_color = reaper.GetTrackColor( track )
    _, region_name = reaper.GetTrackName( track )

    number_of_items = reaper.CountTrackMediaItems( track )

    -- get first item on track
    next_item = reaper.GetTrackMediaItem( track, 0 )
    next_item_start, _, next_item_end = StartLengthEnd(next_item)

    -- start first region
    region_start = next_item_start

    -- iterate over items on track
    for j=1, number_of_items do

      -- shift next item to item
      item, item_start, item_end = next_item, next_item_start, next_item_end

      -- get next item on track
      next_item = reaper.GetTrackMediaItem( track, j )
      if next_item ~= nil then
        next_item_start, _, next_item_end = StartLengthEnd(next_item)
      else -- reached end of track
        next_item_start = item_end + gap + 1 -- always create region for last item
      end

      -- create region now?
      if next_item_start - item_end >= gap then -- if gap to next item big enough
        region = reaper.AddProjectMarker2( 0, true, region_start, item_end, region_name, 0, region_color ) -- add region and save id
        reaper.SetRegionRenderMatrix( 0, region, track, 1 )

        -- adjust render matrix
        if render == "master" or render == "both" then
          reaper.SetRegionRenderMatrix( 0, region, master, 1 )
        end
        if render == "tracks" or render == "both" then
          reaper.SetRegionRenderMatrix( 0, region, track, 1 )
        end

        -- start next region
        region_start = next_item_start
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

-- check # of tracks selected
local number_of_tracks_selected = reaper.CountSelectedTracks( 0 )
if number_of_tracks_selected == 0 then
  reaper.ShowMessageBox("No Tracks Selected.", "Error", 0)
  return
end

reaper.Undo_BeginBlock()

-- save selected tracks
tracks = {}
for i=1, number_of_tracks_selected do
  tracks[i] = reaper.GetSelectedTrack( 0, i-1 )
end

main()

-- restore track selection
for _,track in ipairs(tracks) do
  reaper.SetTrackSelected( track, true )
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Create regions from adjacent items on same track", -1)
