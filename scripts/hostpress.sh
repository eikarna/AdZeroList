#!/bin/bash
#
# hostpress.sh - Script to filter, deduplicate, compress, and generate various hosts file formats.
#

set -e # Exit immediately if a command exits with a non-zero status.

# --- Input Validation ---
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <combined_input_file>"
    echo "The script will generate output files in the current directory."
    exit 1
fi

INPUT_FILE="$1"
MAX_HOSTS_PER_LINE=9 # Common standard, can be adjusted

# --- Output File Names ---
OUTPUT_UNCOMPRESSED="hosts-uncompressed.txt"
OUTPUT_COMPRESSED="hosts.txt"
OUTPUT_DNSMASQ="dnsmasq.conf"
OUTPUT_SMARTDNS="smartdns.conf"
OUTPUT_ADBLOCK="adblock.txt"
OUTPUT_UBLOCK="ublock.txt"

echo "INFO: Starting process with Bash script..."

# --- Stage 1: Parsing, Normalization, and Private Domain Exclusion ---
TEMP_NORMALIZED=$(mktemp)
echo "INFO: Parsing, normalizing, and excluding private domains..."
# Enhanced AWK logic:
# 1. Ignore comment or empty lines.
# 2. Simple IP validation.
# 3. For each host:
#    a. Perform domain name validation according to RFC.
#    b. **EXCLUDE** private domains (localhost, .local, .lan, etc.).
awk '
    !/^\s*(#|$)/ {
        ip = $1
        if ((index(ip, ".") || index(ip, ":")) && length(ip) < 46) {
            for (i = 2; i <= NF; i++) {
                host = tolower($i) # Convert to lowercase for consistency
                if (substr(host, 1, 1) == "#") {
                    break
                }
                
                # Exclusion for private/local domains
                if (host ~ /^(localhost|localhost\.domain)$/ || host ~ /\.local$|\.lan$|\.internal$/) {
                    # Print info to stderr to not interfere with main output
                    # print "INFO: Excluding private domain: " host > "/dev/stderr"
                    continue
                }

                # Hostname Validation (RFC 952/1123)
                if (length(host) < 254 && host ~ /^[a-z0-9][a-z0-9.-]*[a-z0-9]$/) {
                    print ip, host
                }
            }
        }
    }
' "$INPUT_FILE" > "$TEMP_NORMALIZED"

# --- Stage 2: Sort and Deduplicate ---
TEMP_UNIQUE=$(mktemp)
echo "INFO: Sorting and removing duplicates..."
sort -u "$TEMP_NORMALIZED" > "$TEMP_UNIQUE"
rm "$TEMP_NORMALIZED"

# --- Stage 3: Generate Various Output Formats ---

# 3a: Uncompressed Host File (one host per line)
echo "INFO: Generating uncompressed host file -> $OUTPUT_UNCOMPRESSED"
cp "$TEMP_UNIQUE" "$OUTPUT_UNCOMPRESSED"

# 3b: Dnsmasq Configuration File
echo "INFO: Generating Dnsmasq file -> $OUTPUT_DNSMASQ"
awk '{print "address=/"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_DNSMASQ"

# 3c: SmartDNS Configuration File
echo "INFO: Generating SmartDNS file -> $OUTPUT_SMARTDNS"
awk '{print "address /"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_SMARTDNS"

# 3d: Compressed Host File (multiple hosts per line)
echo "INFO: Compressing hosts -> $OUTPUT_COMPRESSED"
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

# 3e: AdBlock Plus/Brave/Generic Adblocker Format
echo "INFO: Generating AdBlock format -> $OUTPUT_ADBLOCK"
{
    echo "! Title: AdZeroList - AdBlock Format"
    echo "! Description: Automatically generated blocklist in AdBlock Plus format"
    echo "! Homepage: https://github.com/eikarna/AdZeroList"
    echo "! Expires: 1 day"
    echo "! Version: $(date +%Y%m%d%H%M%S)"
    echo "!"
    awk '{print "||"$2"^"}' "$TEMP_UNIQUE"
} > "$OUTPUT_ADBLOCK"

# 3f: uBlock Origin Format (same as AdBlock but with additional metadata)
echo "INFO: Generating uBlock Origin format -> $OUTPUT_UBLOCK"
{
    echo "! Title: AdZeroList - uBlock Origin Format"
    echo "! Description: Automatically generated blocklist optimized for uBlock Origin"
    echo "! Homepage: https://github.com/eikarna/AdZeroList"
    echo "! Expires: 1 day"
    echo "! Version: $(date +%Y%m%d%H%M%S)"
    echo "! License: https://github.com/eikarna/AdZeroList/blob/main/LICENSE"
    echo "!"
    awk '{print "||"$2"^"}' "$TEMP_UNIQUE"
} > "$OUTPUT_UBLOCK"

rm "$TEMP_UNIQUE"

echo "INFO: Process complete. All files have been generated."