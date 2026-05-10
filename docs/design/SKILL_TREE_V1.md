# Skill Tree v1 — From Pool to Tree

*Original foundation pass for the skill system in **Zenith Zero: Idle Descent**.*
*Catalog consolidation · anti-snowball weights · deliberate synergies · gated tiers · level-5 evolutions.*

---

## 0. Why this exists

A first-pass read of the skill code revealed four structural issues that compound into a flat, snowball-prone progression curve:

1. The catalog has **127 named skills but only 13 mechanical archetypes** — the rest are cosmetic reskins ([skill_catalog.dart:171-334](../../lib/game/state/skill_catalog.dart), `_skills(...)` helper at line 335).
2. The level-up offer pool gives **owned-archetype skills 4× weight over new ones** ([game_state.dart:696-698](../../lib/game/state/game_state.dart)), so once a player picks Chain they keep seeing Chain.
3. **Synergies are essentially absent** — only Frost+Shatter ([enemy.dart:456-466](../../lib/game/components/enemy.dart)) and Rupture's execute mark ([enemy.dart:423-431](../../lib/game/components/enemy.dart)) cross archetypes. Everything else is isolated stat application.
4. There is **no skill tree** — no prerequisites, no evolutions, no archetype unlocks. The "tree" is a flat weighted random draw with meta-knobs (lock / banish / reroll / widerPick / rareCadence / prePick).

This document is design-only. No code changes are proposed; the goal is a clear set of recommendations for an implementation pass.

---

## 1. Catalog: collapse the cosmetic bloat or commit to differentiation

The current `_skills(archetype, [...10 names])` pattern produces 10–15 skills per archetype that are **mechanically identical**. The picker rolls between, e.g., "Neon Katana Chain" and "Monowire Arcana" — same Chain effect, different sticker. Worse, archetype effect calculations sum levels across all variants ([game_state.dart:702-709](../../lib/game/state/game_state.dart)), so the cosmetic name is gameplay-invisible.

**Recommendation: pick a lane.**

- **Lane A — Consolidate to one skill per archetype.** Drop from 127 → 13. The picker offers the 13 archetypes directly, each with a clear identity and 5 levels. This is the smallest change with the biggest clarity win. Lose: cosmetic variety. Gain: every offer is a real choice.
- **Lane B — Keep the names but make variants mechanically distinct.** Each cosmetic name within an archetype gets a *modifier* (e.g., Chain variants differ in jump count vs. arc damage vs. seek behavior). Costs 5–10× the design and balance work but turns the catalog into actual depth. Recommend only if the team wants a "build crafting" identity.

**Lane A is the recommended default.** If flavor matters, retain *one* alt cosmetic per archetype (13 + ~13 evolutions, see §4) rather than 10.

A side issue: descriptions in [skill_catalog.dart:74-167](../../lib/game/state/skill_catalog.dart) are vague metaphor ("cadence improves", "spellblade cuts through whole packs") but the code applies concrete numbers. Quantify the descriptions ("+12% attack speed", "+1 chain target") so picks are informed. The numbers already exist in [game_state.dart:102-189](../../lib/game/state/game_state.dart) — exposing them is a description rewrite, not a balance change.

---

## 2. Offer weights: add anti-snowball pressure

`_offerWeight` ([game_state.dart:696-698](../../lib/game/state/game_state.dart)) returns weight 4 for owned skills and 1 for unowned. With ~13 archetypes and that bias, a player who has picked 3 archetypes early will see those archetypes ~12× more often than any of the remaining 10. `rareCadence` (every-5th-pick guarantee) is the only counter and only fires once every five level-ups.

**Recommendation: replace the static 4×/1× with a saturating curve.**

- Weight should *peak* at a player's first or second pick of an archetype (rewards commitment) and then *decay* toward parity as the archetype approaches saturation. Concrete shape: `weight = 1 + 3 * exp(-archetypeLevel / 4)`. First pick boosts the archetype; by archetype-level 8 it's back to baseline.
- Add a **cooldown-on-recently-offered**: if archetype X was offered last level-up, halve its weight this level-up. Smooths the "I keep seeing the same thing" feel.
- Make `rareCadence` ([game_state.dart:625-635](../../lib/game/state/game_state.dart)) the *floor*, not a special event: every 3rd level-up, force one card to be a never-owned archetype (when one exists). Small change, large diversity payoff.

**Soft cap on archetype level:** damage curves currently scale linearly (`1 + 0.08*level` for Focus, etc., [game_state.dart:103-126](../../lib/game/state/game_state.dart)). Consider tapered scaling past archetype level 8 (e.g., level 9–15 contributes at half rate). Keeps stacking viable but reduces the "one-archetype solo carry" outcome.

---

## 3. Synergies: pair archetypes deliberately

The 13 archetypes naturally fall into roles. Designing *one* explicit cross-archetype synergy per pair gives the build space real shape. Concrete proposals (each implementable as a single conditional in the relevant component):

| Pair | Synergy | Rationale |
|------|---------|-----------|
| Frost + Rupture | Chilled enemies count as "wounded" for rupture's execute threshold | Pairs the slow / control archetype with the finisher archetype. |
| Chain + Nova | Chain jumps trigger a mini-nova at each hop (smaller radius) | Turns chain from line-clear into AoE clear. |
| Meteor + Firewall | Meteor impacts leave a temporary firewall lane | Two slow-cadence skills become one combined zone-control tool. |
| Sentinel + Barrage | Sentinel blade cooldown scales with hero attack rate | Lets attack-speed builds pull double duty. |
| Bounty + any execute | Execute kills (Rupture proc, Snake bite, Mothership crash) drop bonus gold | Makes Bounty interact with kill-pattern builds, not just raw kill count. |
| Mothership + Summon | Drones inherit summon damage scaling, summons inherit drone count | Two minion archetypes become one "swarm" identity. |

