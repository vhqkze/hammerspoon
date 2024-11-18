-- 基于20-20-20规则的用眼休息提醒
-- 每隔5s检查一下电脑空闲时间
-- 如果空闲时间少于2分钟，说明在工作
-- 如果一直工作20分钟，提示休息
-- 提示一直存在，直到真的休息（空闲时间大于20s）
-- 监测到真的休息后，提示关闭，重新开始计时

local log = hs.logger.new("rest", "debug")

REST_REMINDER = {
    rest_time = hs.timer.seconds(20), -- 休息时间
    work_time = hs.timer.minutes(20), -- 持续工作时间，达到该时间触发休息提醒
    idle_time = hs.timer.minutes(2), -- 电脑空闲时间，小于该值视为正在工作
    last_rest = os.time(), -- 上次休息时间
    show_time = os.time(),
}

REST_REMINDER.msg = hs.canvas.new({ x = 0, y = 0, w = 0, h = 0 })
REST_REMINDER.msg[1] = {
    type = "text",
    text = "􀸙 ",
    textFont = "SF Pro",
    textSize = 30,
    textColor = { hex = "#dddddd" },
    textAlignment = "center",
    withShadow = true,
}
local mainScreen = hs.screen.primaryScreen()
local mainRes = mainScreen:fullFrame()
REST_REMINDER.msg:frame({
    x = (mainRes.w - 80) / 2,
    y = (mainRes.h - 80) / 2,
    w = 80,
    h = 80,
})
REST_REMINDER.msg:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)

REST_REMINDER.timer = hs.timer.doEvery(5, function()
    if REST_REMINDER.msg:isShowing() == true then
        if math.min(os.time() - REST_REMINDER.show_time, hs.host.idleTime()) > REST_REMINDER.rest_time then
            REST_REMINDER.last_rest = os.time()
            REST_REMINDER.msg:hide()
            log.i("rest done, start timer.")
        end
    else
        if hs.host.idleTime() > REST_REMINDER.idle_time then
            REST_REMINDER.last_rest = os.time()
        elseif os.time() - REST_REMINDER.last_rest > REST_REMINDER.work_time then
            REST_REMINDER.msg:show()
            REST_REMINDER.show_time = os.time()
            log.i("show rest reminder")
        end
    end
end)

DID_LOCK_WATCHER = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.screensDidLock then
        log.i("screen locked, stop timer.")
        REST_REMINDER.msg:hide()
        REST_REMINDER.timer:stop()
    elseif event == hs.caffeinate.watcher.screensDidUnlock then
        log.i("screen unlocked, start timer.")
        REST_REMINDER.last_rest = os.time()
        REST_REMINDER.msg:hide()
        REST_REMINDER.timer:start()
    end
end)
DID_LOCK_WATCHER:start()
