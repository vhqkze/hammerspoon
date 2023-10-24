---@diagnostic disable: undefined-doc-name, undefined-field
local M = {}

--- 对app窗口截图，复制到剪贴板
---@param window hs.window
---@return boolean
function M.shot_app(window)
    if window ~= nil then
        if window:isVisible() then
            local im = window:snapshot()
            local size = im:size()
            -- 在我的电脑上这个大小的窗口截图后左右两侧有黑边，去掉黑边
            if window:title() == '影片录制' and size.h == 1200 and size.w == 556 then
                if hs.pasteboard.writeObjects(im:croppedCopy({ x = 1, y = 1, w = 554, h = 1198 })) then
                    return true
                end
            elseif hs.pasteboard.writeObjects(im) then
                return true
            end
        else
            local windowid = window:id()
            local op, status, t, rc = hs.execute("/usr/sbin/screencapture -ocxl " .. windowid)
            if status then
                local im = hs.pasteboard.readImage()
                local size = im:size()
                -- 在我的电脑上这个大小的窗口截图后左右两侧有黑边，去掉黑边
                if window:title() == '影片录制' and size.h == 1200 and size.w == 556 then
                    if hs.pasteboard.writeObjects(im:croppedCopy({ x = 1, y = 1, w = 554, h = 1198 })) then
                        return true
                    end
                elseif hs.pasteboard.writeObjects(im) then
                    return true
                end
            end
        end
    end
    return false
end

return M
