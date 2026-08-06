---
name: automation-code-review
description: "Review read-only terhadap sistem otomasi/robot yang menghubungkan queue, spreadsheet, API, trigger, sinkronisasi hasil, dan retry. Gunakan untuk audit alur end-to-end, idempotensi, concurrency, state machine, serta bukti bug tanpa mengubah source."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [code-review, automation, rpa, idempotency, concurrency, read-only]
    related_skills: [requesting-code-review, systematic-debugging, codebase-inspection]
---

# Automation Code Review

Review existing automation repositories as end-to-end state machines, not merely collections of functions. This skill is designed for robots that move data through spreadsheets or queues, call external APIs, synchronize results, and retry failures.

## When to use

- The user requests source-only analysis of an RPA, integration robot, scheduled worker, or spreadsheet automation.
- The system has producer, consumer, external API, result synchronization, and resend/retry stages.
- The user prohibits code changes or requires approval before any patch.
- Correctness depends on idempotency, row-level keys, sequencing, or concurrent triggers.

For pre-commit review of changes already made, use `requesting-code-review`. For repository metrics only, use `codebase-inspection`.

## Core principles

1. **Honor read-only scope.** Do not turn a review into an implementation task.
2. **Find the deployed source.** Deployment metadata overrides assumptions based on filenames.
3. **Trace the full lifecycle.** Bugs often occur between producer, consumer, synchronizer, and retry components.
4. **Prove repository cleanliness.** Record baseline and final Git state.
5. **Separate evidence levels.** Label findings as dynamically reproduced, statically proven, or conditional risk.
6. **Never exercise production side effects during source review.** Do not call business APIs, update sheets, install triggers, or execute write paths.

## Workflow

### 1. Establish immutable scope

Record:

- Repository URL and local path.
- Branch and exact commit.
- Initial `git status` and diff.
- Explicitly forbidden actions.
- Whether approval is required before proposing or applying code changes.

If approval is required, recommendations may explain remediation intent, but stop before supplying a patch or code replacement.

### 2. Identify architecture and active source

Inspect entry points, package metadata, deployment descriptors, configuration examples, CI, scheduler definitions, and generated/deployed directories. Resolve duplicate source trees before evaluating behavior.

Create an end-to-end map:

1. Input/producer.
2. Queue creation and status assignment.
3. Candidate selection.
4. External side effect.
5. Result persistence.
6. Source synchronization.
7. Retry/resend.
8. Finalization.

### 3. Review state and identity

For every stage, determine:

- Stable business key and row key.
- State transitions and who owns each transition.
- Atomic claim behavior before external calls.
- Crash and timeout recovery.
- Idempotency guarantees.
- Locking around read-check-write sequences.
- Whether parent filters propagate to child processing.
- Whether child results remain distinct through synchronization.

### 4. Review configuration and schema contracts

Cross-check runtime defaults, example environment files, documentation, producer names, consumer names, status values, column aliases, and optional-field access. Treat a schema index used but never registered as a concrete defect, not a style issue.

### 5. Perform non-mutating verification

Use syntax parsing, static searches, and synthetic pure-logic fixtures. Keep temporary harnesses outside the repository, disable bytecode writes where applicable, and remove them afterward.

Recommended checks:

- Python `ast.parse` rather than `compileall` when repository cleanliness matters.
- `node --check` for JavaScript syntax.
- Secret-pattern scans with redacted reporting.
- Search for tests and dependency declarations.
- Synthetic fixtures for key collisions, filter leakage, sequence generation, and missing schema indexes.
- Final `git status` plus `git diff --exit-code`.

### 6. Report by operational risk

For each finding include:

- Severity.
- File and line range.
- Triggering scenario.
- Business/operational impact.
- Probe output when available.
- Conceptual recommendation.

End with:

- What was verified.
- What was intentionally not executed.
- Final repository cleanliness.
- Explicit approval gate before code changes.

## High-value checklist

See [`references/robot-state-machine-review.md`](references/robot-state-machine-review.md) for detailed failure patterns and reproduction guidance.

## Pitfalls

- Reviewing only the main worker while ignoring the producer or sync trigger.
- Assuming CLI `--row`/`--limit` scope propagates downstream without tracing it.
- Treating timeout handling as safe without checking the status before automatic rerun.
- Reporting exposed secrets verbatim instead of redacting and recommending rotation.
- Running import/compile commands that create tracked or untracked artifacts.
- Calling a dry-run safe without verifying that every path respects the flag.
- Offering a patch when the user explicitly requested analysis and prior approval.
