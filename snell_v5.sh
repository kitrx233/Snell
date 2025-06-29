#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Snell Server 管理脚本
#	Author: kitrx233 
#=================================================

sh_ver="2.0.0"
filepath=$(cd "$(dirname "$0")"; pwd)
file_1=$(echo -e "${filepath}"|awk -F "$0" '{print $1}')
FOLDER="/etc/snell/"
FILE="/usr/local/bin/snell-server"
CONF="/etc/snell/config.conf"
Now_ver_File="/etc/snell/ver.txt"
Local="/etc/sysctl.d/local.conf"

# 颜色定义 - 增强版
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m" && Yellow_font_prefix="\033[0;33m" && Blue_font_prefix="\033[0;34m" && Purple_font_prefix="\033[0;35m" && Cyan_font_prefix="\033[0;36m" && White_font_prefix="\033[0;37m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[注意]${Font_color_suffix}"
Warning="${Blue_font_prefix}[警告]${Font_color_suffix}"
Success="${Cyan_font_prefix}[成功]${Font_color_suffix}"

# 动态效果函数
show_progress() {
    local duration=$1
    local message=$2
    local i=0
    local chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    
    echo -ne "${Cyan_font_prefix}${message}${Font_color_suffix}"
    while [ $i -lt $duration ]; do
        echo -ne "\r${Cyan_font_prefix}${chars[$((i % 10))]} ${message}${Font_color_suffix}"
        sleep 0.1
        i=$((i + 1))
    done
    echo -e "\r${Success}✓ ${message}${Font_color_suffix}"
}

show_loading() {
    local message=$1
    local duration=${2:-3}
    local i=0
    local dots=""
    
    echo -ne "${Yellow_font_prefix}${message}${Font_color_suffix}"
    while [ $i -lt $duration ]; do
        dots="${dots}."
        echo -ne "\r${Yellow_font_prefix}${message}${dots}${Font_color_suffix}"
        sleep 0.5
        i=$((i + 1))
    done
    echo
}

show_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${Cyan_font_prefix}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] ${percentage}%%${Font_color_suffix}"
    
    if [ $current -eq $total ]; then
        echo
    fi
}

animate_text() {
    local text=$1
    local delay=${2:-0.05}
    local i=0
    
    while [ $i -lt ${#text} ]; do
        echo -ne "${Purple_font_prefix}${text:$i:1}${Font_color_suffix}"
        sleep $delay
        i=$((i + 1))
    done
    echo
}

show_success_animation() {
    local message=$1
    echo -e "${Green_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
    echo -e "${Green_font_prefix}║${Font_color_suffix}  ${Success}${message}${Font_color_suffix}                                    ${Green_font_prefix}║${Font_color_suffix}"
    echo -e "${Green_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

show_error_animation() {
    local message=$1
    echo -e "${Red_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
    echo -e "${Red_font_prefix}║${Font_color_suffix}  ${Error}${message}${Font_color_suffix}                                    ${Red_font_prefix}║${Font_color_suffix}"
    echo -e "${Red_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

# 图标定义
ICON_INFO="🔵"
ICON_ERROR="🔴"
ICON_SUCCESS="🟢"
ICON_WARNING="🟡"
ICON_TIP="💡"
ICON_STAR="⭐"
ICON_ROCKET="🚀"
ICON_GEAR="⚙️"
ICON_SHIELD="🛡️"
ICON_NETWORK="🌐"
ICON_KEY="🔑"
ICON_PORT="🔌"
ICON_DNS="📡"
ICON_INTERFACE="🔗"

check_root(){
	[[ $EUID != 0 ]] && echo -e "${Error} 当前非ROOT账号(或没有ROOT权限)，无法继续操作，请更换ROOT账号或使用 ${Green_background_prefix}sudo su${Font_color_suffix} 命令获取临时ROOT权限（执行后可能会提示输入当前账号的密码）。" && exit 1
}

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi
}

Installation_dependency(){
	echo -e "${Info} 正在安装依赖包..."
	if [[ ${release} == "centos" ]]; then
		yum update -y && yum install gzip wget curl unzip jq -y
	else
		apt-get update -y && apt-get install gzip wget curl unzip jq -y
	fi
	sysctl -w net.core.rmem_max=26214400
	sysctl -w net.core.rmem_default=26214400
	\cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	echo -e "${Info} 依赖包安装完成！"
}

#检查系统内核版本
sysArch() {
    uname=$(uname -m)
    if [[ "$uname" == "i686" ]] || [[ "$uname" == "i386" ]]; then
        arch="i386"
    elif [[ "$uname" == *"armv7"* ]] || [[ "$uname" == "armv6l" ]]; then
        arch="armv7l"
    elif [[ "$uname" == *"armv8"* ]] || [[ "$uname" == "aarch64" ]]; then
        arch="aarch64"
    else
        arch="amd64"
    fi    
}

#开启系统 TCP Fast Open
enable_systfo() {
	kernel=$(uname -r | awk -F . '{print $1}')
	if [ "$kernel" -ge 3 ]; then
		echo 3 >/proc/sys/net/ipv4/tcp_fastopen
		[[ ! -e $Local ]] && echo "fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.d/local.conf && sysctl --system >/dev/null 2>&1
		echo -e "${Info} TCP Fast Open 已启用！"
	else
		echo -e "${Warning} 系统内核版本过低，无法支持 TCP Fast Open ！"
	fi
}

check_installed_status(){
	[[ ! -e ${FILE} ]] && echo -e "${Error} 检测到 Snell Server 未安装，请检查 !${Font_color_suffix}" && exit 1
}

check_status(){
	status=`systemctl status snell-server | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1`
}

#检查新版本
check_new_ver(){
	echo -e "${Info} 正在检查 Snell Server 最新版本..."
	if [[ "${selected_version}" == "v4" ]]; then
		new_ver="v4.1.1"
		echo -e "${Info} 检测到 Snell Server v4 最新版本为 [ ${new_ver} ]"
	elif [[ "${selected_version}" == "v5" ]]; then
		new_ver="v5.0.0b1"
		echo -e "${Info} 检测到 Snell Server v5 最新版本为 [ ${new_ver} ]"
		echo -e "${Tip} Snell v5.0.0 新特性："
		echo -e "${Tip} - Dynamic Record Sizing (提高丢包网络环境下的延迟表现)"
		echo -e "${Tip} - QUIC Proxy Mode (专为QUIC流量优化)"
		echo -e "${Tip} - 出口控制 (支持egress-interface参数)"
	fi
}

#检查版本比较
check_ver_comparison(){
	now_ver=$(cat ${Now_ver_File})
	if [[ -z ${now_ver} ]]; then
		echo -e "${Error} Snell Server 当前版本获取失败 !" && exit 1
	fi
	if [[ "${selected_version}" == "v4" ]] && [[ "${now_ver}" != "v4.1.1" ]]; then
		echo -e "${Info} 发现 Snell Server v4 已有新版本 [ v4.1.1 ]"
		echo -e "${Info} 当前版本 [ ${now_ver} ] 开始更新..."
		Download
		echo -e "${Info} Snell Server 更新完成 [ ${now_ver} ] > [ v4.1.1 ]"
	elif [[ "${selected_version}" == "v5" ]] && [[ "${now_ver}" != "v5.0.0b1" ]]; then
		echo -e "${Info} 发现 Snell Server v5 已有新版本 [ v5.0.0b1 ]"
		echo -e "${Info} 当前版本 [ ${now_ver} ] 开始更新..."
		Download
		echo -e "${Info} Snell Server 更新完成 [ ${now_ver} ] > [ v5.0.0b1 ]"
	else
		echo -e "${Info} 当前 Snell Server 版本 [ ${now_ver} ] 已是最新版本 !"
	fi
}

Download() {
	show_loading "正在请求下载 Snell Server ${selected_version}" 2
	
	if [[ "${selected_version}" == "v4" ]]; then
		show_progress 3 "下载 v4.1.1 版本"
		wget --no-check-certificate -N "https://dl.nssurge.com/snell/snell-server-v4.1.1-linux-${arch}.zip"
		zip_file="snell-server-v4.1.1-linux-${arch}.zip"
		version_tag="v4.1.1"
	elif [[ "${selected_version}" == "v5" ]]; then
		show_progress 3 "下载 v5.0.0b1 版本"
		wget --no-check-certificate -N "https://dl.nssurge.com/snell/snell-server-v5.0.0b1-linux-${arch}.zip"
		zip_file="snell-server-v5.0.0b1-linux-${arch}.zip"
		version_tag="v5.0.0b1"
	fi
	
	if [[ ! -e "${zip_file}" ]]; then
		show_error_animation "Snell Server ${selected_version} 下载失败！"
		return 1 && exit 1
	else
		show_progress 2 "解压文件"
		unzip -o "${zip_file}"
	fi
	
	if [[ ! -e "snell-server" ]]; then
		show_error_animation "Snell Server 解压失败！"
		return 1 && exit 1
	else
		rm -rf "${zip_file}"
		chmod +x snell-server
		mv -f snell-server "${FILE}"
		echo "${version_tag}" > ${Now_ver_File}
		show_success_animation "Snell Server ${selected_version} 主程序下载安装完毕！"
		return 0
	fi
}

# 选择Snell版本
Select_version(){
	echo -e "${Purple_font_prefix}${ICON_STAR} 请选择要安装的 Snell Server 版本${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}                    ${Yellow_font_prefix}${ICON_ROCKET} 版本选择${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_SHIELD} v4.1.1 (稳定版，向下兼容)                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}2.${Font_color_suffix} ${ICON_ROCKET} v5.0.0b1 (测试版，新功能)                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择版本 (默认：1.v4.1.1)：${Font_color_suffix}" version_choice
	[[ -z "${version_choice}" ]] && version_choice="1"
	if [[ ${version_choice} == "1" ]]; then
		selected_version="v4"
		echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_SHIELD} 已选择：${Red_background_prefix} v4.1.1 (稳定版) ${Font_color_suffix}        ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	elif [[ ${version_choice} == "2" ]]; then
		selected_version="v5"
		echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_ROCKET} 已选择：${Red_background_prefix} v5.0.0b1 (测试版) ${Font_color_suffix}        ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	else
		selected_version="v4"
		echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_SHIELD} 已选择：${Red_background_prefix} v4.1.1 (稳定版) ${Font_color_suffix}        ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	fi
	echo
}

Service(){
	echo '
[Unit]
Description= Snell Service
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
LimitNOFILE=32767 
Type=simple
User=root
Restart=on-failure
RestartSec=5s
ExecStartPre=/bin/sh -c 'ulimit -n 51200'
ExecStart=/usr/local/bin/snell-server -c /etc/snell/config.conf
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/snell-server.service
	systemctl enable --now snell-server
	show_success_animation "Snell Server 服务配置完成！"
}

Write_config(){
	cat > ${CONF}<<-EOF
[snell-server]
listen = ::0:${port}
ipv6 = ${ipv6}
psk = ${psk}
obfs = ${obfs}
obfs-host = ${host}
tfo = ${tfo}
version = ${ver}
EOF
	[[ -n "${dns}" ]] && echo "dns = ${dns}" >> ${CONF}
	[[ -n "${egress_interface}" ]] && echo "egress-interface = ${egress_interface}" >> ${CONF}
}

Read_config(){
	[[ ! -e ${CONF} ]] && echo -e "${Error} Snell Server 配置文件不存在 !${Font_color_suffix}" && exit 1
	ipv6=$(cat ${CONF}|grep 'ipv6 = '|awk -F 'ipv6 = ' '{print $NF}')
	port=$(cat ${CONF}|grep ':'|awk -F ':' '{print $NF}')
	psk=$(cat ${CONF}|grep 'psk = '|awk -F 'psk = ' '{print $NF}')
	obfs=$(cat ${CONF}|grep 'obfs = '|awk -F 'obfs = ' '{print $NF}')
	host=$(cat ${CONF}|grep 'obfs-host = '|awk -F 'obfs-host = ' '{print $NF}')
	tfo=$(cat ${CONF}|grep 'tfo = '|awk -F 'tfo = ' '{print $NF}')
	ver=$(cat ${CONF}|grep 'version = '|awk -F 'version = ' '{print $NF}')
	dns=$(cat ${CONF}|grep 'dns = '|awk -F 'dns = ' '{print $NF}')
	egress_interface=$(cat ${CONF}|grep 'egress-interface = '|awk -F 'egress-interface = ' '{print $NF}')
}

Set_port(){
	while true
		do
		echo -e "${Purple_font_prefix}${ICON_STAR} 端口配置${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 本步骤不涉及系统防火墙端口操作，请手动放行相应端口！${Font_color_suffix}  ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
		echo -e "${Yellow_font_prefix}${ICON_PORT} 请输入 Snell Server 端口 [1-65535]${Font_color_suffix}"
		read -e -p "${Yellow_font_prefix}${ICON_TIP} 端口 (默认: 2345):${Font_color_suffix} " port
		[[ -z "${port}" ]] && port="2345"
		echo $((${port}+0)) &>/dev/null
		if [[ $? -eq 0 ]]; then
			if [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
				echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
				echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_PORT} 端口设置成功: ${Red_background_prefix} ${port} ${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
				echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
				break
			else
				echo -e "${Error}${ICON_ERROR} 输入错误, 请输入正确的端口。${Font_color_suffix}"
			fi
		else
			echo -e "${Error}${ICON_ERROR} 输入错误, 请输入正确的端口。${Font_color_suffix}"
		fi
		done
}

Set_ipv6(){
	echo -e "${Purple_font_prefix}${ICON_STAR} IPv6 配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 是否开启 IPv6 解析？${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_NETWORK} 开启  ${Green_font_prefix}2.${Font_color_suffix} ${ICON_NETWORK} 关闭${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择 (默认：1.开启):${Font_color_suffix} " ipv6
	[[ -z "${ipv6}" ]] && ipv6="1"
	if [[ ${ipv6} == "1" ]]; then
		ipv6=true
	else
		ipv6=false
	fi
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_NETWORK} IPv6 解析状态: ${Red_background_prefix} ${ipv6} ${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set_psk(){
	echo -e "${Purple_font_prefix}${ICON_STAR} 密钥配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 请输入 Snell Server 密钥${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 密钥 (默认: 随机生成):${Font_color_suffix} " psk
	[[ -z "${psk}" ]] && psk=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_KEY} 密钥设置成功: ${Red_background_prefix} ${psk} ${Font_color_suffix}        ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set_obfs(){
	echo -e "${Purple_font_prefix}${ICON_STAR} OBFS 配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 请选择 OBFS 混淆模式${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_SHIELD} HTTP ${Green_font_prefix}2.${Font_color_suffix} ${ICON_SHIELD} 关闭${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择 (默认：2.关闭):${Font_color_suffix} " obfs
	[[ -z "${obfs}" ]] && obfs="2"
	if [[ ${obfs} == "1" ]]; then
		obfs=http
	elif [[ ${obfs} == "2" ]]; then
		obfs=off
	else
		obfs=off
	fi
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_SHIELD} OBFS 状态: ${Red_background_prefix} ${obfs} ${Font_color_suffix}                        ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set_ver(){
	echo -e "${Purple_font_prefix}${ICON_STAR} 协议版本配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 请选择 Snell Server 协议版本${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_SHIELD} v4 (兼容模式，向下兼容v4客户端)        ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}2.${Font_color_suffix} ${ICON_ROCKET} v5 (v5专用，支持QUIC Proxy Mode等新功能)${Font_color_suffix}  ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择 (默认：2.v5):${Font_color_suffix} " ver
	[[ -z "${ver}" ]] && ver="2"
	if [[ ${ver} == "1" ]]; then
		ver=4
	elif [[ ${ver} == "2" ]]; then
		ver=5
	else
		ver=5
	fi
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_ROCKET} 协议版本: ${Red_background_prefix} v${ver} ${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set_host(){
	echo -e "${Purple_font_prefix}${ICON_STAR} OBFS 域名配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 请输入 Snell Server OBFS 域名${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 域名 (默认: www.bing.com):${Font_color_suffix} " host
	[[ -z "${host}" ]] && host=www.bing.com
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_NETWORK} 域名设置成功: ${Red_background_prefix} ${host} ${Font_color_suffix}                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set_tfo(){
	echo -e "${Purple_font_prefix}${ICON_STAR} TCP Fast Open 配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 是否开启 TCP Fast Open？${Font_color_suffix}                              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_GEAR} 开启  ${Green_font_prefix}2.${Font_color_suffix} ${ICON_GEAR} 关闭${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择 (默认：1.开启):${Font_color_suffix} " tfo
	[[ -z "${tfo}" ]] && tfo="1"
	if [[ ${tfo} == "1" ]]; then
		tfo=true
		enable_systfo
	else
		tfo=false
	fi
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_GEAR} TCP Fast Open 状态: ${Red_background_prefix} ${tfo} ${Font_color_suffix}                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set_dns(){
	echo -e "${Purple_font_prefix}${ICON_STAR} DNS 服务器配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 配置自定义DNS服务器 (v4.1.0+ 功能)${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_DNS} 使用默认DNS${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}2.${Font_color_suffix} ${ICON_DNS} 自定义DNS服务器${Font_color_suffix}                        ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择 (默认：1.使用默认DNS):${Font_color_suffix} " dns_choice
	[[ -z "${dns_choice}" ]] && dns_choice="1"
	if [[ ${dns_choice} == "2" ]]; then
		echo -e "${Yellow_font_prefix}${ICON_DNS} 请输入DNS服务器地址 (支持多个，用逗号分隔)${Font_color_suffix}"
		read -e -p "${Yellow_font_prefix}${ICON_TIP} DNS地址 (默认: 8.8.8.8,8.8.4.4):${Font_color_suffix} " dns
		[[ -z "${dns}" ]] && dns="8.8.8.8,8.8.4.4"
	else
		dns=""
	fi
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_DNS} DNS 配置: ${Red_background_prefix} ${dns:-默认DNS} ${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set_egress_interface(){
	echo -e "${Purple_font_prefix}${ICON_STAR} 出口接口配置${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip}${ICON_TIP} 配置出口接口 (v5.0.0+ 功能，需要root权限)${Font_color_suffix}              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_INTERFACE} 使用默认出口${Font_color_suffix}                        ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}2.${Font_color_suffix} ${ICON_INTERFACE} 指定出口接口${Font_color_suffix}                        ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择 (默认：1.使用默认出口):${Font_color_suffix} " egress_choice
	[[ -z "${egress_choice}" ]] && egress_choice="1"
	if [[ ${egress_choice} == "2" ]]; then
		echo -e "${Yellow_font_prefix}${ICON_INTERFACE} 请输入出口接口名称${Font_color_suffix}"
		read -e -p "${Yellow_font_prefix}${ICON_TIP} 接口名称 (例如: eth0, wlan0):${Font_color_suffix} " egress_interface
		[[ -z "${egress_interface}" ]] && egress_interface=""
	else
		egress_interface=""
	fi
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_INTERFACE} 出口接口: ${Red_background_prefix} ${egress_interface:-默认出口} ${Font_color_suffix}                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
}

Set(){
	check_installed_status
	echo -e "${Purple_font_prefix}${ICON_STAR} 配置设置菜单${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}                  ${Yellow_font_prefix}${ICON_GEAR} 配置设置选项${Font_color_suffix}                  ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} ${ICON_PORT} 修改 端口                                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}2.${Font_color_suffix} ${ICON_KEY} 修改 密钥                                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}3.${Font_color_suffix} ${ICON_SHIELD} 配置 OBFS                              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}4.${Font_color_suffix} ${ICON_NETWORK} 配置 OBFS 域名                          ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}5.${Font_color_suffix} ${ICON_NETWORK} 开关 IPv6 解析                          ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}6.${Font_color_suffix} ${ICON_GEAR} 开关 TCP Fast Open                      ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}7.${Font_color_suffix} ${ICON_ROCKET} 配置 Snell Server 协议版本              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}8.${Font_color_suffix} ${ICON_DNS} 配置 DNS 服务器 (v4.1.0+)              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}9.${Font_color_suffix} ${ICON_INTERFACE} 配置出口接口 (v5.0.0+)              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}10.${Font_color_suffix} ${ICON_GEAR} 修改 全部配置                          ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix}${ICON_TIP} 请选择操作 (默认: 取消):${Font_color_suffix} " modify
	[[ -z "${modify}" ]] && echo -e "${Warning}${ICON_WARNING} 已取消...${Font_color_suffix}" && exit 1
	if [[ "${modify}" == "1" ]]; then
		Read_config
		Set_port
		psk=${psk}
		obfs=${obfs}
		host=${host}
		ipv6=${ipv6}
		tfo=${tfo}
		ver=${ver}
		dns=${dns}
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "2" ]]; then
		Read_config
		port=${port}
		Set_psk
		obfs=${obfs}
		host=${host}
		ipv6=${ipv6}
		tfo=${tfo}
		ver=${ver}
		dns=${dns}
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "3" ]]; then
		Read_config
		port=${port}
		psk=${psk}
		Set_obfs
		host=${host}
		ipv6=${ipv6}
		tfo=${tfo}
		ver=${ver}
		dns=${dns}
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "4" ]]; then
		Read_config
		port=${port}
		psk=${psk}
		obfs=${obfs}
		Set_host
		ipv6=${ipv6}
		tfo=${tfo}
		ver=${ver}
		dns=${dns}
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "5" ]]; then
		Read_config
		port=${port}
		psk=${psk}
		obfs=${obfs}
		host=${host}
		Set_ipv6
		tfo=${tfo}
		ver=${ver}
		dns=${dns}
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "6" ]]; then
		Read_config
		port=${port}
		psk=${psk}
		obfs=${obfs}
		host=${host}
		ipv6=${ipv6}
		Set_tfo
		ver=${ver}
		dns=${dns}
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "7" ]]; then
		Read_config
		port=${port}
		psk=${psk}
		obfs=${obfs}
		host=${host}
		ipv6=${ipv6}
		tfo=${tfo}
		Set_ver
		dns=${dns}
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "8" ]]; then
		Read_config
		port=${port}
		psk=${psk}
		obfs=${obfs}
		host=${host}
		ipv6=${ipv6}
		tfo=${tfo}
		ver=${ver}
		Set_dns
		egress_interface=${egress_interface}
		Write_config
		Restart
	elif [[ "${modify}" == "9" ]]; then
		Read_config
		port=${port}
		psk=${psk}
		obfs=${obfs}
		host=${host}
		ipv6=${ipv6}
		tfo=${tfo}
		ver=${ver}
		dns=${dns}
		Set_egress_interface
		Write_config
		Restart
	elif [[ "${modify}" == "10" ]]; then
		Read_config
		Set_port
		Set_psk
		Set_obfs
		Set_host
		Set_ipv6
		Set_tfo
		Set_ver
		Set_dns
		Set_egress_interface
		Write_config
		Restart
	else
		echo -e "${Error} 请输入正确的数字(1-10)" && exit 1
	fi
    sleep 3s
    start_menu
}

