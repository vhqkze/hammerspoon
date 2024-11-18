local M = {}
local event = hs.eventtap.event

---@enum Rel
M.rel = {
    WINDOW = "window",
    MOUSE = "mouse",
    START = "start",
}

---@class Point
---@field x number
---@field y number

--- 获取当前focus窗口的位置
---@return Point|nil
local function getFocusedWindow()
    local win = hs.window.focusedWindow()
    if win then
        return win:topLeft()
    end
end

---根据用户输入的相对坐标，转换为相对屏幕的坐标
---@param point Point 相对坐标，根据rel判断相对位置
---@param rel? Rel
---@return Point|nil 相对当前屏幕的坐标
local function getNewPoint(point, rel)
    if rel == nil then
        return { x = point.x, y = point.y }
    end
    if rel == M.rel.WINDOW then
        local topLeft = getFocusedWindow()
        if topLeft then
            return { x = topLeft.x + point.x, y = topLeft.y + point.y }
        end
    elseif rel == M.rel.MOUSE then
        local mouse_pos = hs.mouse.getRelativePosition()
        return { x = mouse_pos.x + point.x, y = mouse_pos.y + point.y }
    end
end

---leftClick
---@param point Point
---@param rel? Rel
---@param back? boolean 是否返回原点
function M.click(point, rel, back)
    local pos_origin = back and hs.mouse.getRelativePosition() or nil
    local newPoint = getNewPoint(point, rel)
    hs.eventtap.leftClick(newPoint)
    if back then
        hs.mouse.setRelativePosition(pos_origin)
    end
end

---middleClick
---@param point Point
---@param rel? Rel
---@param back? boolean 是否返回原点
function M.middleClick(point, rel, back)
    local pos_origin = back and hs.mouse.getRelativePosition() or nil
    local newPoint = getNewPoint(point, rel)
    hs.eventtap.middleClick(newPoint)
    if back then
        hs.mouse.setRelativePosition(pos_origin)
    end
end

---rightClick
---@param point Point
---@param rel? Rel
---@param back? boolean 是否返回原点
function M.rightClick(point, rel, back)
    local pos_origin = back and hs.mouse.getRelativePosition() or nil
    local newPoint = getNewPoint(point, rel)
    hs.eventtap.rightClick(newPoint)
    if back then
        hs.mouse.setRelativePosition(pos_origin)
    end
end

---doubleClick
---@param point Point
---@param rel? Rel
---@param back? boolean 是否返回原点
function M.doubleClick(point, rel, back)
    local pos_origin = back and hs.mouse.getRelativePosition() or nil
    local newPoint = getNewPoint(point, rel)
    local clickState = event.properties.mouseEventClickState
    event.newMouseEvent(event.types.leftMouseDown, newPoint):setProperty(clickState, 1):post()
    event.newMouseEvent(event.types.leftMouseUp, newPoint):setProperty(clickState, 1):post()
    hs.timer.usleep(1000)
    event.newMouseEvent(event.types.leftMouseDown, newPoint):setProperty(clickState, 2):post()
    event.newMouseEvent(event.types.leftMouseUp, newPoint):setProperty(clickState, 2):post()
    if back then
        hs.mouse.setRelativePosition(pos_origin)
    end
end

---move
---@param point Point
---@param rel? Rel
function M.move(point, rel)
    local newPoint = getNewPoint(point, rel)
    event.newMouseEvent(event.types.mouseMoved, newPoint):post()
end

---drag
---@param start_pos Point
---@param start_rel? Rel
---@param end_pos Point
---@param end_rel? Rel
---@param back? boolean 是否返回原点
function M.drag(start_pos, start_rel, end_pos, end_rel, back)
    local pos_origin = back and hs.mouse.getRelativePosition() or nil
    local pos1 = getNewPoint(start_pos, start_rel)
    if pos1 == nil then
        return
    end
    local pos2 = nil
    if end_rel == M.rel.START then
        pos2 = { x = end_pos.x + pos1.x, y = end_pos.y + pos1.y }
    else
        pos2 = getNewPoint(end_pos, end_rel)
    end
    event.newMouseEvent(event.types.leftMouseDown, pos1):post()
    event.newMouseEvent(event.types.mouseMoved, pos2):post()
    hs.timer.doAfter(0.01, function()
        event.newMouseEvent(event.types.leftMouseUp, pos2):post()
    end)
    if back then
        hs.mouse.setRelativePosition(pos_origin)
    end
end

return M
