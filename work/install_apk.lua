--- 监控 ~/Downloads 目录，如果新增apk文件，则弹出通知询问是否安装到手机

local function install(filename)
    hs.task
        .new("/usr/local/bin/adb", function(exitCode, stdOut, stdErr)
            if exitCode == 0 then
                hs.notify.new({ title = "安装成功", informativeText = filename, withdrawAfter = 10 }):send()
            else
                hs.notify.new({ title = "安装失败", informativeText = stdErr, withdrawAfter = 10 }):send()
            end
        end, function()
            return true
        end, { "install", "-r", "-d", filename })
        :start()
end

local function ask_install(filename)
    hs.notify
        .new(function(notify)
            if notify:activationType() == hs.notify.activationTypes.actionButtonClicked then
                install(filename)
            end
        end)
        :title("发现新的安卓软件包")
        :informativeText(filename)
        :actionButtonTitle("安装")
        :hasActionButton(true)
        :withdrawAfter(0)
        :send()
end

local function install_last_apk(paths, flagTables)
    for index, filename in pairs(paths) do
        if string.sub(filename, -4) == ".apk" then
            for operation, result in pairs(flagTables[index]) do
                if operation == "itemCreated" and result then
                    ask_install(filename)
                end
            end
        end
    end
end

install_apk_watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/Downloads", install_last_apk):start()
