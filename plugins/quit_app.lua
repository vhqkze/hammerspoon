--- 关闭最后一个窗口后退出app

local log = hs.logger.new("quit_app", "debug")
local apps = {
    "App Store",
    "信息",
    "备忘录",
    "快捷指令",
    "文本编辑",
    "日历",
    "活动监视器",
    "预览",
    "Logseq",
    "Anytype",
    "AFFiNE",
    "面板编辑器",
}

QUIT_APP_WATCHER = hs.window.filter.new(false)
for _, app in pairs(apps) do
    QUIT_APP_WATCHER:allowApp(app)
end

QUIT_APP_WATCHER:subscribe(hs.window.filter.windowDestroyed, function(window, name, event)
    log.i(event, name, window)
    local all_windows = hs.window.filter.new(false):setAppFilter(name, {}):getWindows()
    if next(all_windows) == nil then
        log.i("quit app", name)
        window:application():kill()
    end
end)
