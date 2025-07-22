# AdZeroList: Automated Hosts File Generator

This repository automatically generates clean, compressed, and deduplicated `hosts` files from various sources. This process is run daily by GitHub Actions to ensure the `hosts` file is always up-to-date.

## ✨ Features

- **Automated**: Runs daily, no manual intervention needed.
- **Efficient**: Combines multiple hosts into a single line (1 IP for 8 domains) to reduce file size.
- **Deduplicated**: Ensures no duplicate host entries.
- **Flexible**: Easy to add or change `hosts` sources by simply editing the `sources.list` file.
- **Customizable**: Easy to add custom domains (`custom.list`) or exclude them (`custom-white.list`).

## 🚀 Usage

The generated `hosts` file can be downloaded from the **[Releases](https://github.com/eikarna/autohosts/releases)** page of this repository.

Each release will be tagged with a build number and commit hash for tracking.

## 🔧 How It Works

1.  **Trigger**: GitHub Actions runs daily at 00:00 UTC, or whenever there is a `push` to the `main` branch.
2.  **Compilation**: The script compiles `hostpress.c` using `Makefile`.
3.  **Download**: All active (uncommented) URLs from `sources.list` are downloaded.
4.  **Customization**: All domains from `custom.list` are added to the blocklist.
5.  **Process**: The `hostpress` program is run to clean, sort, deduplicate, and compress all entries.
6.  **Whitelist**: Domains present in `custom-white.list` are removed from the processed hosts file.
7.  **Release**: The final `hosts` file is uploaded as an asset to a new release on GitHub.

## 💻 Customization

To modify the blocklist:

-   **Add/Change Sources**: Edit the `sources.list` file. Add or remove URLs (one per line). You can temporarily disable a source by commenting it out (`#`).
-   **Add Custom Blocked Domains**: Edit the `custom.list` file. Add domains you want to block (one per line).
-   **Exclude Domains (Whitelist)**: Edit the `custom-white.list` file. Add domains you do not want to block (one per line).

Your changes will automatically trigger a new build after you `push` to the `main` branch.

## 📜 Current Host Sources

This list is taken from `sources.list`:
- [StevenBlack/hosts](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts)
- [AdAway](https://adaway.org/hosts.txt)
- [badmojr/1Hosts (Lite)](https://raw.githubusercontent.com/badmojr/1Hosts/master/Lite/hosts.txt)
- [hagezi/dns-blocklists (Pro Compressed)](https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro-compressed.txt)
- [AdGuardDNS (unofficial)](https://raw.githubusercontent.com/r-a-y/mobile-hosts/master/AdguardDNS.txt)
- [GoodbyeAds](https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt)

---
*Created with the help of Gemini.*