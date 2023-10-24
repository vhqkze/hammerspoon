-- 检测Wi-Fi变更
local wifi_home = hs.settings.get("wifi_home")
local wifi_work = hs.settings.get("wifi_work")
local wifi = require("hs.wifi")
local lastSSID = wifi.currentNetwork()
local notify = require("hs.notify")
local notify_fail = nil
local log = hs.logger.new("network", "debug")

if lastSSID == wifi_work then
    -- hs.audiodevice.defaultOutputDevice():setVolume(0)
    hs.audiodevice.findOutputByUID("BuiltInSpeakerDevice"):setVolume(0)
    notify.new({ title = "网络变更", informativeText = "已连接到公司网络" .. os.date("%Y-%m-%d %H:%M:%S") }):send()
end

--- 检测网络是否连接成功
---@return boolean
local function is_connected()
    local status_code = hs.http.get("http://connect.rom.miui.com/generate_204")
    return status_code == 204
end

local function ssidChangedCallback()
    local newSSID = wifi.currentNetwork()
    if newSSID == wifi_home and lastSSID ~= wifi_home then
        if notify_fail ~= nil then
            pcall(notify_fail:withdraw())
        end
        log.i("已连接到家庭网络")
        hs.audiodevice.defaultOutputDevice():setVolume(30)
        notify.new({ title = "网络变更", informativeText = "已连接到家庭网络" .. os.date("%Y-%m-%d %H:%M:%S") }):send()
    elseif newSSID == wifi_work and lastSSID ~= wifi_work then
        if notify_fail ~= nil then
            pcall(notify_fail:withdraw())
        end
        log.i("已连接到公司网络")
        hs.audiodevice.defaultOutputDevice():setVolume(0)
        notify.new({ title = "网络变更", informativeText = "已连接到公司网络" .. os.date("%Y-%m-%d %H:%M:%S") }):send()
    elseif newSSID ~= wifi_work and lastSSID == wifi_work then
        log.i("公司网络已断开连接")
        notify_fail = notify.new({
            title = "网络变更",
            informativeText = "公司网络已断开连接" .. os.date("%Y-%m-%d %H:%M:%S"),
            withdrawAfter = 0,
        })
        notify_fail:send()
        hs.timer.doAfter(3, function()
            if is_connected() == false then
                hs.execute("networksetup -setairportnetwork en1 " .. wifi_work)
            end
        end)
    end

    lastSSID = newSSID
end

wifiWatcher = wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()
