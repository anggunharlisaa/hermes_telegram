---
name: linux-server-hardening
description: "Use when auditing or hardening Linux servers. Enforces discovery, explicit approval, backups, rollback planning, incremental changes, and post-change verification; currently implements TC-01 User and Access Management."
version: 1.0.0
author: Anggun + Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [linux, security, hardening, sysadmin, users, sudo, access-management]
    related_skills: []
---

# Linux Server Hardening

## Overview

Use this skill to audit and harden Linux servers without causing accidental lockout, privilege loss, or destructive account changes. The workflow is deliberately conservative:

`discover → assess → propose → approve → apply incrementally → verify → report`

The default mode is **audit-only**. Loading this skill is never permission to change the server. A user must explicitly approve a clearly stated mutation scope before any account, privilege, authentication, service, firewall, network, package, or reboot operation.

The first implemented control is **TC-01 User and Access Management**. Before executing TC-01, read `references/tc-01-user-access-management.md`. Use `scripts/verify-user-access.sh` for read-only verification when available, and format the outcome with `templates/tc-01-report.md`.

## When to Use

Use this skill when:

- Auditing a newly provisioned Linux server.
- Creating or validating developer accounts.
- Managing `sudo` or `wheel` membership.
- Applying an approved password policy.
- Verifying account, group, home-directory, shell, and sudo configuration.
- Producing evidence for a hardening test case.

Do not use this skill for:

- Incident response on a host suspected to be actively compromised.
- Identity management controlled by LDAP, Active Directory, SSSD, FreeIPA, or another central provider without first identifying that provider's workflow.
- Container image users unless the user explicitly asks for image-level configuration.
- Deleting accounts or home directories as an implicit rollback.
- Making changes on an unsupported operating system by guessing package, group, or configuration conventions.

## Operating Modes

### Audit mode — default

Audit mode may perform read-only discovery such as:

- Reading `/etc/os-release`.
- Running `id`, `getent`, `passwd -S`, `chage -l`, `sudo -l -U`, and `stat`.
- Inspecting relevant PAM and password-policy configuration.
- Determining whether `sudo`, `wheel`, LDAP, SSSD, or another identity source is active.

Audit mode must not create users, set passwords, alter groups, change files, install packages, restart services, or modify authentication.

Completion criterion: current state, gaps, proposed changes, risks, and rollback plan are documented with command evidence.

### Apply mode — explicit approval required

Apply mode begins only after the user approves a proposal that states:

- Target host and operating system.
- Username and intended account properties.
- Privileged group and sudo scope.
- Password-setting method and aging policy.
- Exact classes of commands to be run.
- Expected side effects.
- Verification steps.
- Rollback boundaries.

Approval for user creation does not automatically approve account deletion, home-directory deletion, SSH changes, firewall changes, package changes, or reboot.

Completion criterion: only approved mutations were executed, every mutation was verified, and the final report accounts for all success criteria.

## Non-Negotiable Safety Rules

1. **Identify the target first.** Confirm hostname, operating system, execution environment, and whether the terminal is local, SSH, container, or another backend.
2. **Preserve administrator access.** Never remove or disable the current working administrator path while creating another account.
3. **No plaintext secrets.** Never place passwords in chat, skill files, command arguments, shell history, process listings, reports, or logs.
4. **Interactive password handling.** Prefer an interactive `passwd <username>` session through a trusted TTY. If no trusted interactive channel exists, stop and request an approved secret-delivery method.
5. **No guessed policy.** A phrase such as "apply password policy" is incomplete until minimum age, maximum age, warning period, complexity source, and exception handling are defined or explicitly delegated to the host's existing policy.
6. **Append groups safely.** Use supplementary-group operations that preserve existing group memberships. Never replace all supplementary groups unless that exact replacement is approved.
7. **Validate before mutation.** Check whether the user, UID, home directory, shell, and privileged group already exist.
8. **Idempotent behavior.** If the desired state already exists, report success without repeating the mutation.
9. **Partial-state awareness.** If a command fails, inspect current state before retrying. Do not blindly rerun `useradd`, `usermod`, `passwd`, or `chage`.
10. **Destructive rollback is separate.** Removing a user or home directory requires new explicit approval. Default rollback removes newly granted privilege or locks the new account while preserving data.
11. **Evidence without leakage.** Reports may include username, UID/GID, group names, shell, home path, and password status, but never password material or hashes.
12. **Stop on identity ambiguity.** If the account is centrally managed, duplicated across sources, or affected by unexpected NSS/PAM behavior, stop and report instead of forcing local changes.

## Platform Rules

Detect the platform from `/etc/os-release`; do not infer it solely from package-manager availability.

| Platform family | Typical privileged group | Notes |
|---|---|---|
| Ubuntu / Debian | `sudo` | Verify the group and sudoers policy actually exist. |
| RHEL / Rocky / Alma / Fedora | `wheel` | Verify `%wheel` is enabled in sudoers. |
| Other Linux | Unknown until discovered | Do not guess; inspect sudoers and local conventions. |

A group existing does not prove it grants sudo. Verify authorization using `sudo -l -U <username>` and, when necessary, read the applicable sudoers policy with privileged read-only access.

## Control Workflow

### 1. Select the control

For TC-01, read `references/tc-01-user-access-management.md` in full before continuing.

Completion criterion: control requirements, required inputs, and prohibited actions are known.

### 2. Discover current state

