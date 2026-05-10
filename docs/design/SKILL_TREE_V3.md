# Skill Tree v3 — Depth Per Skill

*Next-stage design for **Zenith Zero: Idle Descent**.*
*Builds on v2 (Three Paths) — same vibe: neon cyberpunk · katana · magitech.*

---

## 0. Where v2 left us

The v2 work landed cleanly: EDGE/DAEMON/HEX paths, four-tier path apex effects, nine Fusion Forms, five Heretic Cants, the Sigil Matrix, the Codex, Sutras, and Awakening. The skill *catalog* now has clear identity and clear progression.

But the catalog is also **lean**: 13 archetypes × 5 levels = 65 atomic decisions per run. Compared to a Hades or Vampire Survivors, that's small. The v2 work bought us **breadth** (paths, fusions, cants, codex). v3 buys **depth**: how interesting is each individual pick?

This doc proposes three new systems that multiply per-pick variety without adding new archetypes:

1. **Inflections** — per-level mini-mods, picked at every level-up.
2. **Triads** — named three-archetype synergies that sit between Fusions and base synergies.
3. **Path Signatures** — Stance · Bandwidth · Cinder — unique resources per path that change how each path *plays*.

It also closes three small loose ends from v2.

This doc is design-only. Build order in §5.

---

## 1. Closing v2 loose ends

Three small items from the v2 doc that didn't land in the v2 commit. Worth ticking off before starting v3 work — they're cheap and they finish a story players can already see half of.

### 1a. Sutra perks at marks 5 / 10 / 25

Today, each Sutra mark gives a flat +1% to that archetype's primary stat. The v2 plan promised milestone perks — those are missing.

Suggested per-archetype shape (one perk per milestone):

| Mark | Archetype example | Perk |
|---|---|---|
| 5  | Chain     | Chains can never miss. |
| 5  | Frost     | Slow stacks once before decaying. |
| 10 | Mothership| Drones respawn 50% faster. |
| 10 | Sentinel  | Blades pierce the first enemy they hit. |
| 25 | Nova      | Novas leave a 1s afterglow that re-pulses. |
| 25 | Bounty    | Gold drops compound (each kill within 2s adds 5%). |

Pattern: 5 = small quality-of-life, 10 = noticeable mechanical change, 25 = passive flourish that visibly changes how the skill *plays*. Builds anticipation — at Sutra 4 the player is already counting.

### 1b. Near-orbit offer weighting

The current `_offerWeight` (`1 + 5*level*exp(-level/1.5)`) is a clean commitment curve, but it ignores synergy. Add a small multiplier (~×1.5) when the archetype's partner is owned and the archetype itself isn't yet picked — i.e., the player is **one step from a synergy unlock**.

Effect: when you grab Frost, the picker leans slightly toward offering Rupture next time. The system feels like it noticed your build. Doesn't override the commitment curve — just nudges.

Implementation hint: a new helper `bool _completesSynergyIfPicked(String id)` reading the existing synergy gates. Multiply weight if true. Five lines.

### 1c. Trinity Awakening rings on the Nexus core

Per-path Awakening already grants a flag. The v2 doc described a colored ring on the Nexus core per Awakened path (max three = Trinity Awakening). If the visual isn't present, add three concentric ring sprites tinted to path colors, drawn around the Nexus when the corresponding `_awakenings[path] == true`.

Small art lift, large player-pride payoff. Players show their Nexus in screenshots. Make the screenshot tell the story.

---

## 2. Inflections — per-level mini-mods

> **Figure 1: Inflection fork** — at every level-up of an owned skill, two small mini-mods are offered alongside the base bump. The player picks one. Run-to-run variation multiplies without inflating the catalog.

### The mechanic

Right now, picking *Chain Lv 2* always does the same thing: same stat bump, same effect text. Replace this with:

- The **base bump** still happens (unchanged).
- The pick screen also presents **two random Inflections** drawn from a small per-archetype pool.
- The player picks one Inflection, which attaches to the skill for the rest of the run.
- Inflections persist across levels — by Lv 5 you've stacked four Inflections on the same skill, each making it slightly different.

