---
name: self-improve-minor-skill-creator
description: |
  Make a SMALL, controlled edit to an EXISTING skill as a continuous
  self-improvement step — and record it (version bump + CHANGELOG). Use when:
  (1) a session hit friction with a skill and you want to encode the fix
  ("the skill was almost right", "tweak the wording", "add a trigger keyword",
  "the workflow step was wrong"); (2) an environment or protocol change means a
  skill needs a minor update (a path moved, a flag renamed, a convention shifted);
  (3) you are running an autonomous self-improvement loop over your own skills;
  (4) you want to version-bump a skill or update its CHANGELOG.md after editing it;
  (5) someone asks to "self-improve", "iterate on", "refine", or "patch" a skill.
  The governing idea is a LEARNING RATE: every edit is one gradient step — make the
  SMALLEST change that removes the observed friction, then record it. NOT for
  creating a new skill from scratch, or for major restructures / breaking trigger
  changes / splitting a skill — those are large steps; hand them to `skill-creator`.
category: workflow
tags: [skills, self-improvement, versioning, changelog, continuous-improvement, learning-rate]
version: 1.1.0
---

# Self-Improving Minor Skill Editor

A skill is a living artifact. Once it exists, most of its life is **small edits** —
a clearer trigger keyword, a corrected step, a path that moved, a convention that
shifted. This skill is the discipline for making those edits *safely and
recordably*: change as little as possible, prove the change helped, version it.

For creating a skill from scratch, porting between harnesses, or restructuring one,
use **`skill-creator`**. This skill is its narrow, high-frequency complement: the
**patch** path, not the **author** path.

## The governing idea: a skill edit is a learning step

Treat the skill as a set of weights and each edit as **one gradient step** taken
from a **friction signal** (something a session got wrong, slow, or ambiguous). The
single most important parameter is the **learning rate** — *how big the edit is*.

| Learning rate | In ML | In skill editing | Symptom |
|---|---|---|---|
| **Too large** | Overshoots the minimum, oscillates, diverges | Rewriting a working skill to fix one gap; restructuring; broad reword | A skill that *was* triggering/working now regresses on tasks it used to handle. You "fixed" one session and broke three. |
| **Too small** | Crawls, never converges, underfits | Cosmetic tweak that doesn't actually remove the friction | Same friction recurs next session; you spent a cycle and the gap is still there. |
| **Right** | Steady descent toward the minimum | The *smallest* edit that demonstrably removes the observed friction — one gap, one targeted change | Friction gone, everything else byte-unchanged. |

The right edit is the **smallest diff that makes the friction signal go away** —
and nothing else. If you can't state, in one line, which friction this edit removes,
your step has no gradient — don't take it.

Four corollaries (full mapping in **[references/learning-rate.md](references/learning-rate.md)**):

- **Momentum — don't step on one noisy sample.** One occurrence may be noise. Wait
  for the same friction **2–3 times** (or a clear protocol/environment change that
  guarantees recurrence) before encoding. One data point rarely generalizes.
- **Annealing — steps shrink as a skill matures.** A new skill tolerates bigger
  edits; a mature, heavily-used one should only get small, surgical patches. The
  more a skill is depended on, the smaller your learning rate.
- **Regularization — penalize size.** Every added line is loaded into context on
  every trigger. Prefer the edit that *removes* ambiguity over the one that *adds*
  prose. Minimal change is not just safe, it's cheaper at inference time.
- **A big jump is a different algorithm.** If the right fix really is large
  (restructure, split, breaking trigger change), that's a *warm restart*, not a
  step — stop, and switch to `skill-creator`. See the gate below.

## The minor/major gate — is this even a minor edit?

Run this first. If **any** "Major" row matches, this is out of scope → `skill-creator`.

