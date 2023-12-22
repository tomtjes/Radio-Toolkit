--[[
  Name: Toggle master playrate - 150%
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  License: GPL v3
  Version: 1.0 2022-04-28
  Changelog: + initial release
  About:
    # Toggle master playrate - 150%

    If playrate is 1x, this script sets it to 1.5x.
    If playrate is 1.5x, this script sets it to 1x.

    ## Setup

    The playrate is derived from the name of the script. Change the name of the script to `tomtjes_Toggle master playrate - 200%.lua` and it will set the playrate to 2x.

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

local _, name, _, id, _, _, _ = reaper.get_action_context()

local playrate = tonumber(string.match(name,"(%d+)%%%.lua$")) / 100

local state = reaper.GetPlayState()

if state == 1 then
  reaper.Main_OnCommand(1008,0)
end

if reaper.Master_GetPlayRate(0) == playrate then
  reaper.SetToggleCommandState(0, id, 0)
  reaper.CSurf_OnPlayRateChange(1)
else
  reaper.SetToggleCommandState(0, id, 1)
  reaper.CSurf_OnPlayRateChange(playrate)
end

if state == 1 then
  reaper.Main_OnCommand(1008,0)
end
