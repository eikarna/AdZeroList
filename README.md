# AdZeroList: Automated Hosts File Generator

[![Build Status](https://github.com/eikarna/AdZeroList/workflows/Generate%20Compressed%20Hosts%20File/badge.svg)](https://github.com/eikarna/AdZeroList/actions?query=workflow%3A%22Generate+Compressed+Hosts+File%22)
[![Latest Release](https://img.shields.io/github/v/release/eikarna/AdZeroList?label=latest%20release)](https://github.com/eikarna/AdZeroList/releases/latest)

Welcome to **AdZeroList**! This repository is your go-to solution for automatically generating clean, compressed, and deduplicated `hosts` files. Powered by GitHub Actions, our process ensures your `hosts` file is always up-to-date, providing you with a seamless ad-blocking experience.

## ✨ Features

-   **Automated & Always Fresh**: Our blocklists are automatically generated every 3 hours via GitHub Actions, ensuring you always have the latest protection without any manual intervention.
-   **Production-Ready Sources**: Curated with the best source combinations - Hagezi Pro++, 1Hosts Pro, comprehensive AdBlock filters, and security-focused lists.
-   **Format-Optimized Sources**: Uses dedicated source lists optimized for each format - DNS-level sources for hosts/dnsmasq/smartdns/BIND/Blocky/Unbound, and specialized filter sources for adblocker formats.
-   **Multiple Format Support**: Generate blocklists in 9 different formats including traditional `hosts` files, DNS server configs, and adblocker formats.
-   **Custom Filter Support**: Add your own custom domains (DNS-level) and custom AdBlock filters (browser-level) for personalized blocking.
-   **Enhanced AdBlock Filters**: AdBlock formats combine both converted domain lists and native AdBlock filter rules for comprehensive protection.
-   **Highly Efficient**: We optimize `hosts` files by combining multiple host entries into a single line (1 IP for up to 8 domains), significantly reducing file size and improving performance.
-   **Deduplicated & Clean**: Say goodbye to redundant entries! Our process meticulously deduplicates all entries, providing you with a clean and efficient blocklist.
-   **Flexible Source Management**: Easily manage your sources by editing the appropriate source files. Add, remove, or temporarily disable sources with ease.
-   **Comprehensive Protection**: Blocks ads, trackers, malware, phishing, cryptomining, and annoying elements across all platforms.

## 🚀 Usage

Getting started with AdZeroList is simple! You can download the latest generated files directly from our **[Releases page](https://github.com/eikarna/AdZeroList/releases)**.

### Available Formats

AdZeroList generates blocklists in multiple formats to support different applications:

**DNS Server Formats:**
- **`hosts.txt`** - Traditional hosts file format (compressed, multiple domains per line)
- **`hosts-uncompressed.txt`** - Traditional hosts file format (one domain per line)
- **`dnsmasq.conf`** - Configuration file for dnsmasq DNS server
- **`smartdns.conf`** - Configuration file for SmartDNS
- **`bind-rpz.conf`** - BIND Response Policy Zones configuration
- **`blocky.txt`** - Blocky domain wildcard format
- **`unbound.conf`** - Unbound DNS server configuration

**Browser Extension Formats:**
- **`adblock.txt`** - AdBlock Plus format (compatible with Brave, AdBlock Plus, and most browser extensions)
- **`ublock.txt`** - uBlock Origin optimized format (enhanced metadata for uBlock Origin)

### Browser Extension Usage

For browser-based ad blockers:
1. Download `adblock.txt` for general compatibility with AdBlock Plus, Brave, and similar extensions
2. Download `ublock.txt` for optimal performance with uBlock Origin
3. Add the downloaded file as a custom filter list in your adblocker settings

### DNS Server Usage

For DNS-level blocking:

**BIND (Response Policy Zones):**
1. Download `bind-rpz.conf`
2. Add to your BIND configuration as a response policy zone
3. Configure the zone in your `named.conf`

**Blocky:**
1. Download `blocky.txt`
2. Add the file path to your blocky blacklists configuration
3. Restart blocky service

**Unbound:**
1. Download `unbound.conf`
2. Include the file in your main `unbound.conf` configuration
3. Restart unbound service

**dnsmasq:**
1. Download `dnsmasq.conf`
2. Include in your dnsmasq configuration directory
3. Restart dnsmasq service

**SmartDNS:**
1. Download `smartdns.conf`
2. Include in your SmartDNS configuration
3. Restart SmartDNS service

**Traditional hosts file:**
1. Download `hosts.txt` or `hosts-uncompressed.txt`
2. Append to your system's hosts file (`/etc/hosts` on Linux/macOS, `C:\Windows\System32\drivers\etc\hosts` on Windows)
3. No service restart required

Each release is tagged with a unique identifier and includes detailed information, such as the commit hash that triggered the build and the SHA256 hashes of the `hosts.txt` file, allowing you to verify its integrity and track changes.

### Verifying `hosts.txt` Integrity

Every release body includes the SHA256 hash of the `hosts.txt` file. You'll find two hashes:

-   **Old Hash**: The SHA256 hash of the `hosts.txt` from the *previous* successful build.
-   **New Hash**: The SHA256 hash of the `hosts.txt` generated in the *current* build.

This allows you to quickly see if the `hosts.txt` content has changed between releases. If the old and new hashes are different, it indicates that the `hosts.txt` file has been updated.

## 🔧 How It Works

1.  **Trigger**: Our GitHub Actions workflow is triggered daily at 00:00 UTC, or whenever there's a `push` to the `main` branch, ensuring continuous updates.
2.  **Compilation**: The `hostpress.c` program, the core of our processing, is compiled using `Makefile`.
3.  **Download Sources**: All active (uncommented) URLs listed in `sources.list` are downloaded to gather the latest blocklist data.
4.  **Customization**: Domains specified in `custom.list` are seamlessly integrated into the blocklist.
5.  **Processing**: The `hostpress` program takes over, cleaning, sorting, deduplicating, and compressing all entries for optimal performance.
6.  **Whitelisting**: Domains listed in `custom-white.list` are carefully removed from the processed `hosts` file, ensuring your essential services remain unaffected.
7.  **Release**: The final, optimized files in multiple formats (hosts, dnsmasq, smartdns, BIND RPZ, Blocky, Unbound, and adblocker formats) are uploaded as assets to a new GitHub release.

## 💻 Customization

Want to fine-tune your ad-blocking experience? Here's how:

### Source Management

The system uses production-ready, curated source lists for maximum effectiveness:

**DNS-Level Sources (`lists/sources-dns.list`):**
- **Hagezi Pro++** - Most comprehensive, highly maintained DNS blocklist
- **1Hosts Pro** - High-quality curated domain list  
- **StevenBlack's Unified** - Ads + malware + fakenews + gambling
- **OISD Big** - Comprehensive domain blocking
- **Security Sources** - Phishing Army, URLHaus, Malware Domain List
- **Privacy Sources** - NoTracking, AdAway, GoodbyeAds

**AdBlock Sources (`lists/sources-adblock.list`):**
- **Core Filters** - EasyList, EasyPrivacy (essential)
- **uBlock Origin** - Native uBlock filters, privacy, badware, resource abuse
- **AdGuard** - Base filter, tracking protection, mobile optimization
- **Annoyance** - Fanboy's annoyance, social blocking
- **Security** - Anti-phishing, anti-malware filters
- **Regional** - Optimized for multiple languages

**Legacy Sources (`lists/sources.list`):**
- Maintained for backward compatibility
- Automatically included in DNS formats

### Custom Filters

**Custom Domains (`lists/custom.list`):**
- Add domains for DNS-level blocking across all formats
- Applied to hosts, dnsmasq, smartdns, BIND, Blocky, Unbound

**Custom AdBlock Filters (`lists/custom-adblock.list`):**
- Add native AdBlock filter rules for browser extensions
- Supports all AdBlock Plus/uBlock Origin syntax
- Element hiding, URL blocking, advanced rules

**Whitelist (`lists/custom-white.list`):**
- Exclude domains from all generated blocklists
- Prevent blocking of essential services

Your changes will automatically trigger a new build after you `push` to the `main` branch, so you'll see your customizations in action quickly!

## 📜 Current Sources

### DNS-Level Sources (Optimized for hosts, dnsmasq, smartdns, BIND, Blocky, Unbound)
- [Hagezi DNS Blocklist Pro++](https://github.com/hagezi/dns-blocklists) - Most comprehensive, highly maintained
- [1Hosts Pro](https://github.com/badmojr/1Hosts) - High-quality curated list
- [StevenBlack's Unified hosts](https://github.com/StevenBlack/hosts) - Ads + malware + fakenews + gambling
- [OISD Big](https://oisd.nl/) - Comprehensive domain blocking
- [AdAway](https://adaway.org/) - Mobile-focused blocking
- [GoodbyeAds](https://github.com/jerryn70/GoodbyeAds) - Smart TV ads blocking
- [NoTracking](https://github.com/notracking/hosts-blocklists) - Privacy-focused
- [Phishing Army](https://phishing.army/) - Anti-phishing protection
- [Malware Domain List](https://www.malwaredomainlist.com/) - Security focused
- [URLHaus](https://urlhaus.abuse.ch/) - Malware URL blocking

### AdBlock Sources (Optimized for browser extensions)
- [EasyList](https://easylist.to/) - Core ad blocking (essential)
- [EasyPrivacy](https://easylist.to/) - Privacy protection and tracking prevention
- [uBlock Origin filters](https://github.com/uBlockOrigin/uAssets) - Native uBlock filters, privacy, badware, resource abuse
- [AdGuard filters](https://github.com/AdguardTeam/AdguardFilters) - Base filter, tracking protection, mobile optimization
- [Fanboy's lists](https://easylist.to/) - Annoyance and social blocking
- Anti-phishing and anti-malware filters
- Regional optimization filters

---
*Created with the help of Gemini.*