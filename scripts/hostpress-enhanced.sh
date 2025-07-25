#!/bin/bash
#
# hostpress-enhanced.sh - Enhanced script to generate optimized blocklists for different formats
#

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
MAX_HOSTS_PER_LINE=9
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# --- Output File Names ---
OUTPUT_UNCOMPRESSED="hosts-uncompressed.txt"
OUTPUT_COMPRESSED="hosts.txt"
OUTPUT_DNSMASQ="dnsmasq.conf"
OUTPUT_SMARTDNS="smartdns.conf"
OUTPUT_BIND="bind-rpz.conf"
OUTPUT_BLOCKY="blocky.txt"
OUTPUT_UNBOUND="unbound.conf"
OUTPUT_ADBLOCK="adblock.txt"
OUTPUT_UBLOCK="ublock.txt"

echo "INFO: Starting enhanced processing with format-specific optimization..."

# --- Function: Download and process DNS sources ---
process_dns_sources() {
    local output_file="$1"
    echo "INFO: Processing DNS-level sources..."
    
    if [ -f "lists/sources-dns.list" ]; then
        # Download DNS sources
        grep -vE '^\s*(#|$)' lists/sources-dns.list | while read -r url; do
            echo "INFO: Downloading DNS source: $url"
            curl -s -L "$url" >> "$output_file" 2>/dev/null || wget -q -O - "$url" >> "$output_file" 2>/dev/null || echo "WARNING: Failed to download $url"
        done
    fi
    
    # Add legacy sources.list for backward compatibility
    if [ -f "lists/sources.list" ]; then
        echo "INFO: Adding legacy sources for backward compatibility..."
        grep -vE '^\s*(#|$)' lists/sources.list | while read -r url; do
            echo "INFO: Downloading legacy source: $url"
            curl -s -L "$url" >> "$output_file" 2>/dev/null || wget -q -O - "$url" >> "$output_file" 2>/dev/null || echo "WARNING: Failed to download $url"
        done
    fi
}

# --- Function: Download and process AdBlock sources ---
process_adblock_sources() {
    local output_file="$1"
    echo "INFO: Processing AdBlock-specific sources..."
    
    if [ -f "lists/sources-adblock.list" ]; then
        grep -vE '^\s*(#|$)' lists/sources-adblock.list | while read -r url; do
            echo "INFO: Downloading AdBlock source: $url"
            curl -s -L "$url" >> "$output_file" 2>/dev/null || wget -q -O - "$url" >> "$output_file" 2>/dev/null || echo "WARNING: Failed to download $url"
        done
    fi
}

# --- Function: Process hosts format data ---
process_hosts_data() {
    local input_file="$1"
    local output_file="$2"
    
    echo "INFO: Processing hosts format data..."
    awk '
        !/^\s*(#|$)/ {
            ip = $1
            if ((index(ip, ".") || index(ip, ":")) && length(ip) < 46) {
                for (i = 2; i <= NF; i++) {
                    host = tolower($i)
                    if (substr(host, 1, 1) == "#") break
                    
                    # Exclude private/local domains
                    if (host ~ /^(localhost|localhost\.domain)$/ || host ~ /\.local$|\.lan$|\.internal$/) continue
                    
                    # Hostname validation
                    if (length(host) < 254 && host ~ /^[a-z0-9][a-z0-9.-]*[a-z0-9]$/) {
                        print ip, host
                    }
                }
            }
        }
    ' "$input_file" | sort -u > "$output_file"
}

