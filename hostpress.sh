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
awk '
# Lewati baris komentar atau baris kosong
!/^\s*#/ && NF > 1 {
    ip = $1
    # Validasi dasar untuk memastikan kolom pertama adalah IP.
    # Ini akan menyaring baris header yang tidak valid.
    if (ip ~ /^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ || ip ~ /^::1?$/) {
        # Ulangi untuk setiap kolom setelah IP
        for (i = 2; i <= NF; i++) {
            host = $i
            # Jika kita menemukan komentar di tengah baris, hentikan pemrosesan baris ini
            if (substr(host, 1, 1) == "#") {
                break
            }
            # Validasi nama host: tolak jika mengandung karakter yang tidak diizinkan.
            # Ini adalah perbaikan utama untuk bug yang dilaporkan.
            if (host !~ /["()\/]/) {
                print ip, host
            }
        }
    }
}' "$INPUT_FILE" > "$TEMP_NORMALIZED"

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
        for (i = 1; i <= host_count; i++) {
            printf " %s", hosts[i];
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
        for (i = 1; i <= host_count; i++) {
            printf " %s", hosts[i];
        }
        printf "\n";
    }
}' "$TEMP_UNIQUE" > "$OUTPUT_FILE"

rm "$TEMP_UNIQUE" # Hapus file sementara kedua

echo "INFO: Proses kompresi dengan Bash selesai. Hasil disimpan di $OUTPUT_FILE"