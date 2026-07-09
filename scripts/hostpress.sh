#!/bin/bash
#
# hostpress-optimized.sh - High-performance blocklist generator
# Optimized for speed, robustness, and large-scale string processing
#

set -euo pipefail

# --- Performance Configuration ---
# Use standard C locale for maximum sorting/processing speed
export LC_ALL=C
# Number of parallel download jobs (adjust based on bandwidth/CPU)
PARALLEL_JOBS=10

# --- Directory Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LISTS_DIR="$PROJECT_ROOT/lists"
TEMP_DIR=$(mktemp -d)

# Cleanup on exit
trap 'rm -rf "$TEMP_DIR"' EXIT

# --- File Definitions ---
DNS_SOURCES="$LISTS_DIR/sources-dns.list"
ADBLOCK_SOURCES="$LISTS_DIR/sources-adblock.list"
LEGACY_SOURCES="$LISTS_DIR/sources.list"
CUSTOM_DOMAINS="$LISTS_DIR/custom.list"
CUSTOM_ADBLOCK="$LISTS_DIR/custom-adblock.list"
CUSTOM_WHITE="$LISTS_DIR/custom-white.list"

# Output files
OUTPUT_UNCOMPRESSED="hosts-uncompressed.txt"
OUTPUT_COMPRESSED="hosts.txt"
OUTPUT_DNSMASQ="dnsmasq.conf"
OUTPUT_SMARTDNS="smartdns.conf"
OUTPUT_BIND="bind-rpz.conf"
OUTPUT_BLOCKY="blocky.yml"
OUTPUT_UNBOUND="unbound.conf"
OUTPUT_ADBLOCK="adblock.txt"
OUTPUT_UBLOCK="ublock.txt"

# Temp working files
TEMP_DNS="$TEMP_DIR/dns_raw.txt"
TEMP_ADBLOCK="$TEMP_DIR/adblock_raw.txt"
TEMP_NORMALIZED="$TEMP_DIR/normalized.txt"
TEMP_UNIQUE="$TEMP_DIR/unique.txt"

echo "🚀 Starting AdZeroList optimized build..."
echo "⚡ Using $PARALLEL_JOBS parallel connections for downloads."

# Initialize files
touch "$TEMP_DNS" "$TEMP_ADBLOCK"

# --- Fast Parallel Downloader Function ---
# Usage: process_file_list <source_file> <output_file> <type>
process_file_list() {
    local source_file="$1"
    local output_file="$2"
    local type="$3"

    if [[ ! -f "$source_file" ]]; then
        if [[ "$type" == "DNS" && -f "$LEGACY_SOURCES" ]]; then
            echo "⚠️  DNS sources missing, falling back to legacy list."
            source_file="$LEGACY_SOURCES"
        else
            return 0
        fi
    fi

    echo "📥 Downloading $type sources..."

    # Use xargs to run downloads in parallel
    # Piping the URL list directly to xargs
    grep -v '^[[:space:]]*#' "$source_file" | grep -v '^$' | xargs -P "$PARALLEL_JOBS" -I {} bash -c '
        url="{}"
        # Simple fast download with curl
        if curl -fsSL --connect-timeout 5 --max-time 15 --retry 1 "$url" >> "'"$output_file"'" 2>/dev/null; then
            # Success (silent)
            :
        else
            echo "    ❌ Failed: $url"
        fi
    '
    echo "    ✅ $type downloads complete."
}

# --- AdBlock to Hosts Converter Function ---
convert_adblock_to_hosts() {
    local adblock_file="$1"
    local output_file="$2"
    
    echo "🔄 Converting AdBlock format to hosts format..."
    
    # Ekstrak domain dari format ||domain^ dan ubah ke 0.0.0.0 domain
    sed 's/^\|\|//g; s/\^$//g' "$adblock_file" | \
        grep -v '^[[:space:]]*$' | \
        awk '{print "0.0.0.0 " $0}' > "$output_file"
    
    echo "✅ Conversion complete"
}

# --- 1. Download Phase ---
process_file_list "$DNS_SOURCES" "$TEMP_DNS.unp" "DNS"
process_file_list "$ADBLOCK_SOURCES" "$TEMP_ADBLOCK" "AdBlock"

# Add custom domains
if [[ -f "$CUSTOM_DOMAINS" ]]; then
    echo "📝 Adding custom domains..."
    # Pre-format custom domains to match hosts style for easier processing later
    sed 's/^/0.0.0.0 /' "$CUSTOM_DOMAINS" >> "$TEMP_DNS.unp"
fi

convert_adblock_to_hosts "$TEMP_DNS.unp" "$TEMP_DNS"

# --- 2. Processing Phase (DNS) ---
echo "🔄 Processing DNS data (Normalization & Deduplication)..."

# AWK Script: Normalizes, validates, and filters in one pass
# 1. Skips comments/empty lines
# 2. Extracts valid domains
# 3. Filters local/private domains
# 4. Converts to lowercase
awk '
    !/^\s*(#|$|!)/ {
        ip = $1
        # Check if it looks like an IP (v4 or v6)
        if (index(ip, ".") || index(ip, ":")) {
            for (i = 2; i <= NF; i++) {
                host = tolower($i)
                if (substr(host, 1, 1) == "#") break
                
                # Filters
                if (host ~ /^(localhost|localhost\.domain)$/) continue
                if (host ~ /\.local$|\.lan$|\.internal$/) continue
                
                # Basic valid hostname regex check
                if (length(host) < 254 && host ~ /^[a-z0-9][a-z0-9.-]*[a-z0-9]$/) {
                    # Output: IP domain (sorted format)
                    print ip, host
                }
            }
        }
    }
