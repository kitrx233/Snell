#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS/Debian/Ubuntu
#	Description: Snell Server v5 管理脚本
#	WebSite: https://surge.tel
#	Version: 2.0.0
#=================================================

sh_ver="2.0.0"
FOLDER="/etc/snell/"
FILE="/usr/local/bin/snell-server"
CONF="/etc/snell/config.conf"
Now_ver_File="/etc/snell/ver.txt"

# 颜色定义
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
Cyan='\033[0;36m'
White='\033[1;37m'
NC='\033[0m'

# 状态图标
SUCCESS_ICON="✓"
ERROR_ICON="✗"
INFO_ICON="ℹ"
WARNING_ICON="⚠"

# 日志函数
log_info() {
    echo -e "${INFO_ICON} ${Green}[信息]${NC} $1"
}

log_error() {
    echo -e "${ERROR_ICON} ${Red}[错误]${NC} $1"
}

log_warning() {
    echo -e "${WARNING_ICON} ${Yellow}[警告]${NC} $1"
}

log_success() {
    echo -e "${SUCCESS_ICON} ${Green}[成功]${NC} $1"
}

# 分隔线函数
print_separator() {
    echo -e "${Cyan}══════════════════════════════════════════════════════════════${NC}"
}

# 标题函数
print_title() {
    echo
    print_separator
    echo -e "${White}                    Snell Server v5 管理脚本${NC}"
    echo -e "${Yellow}                          版本: ${sh_ver}${NC}"
    print_separator
    echo
}

# 检查ROOT权限
check_root(){
    [[ $EUID != 0 ]] && {
        log_error "当前非ROOT账号(或没有ROOT权限)，无法继续操作"
        echo -e "${Yellow}请使用以下命令获取临时ROOT权限：${NC}"
        echo -e "${Green}sudo su${NC}"
        exit 1
    }
}

# 检查系统
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
    
    log_info "检测到系统: ${release}"
}

# 检查系统架构
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
    
    log_info "检测到架构: ${arch}"
}

# 安装依赖
Installation_dependency(){
    log_info "正在安装系统依赖..."
    
    if [[ ${release} == "centos" ]]; then
        yum update -y >/dev/null 2>&1
        yum install -y gzip wget curl unzip jq >/dev/null 2>&1
    else
        apt-get update -y >/dev/null 2>&1
        apt-get install -y gzip wget curl unzip jq >/dev/null 2>&1
    fi
    
    log_success "系统依赖安装完成"
}

# 下载函数
Download() {
    log_info "正在下载 Snell Server v5.0.0..."
    
    if [[ ! -e "${FOLDER}" ]]; then
        mkdir "${FOLDER}"
    fi
    
    wget --no-check-certificate -N "https://dl.nssurge.com/snell/snell-server-v5.0.0b1-linux-${arch}.zip"
    
    if [[ ! -e "snell-server-v5.0.0b1-linux-${arch}.zip" ]]; then
        log_error "Snell Server 下载失败!"
        return 1
    else
        log_info "正在解压文件..."
        unzip -o "snell-server-v5.0.0b1-linux-${arch}.zip" >/dev/null 2>&1
    fi
    
    if [[ ! -e "snell-server" ]]; then
        log_error "Snell Server 解压失败!"
        return 1
    else
        rm -rf "snell-server-v5.0.0b1-linux-${arch}.zip"
        chmod +x snell-server
        mv -f snell-server "${FILE}"
        echo "v5.0.0" > ${Now_ver_File}
        log_success "Snell Server v5.0.0 下载安装完毕!"
        return 0
    fi
}

# 服务配置
Service(){
    log_info "正在配置系统服务..."
    
    cat > /etc/systemd/system/snell-server.service << EOF
[Unit]
Description=Snell Server v5 Service
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
WantedBy=multi-user.target
EOF

    systemctl enable --now snell-server >/dev/null 2>&1
    log_success "Snell Server 服务配置完成!"
}

# 写入配置文件
Write_config(){
    cat > ${CONF} << EOF
[snell-server]
listen = ::0:${port}
ipv6 = ${ipv6}
psk = ${psk}
obfs = ${obfs}
obfs-host = ${host}
tfo = ${tfo}
version = ${ver}
# v5 新特性
quic-proxy = ${quic_proxy}
dynamic-record-sizing = ${dynamic_record}
egress-interface = ${egress_interface}
dns = ${dns_servers}
EOF
}

# 设置端口
Set_port(){
    while true; do
        echo -e "${Yellow}⚠ 注意: 本步骤不涉及系统防火墙端口操作，请手动放行相应端口！${NC}"
        echo
        read -e -p "请输入 Snell Server 端口 [1-65535] (默认: 2345): " port
        [[ -z "${port}" ]] && port="2345"
        
        if [[ ${port} =~ ^[0-9]+$ ]] && [[ ${port} -ge 1 ]] && [[ ${port} -le 65535 ]]; then
            echo
            print_separator
            echo -e "${Green}端口设置: ${port}${NC}"
            print_separator
            echo
            break
        else
            log_error "输入错误, 请输入正确的端口。"
        fi
    done
}

