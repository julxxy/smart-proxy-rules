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
2. 输入链接，例如：`https://raw.githubusercontent.com/julxxy/smart-proxy-rules/main/default/claude`
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

## ✨ 融合配置

```
clash
├── clash-fusion-android.yaml
├── clash-fusion-pro.yaml
└── clash-fusion.yaml
shadowrocket
└── shadowrocket-fusion.conf
surge
└── surge-fusion.conf
```

## 💡 软路由 OpenClash 广告拦截规则搭配指南（性能分析）

> ⚠️ OpenClash 首次启动后约 **15 分钟内**内存占用会明显偏高，这是正常现象——Clash 内核需要下载并解析所有远程规则文件，完成后内存会回落并保持稳定。
>
> 各位根据自己路由器的配置做取舍，配置高就 All-in，配置有限就按以下建议精简。

[→ 查看详细搭配方案](./OpenClash广告拦截规则搭配指南.md)

## 🛡️ 广告域名拦截策略

**拦截层（REJECT 栈）**: 个人规则 → 实时威胁 → CN精准 → CN广泛 → 全球兜底，精确优先、范围递增。



> 以下结论基于对三个主流规则源的**实测下载解析**（2026-04），数据真实可复现。

### 规则源实测数据

| 规则源                                                                 |   域名数量   | 维护方式       | 定位         |
|---------------------------------------------------------------------|:--------:|------------|------------|
| [AWAvenue 秋风广告规则](https://github.com/TG-Twilight/AWAvenue-Ads-Rule) |   ~903   | 纯人工审核      | CN 精准层，零误杀 |
| [anti-AD](https://github.com/privacy-protection-tools/anti-AD)      | ~116,000 | 机器多源合并     | CN 广告主力层   |
| [AdRules (Cats-Team)](https://github.com/Cats-Team/AdRules)         | ~185,000 | 多源合并 + 白名单 | 国际广告为主     |
| [HaGeZi Pro](https://github.com/hagezi/dns-blocklists)              | ~400,000 | 机器聚合       | 全球广告/追踪兜底  |

### 重叠率分析

- **anti-AD 有 80.4% 的域名被 AdRules 覆盖**，使用 HaGeZi Pro 后 AdRules 几乎无增量价值
- **AWAvenue 有 98.1% 的域名已被 anti-AD 收录**，但 AWAvenue 的价值在于精准无误杀，而非独占域名
- **AdRules 独占的 9.1 万条域名以 `.br`、`.de`、`.fr` 等欧洲/拉美广告域名为主**，对国内用户增益有限，且已被 HaGeZi Pro 全部覆盖
- **`Loyalsoldier/reject.txt`（即 `v2fly/category-ads-all`）完全被 AWAvenue + anti-AD + HaGeZi Pro 三层覆盖**，属于纯冗余，不建议加入

### 推荐搭配方案

按路由器性能从高到低：

#### 🟢 标准方案（推荐，内存 ≥ 256 MB）

| 层级 | 规则源         |    条数    | 作用            |
|:--:|-------------|:--------:|---------------|
| 1  | AWAvenue 秋风 |   ~903   | CN 广告精准拦截，零误杀 |
| 2  | anti-AD     | ~116,000 | CN 广告/追踪主力拦截  |
| 3  | HaGeZi Pro  | ~400,000 | 全球广告/追踪/恶意兜底  |

分工明确，CN + 全球双线覆盖，无冗余。

#### 🟡 精简方案（内存 128 MB）

| 层级 | 规则源         |    条数    | 作用        |
|:--:|-------------|:--------:|-----------|
| 1  | AWAvenue 秋风 |   ~903   | CN 精准核心广告 |
| 2  | HaGeZi Pro  | ~400,000 | 全球兜底      |

以不到 1,000 条换取最高精准度，误杀率接近零，覆盖率约 95%。

#### 🔴 极简方案（内存 ≤ 64 MB）

| 层级 | 规则源         |  条数  | 作用             |
|:--:|-------------|:----:|----------------|
| 1  | AWAvenue 秋风 | ~903 | 覆盖最顽固的 CN 广告域名 |

### 不推荐的组合

| 组合                   | 原因                                       |
|----------------------|------------------------------------------|
| anti-AD + AdRules    | anti-AD 有 80% 被 AdRules 覆盖，重叠 9.3 万条，纯冗余 |
| AdRules + HaGeZi Pro | AdRules 独占的国际域名已被 HaGeZi Pro 全覆盖，增益极低    |
| 任意组合 + `reject.txt`  | reject.txt 两头均被覆盖，删除无任何损失                |

### 误杀风险说明

| 规则源        | 误杀风险 | 常见症状                   |
|------------|:----:|------------------------|
| AWAvenue   | ✅ 极低 | 基本无                    |
| HaGeZi Pro | 🟡 低 | 偶发海外小众网站访问异常           |
| anti-AD    | ⚠️ 中 | 国内电商返利链接、部分 App 图片加载失败 |
| AdRules    | ⚠️ 中 | 同上，国内体验与 anti-AD 相近    |

> 💬 如频繁遇到国内 App / 网站访问异常，建议先移除 anti-AD，仅保留 **AWAvenue + HaGeZi Pro** 观察效果。