# --- Function: Process AdBlock format data ---
process_adblock_data() {
    local input_file="$1"
    local output_file="$2"
    
    echo "INFO: Processing AdBlock format data..."
    awk '
        # Skip comments and empty lines
        /^\s*!/ || /^\s*$/ { next }
        
        # Process different AdBlock filter types
        {
            line = $0
            
            # Domain blocking rules (||domain.com^)
            if (match(line, /\|\|([^\/\^\*\$]+)\^/)) {
                domain = substr(line, RSTART+2, RLENGTH-3)
                if (length(domain) > 0 && domain !~ /localhost|\.local$|\.lan$/) {
                    print "||" tolower(domain) "^"
                }
            }
            # Element hiding rules - keep as is for adblockers
            else if (match(line, /^[^\/\*]*##/)) {
                print line
            }
            # URL blocking rules - keep as is
            else if (match(line, /^[\|\*]*https?:\/\//)) {
                print line
            }
            # Simple domain rules
            else if (match(line, /^([a-zA-Z0-9][a-zA-Z0-9\.-]*[a-zA-Z0-9])$/)) {
                domain = $0
                if (domain !~ /localhost|\.local$|\.lan$/) {
                    print "||" tolower(domain) "^"
                }
            }
        }
    ' "$input_file" | sort -u > "$output_file"
}

# --- Main Processing ---

# Process DNS sources
DNS_RAW="$TEMP_DIR/dns.raw"
touch "$DNS_RAW"
process_dns_sources "$DNS_RAW"

# Add custom domains to DNS sources
if [ -s "lists/custom.list" ]; then
    echo "INFO: Adding custom domains..."
    while IFS= read -r domain; do
        if [[ -n "$domain" && ! "$domain" =~ ^\s*# ]]; then
            echo "0.0.0.0 $domain" >> "$DNS_RAW"
        fi
    done < lists/custom.list
fi

# Apply whitelist to DNS sources
if [ -s "lists/custom-white.list" ]; then
    echo "INFO: Applying whitelist to DNS sources..."
    grep -v -f lists/custom-white.list "$DNS_RAW" > "$DNS_RAW.tmp" && mv "$DNS_RAW.tmp" "$DNS_RAW"
fi

# Process hosts format data
DNS_PROCESSED="$TEMP_DIR/dns.processed"
process_hosts_data "$DNS_RAW" "$DNS_PROCESSED"

# Generate DNS-based formats (hosts, dnsmasq, smartdns)
echo "INFO: Generating hosts formats..."

# Uncompressed hosts
cp "$DNS_PROCESSED" "$OUTPUT_UNCOMPRESSED"

# Compressed hosts
awk -v max_hosts="$MAX_HOSTS_PER_LINE" '
{
    if (current_ip != "" && ($1 != current_ip || host_count >= max_hosts)) {
        printf "%s", current_ip;
        for (j = 1; j <= host_count; j++) printf " %s", hosts[j];
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
        for (j = 1; j <= host_count; j++) printf " %s", hosts[j];
        printf "\n";
    }
}' "$DNS_PROCESSED" > "$OUTPUT_COMPRESSED"

# Dnsmasq format
awk '{print "address=/"$2"/"$1}' "$DNS_PROCESSED" > "$OUTPUT_DNSMASQ"

# SmartDNS format
awk '{print "address /"$2"/"$1}' "$DNS_PROCESSED" > "$OUTPUT_SMARTDNS"

# BIND RPZ (Response Policy Zones) format
echo "INFO: Generating BIND RPZ format..."
{
    echo "; BIND Response Policy Zone configuration"
    echo "; Generated by AdZeroList - $(date)"
    echo "; Usage: Add this zone to your BIND configuration"
    echo ";"
    echo "\$TTL 300"
    echo "@ IN SOA localhost. root.localhost. ("
    echo "    $(date +%Y%m%d%H) ; Serial"
    echo "    3600       ; Refresh"
    echo "    1800       ; Retry"
    echo "    604800     ; Expire"
    echo "    300 )      ; Minimum TTL"
    echo "@ IN NS localhost."
    echo ";"
    awk '{print $2 " CNAME ."}' "$DNS_PROCESSED"
} > "$OUTPUT_BIND"

# Blocky format (Domain Wildcard)
echo "INFO: Generating Blocky format..."
{
    echo "# Blocky blacklist configuration"
    echo "# Generated by AdZeroList - $(date)"
    echo "# Usage: Add domains to your blocky blacklists configuration"
    echo "#"
    awk '{print $2}' "$DNS_PROCESSED"
} > "$OUTPUT_BLOCKY"

# Unbound format
echo "INFO: Generating Unbound format..."
{
    echo "# Unbound configuration for ad blocking"
    echo "# Generated by AdZeroList - $(date)"
    echo "# Usage: Include this file in your unbound.conf"
    echo "#"
    awk '{print "local-zone: \"" $2 "\" static"}' "$DNS_PROCESSED"
} > "$OUTPUT_UNBOUND"

# Process AdBlock sources
ADBLOCK_RAW="$TEMP_DIR/adblock.raw"
touch "$ADBLOCK_RAW"
process_adblock_sources "$ADBLOCK_RAW"

# Add custom AdBlock filters
if [ -s "lists/custom-adblock.list" ]; then
    echo "INFO: Adding custom AdBlock filters..."
    grep -vE '^\s*(#|$)' lists/custom-adblock.list >> "$ADBLOCK_RAW"
fi

# Convert DNS domains to AdBlock format and merge
awk '{print "||"$2"^"}' "$DNS_PROCESSED" >> "$ADBLOCK_RAW"

# Process AdBlock data
ADBLOCK_PROCESSED="$TEMP_DIR/adblock.processed"
process_adblock_data "$ADBLOCK_RAW" "$ADBLOCK_PROCESSED"

# Generate AdBlock formats
echo "INFO: Generating AdBlock formats..."

# AdBlock Plus format
{
    echo "! Title: AdZeroList - AdBlock Format"
    echo "! Description: Automatically generated blocklist combining DNS and AdBlock sources"
    echo "! Homepage: https://github.com/eikarna/AdZeroList"
    echo "! Expires: 1 day"
    echo "! Version: $(date +%Y%m%d%H%M%S)"
    echo "!"
    cat "$ADBLOCK_PROCESSED"
} > "$OUTPUT_ADBLOCK"

# uBlock Origin format
{
    echo "! Title: AdZeroList - uBlock Origin Format"
    echo "! Description: Optimized blocklist for uBlock Origin combining multiple sources"
    echo "! Homepage: https://github.com/eikarna/AdZeroList"
    echo "! Expires: 1 day"
    echo "! Version: $(date +%Y%m%d%H%M%S)"
    echo "! License: https://github.com/eikarna/AdZeroList/blob/main/LICENSE"
    echo "!"
    cat "$ADBLOCK_PROCESSED"
} > "$OUTPUT_UBLOCK"

echo "INFO: Enhanced processing complete. All optimized formats generated."
echo "INFO: DNS formats use $(wc -l < "$DNS_PROCESSED") unique domains"
echo "INFO: AdBlock formats use $(wc -l < "$ADBLOCK_PROCESSED") unique rules"
echo "INFO: Generated formats:"
echo "  - hosts.txt (compressed)"
echo "  - hosts-uncompressed.txt"
echo "  - dnsmasq.conf"
echo "  - smartdns.conf"
echo "  - bind-rpz.conf"
echo "  - blocky.txt"
echo "  - unbound.conf"
echo "  - adblock.txt"
echo "  - ublock.txt"