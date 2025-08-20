---@diagnostic disable: undefined-doc-name, undefined-field
local M = {}
M.save_dir = os.getenv("HOME") .. "/Pictures/mobile"
hs.fs.mkdir(M.save_dir)

--- 对app窗口截图，复制到剪贴板
---@param window hs.window
---@return boolean
function M.shot_app(window)
    if window ~= nil then
        if window:isVisible() then
            local im = window:snapshot(true)
            local filename = string.format("%s/PIC_%s.png", M.save_dir, os.date("%Y%m%d_%H%M%S"))
            im:saveToFile(filename)
            if hs.pasteboard.writeObjects(im) then
                return true
            end
        else
            local windowid = window:id()
            local op, status, t, rc = hs.execute("/usr/sbin/screencapture -ocxl " .. windowid)
            if status then
                local im = hs.pasteboard.readImage()
                local filename = string.format("%s/PIC_%s.png", M.save_dir, os.date("%Y%m%d_%H%M%S"))
                im:saveToFile(filename)
                return true
            end
        end
    end
    return false
end

return M
