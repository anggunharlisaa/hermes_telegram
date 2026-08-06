# Contributing

## Branch Policy

- Jangan commit langsung ke `main`.
- Gunakan `develop` sebagai branch integrasi.
- Buat satu `feature/<nama>` untuk satu perubahan terisolasi.
- Gunakan `release/vX.Y.Z` untuk persiapan rilis bila diperlukan.
- Jangan force-push ke `main` atau `develop`.

## Mandatory Sync-First Workflow

Sebelum mengubah atau menambahkan file:

```bash
git fetch --prune origin
git switch develop
git pull --ff-only origin develop
git switch -c feature/<nama-perubahan>
```

Jika feature branch sudah ada:

```bash
git fetch --prune origin
git switch feature/<nama-perubahan>
git merge --ff-only origin/develop
```

Jika fast-forward tidak memungkinkan, berhenti dan review divergensi. Jangan menggunakan `git reset --hard`, rebase publik, atau force-push tanpa keputusan eksplisit.

## Skill Layout

Setiap skill berada langsung di bawah `skills/` agar kompatibel dengan custom tap:

```text
skills/<skill-name>/
├── SKILL.md
├── references/   # optional
├── scripts/      # optional
├── templates/    # optional
└── assets/       # optional
```

## Required Checks

```bash
python3 scripts/validate_skills.py
git diff --check
git status --short
git diff --stat
git diff
```

Periksa bahwa:

- `SKILL.md` memiliki frontmatter valid.
- `name` sama dengan nama direktori.
- `description` tidak melebihi 1024 karakter.
- Script shell lulus `bash -n`.
- Tidak ada secret, private key, password, token, memory, atau session.
- Attribution dan license dipertahankan.
- File pendukung yang direferensikan ikut disertakan.

## Commit Convention

```text
feat: add <skill or capability>
fix: correct <behavior>
docs: update <documentation>
chore: maintain <repository operation>
```

Satu commit harus dapat dijelaskan, direview, dan dibatalkan secara independen.