Install(){
	check_root
	[[ -e ${FILE} ]] && show_error_animation "检测到 Snell Server 已安装 !" && exit 1
	
	animate_text "开始安装 Snell Server..." 0.03
	echo
	
	show_progress 2 "选择版本"
	Select_version
	
	show_progress 2 "设置配置"
	Set_port
	Set_psk
	Set_obfs
	Set_host
	Set_ipv6
	Set_tfo
	Set_ver
	Set_dns
	Set_egress_interface
	
	show_progress 3 "安装依赖"
	Installation_dependency
	
	show_progress 5 "下载安装"
	check_new_ver
	Download
	
	show_progress 2 "配置服务"
	Service
	
	show_progress 2 "写入配置"
	Write_config
	
	show_success_animation "所有步骤安装完毕，开始启动..."
	Start
    sleep 3s
    start_menu
}

Start(){
	check_installed_status
	check_status
	[[ "${status}" == "running" ]] && echo -e "${Warning} Snell Server 正在运行 !${Font_color_suffix}" && exit 1
	systemctl start snell-server
	sleep 2s
	check_status
	[[ "${status}" == "running" ]] && show_success_animation "Snell Server 启动成功 !" || show_error_animation "Snell Server 启动失败 !"
}

Stop(){
	check_installed_status
	check_status
	[[ "${status}" == "stopped" ]] && echo -e "${Warning} Snell Server 未在运行 !${Font_color_suffix}" && exit 1
	systemctl stop snell-server
	sleep 2s
	check_status
	[[ "${status}" == "stopped" ]] && show_success_animation "Snell Server 停止成功 !" || show_error_animation "Snell Server 停止失败 !"
}

