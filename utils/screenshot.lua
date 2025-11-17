---@diagnostic disable: undefined-doc-name, undefined-field
local M = {}
M.save_dir = os.getenv("HOME") .. "/Pictures/mobile"
hs.fs.mkdir(M.save_dir)
local file = require("utils.file")

--- compress png file and copy
---@param filename string original png file
---@param filename_zip string compressed png file
---@return boolean
local function compressAndCopy(filename, filename_zip)
    local _, _, _, rc = hs.execute("pngquant --output " .. filename_zip .. " -- " .. filename, true)
    local retry_count = 0
    if rc == 0 then
        hs.timer.waitUntil(function()
            retry_count = retry_count + 1
            return hs.fs.displayName(filename_zip) ~= nil or retry_count > 10
        end, function()
            file.copy(filename_zip)
        end, hs.timer.seconds(0.3))
        return true
    end
    return false
end

--- 对app窗口截图，复制到剪贴板
---@param window hs.window
---@return boolean
function M.shot_app(window)
    if window ~= nil then
        local filename = string.format("%s/PIC_%s.png", M.save_dir, os.date("%Y%m%d_%H%M%S"))
        local filename_zip = string.format("%s/PIC_%s_zip.png", M.save_dir, os.date("%Y%m%d_%H%M%S"))
        if window:isVisible() then
            local im = window:snapshot(true)
            im:saveToFile(filename)
            if hs.settings.get("compressMobileScreenshot") and compressAndCopy(filename, filename_zip) then
                return true
            elseif hs.pasteboard.writeObjects(im) then
                return true
            end
        else
            local windowid = window:id()
            local _, status, _, _ = hs.execute("/usr/sbin/screencapture -ocxl " .. windowid)
            if status then
                local im = hs.pasteboard.readImage()
                im:saveToFile(filename)
                if hs.settings.get("compressMobileScreenshot") then
                    compressAndCopy(filename, filename_zip)
                end
                return true
            end
        end
    end
    return false
end

return M
