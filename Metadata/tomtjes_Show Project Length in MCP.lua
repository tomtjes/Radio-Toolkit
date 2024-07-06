--[[
  Name: Show project length in MCP
  Author: tomtjes
  Donation: https://ko-fi.com/tomtjes
  Links: Github https://github.com/tomtjes/Radio-Toolkit
  Provides:
    [jsfx] helpers/tomtjes_Show Project Length.jsfx
    [main] helpers/tomtjes_Get Project Length.lua
    [nomain] helpers/tomtjes_Insert Project Length FX in MCP.lua
  License: GPL v3
  Version: 1.05-pre6 2024-07-06
  Changelog: 
    ~ fix jsfx location
  About:
    # Show project length in MCP

    Displays the current project length in the MCP

    > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

local script_folder = debug.getinfo(1).source:match("@?(.*[\\/])")
local script_path = script_folder .. "helpers/tomtjes_Insert Project Length FX in MCP.lua"

if reaper.file_exists(script_path) then
    dofile(script_path)
else
    reaper.MB("Missing Insert script.\n Please install Radio Toolkit Base." .. script_path, "Error", 0)
    return
end

reaper.Main_OnCommand("_RS24dcd803546d839f9cf11293746fc8b7319d5924", 0) -- tomtjes_Get Project Length.lua