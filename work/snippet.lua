-- 粘贴选中的片段
local function completionFn(result)
    if result then
        -- hs.pasteboard.setContents(result.text)
        -- hs.eventtap.keyStroke({ "cmd" }, "V")
        hs.eventtap.keyStrokes(tostring(result.text))
    end
end

local function mobile()
    local s = "152"
    for _ = 1, 8 do
        s = s .. math.random(0, 9)
    end
    return s
end

local function tracking_number(shipping_id)
    local result = ""
    if shipping_id == 1 then
        result = "773"
        for _ = 1, 12 do
            result = result .. math.random(9)
        end
    end
    return result
end

local function get_fake_id()
    local op, status, t, rc = hs.execute("cd ~/Developer/minitools && poetry run python work/fakeid.py", true)
    if status then
        local result = hs.json.decode(op)
        return result
    else
        return {}
    end
end

hs.hotkey.bind({ "cmd" }, "g", function()
    local choices = hs.json.read("assets/snippet.json")
    if choices == nil then
        hs.alert("assets/snippet.json not found")
        return
    end
    local result = get_fake_id()
    table.insert(choices, 2, { text = tracking_number(1), subText = "sto申通" })
    if next(result) ~= nil then
        table.insert(choices, 3, { text = result["name"], subText = "fake_name" })
        table.insert(choices, 4, { text = result["mobile"], subText = "fake_mobile" })
        table.insert(choices, 5, { text = result["id"], subText = "fake_id" })
        table.insert(choices, 6, { text = result["company"], subText = "fake_company" })
        table.insert(choices, 7, { text = result["address"], subText = "fake_address" })
    end
    table.insert(choices, { text = os.date("%Y-%m-%d %H:%M:%S"), subText = "datetime" })
    table.insert(choices, { text = os.time(), subText = "timestamp" })
    table.insert(choices, { text = os.date("%Y-%m-%d", os.time() - 3600 * 24), subText = "yesterday" })
    hs.chooser.new(completionFn):choices(choices):searchSubText(true):width(35):show()
end)
