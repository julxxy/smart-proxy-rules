## OpenClash 广告拦截规则搭配指南

### 各规则内存占用估算

| 规则                 | 域名数          | 估算内存       |
|:-------------------|:-------------|:-----------|
| reject-cn-ads      | 174,525      | ~5 MB      |
| reject-malware     | 463          | <1 MB      |
| reject-adservers   | 3,519        | <1 MB      |
| reject-hagezi-pro  | 401,577      | ~12 MB     |
| reject-1hosts-lite | 198,089      | ~6 MB      |
| **五个合计**           | **~66万（去重）** | **~25 MB** |

***

### 🟡 小内存路由器（512MB）

OpenWrt + OpenClash 本身已占用约 150-250MB，规则加载要尽量精简。

**推荐搭配（3个）：**

```yaml
- RULE-SET,reject-cn-ads,REJECT
- RULE-SET,reject-malware,REJECT
- RULE-SET,reject-hagezi-pro,REJECT
```

**去掉的理由：**

- ❌ `reject-adservers`：90.5% 被 HaGeZi 覆盖，独有仅 334 条，性价比最低，**第一个去掉**
- ❌ `reject-1hosts-lite`：20万条占 6MB，与 HaGeZi 重叠 57%，内存紧张时可舍弃

**保留的理由：**

- ✅ `reject-cn-ads`：17万条，与 HaGeZi **零重叠**，专攻中文广告，必须保留
- ✅ `reject-malware`：仅 463 条几乎不占内存，实时恶意域名价值高
- ✅ `reject-hagezi-pro`：40万条覆盖最广，是核心拦截列表

***

### 🟢 大内存路由器（1GB 以上）

内存充裕，五个全上，覆盖最完整。

**推荐搭配（4个，去掉 yoyo）：**

```yaml
rule-providers:
  # 中文互联网广告/追踪域名（Loyalsoldier 维护）
  reject-cn-ads:
    type: http
    behavior: domain
    format: yaml
    url: "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt"
    path: ./ruleset/reject-cn-ads.yaml
    interval: 86400

  # 实时恶意软件/钓鱼域名（abuse.ch URLhaus）
  reject-malware:
    type: http
    behavior: domain
    url: "https://fastly.jsdelivr.net/gh/julxxy/smart-proxy-rules/reject/reject-urlhaus.txt"
    path: ./ruleset/reject-malware.yaml
    interval: 86400

  # 全球广告投放服务器（Peter Lowe yoyo）
  reject-adservers:
    type: http
    behavior: domain
    url: "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=plain&mimetype=plaintext"
    path: ./ruleset/reject-adservers.yaml
    interval: 86400

  # 全球广告/追踪/隐私威胁（HaGeZi Pro，40万条）
  reject-hagezi-pro:
    type: http
    behavior: domain
    url: "https://fastly.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/pro.txt"
    path: ./ruleset/reject-hagezi-pro.yaml
    interval: 86400

  # 全球广告/追踪补充（1Hosts Lite，20万条）
  reject-1hosts-lite:
    type: http
    behavior: domain
    url: "https://badmojr.github.io/1Hosts/Lite/domains.txt"
    path: ./ruleset/reject-1hosts-lite.yaml
    interval: 86400

rules:
  - RULE-SET,reject-cn-ads,REJECT                 # 中文互联网广告/追踪域名（Loyalsoldier 维护）
  - RULE-SET,reject-malware,REJECT                # 实时恶意软件/钓鱼域名（abuse.ch URLhaus）
  - RULE-SET,reject-adservers,REJECT              # 全球广告投放服务器（Peter Lowe yoyo）
  - RULE-SET,reject-hagezi-pro,REJECT             # 全球广告/追踪/隐私威胁（HaGeZi Pro，40万条）
  - RULE-SET,reject-1hosts-lite,REJECT            # 全球广告/追踪补充（1Hosts Lite，20万条）
```

`reject-adservers`（yoyo）90% 被 HaGeZi 覆盖，即使内存够用也意义不大，**建议去掉**。如果想要最完整覆盖，加上也没坏处，Clash
会自动去重。

***

### 总结

| 内存        | 推荐列表                               | 去重后域名数 | 估算内存   |
|:----------|:-----------------------------------|:-------|:-------|
| 512MB 路由器 | cn-ads + malware + hagezi          | ~58万   | ~18 MB |
| 1GB+ 路由器  | cn-ads + malware + hagezi + 1hosts | ~66万   | ~25 MB |

