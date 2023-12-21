--[[
Name: Drafts Helper
Author: tomtjes
Donation: https://ko-fi.com/tomtjes
Links:
  Github https://github.com/tomtjes/ReaScripts
  Drafts App https://getdrafts.com
  Reaper Action Group https://actions.getdrafts.com/g/2Jy
License: GPL v3
Version: 1.0 2023-12-20
Changelog:
  + initial release
About:
  # Drafts Helper

  Allows to control Reaper from the Drafts note taking app and pull data from Reaper into Drafts, e.g. timestamps.

  ## Instructions

  *see instructions in Action Group in Drafts Directory*

  > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]

local function create_marker()

  local function rgbsplit (inputstr, sep)
      if sep == nil then
          sep = "%s"
      end
      local t={}
      for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
          table.insert(t, tonumber(str))
      end
      return t
  end

  local function urldecode(url)
      return (url:gsub("%%(%x%x)", function(x)
      return string.char(tonumber(x, 16))
      end))
  end

  -- get marker
  _, name =  reaper.GetProjExtState( 0, "Drafts", "marker_name" )
  _, color =  reaper.GetProjExtState( 0, "Drafts", "marker_color" )
  _, time =  reaper.GetProjExtState( 0, "Drafts", "marker_time" )
  
  if time ~= nil then
      time = tonumber(time)
      if name == nil then
          name = " "
      else
          name = urldecode(name)
      end
      if color ~= "" then
       color = rgbsplit(color,"_")
       color = reaper.ColorToNative( color[1],color[2],color[3] )|0x1000000
       
      else
          color = 0
      end
      -- add new marker for previous note from Drafts
      reaper.AddProjectMarker2( 0, false, time, 0, name, 0, color )
      end
  end

local function get_project_name()
  name = reaper.GetProjectName( 0 )
  reaper.SetProjExtState(0, "Drafts", "name", name)
end

-- Read the value of "function_to_execute" from the "ProjExtState" table
_, function_to_execute = reaper.GetProjExtState(0, "Drafts", "function_to_execute")

-- Execute the appropriate function based on the value of "function_to_execute"
if function_to_execute == "create_marker" then
create_marker()
elseif function_to_execute == "get_project_name" then
get_project_name()
else
reaper.ShowConsoleMsg("Invalid function name: " .. function_to_execute .. "\n")
end
