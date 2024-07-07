--[[
Name:
    Radio Toolkit Base
Author:
    tomtjes
Donation:
    https://ko-fi.com/tomtjes
Links:
    Github https://github.com/tomtjes/Radio-Toolkit
License:
    GPL v3
Version:
    1.0-pre2 2024-07-06
Changelog:
    + initial release
Provides:
    [nomain] .
About:
    # Radio Toolkit Base

    Functions used by other Radio Toolkit packages

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

function SortAsc(items)
    if #items > 1 then
        table.sort(items, function( a,b )
            if (a.pos < b.pos) then
                -- primary sort on position -> a before b
                return true
            elseif (a.pos > b.pos) then
                -- primary sort on position -> b before a
                return false
            else
                -- primary sort tied, resolve w secondary sort on track
                return a.tracknum < b.tracknum
            end
        end)
    end
    return items
end

function SortDesc(items)
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

function FindContAsc(items, gap)
    -- items must be in ascending order
    local first = {} -- all items beginning at the start of this group
    local last = {}  -- all items ending at the end of this group
    local tracks = {} -- all tracks (as indices) that have items in this group
    repeat
        if #first == 0 or first[1].pos == items[1].pos then
            -- no first item yet or this item is in same position as first item
            first[#first+1] = items[1]
        end
        if #last == 0 or last[1].endpos == items[1].endpos then
            -- no last item yet or this item ends in same position as last item
            last[#last+1] = items[1]
        end
        if last[1].endpos < items[1].endpos then
            -- this item comes after current last item -> becomes new last item
            last = {}
            last[1] = items[1]
        end
        tracks[items[1].track] = true
        table.remove(items,1)
    until #items == 0 or last[1].endpos - items[1].pos > gap -- last item reached or gap detected
    return first, last, items, tracks
end

function FindContDesc(items, gap)
    -- items must be in descending order
    local first = {} -- all items beginning at the start of this group
    local last = {}  -- all items ending at the end of this group
    local tracks = {} -- all tracks (as indices) that have items in this group
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
        tracks[items[1].track] = true
        table.remove(items,1)
    until #items == 0 or first[1].pos - items[1].endpos > gap -- last item reached or gap detected
    return first, last, items, tracks
end

-- general functions

function GetTracks(sel)
    -- get selected tracks or all tracks if none selected or sel==false
    local tracks = {}
    local track_count = reaper.CountTracks(0)
    local track_count_sel = reaper.CountSelectedTracks(0)
    if sel == nil then
        if track_count_sel > 0 then
            sel = true
        else
            sel = false
        end
    end
	for i = 0, track_count - 1 do
		local track = reaper.GetTrack(0, i)
        if (sel and reaper.IsTrackSelected(track)) or sel == false then -- selected tracks only or all tracks if none selected
            tracks[track] = {}
            _, tracks[track].name = reaper.GetTrackName(track)
            tracks[track].color = reaper.GetTrackColor(track)
            tracks[track].num = reaper.GetMediaTrackInfo_Value(track, 'IP_TRACKNUMBER')
        end
	end
    return tracks
end

function GetItems(tracks)
    local items = {}
    for track, tinfo in ipairs(tracks) do
        local item_count = reaper.GetTrackNumMediaItems(track)
        -- build array of items
        for i = 0, item_count - 1 do
            local item = {}
            item.track = track
            item.tracknum = tinfo.num
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
function GetSelectedTracks()
    local tracks = {}
    local trackcount = reaper.CountSelectedTracks(0)
    for i = 1, trackcount do
        tracks[i] = reaper.GetSelectedTrack(0, i-1)
    end
    return tracks
end

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

function SetSelectedItems(items)
    for _, item in ipairs(items) do
        reaper.SetMediaItemSelected(item.item, true)
    end
end