Inflections are **never offered in isolation**. They're a sub-decision tied to a skill pick. The player still picks "Chain Lv 2"; the Inflection is which flavor of Lv 2.

### Why this matters most

- **Per-skill variety multiplies.** With 5 levels and ~6 Inflections per archetype, a single skill has ~7,776 possible build paths (6⁴ ordered Inflection stacks × 5 base levels, allowing repeats and order). Most of those are noise, but enough are flavorful to make every Chain run feel different.
- **No new archetype design work.** Inflections reuse existing skill code paths — they're toggles on the existing math.
- **The picker becomes interesting on level 1.** Today, the only meaningful pick decision happens between archetypes. Inflections give every level-up real choice.

### Catalog shape (~6 per archetype, ~78 total)

Inflections should fall into three flavors so each skill draws a balanced set:

- **Stat-shift** — change the math (more crit, less radius; faster cooldown, less damage).
- **Trigger-shift** — change *when* it fires (on-kill, on-low-HP, on-stagger).
- **Synergy-shift** — change which other archetypes it pairs with (this is where Inflections cross into Triad territory — see §3).

#### Examples — Chain (Edge)

| Inflection | Effect |
|---|---|
| **Volatile** | Final jump in a chain crits. |
| **Greedy** | Gold drops scale with chain length. |
| **Quiet Edge** | Chains don't trigger Hex synergies, but jump twice as fast. |
| **Echoblade** | First jump repeats once. |
| **Tetherbias** | -1 jump count, +50% damage per jump. |
| **Glyph-tagged** | Each jump inscribes a sigil node (synergy with Hex Mage tier). |

#### Examples — Frost (Hex)

| Inflection | Effect |
|---|---|
| **Brittle** | Chilled enemies take +20% from Edge skills. |
| **Lingering** | Chill duration doubles, slow halved. |
| **Frostbite** | Chilled enemies tick for tiny damage. |
| **Cracked Glass** | First hit on a chilled enemy ignores armor. |
| **Coldfront** | Chill propagates between adjacent enemies. |
| **Snowblind** | Chilled enemies miss attacks 10% of the time. |

#### Examples — Mothership (Daemon)

| Inflection | Effect |
|---|---|
| **Carrier-class** | -1 drone count, drones do double damage. |
| **Swarm-class** | +2 drones, drones do 60% damage each. |
| **Reactor-bias** | Drones boost firewall lane intensity. |
| **Flare** | Drones explode on death for AoE. |
| **Network-link** | Drones share kill-credit with bounty for streak stacks. |
| **Glitchsigil** | Drones occasionally fire a hex bolt (cross-path nudge). |

### How they appear in the picker

The pick screen now shows three skill cards (as today) — but if the player owns the skill being offered, the card has a **small "Inflection" sub-row** under the description with two glowing micro-cards. Picking the skill *and* selecting an Inflection happens as one tap. New skills (Lv 0 → 1) have no Inflection yet; their first Inflection arrives at Lv 1 → 2.

### Inflection rarity

Most Inflections are **common** — small flavorful tweaks. A few per archetype should be **rare** (gold-bordered, ~1 in 10 rolls) and represent build-defining mods. The rare ones go in the Codex.

### Codex integration

Add an "Inflections" tab to the Memory-Core. ~78 entries to discover. Each first-time Inflection pick awards a small ember bonus, same as Fusion discoveries.

---

## 3. Triads — three-archetype synergies

> **Figure 2: Triad constellation** — three archetype nodes connected at vertices; the named Triad sits at the centroid. Pure-path triads (all three archetypes from one path) reward dedicated builds; mixed triads reward eclectic ones.

### The mechanic

When you own three specific archetypes at level ≥1, a named **Triad** activates. Each Triad has a unique effect distinct from any individual skill or Fusion. Triads are **passive** — they trigger as long as the conditions hold — and are logged in the Codex.