Restart(){
	check_installed_status
	check_status
	[[ "${status}" == "stopped" ]] && echo -e "${Warning} Snell Server 未在运行 !${Font_color_suffix}" && exit 1
	systemctl restart snell-server
	sleep 2s
	check_status
	[[ "${status}" == "running" ]] && show_success_animation "Snell Server 重启成功 !" || show_error_animation "Snell Server 重启失败 !"
}

Update(){
	check_installed_status
	check_new_ver
	check_ver_comparison
	echo -e "${Info} Snell Server 更新完毕 !"
    sleep 3s
    start_menu
}

Uninstall(){
	check_installed_status
	animate_text "卸载 Snell Server" 0.03
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Warning} 确定要卸载 Snell Server 吗？${Font_color_suffix}                        ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Tip} 卸载后所有配置将被删除！${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	read -e -p "${Yellow_font_prefix} 确定继续吗？(y/N):${Font_color_suffix} " unyn
	[[ -z ${unyn} ]] && unyn="n"
	if [[ ${unyn} == [Yy] ]]; then
		check_status
		[[ "${status}" == "running" ]] && systemctl stop snell-server
		show_progress 2 "删除配置文件"
		if [[ -e ${CONF} ]]; then
			rm -rf ${CONF}
		fi
		if [[ -e ${FOLDER} ]]; then
			rm -rf ${FOLDER}
		fi
		if [[ -e ${FILE} ]]; then
			rm -rf ${FILE}
		fi
		if [[ -e ${Now_ver_File} ]]; then
			rm -rf ${Now_ver_File}
		fi
		if [[ -e "/etc/systemd/system/snell-server.service" ]]; then
			rm -rf "/etc/systemd/system/snell-server.service"
		fi
		if [[ -e "/lib/systemd/system/snell-server.service" ]]; then
			rm -rf "/lib/systemd/system/snell-server.service"
		fi
		systemctl daemon-reload
		show_success_animation "Snell Server 卸载完成 !"
	else
		echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info} 已取消卸载${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	fi
}