Collect, at minimum:

- Hostname and operating-system identity.
- Current effective user and privilege capability.
- Identity source (`files`, LDAP/SSSD, or other relevant NSS source).
- Whether the target username exists.
- Existing UID, primary group, supplementary groups, shell, home, and password status.
- Available privileged group and effective sudo policy.
- Existing password-aging values and applicable password-policy mechanism.

Prefer the bundled read-only verifier:

```bash
bash scripts/verify-user-access.sh <username>
```

When the script is not at the current working directory, resolve it from the loaded skill directory or run equivalent read-only commands manually.

Completion criterion: every relevant current-state field has evidence or is explicitly marked unavailable with a reason.

### 3. Validate requested state

Validate the proposed username against the organization's naming rule. If none is provided, use a conservative local-account form: starts with a lowercase letter or underscore, followed only by lowercase letters, digits, underscores, or hyphens, and does not begin with `-`.

Validate that:

- The requested UID is absent or intentionally reused.
- The home path will not overwrite unrelated data.
- The shell exists and is permitted by `/etc/shells` when applicable.
- The privileged group exists and is authorized by sudoers.
- Password aging values are internally consistent.

Completion criterion: no unresolved collision, invalid identifier, or policy ambiguity remains.

### 4. Present the change proposal

Before mutation, present:

- Current state.
- Desired state.
- Commands or command classes to be executed.
- Whether the account will be newly created or an existing account modified.
- Privileged group and effective sudo scope.
- Secure password-setting method.
- Password-aging values, if any.
- Expected files/directories affected.
- Verification plan.
- Non-destructive rollback plan.
- Separately gated destructive rollback options.

Then stop and ask for explicit approval.

Completion criterion: the approval unambiguously covers the proposed target and mutation scope.

### 5. Apply only the approved state

Follow the exact implementation sequence in `references/tc-01-user-access-management.md`. Do not combine account creation, privilege changes, password setting, and policy changes into an opaque one-liner.

After each mutation:

1. Check the command exit status.
2. Read back the affected state.
3. Stop if the observed state differs from the proposal.

Completion criterion: each approved mutation has immediate read-back evidence.

### 6. Verify all success criteria

Run the bundled verifier again and separately verify effective sudo authorization. Do not claim sudo access solely from group membership.

If an actual login or sudo execution test is requested, state its side effects and obtain approval if it would create a session, cache credentials, or execute a privileged command.

Completion criterion: account existence, properties, privileged authorization, password status, and home ownership all satisfy the approved configuration.

### 7. Report

Use `templates/tc-01-report.md`. Distinguish:

- `PASS`: criterion verified with evidence.
- `FAIL`: criterion checked and not satisfied.
- `NOT TESTED`: check could not be performed.
- `NOT APPLICABLE`: criterion does not apply.

Never convert `NOT TESTED` into `PASS`.

Completion criterion: every TC-01 success criterion has one status and supporting evidence.

## Failure and Recovery Discipline

If any apply step fails:

1. Stop subsequent mutations.
2. Record the failed command without secret values.
3. Re-run read-only discovery for the target account.
4. Classify the state as unchanged, partially changed, or successfully changed despite an ambiguous response.
5. Propose the smallest recovery action.
6. Obtain approval for any new mutation not included in the original scope.

Default recovery preference:

1. Preserve the account and data.
2. Remove only unintended privileged-group membership if approved.
3. Lock the new account if required and approved.
4. Delete the account only with separate approval.
5. Delete the home directory only with explicit destructive approval and a verified backup/data-retention decision.

## Common Pitfalls

1. **Using `usermod -G sudo` without `-a`.** This can remove existing supplementary groups. Use an append operation and verify the complete group list afterward.
2. **Assuming `sudo` membership equals sudo authorization.** Sudoers may differ; verify with `sudo -l -U`.
3. **Putting passwords in `chpasswd` pipelines or command arguments.** This can leak through logs and transcripts. Use a trusted interactive method or approved secret mechanism.
4. **Recreating an existing user.** Detect and reconcile current state instead.
5. **Deleting a pre-existing home during rollback.** Home deletion is destructive and separately gated.
6. **Applying generic password aging blindly.** Existing organizational PAM or directory policy may supersede local settings.
7. **Testing with an unrestricted root command.** Prefer policy inspection; obtain approval before an execution test.
8. **Ignoring central identity.** Local changes may be ineffective or conflict with LDAP/SSSD identities.
9. **Reporting group membership as the only evidence.** Include account, shell, home, password status, and effective sudo policy.

## Verification Checklist

- [ ] Target host and OS identified.
- [ ] Current execution identity and privilege capability verified.
- [ ] Identity source identified.
- [ ] Target username validated.
- [ ] Existing account state inspected.
- [ ] Privileged group and effective sudo policy identified.
- [ ] Password policy and secure password-setting method defined.
- [ ] Proposed mutations, risks, verification, and rollback presented.
- [ ] Explicit approval obtained before mutation.
- [ ] Existing group memberships preserved.
- [ ] No password or hash leaked to output, logs, or reports.
- [ ] Account existence and attributes verified.
- [ ] Effective sudo authorization verified.
- [ ] Password status and aging verified.
- [ ] Home directory ownership verified.
- [ ] Every success criterion reported as PASS, FAIL, NOT TESTED, or NOT APPLICABLE.
- [ ] No unapproved mutation occurred.
