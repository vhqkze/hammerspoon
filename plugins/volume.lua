local log = hs.logger.new("volume", "debug")
hs.audiodevice.watcher.setCallback(function(event)
    if event == "dOut" then
        local current = hs.audiodevice.current(false)
        log.i("输出设备改变为", current.name)
        hs.execute("sketchybar --trigger audiodevice_change", true)
        if current.uid == "BuiltInSpeakerDevice" then
            log.i("重置电脑音量为0")
            current.device:setOutputVolume(0)
        elseif current.name:lower():match("airpods") then
            log.i("重置airpods音量")
            current.device:setOutputVolume(20)
        elseif current.volume > 30 then
            log.i("重置音量为30")
            current.device:setOutputVolume(20)
        end
    end
end)
hs.audiodevice.watcher.start()