# 设置密钥
Set_psk(){
    read -e -p "请输入 Snell Server 密钥 [0-9][a-z][A-Z] (默认: 随机生成): " psk
    [[ -z "${psk}" ]] && psk=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
    
    echo
    print_separator
    echo -e "${Green}密钥: ${psk}${NC}"
    print_separator
    echo
}

# 设置版本
Set_ver(){
    echo -e "${Cyan}配置 Snell Server 协议版本${NC}"
    echo -e "${Green}1.${NC} v4 (兼容模式)  ${Green}2.${NC} v5 (新特性)"
    read -e -p "(默认: 2.v5): " ver
    [[ -z "${ver}" ]] && ver="2"
    
    if [[ ${ver} == "1" ]]; then
        ver=4
    else
        ver=5
    fi
    
    echo
    print_separator
    echo -e "${Green}Snell Server 协议版本: ${ver}${NC}"
    print_separator
    echo
}

# 设置QUIC代理
Set_quic_proxy(){
    echo -e "${Cyan}是否启用 QUIC Proxy 模式？${NC}"
    echo -e "${Yellow}注意: 此功能需要开放UDP端口${NC}"
    echo -e "${Green}1.${NC} 启用  ${Green}2.${NC} 禁用"
    read -e -p "(默认: 1.启用): " quic_proxy
    [[ -z "${quic_proxy}" ]] && quic_proxy="1"
    
    if [[ ${quic_proxy} == "1" ]]; then
        quic_proxy=true
    else
        quic_proxy=false
    fi
    
    echo
    print_separator
    echo -e "${Green}QUIC Proxy 状态: ${quic_proxy}${NC}"
    print_separator
    echo
}

# 设置动态记录大小
Set_dynamic_record(){
    echo -e "${Cyan}是否启用动态记录大小？${NC}"
    echo -e "${Yellow}注意: 此功能可提高丢包网络环境下的延迟表现${NC}"
    echo -e "${Green}1.${NC} 启用  ${Green}2.${NC} 禁用"
    read -e -p "(默认: 1.启用): " dynamic_record
    [[ -z "${dynamic_record}" ]] && dynamic_record="1"
    
    if [[ ${dynamic_record} == "1" ]]; then
        dynamic_record=true
    else
        dynamic_record=false
    fi
    
    echo
    print_separator
    echo -e "${Green}动态记录大小状态: ${dynamic_record}${NC}"
    print_separator
    echo
}

# 设置其他配置
Set_other_config(){
    # 设置IPv6
    echo -e "${Cyan}是否开启 IPv6 解析？${NC}"
    echo -e "${Green}1.${NC} 开启  ${Green}2.${NC} 关闭"
    read -e -p "(默认: 1.开启): " ipv6_choice
    [[ -z "${ipv6_choice}" ]] && ipv6_choice="1"
    
    if [[ ${ipv6_choice} == "1" ]]; then
        ipv6=true
    else
        ipv6=false
    fi
    
    # 设置OBFS
    echo -e "${Cyan}配置 OBFS${NC}"
    echo -e "${Green}1.${NC} HTTP  ${Green}2.${NC} 关闭"
    read -e -p "(默认: 2.关闭): " obfs_choice
    [[ -z "${obfs_choice}" ]] && obfs_choice="2"
    
    if [[ ${obfs_choice} == "1" ]]; then
        obfs=http
    else
        obfs=off
    fi
    
    # 设置域名
    read -e -p "请输入 Snell Server 域名 (默认: www.bing.com): " host
    [[ -z "${host}" ]] && host=www.bing.com
    
    # 设置TCP Fast Open
    echo -e "${Cyan}是否开启 TCP Fast Open？${NC}"
    echo -e "${Green}1.${NC} 开启  ${Green}2.${NC} 关闭"
    read -e -p "(默认: 1.开启): " tfo_choice
    [[ -z "${tfo_choice}" ]] && tfo_choice="1"
    
    if [[ ${tfo_choice} == "1" ]]; then
        tfo=true
    else
        tfo=false
    fi
    
    # 设置出口接口
    echo -e "${Cyan}是否配置出口接口？${NC}"
    echo -e "${Yellow}注意: 需要root权限或CAP_NET_RAW/CAP_NET_ADMIN授权${NC}"
    echo -e "${Green}1.${NC} 配置  ${Green}2.${NC} 不配置"
    read -e -p "(默认: 2.不配置): " egress_choice
    [[ -z "${egress_choice}" ]] && egress_choice="2"
    
    if [[ ${egress_choice} == "1" ]]; then
        read -e -p "请输入出口接口名称 (如: eth0): " egress_interface
        [[ -z "${egress_interface}" ]] && egress_interface=""
    else
        egress_interface=""
    fi
    
    # 设置DNS服务器
    echo -e "${Cyan}是否配置自定义DNS服务器？${NC}"
    echo -e "${Green}1.${NC} 配置  ${Green}2.${NC} 使用系统默认"
    read -e -p "(默认: 2.使用系统默认): " dns_choice
    [[ -z "${dns_choice}" ]] && dns_choice="2"
    
    if [[ ${dns_choice} == "1" ]]; then
        read -e -p "请输入DNS服务器地址 (如: 8.8.8.8,8.8.4.4): " dns_servers
        [[ -z "${dns_servers}" ]] && dns_servers="8.8.8.8,8.8.4.4"
    else
        dns_servers=""
    fi
}

