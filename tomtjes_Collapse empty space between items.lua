--[[
 * ReaScript Name: Collapse empty space between items
 * Description: Reduces gaps between items to a set maximum length. Items are moved left.
                Ripple Edit modes are being respected. The script works on selected items.
                If items across multiple tracks are selected, they are evaluated as if they
                were on the same track, meaning a gap is only a gap if it spans all tracks
                that selected items are in. If no items are selected, the script works on
                selected tracks, collapsing gaps on each selected track individually. 
 * Instructions: select items or tracks, run (modify gap value in first line if desired)
 * Screenshot URI:
 * Author: Thomas Reintjes
 * Author URI: https://ko-fi.com/tomtjes
 * Repository:
 * Repository URI: https://github.com/tomtjes/ReaScripts
 * File URI:
 * Licence: GPL v3
 * Forum Thread:
 * Forum Thread URl:
 * REAPER: 7.0
 * Extensions:
--]]

--[[
 * Changelog:
 * v1.0 (2023-10-22)
	+ Initial Release
--]]

--======= CONFIG =================================--
-- collapse gaps larger than
max_gap = 1.0
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function GetSelectedItems()
    local items = {}
    local itemcount = reaper.CountSelectedMediaItems(0)
    for i = 1, itemcount do
        items[i] = {}
        items[i].item = reaper.GetSelectedMediaItem(0, i-1)
        items[i].pos = reaper.GetMediaItemInfo_Value(items[i].item, "D_POSITION")
        items[i].endpos = items[i].pos + reaper.GetMediaItemInfo_Value(items[i].item, "D_LENGTH")
        items[i].track = reaper.GetMediaItemInfo_Value(items[i].item, "P_TRACK")
    end
    return items
end

function DeleteTimeOnTrack(track)
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(40309, 0) -- turn ripple edit off
    reaper.Main_OnCommand(40142, 0) -- Insert empty item
    reaper.Main_OnCommand(40310, 0) -- turn ripple edit per track on
    reaper.Main_OnCommand(40006, 0) -- Delete item
end

function InsertTimeOnTrack(track)
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(40310, 0) -- turn ripple edit per track on
    reaper.Main_OnCommand(40142, 0) -- Insert empty item
    reaper.Main_OnCommand(40309, 0) -- turn ripple edit off
    reaper.Main_OnCommand(40006, 0) -- Delete item
end

function CollapseSelectedItems(items)
    -- sort by end position, last item first
    table.sort(items, function(a,b)
		if (a.endpos > b.endpos) then
				-- primary sort on end position -> a before b
			return true
			elseif (a.endpos < b.endpos) then
				-- primary sort on end position -> b before a
			return false
		else
			-- primary sort tied, resolve w secondary sort on pos
			return a.pos > b.pos
		end
	end)

    -- find tracks and latest endpos per track
    local tracks = {}
    for _, item in ipairs(items) do
        if not tracks[item.track] then
            tracks[item.track] = item.endpos
        end
    end

    local group_start = items[1].pos
    for n, item in ipairs(items) do
        if item.pos < group_start then
            group_start = item.pos
        end
        if n < #items then
            local gap = group_start - items[n+1].endpos
            if gap > max_gap then
                reaper.GetSet_LoopTimeRange2(0, true, false, group_start - gap, group_start - max_gap, false)
                if orig_RippleAll == 1 then
                    reaper.Main_OnCommand(40201, 0) -- Delete time selection moving later items
                else
                    for t, maxpos in pairs(tracks) do
                        if group_start < maxpos then
                            DeleteTimeOnTrack(t)
                        end
                    end
                    -- above block moved later items, undo if ripple per track is off
                    if orig_RippleTrack == 0 then
                        for t, maxpos in pairs(tracks) do
                            if group_start < maxpos then
                                reaper.GetSet_LoopTimeRange2(0, true, false, maxpos - (gap - max_gap), maxpos, false)
                                InsertTimeOnTrack(t)
                            end
                        end
                    end
                end
            end
        end
    end
end

function CollapseSelectedTracks(tracks)
   for _, track in ipairs(tracks) do
        reaper.SetOnlyTrackSelected(track)
        reaper.Main_OnCommand(40289, 0) -- clear item selection
        reaper.Main_OnCommand(40421, 0) -- select all items in track
        local items = GetSelectedItems()
        CollapseSelectedItems(items)
   end
end

--======= MAIN FUNCTION ==============================--
function Main()
    -- save original time selection
    local orig_start_sel, orig_end_sel = reaper.GetSet_LoopTimeRange2(0,false, false,0,0,false)
    -- save the original ripple edit mode
    orig_RippleAll = reaper.GetToggleCommandStateEx(0, 41991)
    orig_RippleTrack = reaper.GetToggleCommandStateEx(0, 41990)
    -- save original item selection
    local orig_items = GetSelectedItems()
    -- save original track selection
    local orig_tracks = {}
    local trackcount = reaper.CountSelectedTracks(0)
    for i = 1, trackcount do
        orig_tracks[i] = reaper.GetSelectedTrack(0, i-1)
    end

    if #orig_items > 0 then
        CollapseSelectedItems(orig_items)
    elseif trackcount > 0 then
        CollapseSelectedTracks(orig_tracks)
    end
        
    -- restore track selection
    reaper.Main_OnCommand(40297, 0) -- clear track selection
    for _, t in ipairs(orig_tracks) do
        reaper.SetTrackSelected(t, true)
    end
    -- restore item selection
    reaper.Main_OnCommand(40289, 0) -- clear item selection
    for _, item in ipairs(orig_items) do
        reaper.SetMediaItemSelected(item.item, true)
    end
    -- Restore original ripple edit mode and time selection
    if orig_RippleAll == 1 then
        reaper.Main_OnCommand(40311, 0)
    elseif orig_RippleTrack == 1 then
        reaper.Main_OnCommand(40310, 0)
    else
        reaper.Main_OnCommand(40309, 0)
    end
    reaper.GetSet_LoopTimeRange2(0, true, false, orig_start_sel, orig_end_sel, false)
end

--======= RUN ==============================--
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Collapse empty space between items", -1)
reaper.UpdateArrange()