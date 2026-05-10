# Floors v1 — The Descent Has Texture

*First-stage design for the floor / enemy / boss layer of **Zenith Zero: Idle Descent**.*
*Same vibe as the skill tree work: neon cyberpunk · katana · magitech.*

---

## 0. Why this exists

The skill system is now deep. Three Paths, 13 archetypes, 5 levels each, ~53 Inflections, 7 Triads, 9 Fusions, 3 Path Signatures, Sutras, Awakening. The build side asks the player thousands of small questions per run.

The **fight side** asks one: *more floor = more HP*.

Today there are four enemy archetypes — `basic / fast / tank / elite` — gradually unlocked by floor (3, 5, 8). Every floor has the same shape: kill 10 enemies, advance, reroll a level-up. There are no boss floors, no floor archetypes, no enemy abilities, no "this floor wants you to play differently."

All that build variety has nothing to push against. A Hex-Cinder build, an Edge-Stance build, and a Daemon-Bandwidth build all face the same drip-fed enemy stream. The variety doesn't *test* anything.

Floors v1 fixes that. Three new layers, each shippable independently:

1. **Wave structure inside a floor** — a 30s shaped encounter, not a kill counter.
2. **Floor modifiers** — Slay-the-Spire-style global tweaks rolled per floor.
3. **Boss floors + enemy archetypes** — named encounters every 5 floors with mechanics that *require* the player's build to engage with them.

This doc is design-only. Build order in §6.

---

## 1. Wave structure — turn each floor into a 30-second story

### Today

`killsPerFloor = 10` ([game_state.dart](../../lib/game/state/game_state.dart)). The spawner emits one enemy every 1.8s with a slowly-shifting type mix. After 10 kills the floor advances. Pacing is flat — every second of the floor feels identical to every other second.

### Proposal — three phases per floor

Replace the flat kill counter with a phased wave:

- **Phase 1 — Trickle** *(0–10s)*
  3-4 basic/fast enemies, sparse spawn. Lets the player's auto-attack tick. Generates Bandwidth (Daemon) and Cinder (Hex) for the rest of the floor.

- **Phase 2 — Press** *(10–22s)*
  Sustained spawn — 7-9 enemies including 1-2 tanks. Dense enough to require AoE / chain / firewall lane. This is where the build *plays itself*.

- **Phase 3 — Crucible** *(22–32s)*
  One named event — see catalog below. The choice of event is rolled at floor entry so the player sees it on the HUD. Phase 3 is what gives a floor its **personality**.

Floor advances when Phase 3 resolves, not on a fixed kill count.

### Crucible event catalog

Each Crucible is a 6-10 second mini-encounter. Pool of ~8, rolled per floor, shown on the HUD as "Crucible: *Name*" so the player can prepare:

| Crucible | What happens | Tests |
|---|---|---|
| **Pressure** | One Tank spawns, +5 basics in support | AoE, finishers |
| **Hivebreak** | Continuous Fast spawn for 8s | Sustained DPS, slow effects |
| **Sigil Storm** | 4 Sigil-bearers (see §3) appear | Movement-aware play, Hex Cinder |
| **Eclipse** | All enemies frozen 2s, then sprint | Burst windows, Cinder-saved nukes |
| **Quiet** | No enemies for 8s; bonus gold drops if survived without taking damage | Cooldown management, breather |
| **Fractal Pack** | 2 Splinters (see §3) | Execute / Rupture builds |
| **Last Cant** | A Heretic Cant offer in the middle of the fight | Build pivots |
| **Boss Echo** | 1 mini-version of the next boss | Telegraph / preparation |

### Why this works

- Every floor has a **rhythm** — calm, press, climax. Idle-game players still feel the descent has a pulse.
- The Crucible name is **shown in advance**. Players who like to optimize get a target. Players who don't can ignore it; the auto-RPG handles it.
- Phase 1's gentle ramp gives the resource paths (Bandwidth, Cinder) time to build before they're needed in Phase 3. Currently Cinder full-meter moments happen at random; after this, they happen *when the floor wants them to*.

---

## 2. Floor modifiers — small global tweaks rolled per floor

> **Figure 1 — Floor entry card**

Slay-the-Spire-ish. At the start of each floor, **0–2 modifiers** are rolled. They show on the HUD as small chips next to the floor badge. They affect only that floor.

Modifiers live in three flavors:

- **Restrictions** — make a path harder (Bandwidth Black-out, Cinder Damp).
- **Pressures** — make enemies harder (Quickening, Solar Flare).
- **Boons** — give the player something (Echo Tide, Discount Kit).

Players can't reroll modifiers, but accepting a hard one **boosts that floor's gold drop by 50%**. Trade-off creates micro-decisions: do I push through Bandwidth Black-out for the gold, or play conservatively?

### Initial catalog (12)