| | Minor (this skill) | Major (→ `skill-creator`) |
|---|---|---|
| **Trigger** | Add/adjust a keyword or phrasing in `description` | Change *what the skill is for*; rename it; narrow/broaden its whole surface |
| **Body** | Fix a wrong/ambiguous step; add one short clarification or decision row | Restructure sections; rewrite the workflow; change the skill's shape |
| **References** | Correct a fact; add one small reference file for a recurring gap | Split the body into a new reference architecture; reorganize `references/` |
| **Scripts** | Fix a bug; add a fallback for a new environment | Add a whole new capability / new script suite |
| **Scope** | One friction signal → one targeted change | Multiple unrelated changes batched together |

Rule of thumb: a minor edit is **one gap, touching one or two places, reviewable in
under a screen of diff.** More than that, or "while I'm in here…", means stop and
escalate. (Classifying the friction itself: `skill-creator`'s
`references/autonomous-improvement.md` has the signal→root-cause table.)

## The loop

```
Friction signal  →  Verify it recurs (momentum)  →  Gate: minor or major?
   → Locate the minimum edit  →  Apply it  →  Validate (replay the task)
      → Version bump + CHANGELOG entry  →  (snapshot is the rollback)
```

1. **Capture the signal.** What exactly went wrong — wrong trigger, wrong step,
   stale fact, missing edge case? Quote it. A signal you can't quote is too vague
   to step on.
2. **Check momentum.** Has this happened ~2–3×, or is there a definite
   protocol/environment change forcing it? If it's a one-off hunch, **record it in
   the skill's signal log and wait** — don't edit yet. The signal log is how
   momentum survives across sessions (you won't remember last week's friction): a
   `## Pending signals` section at the bottom of the skill's `CHANGELOG.md`, one
   line per observation (`date — friction quote — Nth occurrence`). When a line
   reaches ~3, it has momentum; promote it to an edit and move it up into a released
   changelog entry. A signal that never recurs gets pruned — that's the noise filter
   working.
3. **Gate.** Run the minor/major table. If major → `skill-creator`, stop here.
4. **Locate the minimum edit.** Classify the gap (trigger → `description`; workflow
   → body step; missing fact → reference; missing determinism → script) and find
   the *single* smallest place to change. Read it before you edit.
5. **Apply it.** One targeted `Edit`. Resist touching anything the signal didn't
   point at. Keep imperative voice and the surrounding style.
6. **Validate — replay.** Re-walk the original failing task against the edited
   skill. Did the friction disappear? Did anything that used to work change? If you
   can't show the friction is gone, the step didn't land — adjust or revert.
