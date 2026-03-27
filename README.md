# AdZeroList: Automated Hosts File Generator

[![Build Status](https://github.com/eikarna/AdZeroList/workflows/Build%20and%20Deploy%20Blocklists/badge.svg)](https://github.com/eikarna/AdZeroList/actions/workflows/unified-build.yml)
[![Latest Release](https://img.shields.io/github/v/release/eikarna/AdZeroList?label=latest%20release)](https://github.com/eikarna/AdZeroList/releases/latest)

Welcome to **AdZeroList**, This repository is your go-to solution for automatically generating clean, compressed, and deduplicated `hosts` files. Powered by GitHub Actions, our process ensures your `hosts` file is always up-to-date, providing you with a seamless ad-blocking experience.

## ✨ Features

-   **Automated & Always Fresh**: Our blocklists are automatically generated daily at 02:00 UTC via GitHub Actions, ensuring you always have the latest protection without any manual intervention.
-   **Production-Ready Sources**: Curated with the best source combinations - 1Hosts Pro, comprehensive AdBlock filters, and security-focused lists.
-   **Format-Optimized Sources**: Uses dedicated source lists optimized for each format - DNS-level sources for hosts/dnsmasq/smartdns/BIND/Blocky/Unbound, and specialized filter sources for adblocker formats.
-   **Multiple Format Support**: Generate blocklists in 9 different formats including traditional `hosts` files, DNS server configs, and adblocker formats.
-   **Custom Filter Support**: Add your own custom domains (DNS-level) and custom AdBlock filters (browser-level) for personalized blocking.
-   **Enhanced AdBlock Filters**: AdBlock formats combine both converted domain lists and native AdBlock filter rules for comprehensive protection.
-   **Highly Efficient**: We optimize `hosts` files by combining multiple host entries into a single line (1 IP for up to 8 domains), significantly reducing file size and improving performance.
-   **Deduplicated & Clean**: Say goodbye to redundant entries! Our process meticulously deduplicates all entries, providing you with a clean and efficient blocklist.
-   **Flexible Source Management**: Easily manage your sources by editing the appropriate source files. Add, remove, or temporarily disable sources with ease.
-   **Comprehensive Protection**: Blocks ads, trackers, malware, phishing, cryptomining, and annoying elements across all platforms.

## 🚀 Usage
## 🔗 Direct Download Links (Recommended)

**For better browser compatibility, use these direct links instead of GitHub releases:**

### Browser Adblockers
- **Brave Browser**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/adblock.txt`
- **uBlock Origin**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/ublock.txt`

### DNS Servers  
- **Hosts format**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/hosts.txt`
- **Hosts uncompressed**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/hosts-uncompressed.txt`
- **Dnsmasq**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/dnsmasq.conf`
- **SmartDNS**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/smartdns.conf`
- **BIND RPZ**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/bind-rpz.conf`
- **Blocky**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/blocky.yml`
- **Unbound**: `https://raw.githubusercontent.com/eikarna/AdZeroList/main/outputs/unbound.conf`

> **Note**: GitHub releases may have compatibility issues with some browsers/downloaders. The `raw.githubusercontent.com` links provide direct access without redirect issues.


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

1.  **Trigger**: Our GitHub Actions workflow is triggered daily at 02:00 UTC, or whenever there's a `push` to the `main` branch, ensuring continuous updates.
2.  **Download Sources**: All active (uncommented) URLs listed in `sources.list` are downloaded to gather the latest blocklist data.
3.  **Customization**: Domains specified in `custom.list` are seamlessly integrated into the blocklist.
4.  **Processing**: The `hostpress.sh` script takes over, cleaning, sorting, deduplicating, and compressing all entries for optimal performance.
5.  **Whitelisting**: Domains listed in `custom-white.list` are carefully removed from the processed `hosts` and adblock rules file, ensuring your essential services remain unaffected.
6.  **Release**: The final, optimized files in multiple formats (hosts, dnsmasq, smartdns, BIND RPZ, Blocky, Unbound, and adblocker formats) are uploaded as assets to a new GitHub release.
