--[[
  Name: Get project length
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  NoIndex: true
  License: GPL v3
  Version: 1.2pre 2024-07-06
  Changelog: 
  About:
    # Get project length

    THIS IS JUST A HELPER SCRIPT. Main Script: tomtjes_Show Project Length in MCP.lua

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

function GetProjectLength()
    if reaper.GetPlayState()&4==4 and reaper.GetProjectLength() < reaper.GetPlayPosition() then
        return reaper.GetPlayPosition()
    else
        return reaper.GetProjectLength() + reaper.GetProjectTimeOffset(0, false)
    end
end
  
function Update()
    local length = GetProjectLength()
    reaper.gmem_write(1, length) -- write value to gmem slot
    reaper.defer(Update) -- re-run the script
end

local master = reaper.GetMasterTrack()
local fx = reaper.TrackFX_AddByName(master, "tomtjes_Show Project Length.jsfx", false, 0)

if fx >= 0 then -- fx is present
    reaper.set_action_options(1|2) -- terminate when relaunched, automatically relaunch
    reaper.gmem_attach("tomtjes_projectlength")
    Update()
end