--[[
  Name: Get project length
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  NoIndex: true
  License: GPL v3
  Version: 1.3 2024-07-06
  Changelog: 
    + check all open projects for FX before launching or terminating updater
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

function CheckFX()
    for p = 0, 999 do -- loop through all open projects
        local proj = reaper.EnumProjects(p , '')
        if proj == nil then break end
        local master = reaper.GetMasterTrack(proj)
        local fx = reaper.TrackFX_AddByName(master, "tomtjes_Show Project Length.jsfx", false, 0)
        if fx >= 0 then
          return true
        end
    end
    return false
end

local fx_found = CheckFX()
if fx_found then -- fx is present
    reaper.set_action_options(1|2) -- terminate when relaunched, automatically relaunch, requires Reaper 7
    reaper.gmem_attach("tomtjes_projectlength")
    Update()
end