This sits between today's pair-synergies and Fusions. Where Fusions are *picked* (added to the slot pool), Triads are *unlocked* (passively granted by your composition). They reward thoughtful build construction without using a pick slot.

### The six initial Triads

Three pure-path Triads (reward focus) + three mixed-path Triads (reward breadth):

#### Pure-path

| Triad | Path | Archetypes | Effect |
|---|---|---|---|
| **Quicksilver** | Edge-pure | barrage + chain + focus | Each barrage hit reduces chain cooldown by 0.5s; focus damage stacks per chain hop. |
| **Sovereign Network** | Daemon-pure | mothership + firewall + meteor | Drones patrol firewall lanes; meteor impacts spawn a drone on the lane. |
| **Spirit Choir** | Hex-pure | nova + frost + summon | Summons emit nova pulses on attack; frost-shattered enemies under a summon-pulse spawn ice meteors. |

#### Mixed-path

| Triad | Archetypes | Effect |
|---|---|---|
| **Storm Triad** | chain + nova + frost | Chain hops chill; novas detonating inside chilled clusters become ice storms. |
| **Iron Cathedral** | sentinel + firewall + rupture | Sentinel blades patrol firewall lanes; lane-trapped enemies are auto-executed at 30% HP threshold. |
| **Hellgate Choir** | snake + summon + firewall | Summoned spirits ignite snakes on contact; snakes hatch directly from firewall edges. |

### Discovery

Triads are **hidden in the Codex** until first triggered ("???") with the path-color-mix of the requirement showing as a hint. First trigger awards embers and reveals the entry. Players will reverse-engineer the triggering combos from the path-color hint — that's the discovery loop.

### Why six, not more

Six is enough to feel like a system without becoming a balance nightmare. Single-path triads (3) and mixed (3) cover the design space. If late-game players burn through them, expand to 12 in a v3.5 patch — the framework supports it.

---

## 4. Path Signatures — unique resource per path

> **Figure 3: Path resource HUD strip** — three small bars under the Nexus health bar, one per path. Each bar visualizes a different resource: Stance pips for Edge, Bandwidth fill for Daemon, Cinder meter for Hex.

This is the **biggest** change in v3 and the one with the most identity payoff. Paths today are tags — they group archetypes, drive tier bonuses, and color the matrix. They don't *change how the path plays*. v3 fixes that.

### EDGE — Stance

Successive hits on the same target build a **Stance counter** (1–5). Stance decays after ~1s without a hit. At any time, the player's Edge skills can spend Stance:

- 3 Stance: next blade strike crits.
- 5 Stance: next blade strike triggers a path-tier-scaled cleave.

Stance encourages **target focus** — instead of spraying Edge effects across the screen, the player commits to single targets. This is the sword fantasy made mechanical.

### DAEMON — Bandwidth

A passive **Bandwidth pool** (max 100, refills from kills at ~5 per kill). Daemon effects *consume* Bandwidth:

- Mothership drone spawn: 10 Bandwidth.
- Firewall lane: 20 Bandwidth.
- Meteor strike: 30 Bandwidth.

If Bandwidth is empty, Daemon effects continue at 50% rate. The player learns to watch the meter — when the network is overloaded, AoE goes quiet.

This makes Daemon a **management** path. Skilled play looks like timing meteor drops to coincide with full Bandwidth, not autopilot.

### HEX — Cinder

A meter that **builds from any kill** (cosmetically: ember sparks rise to the Nexus). At full (100), the next Hex skill cast is **doubled** for free — a Nova becomes a screen-wide pulse, a Frost becomes a freeze, a Summon spawns two spirits.

After firing, Cinder resets to zero and rebuilds.

This makes Hex a **pacing** path. The player learns to save Cinder for boss waves and big swarms, then unleash the magic when it matters most.

### How the three feel different

| Path | Mode | Player verb |
|---|---|---|
| EDGE | Stance | Focus and *commit*. |
| DAEMON | Bandwidth | Manage and *time*. |
| HEX | Cinder | Save and *unleash*. |

