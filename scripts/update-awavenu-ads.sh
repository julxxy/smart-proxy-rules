#!/bin/sh

SCRIPT_PATH="/root/update_awavenue_ads.sh"
CRON_FILE="/etc/crontabs/root"

# ─────────────────────────────────────────
#  工具函数
# ─────────────────────────────────────────
info() { echo "  ✓ $*"; }
warn() { echo "  ⚠ $*"; }
fail() {
	echo "  ✗ $*"
	exit 1
}
section() {
	echo ""
	echo "▶ $*"
}

echo "┌─────────────────────────────────────────┐"
echo "│   秋风广告规则定时更新脚本 — 部署向导    │"
echo "└─────────────────────────────────────────┘"

# ──────────────────────────────────────────
# 1. 动态生成脚本文件
# ──────────────────────────────────────────
section "生成更新脚本..."

cat <<'EOF' >"$SCRIPT_PATH"
#!/bin/sh

# =====================================================
# 脚本名称: 秋风广告规则定时更新脚本 (update_awavenue_ads.sh)
#
# 使用说明:
#   功能：定时拉取 AWAvenue-Ads-Rule，写入 dnsmasq.d 后重启 Dnsmasq 生效
#        同时写入 Trellix/McAfee 回传域名拦截规则
#   部署：独立于 OpenClash，由系统 Cron 调度
#   查看日志：logread | grep -i "AWAvenue-Ads"
# =====================================================

LOG_OUT() {
  local msg="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') [信息] $msg" >>/tmp/openclash.log
  logger -t "AWAvenue-Ads" "$msg"
}

WriteTrellixBlockRules() {
  local TARGET_DIR="$1"

  cat >"$TARGET_DIR/trellix-block.conf" <<'EOF'
# Trellix / McAfee Agent 回传域名拦截
# 阻止 masvc / macmnsvc / mfewc / mfehcs 向云端回传日志
address=/mcafee.com/0.0.0.0
address=/trellix.com/0.0.0.0
address=/nai.com/0.0.0.0
address=/update.nai.com/0.0.0.0
address=/download.mcafee.com/0.0.0.0
address=/agent.mcafee.com/0.0.0.0
address=/epo.mcafee.com/0.0.0.0
address=/mvision.mcafee.com/0.0.0.0
address=/mcafee-cloud.com/0.0.0.0
address=/trellix-cloud.com/0.0.0.0
EOF

  LOG_OUT "Trellix 拦截规则已写入: $TARGET_DIR/trellix-block.conf（共 $(wc -l <"$TARGET_DIR/trellix-block.conf") 行）"
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

  # 下载广告规则
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
    LOG_OUT "规则下载成功: 共 $(wc -l <"$TARGET_DIR/awavenue-ads.conf") 条 → $TARGET_DIR/awavenue-ads.conf，已备份至 $BACKUP_FILE"
  else
    rm -f "$TMP_FILE"
    if [ -s "$BACKUP_FILE" ]; then
      cp "$BACKUP_FILE" "$TARGET_DIR/awavenue-ads.conf"
      LOG_OUT "下载失败，已从备份还原旧规则（共 $(wc -l <"$TARGET_DIR/awavenue-ads.conf") 条）"
    else
      LOG_OUT "下载失败，且无备份可用，广告屏蔽规则未加载"
      return 1
    fi
  fi

  # 写入 Trellix 拦截规则（每次都刷新，确保生效）
  WriteTrellixBlockRules "$TARGET_DIR"

  LOG_OUT "正在重启 Dnsmasq 以加载新规则..."
  /etc/init.d/dnsmasq restart >/dev/null 2>&1
  LOG_OUT "Dnsmasq 重启完成，广告屏蔽规则 + Trellix 拦截规则已生效"
}

UpdateAdsRule
exit 0
EOF

[ $? -eq 0 ] && info "脚本已生成: $SCRIPT_PATH" || fail "脚本生成失败，请检查磁盘空间或权限"

# ──────────────────────────────────────────
# 2. 赋予执行权限
# ──────────────────────────────────────────
section "配置执行权限..."

chmod +x "$SCRIPT_PATH" && info "已赋予可执行权限: $SCRIPT_PATH" || fail "chmod 失败"

# ──────────────────────────────────────────
# 3. 注册定时任务（幂等）
# ──────────────────────────────────────────
section "注册定时任务..."

NEW_CRON="30 4 * * * $SCRIPT_PATH >/dev/null 2>&1"

if crontab -l 2>/dev/null | grep -qF "$SCRIPT_PATH"; then
	info "定时任务已存在，跳过"
else
	(
		crontab -l 2>/dev/null
		echo "$NEW_CRON"
	) | crontab -
	/etc/init.d/cron restart >/dev/null 2>&1
	info "定时任务已写入 (每日 04:30)"
fi

crontab -l

# 执行一遍
section "首次执行脚本以验证..."
if sh "$SCRIPT_PATH"; then
	info "脚本执行成功"
else
	warn "脚本执行失败，请检查日志: logread | grep -i AWAvenue-Ads"
fi

# ──────────────────────────────────────────
# 4. 部署完成摘要
# ──────────────────────────────────────────
echo ""
echo "┌─────────────────────────────────────────┐"
echo "│            🎉 部署完成                   │"
echo "├─────────────────────────────────────────┤"
echo "│  脚本路径  $SCRIPT_PATH"
echo "│  执行计划  每日 04:30 自动更新"
echo "│  日志查看  logread | grep -i AWAvenue-Ads"
echo "└─────────────────────────────────────────┘"
echo ""
echo "  ⚠  后续操作提示："
echo "  1. 前往 OpenClash → 自定义防火墙规则，清空旧代码并保存"
echo "  2. 立即手动测试:"
echo "       $SCRIPT_PATH"
echo "  3. 验证广告屏蔽是否生效:"
echo "       nslookup ad.cctv.com 127.0.0.1"
echo "     返回 0.0.0.0 即表示成功 ✓"
echo ""
