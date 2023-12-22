--[[
    Name: Set inpoint to beginning of item if inpoint is 0
    Author: tomtjes
    Donation: https://ko-fi.com/tomtjes
    Links: Github https://github.com/tomtjes/Radio-Toolkit
    License: GPL v3
    Version: 1.0 2017-03-14
    Changelog: + initial release
    About:
        # Set inpoint to beginning of item if inpoint is 0

        If no inpoint (i.e. the beginning of a time selection) is defined or if the inpoint is at the beginning of the project or at the current outpoint,
        the inpoint is set at the beginning of the current item.

        > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

reaper.Undo_BeginBlock()
inpoint, outpoint = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false) -- get in-point and out-point
projstart = reaper.GetProjectTimeOffset(0, false)
if inpoint == projstart or inpoint == 0.0 or inpoint == nil or inpoint == outpoint then
    reaper.SetEditCurPos2(0, outpoint, true, false) -- move edit cursor to out-point
    reaper.Main_OnCommand(40318, 0) -- move cursor to left item edge
	reaper.Main_OnCommand(40625, 0) -- set in-point
end
reaper.Undo_EndBlock("Set inpoint to beginning of item", -1)
reaper.UpdateArrange()
