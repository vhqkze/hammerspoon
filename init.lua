hs.hotkey.bind({ "ctrl", "cmd" }, "r", function()
    hs.reload()
end)
local log = hs.logger.new("init", "debug")
log.i("Initializing")

-- 避免因配置文件错误导致启动失败后dock和menubar都找不到hammerspoon
hs.menuIcon(true)

local output, status, type, rc = hs.execute("brew --prefix", true)
if status then
    hs.ipc.cliInstall(output)
    log.i("ipc 安装成功:", output)
else
    log.e("ipc 安装失败:", output)
end

local env = hs.json.read(".env.json")
if env == nil then
    hs.alert.show("没有.env.json文件, 或解析失败")
    hs.toggleConsole()
    return
end
for k, v in pairs(env) do
    hs.settings.set(k, v)
end

local hostname = hs.host.localizedName()

if hs.settings.get("is_work_device") then
    log.i("是工作电脑，启动工作脚本")
    require("work.restart_app")
    require("work.snippet")
    require("work.copy_img_from_mobile")
    require("work.convert_numbers_to_xlsx")
    require("work.install_apk")
    require("work.sync_server")
    require("work.check_in_out")
    require("work.task")
end

require("plugins.keymap")
require("plugins.time_format")
require("plugins.window_manager")
require("plugins.menubar")
-- require("plugins.network")
require("plugins.rest_reminder")

-- 有yabai时使用yabai，没有yabai时才使用hammerspoon退出app
local _, exist_yabai = hs.execute("command -v yabai >/dev/null 2>&1", true)
if not exist_yabai then
    require("plugins.quit_app")
end
