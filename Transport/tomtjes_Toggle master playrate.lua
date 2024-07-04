--[[
  Name: Toggle master playrate
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  License: GPL v3
  Version: 1.2 2024-07-03
  MetaPackage: true
  Provides:
    [main] . > Toggle master playrate - 125%.lua
    [main] . > Toggle master playrate - 150%.lua
    [main] . > Toggle master playrate - 175%.lua
    [main] . > Toggle master playrate - 200%.lua
  Changelog: 
    + fix metapackage
  About:
    # Toggle master playrate

    Toogles playrate between 1x (100%) and value in script title.

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
