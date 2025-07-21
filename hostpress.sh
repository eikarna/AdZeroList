#!/bin/bash
#
# hostpress.sh - Skrip untuk memfilter, menghilangkan duplikasi, mengkompres, dan menghasilkan berbagai format file hosts.
#

set -e # Keluar segera jika ada perintah yang gagal

# --- Validasi Input ---
if [ "$#" -ne 1 ]; then
    echo "Penggunaan: $0 <file_input_gabungan>"
    echo "Skrip akan menghasilkan file output di direktori saat ini."
    exit 1
fi

INPUT_FILE="$1"
MAX_HOSTS_PER_LINE=9 # Standar umum, bisa disesuaikan

# --- Nama File Output ---
OUTPUT_UNCOMPRESSED="hosts-uncompressed.txt"
OUTPUT_COMPRESSED="hosts.txt"
OUTPUT_DNSMASQ="dnsmasq.conf"
OUTPUT_SMARTDNS="smartdns.conf"

echo "INFO: Memulai proses dengan skrip Bash..."

# --- Tahap 1: Parsing, Normalisasi, dan Pengecualian Domain Privat ---
TEMP_NORMALIZED=$(mktemp)
echo "INFO: Mem-parsing, menormalkan, dan mengecualikan domain privat..."
# Logika AWK yang diperkuat:
# 1. Abaikan baris komentar atau kosong.
# 2. Validasi IP sederhana.
# 3. Untuk setiap host:
#    a. Lakukan validasi nama domain sesuai RFC.
#    b. **KECUALIKAN** domain privat (localhost, .local, .lan, dll).
awk '
    !/^\s*(#|$)/ {
        ip = $1
        if ((index(ip, ".") || index(ip, ":")) && length(ip) < 46) {
            for (i = 2; i <= NF; i++) {
                host = tolower($i) # Konversi ke huruf kecil untuk konsistensi
                if (substr(host, 1, 1) == "#") {
                    break
                }
                
                # Pengecualian untuk domain privat/lokal
                if (host ~ /^(localhost|localhost\.domain)$/ || host ~ /\.local$|\.lan$|\.internal$/) {
                    # Cetak info ke stderr agar tidak mengganggu output utama
                    # print "INFO: Mengecualikan domain privat: " host > "/dev/stderr"
                    continue
                }

                # Validasi Hostname (RFC 952/1123)
                if (length(host) < 254 && host ~ /^[a-z0-9][a-z0-9.-]*[a-z0-9]$/) {
                    print ip, host
                }
            }
        }
    }
' "$INPUT_FILE" > "$TEMP_NORMALIZED"

# --- Tahap 2: Sortir dan De-duplikasi ---
TEMP_UNIQUE=$(mktemp)
echo "INFO: Mengurutkan dan menghapus duplikat..."
sort -u "$TEMP_NORMALIZED" > "$TEMP_UNIQUE"
rm "$TEMP_NORMALIZED"

# --- Tahap 3: Hasilkan Berbagai Format Output ---

# 3a: File Host Tidak Terkompresi (satu host per baris)
echo "INFO: Menghasilkan file host tidak terkompresi -> $OUTPUT_UNCOMPRESSED"
cp "$TEMP_UNIQUE" "$OUTPUT_UNCOMPRESSED"

# 3b: File Konfigurasi Dnsmasq
echo "INFO: Menghasilkan file Dnsmasq -> $OUTPUT_DNSMASQ"
awk '{print "address=/"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_DNSMASQ"

# 3c: File Konfigurasi SmartDNS
echo "INFO: Menghasilkan file SmartDNS -> $OUTPUT_SMARTDNS"
awk '{print "address /"$2"/"$1}' "$TEMP_UNIQUE" > "$OUTPUT_SMARTDNS"

# 3d: File Host Terkompresi (beberapa host per baris)
echo "INFO: Mengkompresi host -> $OUTPUT_COMPRESSED"
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

rm "$TEMP_UNIQUE"

echo "INFO: Proses selesai. Semua file telah dihasilkan."

