local M = {}
local bark_token = hs.settings.get("bark_token")
local bark_url = "https://api.day.app/" .. bark_token .. "/"

--- 使用hammerspoon发送系统通知
---@param content string 通知内容
---@param title? string 通知标题
---@param subTitle? string 通知副标题
---@param callback? function 回调函数
---@param actionButtonTitle? string 按钮
---@param otherButtonTitle? string 副按钮
---@param soundName? string 通知声音
---@param contentImage? string 通知图片
---@param withdrawAfter? integer 通知关闭时间
---@return hs.notify
function M.notify(content, title, subTitle, callback, actionButtonTitle, otherButtonTitle, soundName, contentImage, withdrawAfter)
    local noti = hs.notify.new()
    if content ~= nil then
        noti:informativeText(content)
    end
    if title ~= nil then
        noti:title(title)
    end
    if subTitle ~= nil then
        noti:subTitle(subTitle)
    end
    if actionButtonTitle ~= nil then
        noti:hasActionButton(true)
        noti:actionButtonTitle(actionButtonTitle)
        if otherButtonTitle ~= nil then
            noti:otherButtonTitle(otherButtonTitle)
        end
    end
    if soundName ~= nil then
        noti:soundName(soundName)
    end
    if contentImage ~= nil then
        noti:contentImage(contentImage)
    end
    if withdrawAfter ~= nil then
        noti:withdrawAfter(withdrawAfter)
    end
    return noti:send()
end

function M.applescript(content, title, subTitle)
    local script = string.format('display notifycation "%s"', content)
    if title ~= nil then
        if subTitle ~= nil then
            script = script .. string.format(' with title "%s" subtitle "%s"', title, subTitle)
        else
            script = script .. string.format(' with title "%s"', title)
        end
    end
    hs.osascript.applescript(content)
    return hs.osascript.applescript(script)
end

--- 发送bark消息
---@param content string 消息内容
---@param title? string 消息标题
---@param group? string 消息分组
---@param level? string 消息等级, 默认为active，可选timeSensitive、passive
---@param sound? string 推送铃声
---@param url? string 点击消息后跳转url
---@param copy? string 点击消息后复制的内容
---@param autoCopy? boolean 是否自动复制
---@param badge? integer 设置角标数字
---@param isArchive? boolean 是否保存消息
---@param icon? string 消息图标
function M.bark(content, title, group, level, sound, url, copy, autoCopy, badge, isArchive, icon)
    local request_url = bark_url .. hs.http.encodeForQuery(content)
    if title ~= nil then
        request_url = bark_url .. hs.http.encodeForQuery(title) .. "/" .. hs.http.encodeForQuery(content)
    end
    local params = ""
    if group ~= nil then
        params = params .. "group=" .. hs.http.encodeForQuery(group) .. "&"
    end
    if level ~= nil then
        params = params .. "level=" .. hs.http.encodeForQuery(level) .. "&"
    end
    if sound ~= nil then
        params = params .. "sound=" .. hs.http.encodeForQuery(sound) .. "&"
    end
    if url ~= nil then
        params = params .. "url=" .. hs.http.encodeForQuery(url) .. "&"
    end
    if copy ~= nil then
        params = params .. "copy=" .. hs.http.encodeForQuery(copy) .. "&"
    end
    if autoCopy ~= nil then
        params = params .. "autoCopy=1&"
    end
    if badge ~= nil then
        params = params .. "badge=" .. hs.http.encodeForQuery(badge) .. "&"
    end
    if isArchive ~= nil then
        params = params .. (isArchive == true and "isArchive=1&" or "isArchive=0&")
    end
    if icon ~= nil then
        params = params .. "icon=" .. hs.http.encodeForQuery(icon) .. "&"
    end
    if params ~= "" then
        request_url = request_url .. "?" .. params:sub(1, -2)
    end
    return hs.http.asyncGet(request_url, nil, function() end)
end

return M
