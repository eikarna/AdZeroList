# AutoHosts Generator

Repositori ini secara otomatis menghasilkan file `hosts` yang bersih, terkompresi, dan bebas duplikasi dari berbagai sumber. Proses ini dijalankan setiap hari oleh GitHub Actions untuk memastikan file `hosts` selalu yang terbaru.

## ✨ Fitur

- **Otomatis**: Dijalankan setiap hari, tidak perlu intervensi manual.
- **Efisien**: Menggabungkan beberapa host ke dalam satu baris (1 IP untuk 8 domain) untuk mengurangi ukuran file.
- **Bebas Duplikasi**: Memastikan tidak ada entri host yang berulang.
- **Fleksibel**: Mudah untuk menambah atau mengubah sumber `hosts` hanya dengan mengedit file `sources.list`.
- **Kustomisasi**: Mudah untuk menambahkan domain kustom (`custom.list`) atau mengecualikannya (`custom-white.list`).

## 🚀 Penggunaan

File `hosts` yang sudah jadi dapat diunduh dari halaman **[Releases](https://github.com/eikarna/autohosts/releases)** di repositori ini.

Setiap rilis akan diberi tag dengan nomor build dan hash commit untuk pelacakan.

## 🔧 Cara Kerja

1.  **Trigger**: GitHub Actions dijalankan setiap hari pada pukul 00:00 UTC, atau setiap kali ada `push` ke branch `main`.
2.  **Kompilasi**: Skrip mengkompilasi `hostpress.c` menggunakan `Makefile`.
3.  **Unduh**: Semua URL aktif (tidak dikomentari) dari `sources.list` diunduh.
4.  **Kustomisasi**: Semua domain dari `custom.list` ditambahkan ke daftar blokir.
5.  **Proses**: Program `hostpress` dijalankan untuk membersihkan, mengurutkan, menghilangkan duplikasi, dan mengkompres semua entri.
6.  **Whitelist**: Domain yang ada di `custom-white.list` dihapus dari file hosts yang sudah diproses.
7.  **Rilis**: File `hosts` final diunggah sebagai aset ke rilis baru di GitHub.

## 💻 Kustomisasi

Untuk mengubah daftar blokir:

-   **Menambah/Mengubah Sumber**: Edit file `sources.list`. Tambahkan atau hapus URL (satu per baris). Anda bisa menonaktifkan sebuah sumber untuk sementara dengan memberinya komentar (`#`).
-   **Menambah Domain Blokir Kustom**: Edit file `custom.list`. Tambahkan domain yang ingin Anda blokir (satu per baris).
-   **Mengecualikan Domain (Whitelist)**: Edit file `custom-white.list`. Tambahkan domain yang tidak ingin Anda blokir (satu per baris).

Perubahan Anda akan secara otomatis memicu build baru setelah Anda melakukan `push` ke branch `main`.

## 📜 Sumber Hosts Saat Ini

Daftar ini diambil dari `sources.list`:
- [StevenBlack/hosts](https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling/hosts)
- [AdAway](https://adaway.org/hosts.txt)
- [badmojr/1Hosts (Lite)](https://raw.githubusercontent.com/badmojr/1Hosts/master/Lite/hosts.txt)
- [hagezi/dns-blocklists (Pro Compressed)](https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/pro-compressed.txt)

---
*Dibuat dengan bantuan Gemini.*
