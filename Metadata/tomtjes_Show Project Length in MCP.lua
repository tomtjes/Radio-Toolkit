--[[
  Name: Show project length in MCP
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  Provides:
    [jsfx] tomtjes_Show Project Length.jsfx 
  License: GPL v3
  Version: 1.04 2024-07-03
  Changelog: 
    ~ fix jsfx location
  About:
    # Show project length in MCP

    Displays the current project length in the MCP

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

function GetProjectLength()
  if reaper.GetPlayState()&4==4 and reaper.GetProjectLength() < reaper.GetPlayPosition() then
    return reaper.GetPlayPosition()
  else
    return reaper.GetProjectLength() + reaper.GetProjectTimeOffset(0, false)
  end
end

function main()
    local length = GetProjectLength()
    reaper.gmem_write(1, length) -- write value to gmem slot
    reaper.defer(main) -- re-run the script
end

reaper.gmem_attach("tomtjes_projectlength")

local master = reaper.GetMasterTrack()
local fx = reaper.TrackFX_AddByName(master, "tomtjes_Show Project Length.jsfx", false, 1)
reaper.TrackFX_SetNamedConfigParm(master, fx, "focused", 1)
local state = reaper.GetToggleCommandState(42372)
if state == 0 then
  reaper.Main_OnCommand(42372, 0) -- show embedded GUI in MCP
end

main()