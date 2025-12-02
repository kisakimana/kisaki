#!/bin/bash
#=========================================================
#                 VPS 一键系统管理脚本
#                 版本：v1.0
#                 作者：kisaki
#=========================================================

# ---------- 配色定义 ----------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

# ---------- 权限检测 ----------
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}[×] 错误：此脚本必须以 root 权限运行${RESET}"
    exit 1
fi
# ---------- 通用依赖安装 ----------
apt update -y >/dev/null 2>&1
for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
        echo -e "${BLUE}[→] 安装依赖: $dep${RESET}"
        apt install -y "$dep" >/dev/null 2>&1
    fi
done


# ---------- 基础函数 ----------
get_debian_version() {
    [ -f /etc/debian_version ] && cat /etc/debian_version || echo "0"
}
get_debian_major_version() {
    [ -f /etc/debian_version ] && echo $(cut -d'.' -f1 < /etc/debian_version) || echo "0"
}

# ---------- 系统信息显示 ----------
display_system_info() {
    clear
    echo -e "${BOLD}${CYAN}=================================================="
    echo -e "                 系统信息概览"
    echo -e "==================================================${RESET}"

    if command -v lsb_release >/dev/null 2>&1; then
        os_name=$(lsb_release -d | cut -f2-)
    else
        os_name=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    fi

    echo -e "${YELLOW}操作系统:${RESET} $os_name"
    echo -e "${YELLOW}内核版本:${RESET} $(uname -r)"
    echo -e "${YELLOW}系统架构:${RESET} $(arch)"
    echo -e "${YELLOW}Debian版本:${RESET} $(get_debian_version)"
    echo -e "${YELLOW}登录用户:${RESET} $(whoami)"
    echo -e "${YELLOW}主机名:${RESET} $(hostname)"

    cpu_model=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    cpu_count=$(grep -c '^processor' /proc/cpuinfo)
    echo -e "${YELLOW}CPU型号:${RESET} $cpu_model"
    echo -e "${YELLOW}CPU核心数:${RESET} $cpu_count"

    mem_total=$(free -h | awk '/Mem:/ {print $2}')
    mem_used=$(free -h | awk '/Mem:/ {print $3}')
    echo -e "${YELLOW}内存使用:${RESET} $mem_used / $mem_total"

    swap_total=$(free -h | awk '/Swap:/ {print $2}')
    swap_used=$(free -h | awk '/Swap:/ {print $3}')
    if [ "$swap_total" = "0B" ]; then
        echo -e "${YELLOW}SWAP使用:${RESET} 未检测到SWAP分区"
    else
        echo -e "${YELLOW}SWAP使用:${RESET} $swap_used / $swap_total"
    fi

    echo -e "${YELLOW}硬盘使用:${RESET}"
    df -h | grep -vE 'tmpfs|udev' | awk '{printf "  %-20s %-8s %-8s %-8s %-10s\n", $1, $2, $3, $4, $6}'

    # BBR状态
    bbr_status="未启用"
    sysctl net.ipv4.tcp_congestion_control | grep -q bbr && bbr_status="已启用"
    lsmod | grep -q bbr && bbr_status="$bbr_status (模块已加载)" || bbr_status="$bbr_status (模块未加载)"
    echo -e "${YELLOW}BBR状态:${RESET} $bbr_status"

    qdisc=$(sysctl net.core.default_qdisc 2>/dev/null | awk -F'= ' '{print $2}')
    [ -n "$qdisc" ] && echo -e "${YELLOW}BBR调度算法:${RESET} $qdisc" || echo -e "${YELLOW}BBR调度算法:${RESET} 未设置"

    echo -e "${CYAN}==================================================${RESET}"
}