getipv4(){
	ipv4=$(wget -qO- -4 -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ipv4}" ]]; then
		ipv4=$(wget -qO- -4 -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ipv4}" ]]; then
			ipv4=$(wget -qO- -4 -t1 -T2 members.3322.org/dyndns/getip)
			if [[ -z "${ipv4}" ]]; then
				ipv4="IPv4_Error"
			fi
		fi
	fi
}

getipv6(){
	ip6=$(wget -qO- -6 -t1 -T2 ifconfig.co)
	if [[ -z "${ip6}" ]]; then
		ip6="IPv6_Error"
	fi
}

View(){
	check_installed_status
	Read_config
	getipv4
	getipv6
	clear && echo
	echo -e "${Purple_font_prefix}${ICON_STAR} Snell Server 配置信息${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}                ${Yellow_font_prefix}${ICON_NETWORK} 服务器配置详情${Font_color_suffix}                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	[[ "${ipv4}" != "IPv4_Error" ]] && echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_NETWORK} IPv4地址\t: ${Green_font_prefix}${ipv4}${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	[[ "${ip6}" != "IPv6_Error" ]] && echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_NETWORK} IPv6地址\t: ${Green_font_prefix}${ip6}${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_PORT} 端口\t\t: ${Green_font_prefix}${port}${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_KEY} 密钥\t\t: ${Green_font_prefix}${psk}${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_SHIELD} OBFS\t\t: ${Green_font_prefix}${obfs}${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_NETWORK} 域名\t\t: ${Green_font_prefix}${host}${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_NETWORK} IPv6\t\t: ${Green_font_prefix}${ipv6}${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_GEAR} TFO\t\t: ${Green_font_prefix}${tfo}${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_ROCKET} VER\t\t: ${Green_font_prefix}${ver}${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
	[[ -n "${dns}" ]] && echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_DNS} DNS\t\t: ${Green_font_prefix}${dns}${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	[[ -n "${egress_interface}" ]] && echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${ICON_INTERFACE} 出口接口\t: ${Green_font_prefix}${egress_interface}${Font_color_suffix}                    ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	echo
	before_start_menu
}

