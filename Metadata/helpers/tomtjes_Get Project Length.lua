--[[
  Name: Show project length in MCP
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
    reaper.defer(main) -- re-run the script
end
  
reaper.set_action_options(1|2)
reaper.gmem_attach("tomtjes_projectlength")  
Update()