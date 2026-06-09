# The Learning-Rate Discipline for Skill Edits

The full machine-learning analogy behind "make the smallest edit." Read when
deciding *how big* a given edit should be, or when a fix keeps regressing other
tasks. Each ML concept maps to a concrete editing rule.

## Table of contents

1. The objective being minimized
2. Gradient — the friction signal is the direction
3. Learning rate — the edit magnitude (the core knob)
4. Momentum — don't step on one noisy sample
5. Annealing — shrink steps as a skill matures
6. Regularization — penalize size
7. Overfitting — the central failure mode
8. Warm restart — when a step should be a rewrite
9. Putting it together — picking a step size

## 1. The objective being minimized

A skill's "loss" is the **friction it leaves on the tasks it should serve**: wrong
or missed triggers, wrong steps, stale facts, ambiguity that makes the agent guess,
bloat that wastes context. You never see the loss surface directly — you only get
**samples** (individual sessions) that reveal friction at one point. Every editing
rule below follows from that: you are doing stochastic optimization on a surface you
can only probe one session at a time.

## 2. Gradient — the friction signal is the direction

A friction signal tells you *which way* to move: a missed trigger points at the
`description`; a wrong step points at that body step; a repeatedly-searched fact
points at a missing reference. **No signal → no gradient → don't step.** "This could
be better" with no observed failure is a zero gradient; editing on it is noise
injection. Quote the friction before you touch the file — if you can't, you don't
have a direction.

## 3. Learning rate — the edit magnitude (the core knob)

The learning rate is *how much of the skill you change in one step*. It is the
single parameter that most determines whether self-improvement converges or
diverges.

- **Too high** (big edit): you overshoot. The edit fixes the sampled session but
  moves the skill far enough that it now misbehaves on tasks it used to handle —
  the classic oscillate/diverge. Rewriting a whole section to fix one ambiguous line
  is a high learning rate.
- **Too low** (cosmetic edit): you underfit. The change is too small to actually
  move the friction; the same failure recurs next session. A reworded sentence that
  doesn't resolve the ambiguity is a near-zero step.
- **Right**: the smallest diff that makes *this* friction signal vanish and leaves
  every other behavior unchanged. Measured in lines, the right step is usually 1–10.

Operational test: after the edit, can you name the friction it removes **and**
confirm nothing else changed? If the diff touches things the signal didn't point at,
your rate is too high.

## 4. Momentum — don't step on one noisy sample

Stochastic gradients are noisy: one session's friction may be a fluke (an
 unusual phrasing, a user typo, a one-off environment hiccup). Momentum averages
over recent gradients before committing to a direction. The editing rule: **wait for
the same friction ~2–3 times, or a definite protocol/environment change that
guarantees it recurs, before encoding a fix.** Encoding a single occurrence overfits
to noise and bloats the skill with guidance that may never fire again. Keep a note
of one-offs; promote them to edits only when they repeat.

## 5. Annealing — shrink steps as a skill matures

Learning-rate schedules start large and decay. A skill follows the same curve:

- **Young / lightly-used skill** — bigger steps are fine; it's still finding its
  shape, little depends on it, regressions are cheap.
- **Mature / heavily-depended-on skill** — anneal toward small, surgical patches.
  Each change risks more downstream tasks, so the learning rate should be lower. The
  more a skill is trusted, the more conservative the edit.

A skill that's been stable for many sessions and suddenly "needs" a big edit is
usually a sign the change belongs in a *new* skill or a `skill-creator` restructure,
not a large step on the mature one.

## 6. Regularization — penalize size

L1/L2 penalties push models toward smaller weights to generalize better. The skill
analogue: **every added line costs context on every trigger** and risks drift. So
penalize additions — prefer the edit that *removes* ambiguity or *replaces* a wrong
line over the one that *appends* explanation. A good minor edit often leaves the
skill the same length or shorter. "Could I delete instead of add?" is the
regularizer.

## 7. Overfitting — the central failure mode

Overfitting = fitting the training sample (one session) so tightly that you lose
generality. In skills it looks like: a hyper-specific instruction added for one
weird case that now fires for everyone; a trigger keyword so narrow it only matches
the exact phrasing of the session that prompted it; a workflow contorted around a
single user's request. The defenses are the rules above — momentum (more samples),
regularization (smaller edits), annealing (caution on mature skills). When in doubt,
generalize the *minimum* needed and no further.

## 8. Warm restart — when a step should be a rewrite

Sometimes the loss surface has a better basin that no small step can reach — the
skill's structure itself is wrong. That's a **warm restart**: you don't take a
bigger gradient step, you reinitialize. In skills, that's a restructure, split,
rename, or repurpose — explicitly **out of scope for minor editing**. Recognizing
"no small step fixes this" is itself a skill: stop stepping, hand to `skill-creator`.
Symptoms you need a restart, not a step: you've taken several minor edits at the same
spot and friction persists; the fix requires changing *what the skill is for*; the
edit would touch most sections at once.

## 9. Putting it together — picking a step size

For a given friction signal, the step size is the smallest edit such that:

1. it **has a gradient** — a quoted friction it removes (no fix-on-a-hunch);
2. it has **momentum** — the friction recurred, or a protocol/env change forces it;
3. it is **regularized** — minimal added surface, delete-over-add where possible;
4. it is **annealed** — proportionally smaller the more mature/depended-on the skill;
5. it **doesn't overfit** — generalizes only as far as the evidence supports;
6. it is **not a warm restart in disguise** — if it is, escalate to `skill-creator`.

Then: apply, **validate by replaying the original task**, and record (version +
changelog). Validation is your loss measurement after the step — skip it and you're
optimizing blind.
