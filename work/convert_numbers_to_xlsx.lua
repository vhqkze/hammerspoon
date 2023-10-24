--- 监控 ~/Downloads 目录下的 .numbers 文件，如果有更新，则自动在文件所在文件夹内生成一个同名的xlsx文件

local homedir = os.getenv("HOME")
local log = hs.logger.new("convert_numbers_to_xlsx", "debug")

local function convert(filename, xlsx_file)
    local cmd = homedir .. "/.local/bin/poetry"
    local task = hs.task.new(cmd, function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            hs.notify.new({ title = "转换成功", informativeText = xlsx_file }):send()
        else
            hs.notify.new({ title = "转换错误", informativeText = stdErr }):send()
        end
    end, function()
        return true
    end, { "run", "python", "convert/numbers_to_xlsx.py", filename, xlsx_file })
    task:setWorkingDirectory(homedir .. "/Developer/minitools")
    task:start()
end

convert_numbers_to_xlsx_watcher = hs.pathwatcher
    .new(homedir .. "/Downloads", function(paths, flagTables)
        for index, filename in pairs(paths) do
            if string.sub(filename, -8) == ".numbers" then
                for operation, result in pairs(flagTables[index]) do
                    log.i(index, filename, operation, result)
                    if index == 1 and operation == "itemRenamed" and result then
                        log.f("开始转换numbers文件:%s", filename)
                        local xlsx_file = filename:gsub("%.numbers$", ".xlsx")
                        convert(filename, xlsx_file)
                    end
                end
            end
        end
    end)
    :start()
