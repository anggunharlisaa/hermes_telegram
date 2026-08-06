# TC-01 User and Access Management — Verification Report

## Report Metadata

| Field | Value |
|---|---|
| Control | TC-01 User and Access Management |
| Target host | `<hostname>` |
| Operating system | `<distribution and version>` |
| Execution context | `<local / SSH / container / other>` |
| Mode | `<audit-only / approved apply>` |
| Started at | `<ISO timestamp with timezone>` |
| Completed at | `<ISO timestamp with timezone>` |
| Operator/worker | `<identity>` |
| Change approval | `<approval reference or NOT APPLICABLE>` |

## Approved Scope

- **Target username:** `<username>`
- **Home directory:** `<path>`
- **Login shell:** `<path>`
- **Privileged group:** `<sudo / wheel / custom / none>`
- **Sudo scope:** `<all / restricted / none>`
- **Password method:** `<interactive / centrally managed / SSH-key-only / other>`
- **Password-aging policy:** `<values / preserve host default / centrally managed>`
- **Approved mutations:**
  - `<mutation>`
- **Explicitly excluded:**
  - `<excluded action>`

Do not include password values, hashes, private keys, or tokens.

## Discovery Summary

| Property | Observed value | Evidence | Status |
|---|---|---|---|
| Identity source | `<local / LDAP / SSSD / other>` | `<command>` | `<status>` |
| Account existence | `<value>` | `getent passwd <username>` | `<status>` |
| UID/GID | `<value>` | `id <username>` | `<status>` |
| Home directory | `<value>` | `getent`, `stat` | `<status>` |
| Login shell | `<value>` | `getent passwd` | `<status>` |
| Supplementary groups | `<value>` | `id -nG` | `<status>` |
| Privileged group | `<value>` | `getent group` | `<status>` |
| Effective sudo policy | `<value>` | `sudo -l -U` | `<status>` |
| Password status | `<redacted status only>` | `passwd -S` | `<status>` |
| Password aging | `<non-secret summary>` | `chage -l` | `<status>` |

Allowed status values:

- `PASS`
- `FAIL`
- `NOT TESTED`
- `NOT APPLICABLE`

## Proposed Changes

| Property | Before | Proposed | Risk | Rollback |
|---|---|---|---|---|
| `<property>` | `<current>` | `<desired>` | `<risk>` | `<rollback>` |

## Changes Executed

If audit-only, write: **No mutations executed.**

| Sequence | Action | Result | Read-back verification |
|---:|---|---|---|
| 1 | `<non-secret command/action summary>` | `<exit/result>` | `<evidence>` |

## Success Criteria

| Criterion | Status | Evidence |
|---|---|---|
| User exists | `<status>` | `<evidence>` |
| Account information matches approved configuration | `<status>` | `<evidence>` |
| User belongs to approved privileged group | `<status>` | `<evidence>` |
| Effective sudo authorization is confirmed | `<status>` | `<evidence>` |
| Password status matches approved login method | `<status>` | `<evidence>` |
| Password aging matches approved policy | `<status>` | `<evidence>` |
| Home ownership is correct | `<status>` | `<evidence>` |
| Existing administrator access remains available | `<status>` | `<evidence>` |
| No unapproved mutation occurred | `<status>` | `<evidence>` |

## Exceptions and Residual Risk

- `<exception or None>`
- `<residual risk or None>`

`NOT TESTED` criteria must remain visible and must not be summarized as a full pass.

## Rollback Readiness

- **Non-destructive rollback available:** `<yes/no and method>`
- **Account lock approved:** `<yes/no>`
- **Account deletion approved:** `<yes/no>`
- **Home-directory deletion approved:** `<yes/no>`
- **Data-retention check:** `<result>`

## Final Verdict

- **Verdict:** `<PASS / FAIL / PARTIAL / NOT TESTED>`
- **Summary:** `<one concise paragraph>`
- **Recommended next action:** `<action>`
