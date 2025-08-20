local screenshot = require("utils.screenshot")

--- 对安卓手机截图，复制到电脑剪贴板
--- 优先对scrcpy窗口截图（速度更快，但不是安卓截图原图），使用以下命令启动scrcpy以去除边框：
---     scrcpy --window-borderless
--- 如果没有检测到scrcpy，则使用adb截图（速度较慢，但质量最好）
local function get_image_from_adb()
    local app = hs.application.get("scrcpy")
    if app ~= nil then
        local window = app:mainWindow()
        local result = screenshot.shot_app(window)
        return hs.alert.show(result and "Android: 图片已复制" or "❌ 从安卓设备截图失败")
    end
    local filename = string.format("%s/PIC_%s.png", screenshot.save_dir, os.date("%Y%m%d_%H%M%S"))
    local _, status, _, _ = hs.execute("adb exec-out screencap -p > " .. filename, true)
    if status then
        if hs.pasteboard.writeObjects(hs.image.imageFromPath(filename)) then
            hs.alert.show("Android: 图片已复制")
            return
        end
    end
    hs.alert.show("❌ 从安卓设备截图失败")
end

hs.hotkey.bind({ "option" }, "c", get_image_from_adb)

--- 对ios手机截图，复制到电脑剪贴板
--- 电脑需安装 Bezel 软件，连接iPhone进行镜像显示后，左上角菜单栏里，对 设备->显示风格 设置为 矩形，这样就不会显示手机边框了
--- 按下快捷键后，会对Bezel的窗口进行截图，所以截图质量和窗口大小有关，为了最好的质量，建议Bezel设置窗口为像素精确。
local function get_image_from_ios()
    local bezel = hs.application.get("Bezel")
    if bezel ~= nil and bezel:mainWindow() ~= nil then
        local result = screenshot.shot_app(bezel:mainWindow())
        return hs.alert.show(result and "iOS: 图片已复制" or "❌ 从iOS设备截图失败")
    end
    hs.alert.show("❌ 从iOS设备截图失败")
end

hs.hotkey.bind({ "option" }, "x", get_image_from_ios)
