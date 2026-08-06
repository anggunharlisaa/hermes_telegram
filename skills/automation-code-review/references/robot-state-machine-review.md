# Robot state-machine review checklist

Use this reference while auditing queue/API/synchronization robots.

## Cross-stage failure patterns

### Scope leakage

A parent selector accepts `--row`, `--limit`, tenant, or batch filters, but downstream child selection receives the complete reference map or queue. Reproduce with at least two parents and two valid children; confirm whether selecting one parent still returns both children.

### Result-key collapse

Multiple child rows or action types are stored under a key that is only unique at parent level. A later `PROCESS_LINE`, `BOOK`, or `RELEASE` overwrites an earlier result and the synchronizer applies it to every child. The durable key normally needs source sheet, source row or child identity, record type/action, and parent business key.

### Premature finalization

Finalization checks only candidates processed in the current run. Invalid, skipped, OPEN, FAILED, or mismatched siblings disappear from the result set, allowing BOOK/RELEASE/close to run on an incomplete parent. Gate finalization against the complete current state of all related children.

### Generated sequence collision

Generated line numbers start at a constant or count only OPEN rows. Existing successful rows and explicit numbers are ignored, so a later run reuses an existing number. Test a successful line numbered 10 followed by a new row with no number.

### Async persistence duplicate

An external create succeeds, but source status/document ID is updated later by another synchronizer. Until sync completes, a second run sees the row as OPEN and sends another create. Require an atomic claim, idempotency key, or reconciliation state before retry.

### Read-check-write race

A duplicate check and append/update occur without one lock. Scheduled, manual, and edit-trigger executions can all pass the check. Full-range read/modify/write can also erase edits made between read and write.

### Schema index drift

A writer accesses `indexes["MESSAGE"]`, for example, but the alias builder never registers `MESSAGE`. Confirm by constructing the index through production helper functions and testing key presence, rather than relying only on visual inspection.

### Configuration contract drift

Compare producer sheet/queue names with consumer defaults, examples, README, and deployed runtime config. Report as conditional when a private deployment override could resolve it, but still flag unsafe defaults.

### Source-of-truth divergence

Deployment metadata may point to a generated or nested directory while similarly named root files differ. Compare hashes/content and state clearly which copy is active.

## Safe reproduction pattern

1. Put a harness outside the repository, such as `/tmp/review_<project>.py`.
2. Stub network and SDK imports minimally so pure functions can load.
3. Set `PYTHONDONTWRITEBYTECODE=1`.
4. Build synthetic rows matching the real schema.
5. Print small deterministic outputs that directly prove the claim.
6. Remove the harness.
7. Verify `git status --short --branch` and `git diff --exit-code`.

Do not encode missing local packages as a durable product defect. A dependency defect exists only when the repository imports a package/module that is absent from its declared dependencies or tracked source.

## Reporting secrets

- Cite file and line range.
- Redact the value.
- Recommend immediate rotation/revocation.
- Mention history cleanup because deleting the current line does not remove prior commits.
- Check active deployment source and duplicate copies.

## Approval gate

When the user asks for analysis only or prior approval:

- Provide flow, findings, evidence, and conceptual recommendations.
- Do not provide a diff, replacement function, or patch-ready code.
- End by requesting explicit approval and clarify desired scope: critical/high only or all findings.
