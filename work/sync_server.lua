---@diagnostic disable: lowercase-global
---启动一个web服务器，用于接收请求并将请求内容复制到系统剪贴板
---/pic: 将请求内容保存到 ~/Pictures/Screenshots/ 下，png格式，然后将图片复制到剪贴板
---/text: 将文本复制到剪贴板
---/video: 将请求内容保存到 ~/Pictures/Screenshots/ 下，mp4格式，然后将视频复制到剪贴板
---/clip: 将电脑剪贴板内的文字或图片做为响应返回（手机接收后复制到手机剪贴板，实现电脑剪贴板同步到手机剪贴板）

local log = hs.logger.new("sync_server", "debug")
local port = 8863

sync_server = hs.httpserver.new(false, false)
sync_server:setPort(port)
sync_server:setCallback(function(method, path, reqheaders, reqbody)
    log.f("收到请求%s %s %s", method, path, hs.inspect(reqheaders))
    if reqheaders["token"] ~= hs.settings.get("server_token") or reqheaders["X-Remote-Addr"] ~= "127.0.0.1" then
        return "", 451, {}
    end
    if method ~= "POST" then
        return "", 405, {}
    end
    if path == "/pic" then
        log.i("received pic")
        local filename = os.getenv("HOME") .. "/Pictures/Screenshots/" .. os.date("PIC_%Y%m%d_%H%M%S") .. ".png"
        require("utils.file").save(reqbody, filename)
        if require("utils.file").copy(filename) then
            hs.alert.show("图片已复制")
        else
            hs.alert.show("图片复制失败")
        end
        return "ok", 200, {}
    elseif path == "/text" then
        log.i("received text")
        local result = hs.json.decode(reqbody)
        if hs.pasteboard.writeObjects(result["text"]) then
            hs.alert.show("文本已复制")
        else
            hs.alert.show("文本复制失败")
        end
        return "ok", 200, {}
    elseif path == "/video" then
        log.i("received video")
        local filename = os.getenv("HOME") .. "/Pictures/Screenshots/" .. os.date("VID_%Y%m%d_%H%M%S") .. ".mp4"
        require("utils.file").save(reqbody, filename)
        if require("utils.file").copy(filename) then
            hs.alert.show("视频已复制")
        else
            hs.alert.show("视频复制失败")
        end
        return "ok", 200, {}
    elseif path == "/clip" then
        log.i("received clip")
        local content_type = hs.pasteboard.contentTypes()[1]
        local body = {}
        if content_type == "public.utf8-plain-text" or content_type == "public.rtf" then
            body = { text = hs.pasteboard.readString() }
        elseif content_type == "public.tiff" or content_type == "public.png" then
            body = { image = hs.pasteboard.readImage():encodeAsURLString() }
        else
            log.w("未知的剪贴板内容类型", content_type)
        end
        return hs.json.encode(body), 200, { ["content-type"] = "application/json" }
    end
    return "", 404, {}
end)
sync_server:start()