# ---------- 菜单 ----------
show_menu() {
    display_system_info
    echo -e "${BOLD}${GREEN}               系统管理工具菜单${RESET}"
    echo -e "${CYAN}==================================================${RESET}"
    echo -e "${YELLOW}1.${RESET} 系统升级与缓存清理"
    echo -e "${YELLOW}2.${RESET} 开启BBR加速"
    echo -e "${YELLOW}3.${RESET} 开启 Swap 交换文件"
    echo -e "${YELLOW}4.${RESET} 清理多余内核"
    echo -e "${YELLOW}5.${RESET} 安装 X-UI 面板"
    echo -e "${YELLOW}6.${RESET} 安装 3X-UI 面板"
    echo -e "${YELLOW}7.${RESET} 流媒体解锁测试"
    echo -e "${YELLOW}8.${RESET} 网络质量测试"
    echo -e "${YELLOW}9.${RESET} 融合怪全面测试"
    echo -e "${YELLOW}10.${RESET} 服务器性能测试"
    echo -e "${YELLOW}11.${RESET} 安装 Docker 环境"
    echo -e "${YELLOW}12.${RESET} 系统清理"
    echo -e "${YELLOW}13.${RESET} GB5 性能测试"
    echo -e "${YELLOW}14.${RESET} NextTrace 路由跟踪"
    echo -e "${YELLOW}15.${RESET} 安装 S-UI 面板"
    echo -e "${YELLOW}16.${RESET} PD DNS 延迟检测"
    echo -e "${YELLOW}17.${RESET} 安装 哪吒 V0 面板"
    echo -e "${YELLOW}18.${RESET} 安装 iperf3"
    echo -e "${YELLOW}19.${RESET} DD成 Debian12 并设置密码"
	echo -e "${YELLOW}20.${RESET} 自定义更改主机名"
    echo -e "${YELLOW}0.${RESET} 退出脚本"
    echo -e "${CYAN}==================================================${RESET}"
}

# ---------- 通用依赖安装 ----------
install_deps() {
    for dep in "$@"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -e "${BLUE}[→] 安装依赖: ${dep}${RESET}"
            apt install -y "$dep" >/dev/null 2>&1
        fi
    done
}

# ---------- 通用清理 ----------
cleanup() {
    [ -d "$1" ] && rm -rf "$1" && echo -e "${GREEN}[√] 清理临时目录: $1${RESET}"
}

# ---------- 各功能函数 ----------
system_upgrade() {
    echo -e "${CYAN}>>> 系统升级与清理开始...${RESET}"
    apt update -y && apt upgrade -y && apt autoremove -y && apt autoclean -y
    echo -e "${GREEN}[√] 系统升级与清理完成${RESET}"
}

enable_bbr() {
    echo -e "${CYAN}>>> 正在配置 BBR 加速...${RESET}"
    ver_major=$(get_debian_major_version)
    ver_full=$(get_debian_version)
    echo -e "检测到 Debian ${YELLOW}${ver_full}${RESET} (主版本号: ${ver_major})"

    cfg_file="/etc/sysctl.conf"
    [ "$ver_major" -ge 13 ] && cfg_file="/etc/sysctl.d/sysctl.conf"
    mkdir -p /etc/sysctl.d

    grep -q "net.core.default_qdisc=fq" "$cfg_file" || echo "net.core.default_qdisc=fq" >>"$cfg_file"
    grep -q "net.ipv4.tcp_congestion_control=bbr" "$cfg_file" || echo "net.ipv4.tcp_congestion_control=bbr" >>"$cfg_file"
    [ "$ver_major" -ge 13 ] && sysctl --system >/dev/null || sysctl -p >/dev/null

    modprobe tcp_bbr 2>/dev/null
    if lsmod | grep -q bbr; then
        echo -e "${GREEN}[√] BBR 模块加载成功${RESET}"
    else
        echo -e "${YELLOW}[!] BBR 模块未加载，可能需要重启系统${RESET}"
    fi

    sysctl net.ipv4.tcp_congestion_control
    sysctl net.core.default_qdisc
    echo -e "${GREEN}[√] BBR 配置完成${RESET}"
}