Today only Frost+Shatter (keystone-locked) and Rupture's mark are real cross-archetype effects. Adding 5–6 synergies turns the picker into a *combo* decision, which is the single highest-leverage change for build depth.

**Implementation note:** centralize synergy checks in something like `bool hasSynergy(Pair p)` derived from `_archetypeLevel`. Keeps logic out of components and makes balancing one place.

---

## 4. Real skill-tree structure: gated unlocks and evolutions

There is no prerequisite system today. Every skill is available from floor 1, drawn from the same pool. A "tree" implies branching choices with consequences. Two layers to add, in order of cost:

### Layer A — Archetype tiers (small change, immediate structure)

Group the 13 archetypes into **starter / specialist / capstone** tiers:

- **Starter (always offered)**: Chain, Nova, Barrage, Focus — the four baseline damage archetypes.
- **Specialist (unlocked at archetype-level 5 anywhere)**: Frost, Rupture, Sentinel, Firewall, Bounty.
- **Capstone (unlocked once a specialist hits level 5)**: Meteor, Mothership, Snake, Summon — the heavy / late-fantasy options.

Effect: early runs feel learnable, late runs feel earned. The pool naturally narrows then widens, killing the early-game noise of being offered Mothership at floor 2.

### Layer B — Evolutions at level 5 (bigger change, higher payoff)

Today level 5 says "Big upgrade" in flavor text but is just a stat bump. Replace it with a **branching evolution choice** when an archetype hits level 5:

- Chain → *Chainstorm* (more jumps, less damage per jump) **or** *Tetherblade* (one target, massive damage, long arc).
- Nova → *Pulse Reactor* (faster smaller novas) **or** *Singularity* (slow large novas that pull enemies in).
- Frost → *Glacier* (deeper slow, stacking) **or** *Shatter Bloom* (chilled enemies explode on death — fold today's Shatter keystone into this).
- Mothership → *Carrier Armada* (more drones) **or** *Dreadnought* (one massive drone with high HP).

This is what makes a "skill tree" feel like a tree — the level-5 fork is a permanent identity decision. It also gives the existing keystone system ([meta_catalog.dart:36-146](../../lib/game/state/meta_catalog.dart)) a natural home: keystones become *evolution biases* that nudge you toward one branch.

### Layer C — Cross-archetype unlocks (optional, longest reach)

For dedicated players, unlock *fusion skills* when two specific archetypes hit level 5:

- Chain L5 + Nova L5 → unlocks *Resonance Cascade* (passive: every 5th chain hop detonates).
- Meteor L5 + Firewall L5 → unlocks *Cinder Rain* (firewall-marked enemies attract meteors).

Defer until Layers A and B are in. Mention here because it answers "where does the system go after the redesign."

---

## 5. Critical files (for whoever implements later)

- [lib/game/state/skill_catalog.dart](../../lib/game/state/skill_catalog.dart) — archetype enum, definitions, descriptions. Touch points: §1, §4 (evolutions).
- [lib/game/state/game_state.dart](../../lib/game/state/game_state.dart) — `_offerWeight` (line 696), `_rollUpgradeChoices` (line 615), archetype effect application (lines 102-189), `_archetypeLevel` (line 702). Touch points: §2 (weight curve), §4 (gating logic), description quantification.
- [lib/game/state/meta_catalog.dart](../../lib/game/state/meta_catalog.dart) — keystones. Touch point: §4 layer B (re-home keystones as evolution modifiers).
- [lib/game/components/enemy.dart](../../lib/game/components/enemy.dart) — existing synergy hooks (Frost+Shatter at 456, Rupture mark at 423). Touch point: §3 (add new synergy proc points).

## 6. Verification (when changes are made)

This plan recommends no code changes. If the implementation lands later, the verification path is:

1. **Snowball test (§2)** — run 20 simulated runs picking the highest-weighted offer each level. Track `archetypeLevel` distribution at floor 30. Pre-fix: heavy concentration in 2-3 archetypes. Post-fix: should see 5+ archetypes touched on average.
2. **Tier-gate test (§4 Layer A)** — confirm specialist / capstone archetypes don't appear in offers until prerequisite met. Inspect `_rollUpgradeChoices` candidates list at floor 1 vs. floor 10.
3. **Synergy test (§3)** — when both archetypes of a pair are at level ≥1, confirm the synergy proc fires (visual or log).
4. **Evolution test (§4 Layer B)** — trigger a level-5 pick of any archetype, confirm a fork dialog appears, confirm permanent state on selection.
5. **Live preview** — keep the Flutter web preview running and walk through floors 1–10 to feel the pacing change.

---

## 7. What v1 deliberately defers

- **Layer C cross-archetype fusions.** Mentioned above for direction-setting only. Layers A and B should land first; Layer C becomes its own design pass.
- **Per-skill identity (Lane B).** Cosmetic-rich variants are deferred in favor of the simpler 13-skill catalog.
- **Path / school grouping.** No higher-level structure than starter / specialist / capstone tiers in this pass.
- **New archetypes.** The 13 stay; the pass restructures, doesn't expand.
- **Active player abilities.** Auto-RPG loop holds.

---

*End of v1 — the foundation that everything else builds on. Layer C became Fusion Forms in v2; the path / school grouping became EDGE / DAEMON / HEX in v2.*