Three paths, three completely different play loops. A run committed to Edge feels nothing like a run committed to Hex — even if the underlying engine is the same.

### HUD reflection

A new compact widget under the Nexus health bar, showing only the resources the player has unlocked (i.e., owns at least one skill in that path). Stance shows as five pips, Bandwidth as a cyan-magenta gradient bar, Cinder as a gold-violet meter.

---

## 5. Build order

Each item is shippable on its own.

1. **Sutra perks at 5/10/25** *(½ day)* — close v2.
2. **Near-orbit offer weighting** *(½ day)* — close v2.
3. **Trinity Awakening rings** *(1 day, art-light)* — close v2.
4. **Triads** *(2–3 days)* — high-impact, low surface area; ship before Inflections so Inflections can reference Triad gates.
5. **Inflections (commons only)** *(1–2 weeks)* — full Inflection system with ~4 commons per archetype. Hold rares for a follow-up patch once balance settles.
6. **Inflections (rares + Codex tab)** *(3–4 days after #5)* — completes the long-tail discovery loop.
7. **Path Signatures: HUD widget** *(2 days)* — meter visuals only, no mechanical effect yet. Ship to surface the concept.
8. **Path Signatures: Stance / Bandwidth / Cinder mechanics** *(2–3 weeks)* — biggest change; do it last. Each resource is a separate sprint.

Total roadmap if shipped serially: ~6–8 weeks. The first three items are a good two-day patch.

---

## 6. Player-incentive checklist

Same five hooks from v2. v3 reinforces every one:

| Hook | v3 addition that hits it |
|---|---|
| Numbers go up | Sutra perks at milestones; Stance crit multipliers |
| Surprise / discovery | Triads hidden in Codex; rare Inflections gold-bordered |
| Visible identity | Path Signature HUD bars; Awakening rings; Inflection-flavored projectile VFX |
| Meta progress | Sutra perks visibly unlock; Codex Inflection tab grows |
| Mastery achievement | Stance-5 cleave moments; Cinder-saved boss kills; full Triad codex |

If a future v4 system doesn't hit at least one of these hooks, it's almost certainly the wrong system.

---

## 7. What v3 deliberately avoids

- **No new archetypes.** Still thirteen. The 5/4/4 Edge/Daemon/Hex split must stay clean.
- **No new Fusions.** Nine is enough; if a triadic-pair-fusion idea emerges, it's a Triad, not a Fusion.
- **No active abilities.** All Path Signatures activate passively (Stance auto-procs at 3 or 5, Cinder auto-doubles next cast). Active button-press abilities would break the auto-RPG loop.
- **No skill respec mid-run.** Inflections, once chosen, lock for the run. Reroll/banish meta upgrades can adjust cards offered, but not undo Inflection commits. Keeps decisions weighty.
- **No Inflection trees** (Inflection requires another Inflection). Flat catalog. Trees within trees is depth-fatigue.

---

## 8. Open questions for playtesting

1. **How many Inflections per archetype?** Six suggested. Five may feel sparse, eight may bloat. Verify by feel.
2. **Triad activation threshold** — level ≥1 each, or level ≥2 each? The latter slows discovery but raises stakes.
3. **Stance decay timing** — 1s feels right but verify against typical attack cadences. If hero attack speed is high, decay might never trigger and Stance becomes a permanent buff.
4. **Bandwidth max** — 100 is a clean number. If it caps too easily, raise to 200; if it caps too slowly, drop to 60.
5. **Cinder ultimate radius** — does a Cinder-empowered Nova clear the screen? If yes, players will sandbag every wave for it; that's the *intended* feel but verify it doesn't trivialize floor pacing.
6. **Should Inflections bias toward synergy?** When picking a Frost Inflection, weight slightly toward Inflections that pair with already-owned archetypes. Same trick as the near-orbit offer rule, applied one layer down.

---

*End of v3 design — three resources, six triads, seventy-eight inflections.*
