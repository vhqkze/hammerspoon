local log = hs.logger.new("volume", "debug")
hs.audiodevice.watcher.setCallback(function(event)
    log.i(event, hs.inspect(hs.audiodevice.current()))
    if event == "dOut" then
        log.i("输出设备改变")
        local current = hs.audiodevice.current(false)
        if current.uid == "BuiltInSpeakerDevice" then
            hs.execute("sketchybar --trigger audiodevice_change", true)
            if current.muted == false and current.volume > 0 then
                log.i("重置电脑音量为0")
                current.device:setOutputVolume(0)
            end
        elseif current.name:lower():match("airpods") then
            log.i("当前是airpods")
            hs.execute("sketchybar --trigger audiodevice_change", true)
            if current.muted == false and current.volume > 30 then
                log.i("重置airpods音量")
                current.device:setOutputVolume(20)
            end
        else
            hs.execute("sketchybar --trigger audiodevice_change", true)
        end
    end
end)
hs.audiodevice.watcher.start()
