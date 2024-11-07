#!/bin/bash
#===============================================
# Description: 2305_x64_temp DIY script part 2
# File name: 2305_x64_temp_diy-part2
# Lisence: MIT
# By: GXNAS
#===============================================

echo "开始 DIY2 配置……"
echo "========================="

# Git稀疏克隆，只克隆指定目录到本地
chmod +x $GITHUB_WORKSPACE/diy_script/function.sh
source $GITHUB_WORKSPACE/diy_script/function.sh
rm -rf package/custom; mkdir package/custom

# 修改主机名字，修改你喜欢的就行（不能纯数字或者使用中文）
sed -i "/uci commit system/i\uci set system.@system[0].hostname='OpenWrt-GXNAS'" package/lean/default-settings/files/zzz-default-settings
sed -i "s/hostname='.*'/hostname='OpenWrt-GXNAS'/g" ./package/base-files/files/bin/config_generate

# 修改默认IP
#sed -i 's/192.168.1.1/192.168.1.11/g' package/base-files/files/bin/config_generate

# 设置旁路由模式
cat >> package/lean/default-settings/files/zzz-default-settings <<-EOF
uci set network.lan.ipaddr='192.168.1.11'                    # 旁路由设置本机IPv4地址
uci set network.lan.gateway='192.168.1.1'                    # 旁路由设置 IPv4 网关
uci set network.lan.dns='223.5.5.5 114.114.114.114'          # 旁路由设置 DNS(多个DNS要用空格分开)
uci set dhcp.lan.ignore='1'                                  # 旁路由关闭DHCP功能
uci delete network.lan.type                                  # 旁路由桥接模式-禁用
uci set network.lan.delegate='0'                             # 去掉LAN口使用内置的 IPv6 管理(若用IPV6请把'0'改'1')
uci set dhcp.@dnsmasq[0].filter_aaaa='0'                     # 禁止解析 IPv6 DNS记录(若用IPV6请把'1'改'0')

# 旁路IPV6需要全部禁用
uci set network.lan.ip6assign=''                             # IPV6分配长度-禁用
uci set dhcp.lan.ra=''                                       # 路由通告服务-禁用
uci set dhcp.lan.dhcpv6=''                                   # DHCPv6 服务-禁用
uci set dhcp.lan.ra_management=''                            # DHCPv6 模式-禁用

# 如果有用IPV6的话,可以使用以下命令创建IPV6客户端(LAN口)（去掉全部代码uci前面#号生效）
#uci set network.ipv6=interface
#uci set network.ipv6.proto='dhcpv6'
#uci set network.ipv6.ifname='@lan'
#uci set network.ipv6.reqaddress='try'
#uci set network.ipv6.reqprefix='auto'
#uci set firewall.@zone[0].network='lan ipv6'

EOF

# 修改退出命令到最后
sed -i '/exit 0/d' package/lean/default-settings/files/zzz-default-settings && echo "exit 0" >> package/lean/default-settings/files/zzz-default-settings

# 设置密码为空（安装固件时无需密码登陆，然后自己修改想要的密码）
sed -i '/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF./d' package/lean/default-settings/files/zzz-default-settings

# 调整 x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

#修改SSH下root后面的名称
sed -i 's/OpenWrt/OpenWrt-GXNAS/g' package/base-files/files/bin/config_generate

# 修改版本号
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%y.%m.%d)'|g" package/lean/default-settings/files/zzz-default-settings

# 设置ttyd免帐号登录
sed -i 's/\/bin\/login/\/bin\/login -f root/' feeds/packages/utils/ttyd/files/ttyd.config

# 默认 shell 为 bash
sed -i 's/\/bin\/ash/\/bin\/bash/g' package/base-files/files/etc/passwd

# samba解除root限制
sed -i 's/invalid users = root/#&/g' feeds/packages/net/samba4/files/smb.conf.template

