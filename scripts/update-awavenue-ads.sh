#!/bin/sh

SCRIPT_PATH="/root/update-awavenue-ads.sh"
CRON_FILE="/etc/crontabs/root"

echo "====================================================="
echo "  开始部署 秋风广告规则定时更新脚本"
echo "====================================================="

# ==========================================
# 1. 动态生成脚本文件
# ==========================================
cat <<'EOF' >"$SCRIPT_PATH"
#!/bin/sh

# =====================================================
# 脚本名称: 秋风广告规则定时更新脚本 (update-awavenue-ads.sh)
#
# 使用说明:
#   功能：定时拉取 AWAvenue-Ads-Rule，写入 dnsmasq.d 后重启 Dnsmasq 生效
#   部署：独立于 OpenClash，由系统 Cron 调度
#   查看日志：logread | grep -i "AWAvenue-Ads"
# =====================================================

LOG_OUT() {
  local msg="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [信息] $msg" >>/tmp/openclash.log
  logger -t "AWAvenue-Ads" "$msg"
}

UpdateAdsRule() {
  LOG_OUT "拉取秋风广告规则..."

  local JSDELIVR_HOST="testingcf.jsdelivr.net"
  local BACKUP_FILE="/root/awavenue-ads.conf"

  # 等待网络就绪
  local RETRY=0
  until ping -c 1 -W 2 "$JSDELIVR_HOST" >/dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    [ "$RETRY" -ge 20 ] && LOG_OUT "网络等待超时，尝试继续..." && break
    sleep 3
  done

  # 检测 dnsmasq.d 目录
  local TARGET_DIR
  TARGET_DIR=$(find /tmp -maxdepth 1 -type d -name "dnsmasq.*.d" | head -n 1)
  [ -z "$TARGET_DIR" ] && TARGET_DIR="/tmp/dnsmasq.d"
  [ ! -d "$TARGET_DIR" ] && mkdir -p "$TARGET_DIR"

  # 下载规则
  local MAX_RETRY=3
  local SLEEP_SECONDS=5
  local TMP_FILE
  TMP_FILE=$(mktemp)

  RETRY=0
  until curl -sf --max-time 30 \
    "https://$JSDELIVR_HOST/gh/TG-Twilight/AWAvenue-Ads-Rule@main/Filters/AWAvenue-Ads-Rule-Dnsmasq.conf" \
    -o "$TMP_FILE" && [ -s "$TMP_FILE" ]; do
    RETRY=$((RETRY + 1))
    [ "$RETRY" -ge "$MAX_RETRY" ] && break
    LOG_OUT "下载失败，${SLEEP_SECONDS}秒后重试($RETRY/$MAX_RETRY)..."
    sleep "$SLEEP_SECONDS"
  done

  if [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$TARGET_DIR/awavenue-ads.conf"
    cp "$TARGET_DIR/awavenue-ads.conf" "$BACKUP_FILE"
    LOG_OUT "规则 $TARGET_DIR/awavenue-ads.conf 下载成功: 共 $(wc -l <"$TARGET_DIR/awavenue-ads.conf") 条，已备份至 $BACKUP_FILE"
  else
    rm -f "$TMP_FILE"
    if [ -s "$BACKUP_FILE" ]; then
      cp "$BACKUP_FILE" "$TARGET_DIR/awavenue-ads.conf"
      LOG_OUT "下载失败，已从备份还原旧规则: $BACKUP_FILE（共 $(wc -l <"$TARGET_DIR/awavenue-ads.conf") 条）"
    else
      LOG_OUT "下载失败，且无备份可用，广告屏蔽规则未加载"
      return 1
    fi
  fi

  # 规则就绪后，重启 Dnsmasq 使 conf-dir 中的新规则完整加载
  LOG_OUT "正在重启 Dnsmasq 以加载新规则..."
  /etc/init.d/dnsmasq restart >/dev/null 2>&1
  LOG_OUT "Dnsmasq 重启完成，广告屏蔽规则已生效"
}

UpdateAdsRule
exit 0
EOF

echo "✓ 脚本已生成至: $SCRIPT_PATH"

# ==========================================
# 2. 赋予执行权限
# ==========================================
chmod +x "$SCRIPT_PATH"
echo "✓ 权限已配置完毕"

# ==========================================
# 3. 添加定时任务 (幂等处理)
# ==========================================
mkdir -p /etc/crontabs
[ ! -f "$CRON_FILE" ] && touch "$CRON_FILE"

# 删除旧任务
sed -i '/update-awavenue-ads\.sh/d' "$CRON_FILE"

# 确保文件末尾有换行符
[ -n "$(tail -c 1 "$CRON_FILE")" ] && echo "" >>"$CRON_FILE"

# 写入新任务 (每天凌晨 4:30 自动执行)
echo "30 4 * * * $SCRIPT_PATH >/dev/null 2>&1" >>"$CRON_FILE"

# 重启 cron
if /etc/init.d/cron restart; then
  echo "✓ 定时任务已添加，当前计划任务列表 ($CRON_FILE):"
  grep "update-awavenue-ads.sh" "$CRON_FILE"
fi

# ==========================================
# 4. 立即触发执行提示
# ==========================================
echo "====================================================="
echo "🎉 部署全部完成！"
echo "⚠️  最后的操作确认："
echo "   1. 请务必前往 OpenClash [自定义防火墙规则] 中清空你之前贴的旧代码并保存！"
echo "   2. 清空完成后，复制并运行下方命令可立即测试完整流程："
echo "      /root/update-awavenue-ads.sh"
echo "   3. 验证拦截是否生效："
echo "      nslookup ad.cctv.com 127.0.0.1  # 返回 0.0.0.0 即成功"
echo "====================================================="
