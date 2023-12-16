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
    local img_tmp = "/tmp/screenshot.png"
    local output, status, t, rc = hs.execute("/usr/local/bin/adb exec-out screencap -p > " .. img_tmp)
    if status then
        if hs.pasteboard.writeObjects(hs.image.imageFromPath(img_tmp)) then
            hs.alert.show("Android: 图片已复制")
            os.remove(img_tmp)
            return
        end
    end
    hs.alert.show("❌ 从安卓设备截图失败")
    os.remove(img_tmp)
end

hs.hotkey.bind({ "option" }, "c", get_image_from_adb)

--- 对ios手机截图，复制到电脑剪贴板
--- 手机通过数据线连接电脑，电脑打开QuickTime Player，选择文件->新建影片录制
--- 录制按钮右边的小箭头点击下，屏幕选择手机，就可以将手机屏幕内容镜像到QuickTime Player上了
--- 通过对QuickTime Player窗口截图，速度较快，但质量较差
local function get_image_from_ios()
    local quicktime = hs.application.get("QuickTime Player")
    if quicktime ~= nil then
        local window = hs.window.filter.new(false):setAppFilter("QuickTime Player", { allowTitles = "影片录制" }):getWindows()[1]
        if window ~= nil then
            local result = screenshot.shot_app(window)
            return hs.alert.show(result and "iOS: 图片已复制" or "❌ 从iOS设备截图失败")
        end
    end
    local bezel = hs.application.get("Bezel")
    if bezel ~= nil and bezel:mainWindow() ~= nil then
        local result = screenshot.shot_app(bezel:mainWindow())
        return hs.alert.show(result and "iOS: 图片已复制" or "❌ 从iOS设备截图失败")
    end
    hs.alert.show("❌ 从iOS设备截图失败")
end

hs.hotkey.bind({ "option" }, "x", get_image_from_ios)
