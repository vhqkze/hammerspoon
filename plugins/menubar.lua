---@diagnostic disable: lowercase-global, undefined-doc-name
menu = hs.menubar.new()
local log = hs.logger.new("menubar", "debug")
local coffeeIcon = hs.image.imageFromPath("assets/icon_coffee.png"):setSize({ h = 20, w = 20 })
local defaultIcon = hs.image.imageFromPath("assets/statusicon.pdf")

---@class caffeine
---@field start number 咖啡因开始时间
---@field stop number 咖啡因结束时间
---@field timer hs.timer? 咖啡因计时器
---@field select string? 咖啡因当前选择
caffeine = { start = 0, stop = 0, timer = nil, select = nil }

pasteboardWatcher = hs.pasteboard.watcher.new(function(content)
    if content == nil then
        return
    end
    new_content = content:gsub("^%s+", ""):gsub("%s+$", "")
    if new_content ~= content then
        hs.pasteboard.setContents(new_content)
    end
end)
pasteboardWatcher:stop()

---判断系统当前是否darkmode
---@return boolean
local function getDarkModeFromSystem()
    -- local _, darkmode = hs.osascript.applescript('tell application "System Events"\nreturn dark mode of appearance preferences\nend tell')
    local _, darkmode = hs.osascript.javascript("Application('System Events').appearancePreferences.darkMode.get()")
    return darkmode
end

-- 设置系统是否夜间模式
---@param state boolean
local function setDarkMode(state)
    hs.osascript.javascript(string.format("Application('System Events').appearancePreferences.darkMode.set(%s)", state))
end

local function getDockAutoHide()
    local result, obj, desc = hs.osascript.applescript('tell application "System Events" to tell dock preferences to get autohide')
    return obj
end

local function getCaffeineTitle()
    if caffeine.start == 0 and caffeine.stop == 0 then
        return "Caffeine"
    elseif caffeine.start > 0 and caffeine.stop == 0 then
        return "Caffeine Forever"
    elseif caffeine.start < caffeine.stop then
        local remain = caffeine.stop - os.time()
        if remain < 0 then
            return "Caffeine, Remain 0s"
        end
        local hour = remain // 3600
        local minute = (remain - hour * 3600) // 60
        local second = remain - hour * 3600 - minute * 60
        if hour > 0 then
            return "Caffeine, Remain " .. string.format("%02d:%02d:%02d", hour, minute, second)
        elseif minute > 0 then
            return "Caffeine, Remain " .. string.format("%02d:%02d", minute, second)
        else
            return "Caffeine, Remain " .. second .. "s"
        end
    end
end

--- 重置caffeine
---@param interval integer? 为0则立即停止；为nil表示不停止；为数字表示在该段时间
local function reset_caffeine(interval)
    caffeine.select = nil
    if caffeine.timer ~= nil then
        caffeine.timer:stop()
        caffeine.timer = nil
    end
    caffeine.start = 0
    caffeine.stop = 0
    if interval == 0 then
        hs.caffeinate.set("displayIdle", false, true)
        menu:setIcon(defaultIcon)
        return
    elseif interval == nil then
        hs.caffeinate.set("displayIdle", true, true)
        menu:setIcon(coffeeIcon)
        caffeine.start = os.time()
        caffeine.stop = 0
        return
    end
    hs.caffeinate.set("displayIdle", true, true)
    menu:setIcon(coffeeIcon)
    caffeine.start = os.time()
    caffeine.stop = caffeine.start + interval
    caffeine.timer = hs.timer.doAfter(interval, function()
        hs.caffeinate.set("displayIdle", false, true)
        menu:setIcon(defaultIcon)
        caffeine.select = nil
        caffeine.timer = nil
        caffeine.start = 0
        caffeine.stop = 0
    end)
end