# coremark跑分定时清除
sed -i '/\* \* \* \/etc\/coremark.sh/d' feeds/packages/utils/coremark/*

# 修改 argon 为默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
sed -i 's/Bootstrap theme/Argon theme/g' feeds/luci/collections/*/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/*/Makefile

##切换为samba4
# sed -i 's/luci-app-samba/luci-app-samba4/g' package/lean/autosamba/Makefile

# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

# 替换curl修改版（无nghttp3、ngtcp2）
curl_ver=$(grep -i "PKG_VERSION:=" feeds/packages/net/curl/Makefile | awk -F'=' '{print $2}')
if [ "$curl_ver" != "8.9.1" ]; then
    echo "当前 curl 版本是: $curl_ver,开始替换......"
    rm -rf feeds/packages/net/curl
    cp -rf $GITHUB_WORKSPACE/personal/curl feeds/packages/net/curl
fi

# 报错修复
# sed -i 's/9625784cf2e4fd9842f1d407681ce4878b5b0dcddbcd31c6135114a30c71e6a8/5de8c8e29aaa3fb9cc6b47bb27299f271354ebb72514e3accadc7d38b5bbaa72/g' feeds/packages/utils/jq/Makefile
# sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=1.7.2/g' feeds/Jejz/xray-core/Makefile
# sed -i 's/PKG_HASH:=.*/PKG_HASH:=e35824e19e8acc06296ce6bfa78a14a6f3ee8f42a965f7762b7056b506457a29/g' feeds/Jejz/xray-core/Makefile
# cp -f $GITHUB_WORKSPACE/personal/hysteria/* feeds/Jejz/hysteria
# cp -f $GITHUB_WORKSPACE/personal/chinadns-ng/* feeds/Jejz/chinadns-ng
rm -rf feeds/packages/utils/v2dat

# merge_package 复制 仓库下的文件夹 git clone 复制整个仓库
# vssr adguardhome turboacc去dns
rm -rf package/feeds/packages/adguardhome
rm -rf feeds/luci/applications/luci-app-turboacc
merge_package master https://github.com/xiangfeidexiaohuo/extra-ipk package/custom luci-app-adguardhome patch/luci-app-turboacc patch/wall-luci/lua-maxminddb patch/wall-luci/luci-app-vssr

# ddns-go 动态域名
# git clone --depth=1 https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go

# chatgpt
git clone --depth=1 https://github.com/sirpdboy/luci-app-chatgpt-web package/luci-app-chatgpt

# lucky 大吉
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

# ddnsto
merge_package main https://github.com/linkease/nas-packages-luci package/custom luci/luci-app-ddnsto
merge_package master https://github.com/linkease/nas-packages package/custom network/services/ddnsto

# OpenAppFilter 应用过滤
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# autotimeset 定时
# git clone --depth=1 https://github.com/sirpdboy/luci-app-autotimeset package/luci-app-autotimeset

# dockerman
# rm -rf feeds/luci/applications/luci-app-dockerman
# git clone --depth=1 https://github.com/lisaac/luci-app-dockerman.git package/luci-app-dockerman

# eqos 限速
# merge_package master https://github.com/kenzok8/openwrt-packages package/custom luci-app-eqos

# filebrowser 文件浏览器
merge_package main https://github.com/Lienol/openwrt-package package/custom luci-app-filebrowser

# frpc frps
rm -rf feeds/luci/applications/{luci-app-frpc,luci-app-frps,luci-app-hd-idle,luci-app-adblock,luci-app-filebrowser}
merge_package master https://github.com/immortalwrt/luci package/custom applications/luci-app-filebrowser applications/luci-app-syncdial applications/luci-app-eqos applications/luci-app-nps applications/luci-app-nfs applications/luci-app-frpc applications/luci-app-frps applications/luci-app-hd-idle applications/luci-app-adblock applications/luci-app-socat

# poweroff
git clone https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff

# unblockneteasemusic
# git clone --depth=1 https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic.git package/luci-app-unblockneteasemusic

# smartdns
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns
git clone --depth=1 -b master https://github.com/pymumu/luci-app-smartdns.git package/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# mosdns
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
git clone --depth=1 -b v5 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# alist
rm -rf feeds/packages/lang/golang
rm -rf feeds/packages/net/alist
rm -rf feeds/luci/applications/luci-app-alist
git clone --depth=1 https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/luci-app-alist package/alist

# passwall
rm -rf feeds/luci/applications/luci-app-passwall
merge_package main https://github.com/xiaorouji/openwrt-passwall package/custom luci-app-passwall

# passwall2
# merge_package main https://github.com/xiaorouji/openwrt-passwall2 package/custom luci-app-passwall2

# mihomo
git clone --depth=1 https://github.com/morytyann/OpenWrt-mihomo package/luci-app-mihomo

# homeproxy
git clone --depth=1 https://github.com/muink/luci-app-homeproxy.git package/luci-app-homeproxy

# openclash
rm -rf feeds/luci/applications/luci-app-openclash
merge_package master https://github.com/vernesong/OpenClash package/custom luci-app-openclash
# merge_package dev https://github.com/vernesong/OpenClash package/custom luci-app-openclash
# 编译 po2lmo (如果有po2lmo可跳过)
pushd package/custom/luci-app-openclash/tools/po2lmo
make && sudo make install
popd

# argon 主题
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 -b js https://github.com/lwb1978/luci-theme-kucat package/luci-theme-kucat

