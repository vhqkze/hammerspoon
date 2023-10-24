local convert_home_to_cmd_left = hs.hotkey.new("", "home", nil, function()
    hs.eventtap.keyStroke("cmd", "left")
end)
local convert_end_to_cmd_right = hs.hotkey.new("", "end", nil, function()
    hs.eventtap.keyStroke("cmd", "right")
end)
local convert_shome_to_cmd_sleft = hs.hotkey.new("shift", "home", nil, function()
    hs.eventtap.keyStroke({ "cmd", "shift" }, "left")
end)
local convert_send_to_cmd_sright = hs.hotkey.new("shift", "end", nil, function()
    hs.eventtap.keyStroke({ "cmd", "shift" }, "right")
end)

app_watcher = hs.application.watcher.new(function(name, event, app)
    if
        app == hs.application.get("com.tinyapp.TablePlus")
        or app == hs.application.get("org.hammerspoon.Hammerspoon")
        or app == hs.application.get("com.coderforart.MWeb3")
    then
        if event == hs.application.watcher.activated then
            convert_home_to_cmd_left:enable()
            convert_shome_to_cmd_sleft:enable()
            convert_end_to_cmd_right:enable()
            convert_send_to_cmd_sright:enable()
        elseif event == hs.application.watcher.deactivated then
            convert_home_to_cmd_left:disable()
            convert_shome_to_cmd_sleft:disable()
            convert_end_to_cmd_right:disable()
            convert_send_to_cmd_sright:disable()
        elseif event == hs.application.watcher.terminated then
            convert_home_to_cmd_left:disable()
            convert_shome_to_cmd_sleft:disable()
            convert_end_to_cmd_right:disable()
            convert_send_to_cmd_sright:disable()
        end
    end
end)
app_watcher:start()
