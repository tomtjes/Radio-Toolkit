--[[
 * Name: Show project length
 * Author: tomtjes
 * Donation: https://ko-fi.com/tomtjes
 * Links: Github https://github.com/tomtjes/ReaScripts
 * License: GPL v3
 * Version: 1.0 2023-12-20
 * Changelog: Initial Release
@about
  # Show project length 

  Displays the current project length in a Docker tab with docking capability

  > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

local script_title = "tomtjes_Show Project Length"
_, _, section_id, command_id, _, _, _ = reaper.get_action_context() --For this script
local toggle_command_state = reaper.GetToggleCommandStateEx(section_id, command_id)

if toggle_command_state ~= 1 then
  reaper.SetToggleCommandState(section_id, command_id, 1)
  reaper.RefreshToolbar2(section_id, command_id)
end

if reaper.HasExtState(script_title, "dock_state") then
  dock_state = reaper.GetExtState(script_title, "dock_state", dock_state, 1) --Recall gfx window state from previous session
  gfx_x = reaper.GetExtState(script_title, "gfx_x", gfx_x, 1)
  gfx_y = reaper.GetExtState(script_title, "gfx_y", gfx_y, 1)
  gfx_w = reaper.GetExtState(script_title, "gfx_w", gfx_w, 1)
  gfx_h = reaper.GetExtState(script_title, "gfx_h", gfx_h, 1)
  -- gfx.init(script_title, gfx_w, gfx_h, dock_state, gfx_x, gfx_y)
else
  -- gfx.init(script_title,100,100,0)
end

function exit()
  local dock_state, gfx_x, gfx_y, gfx_w, gfx_h = gfx.dock(-1,0,0,0,0)
  reaper.SetExtState(script_title, "dock_state", dock_state, 1) --On exit, store gfx window state
  reaper.SetExtState(script_title, "gfx_x", gfx_x, 1)
  reaper.SetExtState(script_title, "gfx_y", gfx_y, 1)
  reaper.SetExtState(script_title, "gfx_w", gfx_w, 1)
  reaper.SetExtState(script_title, "gfx_h", gfx_h, 1)
  gfx.quit()
  reaper.SetToggleCommandState(section_id, command_id, 0)
  reaper.RefreshToolbar2(section_id, command_id)
end

function GetProjectLength()
  if reaper.GetPlayState()&4==4 and reaper.GetProjectLength()<reaper.GetPlayPosition() then
    return reaper.GetPlayPosition()
  else
    return reaper.GetProjectLength()
  end
end

function GetFormattedProjectLength()
    local project_length = GetProjectLength()
    local hours = math.floor(project_length / 3600)
    local minutes = math.floor((project_length-hours*3600) / 60)
    local seconds = project_length % 60
    return string.format("%02d:%02d:%02.0f", hours, minutes, seconds)
end

function SetThemeColors()
    -- Get colors from the theme
    local r, g, b = reaper.ColorFromNative(reaper.GetThemeColor("coloreditbg"))
    gfx.set(r/255, g/255, b/255) -- Set background color

    r, g, b = reaper.ColorFromNative(reaper.GetThemeColor("colortext"))
    gfx.setfont(1, "Arial", 12, r, g, b) -- Set font color
end

function main()
  if gfx.w == 0 then
      if reaper.HasExtState(script_title, "dock_state") then
        gfx.init("Project Length", gfx_w, gfx_h, dock_state, gfx_x, gfx_y)
      else
        gfx.init("Project Length", 387, 137, 1, 809, 638)
      end
        SetThemeColors()
        --gfx.dock(257)  -- Use -1 to allow docking/undocking
      --gfx.setfont(1, "Arial", 12)
 
  end
  
  gfx.x = 10
  gfx.y = 10
    
    local length_str = GetFormattedProjectLength()
    gfx.drawstr(length_str)

    gfx.update()
    if gfx.getchar() >= 0 then
        reaper.defer(main) -- Re-run the script
    end
end

reaper.atexit(exit)

main()
