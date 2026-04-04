### OpenClash 广告拦截规则搭配指南

> 以下域名数量均为**实测下载解析数据**（2026-04），标注「估算」的数字为基于实测数据的推算值。

### 各规则内存占用估算

| 规则                     |       域名数        |    估算内存    | 说明                 |
|:-----------------------|:----------------:|:----------:|--------------------|
| reject-threat          |       个人维护       |   <1 MB    | classical 格式，条数少   |
| reject-malware         |       ~463       |   <1 MB    | URLhaus 实时恶意域名     |
| reject-cn-ads-awavenue |       ~903       |   <1 MB    | AWAvenue 秋风，人工精选   |
| reject-cn-ads-antiad   |     ~116,000     |   ~3 MB    | anti-AD，CN 广告主力    |
| reject-1hosts-lite     |     ~198,000     |   ~6 MB    | 1Hosts Lite，国际追踪为主 |
| reject-hagezi-pro      |     ~400,000     |   ~12 MB   | HaGeZi Pro，全球兜底    |
| **六个合计**               | **~57 万（去重后估算）** | **~22 MB** |                    |

> 💡 `Loyalsoldier/reject.txt`（`v2fly/category-ads-all`）已从所有方案中移除——其 CN 部分被 AWAvenue + anti-AD 全覆盖，国际部分被
> HaGeZi Pro 全覆盖，属于纯冗余。

---

### 1Hosts Lite 的定位

1Hosts Lite 与其他规则源的重叠情况（基于原始数据 + 实测推算）：

| 对比              |      重叠量      | 说明                    |
|-----------------|:-------------:|-----------------------|
| 与 HaGeZi Pro 重叠 | ~112,910（57%） | 超过一半已被 HaGeZi 覆盖      |
| 1Hosts Lite 独占  | ~85,000（43%）  | 不在 HaGeZi Pro 中的新增域名  |
| 在标准方案中的真实增量     |  ~50,000（估算）  | 去掉 anti-AD 已覆盖部分后的净增量 |

**结论：** 1Hosts Lite 的独特价值在于其 **43% 不与 HaGeZi 重叠的国际追踪/广告域名**——主要是欧美中小型广告联盟和追踪器。内存充裕时值得加入；内存紧张时
HaGeZi Pro 已覆盖其主体，可舍弃。

---

### 🔴 极简方案（内存 ≤ 64 MB）

**推荐搭配（1 个）：**

```yaml
rules:
  - RULE-SET,reject-cn-ads-awavenue,REJECT   # AWAvenue 秋风，~903 条，<1 MB
```

903 条精准覆盖国内最顽固广告域名，内存占用可忽略不计。

---

### 🟡 小内存路由器（128–512 MB）

**推荐搭配（3 个，~13 MB）：**

```yaml
rules:
  - RULE-SET,reject-malware,REJECT           # URLhaus 实时恶意域名，<1 MB
  - RULE-SET,reject-cn-ads-awavenue,REJECT   # AWAvenue 秋风，<1 MB
  - RULE-SET,reject-hagezi-pro,REJECT        # HaGeZi Pro，~12 MB
```

**取舍理由：**

- ✅ `reject-malware`：仅 463 条，几乎不占内存，实时威胁价值高，必留
- ✅ `reject-cn-ads-awavenue`：903 条精准无误杀，CN 广告命中率极高，必留
- ✅ `reject-hagezi-pro`：40 万条全球兜底，是核心，必留
- ❌ `reject-cn-ads-antiad`：11.6 万条占 ~3 MB，内存紧张时可舍——AWAvenue 补位 CN 精准广告，损失可控
- ❌ `reject-1hosts-lite`：57% 已被 HaGeZi 覆盖，内存紧张时优先级低于 anti-AD

---

### 🟢 标准方案（内存 ≥ 256 MB，推荐）

**推荐搭配（5 个，~16 MB）：**

