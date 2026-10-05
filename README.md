# agy-by-nou — Universal Custom Statusline & Multi-Account Manager for Antigravity CLI (`agy`)

Bar status persisten di terminal Antigravity CLI (`agy`): visual gauge kuota real-time + konteks sesi aktif.
Tanpa perlu mengetik `/usage` lagi. Menggunakan slot resmi `statusLine` di `settings.json` — 100% tanpa modifikasi binary.

Dilengkapi dengan manajer profil multi-akun (**Multi-Account Switcher**) yang bekerja secara instan tanpa memakan kuota, tanpa jeda giliran agen (*zero agent turn*), serta portabel untuk dipasang di sistem operasi apa pun (**Linux, macOS, WSL, Synology DSM**).

---

## 📸 Contoh Tampilan (108–145 Kolom)

```text
● Gemini 5h ░░░░░░ 0% ↺5m  W ████░░ 69% 29Sep │ ● Other 5h ██████ 100% ↺4h  W ██████ 100% 30Sep │ @user 16:33 my-project ⎇ main
```

* **`●` Indikator Status Kuota**: Hijau ($\ge 70\%$), Kuning ($\ge 30\%$), Merah ($< 30\%$).
* **Bar `5h` & `W`**: Batas 5-jam ("harian") & batas mingguan (Weekly) + hitung mundur reset (`↺5m`) atau tanggal pembaruan (`29Sep`).
* **Konteks `@akun`**: Identitas akun aktif yang diperoleh langsung dari session payload runner tanpa overhead jaringan/kuota.
* **Konteks Direktori & Git**: Jam sistem, nama direktori kerja aktif, dan status branch git (`⎇ main*`, tanda `*` menandakan working tree kotor).

---

## 🚀 Instalasi Universal (1 Langkah)

Paket ini dirancang **universal** dan tidak bergantung pada direktori atau path server tertentu (`/volume1/` atau `/var/services/` telah dieliminasi total). Seluruh komponen terpasang ke direktori standar pengguna (`~/.gemini/` dan `~/.local/bin/`).

### Cara Pasang:
Clone repositori ke direktori mana saja di komputer/server Anda, lalu jalankan `install.sh`:

```sh
git clone <repo-url> agy-by-nou
cd agy-by-nou
sh install.sh
```

### Apa yang Dilakukan oleh `install.sh` Secara Otomatis:
1. **Deteksi Environment Universal**: Menemukan `$HOME` pengguna secara dinamis di Linux, macOS, WSL, atau Synology DSM.
2. **Memasang Script Statusline & Switcher**: Menyalin `statusline-usage.sh`, `restore-statusline.sh`, `statusline-config.json`, dan `profile-switch.sh` ke `~/.gemini/antigravity-cli/`.
3. **Memasang Binary CLI `agy-switch`**: Menyalin executable `agy-switch` ke `~/.local/bin/agy-switch`.
4. **Mendaftarkan Slash Commands**: Menyalin seluruh perintah custom ke `~/.gemini/commands/` (`/switch-account*`).
5. **Mendaftarkan Agent Skills**: Menyalin skill AI ke `~/.gemini/config/skills/` agar agen memahami perintah pergantian akun.
6. **Auto-Inject Konfigurasi**: Memperbarui blok `statusLine` pada `~/.gemini/antigravity-cli/settings.json` secara idempoten dan aman dengan backup berwaktu.

> **Catatan**: Script instalasi bersifat **idempoten** — sangat aman dijalankan berulang kali kapan saja untuk memperbarui paket.

---

## ⚡ Integrasi Shell (Opsional & Sangat Direkomendasikan)

Agar perintah `agy switch ...` dapat dipanggil langsung dari shell terminal seperti sub-perintah bawaan, tambahkan baris berikut ke `~/.bashrc`, `~/.zshrc`, atau `~/.profile`:

```sh
[ -f "$HOME/.gemini/antigravity-cli/shell-agy-function.sh" ] && . "$HOME/.gemini/antigravity-cli/shell-agy-function.sh"
```

Setelah di-source (`source ~/.bashrc`), fungsi shell `agy()` akan:
* Mencegat argumen `switch` dan meneruskannya langsung ke `profile-switch.sh` tanpa turn/kuota.
* Meneruskan seluruh perintah `agy` lainnya secara transparan ke binary asli (`command agy`).

---

## 👥 Penggunaan Multi-Akun (Account Profiles)

Antigravity CLI secara bawaan membaca token autentikasi saat startup. Fitur multi-akun mengisolasi berkas token dan setelan per profil di `~/.gemini/antigravity-profiles/` (izin ketat `0700`).

### 1. Perintah Shell Langsung (Tanpa Agent Turn, Tanpa Kuota)

Anda dapat menggunakan salah satu dari dua cara berikut:

```sh
# Melalui integrasi fungsi shell:
agy switch list                     # Daftar profil dan cek akun aktif
agy switch current                  # Tampilkan pointer profil vs token live
agy switch new <nama_profil>        # Buat profil baru (login via link sekali)
agy switch switch <nama_profil>     # Beralih ke profil tertentu
agy switch del <nama_profil>        # Hapus profil non-aktif

# ATAU langsung melalui binary CLI:
agy-switch list
agy-switch switch <nama_profil>
```

