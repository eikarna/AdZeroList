#!/bin/bash
#
# hostpress-enhanced.sh - Enhanced script for generating multiple blocklist formats
# Compatible with GitHub Actions and various bash environments
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LISTS_DIR="$PROJECT_ROOT/lists"
TEMP_DIR=$(mktemp -d)
MAX_HOSTS_PER_LINE=9

# Cleanup function
trap 'rm -rf "$TEMP_DIR"' EXIT

# Source lists
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

echo "🚀 Starting AdZeroList enhanced build process..."
echo "📁 Working directory: $SCRIPT_DIR"
echo "📁 Project root: $PROJECT_ROOT"

# Function to download with timeout and retry
safe_download() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local timeout_duration=15
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        echo "    Attempt $attempt/$max_attempts..."
        if timeout $timeout_duration curl -fsSL --connect-timeout 5 --max-time 10 --retry 1 "$url" >> "$output" 2>/dev/null; then
            return 0
        fi
        if [ $attempt -lt $max_attempts ]; then
            sleep 2
        fi
        attempt=$((attempt + 1))
    done
    return 1
}

# Function to process source lists
process_sources() {
    local source_file="$1"
    local output_file="$2"
    local source_type="$3"
    
    echo "DEBUG: Checking source file: $source_file"
    
    # Determine which source file to use
    if [ ! -f "$source_file" ]; then
        if [ "$source_type" = "DNS" ] && [ -f "$LEGACY_SOURCES" ]; then
            echo "⚠️  $source_type sources not found, using legacy sources..."
            source_file="$LEGACY_SOURCES"
        else
            echo "⚠️  No $source_type sources available, skipping..."
            return 0
        fi
    fi
    
    echo "📥 Processing $source_type sources from $(basename "$source_file")..."
    
    local success_count=0
    local total_count=0
    
    # Read URLs and download
    while IFS= read -r url || [ -n "$url" ]; do
        # Skip empty lines and comments
        case "$url" in
            ''|'#'*) continue ;;
        esac
        
        total_count=$((total_count + 1))
        echo "  📡 [$total_count] $url"
        
        if safe_download "$url" "$output_file"; then
            echo "    ✅ Success"
            success_count=$((success_count + 1))
        else
            echo "    ❌ Failed after retries"
        fi
    done < "$source_file"
    
    echo "  📊 Downloaded $success_count/$total_count sources successfully"
    return 0
}

# Initialize temporary files
TEMP_DNS="$TEMP_DIR/dns_raw.txt"
TEMP_ADBLOCK="$TEMP_DIR/adblock_raw.txt"
touch "$TEMP_DNS" "$TEMP_ADBLOCK"

# Process sources
echo ""
echo "DEBUG: About to process DNS sources..."
process_sources "$DNS_SOURCES" "$TEMP_DNS" "DNS"
echo ""
echo "DEBUG: About to process AdBlock sources..."
process_sources "$ADBLOCK_SOURCES" "$TEMP_ADBLOCK" "AdBlock"

# Add custom domains
if [ -f "$CUSTOM_DOMAINS" ]; then
    echo ""
    echo "📝 Adding custom domains..."
    while IFS= read -r domain || [ -n "$domain" ]; do
        case "$domain" in
            ''|'#'*) continue ;;
        esac
        echo "0.0.0.0 $domain" >> "$TEMP_DNS"
        echo "  ✅ Added: $domain"
    done < "$CUSTOM_DOMAINS"
fi

# Process and normalize DNS data
echo ""
echo "🔄 Processing and normalizing DNS data..."
TEMP_NORMALIZED="$TEMP_DIR/normalized.txt"

awk '
    !/^\s*(#|$|!)/ {
        ip = $1
        if ((index(ip, ".") || index(ip, ":")) && length(ip) < 46) {
            for (i = 2; i <= NF; i++) {
                host = tolower($i)
                if (substr(host, 1, 1) == "#") break
                
                # Skip private/local domains
                if (host ~ /^(localhost|localhost\.domain)$/ || host ~ /\.local$|\.lan$|\.internal$/) continue
                
                # Basic hostname validation
                if (length(host) < 254 && host ~ /^[a-z0-9][a-z0-9.-]*[a-z0-9]$/) {
                    print ip, host
                }
            }
        }
    }