```yaml
rule-providers:
  # 个人维护 - 威胁情报（诈骗、钓鱼、恶意软件等）
  reject-threat:
    type: http
    format: text
    behavior: classical
    url: "https://raw.githubusercontent.com/julxxy/smart-proxy-rules/main/reject/reject-threat.conf"
    path: ./ruleset/reject-threat.conf
    interval: 86400

  # 实时恶意软件/钓鱼域名（abuse.ch URLhaus）
  reject-malware:
    type: http
    format: text
    behavior: domain
    url: "https://fastly.jsdelivr.net/gh/julxxy/smart-proxy-rules/reject/reject-urlhaus.txt"
    path: ./ruleset/reject-malware.yaml
    interval: 86400

  # 秋风广告规则 (AWAvenue Ads) — CN 精准层
  reject-cn-ads-awavenue:
    type: http
    behavior: domain
    format: yaml
    url: "https://fastly.jsdelivr.net/gh/TG-Twilight/AWAvenue-Ads-Rule@main/Filters/AWAvenue-Ads-Rule-Clash.yaml"
    path: ./ruleset/awavenue-cn-ads.yaml
    interval: 86400

  # anti-AD — CN 广告主力层
  reject-cn-ads-antiad:
    type: http
    behavior: domain
    format: yaml
    url: "https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-clash.yaml"
    path: ./ruleset/anti-cn-ads.yaml
    interval: 86400

  # 全球广告/追踪/隐私威胁（HaGeZi Pro，40 万条）
  reject-hagezi-pro:
    type: http
    format: text
    behavior: domain
    url: "https://fastly.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/pro.txt"
    path: ./ruleset/reject-hagezi-pro.yaml
    interval: 86400

rules:
  - RULE-SET,reject-threat,REJECT             # 个人维护威胁情报
  - RULE-SET,reject-malware,REJECT            # 实时恶意域名（URLhaus）
  - RULE-SET,reject-cn-ads-awavenue,REJECT    # AWAvenue 秋风（CN 精准）
  - RULE-SET,reject-cn-ads-antiad,REJECT      # anti-AD（CN 主力）
  - RULE-SET,reject-hagezi-pro,REJECT         # HaGeZi Pro（全球兜底）
```

---

### 🔵 All-in 方案（内存 ≥ 1 GB）

在标准方案基础上加入 **1Hosts Lite**，净增约 5 万条国际追踪域名（+~6 MB）：

```yaml
  # 1Hosts Lite — 国际追踪/广告补充层（~19.8 万条，独占 ~8.5 万条）
  reject-1hosts-lite:
    type: http
    behavior: domain
    format: text
    url: "https://badmojr.github.io/1Hosts/Lite/domains.txt"
    path: ./ruleset/reject-1hosts-lite.txt
    interval: 86400
```

```yaml
rules:
  - RULE-SET,reject-threat,REJECT
  - RULE-SET,reject-malware,REJECT
  - RULE-SET,reject-cn-ads-awavenue,REJECT
  - RULE-SET,reject-cn-ads-antiad,REJECT
  - RULE-SET,reject-1hosts-lite,REJECT        # 1Hosts Lite（国际补充）
  - RULE-SET,reject-hagezi-pro,REJECT
```

> ⚠️ 1Hosts Lite 建议放在 HaGeZi Pro **之前**，让其独占的 ~8.5 万条优先命中，减少 HaGeZi 的遍历压力。

---

### 不推荐加入的规则

| 规则                        | 原因                                                 |
|---------------------------|----------------------------------------------------|
| `Loyalsoldier/reject.txt` | CN 部分被 AWAvenue + anti-AD 全覆盖，国际部分被 HaGeZi 全覆盖，纯冗余 |
| `AdRules (Cats-Team)`     | 独占域名以欧洲/拉美广告为主，已被 HaGeZi 覆盖，对国内用户无增益               |

---

### 总结

| 路由器内存      | 推荐组合                                         | 去重后域名数 |  估算内存  |
|:-----------|:---------------------------------------------|:------:|:------:|
| ≤ 64 MB    | AWAvenue                                     |  ~903  | <1 MB  |
| 128–512 MB | AWAvenue + URLhaus + HaGeZi                  | ~40 万  | ~13 MB |
| ≥ 256 MB   | 威胁情报 + URLhaus + AWAvenue + anti-AD + HaGeZi | ~52 万  | ~16 MB |
| ≥ 1 GB     | 全部（含 1Hosts Lite）                            | ~57 万  | ~22 MB |

> ⚠️ 若使用标准方案后频繁遇到国内 App / 网站访问异常，建议先移除 **anti-AD**，仅保留 AWAvenue + HaGeZi Pro 观察效果——anti-AD
> 误杀率在所有规则源中最高。
