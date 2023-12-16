# Hammerspoon 配置

这里是我的 hammerspoon 软件配置，里面集合了一些工作中经常用到的工具。每个工具基本都是独立的，可以直接在 `init.lua` 里面注释掉 `require` 行来屏蔽它。

## 安装使用

### 下载

需要先安装 [Hammerspoon](http://www.hammerspoon.org/)，然后克隆本仓库，改名后放到 `~/.hammerspoon/`

```bash
git clone https://github.com/vhqkze/hammerspoon.git ~/.hammerspoon
```

或者下载到其他地方，然后通过软链接的方式

```bash
git clone https://github.com/vhqkze/hammerspoon.git
ln -s /path/to/repo/hammerspoon ~/.hammerspoon
```

### 修改配置

需要提供 `.env.json` 文件

```bash
cp .env.json.example .env.json
```

然后根据自己需求自行修改 json 文件中的值。

然后启动 hammerspoon 软件即可。

如果你之前已经使用了 hammerspoon，通过软链接使用本仓库配置文件，则需要重启 hammerspoon，而不是重新加载配置。

## 工具说明

### work/check_in_out.lua

定时检查上下班是否打卡，如果没有打卡，则给电脑发个通知消息，给手机发 bark 消息。

需要搭配 `~/Developer/minitools/work/check_in_out.py` 使用，`check_in_out.py` 会检查是否打卡，打卡成功返回0，未打卡返回1。

工具中通过调用 `cd ~/Developer/minitools && poetry run python work/check_in_out.py` 命令检查是否打卡。因为有上班打卡和下班打卡，所以这里是根据执行命令的时间来智能判断的（在 `check_in_out.py` 文件中实现），如果在上午或中午执行，则会检查上班卡；如果在晚上或凌晨，则会检查下班卡。

工具会在上午 09:55 检查上班卡，在晚上 22:00 开始一个定时器，每隔 5s 检查系统空闲时间（距离上次电脑接收到键盘鼠标输入的时间），如果系统空闲时间超过 3分钟，则表示人已离开电脑，则会检查是否打下班卡，如果未打下班卡，电脑上会收到一个通知，手机上也会收到一个 bark 通知，如果用户点击了电脑上的通知，则表示用户还没有下班，则重启定时器，继续每隔 5s检查一次空闲时间。用户点击 bark 通知是没用的，bark 通知只是通知没有打卡。

### work/convert_numbers_to_xlsx.lua

需要搭配 `~/Developer/minitools/convert/numbers_to_xlsx.py` 使用。

我电脑没有安装 Microsoft Office，平时都是使用 macOS 自带的 Numbers 软件，但是工作上经常需要 xlsx 格式的文件，Numbers 软件可以将修改导出为 xlsx 格式，但是需要一系列步骤，比较麻烦，这里我会监控 `~/Downloads/` 目录，如果该目录及其子目录下，新增或修改了 `.numbers` 文件，则会自动在该 `.numbers` 文件所在目录生成一个相同内容、相同名称的 `.xlsx` 文件。

### work/copy_img_from_mobile.lua

因为工作上涉及到 Android 和 iOS 上的 app 测试，经常需要对手机进行截屏，然后在电脑上使用，这个工具定义了两个快捷键可以直接对手机进行截图，并将截图复制到电脑剪贴板。

#### Android

快捷键 `option+c`

需要手机开启了 USB 调试。

会优先检查是否使用了 [scrcpy](https://github.com/Genymobile/scrcpy) 软件，如果检测到正在使用 scrcpy，则会对 scrcpy 窗口进行截图，这种方法速度较快，且不需要 scrcpy 窗口显示在最前端，但这种方式获得的截图质量不如手机原生截图。

如果没有使用 scrcpy，则会使用 adb 进行截图，会执行以下命令获取截图并保存在 `/tmp/screenshot.png`

```bash
/usr/local/bin/adb exec-out screencap -p > /tmp/screenshot.png
```

然后复制 `/tmp/screenshot.png` 内容到电脑剪贴板，再自动清除 `/tmp/screenshot.png` 文件。

#### iOS

快捷键 `option+x`

优先检查 QuickTime Player 软件是否打开了 **影片录制** 窗口，需要手机连接电脑后，电脑打开 QuickTime Player，新建影片录制，屏幕选择手机，这样 QuickTime Player 可以实时镜像显示手机屏幕内容。如果检测到有 **影片录制** 窗口，则对该窗口截图并复制到电脑剪贴板，不要求窗口在最前端，即使窗口被挡住或最小化，也可以获取到截图（最好不要最小化，最小化后 QuickTime Player 获取到的镜像画面有延迟）。

如果没有使用 QuickTime Player 进行投屏，则会检测是否使用了 [Bezel](https://getbezel.app/) 软件，如果在运行 bezel 软件，则会对 bezel 窗口进行截图。

如果以上两种方式都不行，则直接会显示截图失败。

这里我附上一段 AppleScript 脚本，可以快速打开 QuickTime Player 进行镜像显示

```AppleScript
tell application "QuickTime Player"
    # 激活软件
    activate
    # 按快捷键 cmd + option + N 以新建影片录制
    tell application "System Events" to key code 45 using {option down, command down}
    tell application "System Events" to tell process "QuickTime Player"
        # 点击录制按钮
        # click button 3 of window 1
        # 点击录制按钮右边的小箭头以打开选项
        click button 2 of window 1
        # 点击选项里面的屏幕为自己的手机（这里 v Phone 是我的手机名称，需要改成你自己的）
        click menu item "v Phone" of menu 1 of button 2 of window 1
    end tell
end tell
```

### work/install_apk.lua

监控 `~/Downloads/` 目录，如果有新增 `.apk` 文件，则会在电脑右上角弹出一个通知，询问是否安装，如果点击了安装，则会将这个 `.apk` 文件安装到安卓手机上。

这里附上一段 shell 脚本，可以将其保存到 `~/.zshrc` 里面，后面可以通过执行 `adb_install_latest` 命令来获取 `~/Downloads/` 下最新的一个 `.apk` 文件并安装到手机上。

```bash
adb_install_latest() {
    echo "adb install -r -d $(ls -1t "$HOME"/Downloads/*.apk | head -n 1)"
    adb install -r -d "$(ls -1t "$HOME"/Downloads/*.apk | head -n 1)"
}
```

### work/snippet.lua

快捷键 `cmd+g` 弹出一个菜单，包含一些常用的字符串，选择后会将内容输入到正在使用的 app 上。

如果需要使用 snippet，还需要修改 `assets/snippet.json` 文件，这里提供了样例

```json
cp assets/snippet.json.example assets/snippet.json
```

### work/restart_app.lua

检测 app 是否停止运行，如果发现 app 停止运行了，自动重启它。

### work/sync_server.lua

如果你和我一样，满足以下条件

- 电脑和手机即使都连接公司网络，也无法正常使用 iCloud 同步、剪贴板同步、Airdrop
- 公司提供了代理，方便电脑对手机进行抓包：假如电脑抓包软件的代理端口为 8899，公司提供代理，可以将本机的 8899 端口映射到 <http://proxy.test:12345>，然后手机连接公司网络后，Wi-Fi 配置代理为 <http://proxy.text:12345>，这样电脑 8899 端口的抓包软件就可以收到手机上的请求，实现对手机进行抓包
- 需要经常对电脑和手机进行同步数据（文本、最新的截图、最新的录屏、剪贴板）

那么，就可以使用本工具来实现。

这个工具会启动一个端口为 8863 的 web 服务器，手机向 <http://proxy.test:12345> 发送请求，电脑抓包软件获取到该请求后，将请求转发到本机的 8863 端口，工具启动的 web 服务器收到请求后，根据请求 url 执行相应动作。

| url    | 请求内容     | 执行动作                                                                     |
| ---    | ---          | ---                                                                          |
| /pic   | 手机上的图片 | 将请求中的图片复制到电脑剪贴板                                               |
| /text  | 手机上的文本 | 将请求中的文本复制到电脑剪贴板                                               |
| /video | 手机上的录屏 | 将请求中的录屏文件复制到电脑剪贴板（录屏较大可能发送失败）                   |
| /clip  | 无           | 将电脑剪贴板内的文本或图片做为响应返回，手机端收到后将内容复制到手机剪贴板上 |

手机可以通过快捷指令来触发这些请求，以下为用到的快捷指令。

### work/task.lua

公司的任务系统比较难用，我本机使用 docker 部署了 Apitable，然后使用 `~/Developer/minitools/work/apitable_sync.py` 实现公司的任务系统和本机的 apitable 系统双向同步。

电脑使用 crontab 在工作日定时执行 `apitable_sync.py` 对 apitable 和公司任务系统进行双向同步。

工具会从本机的 apitable 系统中获取到待处理任务，处理后显示在 menubar 上，点击菜单中的任务，可以直接在浏览器中打开该任务。

工具会开启 9234 端口进行监听，apitable 任务有更新时，会有 hook 向 9234 端口发消息，工具收到消息后，会触发刷新 menubar 中内容。

### plugins/keymap.lua

定义常用快捷键，可以指定 app 定义快捷键。

### plugins/menubar.lua

在电脑 menubar 中显示一个自定义的图标，替换掉 hammerspoon 自带的图标。点击图标，有一系列常用工具如下

- 黑暗模式
- 黑白模式（部分显示器支持）
- 咖啡因（使屏幕保持唤醒，可指定生效时长）
- 自动隐藏 dock
- 显示屏保
- 编码解码
  - 剪贴板内的文本或图片使用 base64 编码
  - 剪贴板内的文本使用 base64 解码
- Hammerspoon菜单
- 显示桌面（将所有窗口最小化）

### plugins/network.lua

监听 Wi-Fi 变化，实现电脑连接/断开指定 Wi-Fi 后执行相应动作。

### plugins/quit.app

对指定的窗口，在关闭最后一个窗口后退出app。

### plugins/time_format.lua

工作中经常碰到时间戳，但是时间戳需要经过转换才能知道对应的真实时间，这个工具提供了快速将时间戳转换为年月日时分秒，或将年月日时分秒转换为时间戳，并将转换结果显示在屏幕中央。

先选中时间戳（10位的秒级时间戳或13位的毫秒级时间戳），按下快捷键 `cmd+b`，会复制选中内容，然后获取剪贴板内容，转换为 `2023-10-23 11:02:03` 这样的格式，显示在屏幕中央，同时将转换后的内容复制到剪贴板。

如果选中的就是形如 `2023-10-23 11:02:03` 的内容，按下快捷键 `cmd+b` 后，会复制选中内容，获取剪贴板内容，转换为秒级时间戳，显示在屏幕中央，同时将转换后的时间戳复制到剪贴板。

### plugins/window_manager.lua

窗口管理器。按下快捷键 `F8` 后，会进入窗口管理模式（右下角显示 `Edit Mode`），此时按下快捷键可以调整当前活跃窗口，如果 1s内无操作，或按下了 `q` 或 `ESC` 键，则会退出窗口管理模式。在窗口管理模式下，可用的快捷键如下。

| 快捷键 | 说明 |
| :---: | --- |
| `a` | 窗口左边界左移一个step |
| `s` | 窗口下边界下移一个step |
| `d` | 窗口上边界上移一个step |
| `f` | 窗口右边界右移一个step |
| `ctrl`+`a` | 窗口左边界左移一个像素 |
| `ctrl`+`s` | 窗口下边界下移一个像素 |
| `ctrl`+`d` | 窗口上边界上移一个像素 |
| `ctrl`+`f` | 窗口右边界右移一个像素 |
| `shift`+`a` | 窗口左边界右移一个step |
| `shift`+`s` | 窗口下边界上移一个step |
| `shift`+`d` | 窗口上边界下移一个step |
| `shift`+`f` | 窗口右边界左移一个step |
| `ctrl`+`shift`+`a` | 窗口左边界右移一个像素 |
| `ctrl`+`shift`+`s` | 窗口下边界上移一个像素 |
| `ctrl`+`shift`+`d` | 窗口上边界下移一个像素 |
| `ctrl`+`shift`+`f` | 窗口右边界左移一个像素 |
| `-` | 窗口中心点不变，四边以step为单位缩小窗口 |
| `=` | 窗口中心点不变，四边以step为单位放大窗口 |
| `ctrl`+`-` | 窗口中心点不变，四边以1像素为单位缩小窗口 |
| `ctrl`+`+` | 窗口中心点不变，四边以1像素为单位放大窗口 |
| `h` | 窗口整体左移一个step |
| `j` | 窗口整体下移一个step |
| `k` | 窗口整体上移一个step |
| `l` | 窗口整体右移一个step |
| `ctrl`+`h` | 窗口整体左移一个像素 |
| `ctrl`+`j` | 窗口整体下移一个像素 |
| `ctrl`+`k` | 窗口整体上移一个像素 |
| `ctrl`+`l` | 窗口整体右移一个像素 |
| `shift`+`h` | 窗口调整为占据左半边屏幕 |
| `shift`+`j` | 窗口调整为占据下半边屏幕 |
| `shift`+`k` | 窗口调整为占据上半边屏幕 |
| `shift`+`l` | 窗口调整为占据右半边屏幕 |
| `m` | 最大化窗口（非全屏） |
| `n` | 常规话窗口（一般大小，屏幕居中显示） |
| `,` | 窗口大小不变，调整为屏幕居中显示 |
| `.` | 全屏 |
