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
    1.2 2024-06-22
Changelog:
    ~ improve code quality
    ~ lower track numbers take precedence in naming and coloring regions
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
Gap = 1 -- minimum distance (seconds) between items for a new region to be created
Render = "tracks" -- options: "master", "tracks", "both"
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function Main()
    -- save original item selection
    local orig_items = GetSelectedItems()
    reaper.Main_OnCommand(40289, 0) -- clear item selection

    Tracks = GetTracks()
    Master = reaper.GetMasterTrack(0)

    local items = GetItems(Tracks)
    items = SortByPos(items)
    while #items > 0 do
        local first_of_group, last_of_group, trks
        items, first_of_group, last_of_group, trks = FindContiguous(items,Gap)
---@diagnostic disable-next-line: need-check-nil
        AddRegion(first_of_group.pos, last_of_group.endpos, trks)
    end

    -- restore item selection
    for _, item in ipairs(orig_items) do
        reaper.SetMediaItemSelected(item, true)
    end
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
    for track, v in pairs(tracks) do
        local item_count = reaper.GetTrackNumMediaItems(track)
        -- build array of items
        for j = 0, item_count - 1 do
            local item = {}
            item.track = track
            item.tracknum = v.num
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

function FindContiguous(items,gap)
    local first_of_group = items[1] -- first item of contiguous group
    local last_of_group = items[1] -- last item of contiguous group
    local tracks = {}
    repeat
        if last_of_group.endpos < items[1].endpos then
            last_of_group = items[1]
        end
        -- save track for render matrix and region naming
        tracks[items[1].track] = true
        table.remove(items,1)
    until #items == 0 or items[1].pos - last_of_group.endpos >= gap -- last item reached or gap detected
    return items, first_of_group, last_of_group, tracks
end

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

    local region = reaper.AddProjectMarker2( 0, true, start, stop, name, 1, color ) -- add region and save id

    -- adjust render matrix
    if Render == "master" or Render == "both" then
        reaper.SetRegionRenderMatrix( 0, region, Master, 1 )
    end

    for _, trk in pairs(trks) do
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