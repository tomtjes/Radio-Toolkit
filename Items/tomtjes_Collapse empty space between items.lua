--[[
    Name:
        Collapse empty space between items
    Screenshot:
        https://github.com/tomtjes/Radio-Toolkit/blob/master/Items/tomtjes_Collapse%20empty%20space%20between%20items.gif
    Author:
        tomtjes
    Donation:
        https://ko-fi.com/tomtjes
    Links:
        Github https://github.com/tomtjes/Radio-Toolkit
    Version:
        1.2 2024-07-07
    Changelog:
        ~ fix groups spanning multiple tracks
    License:
        GPL v3
    About:
        # Collapse empty space between items
        
        Reduces gaps between items to a set maximum length. Items are moved left.
        Ripple Edit modes are being respected. The script works on selected items.
        If items across multiple tracks are selected, they are evaluated as if they
        were on the same track, meaning a gap is only a gap if it spans all tracks
        that selected items are in. If no items are selected, the script works on
        selected tracks, collapsing gaps on each selected track individually. 

        ## Instructions

        - optional: modify gap value in first line
        - select items or tracks
        - run script 
--]]

--======= CONFIG =================================--
-- collapse gaps larger than (seconds)
Gap = 1.0
--======= END OF CONFIG ==========================--

--======= FUNCTIONS ==============================--
local script_folder = debug.getinfo(1).source:match("@?(.*[\\/])")
script_folder = script_folder:match("^(.*[\\/])[^\\/]*[\\/]$") -- parent folder
local script_path = script_folder .. "Functions/tomtjes_Radio Toolkit Base.lua"

if reaper.file_exists(script_path) then
    dofile(script_path)
else
    reaper.MB("Missing base functions.\n Please install Radio Toolkit Base." .. script_path, "Error", 0)
    return
end

function DeleteTimeOnTrack(track)
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(40309, 0) -- turn ripple edit off
    reaper.Main_OnCommand(40142, 0) -- Insert empty item
    reaper.Main_OnCommand(40310, 0) -- turn ripple edit per track on
    reaper.Main_OnCommand(40006, 0) -- Delete item
end

function InsertTimeOnTrack(track)
    reaper.SetOnlyTrackSelected(track)
    reaper.Main_OnCommand(40310, 0) -- turn ripple edit per track on
    reaper.Main_OnCommand(40142, 0) -- Insert empty item
    reaper.Main_OnCommand(40309, 0) -- turn ripple edit off
    reaper.Main_OnCommand(40006, 0) -- Delete item
end

function CollapseSelectedItems(items)
    items = SortDesc(items)
    local tracks
    local groups = {}
    while #items > 0 do
        local first_of_group, last_of_group
        first_of_group, last_of_group, items, tracks = FindContDesc(items,Gap)
        groups[#groups+1] = { pos = first_of_group[1].pos, endpos = last_of_group[1].endpos, tracks = tracks }
    end

    for i = 1, #groups-1 do
        local gapstart = groups[i+1].endpos
        local gapend = groups[i].pos
        reaper.GetSet_LoopTimeRange2(0, true, false, gapstart, gapend - Gap, false)
        if RippleAll == 1 then
            reaper.Main_OnCommand(40201, 0) -- Delete time selection moving later items
        else
            for t, _ in pairs(groups[i].tracks) do
                DeleteTimeOnTrack(t)
            end
            -- above block moved later items, undo if ripple per track is off
            if RippleTrack == 0 then
                for t, _ in pairs(groups[i].tracks) do
                    reaper.GetSet_LoopTimeRange2(0, true, false, groups[1].endpos-(gapend-gapstart)+Gap, groups[1].endpos, false)
                    InsertTimeOnTrack(t)
                end
            end
        end
    end
end

function CollapseSelectedTracks(tracks)
   for _, track in ipairs(tracks) do
        reaper.SetOnlyTrackSelected(track)
        reaper.Main_OnCommand(40289, 0) -- clear item selection
        reaper.Main_OnCommand(40421, 0) -- select all items in track
        local items = GetSelectedItems()
        CollapseSelectedItems(items)
   end
end

--======= MAIN FUNCTION ==============================--
function Main()
    -- save original time selection
    local orig_start_sel, orig_end_sel = reaper.GetSet_LoopTimeRange2(0,false, false,0,0,false)
    -- save the original ripple edit mode
    RippleAll = reaper.GetToggleCommandStateEx(0, 41991)
    RippleTrack = reaper.GetToggleCommandStateEx(0, 41990)
    -- save original item selection
    local orig_items = GetSelectedItems()
    -- save original track selection
    local orig_tracks = GetSelectedTracks()

    if #orig_items > 0 then
        local items = GetSelectedItems() -- can't copy orig_items here because tables are references 
        CollapseSelectedItems(items)
    elseif #orig_tracks > 0 then
        CollapseSelectedTracks(orig_tracks)
    end

    -- restore track selection
    reaper.Main_OnCommand(40297, 0) -- clear track selection
    for _, t in pairs(orig_tracks) do
        reaper.SetTrackSelected(t, true)
    end
    -- restore item selection
    reaper.Main_OnCommand(40289, 0) -- clear item selection
    SetSelectedItems(orig_items)
    -- Restore original ripple edit mode and time selection
    if RippleAll == 1 then
        reaper.Main_OnCommand(40311, 0)
    elseif RippleTrack == 1 then
        reaper.Main_OnCommand(40310, 0)
    else
        reaper.Main_OnCommand(40309, 0)
    end
    reaper.GetSet_LoopTimeRange2(0, true, false, orig_start_sel, orig_end_sel, false)
end

--======= RUN ==============================--
reaper.Undo_BeginBlock()
Main()
reaper.Undo_EndBlock("Collapse empty space between items", -1)
reaper.UpdateArrange()