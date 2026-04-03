# 🌐 Shadowrocket & Clash & Surge Rules Collection

这里是我个人整理的一些常用代理规则文件，用于：

- Shadowrocket
- Clash / Clash Verge / Clash Meta
- Surge

## 📦 规则列表

| 名称          | 类型           | 说明                      |
|-------------|--------------|-------------------------|
| claude.conf | Shadowrocket | Anthropic Claude 相关域名代理 |
| openai.conf | Shadowrocket | ChatGPT / OpenAI 域名代理   |
| global.conf | Shadowrocket | 全局常见域名集合                |

## 📘 使用方法

### Shadowrocket

1. 打开 **配置 → 规则集 → 添加规则集**
2. 输入链接，例如：https://raw.githubusercontent.com/julxxy/smart-proxy-rules/main/default/claude
3. 保存并应用

### Clash

1. 在配置文件中添加：

```yaml
rule-providers:
  claude:
    type: http
    behavior: domain
    url: https://raw.githubusercontent.com/julxxy/smart-proxy-rules/main/default/claude
    interval: 86400
```

## 📘 软路由 OpenClash 广告拦截规则搭配指南（性能分析）

> ⚠️ OpenClash 首次启动后约 **15 分钟内**内存占用会明显偏高，这是正常现象——Clash 内核需要下载并解析所有远程规则文件，完成后内存会回落并保持稳定。
>
> 各位根据自己路由器的配置做取舍，配置高就 All-in，配置有限就按以下建议精简。

[→ 查看详细搭配方案](./OpenClash%20广告拦截规则搭配指南.md)
