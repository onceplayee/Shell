#!/bin/bash
# system-check.sh - 服务器巡检脚本（关键信息）
# 说明：
#   该脚本收集系统运行时间、内存、磁盘、顶级 CPU/内存进程、磁盘 I/O、网络流量、
#   当前登录用户数量及防火墙状态，结果保存在 /var/log 目录下。
# 注意：
#   需要部分命令（如 iostat）提前安装，命令执行出错会输出错误信息。

REPORT_FILE="/var/log/detailed_inspection_$(date +'%Y%m%d').log"

{
  echo "=============================================="
  echo "    Detailed Server Inspection Report"
  echo "    $(date)"
  echo "=============================================="
  echo

  # 1. 系统运行时间与负载
  echo "[系统运行时间与负载]"
  if uptime_output=$(uptime 2>/dev/null); then
    echo "$uptime_output"
  else
    echo "ERROR: 无法获取系统运行时间信息。"
  fi
  echo

  # 2. 内存使用情况
  echo "[内存使用情况]"
  if command -v free &>/dev/null; then
    free -h 2>/dev/null
  else
    echo "ERROR: free 命令不存在。"
  fi
  echo

  # 3. 磁盘使用情况（显示 /dev 开头的分区）
  echo "[磁盘使用情况]"
  if command -v df &>/dev/null; then
    df -h 2>/dev/null | grep '^/dev/'
  else
    echo "ERROR: df 命令不存在。"
  fi
  echo

  # 4. CPU 占用最高的进程
  echo "[CPU 占用最高的进程]"
  if command -v ps &>/dev/null; then
    ps -eo pid,cmd,%cpu --sort=-%cpu 2>/dev/null | sed -n '2p'
  else
    echo "ERROR: ps 命令不存在。"
  fi
  echo

  # 5. 内存占用最高的进程
  echo "[内存占用最高的进程]"
  if command -v ps &>/dev/null; then
    ps -eo pid,cmd,%mem --sort=-%mem 2>/dev/null | sed -n '2p'
  else
    echo "ERROR: ps 命令不存在。"
  fi
  echo

  # 6. 磁盘 I/O 统计
  echo "[磁盘 I/O 统计]"
  if command -v iostat &>/dev/null; then
    # 采集 2 次统计数据
    iostat -dx 1 2 2>/dev/null
  else
    echo "ERROR: iostat 命令不存在，请安装 sysstat。"
  fi
  echo

  # 7. 网络流量统计
  echo "[网络流量统计]"
  if command -v ip &>/dev/null; then
    ip -s link 2>/dev/null
  elif command -v ifconfig &>/dev/null; then
    ifconfig -a 2>/dev/null
  else
    echo "ERROR: 无法获取网络流量统计（缺少 ip 或 ifconfig 命令）。"
  fi
  echo

  # 8. 当前登录的用户数量
  echo "[当前登录用户数量]"
  if command -v who &>/dev/null; then
    user_count=$(who 2>/dev/null | wc -l)
    echo "当前登录用户数: $user_count"
  else
    echo "ERROR: who 命令不存在。"
  fi
  echo

  # 9. 防火墙状态
  echo "[防火墙状态]"
  if command -v ufw &>/dev/null; then
    ufw status 2>/dev/null
  elif command -v iptables &>/dev/null; then
    iptables -L 2>/dev/null | head -n 10
  else
    echo "ERROR: 未找到防火墙管理工具（ufw 或 iptables）。"
  fi
  echo

  echo "=============================================="
} > "$REPORT_FILE" 2>&1

echo "巡检报告已生成：$REPORT_FILE"