' "$TEMP_DNS" | sort -u > "$TEMP_NORMALIZED"

# --- 3. Whitelist Application (Highly Optimized) ---
if [[ -f "$CUSTOM_WHITE" ]]; then
    echo "🤍 Applying whitelist..."
    # Use AWK with hash map. It reads whitelist into memory, then filters stream.
    # Much faster than grep for large datasets.
    awk 'NR==FNR {exclude[$1]; next} !($2 in exclude)' "$CUSTOM_WHITE" "$TEMP_NORMALIZED" > "$TEMP_UNIQUE"
else
    mv "$TEMP_NORMALIZED" "$TEMP_UNIQUE"
fi

DOMAIN_COUNT=$(wc -l < "$TEMP_UNIQUE")
echo "📊 Total unique domains: $DOMAIN_COUNT"

# --- 4. Generate DNS Formats ---
echo "🏗️  Generating DNS server formats..."

# Hosts Uncompressed
ln "$TEMP_UNIQUE" "$OUTPUT_UNCOMPRESSED"

# Hosts Compressed (Multi-domain per line)
# AWK buffers lines to pack up to 9 domains per IP line
awk -v max=9 '
{
    if (curr_ip != "" && ($1 != curr_ip || count >= max)) {
        printf "%s", curr_ip;
        for (j = 1; j <= count; j++) printf " %s", hosts[j];
        printf "\n";
        count = 0;
        delete hosts;
    }
    curr_ip = $1;
    hosts[++count] = $2;
}
END {
    if (count > 0) {
        printf "%s", curr_ip;
        for (j = 1; j <= count; j++) printf " %s", hosts[j];
        printf "\n";
    }
}' "$TEMP_UNIQUE" > "$OUTPUT_COMPRESSED"

# Dnsmasq
awk '{print "address=/"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_DNSMASQ"

# SmartDNS
awk '{print "address /"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_SMARTDNS"

# BIND RPZ
{
    echo "; AdZeroList BIND RPZ Zone"
    echo "; Generated: $(date -u)"
    echo "; Domains: $DOMAIN_COUNT"
    awk '{print $2" CNAME ."}' "$TEMP_UNIQUE"
} > "$OUTPUT_BIND"

# Blocky
{
    echo "# AdZeroList Blocky Config"
    echo "blocking:"
    echo "  blackLists:"
    echo "    ads:"
    awk '{print "      - "$2}' "$TEMP_UNIQUE"
} > "$OUTPUT_BLOCKY"

# Unbound
awk '{print "local-zone: \""$2"\" static"}' "$TEMP_UNIQUE" > "$OUTPUT_UNBOUND"

# --- 5. Generate AdBlock Formats ---
echo "🏗️  Generating AdBlock formats..."

# Convert DNS to AdBlock ||domain^
awk '{print "||"$2"^"}' "$TEMP_UNIQUE" > "$TEMP_DIR/adblock_dns.txt"

# Extract rules from raw adblock sources (filter valid rules)
if [[ -f "$TEMP_ADBLOCK" ]] && [[ -s "$TEMP_ADBLOCK" ]]; then
    grep -E '^\|\|.*\^' "$TEMP_ADBLOCK" > "$TEMP_DIR/adblock_src.txt" || true
else
    touch "$TEMP_DIR/adblock_src.txt"
fi

# Combine, Sort, Deduplicate
cat "$TEMP_DIR/adblock_dns.txt" "$TEMP_DIR/adblock_src.txt" | \
    sort -u > "$TEMP_DIR/adblock_combined.txt"

# Add custom adblock filters
if [[ -f "$CUSTOM_ADBLOCK" ]]; then
    grep -v '^[[:space:]]*#' "$CUSTOM_ADBLOCK" >> "$TEMP_DIR/adblock_combined.txt"
    sort -u "$TEMP_DIR/adblock_combined.txt" -o "$TEMP_DIR/adblock_combined.txt"
fi

# Filter rules incompatible with ABP (Optimized for uBlock)
# Using grep -vE is faster than multiple grep passes
grep -vE '(:has\(|:is\(|\#@|##|#\$|^\|\|.*\$|^\|\|.*\+js\()' "$TEMP_DIR/adblock_combined.txt" > "$TEMP_DIR/adblock_final.txt" || true

ADBLOCK_COUNT=$(wc -l < "$TEMP_DIR/adblock_final.txt")

# AdBlock Plus/Brave
{
    echo "[Adblock Plus 2.0]"
    echo "! Title: AdZeroList - ABP"
    cat "$TEMP_DIR/adblock_final.txt"
} > "$OUTPUT_ADBLOCK"

# uBlock Origin
{
    echo "! Title: AdZeroList - uBlock"
    cat "$TEMP_DIR/adblock_final.txt"
} > "$OUTPUT_UBLOCK"

# --- Summary ---
echo ""
echo "✅ Build completed successfully!"
echo "📊 Stats:"
echo "   • DNS Domains: $DOMAIN_COUNT"
echo "   • AdBlock Rules: $ADBLOCK_COUNT"
echo "📁 Generated files:"
ls -lh "$OUTPUT_COMPRESSED" "$OUTPUT_ADBLOCK" | awk '{print "   " $9 " (" $5 ")"}'
echo "🎯 Ready for deployment."
