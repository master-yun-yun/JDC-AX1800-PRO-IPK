#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	IFS=' ' read -ra KEYWORDS <<< "$PKG_NAMES"
	for KEYWORD in "${KEYWORDS[@]}"; do
		find ./ ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$KEYWORD*" -exec rm -rf {} +
	done

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		for KEYWORD in "${KEYWORDS[@]}"; do
			find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$KEYWORD*" -prune -exec cp -rf {} ./ \;
		done
		rm -rf ./$REPO_NAME
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME ${KEYWORDS[0]}
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-24.10"

UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

UPDATE_PACKAGE "alist" "sbwml/luci-app-alist" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5"
UPDATE_PACKAGE "luci-app-wol" "VIKINGYFY/packages" "main" "pkg"

#UPDATE_PACKAGE "luci-app-gecoosac" "lwb1978/openwrt-gecoosac" "main"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"

UPDATE_PACKAGE "lazyoop" "lazyoop/networking-artifact" "main"

if [[ $WRT_REPO != *"immortalwrt"* ]]; then
	UPDATE_PACKAGE "qmi-wwan" "immortalwrt/wwan-packages" "master" "pkg"
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-not}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	echo " "

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo "$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Pho 'PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)' $PKG_FILE | head -n 1)
		local PKG_VER=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease|$PKG_MARK)) | first | .tag_name")
		local NEW_VER=$(echo $PKG_VER | sed "s/.*v//g; s/_/./g")
		local NEW_HASH=$(curl -sL "https://codeload.github.com/$PKG_REPO/tar.gz/$PKG_VER" | sha256sum | cut -b -64)
		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")

		echo "$OLD_VER $PKG_VER $NEW_VER $NEW_HASH"

		if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
UPDATE_VERSION "sing-box"
UPDATE_VERSION "tailscale"

#以下自定义源
#全能推送PushBot
UPDATE_PACKAGE "luci-app-pushbot" "zzsj0928/luci-app-pushbot" "master"
#关机poweroff
UPDATE_PACKAGE "luci-app-poweroff" "DongyangHu/luci-app-poweroff" "main"
#主题界面edge
UPDATE_PACKAGE "luci-theme-edge" "ricemices/luci-theme-edge" "master"
#分区扩容
UPDATE_PACKAGE "luci-app-partexp" "sirpdboy/luci-app-partexp" "main"
#阿里云盘aliyundrive-webdav
UPDATE_PACKAGE "luci-app-aliyundrive-webdav" "messense/aliyundrive-webdav" "main"
#UPDATE_PACKAGE "aliyundrive-webdav" "master-yun-yun/aliyundrive-webdav" "main" "pkg"
#UPDATE_PACKAGE "luci-app-aliyundrive-webdav" "master-yun-yun/aliyundrive-webdav" "main"
#服务器
#UPDATE_PACKAGE "luci-app-openvpn-server" "hyperlook/luci-app-openvpn-server" "main"
#UPDATE_PACKAGE "luci-app-openvpn-server" "ixiaan/luci-app-openvpn-server" "main"
#luci-app-navidrome音乐服务器
UPDATE_PACKAGE "luci-app-navidrome" "tty228/luci-app-navidrome" "main"
#luci-theme-design主题界面
UPDATE_PACKAGE "luci-theme-design" "emxiong/luci-theme-design" "master"
#luci-app-design-config主题配置
#UPDATE_PACKAGE "luci-app-design-config" "kenzok78/luci-app-design-config" "main"
#luci-app-quickstart
#UPDATE_PACKAGE "luci-app-quickstart" "animegasan/luci-app-quickstart" "main"
#以上自定义源

#-------------------------------------2025.04.04测试---------------------------------------#
# 关键修改：使用 pkg 模式逐个提取需要的包，避免引入整个仓库
#UPDATE_PACKAGE "luci-lib-xterm" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "taskd" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-lib-taskd" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-store" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "vlmcsd" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-vlmcsd" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "aliyundrive-webdav" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-aliyundrive-webdav" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "clouddrive2" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-clouddrive2" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "sunpanel" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-sunpanel" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "luci-app-openvpn-server" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "luci-app-socat" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "istoreenhance" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-istoreenhance" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "linkmount" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "linkease" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-linkease" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "luci-app-memos" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "luci-app-navidrome" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "quickstart" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-quickstart" "kenzok8/small-package" "main" "pkg"

#UPDATE_PACKAGE "luci-theme-design" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "luci-app-design-config" "kenzok8/small-package" "main" "pkg"

#-------------------------------------2025.04.04测试---------------------------------------#
