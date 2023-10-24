local log = hs.logger.new("restart_app", "debug")

restart_whistle = hs.timer.doEvery(hs.timer.minutes(5), function()
    -- 自动重启whistle
    local op = hs.execute("whistle status", true)
    if not op:match("is running") then
        log.e("whistle is not running")
        hs.execute("whistle restart", true)
        log.i("restart whistle")
    end
end)

restart_pastenow = hs.timer.doEvery(hs.timer.seconds(3), function()
    local op, status, t, rc = hs.execute("ps -ef | rg 'PasteNow' | rg -v rg", true)
    if rc ~= 0 then
        log.e("PasteNow is not running")
        hs.execute("open -a /Applications/PasteNow.app", true)
        log.i("restart PasteNow")
    end
end)
