#!/bin/bash

# 定义颜色以便输出更清晰
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. 检查是否为 Root 用户
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}错误: 请使用 root 权限或 sudo 运行此脚本。${NC}"
  exit 1
fi

# 2. 获取当前主机名
CURRENT_HOSTNAME=$(hostname)

# 3. 获取新主机名参数
if [ -n "$1" ]; then
    NEW_HOSTNAME="$1"
else
    echo -e "当前主机名是: ${GREEN}$CURRENT_HOSTNAME${NC}"
    read -p "请输入新的主机名 (例如 my-server): " NEW_HOSTNAME
fi

# 检查输入是否为空
if [ -z "$NEW_HOSTNAME" ]; then
    echo -e "${RED}错误: 主机名不能为空。${NC}"
    exit 1
fi

echo "正在将主机名从 '$CURRENT_HOSTNAME' 修改为 '$NEW_HOSTNAME' ..."

# 4. 使用 hostnamectl 修改主机名 (systemd 标准方式)
hostnamectl set-hostname "$NEW_HOSTNAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}√ 系统主机名已设置。${NC}"
else
    echo -e "${RED}X 设置主机名失败。${NC}"
    exit 1
fi

# 5. 修改 /etc/hosts 文件
# Debian 通常将主机名映射在 127.0.1.1 或 127.0.0.1
# 使用 sed 将旧主机名替换为新主机名
if grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
    sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
    echo -e "${GREEN}√ /etc/hosts 文件已更新。${NC}"
else
    # 如果在 hosts 文件里没找到旧主机名，则追加一行
    echo "127.0.1.1 $NEW_HOSTNAME" >> /etc/hosts
    echo -e "${GREEN}√ 已将新主机名添加到 /etc/hosts。${NC}"
fi

# 6. 验证结果
FINAL_HOSTNAME=$(hostname)
echo "----------------------------------------"
echo -e "修改完成！当前主机名: ${GREEN}$FINAL_HOSTNAME${NC}"
echo "----------------------------------------"
echo "注意: 建议重启系统以确保所有运行中的服务识别新名称。"
echo "是否现在重启? (y/n)"
read -r REBOOT_CONFIRM

if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    reboot
else
    echo "请稍后手动执行 'reboot'。"
fi
