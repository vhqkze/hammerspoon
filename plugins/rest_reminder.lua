-- 每隔5s检查一下电脑活跃时间
-- 如果活跃时间少于1分钟，说明在工作
-- 如果一直工作30分钟，提示休息
-- 提示一直存在，直到真的休息（活跃时间大于1分钟）
-- 监测到真的休息后，提示关闭，重新开始计时

REST_REMINDER = {}

REST_REMINDER.last_rest = os.time()
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
        if hs.host.idleTime() > hs.timer.minutes(1) then -- 需要休息1分钟
            REST_REMINDER.last_rest = os.time()
            REST_REMINDER.msg:hide()
        end
    else
        if hs.host.idleTime() > hs.timer.minutes(1) then -- 1分钟不间断工作视为高强度工作
            REST_REMINDER.last_rest = os.time()
        elseif os.time() - REST_REMINDER.last_rest > hs.timer.minutes(30) then -- 连续30分钟工作触发提醒
            REST_REMINDER.msg:show()
        end
    end
end)