enable_swap() {
    echo -e "${CYAN}>>> 开启 Swap 交换文件${RESET}"
    
    if [ -f "/swapfile" ]; then
        old_size=$(ls -lh /swapfile | awk '{print $5}')
        echo -e "${YELLOW}[!] 检测到旧 Swap 文件，大小: ${old_size}${RESET}"
        read -p "是否删除旧 Swap 文件? [Y/n]: " confirm
        case $confirm in
            [yY]|[yY][eE][sS]|"")
                echo -e "${CYAN}>>> 移除旧 Swap 文件...${RESET}"
                swapoff /swapfile 2>/dev/null
                sed -i '/\/swapfile/d' /etc/fstab
                rm -f /swapfile
                echo -e "${GREEN}[√] 旧 Swap 文件已移除${RESET}"
                ;;
            [nN]|[nN][oO])
                echo -e "${YELLOW}[!] 已取消操作，退出脚本${RESET}"
                return 1
                ;;
            *)
                echo -e "${RED}[!] 无效输入，退出脚本${RESET}"
                return 1
                ;;
        esac
    fi

    read -p "请输入 swap 大小 (MB): " size
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}[!] 输入错误，请输入数字${RESET}"
        return 1
    fi
    
    echo -e "${CYAN}>>> 创建新的 Swap 文件 (${size}MB)...${RESET}"
    dd if=/dev/zero of=/swapfile bs=1M count=$size status=progress
    chmod 600 /swapfile
    mkswap /swapfile && swapon /swapfile
    echo "/swapfile none swap sw 0 0" >> /etc/fstab
    sysctl -w vm.swappiness=10 >/dev/null
    echo -e "${GREEN}[√] Swap 已启用 (${size}MB)${RESET}"
    free -h | grep -E "Mem:|Swap:"
}

clean_kernels() {
    echo -e "${CYAN}>>> 扫描可清理内核...${RESET}"
    local oldkernels=$(dpkg --get-selections | grep linux | grep deinstall | awk '{print $1}')
    if [ -z "$oldkernels" ]; then
        echo -e "${YELLOW}[!] 未发现旧内核${RESET}"
    else
        echo "$oldkernels" | xargs apt purge -y
        echo -e "${GREEN}[√] 旧内核清理完成${RESET}"
    fi
}

install_xui() {
    install_deps "curl"
    echo -e "${CYAN}>>> 正在安装 X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
    echo -e "${GREEN}[√] 安装完成，可访问: http://<IP>:54321${RESET}"
}

install_3xui() {
    install_deps "curl"
    echo -e "${CYAN}>>> 正在安装 3X-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    echo -e "${GREEN}[√] 安装完成，可访问: http://<IP>:2053${RESET}"
}

