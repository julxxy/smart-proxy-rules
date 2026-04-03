import subprocess

urls = {
    "reject-cn-ads": "https://fastly.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt",
    "reject-malware": "https://fastly.jsdelivr.net/gh/julxxy/smart-proxy-rules/reject/reject-urlhaus.txt",
    "reject-adservers": "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=plain&mimetype=plaintext", # 收益偏低, 90% 被 HaGeZi 覆盖，独有仅 334 条
    "reject-hagezi-pro": "https://fastly.jsdelivr.net/gh/hagezi/dns-blocklists@latest/domains/pro.txt",
    "reject-1hosts-lite": "https://badmojr.github.io/1Hosts/Lite/domains.txt",
}

# 下载所有列表
data = {}
for name, url in urls.items():
    r = subprocess.run(['curl', '-sL', url], capture_output=True, text=True)
    lines = r.stdout.strip().split('\n')
    # 兼容 yaml 格式（- "domain.com"）和纯域名格式
    domains = set()
    for l in lines:
        l = l.strip().lstrip('- ').strip('"').strip("'")
        if l and not l.startswith('#') and not l.startswith('payload'):
            domains.add(l)
    data[name] = domains
    print(f"{name}: {len(domains):,} 条")

hagezi = data["reject-hagezi-pro"]

# 所有列表与 HaGeZi Pro 比较
print("\n" + "=" * 70)
print("各列表与 reject-hagezi-pro 重叠分析")
print("=" * 70)
print(f"{'列表':<25} {'总条数':>10} {'重复':>10} {'重复率':>8} {'独有':>10} {'独有率':>8}")
print("-" * 70)

for name in ["reject-cn-ads", "reject-malware", "reject-adservers", "reject-1hosts-lite"]:
    s = data[name]
    overlap = s & hagezi
    unique = s - hagezi
    print(f"{name:<25} {len(s):>10,} {len(overlap):>10,} {len(overlap)/len(s)*100:>7.1f}% {len(unique):>10,} {len(unique)/len(s)*100:>7.1f}%")

# 1Hosts Lite 独有域名样例
print("\n" + "=" * 70)
print("reject-1hosts-lite 独有域名（HaGeZi 没有的）前 10 条样例：")
print("=" * 70)
unique_1hosts = data["reject-1hosts-lite"] - hagezi
for d in list(unique_1hosts)[:10]:
    print(f"  {d}")

# 合并去重统计
all_domains = set()
for k in data:
    all_domains |= data[k]
total_raw = sum(len(data[k]) for k in data)
print(f"\n{'=' * 70}")
print(f"五个列表原始总条数（含重复）: {total_raw:,}")
print(f"合并去重后实际条数:           {len(all_domains):,}")
print(f"节省（重复条数）:             {total_raw - len(all_domains):,} ({(total_raw - len(all_domains))/total_raw*100:.1f}%)")
