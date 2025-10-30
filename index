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
    echo -e "${YELLOW}0.${RESET} 退出脚本"
    echo -e "${CYAN}==================================================${RESET}"
}

# ---------- 通用函数 ----------
install_deps() {
    for dep in "$@"; do
        if ! command -v "$dep" &>/dev/null; then
            echo -e "${BLUE}[→] 安装依赖: ${dep}${RESET}"
            apt install -y "$dep" >/dev/null 2>&1
        fi
    done
}
cleanup() {
    [ -d "$1" ] && rm -rf "$1" && echo -e "${GREEN}[√] 清理临时目录: $1${RESET}"
}

# ---------- 原功能函数（1–12） ----------
# …（保留原逻辑，省略这里，你已有完整代码）…

# ---------- 新增功能 ----------
gb5_test() {
    install_deps "curl"
    echo -e "${CYAN}>>> 开始 GB5 性能测试...${RESET}"
    curl -sL yabs.sh | bash -s -- -i5
    echo -e "${GREEN}[√] GB5 测试完成${RESET}"
}

nexttrace_test() {
    install_deps "curl"
    echo -e "${CYAN}>>> 安装并运行 NextTrace 路由测试...${RESET}"
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
    echo -e "${CYAN}>>> 开始 PD DNS 延迟检测...${RESET}"
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
        0) echo -e "${GREEN}已退出脚本，再见！${RESET}"; exit 0 ;;
        *) echo -e "${RED}[×] 无效选项，请重新输入${RESET}"; sleep 1 ;;
    esac
    read -p "按 Enter 返回主菜单..."
done
