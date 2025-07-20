#!/bin/bash
#
# hostpress.sh - Skrip untuk memfilter, menghilangkan duplikasi, dan mengkompres file hosts.
# Pengganti hostpress.c yang lebih portabel dan kuat.

set -e # Keluar segera jika ada perintah yang gagal

# --- Validasi Input ---
if [ "$#" -ne 2 ]; then
    echo "Penggunaan: $0 <file_input> <file_output>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"
MAX_HOSTS_PER_LINE=8

echo "INFO: Memulai proses dengan skrip Bash..."

# --- Tahap 1: Parsing dan Normalisasi yang Diperketat ---
# - Menggunakan awk untuk logika yang lebih kuat untuk memvalidasi setiap baris.
TEMP_NORMALIZED=$(mktemp)
echo "INFO: Mem-parsing dan menormalkan entri dengan validasi ketat..."
# Logika AWK yang diperkuat:
# 1. Hanya proses baris yang tidak diawali '#' atau kosong.
# 2. Pastikan kolom pertama ($1) adalah IP yang valid.
# 3. Untuk setiap host (kolom >= 2):
#    a. Lewati jika itu adalah komentar '#'.
#    b. Terapkan validasi nama domain yang ketat sesuai RFC.
awk '
    !/^\s*(#|$)/ {
        ip = $1
        # Validasi IP sederhana: harus mengandung setidaknya satu titik (untuk IPv4) atau titik dua (untuk IPv6)
        # dan tidak boleh lebih dari 45 karakter (panjang maks IPv6).
        if ((index(ip, ".") || index(ip, ":")) && length(ip) < 46) {
            for (i = 2; i <= NF; i++) {
                host = $i
                # Lewati komentar di tengah baris
                if (substr(host, 1, 1) == "#") {
                    break
                }
                # Validasi Hostname (RFC 952/1123):
                # - Hanya boleh berisi huruf, angka, dan tanda hubung.
                # - Tidak boleh diawali atau diakhiri dengan tanda hubung atau titik.
                # - Panjang total tidak lebih dari 253 karakter.
                if (length(host) < 254 && host ~ /^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$/) {
                    print ip, host
                }
            }
        }
    }
' "$INPUT_FILE" > "$TEMP_NORMALIZED"

# --- Tahap 2: Sortir dan De-duplikasi ---
# - Mengurutkan entri dan menghapus duplikat secara bersamaan.
TEMP_UNIQUE=$(mktemp)
echo "INFO: Mengurutkan dan menghapus duplikat..."
sort -u "$TEMP_NORMALIZED" > "$TEMP_UNIQUE"
rm "$TEMP_NORMALIZED" # Hapus file sementara pertama

# --- Tahap 3: Kompresi (Menggabungkan Host per IP) ---
echo "INFO: Mengkompresi host..."
awk -v max_hosts="$MAX_HOSTS_PER_LINE" '
{
    # Jika IP berubah dari baris sebelumnya atau buffer penuh
    if (current_ip != "" && ($1 != current_ip || host_count >= max_hosts)) {
        # Tulis baris yang sudah dikompres
        printf "%s", current_ip;
        for (j = 1; j <= host_count; j++) {
            printf " %s", hosts[j];
        }
        printf "\n";
        
        # Reset buffer
        host_count = 0;
        delete hosts;
    }
    
    # Simpan IP saat ini dan tambahkan host ke buffer
    current_ip = $1;
    hosts[++host_count] = $2;
}
END {
    # Jangan lupa tulis sisa host di buffer terakhir
    if (host_count > 0) {
        printf "%s", current_ip;
        for (j = 1; j <= host_count; j++) {
            printf " %s", hosts[j];
        }
        printf "\n";
    }
}' "$TEMP_UNIQUE" > "$OUTPUT_FILE"

rm "$TEMP_UNIQUE" # Hapus file sementara kedua

echo "INFO: Proses kompresi dengan Bash selesai. Hasil disimpan di $OUTPUT_FILE"