Status(){
	check_installed_status
	check_status
	clear && echo
	echo -e "${Purple_font_prefix}${ICON_STAR} Snell Server 运行状态${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}                ${Yellow_font_prefix}${ICON_TIP} 服务状态详情${Font_color_suffix}                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	if [[ "${status}" == "running" ]]; then
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success}${ICON_SUCCESS} 运行状态\t: ${Green_font_prefix}已启动${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 进程ID\t\t: ${Green_font_prefix}${PID}${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 运行时长\t: ${Green_font_prefix}${run_time}${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 内存占用\t: ${Green_font_prefix}${mem_usage}${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 虚拟内存\t: ${Green_font_prefix}${virtual_memory}${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 共享内存\t: ${Green_font_prefix}${shared_memory}${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 状态\t\t: ${Green_font_prefix}${Status}${Font_color_suffix}                                    ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 优先级\t\t: ${Green_font_prefix}${Priority}${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} CPU使用率\t: ${Green_font_prefix}${Cpu_usage}${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 运行用户\t: ${Green_font_prefix}${Owner}${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Info}${ICON_GEAR} 启动时间\t: ${Green_font_prefix}${Start_time}${Font_color_suffix}                            ${Cyan_font_prefix}║${Font_color_suffix}"
	else
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Error}${ICON_ERROR} 运行状态\t: ${Red_font_prefix}未启动${Font_color_suffix}                                ${Cyan_font_prefix}║${Font_color_suffix}"
	fi
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	echo
	before_start_menu
}

before_start_menu() {
    echo && echo -n -e "${Yellow_font_prefix}* 按回车返回主菜单 *${Font_color_suffix}" && read temp
    start_menu
}

start_menu(){
clear
check_root
check_sys
sysArch
action=$1
	animate_text "Snell Server 管理脚本" 0.02
	echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}              ${Yellow_font_prefix} Snell Server 管理脚本 v${sh_ver}${Font_color_suffix}              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╠══════════════════════════════════════════════════════════════╣${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}1.${Font_color_suffix} 安装 Snell Server${Yellow_font_prefix}[可选v4/v5]${Font_color_suffix}              ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Red_font_prefix}2.${Font_color_suffix} 卸载 Snell Server                          ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Green_font_prefix}3.${Font_color_suffix} 启动 Snell Server                          ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Yellow_font_prefix}4.${Font_color_suffix} 停止 Snell Server                          ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Blue_font_prefix}5.${Font_color_suffix} 重启 Snell Server                          ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Purple_font_prefix}6.${Font_color_suffix} 设置 配置信息                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Cyan_font_prefix}7.${Font_color_suffix} 查看 配置信息                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${White_font_prefix}8.${Font_color_suffix} 查看 运行状态                            ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Red_font_prefix}9.${Font_color_suffix} 退出脚本                                ${Cyan_font_prefix}║${Font_color_suffix}"
	echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	
	# 状态显示
	if [[ -e ${FILE} ]]; then
		check_status
		if [[ "$status" == "running" ]]; then
			echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
			echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Success} 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}              ${Cyan_font_prefix}║${Font_color_suffix}"
			echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
		else
			echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
			echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Warning} 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}              ${Cyan_font_prefix}║${Font_color_suffix}"
			echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
		fi
	else
		echo -e "${Cyan_font_prefix}╔══════════════════════════════════════════════════════════════╗${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}║${Font_color_suffix}  ${Error} 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}                              ${Cyan_font_prefix}║${Font_color_suffix}"
		echo -e "${Cyan_font_prefix}╚══════════════════════════════════════════════════════════════╝${Font_color_suffix}"
	fi
	echo
	read -e -p "${Yellow_font_prefix} 请输入数字 [1-9]:${Font_color_suffix} " num
	case "$num" in
		1)
		Install
		;;
		2)
		Uninstall
		;;
		3)
		Start
		;;
		4)
		Stop
		;;
		5)
		Restart
		;;
		6)
		Set
		;;
		7)
		View
		;;
		8)
		Status
		;;
		9)
		exit 1
		;;
		*)
		echo -e "${Error} 请输入正确数字 [1-9]${Font_color_suffix}"
		;;
	esac
}

# 脚本入口
start_menu 