#!/usr/bin/env python3
"""Validate custom Hermes skills without external dependencies."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILLS = ROOT / "skills"
MAX_SKILL_CHARS = 100_000
MAX_DESCRIPTION_CHARS = 1_024
NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")
SECRET_PATTERNS = {
    "private key": re.compile(r"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY"),
    "GitHub token": re.compile(r"gh[pousr]_[A-Za-z0-9_]{20,}"),
    "AWS access key": re.compile(r"AKIA[0-9A-Z]{16}"),
    "OpenAI-style key": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
}


def fail(message: str, errors: list[str]) -> None:
    errors.append(message)
    print(f"FAIL: {message}")


def frontmatter_value(frontmatter: str, key: str) -> str | None:
    match = re.search(
        rf"(?m)^{re.escape(key)}:\s*(?:\"([^\"]*)\"|'([^']*)'|([^\n#]+))",
        frontmatter,
    )
    if not match:
        return None
    return next(value for value in match.groups() if value is not None).strip()


def validate_skill(skill_dir: Path, errors: list[str]) -> None:
    skill_md = skill_dir / "SKILL.md"
    rel = skill_dir.relative_to(ROOT)
    if not skill_md.is_file():
        fail(f"{rel}: SKILL.md missing", errors)
        return

    text = skill_md.read_text(encoding="utf-8")
    if len(text) > MAX_SKILL_CHARS:
        fail(f"{rel}: SKILL.md exceeds {MAX_SKILL_CHARS} characters", errors)
    if not text.startswith("---\n"):
        fail(f"{rel}: frontmatter must begin at byte zero", errors)
        return

    marker = text.find("\n---\n", 4)
    if marker < 0:
        fail(f"{rel}: closing frontmatter marker missing", errors)
        return

    frontmatter = text[4:marker]
    body = text[marker + 5 :].strip()
    name = frontmatter_value(frontmatter, "name")
    description = frontmatter_value(frontmatter, "description")
    license_value = frontmatter_value(frontmatter, "license")

    if not name or not NAME_RE.fullmatch(name):
        fail(f"{rel}: invalid or missing name", errors)
    elif name != skill_dir.name:
        fail(f"{rel}: frontmatter name {name!r} differs from directory", errors)
    if not description:
        fail(f"{rel}: description missing", errors)
    elif len(description) > MAX_DESCRIPTION_CHARS:
        fail(f"{rel}: description exceeds {MAX_DESCRIPTION_CHARS} characters", errors)
    if not license_value:
        fail(f"{rel}: license missing", errors)
    if not body:
        fail(f"{rel}: body is empty", errors)

    for path in skill_dir.rglob("*"):
        if path.is_symlink():
            fail(f"{path.relative_to(ROOT)}: symlinks are not allowed", errors)
            continue
        if not path.is_file():
            continue
        data = path.read_bytes()
        if b"\x00" in data[:8192]:
            continue
        content = data.decode("utf-8", errors="replace")
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(content):
                fail(f"{path.relative_to(ROOT)}: possible {label}", errors)
        if path.suffix == ".sh":
            result = subprocess.run(
                ["bash", "-n", str(path)],
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode:
                fail(
                    f"{path.relative_to(ROOT)}: bash syntax error: {result.stderr.strip()}",
                    errors,
                )

    print(f"PASS: {rel}")


def main() -> int:
    errors: list[str] = []
    if not SKILLS.is_dir():
        fail("skills directory missing", errors)
    else:
        skill_dirs = sorted(path.parent for path in SKILLS.glob("*/SKILL.md"))
        if not skill_dirs:
            fail("no skills found", errors)
        for skill_dir in skill_dirs:
            validate_skill(skill_dir, errors)

    if errors:
        print(f"\nValidation failed: {len(errors)} error(s).")
        return 1
    print("\nValidation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
