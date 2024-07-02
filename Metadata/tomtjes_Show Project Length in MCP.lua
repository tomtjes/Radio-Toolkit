--[[
  Name: Show project length in MCP
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  Provides:
    [jsfx] jsfx/tomtjes_Show_project_length.jsfx > tomtjes_Show_project_length.jsfx
  License: GPL v3
  Version: 1.0 2024-06-28
  Changelog: + initial release
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
local fx = reaper.TrackFX_GetByName(master, "tomtjes_Show_project_length.jsfx", true)
-- reaper.TrackFX_SetNamedConfigParm(master, fx, "renamed_name", "Project Length")
reaper.TrackFX_SetNamedConfigParm(master, fx, "focused", 1)
reaper.Main_OnCommand(42372, 0) -- show embedded GUI in MCP

main()