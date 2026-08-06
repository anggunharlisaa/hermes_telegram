# TC-01 — User and Access Management

## Control Metadata

- **Control ID:** TC-01
- **Domain:** User and Access Management
- **Default mode:** Audit-only
- **Mutation risk:** High
- **Primary targets:** Ubuntu and Debian
- **Conditional targets:** RHEL, Rocky Linux, AlmaLinux, Fedora

## Scenario

A new server will be used by a developer team. An administrator needs to create a user account, grant the approved sudo privilege, set a password through a secure method, apply the defined password-aging policy, and verify the resulting account information.

## Requirements

- The requested user account exists.
- The account has the approved home directory and login shell.
- The account belongs to the approved privileged group.
- Effective sudo authorization is confirmed.
- Password status is set without exposing the password.
- Applicable password-aging information is verified.
- Account information can be independently read back.

## Success Criteria

TC-01 passes only when all applicable criteria are evidenced:

1. The user account exists in the intended identity source.
2. UID, primary GID, home directory, shell, and account name match the approved configuration.
3. The user belongs to the expected privileged group.
4. `sudo -l -U <username>` or equivalent policy inspection confirms the intended sudo authorization.
5. Password status indicates an administratively valid state according to the approved login method.
6. Password-aging values match the approved policy or are explicitly marked as centrally managed/not applicable.
7. Home directory ownership is correct.
8. Existing administrator access remains available.
9. No unapproved account, group, authentication, SSH, or filesystem change occurred.

Group membership alone is insufficient to pass criterion 4.

## Required Inputs

Collect these values before proposing changes:

| Input | Required | Notes |
|---|---:|---|
| Target host | Yes | Hostname or server identifier. |
| Username | Yes | Must pass naming and collision checks. |
| Full name/comment | No | Must not contain secrets. |
| Login shell | Yes | Default may be `/bin/bash` if approved and present. |
| Home directory | Yes | Default may be `/home/<username>` if approved. |
| Privileged access | Yes | `none`, `sudo`, `wheel`, or custom sudoers policy. |
| Sudo scope | Yes | All commands or approved restricted commands. |
| Password login | Yes | Enabled, disabled, centrally managed, or not applicable. |
| Password-setting method | Conditional | Trusted interactive TTY or approved secret mechanism. |
| Password minimum age | Conditional | Do not invent. |
| Password maximum age | Conditional | Do not invent. |
| Password warning period | Conditional | Do not invent. |
| Account expiry | No | Apply only when explicitly requested. |
| Existing-user handling | Yes | Reconcile, reject, or modify approved fields. |

If password-policy values are not supplied, inspect and preserve the host's effective policy. Do not claim a custom policy was applied.

## Phase A — Read-Only Discovery

### A1. Identify platform and execution context

Read:

```bash
hostname
id
cat /etc/os-release
```

Determine whether execution is local, SSH, container, or another backend. If the target is a container or immutable image, stop and confirm that local account creation is appropriate.

### A2. Identify the account source

Inspect NSS configuration where relevant:

```bash
getent passwd <username>
getent group sudo
getent group wheel
```

If `getent passwd` returns a user not present in `/etc/passwd`, the identity may be centrally managed. Investigate LDAP/SSSD/FreeIPA/AD before any local mutation.

### A3. Inspect the target account

Run read-only checks:

```bash
id <username>
getent passwd <username>
passwd -S <username>
chage -l <username>
```

Some commands require root for complete output. If privilege is unavailable, report `NOT TESTED`; do not guess.

Inspect the configured shell and home directory:

```bash
getent passwd <username>
getent passwd <username> | cut -d: -f6,7
stat <home-directory>
```

### A4. Determine the effective privileged group

Typical mappings:

- Ubuntu/Debian: `sudo`
- RHEL/Rocky/Alma/Fedora: `wheel`

Verify both the group and sudoers policy:

```bash
getent group sudo
getent group wheel
sudo -l -U <username>
```

Where permitted, inspect effective sudoers configuration using read-only privileged access. Never edit `/etc/sudoers` directly; any future sudoers changes must use a validated drop-in and `visudo -c`.

### A5. Inspect password policy

Identify applicable policy sources, which may include:

- `/etc/login.defs`
- PAM configuration
- `pam_pwquality`
- `pam_pwhistory`
- SSSD or directory policy
- Existing per-user `chage` values

This control does not authorize changing global PAM policy. TC-01 may apply approved per-user aging values, but global password-policy hardening belongs in a separately approved control.

### A6. Produce discovery result

Classify the target:

- **ABSENT:** safe to propose new local-account creation after collision checks.
- **PRESENT-COMPLIANT:** desired state already exists; no mutation needed.
- **PRESENT-NONCOMPLIANT:** propose only the specific differences.
- **CENTRALLY-MANAGED:** stop local changes and route to the identity provider workflow.
- **AMBIGUOUS:** stop and request clarification.

## Phase B — Proposal and Approval

Present a table similar to:

| Property | Current | Proposed | Mutation required |
|---|---|---|---|
| Username | absent | `developer1` | Yes |
| Home | absent | `/home/developer1` | Yes |
| Shell | absent | `/bin/bash` | Yes |
| Privileged group | absent | `sudo` | Yes |
| Password | absent | interactive setting | Yes |
| Aging | host default | preserve host default | No |

Include the proposed sequence and rollback:

