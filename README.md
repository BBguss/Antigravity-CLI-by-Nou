# Antigravity CLI by Nou (`agy-by-nou`)

[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20WSL-blue.svg)](#kompatibilitas--persyaratan)
[![Shell](https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh%20%7C%20Ash%20%7C%20POSIX-green.svg)](#integrasi-shell-opsional)
[![Engine](https://img.shields.io/badge/Engine-Direct%20Streaming%20v5-orange.svg)](#arsitektur-teknis-direct-mode-v5)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](#lisensi)

**Antigravity CLI by Nou** adalah ekstensi persisten untuk Google Antigravity CLI (`agy`) yang menyediakan visualisasi kuota real-time pada status bar terminal serta pengelola multi-akun instan (**Multi-Account Switcher**) tanpa memakan kuota LLM dan tanpa delay giliran agen (*zero turn, zero quota*).

Menggunakan slot resmi konfigurasi `statusLine` pada `settings.json` bawaan Antigravity — **100% aman tanpa modifikasi binary**.

---

## Tampilan Statusline

```text
● Gemini 5h ░░░░░░ 0% ↺5m  W ████░░ 69% 29Sep │ ● Other 5h ██████ 100% ↺4h  W ██████ 100% 30Sep │ @user 16:33 my-project ⎇ main*
```

- **Gauge Kuota Visual**: Bar status 5-jam (*sliding window*) dan mingguan (*weekly*) dengan indikator warna ANSI adaptif:
  - **Hijau**: Sisa kuota $\ge 70\%$
  - **Kuning**: Sisa kuota $\ge 30\%$
  - **Merah**: Sisa kuota $< 30\%$
- **Hitung Mundur Reset**: Menampilkan countdown reset kuota (`↺5m`, `↺4h`) atau tanggal reset mingguan (`29Sep`).
- **Konteks Sesi Aktif**: Menampilkan akun pengguna aktif (`@user`), waktu sistem, direktori kerja saat ini, serta status git branch (`⎇ main*` dengan tanda `*` jika working tree kotor).

---

## Fitur Utama

- **Zero-Quota Statusline**: Kuota dan status sesi dibaca langsung dari payload runner secara lokal tanpa request API tambahan dan tanpa memakan kuota model.
- **Direct Mode Streaming (v5)**: Render berkecepatan tinggi (~0.15 detik) membaca `stdin` tanpa proses latar belakang terpisah, tanpa daemon eksternal, dan bebas dari risiko proses macet (*hang*).
- **Instant Multi-Account Switcher**: Beralih profil akun Google dengan satu perintah shell atau satu slash command di dalam antarmuka TUI.
- **Isolasi Profil Aman**: Kredensial dan token disimpan terpisah di direktori profil lokal pengguna (`0700` permissions) dan tidak pernah masuk ke repositori kode.
- **Multi-Tier Interface**: Mendukung pemanggilan lewat integrasi fungsi shell (`agy switch`), executable CLI (`agy-switch`), slash commands TUI (`/switch-account*`), maupun AI agent skills.
- **Cross-Platform Universal**: Berjalan secara konsisten di berbagai distribusi Linux (Ubuntu, Debian, Fedora, Arch, Alpine), macOS, dan Windows WSL.

---

## Instalasi

Clone repositori dan jalankan skrip instalasi otomatis:

```sh
git clone https://github.com/BBguss/Antigravity-CLI-by-Nou.git
cd Antigravity-CLI-by-Nou
sh install.sh
```

### Alur Kerja Installer Otomatis:
1. Mendeteksi variabel lingkungan pengguna (`$HOME` dan `$PATH`) secara dinamis.
2. Memasang modul statusline dan switcher ke direktori konfigurasi `~/.gemini/antigravity-cli/`.
3. Memasang binary CLI `agy-switch` ke direktori eksekusi `~/.local/bin/`.
4. Mendaftarkan slash commands ke `~/.gemini/commands/`.
5. Mendaftarkan skill AI ke `~/.gemini/config/skills/`.
6. Menerapkan konfigurasi `statusLine` ke `settings.json` secara idempoten disertai pencadangan otomatis bertanggal.

> [!NOTE]
> Skrip `install.sh` bersifat **idempoten** — aman dijalankan ulang kapan saja untuk memperbarui instalasi.

---

## Integrasi Shell (Opsional)

Agar perintah `agy switch ...` dapat dipanggil secara langsung di terminal, tambahkan baris berikut ke konfigurasi shell Anda (`~/.bashrc`, `~/.zshrc`, atau `~/.profile`):

```sh
[ -f "$HOME/.gemini/antigravity-cli/shell-agy-function.sh" ] && . "$HOME/.gemini/antigravity-cli/shell-agy-function.sh"
```

Setelah memuat ulang sesi shell (`source ~/.bashrc`):
- `agy switch ...` mengeksekusi switcher akun instan (tanpa turn agen dan tanpa kuota).
- Perintah `agy` lainnya (seperti `agy`, `agy -p`) diteruskan langsung ke binary resmi Antigravity.

---

## Panduan Penggunaan Multi-Akun

### 1. Terminal Shell
Gunakan fungsi shell `agy switch` atau binary `agy-switch`:

```sh
# Menampilkan daftar profil terdaftar dan melihat profil aktif:
agy switch list

# Memeriksa status pointer profil aktif vs token file live:
agy switch current

# Membuat profil baru (profil disiapkan kosong, siap untuk login):
agy switch new akun-kerja

# Berpindah ke profil tertentu:
agy switch switch akun-kerja

# Menghapus profil (hanya profil non-aktif yang dapat dihapus):
agy switch del profil-lama
```

> [!IMPORTANT]
> Pergantian profil menukar berkas token di `~/.gemini/antigravity-cli/`. Perubahan efektif pada **sesi `agy` berikutnya** (cukup restart sesi TUI `agy`). Profil baru memerlukan satu kali autentikasi OAuth melalui tautan browser seperti biasa.

---

### 2. Antarmuka TUI Antigravity (Slash Commands)
Perintah dapat diketik langsung di dalam prompt interaktif `agy`:

```text
/switch-account list            # Menampilkan daftar akun
/switch-account current         # Cek akun aktif saat ini
/switch-account switch akun-b   # Beralih ke profil 'akun-b'
/switch-account new akun-c      # Menyiapkan profil baru
/switch-account del akun-c      # Menghapus profil
```

Tersedia juga alias perintah satu baris:
- `/switch-account-list`
- `/switch-account-current`
- `/switch-account-switch <nama>`
- `/switch-account-new <nama>`
- `/switch-account-del <nama>`

---

## Struktur Berkas Proyek

| Berkas | Lokasi Terpasang | Deskripsi |
|---|---|---|
| `statusline-usage.sh` | `~/.gemini/antigravity-cli/` | Engine utama render statusline ANSI (Direct Mode v5). |
| `statusline-config.json` | `~/.gemini/antigravity-cli/` | Template kanonis konfigurasi blok `statusLine`. |
| `restore-statusline.sh` | `~/.gemini/antigravity-cli/` | Skrip pemulih konfigurasi statusline di `settings.json`. |
| `profile-switch.sh` | `~/.gemini/antigravity-cli/` | Core engine manajemen multi-profil dan rotasi token. |
| `shell-agy-function.sh` | `~/.gemini/antigravity-cli/` | Integrasi fungsi shell `agy()` untuk penanganan sub-command. |
| `bin/agy-switch` | `~/.local/bin/agy-switch` | Executable CLI standalone untuk dipanggil langsung dari shell. |
| `commands/*.toml` | `~/.gemini/commands/` | Definisi slash commands bawaan TUI. |
| `skills/*` | `~/.gemini/config/skills/` | Definisi kemampuan AI agent untuk mengenali perintah akun. |
| `install.sh` | *(Root installer)* | Otomatisasi instalasi dan konfigurasi lingkungan. |

---

## Pemulihan (Self-Healing) & Rollback

### Pemulihan Cepat
Jika pembaruan binary `agy` di masa mendatang menimpa konfigurasi `settings.json`, pulihkan statusline secara instan dengan:
```sh
sh ~/.gemini/antigravity-cli/restore-statusline.sh
```
Atau langsung di dalam sesi TUI:
```text
/statusline enable
```

### Rollback Konfigurasi
Installer selalu membuat berkas cadangan otomatis sebelum melakukan perubahan:
```sh
# Mengembalikan settings ke berkas cadangan sebelum instalasi:
cp ~/.gemini/antigravity-cli/settings.json.bak-<TIMESTAMP> ~/.gemini/antigravity-cli/settings.json
```
Atau melalui perintah TUI: `/statusline reset`.

---

## Arsitektur Teknis (Direct Mode v5)

1. **Streaming Ingestion**: Antigravity TUI runner mengalirkan payload JSON sesi secara otomatis melalui `stdin` setiap kali merender baris status. Skrip menangkap stream tersebut dan melakukan pemformatan ANSI dalam satu proses Python berkecepatan tinggi (~0.15 detik) tanpa *process forking* berulang.
2. **Environment Stripping Resilience**: Antigravity mengeksekusi sub-proses statusline dengan environment minimal. Skrip secara otomatis memulihkan konteks `$HOME` dan `$PATH` standar POSIX agar command git dan interpreter lokal selalu dapat ditemukan.
3. **Atomic Profile Switch**: Penukaran profil akun menggunakan transaksi berkas atomik disertai mekanisme *rollback* otomatis jika format berkas `settings.json` terdeteksi tidak valid.

---

## Kompatibilitas & Persyaratan

- **Sistem Operasi**: Linux (seluruh distribusi), macOS (Intel & Apple Silicon), Windows (via WSL2).
- **Dependensi**:
  - Python 3.6+ (standar bawaan sistem operasi).
  - Shell POSIX (`bash`, `zsh`, `dash`, atau `ash`).
  - Git (opsional, untuk konteks branch di status bar).
  - Antigravity CLI (`agy`) yang sudah terpasang.

---

## Kontributor & Author

- **BBguss** ([@BBguss](https://github.com/BBguss)) &bull; `mbbbdg@gmail.com`

---

## Lisensi

Didistribusikan di bawah lisensi [MIT](LICENSE). Terbuka untuk digunakan, dimodifikasi, dan didistribusikan secara bebas.
