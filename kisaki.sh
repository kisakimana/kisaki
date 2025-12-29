#!/bin/bash
#=========================================================
#                 VPS SYSTEM MANAGER PRO
#                 版本：v1.6 (Green Vertical Pro)
#                 作者：kisaki
#                 更新：2025.12.2
#=========================================================

# ---------- 颜色定义 ----------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
WHITE="\033[37m"
BOLD="\033[1m"
RESET="\033[0m"

# ---------- 权限检测 ----------
[[ "$(id -u)" != "0" ]] && echo -e "${RED}✘ 错误：请使用 root 权限运行${RESET}" && exit 1

# ---------- 纯净信息采集 ----------
get_sys_info() {
    # 强制只抓取 IP 数字
    IP=$(curl -s4m 2 ip.p3terx.com 2>/dev/null | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n1)
    [ -z "$IP" ] && IP="Network Error"
    
    OS=$(hostnamectl 2>/dev/null | grep "Operating System" | cut -d: -f2 | xargs)
    [ -z "$OS" ] && OS=$(cat /etc/issue | head -n1 | awk '{print $1,$2}')
    OS=${OS:0:35}

    KERNEL=$(uname -r | cut -d- -f1,2)
    
    MEM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
    MEM_USED=$(free -m | awk '/Mem:/{print $3}')
    MEM_PER=$((MEM_USED * 100 / MEM_TOTAL))
}

# ---------- 终极单列菜单 ----------
draw_menu() {
    get_sys_info
    clear
    local L="${CYAN}║${RESET}"
    local R="${CYAN}║${RESET}"
    local G="${GREEN}"
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
    printf "${L}${BOLD}${G} %-51s ${R}\n" "       VPS 系统管理工具 作者：kisaki"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"
    printf "${L}${G}  %-10s : %-37s ${R}\n" "SYSTEM" "$OS"
    printf "${L}${G}  %-10s : %-37s ${R}\n" "KERNEL" "$KERNEL"
    printf "${L}${G}  %-10s : %-37s ${R}\n" "IP ADDR" "$IP"
    printf "${L}${G}  %-10s : %-37s ${R}\n" "MEMORY" "$MEM_USED / $MEM_TOTAL MB ($MEM_PER%)"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"
    
    # 按照数字顺序排列的所有功能
    printf "${L}${G}  1.  💎 系统升级与清理                         ${R}\n"
    printf "${L}${G}  2.  🚀 开启 BBR 加速                          ${R}\n"
    printf "${L}${G}  3.  💾 开启 Swap 交换文件                     ${R}\n"
    printf "${L}${G}  4.  🧹 清理多余系统内核                       ${R}\n"
    printf "${L}${G}  5.  🛠️  安装 X-UI 面板                         ${R}\n"
    printf "${L}${G}  6.  🛠️  安装 3X-UI 面板                        ${R}\n"
    printf "${L}${G}  7.  🎬 流媒体解锁测试                         ${R}\n"
    printf "${L}${G}  8.  📡 网络质量测试                           ${R}\n"
    printf "${L}${G}  9.  👹 融合怪全面测试                         ${R}\n"
    printf "${L}${G}  10. 📊 服务器性能测试 (YABS)                  ${R}\n"
    printf "${L}${G}  11. 🐳 安装 Docker 环境                       ${R}\n"
    printf "${L}${G}  12. 🧼 深度系统瘦身清理                       ${R}\n"
    printf "${L}${G}  13. 🏎️  GB5 性能测试                           ${R}\n"
    printf "${L}${G}  14. 🛣️  NextTrace 路由跟踪                     ${R}\n"
    printf "${L}${G}  15. 🛠️  安装 S-UI 面板                         ${R}\n"
    printf "${L}${G}  16. 🔍 PD DNS 延迟检测                        ${R}\n"
    printf "${L}${G}  17. 🛰️  安装 哪吒监控 V0                       ${R}\n"
    printf "${L}${G}  18. 📶 安装 iperf3 工具                       ${R}\n"
    printf "${L}${G}  19. 🔥 ${RED}${BOLD}DD 重装 Debian 12 (慎用)${RESET}${G}              ${R}\n"
    printf "${L}${G}  20. 🏷️  自定义更改主机名                       ${R}\n"
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"
    printf "${L}${BOLD}${G}  00. 🚪 退出脚本并返回终端                     ${R}\n"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
}

# ---------- 任务执行器 ----------
execute() {
    echo -e "\n${GREEN}➔ 正在开始执行任务...${RESET}"
    echo -e "${CYAN}------------------------------------------------------${RESET}"
    eval $1
    echo -e "${CYAN}------------------------------------------------------${RESET}"
    echo -e "${GREEN}✔ 任务处理已完成！${RESET}"
    read -p "按 [Enter] 键返回主菜单..."
}

# ---------- 主循环 ----------
while true; do
    draw_menu
    read -p " 请输入数字编号 [0-20]: " choice
    case $choice in
        1|01) execute "apt update -y && apt upgrade -y && apt autoremove -y" ;;
        2|02) execute "sysctl -w net.core.default_qdisc=fq && sysctl -w net.ipv4.tcp_congestion_control=bbr && sysctl -p" ;;
        3|03) read -p "请输入Swap大小(MB): " s; execute "dd if=/dev/zero of=/swapfile bs=1M count=$s status=progress && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo '/swapfile none swap sw 0 0' >> /etc/fstab" ;;
        4|04) execute "apt purge \$(dpkg --get-selections | grep linux | grep deinstall | awk '{print \$1}') -y" ;;
        5|05) execute "bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)" ;;
        6|06) execute "bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)" ;;
        7|07) execute "bash <(curl -Ls https://IP.Check.Place)" ;;
        8|08) execute "bash <(curl -Ls https://Check.Place) -N" ;;
        9|09) execute "bash <(curl -sL https://run.NodeQuality.com)" ;;
        10) execute "curl -sL yabs.sh | bash" ;;
        11) execute "curl -fsSL https://get.docker.com | sh" ;;
        12) execute "journalctl --vacuum-time=1d && apt autoclean -y && apt autoremove -y" ;;
        13) execute "curl -sL yabs.sh | bash -s -- -i5" ;;
        14) execute "bash <(curl -Ls https://raw.githubusercontent.com/sjlleo/nexttrace/main/nt_install.sh)" ;;
        15) execute "bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)" ;;
        16) execute "bash <(curl -sL https://raw.githubusercontent.com/Cd1s/network-latency-tester/main/latency.sh)" ;;
        17) execute "curl -L https://raw.githubusercontent.com/Xun-X/nezha-v0/refs/heads/main/install.sh -o nezha-v0.sh && chmod +x nezha-v0.sh && ./nezha-v0.sh" ;;
        18) execute "apt install iperf3 -y" ;;
        19) # DD 逻辑
            echo -e "${RED}${BOLD}警告: 数据将清空！${RESET}"
            read -p "确定重装为 Debian 12 吗？(y/n): " confirm
            [[ $confirm == "y" ]] && bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh') -debian 12 -pwd password ;;
        20) read -p "请输入新主机名: " nh; hostnamectl set-hostname $nh; echo "修改成功" ;;
        0|00) echo -e "${GREEN}脚本已退出。${RESET}"; exit 0 ;;
        *) echo -e "${RED}✘ 无效输入，请输入正确的数字编号！${RESET}"; sleep 1 ;;
    esac
done