1. Create the account and home directory.
2. Read back account metadata.
3. Append the account to the approved privileged group.
4. Read back group membership and effective sudo policy.
5. Set password through the approved secure method.
6. Apply only explicitly approved per-user aging values.
7. Run complete verification.

Then stop. Do not interpret the original requirement document as runtime approval for a particular host or username.

## Phase C — Approved Apply Procedure

Execute only after explicit approval covers the target and values.

### C1. Re-check immediately before mutation

Repeat the account and group lookup immediately before creating the user. This closes the gap between discovery and apply.

If the state changed, stop and issue a revised proposal.

### C2. Create the account

Use the platform's supported account-management command. For a conventional local account, the operation should create a home directory and set the approved shell and comment.

Illustrative command shape:

```bash
sudo useradd --create-home --shell <approved-shell> --comment <approved-comment> -- <username>
```

Rules:

- Validate every substituted value first.
- Do not pass unsanitized free-form data through shell interpolation.
- Do not specify a UID unless explicitly required and collision-checked.
- Do not create a system account unless explicitly requested.
- Do not include a plaintext password or password hash in the command transcript.

Immediately verify:

```bash
getent passwd <username>
id <username>
stat <home-directory>
```

If creation fails, inspect state before retrying.

### C3. Grant approved group membership

Append rather than replace supplementary groups:

```bash
sudo usermod --append --groups <approved-privileged-group> -- <username>
```

Immediately verify:

```bash
id <username>
getent group <approved-privileged-group>
sudo -l -U <username>
```

If sudo policy does not grant the intended access, do not assume adding another group is the fix. Inspect policy and issue a new proposal.

### C4. Set the password securely

Preferred method:

```bash
sudo passwd <username>
```

Run only in a trusted interactive TTY. The password must be entered by an authorized human and must not be repeated into chat or captured in a report.

If no trusted TTY is available:

1. Do not improvise a plaintext pipeline.
2. Leave the account locked or without usable password authentication as appropriate.
3. Request an approved secret-manager, SSH-key, or account-activation workflow.

Immediately verify password status without revealing password material:

```bash
sudo passwd -S <username>
```

Interpret status according to the platform. Do not claim password login works solely because a password status entry exists; SSH/PAM policy may disable it.

### C5. Apply approved per-user password aging

Only when exact values were approved, use the appropriate `chage` options. Illustrative shape:

```bash
sudo chage --mindays <min> --maxdays <max> --warndays <warn> -- <username>
```

Do not invent values. Verify with:

```bash
sudo chage -l <username>
```

Global PAM/password-complexity changes are outside TC-01 unless separately approved.

### C6. Optional execution test

Policy inspection is preferred. An actual login or sudo command test may:

- Create authentication logs.
- Cache sudo credentials.
- Create shell history or user files.
- Trigger security monitoring.

Describe these effects and obtain approval before performing such a test. Use the least-privileged harmless command approved by the operator.

## Phase D — Verification

Run:

```bash
bash scripts/verify-user-access.sh <username>
```

Then verify any environment-specific item the script could not test.

Required evidence:

- `getent passwd` output confirms account attributes.
- `id` output confirms UID/GID and supplementary groups.
- `getent group` confirms membership.
- `sudo -l -U` confirms effective sudo policy.
- `passwd -S` confirms password state.
- `chage -l` confirms aging state when applicable.
- `stat` confirms home ownership.

Redact unrelated sensitive information from the final report.

## Failure Handling

### User creation returned an error

- Run `getent passwd <username>` and `id <username>`.
- If absent, diagnose the original error before retrying.
- If present, treat as partial or ambiguous success and continue with read-only reconciliation.

### Group update returned an error

- Read current memberships with `id`.
- Do not repeat with `usermod -G` or replace groups.
- Confirm the target group exists and sudoers authorizes it.

### Password setting was interrupted

- Inspect `passwd -S`.
- Do not assume a usable password was set.
- Keep or lock the account according to the approved recovery scope.

### Verification differs from proposal

- Stop.
- Record the difference.
- Do not proceed to optional policy or login tests.
- Propose the smallest correction.

## Rollback

Rollback is not automatically destructive.

### Preferred non-destructive rollback

With approval, remove only the newly granted privileged membership while preserving other groups:

```bash
sudo gpasswd --delete <username> <privileged-group>
```

Verify with `id` and `sudo -l -U`.

With approval, lock the new account:

```bash
sudo usermod --lock -- <username>
```

Verify with `passwd -S`.

### Destructive rollback — separate approval

Account deletion:

```bash
sudo userdel -- <username>
```

Account and home deletion:

```bash
sudo userdel --remove -- <username>
```

Never execute either command merely because an earlier step failed. Before deletion:

- Confirm the account was created by this change.
- Check active sessions and processes.
- Check home-directory contents and data-retention requirements.
- Confirm no files outside the home are owned by the UID.
- Obtain explicit approval for account deletion.
- Obtain separate explicit approval for home/data deletion.

## Report Requirements

Use `templates/tc-01-report.md` and include:

- Target and timestamp with timezone.
- Execution mode.
- Approved scope.
- Current-state summary.
- Mutations actually executed.
- Verification evidence.
- Criterion-by-criterion status.
- Exceptions and residual risk.
- Rollback readiness.

Never include:

- Passwords or hashes.
- Private keys.
- Authentication tokens.
- Unrelated sudoers content.
- Full sensitive directory listings.
