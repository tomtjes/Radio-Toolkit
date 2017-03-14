--[[
    When no in-point is set or the in-point is 0, the in-point is set to the out-point
*** Caveat: If you want the in-point to be at the project start, you have to set it after setting the out-point! ***
--]]

reaper.Main_OnCommand(40626, 0) -- set outpoint
inpoint, outpoint = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) -- get in-point and out-point
reaper.SetEditCurPos2(0, outpoint, true, false) -- move edit cursor to out-point
if inpoint == 0 then
	reaper.Main_OnCommand(40625, 0) -- set in-point = out-point
end
reaper.UpdateArrange()