stream_test() {
    install_deps "curl"
    temp=$(mktemp -d)
    echo -e "${CYAN}>>> 开始流媒体解锁测试...${RESET}"
    cd "$temp" && bash <(curl -Ls https://IP.Check.Place)
    cd - >/dev/null
    cleanup "$temp"
    echo -e "${GREEN}[√] 流媒体测试完成${RESET}"
}

net_test() {
    install_deps "curl"
    temp=$(mktemp -d)
    echo -e "${CYAN}>>> 开始网络质量测试...${RESET}"
    cd "$temp" && bash <(curl -Ls https://Check.Place) -N
    cd - >/dev/null
    cleanup "$temp"
    echo -e "${GREEN}[√] 网络质量测试完成${RESET}"
}

full_test() {
    install_deps "curl"
    temp=$(mktemp -d)
    echo -e "${CYAN}>>> 开始NodeQuality综合测试...${RESET}"
    cd "$temp" && bash <(curl -sL https://run.NodeQuality.com)
    cd - >/dev/null
    cleanup "$temp"
    echo -e "${GREEN}[√] NodeQuality综合测试完成${RESET}"
}

benchmark() {
    install_deps "curl"
    temp=$(mktemp -d)
    echo -e "${CYAN}>>> 开始服务器性能测试...${RESET}"
    cd "$temp" && curl -sL yabs.sh -o yabs.sh && chmod +x yabs.sh && bash yabs.sh
    cd - >/dev/null
    cleanup "$temp"
    echo -e "${GREEN}[√] 性能测试完成${RESET}"
}

install_docker() {
    install_deps "curl"
    echo -e "${CYAN}>>> 安装 Docker 环境...${RESET}"
    curl -fsSL https://get.docker.com | sh
    arch=$(uname -m)
    [ "$arch" = "aarch64" ] && arch="arm64" || arch="x86_64"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$arch" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}[√] Docker & Compose 安装完成${RESET}"
    docker --version
    docker-compose --version
}

system_cleanup() {
    echo -e "${BOLD}${CYAN}>>> 正在执行系统多方位清理...${RESET}"

    declare -A cleanup_dirs=(
        ["/tmp"]="临时目录"
        ["/var/tmp"]="临时系统缓存"
        ["/var/cache/apt/archives"]="APT 缓存"
        ["/var/lib/apt/lists/partial"]="APT 残留包"
        ["/var/crash"]="系统崩溃转储文件"
    )

    for dir in "${!cleanup_dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "${dir:?}"/* 2>/dev/null
            echo -e "${YELLOW}[→] 已清理 ${cleanup_dirs[$dir]}: $dir${RESET}"
        fi
    done

    for user_home in /home/*; do
        [ -d "$user_home" ] || continue
        [ -d "$user_home/.cache" ] && rm -rf "$user_home/.cache/*" 2>/dev/null
        [ -d "$user_home/.cache/thumbnails" ] && rm -rf "$user_home/.cache/thumbnails/*" 2>/dev/null
        [ -d "$user_home/Downloads" ] && rm -rf "$user_home/Downloads/*" 2>/dev/null
    done
    echo -e "${GREEN}[√] 用户缓存、缩略图、Downloads 清理完成${RESET}"

    journalctl --vacuum-time=1d >/dev/null 2>&1
    echo -e "${RED}[!] systemd 日志已清理 (仅保留1天内日志)${RESET}"

    find /var/log -type f \( -name "*.gz" -o -name "*.old" -o -name "*.log.*" \) -delete 2>/dev/null
    echo -e "${RED}[!] 旧日志文件清理完成${RESET}"

    echo -e "${BOLD}${CYAN}--------------------------------------------------${RESET}"
    echo -e "${BOLD}${GREEN}系统清理完成！${RESET}"
    df -h / | tail -1 | awk -v G="${GREEN}" -v R="${RESET}" '{printf "%s当前磁盘使用情况:%s\n  总空间: %s, 已用: %s, 可用: %s, 使用率: %s%s\n", G, R, $2, $3, $4, $5, R}'
    echo -e "${BOLD}${CYAN}--------------------------------------------------${RESET}"
}

gb5_test() {
    install_deps "curl"
    echo -e "${CYAN}>>> 开始 GB5 性能测试...${RESET}"
    curl -sL yabs.sh | bash -s -- -i5
    echo -e "${GREEN}[√] GB5 测试完成${RESET}"
}

nexttrace_test() {
    install_deps "curl"
    echo -e "${CYAN}>>> 安装并运行 NextTrace 路由跟踪...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/sjlleo/nexttrace/main/nt_install.sh)
    echo -e "${GREEN}[√] NextTrace 已执行${RESET}"
}

install_sui() {
    install_deps "curl"
    echo -e "${CYAN}>>> 安装 S-UI 面板...${RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)
    echo -e "${GREEN}[√] S-UI 安装完成${RESET}"
}

pd_dns_test() {
    install_deps "wget"
    echo -e "${CYAN}>>> PD DNS 延迟检测...${RESET}"
    bash <(wget -qO- https://raw.githubusercontent.com/Cd1s/network-latency-tester/main/latency.sh)
    echo -e "${GREEN}[√] PD DNS 测试完成${RESET}"
}

install_nezha_v0() {
    install_deps "curl"
    echo -e "${CYAN}>>> 安装 哪吒 V0 面板...${RESET}"
    curl -L https://raw.githubusercontent.com/Xun-X/nezha-v0/refs/heads/main/install.sh -o nezha-v0.sh
    chmod +x nezha-v0.sh
    ./nezha-v0.sh
    echo -e "${GREEN}[√] 哪吒 V0 安装完成${RESET}"
}

install_iperf3() {
    if command -v iperf3 &>/dev/null; then
        echo -e "${YELLOW}[!] iperf3 已安装，版本: $(iperf3 --version | head -1)${RESET}"
    else
        echo -e "${CYAN}>>> 安装 iperf3...${RESET}"
        apt-get install -y iperf3
        echo -e "${GREEN}[√] iperf3 安装完成${RESET}"
        iperf3 --version
    fi
}

# ---------- 19 DD成Debian12并设置密码 ----------
dd_debian12() {
    read -p "请输入目标密码 (默认: password): " user_pass
    user_pass=${user_pass:-password}
    echo -e "${CYAN}>>> 开始 DD 成 Debian12，并设置密码: ${user_pass}${RESET}"
    wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh'
    chmod a+x InstallNET.sh
    bash InstallNET.sh -debian 12 -pwd "$user_pass"
    echo -e "${GREEN}[√] Debian12 DD 并设置密码完成${RESET}"
}
# ---------- 20 自定义更改主机名 ----------
change_hostname() {
    echo -e "${CYAN}>>> 自定义更改主机名${RESET}"

    CURRENT_HOSTNAME=$(hostname)
    echo -e "当前主机名是: ${YELLOW}$CURRENT_HOSTNAME${RESET}"
    read -p "请输入新的主机名 (例如 my-server): " NEW_HOSTNAME

    if [ -z "$NEW_HOSTNAME" ]; then
        echo -e "${RED}[×] 主机名不能为空，操作已取消${RESET}"
        return
    fi

    echo -e "正在将主机名从 '${CURRENT_HOSTNAME}' 修改为 '${NEW_HOSTNAME}' ..."

    # 修改主机名
    hostnamectl set-hostname "$NEW_HOSTNAME"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[√] 系统主机名已设置${RESET}"
    else
        echo -e "${RED}[×] 设置主机名失败${RESET}"
        return
    fi

    # 更新 /etc/hosts
    if grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
        sed -i "s/\b$CURRENT_HOSTNAME\b/$NEW_HOSTNAME/g" /etc/hosts
        echo -e "${GREEN}[√] /etc/hosts 文件已更新${RESET}"
    else
        echo "127.0.1.1 $NEW_HOSTNAME" >> /etc/hosts
        echo -e "${GREEN}[√] 已将新主机名添加到 /etc/hosts${RESET}"
    fi

    FINAL_HOSTNAME=$(hostname)
    echo -e "----------------------------------------"
    echo -e "修改完成！当前主机名: ${YELLOW}$FINAL_HOSTNAME${RESET}"
    echo -e "----------------------------------------"
    echo "建议重启系统以确保所有服务识别新名称。"
    read -p "是否现在重启? (y/n): " REBOOT_CONFIRM
    [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]] && reboot
}

# ---------- 主循环 ----------
while true; do
    show_menu
    read -p "请输入选项编号: " choice
    case $choice in
        1) system_upgrade ;;
        2) enable_bbr ;;
        3) enable_swap ;;
        4) clean_kernels ;;
        5) install_xui ;;
        6) install_3xui ;;
        7) stream_test ;;
        8) net_test ;;
        9) full_test ;;
        10) benchmark ;;
        11) install_docker ;;
        12) system_cleanup ;;
        13) gb5_test ;;
        14) nexttrace_test ;;
        15) install_sui ;;
        16) pd_dns_test ;;
        17) install_nezha_v0 ;;
        18) install_iperf3 ;;
        19) dd_debian12 ;;
		20) change_hostname ;;
        0) echo -e "${GREEN}已退出脚本，再见！${RESET}"; exit 0 ;;
        *) echo -e "${RED}[×] 无效选项，请重新输入${RESET}"; sleep 1 ;;
    esac
    read -p "按 Enter 返回主菜单..."
done
