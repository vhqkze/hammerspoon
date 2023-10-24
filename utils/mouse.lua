local M = {}
local event = hs.eventtap.event
M.rel = {
    WINDOW = "window",
    MOUSE = "mouse",
    START = "start",
    NIL = nil,
}

-- 各个函数的入参point有三个参数
--  - x: number, 横坐标
--  - y: number, 纵坐标
--  - rel: string, "window": 相对活跃窗口左上角坐标；"mouse": 相对当前鼠标位置坐标; "start": 相对拖拽的起始点坐标（仅拖拽to参数可用）

--- 获取当前focus窗口的位置
local function getFocusedWindow()
    local win = hs.window.focusedWindow()
    if win then
        return win:topLeft()
    end
end

--- 根据用户输入的相对坐标，转换为绝对坐标
---@param point table 相对坐标，根据rel判断相对位置
---@return table 绝对坐标
local function getNewPoint(point)
    if point.rel == M.rel.WINDOW then
        local topLeft = getFocusedWindow()
        if topLeft then
            point.x = topLeft.x + point.x
            point.y = topLeft.y + point.y
        else
            hs.alert.show("No focused window!")
        end
    elseif point.rel == M.rel.MOUSE then
        local mouse_pos = hs.mouse.getRelativePosition()
        point.x = mouse_pos.x + point.x
        point.y = mouse_pos.y + point.y
    end
    return { x = point.x, y = point.y }
end

---左键单击
---@param point table
---@class point
---@field x number
---@field y number
---@field rel string nil或空: 绝对坐标, window: 相对活跃窗口左上角坐标；mouse：相对当前鼠标位置坐标
function M.click(point)
    local newPoint = getNewPoint(point)
    hs.eventtap.leftClick(newPoint)
end

---右键单击
---@param point table
function M.rightClick(point)
    local newPoint = getNewPoint(point)
    hs.eventtap.rightClick(newPoint)
end

---左键双击
---@param point table
function M.doubleClick(point)
    local newPoint = getNewPoint(point)
    local clickState = event.properties.mouseEventClickState
    event.newMouseEvent(event.types.leftMouseDown, newPoint):setProperty(clickState, 1):post()
    event.newMouseEvent(event.types.leftMouseUp, newPoint):setProperty(clickState, 1):post()
    hs.timer.usleep(1000)
    event.newMouseEvent(event.types.leftMouseDown, newPoint):setProperty(clickState, 2):post()
    event.newMouseEvent(event.types.leftMouseUp, newPoint):setProperty(clickState, 2):post()
end

---移动鼠标
---@param point table
function M.move(point)
    local newPoint = getNewPoint(point)
    event.newMouseEvent(event.types.mouseMoved, newPoint):post()
end

---拖拽
---@param from table
---@param to table
function M.drag(from, to)
    local point_start = getNewPoint(from)
    local point_end = nil
    if to.rel == M.rel.START then
        point_end = { x = to.x + point_start.x, y = to.y + point_start.y }
    else
        point_end = getNewPoint(to)
    end
    event.newMouseEvent(event.types.leftMouseDown, point_start):post()
    event.newMouseEvent(event.types.mouseMoved, point_end):post()
    hs.timer.doAfter(0.01, function()
        event.newMouseEvent(event.types.leftMouseUp, point_end):post()
    end)
end

return M
