--[[
 * Name: Calculate total length of items on selected tracks
 * Screenshot: https://github.com/tomtjes/ReaScripts/Metadata/tomtjes_Calculate total length of items on selected tracks.png
 * Author: tomtjes
 * Donation: https://ko-fi.com/tomtjes
 * Links: Repository https://github.com/tomtjes/ReaScripts
 * License: GPL v3
 * Version: 1.0 2023-12-19
 * Changelog: Initial Release
 * About: 
     # Calculate total length of items on selected tracks

     Sums up the lengths of all items and breaks the result down by track and media source file.
     If you use markers named `=START` and/or `=END`, anything outside that range is disregarded.

     ## Instructions

     - select one or more tracks
     - run the script
    
     > If this script frequently saves you time and money, please consider to [support my work with coffee](https://ko-fi.com/tomtjes). 
--]]


-- Initialize Reaper
reaper.ClearConsole()

-- Function to convert seconds to hh:mm:ss
function SecondsToHHMMSS(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local seconds = math.floor((seconds % 60) + 0.5) -- +0.5 for proper rounding
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- Function to extract filename from full path
function GetFilenameFromPath(filePath)
    return filePath:match("([^\\/]+)$")
end

-- Function to find marker position by name
function FindMarkerPosition(markerName)
    local numMarkers = reaper.CountProjectMarkers(0)
    for i = 0, numMarkers - 1 do
        local _, isrgn, pos, _, name = reaper.EnumProjectMarkers3(0, i)
        if not isrgn and name == markerName then
            return pos
        end
    end
    return nil
end

-- Function to get total length of items on a track, broken down by media source
function GetLengthsByMediaSource(track, startPos, endPos)
    local totalLength = 0
    local lengthsBySource = {}
    local itemCount = reaper.CountTrackMediaItems(track)

    for i = 0, itemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemEnd = itemStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

        -- Adjust start and end if item extends beyond the range
        local adjustedStart = math.max(itemStart, startPos or 0)
        local adjustedEnd = (endPos and math.min(itemEnd, endPos)) or itemEnd
        local itemLength = math.max(0, adjustedEnd - adjustedStart)

        if itemLength > 0 then
            totalLength = totalLength + itemLength
            ItemTotal = ItemTotal + 1

            local take = reaper.GetActiveTake(item)
            if take then
                local pcm_source = reaper.GetMediaSourceParent(reaper.GetMediaItemTake_Source(take)) or reaper.GetMediaItemTake_Source(take)
                local sourceFilePath = reaper.GetMediaSourceFileName(pcm_source) -- or "-empty- (MIDI?)"
                -- local sourceFileName = GetFilenameFromPath(sourceFilePath) or "-empty-"
                lengthsBySource[sourceFilePath] = (lengthsBySource[sourceFilePath] or 0) + itemLength
            else
                lengthsBySource["empty (text) items"] = (lengthsBySource["empty (text) items"] or 0) + itemLength
            end
        end
    end
    return totalLength, lengthsBySource
end

-- Main script
local selectedTrackCount = reaper.CountSelectedTracks(0)
local maxTrackNameLength = 10  -- Minimum length for "Track Name"
local maxFileNameLength = 12  -- Minimum length for "Source File"
ItemTotal = 0

if selectedTrackCount == 0 then
    reaper.ShowConsoleMsg("ERROR: No track selected")
    return
end

-- Find the maximum length of track names and source file names for padding
for i = 0, selectedTrackCount - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    local _, trackName = reaper.GetTrackName(track)
    maxTrackNameLength = math.max(maxTrackNameLength, #trackName)

    local itemCount = reaper.CountTrackMediaItems(track)
    for j = 0, itemCount - 1 do
        local item = reaper.GetTrackMediaItem(track, j)
        local take = reaper.GetActiveTake(item)
        if take then
            local pcm_source = reaper.GetMediaSourceParent(reaper.GetMediaItemTake_Source(take)) or reaper.GetMediaItemTake_Source(take)
            local sourceFilePath = reaper.GetMediaSourceFileName(pcm_source) 
            local sourceFileName = GetFilenameFromPath(sourceFilePath) or " "
            maxFileNameLength = math.max(maxFileNameLength, #sourceFileName)
        end
    end
end

-- Table headers
local p = 3 -- padding
local formatString = "%-" .. maxTrackNameLength + p-1 .. "s %-" .. maxFileNameLength + p-1 .. "s %-8s"
local formatStringTotal = "%-" .. maxTrackNameLength + p-1 .. "s %" .. maxFileNameLength .. "s %" .. p-1 + 8 .."s"

reaper.ShowConsoleMsg(string.format(formatString, "TRACK", "SOURCE", "LENGTH") .. "\n")
reaper.ShowConsoleMsg(string.rep("-", maxTrackNameLength + maxFileNameLength + p*2 + 8) .. "\n")

-- Get positions of "=START" and "=END" markers
local startMarker = FindMarkerPosition("=START")
local endMarker = FindMarkerPosition("=END")

-- Output track and source lengths in table format
local totalsBySource = {}
local sourceOnMultipleTracks = false

for i = 0, selectedTrackCount - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    local _, trackName = reaper.GetTrackName(track)
    local totalLength, lengthsBySource = GetLengthsByMediaSource(track, startMarker, endMarker)
    local formattedTotalLength = SecondsToHHMMSS(totalLength)

    local t = trackName
    for sourceFilePath, length in pairs(lengthsBySource) do
        if not sourceOnMultipleTracks and totalsBySource[sourceFilePath] then
            sourceOnMultipleTracks = true
        end
        totalsBySource[sourceFilePath] = (totalsBySource[sourceFilePath] or 0) + length
        local formattedLength = SecondsToHHMMSS(length)
        local sourceFileName = GetFilenameFromPath(sourceFilePath) or "MIDI items"
        reaper.ShowConsoleMsg(string.format(formatString, t, sourceFileName, formattedLength) .. "\n")
        t = "" -- print track name on first iteration only
    end
    reaper.ShowConsoleMsg(string.format(formatStringTotal, t, "TOTAL", formattedTotalLength) .. "\n")
    reaper.ShowConsoleMsg(string.rep("-", maxTrackNameLength + maxFileNameLength + p*2 + 8) .. "\n")
end

if sourceOnMultipleTracks then
    reaper.ShowConsoleMsg("\nTotal lengths by source:\n")
    for sourceFilePath, length in pairs(totalsBySource) do
        local formattedLength = SecondsToHHMMSS(length)
        local sourceFileName = GetFilenameFromPath(sourceFilePath) or "MIDI items"
        reaper.ShowConsoleMsg(string.format(formatString, "", sourceFileName, formattedLength) .. "\n")
    end
end

reaper.ShowConsoleMsg("\n")

if startMarker then
    reaper.ShowConsoleMsg("Note: Disregarded anything before '=START' marker \n")
end
if endMarker then
    reaper.ShowConsoleMsg("Note: Disregarded anything after '=END' marker \n")
end

local sourceTotal = 0
for _, _ in pairs(totalsBySource) do
    sourceTotal = sourceTotal + 1
end

reaper.ShowConsoleMsg("\nFun Fact: The selected tracks comprise " .. ItemTotal .. " items from " .. sourceTotal .. " different source files \n")

-- Cleanup
reaper.UpdateArrange()
