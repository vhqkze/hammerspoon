local M = {}
local log = hs.logger.new("file", "debug")

--- 保存数据为文件
---@param data string 文件内容
---@param path string 文件路径，如不存在则创建
---@return boolean 是否保存成功
function M.save(data, path)
    local f = io.open(path, "w")
    if f == nil then
        return false
    end
    f:write(data)
    f:close()
    return true
end

--- 复制文件到系统剪贴板
---@param filename string 文件路径
---@return boolean 复制结果
function M.copy(filename)
    local result, obj, desc = hs.osascript.applescript(string.format('tell app "Finder" to set the clipboard to POSIX file "%s"', filename))
    if result ~= true then
        log.e(obj, desc)
        return false
    end
    return true
end

return M