| Modifier | Type | Effect |
|---|---|---|
| **Bandwidth Black-out** | Restriction | Daemon effects cost 2× Bandwidth this floor. |
| **Cinder Damp** | Restriction | Cinder fills at half rate this floor. |
| **Stance Stutter** | Restriction | Stance decays in 0.5s instead of 1s. |
| **Quickening** | Pressure | Enemies move 25% faster. |
| **Solar Flare** | Pressure | All enemies spawn with a one-hit shield. |
| **Veil of Ash** | Pressure | Damage numbers and HP bars hidden this floor. |
| **Heretic Tide** | Pressure | Floor 5 cant rule applies even if not on a multiple of 5. |
| **Cipher Storm** | Pressure | Random damage-type immunity rotates every 4s. |
| **Echo Tide** | Boon | Skills proc twice on the first 5 enemies of the floor. |
| **Discount Kit** | Boon | Heretic Cant offers don't deduct HP. |
| **Mana Bloom** | Boon | Cinder bar starts at 50% on floor entry. |
| **Glyph Cache** | Boon | Floor reward includes a guaranteed Inflection roll. |

### Why this matters

- **It makes floor pacing variable without redesigning the game.** Same enemies, different rules.
- **It surfaces the path resources.** A player who never thought about Bandwidth gets a floor where Bandwidth is the only thing they're thinking about. Surfaced systems = remembered systems.
- **It's expandable.** New modifiers ship as a single line in a list.

---

## 3. Boss floors + enemy archetypes

This is the heaviest layer and the one with the most identity payoff. Every 5 floors, instead of a normal Phase 3, a **Boss** appears. Boss floors are mechanically meaningful — they punish autopilot and reward the player who has been actually paying attention to their build.

> **Figure 2 — Boss roster ladder**

### Five bosses (floors 5, 10, 15, 20, 25)

| Floor | Boss | Telegraph | What it tests |
|---|---|---|---|
| 5  | **The Watcher**     | Stationary eye-satellite at top of arena. Spawns 3 Daemon-shielded adds every 6s. | AoE / Chain / Hex Cinder. Edge-only builds will be slow here. |
| 10 | **Glass Sovereign** | Fast, evasive, low HP, immune to splash damage. Phases through firewall lanes. | Edge focus / single-target. AoE-only Hex builds will struggle. |
| 15 | **Hivefather**      | Slow tank. Spawns drone broods every 8s. Drones are weak but numerous. | Sustained AoE / firewall / nova. |
| 20 | **Cipher Twin**     | Two linked enemies. One is Daemon-immune, the other Hex-immune. They phase-swap every 10s. | Dual-path builds. Pure Edge wins; pure Daemon or pure Hex stalls. |
| 25 | **The Architect**   | Final boss. All four phases — Watcher's adds, Sovereign's evasion, Hivefather's broods, Cipher's immunity rotation — compressed into one fight. | Everything. The "did your build actually come together" test. |

### Boss design rules

1. **Bosses telegraph their mechanic.** The player sees what's coming on floor entry — name, sprite, one-line description. No hidden gotchas.
2. **Bosses are beatable by every build.** A pure-Edge run can beat the Watcher; it just takes longer. Bosses *favor* certain builds; they don't *require* them.
3. **Boss kills drop a guaranteed reward.** Floor 5 = +50 embers; floor 10 = a Sutra mark of choice; floor 15 = a Codex preview; floor 20 = a free Fusion offer; floor 25 = a permanent meta unlock.
4. **Boss arenas dim the rest of the screen.** Visual signal that this fight is different.

### Six new enemy archetypes (used by bosses, floor mixes, and Crucibles)

| Enemy | Behavior | Counters |
|---|---|---|
| **Aegis**       | Reflects 50% of single-target damage back to the Nexus. | Chain, AoE (Nova, Firewall). Punishes Edge-Stance solo focus. |
| **Wraith**      | Phases out (untargetable) for 1s after taking damage. | DOTs (Snake), Frost (chill ignores phase), Sentinel (auto-targeting). |
| **Cinder-Drinker** | Heals from Hex damage. | Edge / Daemon. Hex-only runs must finish them with a non-Hex skill. |
| **Splinter**    | On death, divides into 2 small basics with 30% HP each. | Execute (Rupture), large AoE that finishes both halves. |
| **Sutra-bound** | Heals nearby enemies for 5%/s. Low HP. | Priority targeting (Mothership), Focus, Chain. |
| **Sigil-bearer** | On death, leaves a hazard glyph on the floor for 6s. Glyph damages the Nexus if it touches. | Movement-aware Frost slows; kill them at the edges. |

These enemies appear in normal Phase 2 / Crucible mixes from floor ~6 onward, ramping in frequency. They *teach* the player how to handle the bosses by showing the mechanic at smaller scale first.

### Why six, not twelve

Six new types + four existing = ten total. That's a manageable design surface and gives every Crucible / boss real composition variety. If late-game players burn through them, expand in v1.5.

---

## 4. The Codex — close the discovery loop

The Memory-Core already lists Archetypes, Fusions, Inflections. Add two tabs:

- **Bestiary** — every enemy type met for the first time. Shows sprite + counter-tip ("vulnerable to: Edge / DOT").
- **Crucibles** — the 8 Crucible events; greyed out until first encountered.

First-time entries pay embers, same as Inflections / Fusions. Codex 100% (Trinity Sigil from v2) now requires all enemy and Crucible discoveries too. Long-tail completion target stays the same shape — just deeper.

