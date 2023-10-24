---@diagnostic disable: lowercase-global
local log = hs.logger.new("check_in_out", "debug")
log.i("初始化打卡监控程序")
check_out_is_done = false

local function has_checked()
    local cmd = "cd ~/Developer/minitools && poetry run python work/check_in_out.py"
    local output, status, t, rc = hs.execute(cmd, true)
    log.f("output: %s, status: %s, type: %s, return_code: %s", output, status, t, rc)
    return rc == 0
end

-- 上班检查是否打卡
check_work_in = hs.timer.doAt("9:55", hs.timer.days(1), function()
    log.i("开始检查是否上班打卡")
    if os.date("*t").wday == 7 then
        log.i("今天是周六，不用上班")
        return
    end
    if not has_checked() then
        log.i("检测到没有打卡，开始发送系统通知")
        require("utils.notify").bark("没有打卡", "未打卡提醒", "打卡", "timeSensitive", "glass")
        hs.notify.new():title("没有打卡"):informativeText("还没有打开，快点打卡"):withdrawAfter(hs.timer.minutes(10)):send()
    end
end)

--- 检查下班是否打卡
--- 如果是周六，或者check_out_is_done为true,则不执行
--- 每隔5s检查一次check_out_is_done, 为false则开始检查是否下班，如果为true，则结束程序
--- 检查下班打卡，先判断电脑是否在使用（空闲时间超过3分钟即视为已下班）
--- 如果人已下班，启动脚本检查是否打卡
--- 如果未打卡，发打卡失败通知，修改check_out_is_done为true(以让下次5s循环判断返回true，停止程序)
---     如果在电脑端点击了失败通知，则判断人还在电脑工作，则修改check_out_is_done为false，继续循环判断
--- 如果已打卡，发打卡成功通知，修改check_out_is_done为true(以让下次5s循环判断返回true，停止程序)
function start_check_out()
    hs.timer.doUntil(function()
        log.i("检查是否完成")
        if os.date("*t").wday == 7 then
            log.i("今天是周六，不用上班")
            return true
        end
        if check_out_is_done then
            log.i("已经完成，修改check_out_is_done为false，然后结束")
            check_out_is_done = false
            return true
        end
        log.i("未完成，继续监控")
        return false
    end, function()
        log.i("开始检查下班打卡")
        check_out_is_done = false
        local idle_time = hs.host.idleTime()
        if idle_time < hs.timer.minutes(3) then
            log.i("空闲时间低于3分钟，跳过")
            return
        end
        log.i("不活跃超过3分钟，开始执行检查")
        if has_checked() then
            log.i("已经打卡下班，结束")
            require("utils.notify").bark("已打下班卡", "打卡成功", "打卡", "timeSensitive", "bell")
            check_out_is_done = true
            return
        end
        log.i("下班没有打卡，发送系统通知")
        require("utils.notify").bark("没有打卡", "未打卡提醒", "打卡", "timeSensitive", "glass")
        noti = hs.notify.new(function(notify)
            local action = notify:activationType()
            if action == hs.notify.activationTypes.actionButtonClicked or action == hs.notify.activationTypes.contentsClicked then
                check_out_is_done = false
                start_check_out()
            end
        end)
        noti:title("没有打卡")
            :informativeText("没有打开，快去打卡")
            :actionButtonTitle("继续监控")
            :hasActionButton(true)
            :withdrawAfter(hs.timer.minutes(120))
        noti:send()
        check_out_is_done = true
    end, hs.timer.seconds(5)) -- 每隔5s时间检查一次系统空闲时间
end

-- 每晚22:00开始检查是否下班打卡
check_work_out = hs.timer.doAt("22:00", hs.timer.days(1), start_check_out)

-- 如果晚上22:00~06:59之间重启了hammerspoon，启动下班检查
if os.date("%H") >= "22" or os.date("%H") <= "06" then
    start_check_out()
end
