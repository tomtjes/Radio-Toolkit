--[[
Name:
    Extend end of adjacent items (across tracks)
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
    1.1 2024-07-03
Changelog:
    + fix case where multiple items end in same position
    ~ clear time selection when finished
About:
    # Extend end of adjacent items (across tracks)
    Finds all contiguous groups of items that are less than a
    given number of seconds (default: 1) apart from each other. The last item in
    each group is then extended by the given number of seconds (default: 2).

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
Extend = 2 -- number of seconds to extend the last item to the right
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function Main()
    -- save original item selection
    local orig_items = GetSelectedItems()
    reaper.Main_OnCommand(40289, 0) -- clear item selection

    local tracks = GetTracks()
    local items = GetItems(tracks)
    items = SortByPos(items)
    while #items > 0 do
        local last_of_group
        items, last_of_group = FindContiguous(items,Gap)
        ExtendRight(last_of_group,Extend)
    end

    -- restore item selection
    for _, item in ipairs(orig_items) do
        reaper.SetMediaItemSelected(item, true)
    end
    reaper.Main_OnCommand(40020, 0) -- clear time selection
end -- END MAIN

function GetSelectedItems()
    local items = {}
    local itemcount = reaper.CountSelectedMediaItems(0)
    for i = 1, itemcount do
        items[i] = reaper.GetSelectedMediaItem(0, i-1)
    end
    return items
end

function GetTracks()
    local tracks = {}
    local track_count = reaper.CountTracks(0)
    local track_count_sel = reaper.CountSelectedTracks(0)
	for i = 0, track_count - 1 do
		local track = reaper.GetTrack(0, i)
        if (track_count_sel > 0 and reaper.IsTrackSelected(track) == true) or track_count_sel == 0 then -- selected tracks only or all tracks if none selected
            tracks[#tracks+1] = track
        end
	end
    return tracks
end

function GetItems(tracks)
    local items = {}
    for i=1, #tracks do
        local track = tracks[i]
        local item_count = reaper.GetTrackNumMediaItems(track)
        -- build array of items
        for j = 0, item_count - 1 do
            local item = {}
            item.track = track
            item.tracknum = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
            item.item = reaper.GetTrackMediaItem(track, j)
            item.length = reaper.GetMediaItemInfo_Value(item.item, "D_LENGTH")
            item.pos = reaper.GetMediaItemInfo_Value(item.item, "D_POSITION")
            item.endpos = item.pos + item.length
            item.offset = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item.item), "D_STARTOFFS")
            item.endsec = item.offset + item.length
            item.sourcelength = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(reaper.GetActiveTake(item.item)))
            
            items[#items+1] = item
        end
    end
    return items
end

function SortByPos(items)
    -- goal: start from end of project
    if #items > 1 then
        table.sort(items, function( a,b )
            if (a.endpos > b.endpos) then
                -- primary sort on end position -> a before b
                return true
            elseif (a.endpos < b.endpos) then
                -- primary sort on end position -> b before a
                return false
            else
                -- primary sort tied, resolve w secondary sort on track
                return a.tracknum < b.tracknum
            end
        end)
    end
    return items
end

function FindContiguous(items,gap)
    local last_of_group = {} -- last item(s) of contiguous group
    local first_of_group = items[1]
    repeat
        if #last_of_group == 0 or last_of_group[1].endpos == items[1].endpos then
            last_of_group[#last_of_group+1] = items[1] -- all items ending at the end of this group
        end
        if first_of_group.pos > items[1].pos then
            first_of_group = items[1]
        end
        table.remove(items,1)
    until #items == 0 or first_of_group.pos - items[1].endpos >= gap -- last item reached or gap detected
    return items,last_of_group
end

function ExtendRight(items,sec)
    local extmax = 0
    for _, item in ipairs(items) do
        extmax = math.max(extmax,item.sourcelength - item.endsec) -- make sure take is long enough
    end
    extmax = math.min(extmax,sec)
    if extmax > 0.0001 then -- >0 doesn't work
        reaper.GetSet_LoopTimeRange2( 0, true, true, items[1].endpos+extmax, items[1].endpos+extmax+extmax, false )
        reaper.Main_OnCommand( 40200, 0 ) -- insert silence in time selection
        for _, item in ipairs(items) do
            local ext = math.min(extmax, item.sourcelength - item.endsec)
            reaper.SetMediaItemSelected( item.item, true )
            reaper.SetEditCurPos2( 0, item.endpos+ext, false, false )
            reaper.Main_OnCommand( 41311, 0 ) -- extend item right to cursor
            reaper.SetMediaItemSelected( item.item, false )
        end
    end
end

--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()
Main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Extend end of adjacent items (across tracks)", -1)