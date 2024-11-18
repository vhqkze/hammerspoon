---@diagnostic disable: undefined-doc-name, undefined-field
local M = {}

--- 对app窗口截图，复制到剪贴板
---@param window hs.window
---@return boolean
function M.shot_app(window)
    if window ~= nil then
        if window:isVisible() then
            local im = window:snapshot(true)
            local size = im:size()
            local filename = os.getenv("HOME") .. "/Pictures/mobile/PIC_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
            -- 在我的电脑上这个大小的窗口截图后左右两侧有黑边，去掉黑边
            if window:application():name() == "Bezel" and size.h == 2658 and size.w == 1314 then
                im = im:croppedCopy({ x = 72, y = 63, w = 1170, h = 2532 })
                im:saveToFile(filename)
                if hs.pasteboard.writeObjects(im) then
                    return true
                end
            elseif hs.pasteboard.writeObjects(im) then
                im:saveToFile(filename)
                return true
            end
        else
            local windowid = window:id()
            local op, status, t, rc = hs.execute("/usr/sbin/screencapture -ocxl " .. windowid)
            if status then
                local im = hs.pasteboard.readImage()
                local size = im:size()
                local filename = os.getenv("HOME") .. "/Pictures/mobile/PIC_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
                -- 在我的电脑上这个大小的窗口截图后左右两侧有黑边，去掉黑边
                if window:application():name() == "Bezel" and size.h == 2658 and size.w == 1314 then
                    im = im:croppedCopy({ x = 72, y = 63, w = 1170, h = 2532 })
                    im:saveToFile(filename)
                    if hs.pasteboard.writeObjects(im) then
                        return true
                    end
                elseif hs.pasteboard.writeObjects(im) then
                    im:saveToFile(filename)
                    return true
                end
            end
        end
    end
    return false
end

return M