' "$TEMP_DNS" > "$TEMP_NORMALIZED"

# Sort and deduplicate
TEMP_UNIQUE="$TEMP_DIR/unique.txt"
sort -u "$TEMP_NORMALIZED" > "$TEMP_UNIQUE"

# Apply whitelist
if [ -f "$CUSTOM_WHITE" ]; then
    echo "🤍 Applying whitelist..."
    TEMP_FILTERED="$TEMP_DIR/filtered.txt"
    if grep -vFf "$CUSTOM_WHITE" "$TEMP_UNIQUE" > "$TEMP_FILTERED" 2>/dev/null; then
        mv "$TEMP_FILTERED" "$TEMP_UNIQUE"
        echo "  ✅ Whitelist applied"
    else
        echo "  ⚠️  Whitelist application failed, continuing without"
    fi
fi

DOMAIN_COUNT=$(wc -l < "$TEMP_UNIQUE")
echo "📊 Total unique domains: $DOMAIN_COUNT"

# Generate DNS server formats
echo ""
echo "🏗️  Generating DNS server formats..."

# Hosts uncompressed
echo "  📄 Generating hosts-uncompressed.txt..."
cp "$TEMP_UNIQUE" "$OUTPUT_UNCOMPRESSED"

# Hosts compressed
echo "  📄 Generating hosts.txt (compressed)..."
awk -v max_hosts="$MAX_HOSTS_PER_LINE" '
{
    if (current_ip != "" && ($1 != current_ip || host_count >= max_hosts)) {
        printf "%s", current_ip;
        for (j = 1; j <= host_count; j++) {
            printf " %s", hosts[j];
        }
        printf "\n";
        host_count = 0;
        delete hosts;
    }
    current_ip = $1;
    hosts[++host_count] = $2;
}
END {
    if (host_count > 0) {
        printf "%s", current_ip;
        for (j = 1; j <= host_count; j++) {
            printf " %s", hosts[j];
        }
        printf "\n";
    }
}' "$TEMP_UNIQUE" > "$OUTPUT_COMPRESSED"

# Dnsmasq
echo "  📄 Generating dnsmasq.conf..."
awk '{print "address=/"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_DNSMASQ"

# SmartDNS
echo "  📄 Generating smartdns.conf..."
awk '{print "address /"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_SMARTDNS"

# BIND RPZ
echo "  📄 Generating bind-rpz.conf..."
{
    echo "; AdZeroList BIND RPZ Zone"
    echo "; Generated: $(date -u)"
    echo "; Total domains: $DOMAIN_COUNT"
    echo ""
    awk '{print $2" CNAME ."}' "$TEMP_UNIQUE"
} > "$OUTPUT_BIND"

# Blocky
echo "  📄 Generating blocky.yml..."
{
    echo "# AdZeroList Blocky Configuration"
    echo "# Generated: $(date -u)"
    echo "# Total domains: $DOMAIN_COUNT"
    echo ""
    echo "blocking:"
    echo "  blackLists:"
    echo "    ads:"
    awk '{print "      - "$2}' "$TEMP_UNIQUE"
} > "$OUTPUT_BLOCKY"

# Unbound
echo "  📄 Generating unbound.conf..."
{
    echo "# AdZeroList Unbound Configuration"
    echo "# Generated: $(date -u)"
    echo "# Total domains: $DOMAIN_COUNT"
    echo ""
    awk '{print "local-zone: \""$2"\" static"}' "$TEMP_UNIQUE"
} > "$OUTPUT_UNBOUND"

# Generate AdBlock formats
echo ""
echo "🏗️  Generating AdBlock formats..."

# Process AdBlock sources
TEMP_ADBLOCK_PROCESSED="$TEMP_DIR/adblock_processed.txt"

