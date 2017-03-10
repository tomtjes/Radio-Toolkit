seconds = 2 -- time in seconds that gets played at either end of time selection

start_time, end_time = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) -- get start and end time selection value in seconds
endplayed = 0 -- play the end only once...

function playstart()
    time1 = reaper.time_precise()
    reaper.Main_OnCommand(40073, 0) -- play/pause
    timer()
end

function playend()
  stopatend = reaper.GetToggleCommandState(reaper.NamedCommandLookup("_XEN_PREF_STOPATENDLOOP")) --  check state of "stop at end of time selection"
  if stopatend == 0 then
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_XEN_PREF_STOPATENDLOOP"), 0) -- toggle stop at end
  end
  reaper.Main_OnCommand(40073, 0) -- play/pause
  if stopatend == 0 then
	reaper.Main_OnCommand(reaper.NamedCommandLookup("_XEN_PREF_STOPATENDLOOP"), 0) -- restore/toggle stop at end
  end
  endplayed = 1
end

function timer()    
 time2 = reaper.time_precise() 
 if time2 - time1 < seconds then 
   reaper.defer(timer) 
 elseif endplayed == 0 then  
   reaper.Main_OnCommand(40073, 0) -- play/pause: stop play start section
   reaper.SetEditCurPos2( 0, end_time - seconds, true, false ) -- go to end
   playend()
   reaper.defer(timer)
 elseif time2 - time1 >= seconds *2 then -- wait until end has played
   reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_RESTORE_CURSOR_POS_SLOT_1"), 0) --restore cursor position
   reaper.atexit() -- stop running script
 else 
   reaper.defer(timer) 
 end   
end


if start_time ~= end_time then -- if there is a time selection
  reaper.Main_OnCommand(reaper.NamedCommandLookup("_BR_SAVE_CURSOR_POS_SLOT_1"), 0) -- store cursor position
  reaper.Main_OnCommand(40630, 0) -- go to start of time selection
  if end_time <= (start_time + (seconds * 2)) then -- if time selection too short, play time selection
  	playend()
  else	
    playstart()
  end								   
end