# 更改argon主题背景
cp -f $GITHUB_WORKSPACE/personal/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# 修改主题多余版本信息
sed -i 's|<a class="luci-link" href="https://github.com/openwrt/luci"|<a|g' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's|<a class="luci-link" href="https://github.com/openwrt/luci"|<a|g' package/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm
sed -i 's|<a href="https://github.com/jerrykuku/luci-theme-argon" target="_blank">|<a>|g' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's|<a href="https://github.com/jerrykuku/luci-theme-argon" target="_blank">|<a>|g' package/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm

# 显示增加编译时间
#sed -i "s/<%=pcdata(ver.distname)%> <%=pcdata(ver.distversion)%>/<%=pcdata(ver.distname)%> <%=pcdata(ver.distversion)%> (By @GXNAS build $(TZ=UTC-8 date "+%Y-%m-%d %H:%M"))/g" package/lean/autocore/files/x86/index.htm
echo "package/base-files/files/etc/openwrt_release："
echo "默认的package/base-files/files/etc/openwrt_release 配置文件内容如下："
cat package/base-files/files/etc/openwrt_release
echo "修改主机名字后，package/base-files/files/etc/openwrt_release 配置文件内容如下："
sed -i "s/DISTRIB_REVISION=.*/DISTRIB_REVISION='OpenWrt_2305_x64_临时版 by GXNAS build @R$(date +%y.%m.%d)'/g" package/base-files/files/etc/openwrt_release
cat package/base-files/files/etc/openwrt_release

# 修改概览里时间显示为中文数字
sed -i 's/os.date()/os.date("%Y年%m月%d日") .. " " .. translate(os.date("%A")) .. " " .. os.date("%X")/g' package/lean/autocore/files/x86/index.htm

# 修改欢迎banner
cp -f $GITHUB_WORKSPACE/personal/banner package/base-files/files/etc/banner
# wget -O ./package/base-files/files/etc/banner https://raw.githubusercontent.com/Jejz168/OpenWrt/main/personal/banner

# 修改makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/luci\.mk/include \$(TOPDIR)\/feeds\/luci\/luci\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/include\ \.\.\/\.\.\/lang\/golang\/golang\-package\.mk/include \$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang\-package\.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHREPO/PKG_SOURCE_URL:=https:\/\/github\.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=\@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload\.github\.com/g' {}

# 调整V2ray服务到VPN菜单
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/controller/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/model/cbi/v2ray_server/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/view/v2ray_server/*.htm

# nlbwmon移动网络
sed -i 's/services/network/g' feeds/luci/applications/luci-app-nlbwmon/root/usr/share/luci/menu.d/luci-app-nlbwmon.json
sed -i 's/services/network/g' feeds/luci/applications/luci-app-nlbwmon/htdocs/luci-static/resources/view/nlbw/config.js

# 重命名
sed -i 's,frp 服务器,Frp 服务器,g' feeds/luci/applications/luci-app-frps/po/zh_Hans/frps.po
sed -i 's,frp 客户端,Frp 客户端,g' feeds/luci/applications/luci-app-frpc/po/zh_Hans/frpc.po

# 修改插件名字
sed -i 's/"iStore"/"应用商店"/g' `grep "iStore 应用商店" -rl ./`
# sed -i 's/"挂载 SMB 网络共享"/"挂载共享"/g' `grep "挂载 SMB 网络共享" -rl ./`
# sed -i 's/"Argon 主题设置"/"Argon 设置"/g' `grep "Argon 主题设置" -rl ./`
# sed -i 's/"阿里云盘 WebDAV"/"阿里云盘"/g' `grep "阿里云盘 WebDAV" -rl ./`
# sed -i 's/"USB 打印服务器"/"USB 打印"/g' `grep "USB 打印服务器" -rl ./`
# sed -i 's/"网络存储"/"存储"/g' `grep "网络存储" -rl ./`
# sed -i 's/"Turbo ACC 网络加速"/"网络加速"/g' `grep "Turbo ACC 网络加速" -rl ./`
# sed -i 's/"实时流量监测"/"流量"/g' `grep "实时流量监测" -rl ./`
# sed -i 's/"KMS 服务器"/"KMS激活"/g' `grep "KMS 服务器" -rl ./`
# sed -i 's/"TTYD 终端"/"命令窗"/g' `grep "TTYD 终端" -rl ./`
# sed -i 's/"USB 打印服务器"/"打印服务"/g' `grep "USB 打印服务器" -rl ./`

./scripts/feeds update -a
./scripts/feeds install -a

echo "========================="
echo " DIY2 配置完成……"
