# AdZeroList: Automated Hosts File Generator

[![Build Status](https://github.com/eikarna/AdZeroList/workflows/Generate%20Compressed%20Hosts%20File/badge.svg)](https://github.com/eikarna/AdZeroList/actions?query=workflow%3A%22Generate+Compressed+Hosts+File%22)
[![Latest Release](https://img.shields.io/github/v/release/eikarna/AdZeroList?label=latest%20release)](https://github.com/eikarna/AdZeroList/releases/latest)

Welcome to **AdZeroList**! This repository is your go-to solution for automatically generating clean, compressed, and deduplicated `hosts` files. Powered by GitHub Actions, our process ensures your `hosts` file is always up-to-date, providing you with a seamless ad-blocking experience.

## ✨ Features

-   **Automated & Always Fresh**: Our `hosts` files are automatically generated daily via GitHub Actions, ensuring you always have the latest blocklist without any manual intervention.
-   **Multiple Format Support**: Generate blocklists in various formats including traditional `hosts` files, dnsmasq, smartdns, and adblocker formats (AdBlock Plus, uBlock Origin, Brave).
-   **Highly Efficient**: We optimize `hosts` files by combining multiple host entries into a single line (1 IP for up to 8 domains), significantly reducing file size and improving performance.
-   **Deduplicated & Clean**: Say goodbye to redundant entries! Our process meticulously deduplicates all host entries, providing you with a clean and efficient blocklist.
-   **Flexible Source Management**: Easily manage your `hosts` sources by simply editing the `sources.list` file. Add, remove, or temporarily disable sources with ease.
-   **Personalized Customization**: Tailor your ad-blocking experience. Add your own custom domains to block (`custom.list`) or whitelist domains you never want to block (`custom-white.list`).

## 🚀 Usage

Getting started with AdZeroList is simple! You can download the latest generated files directly from our **[Releases page](https://github.com/eikarna/AdZeroList/releases)**.

### Available Formats

AdZeroList generates blocklists in multiple formats to support different applications:

- **`hosts.txt`** - Traditional hosts file format (compressed, multiple domains per line)
- **`hosts-uncompressed.txt`** - Traditional hosts file format (one domain per line)
- **`dnsmasq.conf`** - Configuration file for dnsmasq DNS server
- **`smartdns.conf`** - Configuration file for SmartDNS
- **`adblock.txt`** - AdBlock Plus format (compatible with Brave, AdBlock Plus, and most browser extensions)
- **`ublock.txt`** - uBlock Origin optimized format (enhanced metadata for uBlock Origin)

### Browser Extension Usage

For browser-based ad blockers:
1. Download `adblock.txt` for general compatibility with AdBlock Plus, Brave, and similar extensions
2. Download `ublock.txt` for optimal performance with uBlock Origin
3. Add the downloaded file as a custom filter list in your adblocker settings

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
7.  **Release**: The final, optimized files in multiple formats (hosts, dnsmasq, smartdns, and adblocker formats) are uploaded as assets to a new GitHub release.

## 💻 Customization

Want to fine-tune your ad-blocking experience? Here's how:

-   **Add/Change Sources**: Modify the `sources.list` file. Simply add or remove URLs (one per line). You can temporarily disable a source by commenting it out with a `#`.
-   **Add Custom Blocked Domains**: Edit the `custom.list` file to add any domains you wish to block (one per line).
-   **Exclude Domains (Whitelist)**: Use the `custom-white.list` file to add domains you do *not* want to block (one per line).

Your changes will automatically trigger a new build after you `push` to the `main` branch, so you'll see your customizations in action quickly!

## 📜 Current Host Sources

This list is dynamically sourced from `sources.list`:
- [StevenBlack/hosts](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts)
- [AdAway](https://adaway.org/hosts.txt)
- [badmojr/1Hosts (Lite)](https://raw.githubusercontent.com/badmojr/1Hosts/master/Lite/hosts.txt)
- [hagezi/dns-blocklists (Pro Compressed)](https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro-compressed.txt)
- [AdGuardDNS (unofficial)](https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt)
- [GoodbyeAds](https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt)

---
*Created with the help of Gemini.*