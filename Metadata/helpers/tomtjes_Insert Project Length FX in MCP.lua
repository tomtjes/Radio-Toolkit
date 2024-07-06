--[[
  Name: Insert project length FX in MCP
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  NoIndex: true
  License: GPL v3
  Version: 1.0 2024-07-06
  Changelog: 
  About:
    # Show project length in MCP

    Displays the current project length in the MCP

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]
  
local master = reaper.GetMasterTrack()
local fx = reaper.TrackFX_AddByName(master, "tomtjes_Show Project Length.jsfx", false, 1)
reaper.TrackFX_SetNamedConfigParm(master, fx, "focused", 1)
local state = reaper.GetToggleCommandState(42372)
if state == 0 then
    reaper.Main_OnCommand(42372, 0) -- show embedded GUI in MCP
end
