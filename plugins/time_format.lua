-- 时间格式相关
-- 鼠标选中秒级/毫秒级时间戳或年月日时分秒，按下快捷键，显示对应的年月日时分秒或时间戳并复制到剪贴板

hs.hotkey.bind({ "cmd" }, "B", function()
    -- 选中文本后，按下关键键，
    -- 如果选中的文本是毫秒级/秒级时间戳，则转换为年月日时分秒，显示在屏幕上并复制到剪贴板；
    -- 如果选中的文本是年月日时分秒，则转换为秒级时间戳，显示在屏幕上并复制到剪贴板；
    -- 如果不是以上两种，则什么也不会发生。
    local oldText = hs.pasteboard.getContents() -- 记录剪贴板内容
    hs.eventtap.keyStroke({ "cmd" }, "c")
    hs.timer.usleep(25000)
    local text = hs.pasteboard.getContents()
    print("text", text)
    if text == "" then
        hs.pasteboard.setContents(oldText)
        return
    end
    local result
    if string.match(text, "^1%d+$") and #text == 13 then -- 毫秒级时间戳转年月日时分秒
        text = string.sub(text, 1, 10)
        result = os.date("%Y-%m-%d %H:%M:%S", text) -- 秒级时间戳转年月日时分秒
    elseif string.match(text, "^1%d+$") and #text == 10 then
        result = os.date("%Y-%m-%d %H:%M:%S", text)
    elseif string.match(text, "^%d%d%d%d[-/]%d%d?[-/]%d%d? %d%d:%d%d:%d%d$") then -- 年月日时分秒转换为秒级时间戳
        local p = "(%d+)[-/](%d+)[-/](%d+) (%d+):(%d+):(%d+)"
        local year, month, day, hour, minute, second = string.match(text, p)
        result = os.time({ year = year, month = month, day = day, hour = hour, min = minute, sec = second })
    else
        hs.pasteboard.setContents(oldText)
        return
    end
    hs.alert.show(result)
    hs.pasteboard.setContents(result)
end)