7. **Record.** Bump the `version:` and add one `CHANGELOG.md` line (rules below).
   An unrecorded edit is an untracked weight update — it makes the next person's
   (or session's) gradient estimate wrong.
8. **Rollback is free.** The skill manager auto-snapshots on install/edit
   (`~/.skills`-managed skills land copies under `.snapshots/`); a bad step is a
   restore, not a panic. Knowing rollback is cheap is what lets you keep steps small
   and frequent.

## Worked example — one full step

> Skill `auth-cli-setup-runbook`, currently `1.3.0`. Over three sessions the agent
> failed to trigger it when users said *"rotate the service credentials"* — the
> `description` listed "onboard a service" but never "rotate". Each miss is logged
> as a pending signal.

1. **Signal (quoted):** *"can you rotate the prod API key for the billing service"*
   → skill didn't fire; agent hand-rolled the steps.
2. **Momentum:** signal log shows this is the **3rd** occurrence → has momentum.
3. **Gate:** adds a keyword to `description`, no shape change → **minor** (PATCH).
4. **Minimum edit** — one line in `description`, nothing else:
   ```diff
   - Use when onboarding a service — clone, configure the four JSON files, run ./setup,
   + Use when onboarding a service OR rotating its credentials — clone, configure the
   +   four JSON files, run ./setup, rotate keys,
   ```
5. **Validate — replay:** re-pose *"rotate the prod API key…"*; the skill now
   triggers. Re-check an existing onboarding phrasing still triggers (no regression).
6. **Record:** bump `1.3.0 → 1.3.1`; CHANGELOG line:
   `PATCH: description — add "rotate credentials" trigger (missed 3×).` Move the
   pending-signal line out of `## Pending signals` into the released entry.

Total diff: two lines of `description` + one frontmatter digit + one changelog line.
That's a correctly-sized step — the friction is gone and nothing else moved.

## Versioning + CHANGELOG.md

Minor edits are only safe *because they are recorded*. Give each self-improving
skill a `version:` in frontmatter and a `CHANGELOG.md` in its directory.

Semver, read through the learning-rate lens — **the bump size IS the step size:**

| Bump | Meaning | Examples | In scope here? |
|---|---|---|---|
| **PATCH** (`x.y.Z`) | Clarify, correct, retune — no behavior change to *what triggers or what it does* | Typo, reword for clarity, add/adjust a trigger keyword, fix a stale path or line ref, tighten a step | ✅ the common case |
| **MINOR** (`x.Y.0`) | Additive — new capability that doesn't break existing use | New reference file, new decision row, a new optional step, a new script with a fallback | ✅ at the upper edge |
| **MAJOR** (`X.0.0`) | Breaking — restructure, rename, change the trigger surface or core workflow | Rewrite the body, split the skill, repurpose it | ❌ → `skill-creator` |

If you ever reach for a MAJOR bump, that's the signal your learning rate is too
high for this skill — stop and escalate. The version number is a built-in governor.

**CHANGELOG.md format** (newest first; one line per step — full template in
**[assets/CHANGELOG.template.md](assets/CHANGELOG.template.md)**):

```markdown
# Changelog — <skill-name>

## [1.2.0] — 2026-06-08
- MINOR: add references/troubleshooting.md for the 403-on-refresh case (recurred 3×).

## [1.1.1] — 2026-06-07
- PATCH: description — add "rotate credentials" trigger; skill was missing the rotate-flow asks.
```

Each entry states **what changed** and, briefly, **the friction it removes** — the
"why" is the gradient that justified the step. A skill with no `version:` yet starts
at `1.0.0` on its first recorded edit (add the field; that itself is the first
CHANGELOG line). Deeper rules + how this rides the snapshot safety net:
**[references/versioning.md](references/versioning.md)**.

## Anti-patterns

| Anti-pattern | Why it fails | Instead |
|---|---|---|
| "While I'm in here…" — batching unrelated edits | Each is an un-gradiented step; you can't tell which one regressed anything | One signal, one edit, one changelog line |
| Rewriting the skill to fix one gap | Learning rate too high — destabilizes a working artifact | Smallest diff that removes *this* friction |
| Editing on a single occurrence | No momentum — fitting noise, won't generalize | Wait for ~2–3×, or a definite protocol/env change |
| Silent edit, no version/changelog | Untracked weight update; next reader can't trust history or roll back | Always bump + log, even for a typo |
| Cosmetic tweak that doesn't move the needle | Learning rate too low — friction recurs next session | Validate by replay; if the gap survives, the step didn't land |
| Minor-editing your way into a restructure | You're running the wrong algorithm in small steps | Recognize the major change, hand to `skill-creator` |

## Reference files

- **[references/learning-rate.md](references/learning-rate.md)** — the full
  ML-analogy mapping (gradient/momentum/annealing/regularization/overfitting/warm
  restart) and how to read each as an editing rule. Read when deciding *how big* a
  given edit should be, or when a "fix" keeps regressing other tasks.
- **[references/versioning.md](references/versioning.md)** — semver-for-skills bump
  rules, the `version:` frontmatter field, CHANGELOG conventions, and how versioning
  composes with the skill-manager auto-snapshot rollback. Read when recording an edit.

## Related skills

- **`skill-creator`** — authoring, porting, restructuring, and the general
  friction→fix classification (`references/autonomous-improvement.md`). Every MAJOR
  change and every from-scratch skill goes there. This skill is the small-step path.
- **`skill-manager`** — the local `skills` CLI: snapshots, `skills open <name>`,
  `skills doctor`/`audit`. The mechanical layer under the rollback and edit steps.
