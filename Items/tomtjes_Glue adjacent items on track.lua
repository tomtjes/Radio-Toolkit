--[[
 * Name: Glue adjacent items on track
 * Screenshot: https://github.com/tomtjes/ReaScripts/Items/tomtjes_Glue adjacent items on track.gif
 * Author: tomtjes
 * Donation: https://ko-fi.com/tomtjes
 * Links: Github https://github.com/tomtjes/ReaScripts
 * License: GPL v3
 * Version: 1.0 2020-09-11
 * Changelog: Initial Release 
@about
  # Glue adjacent items on track

  Glues all items on the same track that are less than a given number of seconds (default: 1) apart.

  ## Instructions

  - modify gap value in first line of code if desired
  - select track(s)
  - run script

  > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

--======= CONFIG =================================--
gap = 1 -- minimum distance (seconds) between items for them not to be glued
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function main(tracks)
  local number_of_items, item, item_start, item_end, next_item, next_item_start, next_item_end, selection_end

  -- iterate over tracks
  for track in pairs(tracks) do
    reaper.SetOnlyTrackSelected( track )

    number_of_items = reaper.CountTrackMediaItems( track )

    if number_of_items > 0 then

      -- get last item on track
      next_item = reaper.GetTrackMediaItem( track, number_of_items - 1 )
      next_item_start, _, next_item_end = StartLengthEnd(next_item)

      -- start group of items to glue
      selection_end = next_item_end

      -- iterate over items on track
      for j=number_of_items-1, 0, -1 do -- start from end of track

        -- shift next item to item
        item, item_start, item_end = next_item, next_item_start, next_item_end

        -- get next item (preceding item on track)
        next_item = reaper.GetTrackMediaItem( track, j-1 )
        if next_item ~= nil then
          next_item_start, _, next_item_end = StartLengthEnd(next_item)
        else -- reached first item on track
          next_item_end = item_start - gap -- always glue
        end

        -- glue now?
        if item_start - next_item_end >= gap then -- if gap to next item big enough
          reaper.GetSet_LoopTimeRange2(0, true, false, item_start, selection_end, false)
          reaper.SelectAllMediaItems( 0, false ) -- deselect all previously selected items
          reaper.Main_OnCommand(40718, 0) -- select all items on track in time selection
          reaper.Main_OnCommand(41588, 0) -- glue selected items
          selection_end = next_item_end -- start new group of items to glue
        end
      end
    end
  end
  reaper.SelectAllMediaItems( 0, false ) -- deselect items
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
  reaper.ShowMessageBox("No tracks selected.", "Error", 0)
  return
end

-- get selected tracks
local tracks = {}
for i=0, number_of_tracks_selected-1 do
  local track = reaper.GetSelectedTrack( 0, i )
  tracks[track] = true
end

reaper.Undo_BeginBlock()

-- preserve time selection, edit cursor and selected items
local ts_start, ts_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
local cursor = reaper.GetCursorPositionEx( 0 )
local selected_items = {}
local selected_items_count = reaper.CountSelectedMediaItems( 0 )
for i=0, selected_items_count-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  -- make sure item is not on a track where items will be glued
  local item_track = reaper.GetMediaItem_Track( item )
  if not tracks[item_track] then
    table.insert(selected_items, item)
  end
end

main(tracks)

-- restore state
reaper.GetSet_LoopTimeRange2(0, true, false, ts_start, ts_end, false)
reaper.SetEditCurPos2(0, cursor, true, false)
for _,item in ipairs(selected_items) do
  reaper.SetMediaItemSelected( item, true )
end
-- restore track selection
for track in pairs(tracks) do
  reaper.SetTrackSelected( track, true )
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Glue adjacent items on track", -1)