local menus = function()
    log.i("caffeine", os.date("%Y-%m-%d %H:%M:%S", caffeine.start), os.date("%Y-%m-%d %H:%M:%S", caffeine.stop))
    local myMiniTools = {
        {
            title = "Dark Mode",
            checked = getDarkModeFromSystem(),
            fn = function()
                setDarkMode(not getDarkModeFromSystem())
            end,
        },
        {
            title = "Gray Mode",
            checked = hs.screen.getForceToGray(),
            fn = function()
                hs.screen.setForceToGray(not hs.screen.getForceToGray())
            end,
        },
        {
            title = getCaffeineTitle(),
            checked = hs.caffeinate.get("displayIdle"),
            menu = {
                {
                    title = "Stop",
                    fn = function()
                        reset_caffeine(0)
                    end,
                },
                {
                    title = "Forever",
                    checked = caffeine.select == "forever",
                    fn = function()
                        reset_caffeine()
                        caffeine.select = "forever"
                    end,
                },
                {
                    title = "30 minutes",
                    checked = caffeine.select == "30",
                    fn = function()
                        reset_caffeine(hs.timer.minutes(30))
                        caffeine.select = "30"
                    end,
                },
                {
                    title = "1 hour",
                    checked = caffeine.select == "60",
                    fn = function()
                        reset_caffeine(hs.timer.hours(1))
                        caffeine.select = "60"
                    end,
                },
                {
                    title = "2 hours",
                    checked = caffeine.select == "120",
                    fn = function()
                        reset_caffeine(hs.timer.hours(2))
                        caffeine.select = "120"
                    end,
                },
                {
                    title = "Custom minutes",
                    checked = caffeine.select == "custom",
                    fn = function()
                        local lastApplication = hs.application.frontmostApplication()
                        hs.focus()
                        local button, interval = hs.dialog.textPrompt("自定义咖啡因时间", "请输入整数", "30", "OK", "Cancel")
                        if lastApplication then
                            lastApplication:activate()
                        end
                        if button ~= "OK" then
                            return
                        end
                        interval = tonumber(interval)
                        if interval == nil or interval < 0 then
                            hs.alert.show("请输入数字")
                            return
                        end
                        reset_caffeine(hs.timer.minutes(interval))
                        caffeine.select = "custom"
                    end,
                },
            },
        },
        {
            title = "Auto Trim Pasteboard",
            checked = pasteboardWatcher:running(),
            fn = function()
                if pasteboardWatcher:running() then
                    pasteboardWatcher:stop()
                else
                    pasteboardWatcher:start()
                end
            end,
        },
        {
            title = "Auto Hide Dock",
            checked = getDockAutoHide(),
            fn = function()
                hs.osascript.applescript('tell application "System Events" to tell dock preferences to set autohide to not autohide')
            end,
        },
        {
            title = "Screen Saver",
            fn = hs.caffeinate.startScreensaver,
        },
        {
            title = "-",
        },
        {
            title = "EncodeDecode",
            menu = {
                {
                    title = "str/img to base64",
                    fn = function()
                        local content = hs.pasteboard.readImage()
                        if content ~= nil then
                            local result = content:encodeAsURLString()
                            hs.pasteboard.writeObjects(result)
                            hs.alert.show("image to base64 success")
                        else
                            content = hs.pasteboard.readString()
                            if content ~= nil then
                                hs.pasteboard.writeObjects(hs.base64.encode(content))
                                hs.alert.show("str to base64 success")
                            end
                        end
                    end,
                },
                {
                    title = "base64 to str",
                    fn = function()
                        local content = hs.pasteboard.readString()
                        if content ~= nil then
                            local str = hs.base64.decode(content)
                            hs.pasteboard.writeObjects(str)
                            hs.alert.show(str)
                        end
                    end,
                },
            },
        },
        {
            title = "-",
        },
        {
            title = "Hammerspoon",
            menu = {
                {
                    title = "Console...",
                    fn = hs.openConsole,
                },
                {
                    title = "Show Docs",
                    fn = function()
                        hs.doc.hsdocs.start()
                        local port = hs.doc.hsdocs.port()
                        hs.execute("open http://fbi.com:" .. port)
                    end,
                },
                {
                    title = "Preferences...",
                    fn = hs.openPreferences,
                },
                {
                    title = "About Hammerspoon",
                    fn = hs.openAbout,
                },
                {
                    title = "Reload Config",
                    fn = hs.reload,
                },
                {
                    title = "Restart",
                    fn = hs.relaunch,
                },
                {
                    title = "Check for Updates...",
                    fn = function()
                        hs.checkForUpdates()
                    end,
                },
                {
                    title = "Quit Hammerspoon",
                    fn = function()
                        local app = hs.application.applicationForPID(hs.processInfo["processID"])
                        app:kill()
                    end,
                },
            },
        },
        {
            title = "Show Desktop",
            fn = function()
                for _, win in pairs(hs.window.allWindows()) do
                    win:minimize()
                end
            end,
        },
    }
    return myMiniTools
end

menu:setIcon(hs.caffeinate.get("displayIdle") and coffeeIcon or defaultIcon)
menu:setMenu(menus)
menu:setTitle()

-- DarkMode watcher
local lastUIAppearance = getDarkModeFromSystem()
nightWatcher = hs.distributednotifications.new(function(name, object, userInfo)
    local currentUIAppearance = getDarkModeFromSystem()
    if currentUIAppearance ~= lastUIAppearance then
        if currentUIAppearance then
            hs.alert.show("Dark Mode ON")
        else
            hs.alert.show("Dark Mode OFF")
        end
    end
    lastUIAppearance = currentUIAppearance
end, "AppleInterfaceThemeChangedNotification")
nightWatcher:start()

hs.menuIcon(false)
