--[[
Name:
    Functions
Author:
    tomtjes
Donation:
    https://ko-fi.com/tomtjes
Links:
    Github https://github.com/tomtjes/Radio-Toolkit
License:
    GPL v3
Version:
    1.03 2024-07-04
Changelog:
    + initial release
NoIndex: true
Provides:
    [nomain] .
About:
    # Functions

    Functions used by other Radio Toolkit packages

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

function SortReverse(items)
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

function FindContiguous(items, gap)
    -- items must be in reverse order
    local first = {} -- all items beginning at the start of this group
    local last = {}  -- all items ending at the end of this group
    repeat
        if #first == 0 or first[1].pos == items[1].pos then
            -- no first item yet or this item is in same position as first item
            first[#first+1] = items[1]
        end
        if first[1].pos > items[1].pos then
            -- this item comes before current first item -> becomes new first item
            first = {}
            first[1] = items[1]
        end
        if #last == 0 or last[1].endpos == items[1].endpos then
            -- no last item yet or this item ends in same position as last item
            last[#last+1] = items[1] 
        end
        table.remove(items,1)
    until #items == 0 or first[1].pos - items[1].endpos > gap -- last item reached or gap detected
    return first, last, items
end

-- general functions

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
    for _, track in ipairs(tracks) do
        local item_count = reaper.GetTrackNumMediaItems(track)
        -- build array of items
        for i = 0, item_count - 1 do
            local item = {}
            item.track = track
            item.tracknum = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
            item.item = reaper.GetTrackMediaItem(track, i)
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

-- save and restore states
function GetSelectedItems()
    local items = {}
    local itemcount = reaper.CountSelectedMediaItems(0)
    for i = 1, itemcount do
        items[i] = reaper.GetSelectedMediaItem(0, i-1)
    end
    return items
end

function SetSelectedItems(items)
    for _, item in ipairs(items) do
        reaper.SetMediaItemSelected(item, true)
    end
end