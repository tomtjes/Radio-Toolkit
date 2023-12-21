--[[
 * Name: Create regions from adjacent items across tracks
 * Screenshot: https://github.com/tomtjes/ReaScripts/Regions/tomtjes_Create regions from adjacent items across tracks.gif
 * Author: tomtjes
 * Donation: https://ko-fi.com/tomtjes
 * Links: Repository https://github.com/tomtjes/ReaScripts
 * License: GPL v3
 * Version: 1.1 2022-01-28
 * Changelog:
    ~ fix for first item at position 0 (using code from https://github.com/nofishonfriday/ReaScripts/blob/master/editing/nofish_Select%20next%20item%20(in%20time)%20across%20tracks.lua)
    ~ fix for multiple items with same position but different length
    ~ fix region numbering (start with 1 instead of 0)
    ~ define region color by first track
    ~ set default to render tracks
    ~ reduce number of calls to reaper
    - remove requirement to select tracks, apply script to all tracks if none selected
    (Initial relase was 2020-09-11)
 * About:
     # Create regions from adjacent items across tracks
     
     Creates regions that comprise all items that are less than a
     given number of seconds (default: 1) apart. The region render
     matrix gets adjusted to render the respective tracks for the created
     regions and/or the master track (configurable). Regions are named and colored after track of first item
     in region.

     Evaluates items on selected tracks or all items if no tracks are selected.

     ## Instructions

     - modify gap value and render setting in first lines of code (optional)
     - select track(s) (optional)
     - run script

     > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

--======= CONFIG =================================--
gap = 1 -- minimum distance (seconds) between items for a new region to be created
render = "tracks" -- options: "master", "tracks", "both"
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--

function main()
    local region, item
    local tracks = {}
    local items = {}

    -- get master track
    local master = reaper.GetMasterTrack( 0 )

	local items_total = 0

    local track_count = reaper.CountTracks(0)
    local track_count_sel = reaper.CountSelectedTracks(0)

	-- LOOP THROUGH TRACKS
	for i = 0, track_count - 1 do

		track = reaper.GetTrack(0, i)

        if (track_count_sel > 0 and reaper.IsTrackSelected(track) == true) or track_count_sel == 0 then

            -- create tracks array in project order (for later use)
            tracks[track] = {}
            tracks[track].set = false
            _, tracks[track].name = reaper.GetTrackName(track)
            tracks[track].color = reaper.GetTrackColor(track)

            count_items_tracks = reaper.GetTrackNumMediaItems(track)

            for j = 0, count_items_tracks - 1 do

                item = reaper.GetTrackMediaItem(track, j)

                items_total = items_total + 1

                items[items_total] = {}

                items[items_total].item = item
                items[items_total].pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                items[items_total].endpos = items[items_total].pos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                items[items_total].track = track
            end
        end
		
	end

	table.sort(items, function( a,b )
		if (a.pos < b.pos) then
				-- primary sort on position -> a before b
			return true
			elseif (a.pos > b.pos) then
				-- primary sort on position -> b before a
			return false
		else
			-- primary sort tied, resolve w secondary sort on rank
			return a.pos < b.pos
		end
	end)

    -- add virtual last item to make sure the last region gets created
    items[items_total+1] = {}
    items[items_total+1].pos = items[items_total].endpos + gap + 1

    -- start first region
    InitializeRegion(items[1].pos)

	-- loop through items
	for i = 1, items_total do

        -- if current item longer than region, extend region
        if region_end < items[i].endpos then
            region_end = items[i].endpos
        end

        -- save track for render matrix and region naming
        tracks[items[i].track].set = true

        -- create region now?
        if items[i+1].pos - region_end >= gap then -- if gap to next item big enough
        
            -- region name and color defined by tracks in project order
            for _, trk in pairs(tracks) do
                if trk.set == true then
                    region_name = region_name .. trk.name    
                    if region_color == "" then
                        region_color = trk.color
                    end
                end
            end

            region = reaper.AddProjectMarker2( 0, true, region_start, region_end, region_name, 1, region_color ) -- add region and save id
  
            -- adjust render matrix
            if render == "master" or render == "both" then
                reaper.SetRegionRenderMatrix( 0, region, master, 1 )
            end

            for id, trk in pairs(tracks) do
                if trk.set == true and (render == "tracks" or render == "both") then
                    reaper.SetRegionRenderMatrix( 0, region, id, 1 )
                end
                tracks[id].set=false
            end

            -- start next region
            InitializeRegion(items[i+1].pos)
        end

	end -- ENDLOOP through items
end

function InitializeRegion(start)
  region_start = start
  region_end = 0
  region_name = ""
  region_color = ""
end

--======= END OF FUNCTIONS =======================--

reaper.Undo_BeginBlock()
main()
reaper.UpdateArrange()
reaper.Undo_EndBlock("Create regions from adjacent items across tracks", -1)
