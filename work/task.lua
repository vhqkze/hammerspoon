menu_task = hs.menubar.new()
local log = hs.logger.new("menu_task", "debug")
local headers = { Authorization = hs.settings.get("apitable_token") }

---获取所有未完成的任务，按状态分组，组成菜单名称
---@return string
local function getTaskCount()
    local filterByFormula = hs.http.encodeForQuery('AND({status}!="测试完成",{status}!="其他")')
    local url = "http://fbi.com:8088/fusion/v1/datasheets/dstua7QMSQYYTbfmSd/records?viewId=viwPw9bRPBpD5&fieldKey=name&filterByFormula="
        .. filterByFormula
    local status_code, response = hs.http.get(url, headers)
    if status_code == 200 then
        local resp = hs.json.decode(response)
        local result = {}
        for _, t in pairs(resp["data"]["records"]) do
            result[t["fields"]["status"]] = result[t["fields"]["status"]] and result[t["fields"]["status"]] + 1 or 1
        end
        local text = ""
        text = text .. (result["未提测"] and "未" .. result["未提测"] or "")
        text = text .. (result["已提测"] and "已" .. result["已提测"] or "")
        text = text .. (result["测试中"] and "测" .. result["测试中"] or "")
        text = text .. (result["阻塞"] and "阻" .. result["阻塞"] or "")
        log.i(text and text or "")
        return text and text or ""
    end
    return ""
end

---获取待办任务，根据状态查询
---@param status string 状态，未提测，已提测，测试中，阻塞
---@param short_status string 返回的简短状态标识
---@return table
local function getTaskByStatus(status, short_status)
    local result = {}
    local filterByFormula = hs.http.encodeForQuery('{status}="' .. status .. '"')
    log.i(filterByFormula)
    local url = "http://fbi.com:8088/fusion/v1/datasheets/dstua7QMSQYYTbfmSd/records?viewId=viwPw9bRPBpD5&fieldKey=name&filterByFormula="
        .. filterByFormula
    local status_code, response = hs.http.get(url, headers)
    log.df("响应码: %s 响应: %s", status_code, response)
    if status_code == 200 then
        local resp = hs.json.decode(response)
        log.i(resp)
        for _, t in pairs(resp["data"]["records"]) do
            table.insert(result, {
                title = short_status .. " " .. t["fields"]["owner_production"] .. "·" .. t["fields"]["title"],
                fn = function()
                    hs.urlevent.openURL(t["fields"]["url"]["text"])
                end,
            })
        end
    end
    return result
end

-- 合并list
---@param table_a table
---@param table_b table
---@return table
local function tableMerge(table_a, table_b)
    if next(table_a) ~= nil and next(table_b) ~= nil then
        table.insert(table_a, { title = "-" })
    end
    for _, t in pairs(table_b) do
        table.insert(table_a, t)
    end
    return table_a
end

---获取任务组成的menu
---@return table
local function getTaskMenu()
    local result = getTaskByStatus("未提测", "未") -- 未提测
    local already = getTaskByStatus("已提测", "已") -- 已提测
    result = tableMerge(result, already)
    local doing = getTaskByStatus("测试中", "测") -- 测试中
    result = tableMerge(result, doing)
    local canot = getTaskByStatus("阻塞", "阻") -- 阻塞
    result = tableMerge(result, canot)
    log.f("table: %s", hs.inspect(result))
    return result
end

local function getTitle()
    local tasks = getTaskCount()
    if tasks and tasks ~= "" then
        return tasks
    end
    return "暂无任务"
end

local menus = function()
    local task = {
        {
            title = "Sync",
            fn = function()
                hs.timer.doAfter(0, function()
                    hs.execute("cd ~/Developer/minitools && poetry run python work/apitable_sync.py > work/apitable_sync.log 2>&1", true)
                end)
            end,
        },
        {
            title = "-",
        },
    }
    return tableMerge(task, getTaskMenu())
end

menu_task:setIcon()
menu_task:setMenu(menus)
menu_task:setTitle(getTitle())

local op, status, t, rc = hs.execute("lsof -i :9234", true)
if status and rc == 0 then
    hs.alert.show("端口9234被占用")
end
apitable_server = hs.httpserver.new(false, false)
apitable_server:setPort(9234)
apitable_server:setCallback(function(method, path, reqheaders, reqbody)
    log.f("收到请求%s %s %s", method, path, hs.inspect(reqheaders))
    if reqheaders["token"] ~= hs.settings.get("server_token") or reqheaders["X-Remote-Addr"] ~= "127.0.0.1" then
        return "", 451, {}
    end
    if method == "POST" and path == "/refresh_menu" then
        hs.execute("sketchybar --trigger task_update", true)
        menu_task:setTitle(getTitle())
        log.i("refresh_menu")
        -- log.i(reqbody)
        return "ok", 200, {}
    end
    return "", 404, {}
end)
apitable_server:start()
