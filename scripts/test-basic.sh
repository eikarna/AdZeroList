#!/bin/bash
#
# Quick test script to verify basic functionality
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LISTS_DIR="$PROJECT_ROOT/lists"
TEMP_DIR=$(mktemp -d)

trap 'rm -rf "$TEMP_DIR"' EXIT

echo "🧪 Testing basic functionality..."
echo "📁 Working directory: $SCRIPT_DIR"
echo "📁 Project root: $PROJECT_ROOT"

# Test file creation
TEMP_DNS="$TEMP_DIR/dns_test.txt"
touch "$TEMP_DNS"

# Add some test data
echo "0.0.0.0 example.com" > "$TEMP_DNS"
echo "0.0.0.0 test.com" >> "$TEMP_DNS"

# Add custom domains if file exists
if [[ -f "$LISTS_DIR/custom.list" ]]; then
    echo "📝 Adding custom domains..."
    while IFS= read -r domain || [[ -n "$domain" ]]; do
        [[ -z "$domain" || "$domain" =~ ^[[:space:]]*# ]] && continue
        echo "0.0.0.0 $domain" >> "$TEMP_DNS"
    done < "$LISTS_DIR/custom.list"
fi

# Process and generate basic hosts file
echo "🔄 Processing test data..."
TEMP_NORMALIZED="$TEMP_DIR/normalized.txt"
awk '
    !/^\s*(#|$|!)/ {
        ip = $1
        if ((index(ip, ".") || index(ip, ":")) && length(ip) < 46) {
            for (i = 2; i <= NF; i++) {
                host = tolower($i)
                if (substr(host, 1, 1) == "#") break
                
                if (host ~ /^(localhost|localhost\.domain)$/ || host ~ /\.local$|\.lan$|\.internal$/) continue
                
                if (length(host) < 254 && host ~ /^[a-z0-9][a-z0-9.-]*[a-z0-9]$/) {
                    print ip, host
                }
            }
        }
    }
' "$TEMP_DNS" > "$TEMP_NORMALIZED"

TEMP_UNIQUE="$TEMP_DIR/unique.txt"
sort -u "$TEMP_NORMALIZED" > "$TEMP_UNIQUE"

echo "📊 Total unique domains: $(wc -l < "$TEMP_UNIQUE")"

# Generate test outputs
echo "🏗️  Generating test outputs..."

# Basic hosts file
cp "$TEMP_UNIQUE" "hosts-test.txt"
echo "  ✅ hosts-test.txt ($(wc -l < "hosts-test.txt") lines)"

# Basic adblock format
{
    echo "! Title: AdZeroList - Test AdBlock Format"
    echo "! Version: $(date +%Y%m%d%H%M%S)"
    echo "!"
    awk '{print "||"$2"^"}' "$TEMP_UNIQUE"
} > "adblock-test.txt"
echo "  ✅ adblock-test.txt ($(wc -l < "adblock-test.txt") lines)"

echo ""
echo "✅ Test completed successfully!"
echo "📁 Generated test files:"
ls -la *-test.txt