# Start with DNS domains converted to AdBlock format
awk '{print "||"$2"^"}' "$TEMP_UNIQUE" > "$TEMP_ADBLOCK_PROCESSED"

# Add existing AdBlock rules if available
if [ -f "$TEMP_ADBLOCK" ] && [ -s "$TEMP_ADBLOCK" ]; then
    echo "  📝 Processing existing AdBlock rules..."
    grep -E '^\|\|.*\^' "$TEMP_ADBLOCK" 2>/dev/null >> "$TEMP_ADBLOCK_PROCESSED" || true
fi

# Add custom AdBlock filters
if [ -f "$CUSTOM_ADBLOCK" ]; then
    echo "  📝 Adding custom AdBlock filters..."
    grep -v '^[[:space:]]*#' "$CUSTOM_ADBLOCK" 2>/dev/null >> "$TEMP_ADBLOCK_PROCESSED" || true
fi

# Sort and deduplicate AdBlock rules
sort -u "$TEMP_ADBLOCK_PROCESSED" -o "$TEMP_ADBLOCK_PROCESSED"

# Additional filter cleaning for uBlock Origin, because ABP doesnt support
grep -vE '(:has\(|:is\(|\#@|##|#\$|^\|\|.*\$|^\|\|.*\+\js\()' "$TEMP_ADBLOCK_PROCESSED" > "$TEMP_ADBLOCK_PROCESSED.tmp" || true
mv "$TEMP_ADBLOCK_PROCESSED.tmp" "$TEMP_ADBLOCK_PROCESSED"

ADBLOCK_COUNT=$(wc -l < "$TEMP_ADBLOCK_PROCESSED")

# AdBlock Plus/Brave format
echo "  📄 Generating adblock.txt..."
{
    echo "[Adblock Plus 2.0]"
    echo "! Title: AdZeroList - ABP"
    echo "! Description: Comprehensive blocklist for AdBlock Plus, Brave, and compatible adblockers"
    echo "! Homepage: https://github.com/eikarna/AdZeroList"
    echo "! Expires: 1 day"
    echo "! Version: $(date +%Y%m%d%H%M)"
    echo "! Entries: $ADBLOCK_COUNT"
    echo "! Maintainer: eikarna"
    echo "!"
    cat "$TEMP_ADBLOCK_PROCESSED"
} > "$OUTPUT_ADBLOCK"

# uBlock Origin format
echo "  📄 Generating ublock.txt..."
{
    echo "! Title: AdZeroList - uBlock"
    echo "! Description: Comprehensive blocklist optimized for uBlock Origin"
    echo "! Homepage: https://github.com/eikarna/AdZeroList"
    echo "! Expires: 1 day"
    echo "! Version: $(date +%Y%m%d%H%M)"
    echo "! License: https://github.com/eikarna/AdZeroList/blob/main/LICENSE"
    echo "! Total rules: $ADBLOCK_COUNT"
    echo "! Maintainer: eikarna"
    echo "!"
    cat "$TEMP_ADBLOCK_PROCESSED"
} > "$OUTPUT_UBLOCK"

# Final summary
echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📊 Final Statistics:"
echo "   • DNS domains processed: $DOMAIN_COUNT"
echo "   • AdBlock rules generated: $ADBLOCK_COUNT"
echo "   • Output formats: 9"
echo ""
echo "📁 Generated files:"
for file in "$OUTPUT_UNCOMPRESSED" "$OUTPUT_COMPRESSED" "$OUTPUT_DNSMASQ" "$OUTPUT_SMARTDNS" "$OUTPUT_BIND" "$OUTPUT_BLOCKY" "$OUTPUT_UNBOUND" "$OUTPUT_ADBLOCK" "$OUTPUT_UBLOCK"; do
    if [ -f "$file" ]; then
        size=$(wc -l < "$file")
        echo "   ✅ $file ($size lines)"
    else
        echo "   ❌ $file (failed to generate)"
    fi
done
echo ""
echo "🎯 Ready for deployment!"
