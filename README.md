# Hermes Telegram Skills

Repository ini menyimpan skill custom yang digunakan oleh Hermes Agent pada integrasi Telegram milik `anggunharlisaa`, serta katalog skill bundled yang tersedia pada profile aktif.

## Isi Repository

```text
.
├── skills/                         # Skill custom yang dapat di-install
│   ├── linux-server-hardening/
│   └── automation-code-review/
├── catalog/
│   ├── custom-skills.md
│   └── bundled-skills.md           # Katalog/link; source tidak dimirror
├── scripts/
│   └── validate_skills.py
├── .github/workflows/
│   └── validate-skills.yml
├── CONTRIBUTING.md
└── LICENSE
```

Repository ini **tidak** menyimpan konfigurasi Hermes, memory, session, password, API token, private SSH key, atau credential Telegram/GitHub.

## Custom Skills

### `linux-server-hardening`

Skill hardening Linux dengan safety gate. Versi awal mengimplementasikan **TC-01 User and Access Management**:

- Audit sebagai mode default.
- Approval sebelum mutation.
- Pembuatan dan verifikasi user.
- Sudo/wheel membership dan effective sudo policy.
- Password handling tanpa menyimpan plaintext secret.
- Failure handling, rollback, dan template laporan.

### `automation-code-review`

Review read-only untuk robot/RPA dan sistem otomasi yang menggunakan queue, spreadsheet, API, result synchronization, dan retry. Fokus pada state machine, idempotency, concurrency, schema contract, dan bukti bug tanpa mengubah source.

## Install pada Hermes

Tambahkan repository sebagai custom skill tap:

```bash
hermes skills tap add anggunharlisaa/hermes_telegram
```

Kemudian install skill:

```bash
hermes skills install anggunharlisaa/hermes_telegram/linux-server-hardening
hermes skills install anggunharlisaa/hermes_telegram/automation-code-review
```

Alternatif manual:

```bash
git clone https://github.com/anggunharlisaa/hermes_telegram.git
mkdir -p ~/.hermes/skills/devops ~/.hermes/skills/software-development
cp -a hermes_telegram/skills/linux-server-hardening ~/.hermes/skills/devops/
cp -a hermes_telegram/skills/automation-code-review ~/.hermes/skills/software-development/
```

Setelah instalasi, mulai sesi baru atau jalankan:

```text
/reload-skills
```

## Contoh Penggunaan

```text
Audit TC-01 menggunakan skill linux-server-hardening untuk user anggun.
Jangan lakukan perubahan sebelum approval.
```

```text
Gunakan automation-code-review untuk memeriksa source robot ini secara read-only.
Jangan berikan patch sebelum approval.
```

## Branch Strategy

- `main` — rilis stabil dan siap digunakan sebagai tap.
- `develop` — integrasi perubahan yang telah divalidasi.
- `feature/<nama-perubahan>` — satu penambahan atau perubahan terisolasi.
- `release/vX.Y.Z` — persiapan rilis stabil bila diperlukan.

Perubahan awal disiapkan pada `feature/initial-skill-catalog`, kemudian diintegrasikan ke `develop`, dan baru dipromosikan ke `main` setelah verifikasi.

## Sync-First Policy

Sebelum setiap rangkaian perubahan:

```bash
git fetch --prune origin
git pull --ff-only
```

Jika bekerja pada feature branch yang belum memiliki upstream, fetch lalu fast-forward terhadap branch basis:

```bash
git fetch --prune origin
git merge --ff-only origin/develop
```

Jangan melakukan force-push ke `main` atau `develop`.

## Bundled Skills

Skill bawaan Hermes tidak disalin ulang ke repository ini. Daftar, provenance, lisensi, dan link upstream tersedia pada [`catalog/bundled-skills.md`](catalog/bundled-skills.md).

Pengecualian ini penting karena beberapa bundled skill memiliki lisensi yang membatasi reproduksi atau tidak mendeklarasikan izin redistribusi secara jelas.

## Validasi

Jalankan:

```bash
python3 scripts/validate_skills.py
```

Validator memeriksa struktur `SKILL.md`, frontmatter utama, ukuran, nama direktori, file shell, symlink, dan pola secret berisiko tinggi.

## Lisensi

Materi original dalam repository ini menggunakan lisensi MIT kecuali jika file atau skill menyatakan lisensi lain. Attribution dan lisensi upstream tetap berlaku untuk materi yang dirujuk.
