---@diagnostic disable: lowercase-global
menu = hs.menubar.new()
local log = hs.logger.new("menubar", "debug")
local coffeeIcon = hs.image.imageFromPath("assets/icon_coffee.png"):setSize({ h = 20, w = 20 })
local defaultIcon = hs.image.imageFromPath("assets/statusicon.pdf")
local caffeine_start = 0
local caffeine_stop = 0
caffeine_timer = nil

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
    if caffeine_start == 0 and caffeine_stop == 0 then
        return "Caffeine"
    elseif caffeine_start > 0 and caffeine_stop == 0 then
        return "Caffeine Forever"
    elseif caffeine_start < caffeine_stop then
        local remain = caffeine_stop - os.time()
        if remain < 0 then
            return "Caffine, Remain 0s"
        end
        local hour = remain // 3600
        local minute = (remain - hour * 3600) // 60
        local second = remain - hour * 3600 - minute * 60
        if hour > 0 then
            return "Caffine, Remain " .. string.format("%02d:%02d:%02d", hour, minute, second)
        elseif minute > 0 then
            return "Caffine, Remain " .. string.format("%02d:%02d", minute, second)
        else
            return "Caffine, Remain " .. second .. "s"
        end
    end
end

local menus = function()
    log.i("caffeine", os.date("%Y-%m-%d %H:%M:%S", caffeine_start), os.date("%Y-%m-%d %H:%M:%S", caffeine_stop))
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
                        hs.caffeinate.set("displayIdle", false, true)
                        menu:setIcon(defaultIcon)
                        if caffeine_timer ~= nil then
                            caffeine_timer:stop()
                            caffeine_timer = nil
                        end
                        caffeine_start = 0
                        caffeine_stop = 0
                    end,
                },
                {
                    title = "Forever",
                    checked = caffeine_start > caffeine_stop,
                    fn = function()
                        if caffeine_timer ~= nil then
                            caffeine_timer:stop()
                            caffeine_timer = nil
                        end
                        hs.caffeinate.set("displayIdle", true, true)
                        menu:setIcon(coffeeIcon)
                        caffeine_start = os.time()
                        caffeine_stop = 0
                    end,
                },
                {
                    title = "30 minutes",
                    checked = caffeine_start + hs.timer.minutes(30) == caffeine_stop,
                    fn = function()
                        if caffeine_timer ~= nil then
                            caffeine_timer:stop()
                        end
                        local interval = hs.timer.minutes(30)
                        hs.caffeinate.set("displayIdle", true, true)
                        menu:setIcon(coffeeIcon)
                        caffeine_start = os.time()
                        caffeine_stop = caffeine_start + interval
                        caffeine_timer = hs.timer.doAfter(interval, function()
                            log.i("开始执行30分钟定时器")
                            hs.caffeinate.set("displayIdle", false, true)
                            menu:setIcon(defaultIcon)
                            caffeine_timer = nil
                            caffeine_start = 0
                            caffeine_stop = 0
                        end)
                    end,
                },
                {
                    title = "1 hour",
                    checked = caffeine_start + hs.timer.hours(1) == caffeine_stop,
                    fn = function()
                        if caffeine_timer ~= nil then
                            caffeine_timer:stop()
                        end
                        local interval = hs.timer.hours(1)
                        hs.caffeinate.set("displayIdle", true, true)
                        menu:setIcon(coffeeIcon)
                        caffeine_start = os.time()
                        caffeine_stop = caffeine_start + interval
                        caffeine_timer = hs.timer.doAfter(interval, function()
                            hs.caffeinate.set("displayIdle", false, true)
                            menu:setIcon(defaultIcon)
                            caffeine_timer = nil
                            caffeine_start = 0
                            caffeine_stop = 0
                        end)
                    end,
                },
                {
                    title = "2 hours",
                    checked = caffeine_start + hs.timer.hours(2) == caffeine_stop,
                    fn = function()
                        if caffeine_timer ~= nil then
                            caffeine_timer:stop()
                        end
                        local interval = hs.timer.hours(2)
                        hs.caffeinate.set("displayIdle", true, true)
                        menu:setIcon(coffeeIcon)
                        caffeine_start = os.time()
                        caffeine_stop = caffeine_start + interval
                        caffeine_timer = hs.timer.doAfter(interval, function()
                            hs.caffeinate.set("displayIdle", false, true)
                            menu:setIcon(defaultIcon)
                            caffeine_timer = nil
                            caffeine_start = 0
                            caffeine_stop = 0
                        end)
                    end,
                },
            },
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
