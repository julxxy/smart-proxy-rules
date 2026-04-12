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
#     - 需要设备能访问 cnd.jsdelivr.net（国内一般可用）
#     - 下载失败时会保留上次规则，不会清空
#     - 若文件顶部已有 ". /usr/share/openclash/log.sh" 则删除下一行，避免重复加载

. /usr/share/openclash/log.sh

UpdateAdsRule() {
  LOG_OUT "拉取秋风广告规则..."

  WaitForNetwork() {
    local RETRY=0
    until ping -c 1 -W 2 cnd.jsdelivr.net >/dev/null 2>&1; do
      RETRY=$((RETRY + 1))
      [ "$RETRY" -ge 15 ] && LOG_OUT "网络等待超时，尝试继续..." && return
      sleep 2
    done
  }
  WaitForNetwork

  # 检测 dnsmasq.d 目录
  local TARGET_DIR
  TARGET_DIR=$(find /tmp -maxdepth 1 -type d -name "dnsmasq.*.d" | head -n 1)
  [ -z "$TARGET_DIR" ] && TARGET_DIR="/tmp/dnsmasq.d"
  [ ! -d "$TARGET_DIR" ] && mkdir -p "$TARGET_DIR"

  # 下载规则，成功且非空才替换
  local TMP_FILE
  TMP_FILE=$(mktemp)
  if curl -sf --max-time 30 \
    "https://cnd.jsdelivr.net/gh/TG-Twilight/AWAvenue-Ads-Rule@main/Filters/AWAvenue-Ads-Rule-Dnsmasq.conf" \
    -o "$TMP_FILE" && [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$TARGET_DIR/awavenue-ads.conf"
    LOG_OUT "规则下载成功: $TARGET_DIR/awavenue-ads.conf, 共 $(wc -l < "$TARGET_DIR/awavenue-ads.conf") 条"
  else
    rm -f "$TMP_FILE"
    LOG_OUT "秋风广告规则拉取失败，保留旧规则"
    exit 1
  fi

  # 重载 dnsmasq
  if /etc/init.d/dnsmasq reload; then
    LOG_OUT "秋风广告规则加载完成"
  else
    LOG_OUT "dnsmasq reload 失败，请检查规则格式"
    exit 1
  fi
}
UpdateAdsRule

exit 0
