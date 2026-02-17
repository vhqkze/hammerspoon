---@diagnostic disable: undefined-doc-name, undefined-field
local M = {}
local log = hs.logger.new("screenshot", "debug")
M.save_dir = os.getenv("HOME") .. "/Pictures/mobile"
hs.fs.mkdir(M.save_dir)
local file = require("utils.file")

---@param originalImage hs.image
---@param text string
---@return hs.image
function M.add_timestamp(originalImage, text)
    local imageSize = originalImage:size()
    local canvas = hs.canvas.new({ x = 0, y = 0, w = imageSize.w, h = imageSize.h })
    canvas:appendElements({
        type = "image",
        image = originalImage,
        frame = { x = 0, y = 0, w = imageSize.w, h = imageSize.h },
    })
    local padding = 25
    -- 去掉左右padding，文字占据屏幕一半宽度，总共19个字符，一个字符宽度大概是高度的3/5，字符高度即为字体大小
    local fontSize = math.floor((imageSize.w - padding * 2) / 2 / 19 / 3 * 5 + 0.5)
    log.f("图片宽度 %s, 字体大小 %s", imageSize.w, fontSize)
    canvas:appendElements({
        type = "text",
        text = hs.styledtext.new(text, {
            font = { name = "Monaco", size = fontSize }, -- Helvetica
            color = { red = 0, green = 0, blue = 0, alpha = 1.0 },
            shadow = { offset = { h = 0, w = 0 }, blurRadius = 20, color = { red = 230 / 255, green = 230 / 255, blue = 230 / 255, alpha = 1.0 } },
        }),
        frame = {
            x = padding, -- 从左边留出padding，这样文本区域的起点就在左侧
            y = imageSize.h - fontSize - padding * 2, -- 粗略计算文本Y位置，使其在底部上方，在导航栏上方
            w = imageSize.w - (padding * 2), -- 文本区域的宽度
            h = fontSize + (padding * 2), -- 文本区域的高度，略大于字体大小
        },
    })
    return canvas:imageFromCanvas()
end

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
            im = M.add_timestamp(im, tostring(os.date("%Y-%m-%d %H:%M:%S")))
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
                im = M.add_timestamp(im, tostring(os.date("%Y-%m-%d %H:%M:%S")))
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
