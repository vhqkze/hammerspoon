local log = hs.logger.new("window_manager", "debug")

local stepw = 48
local steph = 25

local tray = hs.canvas.new({ x = 0, y = 0, w = 285, h = 45 })
tray:appendElements({
    id = "show edit",
    type = "text",
    text = "Edit Mode",
    textSize = 30,
    textFont = "Iosevka",
    textAlignment = "right",
    textColor = { hex = "#FF0000", alpha = 1 },
})


-- cwin: 当前活动窗口
-- cscreen: 当前活动窗口所在屏幕，screen对应实际物理屏幕


--- WinWin:stepMove(direction)
--- Method
--- Move the focused window in the `direction` by on step. The step scale equals to the width/height of one gridpart.
---
--- Parameters:
---  - direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`.
---  - step: step
local function stepMove(direction, step)
    -- 移动活动窗口
    local cwin = hs.window.focusedWindow()
    if not cwin then
        hs.alert.show("No focused window!")
        return
    end
    local stepx = step and step or stepw
    local stepy = step and step or steph
    local wf = cwin:frame()
    local axApp = hs.axuielement.applicationElement(cwin:application())
    local wasEnhanced = axApp.AXEnhancedUserInterface
    axApp.AXEnhancedUserInterface = wasEnhanced and false or false
    if direction == "left" then
        cwin:setFrame({ x = wf.x - stepx, y = wf.y, w = wf.w, h = wf.h })
    elseif direction == "right" then
        cwin:setFrame({ x = wf.x + stepx, y = wf.y, w = wf.w, h = wf.h })
    elseif direction == "up" then
        cwin:setFrame({ x = wf.x, y = wf.y - stepy, w = wf.w, h = wf.h })
    elseif direction == "down" then
        cwin:setFrame({ x = wf.x, y = wf.y + stepy, w = wf.w, h = wf.h })
    end
    if wasEnhanced then
        hs.timer.doAfter(0.4, function ()
            axApp.AXEnhancedUserInterface = true
        end)
    end
end

--- Resize the focused window in the `direction` by on step.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: 
---     - `leftLeft`, `leftRight`, `rightLeft`, `rightRight`,
---     - `upUp`, `upDown`, `downUp`, `downDown`,
---     - `expand`, `shrink`.
--- * step
local function stepResize(direction, step)
    -- 移动活动窗口边界以放大、缩小窗口
    local cwin = hs.window.focusedWindow()
    if not cwin then
        hs.alert.show("No focused window!")
        return
    end
    local stepx = step and step or stepw
    local stepy = step and step or steph
    local wf = cwin:frame() -- 窗口的位置和大小
    local options = {
        leftLeft   = function () cwin:setFrame({ x = wf.x - stepx, y = wf.y,         w = wf.w + stepx,     h = wf.h             }) end,
        leftRight  = function () cwin:setFrame({ x = wf.x + stepx, y = wf.y,         w = wf.w - stepx,     h = wf.h             }) end,
        rightLeft  = function () cwin:setFrame({ x = wf.x,         y = wf.y,         w = wf.w - stepx,     h = wf.h             }) end,
        rightRight = function () cwin:setFrame({ x = wf.x,         y = wf.y,         w = wf.w + stepx,     h = wf.h             }) end,
        upUp       = function () cwin:setFrame({ x = wf.x,         y = wf.y - stepy, w = wf.w,             h = wf.h + stepy     }) end,
        upDown     = function () cwin:setFrame({ x = wf.x,         y = wf.y + stepy, w = wf.w,             h = wf.h - stepy     }) end,
        downUp     = function () cwin:setFrame({ x = wf.x,         y = wf.y,         w = wf.w,             h = wf.h - stepy     }) end,
        downDown   = function () cwin:setFrame({ x = wf.x,         y = wf.y,         w = wf.w,             h = wf.h + stepy     }) end,
        expand     = function () cwin:setFrame({ x = wf.x - stepx, y = wf.y - stepy, w = wf.w + stepx * 2, h = wf.h + stepy * 2 }) end,
        shrink     = function () cwin:setFrame({ x = wf.x + stepx, y = wf.y + stepy, w = wf.w - stepx * 2, h = wf.h - stepy * 2 }) end,
    }
    if options[direction] then
        local axApp = hs.axuielement.applicationElement(cwin:application())
        local wasEnhanced = axApp.AXEnhancedUserInterface
        axApp.AXEnhancedUserInterface = wasEnhanced and false or false
        options[direction]()
        axApp.AXEnhancedUserInterface = wasEnhanced and true or false
        if wasEnhanced then
            hs.timer.doAfter(0.4, function ()
                axApp.AXEnhancedUserInterface = true
            end)
        end
    else
        log.df("Unknown direction: " .. direction)
    end
end

--- WinWin:moveAndResize(option)
--- Method
--- Move and resize the focused window.
---
--- Parameters:
---  * option - A string specifying the option, valid strings are: 
---     - `halfleft`, `halfright`, `halfup`, `halfdown`
---     - `cornerNW`, `cornerSW`, `cornerNE`, `cornerSE`
---     - `center`, `fullscreen`, `normal`, `maximum`.
local function moveAndResize(option)
    local cwin = hs.window.focusedWindow()
    if not cwin then
        hs.alert.show("No focused window!")
        return
    end
    local cscreen = cwin:screen() -- 窗口所在的屏幕
    local csf = cscreen:frame() -- 不包含menu、dock后的屏幕尺寸, x,y,w,h
    local wf = cwin:frame() -- 窗口位置大小, x,y,w,h
    log.df("当前窗口位置: %s", wf)
    log.df("当前屏幕可用大小: %s", csf)
    local options = {
        halfleft = function ()
            if math.abs(wf.x - csf.x) < 3 and math.abs(wf.y - csf.y) < 3 and math.abs(wf.w - csf.w / 2) < 3 and math.abs(wf.h - csf.h) < 3 then
                cwin:moveToUnit({x = 0, y = 0, w = 1/3, h = 1})  -- 如果当前为左1/2，则设为左1/3
            elseif math.abs(wf.x - csf.x) < 3 and math.abs(wf.y - csf.y) < 3 and math.abs(wf.w - csf.w / 3) < 3 and math.abs(wf.h - csf.h) < 3 then
                cwin:moveToUnit({x = 0, y = 0, w = 1/4, h = 1})  -- 如果当前为左1/3，则设为左1/4
            else
                cwin:moveToUnit({x = 0, y = 0, w = 1/2, h = 1})
            end
        end,
        halfright = function ()
            if math.abs(wf.x - csf.w / 2) < 3 and math.abs(wf.y - csf.y) < 3 and math.abs(wf.w - csf.w / 2) < 3 and math.abs(wf.h - csf.h) < 3 then
                cwin:moveToUnit({x = 2/3, y = 0, w = 1/3, h = 1})  -- 如果当前为右1/2，则设为右1/3
            elseif math.abs(wf.x - csf.w / 3 * 2) < 3 and math.abs(wf.y - csf.y) < 3 and math.abs(wf.w - csf.w / 3) < 3 and math.abs(wf.h - csf.h) < 3 then
                cwin:moveToUnit({x = 3/4, y = 0, w = 1/4, h = 1})  -- 如果当前为右1/3，则设为右1/4
            else
                cwin:moveToUnit({x = 1/2, y = 0, w = 1/2, h = 1})  -- 设为右1/2
            end
        end,
        halfup   = function () cwin:moveToUnit({x = 0,   y = 0,   w = 1,   h = 1/2}) end,  -- 半上
        halfdown = function () cwin:moveToUnit({x = 0,   y = 1/2, w = 1,   h = 1/2}) end,  -- 半下
        cornerNW = function () cwin:moveToUnit({x = 0,   y = 0,   w = 1/2, h = 1/2}) end,  -- 左上
        cornerNE = function () cwin:moveToUnit({x = 1/2, y = 0,   w = 1/2, h = 1/2}) end,  -- 右上
        cornerSW = function () cwin:moveToUnit({x = 0,   y = 1/2, w = 1/2, h = 1/2}) end,  -- 左下
        cornerSE = function () cwin:moveToUnit({x = 1/2, y = 1/2, w = 1/2, h = 1/2}) end,  -- 右下
        fullscreen = function ()
            cwin:toggleFullScreen()
        end,
        maximum = function ()
            cwin:setFrame(cscreen:frame())
            -- cwin:toggleZoom()  -- 不好用，可能会全屏
        end,
        normal = function ()
            -- cwin:setFrame({ x = csf.w * 0.2 + csf.x, y = csf.h * 0.17 + csf.y, w = csf.w * 0.6, h = csf.h * 0.66 })
            local new_w = csf.w * 0.6 // stepw * stepw
            local new_h = csf.h * 0.7 // steph * steph
            local new_x = (csf.w - new_w) // 2 + csf.x
            local new_y = (csf.h - new_h) // 2 + csf.y
            cwin:setFrame({x = new_x, y = new_y, w = new_w, h = new_h})
        end,
        center = function ()
            -- cwin:centerOnScreen()
            cwin:setFrame({ x = (csf.w - wf.w) // 2 + csf.x, y = (csf.h - wf.h) // 2 + csf.y, w = wf.w, h = wf.h })
        end,
    }
    if options[option] then
        local axApp = hs.axuielement.applicationElement(cwin:application())
        local wasEnhanced = axApp.AXEnhancedUserInterface
        axApp.AXEnhancedUserInterface = wasEnhanced and false or false
        options[option]()
        if wasEnhanced then
            hs.timer.doAfter(0.4, function ()
                axApp.AXEnhancedUserInterface = true
            end)
        end
    else
        hs.alert.show("Unknown option: " .. option)
    end
end

--- WinWin:moveToScreen(direction)
--- Method
--- Move the focused window between all of the screens in the `direction`.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`, `next`.
local function moveToScreen(direction)
    local cwin = hs.window.focusedWindow()
    if not cwin then
        hs.alert.show("No focused window!")
        return
    end
    local cscreen = cwin:screen()
    if direction == "up" then
        cwin:moveOneScreenNorth()
    elseif direction == "down" then
        cwin:moveOneScreenSouth()
    elseif direction == "left" then
        cwin:moveOneScreenWest()
    elseif direction == "right" then
        cwin:moveOneScreenEast()
    elseif direction == "next" then
        cwin:moveToScreen(cscreen:next())
    end
