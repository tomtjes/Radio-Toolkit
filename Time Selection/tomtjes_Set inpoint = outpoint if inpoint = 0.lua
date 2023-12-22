--[[
    Name: Set inpoint to outpoint if inpoint is 0
    Author: tomtjes
    Donation: https://ko-fi.com/tomtjes
    Links: Github https://github.com/tomtjes/Radio-Toolkit
    License: GPL v3
    Version: 1.0 2017-03-14
    Changelog: + initial release
    About:
        # Set inpoint to outpoint if inpoint is 0

        If the in-point (i.e. the beginning of a time selection) is at the beginning of the project,
        the inpoint is set to the same position as the current out-point.

        > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

reaper.Main_OnCommand(40626, 0) -- set outpoint
inpoint, outpoint = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) -- get in-point and out-point
reaper.SetEditCurPos2(0, outpoint, true, false) -- move edit cursor to out-point
if inpoint == 0 then
	reaper.Main_OnCommand(40625, 0) -- set in-point = out-point
end
reaper.UpdateArrange()
