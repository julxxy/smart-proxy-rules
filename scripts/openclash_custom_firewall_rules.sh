#!/bin/sh

# 使用说明:
#   功能：在 OpenClash 启动时自动拉取秋风广告屏蔽规则（dnsmasq 格式）并注入
#   规则来源：https://github.com/TG-Twilight/AWAvenue-Ads-Rule
#
#   部署方法：
#     OpenClash 后台 → 插件设置 → 开发者选项 → 自定义防火墙规则
#     将本脚本内容粘贴进去保存即可
#
#   查看日志：
#     OpenClash 面板 → 运行日志 → 搜索"秋风"
#     或：logread | grep -i "秋风\|awavenue"
#
#   更新规则：
#     重启 OpenClash 即可自动重新拉取最新规则
#
#   注意事项：
#     - 下载失败时会从 /root/awavenue-ads.conf 还原上次规则
#     - 若文件顶部已有 ". /usr/share/openclash/log.sh" 则删除下一行，避免重复加载

. /usr/share/openclash/log.sh
. /lib/functions.sh

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

  # 下载规则（实际尝试次数为 MAX_RETRY+1）
  local MAX_RETRY=3
  local SLEEP_SECONDS=5
  local TMP_FILE
  TMP_FILE=$(mktemp)
  trap 'rm -f "$TMP_FILE"' RETURN
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
    LOG_OUT "规则下载成功: $TARGET_DIR/awavenue-ads.conf，共 $(wc -l <"$TARGET_DIR/awavenue-ads.conf") 条，已备份至 $BACKUP_FILE"
  else
    # TMP_FILE 由 trap 清理，无需手动 rm
    if [ -s "$BACKUP_FILE" ]; then
      cp "$BACKUP_FILE" "$TARGET_DIR/awavenue-ads.conf"
      LOG_OUT "下载失败，已从备份还原旧规则: $BACKUP_FILE（共 $(wc -l <"$TARGET_DIR/awavenue-ads.conf") 条）"
    else
      LOG_OUT "下载失败，且无备份可用，广告屏蔽规则未加载"
      return 1
    fi
  fi

  # 重载 dnsmasq
  if /etc/init.d/dnsmasq reload; then
    LOG_OUT "秋风广告规则加载完成"
  else
    LOG_OUT "dnsmasq reload 失败，请检查规则格式"
    return 1
  fi
}
UpdateAdsRule

exit 0