end

-- 定义快捷键进入窗口编辑模式
local k = hs.hotkey.modal.new("", "f8")
function k:entered()
    hs.alert.show("Enter Edit Mode")
    local cscreen = hs.screen.mainScreen()
    local cres = cscreen:fullFrame()
    tray:frame({ x = cres.w - 300, y = cres.h - 45, w = 285, h = 45 })
    tray:show()
    -- automatic exit edit mode after 1s
    -- window_mode_timer = hs.timer.waitUntil(function()
    hs.timer.waitUntil(function()
        return hs.host.idleTime() > 1
    end, function()
        k:exit()
    end, 0.1)
end

function k:exited()
    tray:delete()
end

-- 退出编辑模式
k:bind("", "escape", function() k:exit() end)
k:bind("", "q",      function() k:exit() end)

-- 调整窗口边界 -> 放大窗口
k:bind("",     "a", function() stepResize("leftLeft")      end, nil, function() stepResize("leftLeft")      end)
k:bind("",     "s", function() stepResize("downDown")      end, nil, function() stepResize("downDown")      end)
k:bind("",     "d", function() stepResize("upUp")          end, nil, function() stepResize("upUp")          end)
k:bind("",     "f", function() stepResize("rightRight")    end, nil, function() stepResize("rightRight")    end)
k:bind("ctrl", "a", function() stepResize("leftLeft",   1) end, nil, function() stepResize("leftLeft",   1) end)
k:bind("ctrl", "s", function() stepResize("downDown",   1) end, nil, function() stepResize("downDown",   1) end)
k:bind("ctrl", "d", function() stepResize("upUp",       1) end, nil, function() stepResize("upUp",       1) end)
k:bind("ctrl", "f", function() stepResize("rightRight", 1) end, nil, function() stepResize("rightRight", 1) end)

-- 调整窗口边界 -> 缩小窗口
k:bind({"shift"},         "a", function() stepResize("leftRight")    end, nil, function() stepResize("leftRight")    end)
k:bind({"shift"},         "s", function() stepResize("downUp")       end, nil, function() stepResize("downUp")       end)
k:bind({"shift"},         "d", function() stepResize("upDown")       end, nil, function() stepResize("upDown")       end)
k:bind({"shift"},         "f", function() stepResize("rightLeft")    end, nil, function() stepResize("rightLeft")    end)
k:bind({"ctrl", "shift"}, "a", function() stepResize("leftRight", 1) end, nil, function() stepResize("leftRight", 1) end)
k:bind({"ctrl", "shift"}, "s", function() stepResize("downUp",    1) end, nil, function() stepResize("downUp",    1) end)
k:bind({"ctrl", "shift"}, "d", function() stepResize("upDown",    1) end, nil, function() stepResize("upDown",    1) end)
k:bind({"ctrl", "shift"}, "f", function() stepResize("rightLeft", 1) end, nil, function() stepResize("rightLeft", 1) end)

-- 同时调整窗口四个边界
k:bind("",     "-", function() stepResize("shrink")    end, nil, function() stepResize("shrink")    end)
k:bind("",     "=", function() stepResize("expand")    end, nil, function() stepResize("expand")    end)
k:bind("ctrl", "-", function() stepResize("shrink", 1) end, nil, function() stepResize("shrink", 1) end)
k:bind("ctrl", "=", function() stepResize("expand", 1) end, nil, function() stepResize("expand", 1) end)

-- 移动窗口，不改变窗口大小（碰到屏幕边界还是会改变窗口大小的）
k:bind("",     "h", function() stepMove("left")     end, nil, function() stepMove("left")     end)
k:bind("",     "j", function() stepMove("down")     end, nil, function() stepMove("down")     end)
k:bind("",     "k", function() stepMove("up")       end, nil, function() stepMove("up")       end)
k:bind("",     "l", function() stepMove("right")    end, nil, function() stepMove("right")    end)
k:bind("ctrl", "h", function() stepMove("left",  1) end, nil, function() stepMove("left",  1) end)
k:bind("ctrl", "j", function() stepMove("down",  1) end, nil, function() stepMove("down",  1) end)
k:bind("ctrl", "k", function() stepMove("up",    1) end, nil, function() stepMove("up",    1) end)
k:bind("ctrl", "l", function() stepMove("right", 1) end, nil, function() stepMove("right", 1) end)

-- 将窗口移动到特殊位置
k:bind("shift", "h", function() moveAndResize("halfleft")  end)
k:bind("shift", "j", function() moveAndResize("halfdown")  end)
k:bind("shift", "k", function() moveAndResize("halfup")    end)
k:bind("shift", "l", function() moveAndResize("halfright") end)

k:bind("", "m", function() moveAndResize("maximum")    end)
k:bind("", "n", function() moveAndResize("normal")     end)
k:bind("", ",", function() moveAndResize("center")     end)
k:bind("", ".", function() moveAndResize("fullscreen") end)

-- -- win = some `hs.window` instance
-- local axApp = hs.axuielement.applicationElement(win:application())
-- local wasEnhanced = axApp.AXEnhancedUserInterface
-- if wasEnhanced then
-- 	axApp.AXEnhancedUserInterface = false
-- end
-- win:setFrame(newFrame) -- or win:moveToScreen(someScreen), etc.
-- if wasEnhanced then
-- 	axApp.AXEnhancedUserInterface = true
-- end
