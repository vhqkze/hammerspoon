---@diagnostic disable: lowercase-global
hs.execute("networksetup -setwebproxystate Ethernet off")
hs.execute("networksetup -setsecurewebproxystate Ethernet off")
hs.execute("networksetup -setsocksfirewallproxystate Ethernet off")
nc = hs.network.configuration.open()
nc:monitorKeys("State:/Network/Global/Proxies")
nc:setCallback(function(a)
    if hs.network.interfaceName() ~= "Ethernet" then
        return
    end
    local proxy = a:proxies()
    if proxy.HTTPEnable == 1 then
        hs.execute("networksetup -setwebproxystate Ethernet off")
    end
    if proxy.HTTPSEnable == 1 then
        hs.execute("networksetup -setsecurewebproxystate Ethernet off")
    end
    if proxy.SOCKSEnable == 1 then
        hs.execute("networksetup -setsocksfirewallproxystate Ethernet off")
    end
end)
nc:start()