# 安装
Install(){
    check_root
    [[ -e ${FILE} ]] && {
        log_error "检测到 Snell Server 已安装!"
        exit 1
    }
    
    print_title
    
    log_info "开始配置 Snell Server v5..."
    Set_port
    Set_psk
    Set_ver
    Set_quic_proxy
    Set_dynamic_record
    Set_other_config
    
    log_info "开始安装系统依赖..."
    Installation_dependency
    
    log_info "开始下载 Snell Server v5..."
    Download
    
    log_info "开始配置系统服务..."
    Service
    
    log_info "开始写入配置文件..."
    Write_config
    
    log_info "所有步骤安装完毕，开始启动..."
    systemctl start snell-server
    log_success "Snell Server v5 安装完成并已启动!"
    
    sleep 3s
    start_menu
}

# 卸载
Uninstall(){
    check_root
    [[ ! -e ${FILE} ]] && {
        log_error "Snell Server 未安装!"
        exit 1
    }
    
    echo -e "${Yellow}确定要卸载 Snell Server? (y/N)${NC}"
    read -e -p "(默认: n): " unyn
    [[ -z ${unyn} ]] && unyn="n"
    
    if [[ ${unyn} == [Yy] ]]; then
        systemctl stop snell-server
        systemctl disable snell-server
        rm -rf "${FILE}"
        rm -rf "${FOLDER}"
        log_success "Snell Server 卸载完成!"
    else
        log_warning "卸载已取消"
    fi
    
    sleep 3s
    start_menu
}

# 查看配置
View(){
    check_root
    [[ ! -e ${CONF} ]] && {
        log_error "Snell Server 配置文件不存在!"
        exit 1
    }
    
    clear
    print_title
    
    echo -e "${White}Snell Server v5 配置信息：${NC}"
    print_separator
    
    # 读取配置
    port=$(cat ${CONF}|grep ':'|awk -F ':' '{print $NF}')
    psk=$(cat ${CONF}|grep 'psk = '|awk -F 'psk = ' '{print $NF}')
    ver=$(cat ${CONF}|grep 'version = '|awk -F 'version = ' '{print $NF}')
    quic_proxy=$(cat ${CONF}|grep 'quic-proxy = '|awk -F 'quic-proxy = ' '{print $NF}')
    dynamic_record=$(cat ${CONF}|grep 'dynamic-record-sizing = '|awk -F 'dynamic-record-sizing = ' '{print $NF}')
    
    echo -e "${Cyan}端口${NC}: ${Green}${port}${NC}"
    echo -e "${Cyan}密钥${NC}: ${Green}${psk}${NC}"
    echo -e "${Cyan}协议版本${NC}: ${Green}${ver}${NC}"
    echo -e "${Cyan}QUIC代理${NC}: ${Green}${quic_proxy:-"未配置"}${NC}"
    echo -e "${Cyan}动态记录大小${NC}: ${Green}${dynamic_record:-"未配置"}${NC}"
    
    print_separator
    echo
    
    before_start_menu
}

# 返回主菜单前
before_start_menu() {
    echo -e "${Yellow}按回车键返回主菜单${NC}"
    read temp
    start_menu
}

# 主菜单
start_menu(){
    clear
    check_root
    check_sys
    sysArch
    
    print_title
    
    echo -e "${White}请选择操作：${NC}"
    print_separator
    echo -e "${Green}1.${NC} 安装 Snell Server v5"
    echo -e "${Green}2.${NC} 卸载 Snell Server"
    echo -e "${Green}3.${NC} 查看配置信息"
    print_separator
    echo -e "${Green}0.${NC} 退出脚本"
    print_separator
    
    # 显示当前状态
    if [[ -e ${FILE} ]]; then
        if systemctl is-active --quiet snell-server; then
            echo -e "${Green}当前状态: 已安装并已启动${NC}"
        else
            echo -e "${Yellow}当前状态: 已安装但未启动${NC}"
        fi
    else
        echo -e "${Red}当前状态: 未安装${NC}"
    fi
    
    echo
    read -e -p "请输入数字 [0-3]: " num
    
    case "$num" in
        1) Install ;;
        2) Uninstall ;;
        3) View ;;
        0) exit 0 ;;
        *) 
            log_error "请输入正确数字 [0-3]"
            sleep 2s
            start_menu
            ;;
    esac
}

# 启动脚本
start_menu 