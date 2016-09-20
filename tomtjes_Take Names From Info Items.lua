-- check if 2 tracks are selected
if reaper.CountSelectedTracks( 0 ) ~= 2 then
	reaper.ShowConsoleMsg("This script requires exactly 2 (two) selected tracks!".."\n".."One track must contain the audio, the other the info items.")
	return
else	
    -- figure out which track contains empty items - the one with higher item count
	track1 = reaper.GetSelectedTrack( 0, 0 )                               
	track2 = reaper.GetSelectedTrack( 0, 1 )

	items_track1 = reaper.CountTrackMediaItems( track1 )
	items_track2 = reaper.CountTrackMediaItems( track2 )
	
  	-- check if there's one track with only one item on it
	if math.min( items_track1, items_track2 ) ~= 1 then
		reaper.ShowConsoleMsg("Audio track must contain exactly 1 item!")
		return
	elseif items_track1 > items_track2 then
		info_track = track1                               
		audio_track = track2
		number_of_items = items_track1
	else
		info_track = track2                               
		audio_track = track1  
		number_of_items = items_track2                          
	end
	
    -- assess audio item
	audio_item = reaper.GetTrackMediaItem( audio_track, 0 )                    
	audio_item_start = reaper.GetMediaItemInfo_Value( audio_item, "D_POSITION" )
	audio_item_end = audio_item_start + reaper.GetMediaItemInfo_Value( audio_item, "D_LENGTH" )

	for i = 0, number_of_items - 1 do
        -- assess info item
		info_item = reaper.GetTrackMediaItem( info_track, i )
        -- do they overlap?    
		position = reaper.GetMediaItemInfo_Value( info_item, "D_POSITION" )
		if audio_item_start > position or audio_item_end < position then
			reaper.ShowConsoleMsg("Audio and info items don't align!")
			return
		else
			-- split audio item and select right side of split
			audio_item = reaper.SplitMediaItem( audio_item, position )
			-- extract note from info item
			note = reaper.ULT_GetMediaItemNote( info_item )
			-- select take of audio item and rename
			audio_take = reaper.GetMediaItemTake( audio_item, 0 )                  
			reaper.GetSetMediaItemTakeInfo_String( audio_take, "P_NAME", note, 1 )
			-- oh, and why not copy/paste the color too?
			color = reaper.GetDisplayedMediaItemColor( info_item )
			reaper.SetMediaItemInfo_Value( audio_item, "I_CUSTOMCOLOR", color )
		end					   
	end
	reaper.UpdateArrange()									   
end