> **Aturan Pergantian Akun**: Pergantian profil (*switch*) langsung menukar berkas token di `~/.gemini/antigravity-cli/`. Pergantian efektif pada **sesi `agy` berikutnya** (cukup restart TUI `agy`).

---

### 2. Slash Command di Dalam TUI (`/switch-account`)

Dapat dipanggil langsung saat Anda sedang berada di dalam sesi TUI Antigravity:

```text
/switch-account list            # Lihat profil + akun aktif
/switch-account current         # Pointer profil vs file live
/switch-account switch akunb    # Ganti akun ke 'akunb'
/switch-account new akunc       # Tambah profil baru
/switch-account del akunc       # Hapus profil
```

Tersedia juga alias instan satu baris:
* `/switch-account-list`
* `/switch-account-current`
* `/switch-account-switch <nama>`
* `/switch-account-new <nama>`
* `/switch-account-del <nama>`

---

## 📦 Struktur Berkas & Komponen

| Berkas Sumber | Tujuan Pemasangan | Peran & Fungsi |
|---|---|---|
| `statusline-usage.sh` | `~/.gemini/antigravity-cli/` | Renderer statusline visual 1 baris ANSI (Direct Mode v5). |
| `statusline-config.json` | `~/.gemini/antigravity-cli/` | Definisi kanon blok `statusLine` untuk pemulihan. |
| `restore-statusline.sh` | `~/.gemini/antigravity-cli/` | Skrip idempoten pemulih `statusLine` di `settings.json`. |
| `profile-switch.sh` | `~/.gemini/antigravity-cli/` | Core engine switcher akun multi-profil. |
| `shell-agy-function.sh` | `~/.gemini/antigravity-cli/` | Wrapper integrasi fungsi shell `agy()`. |
| `bin/agy-switch` | `~/.local/bin/agy-switch` | Binary CLI standalone untuk switch profil. |
| `commands/*.toml` | `~/.gemini/commands/` | Definisi slash commands `/switch-account*`. |
| `skills/*` | `~/.gemini/config/skills/` | Skill integrasi AI untuk mendeteksi intent pergantian akun. |
| `install.sh` | *(Installer root)* | Skrip pemasang otomatis ke seluruh target di atas. |

---

## 🔧 Pemulihan (*Self-Healing*) & Rollback

### Jika Statusline Hilang Akibat Update `agy`:
Jika pembaruan binary `agy` menimpa `settings.json`, Anda dapat memulihkannya dalam 1 detik:
```sh
sh ~/.gemini/antigravity-cli/restore-statusline.sh
```
Atau di dalam sesi TUI:
```text
/statusline enable
```

### Rollback ke Pengaturan Asli:
Skrip installer selalu membuat berkas cadangan bertanggal sebelum memodifikasi `settings.json`:
```sh
# Contoh merestore backup otomatis:
cp ~/.gemini/antigravity-cli/settings.json.bak-<TIMESTAMP> ~/.gemini/antigravity-cli/settings.json
```
Atau di dalam TUI: `/statusline reset`.

---

## 🧠 Catatan Arsitektur Teknis (Direct Mode v5)

1. **Direct Session Ingestion (v5)**:
   Runner TUI Antigravity mengalirkan payload JSON sesi lengkap melalui `stdin` pada setiap siklus render (persentase kuota, email akun, cwd, model, terminal width). Script mengeksekusi satu proses Python membaca `stdin` tanpa proses latar belakang (*zero background daemons*), tanpa fetch eksternal, dan tanpa file lock yang berisiko *stampede*.
2. **Pembersihan Environment Terlucuti (*Stripped Env*)**:
   Runner TUI mengeksekusi sub-proses statusline dengan environment terlucuti (tanpa `$HOME` lengkap). `statusline-usage.sh` memulihkan `$HOME` dan `$PATH` secara otomatis melalui resolusi POSIX (`getent` / `id` / `eval`) sebelum merender output.
3. **Penyimpanan Profil Terisolasi**:
   Semua data otentikasi disimpan di `~/.gemini/antigravity-profiles/` dengan izin `0700` (hanya dapat dibaca oleh pemilik proses). Tidak ada data rahasia atau token OAuth yang tersimpan di dalam repositori kode.

---

## 📜 Riwayat Pembaruan

* **v5.1 Universal Portability (2026-10-05)**:
  * Eliminasi total seluruh path spesifik server (`/volume1/web/...` dan `/var/services/homes/...`).
  * Installer otomatis menyeluruh: menyalin script, binary CLI `~/.local/bin/agy-switch`, slash commands `~/.gemini/commands/`, dan skills `~/.gemini/config/skills/`.
  * Resolusi path dinamis di `restore-statusline.sh` dan `bin/agy-switch` agar berjalan di sembarang OS (Linux, macOS, WSL, Synology DSM).
* **v5 Direct Mode (2026-09-23)**:
  * Arsitektur stdin streaming: render instan (~0.15 detik) langsung dari session payload runner Antigravity.
  * Menghapus mekanisme lock/background worker yang memicu proses zombie.
* **v4 (2026-09-23)**:
  * Atomic directory lock & auto-reclaim pencegah race condition saat render cepat.
* **v1–v3**:
  * Teks polos $\rightarrow$ gauge ANSI visual $\rightarrow$ segmen konteks akun & status git.
