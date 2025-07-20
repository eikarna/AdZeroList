#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_HOSTS_PER_LINE 8
#define MAX_LINE_LENGTH 4096
#define IP_ADDRESS_MAX_LENGTH 46 // Cukup untuk IPv6

// Struktur untuk menyimpan satu entri host (IP dan nama host)
typedef struct {
    char *ip;
    char *host;
} HostEntry;

// Fungsi pembanding untuk qsort. Mengurutkan berdasarkan IP, lalu berdasarkan host.
int compare_entries(const void *a, const void *b) {
    HostEntry *entryA = (HostEntry *)a;
    HostEntry *entryB = (HostEntry *)b;
    int ip_cmp = strcmp(entryA->ip, entryB->ip);
    if (ip_cmp != 0) {
        return ip_cmp;
    }
    return strcmp(entryA->host, entryB->host);
}

// Fungsi untuk membersihkan (trim) whitespace dari awal dan akhir string
char *trim_whitespace(char *str) {
    char *end;
    while (isspace((unsigned char)*str)) str++;
    if (*str == 0) return str;
    end = str + strlen(str) - 1;
    while (end > str && isspace((unsigned char)*end)) end--;
    end[1] = '\0';
    return str;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Penggunaan: %s <file_input> <file_output>\n", argv[0]);
        return 1;
    }

    FILE *infile = fopen(argv[1], "r");
    if (!infile) {
        perror("Error: Gagal membuka file input");
        return 1;
    }

    // Tahap 1: Baca semua host dari file input ke dalam memori
    HostEntry *entries = NULL;
    size_t entry_count = 0;
    size_t capacity = 0;
    char line[MAX_LINE_LENGTH];

    printf("INFO: Membaca dan mem-parsing file input...\n");
    while (fgets(line, sizeof(line), infile)) {
        char *trimmed_line = trim_whitespace(line);

        if (trimmed_line[0] == '#' || trimmed_line[0] == '\0') {
            continue;
        }

        char *ip = strtok(trimmed_line, " \t");
        if (!ip) {
            continue;
        }

        char *host;
        while ((host = strtok(NULL, " \t\n\r"))) {
            if (host[0] == '#') {
                break; // Abaikan sisa baris jika ada komentar
            }
            
            char *clean_host = trim_whitespace(host);
            if (*clean_host == '\0') {
                continue;
            }

            if (entry_count >= capacity) {
                size_t new_capacity = (capacity == 0) ? 1024 : capacity * 2;
                HostEntry *new_entries = realloc(entries, new_capacity * sizeof(HostEntry));
                if (!new_entries) {
                    perror("Error: Gagal mengalokasikan memori untuk entri");
                    // Lakukan cleanup
                    for(size_t i = 0; i < entry_count; i++) {
                        free(entries[i].ip);
                        free(entries[i].host);
                    }
                    free(entries);
                    fclose(infile);
                    return 1;
                }
                entries = new_entries;
                capacity = new_capacity;
            }

            entries[entry_count].ip = strdup(ip);
            entries[entry_count].host = strdup(clean_host);
            if (!entries[entry_count].ip || !entries[entry_count].host) {
                perror("Error: Gagal menduplikasi string");
                // Lakukan cleanup
                 for(size_t i = 0; i < entry_count; i++) {
                    free(entries[i].ip);
                    free(entries[i].host);
                }
                free(entries);
                fclose(infile);
                return 1;
            }
            entry_count++;
        }
    }
    fclose(infile);
    printf("INFO: Ditemukan %zu entri host.\n", entry_count);

    // Tahap 2: Urutkan entri untuk mengelompokkan IP dan mempermudah de-duplikasi
    printf("INFO: Mengurutkan entri host...\n");
    qsort(entries, entry_count, sizeof(HostEntry), compare_entries);
    printf("INFO: Pengurutan selesai.\n");

    // Tahap 3: Tulis hasil yang sudah dikompres dan di-deduplikasi ke file output
    FILE *outfile = fopen(argv[2], "w");
    if (!outfile) {
        perror("Error: Gagal membuat file output");
        // Lakukan cleanup
        for(size_t i = 0; i < entry_count; i++) {
            free(entries[i].ip);
            free(entries[i].host);
        }
        free(entries);
        return 1;
    }

    printf("INFO: Menulis hasil kompresi...\n");
    if (entry_count > 0) {
        char current_ip[IP_ADDRESS_MAX_LENGTH];
        char *host_buffer[MAX_HOSTS_PER_LINE];
        int host_count_in_buffer = 0;

        // Inisialisasi dengan entri pertama
        strcpy(current_ip, entries[0].ip);
        host_buffer[host_count_in_buffer++] = entries[0].host;

        for (size_t i = 1; i < entry_count; i++) {
            // Lewati duplikat
            if (strcmp(entries[i].ip, entries[i-1].ip) == 0 && strcmp(entries[i].host, entries[i-1].host) == 0) {
                continue;
            }

            // Jika IP berubah atau buffer penuh, tulis ke file
            if (strcmp(entries[i].ip, current_ip) != 0 || host_count_in_buffer >= MAX_HOSTS_PER_LINE) {
                fprintf(outfile, "%s", current_ip);
                for (int j = 0; j < host_count_in_buffer; j++) {
                    fprintf(outfile, " %s", host_buffer[j]);
                }
                fprintf(outfile, "\n");

                // Reset buffer
                strcpy(current_ip, entries[i].ip);
                host_count_in_buffer = 0;
            }

            // Tambahkan host ke buffer
            host_buffer[host_count_in_buffer++] = entries[i].host;
        }

        // Tulis sisa host di buffer terakhir
        if (host_count_in_buffer > 0) {
            fprintf(outfile, "%s", current_ip);
            for (int j = 0; j < host_count_in_buffer; j++) {
                fprintf(outfile, " %s", host_buffer[j]);
            }
            fprintf(outfile, "\n");
        }
    }

    fclose(outfile);

    // Tahap 4: Bebaskan semua memori yang dialokasikan
    printf("INFO: Membersihkan memori...\n");
    for (size_t i = 0; i < entry_count; i++) {
        free(entries[i].ip);
        free(entries[i].host);
    }
    free(entries);

    printf("\nProses kompresi selesai. Hasil disimpan di %s\n", argv[2]);

    return 0;
}