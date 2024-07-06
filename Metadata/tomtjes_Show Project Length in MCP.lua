--[[
  Name: Show project length in MCP
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  Provides:
    [jsfx] helpers/tomtjes_Show Project Length.jsfx
    [main] helpers/tomtjes_Get Project Length.lua
  License: GPL v3
  Version: 1.06 2024-07-06
  Changelog: 
    + check all open projects for FX before launching or terminating updater
  About:
    # Show project length in MCP

    Displays the current project length in the MCP

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

local version = tonumber(reaper.GetAppVersion():match("^(%d)"))
if version < 7 then
  reaper.MB("Reaper 7+ required.", "Error", 0)
  return
end

-- insert FX
local master = reaper.GetMasterTrack()
local fx = reaper.TrackFX_AddByName(master, "tomtjes_Show Project Length.jsfx", false, 1)
reaper.TrackFX_SetNamedConfigParm(master, fx, "focused", 1)
local state = reaper.GetToggleCommandState(42372) -- check if GUI in MCP
if state == 0 then
  reaper.Main_OnCommand(42372, 0) -- show embedded GUI in MCP
end

-- run updater script tomtjes_Get Project Length.lua
local cmd = reaper.NamedCommandLookup("_RS24dcd803546d839f9cf11293746fc8b7319d5924")
reaper.Main_OnCommand(cmd, 0)