---

## 5. Floor reward structure

Currently the floor "reward" is a level-up offer. After Floors v1, scale it:

- **Normal floor** — one level-up offer (today).
- **Crucible-survived without damage** — bonus 25 gold.
- **Boss floor** — guaranteed reward (per §3) + level-up.
- **Floor multiple of 10 (post-boss)** — floor reward room: pick one of two boons (e.g., +5% max HP for run, or +1 reroll, or instant Inflection).

The reward variety mirrors the encounter variety. Idle-game retention is "what do I unlock next?" — make the answer more interesting than "another level-up."

---

## 6. Build order

Each item is shippable on its own. Heaviest items deferred so smaller wins land first.

1. **Boss floor scaffolding + The Watcher (floor 5)** *(3-4 days)*
   Just one boss to validate the loop. Telegraph, fight, reward. Everything else still works the way it does today.
2. **New enemy archetypes — Aegis, Splinter, Sigil-bearer** *(2-3 days)*
   The three most build-discriminating ones. Add to the spawn pool from floor ~6. Tune mix.
3. **Wave structure — Phases 1/2/3** *(1 week)*
   Replaces the kill counter with phase timer. HUD reflects current phase. Crucible is just "Phase 3 = a slightly bigger fight" for v1.
4. **Floor modifiers — top 6 only** *(3-4 days)*
   Bandwidth Black-out, Quickening, Solar Flare, Echo Tide, Mana Bloom, Glyph Cache. The most flavor-impactful. Hold the rest for follow-up.
5. **Crucible event catalog — full 8** *(1 week)*
   Now Phase 3 has real variety. Crucible name on HUD.
6. **Bosses 10 / 15 / 20** *(2-3 weeks)*
   Glass Sovereign, Hivefather, Cipher Twin. Each is its own design + tuning pass.
7. **Remaining enemies — Wraith, Cinder-Drinker, Sutra-bound** *(1 week)*
   The mix-extending types. Less load-bearing than the first three.
8. **Floor 25 — The Architect** *(2-3 weeks)*
   Final boss. Compresses all earlier mechanics. Ship last because it *requires* the rest of the system to mean anything.
9. **Codex bestiary + crucible tabs** *(2-3 days)*
   Polish stage; close the discovery loop.
10. **Floor reward room (post-boss multiple-of-10)** *(3-4 days)*
    Final item. Builds on the boss reward system from #1.

Total roadmap if shipped serially: ~10-12 weeks. Steps 1-4 land within a sprint and already dramatically change how a run feels.

---

## 7. Player-incentive checklist

Same five hooks from the skill tree work. Floors v1 hits each one:

| Hook | Floors v1 addition |
|---|---|
| Numbers go up | Boss kill rewards (embers, sutra marks); Crucible-clean gold bonus |
| Surprise / discovery | Bestiary; Crucibles hidden until met; modifier rolls |
| Visible identity | Boss telegraphs match the player's build identity (Edge vs Hex vs Daemon-favored bosses) |
| Meta progress | Boss rewards (especially F25 unlock); Codex enemy/crucible completion |
| Mastery achievement | "Beat F25 with a single-path build"; "Survive Solar Flare without damage" |

If a future v2 floor system doesn't hit at least one, it's probably noise.

---

## 8. What v1 deliberately avoids

- **No multiplayer raids, no shared bosses.** Single-player descent stays.
- **No procedural enemy generation.** Every enemy is hand-designed. 10 types is enough; quality > quantity.
- **No branching floor paths (Slay-the-Spire map).** The descent is linear; the variation is in encounter mix, not topology. Branching would change the game's identity.
- **No timed runs, no daily bosses, no leaderboards.** v1 is structural. Time-pressure systems can layer on top after.
- **No active player abilities for boss fights.** The auto-RPG loop holds; bosses are tested by *build composition*, not reflexes.

---

## 9. Open questions for playtesting

1. **Floor duration** — phases sum to ~32s. Is that the right pace? Idle-genre norm is 30-60s per "step." Faster bores; slower drags.
2. **Modifier frequency** — 0-2 per floor. Should later floors guarantee at least 1?
3. **Boss difficulty curve** — Watcher (F5) needs to be beatable on ~any build. Architect (F25) should require build commitment. The middle three need to feel proportional.
4. **Crucible "Last Cant"** — interrupting a fight with a Cant offer is a rhythm break. Might feel disruptive. Test whether players love it or hate it.
5. **Aegis reflection percentage** — 50% reflection of single-target damage. Could be 30% if Edge builds feel oppressed; 70% if Edge dominates anyway.
6. **Boss reward scaling** — does the F25 permanent meta unlock create a "first clear forever" cliff? May need to spread permanent unlocks across F10/15/20/25 so progression doesn't bottleneck on the hardest fight.
7. **Should bosses respawn as elites in later floors?** F25 player runs floor 30+ — does the Watcher come back as a regular enemy? Could be a fun callback but might cheapen the boss feel.

---

*End of v1 design — three phases · twelve modifiers · five bosses · six new enemies.*
