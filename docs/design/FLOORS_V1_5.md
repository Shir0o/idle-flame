# Floors v1.5 — Finishing the Texture

*Polish pass for **Zenith Zero: Idle Descent**.*
*Closes the texture gaps left by Floors v1.*

---

## 0. Why this exists

The Floors v1 commit landed the entire framework: three phases per floor, twelve modifiers, all five bosses with mechanics, six new enemy archetypes with full combat behavior. That is *more than what was scoped*.

What's missing is **texture** — the small layer that makes the framework feel finished from the player's seat:

- Bosses currently advance the floor and drop nothing. Beating the Watcher feels the same as killing 10 basics.
- The Watcher just *appears* during Phase 3. There's no "boss fight!" beat, no name on screen, no mechanic hint.
- A new player encountering an Aegis takes 50% chip damage with no idea why.
- The Codex doesn't track enemies or Crucibles met, so the new content has no discovery loop.
- Two modifiers (Cipher Storm, Stance Stutter) are in the enum but their effects aren't wired.
- Big boss clears (F10, F20) feel structurally identical to F11 or F21.

v1.5 is six small fixes that turn "lots of stuff happening" into "lots of stuff happening *that I understand and care about*." Total scope: ~2 weeks. None of this is new design — it's plumbing the v1 doc already promised but didn't ship.

This doc is design-only. Build order in §7.

---

## 1. Tiered boss rewards

> **Figure 1: Boss reward ladder** — five bosses, five distinct payouts. Beating each one *earns* something visible, not just "advance to next floor."

Today, [`registerKill`](lib/game/state/game_state.dart) advances the floor on a boss kill but grants no special reward. The boss is mechanically a tank-elite. There's no progression beat.

Restore the tiered payout from the v1 doc:

| Floor | Boss | Reward | Why |
|---|---|---|---|
| 5  | The Watcher     | **+50 embers** (instant, banked to meta) | First boss; pure currency reward teaches the loop. |
| 10 | Glass Sovereign | **+1 Sutra mark of player's choice** | Engages the Sutra system that exists but rarely converts. |
| 15 | Hivefather      | **+1 Codex peek** (reveal one undiscovered Inflection or Triad name) | Engages Codex without forcing first-time encounters. |
| 20 | Cipher Twin     | **A free Fusion offer at next level-up** | Engages Fusions; lets the player guarantee one for the run. |
| 25 | The Architect   | **Permanent meta unlock** (e.g., Nexus skin, fourth Heretic Cant slot, +1 starting reroll) | The "I beat the game" trophy. Each F25 first-clear unlocks something different until the unlock list is exhausted. |

### Implementation hints

- Rewards trigger on the `_advanceFloor()` call when `isBossFloor && isBoss`. There's already a branch at [game_state.dart:658](lib/game/state/game_state.dart) — slot the reward dispatch there.
- The Sutra-mark choice should pop a small picker dialog (3 archetypes the player owns, or all 13 if no specifics).
- The Fusion offer guarantee should set a flag (`_pendingGuaranteedFusion = true`) that `_rollUpgradeChoices` honors at the next level-up.
- F25 unlocks need a queue. Track which permanent unlocks have been awarded; pull the next from a list. ~5 entries is enough for v1.5.

### Why this matters most

Idle games answer "what did I earn?" every two minutes. Today the answer at every boss is the same: "the next floor." This single change converts every 5th floor from a beat into a *milestone*.

---

## 2. Boss telegraph + arena dim

When a boss spawns today, it appears in the same wave as everything else. Players who don't read the changelog won't realize what's happening until the boss is a third of the way down the screen.

### Proposal — "BOSS INCOMING" entry beat

When the spawner triggers [`_spawnBoss`](lib/game/components/enemy_spawner.dart:181):

1. **Pause the spawn timer** for 1.5s.
2. **Dim the rest of the screen** to 40% opacity using the same overlay technique as `_LevelUpPicker`.
3. **Show a centered telegraph card** for 1.2s:
   - Top line: `BOSS · F5` (gold, small caps)
   - Middle line: `THE WATCHER` (large, white, glow)
   - Bottom line: One-sentence mechanic — *"Daemon-shielded adds. AoE wins."*
4. **Zoom the screen in slightly** (1.05×) for the duration of the boss fight; release on boss death.

### Why this works

- The telegraph **names the fight** — the player can later say "I lost on the Watcher" instead of "I lost on a hard floor."
- The mechanic hint is a soft tutorial. After three runs, every player knows that AoE counters Watcher.
- Arena dim is the same trick used by every action game. Players already know what it means: *this fight is different*.

### Per-boss telegraph copy

| Boss | One-line hint |
|---|---|
| The Watcher     | *"Daemon-shielded adds. AoE wins."* |
| Glass Sovereign | *"Evasive and splash-immune. Edge focus wins."* |
| Hivefather      | *"Drone broods. Sustain wins."* |
| Cipher Twin     | *"Alternating immunities. Mixed paths win."* |
| The Architect   | *"Everything you've learned. No hints."* |

The Architect deliberately doesn't tell the player what to do — by F25 they should know.

---

## 3. First-encounter counter tips

> **Figure 3: First-encounter toast** — a small corner chip with the enemy's name, one-line behavior, and the counter hint.

Aegis reflects 50% of single-target damage to the Nexus. A new player will lose ~30% HP to this before figuring it out. That's punishing and *not in a fun way* — the game taught nothing.

### Proposal

The first time the player sees a given enemy archetype (tracked in `meta_state` discovery set), display a small toast in the top-right of the HUD for 4 seconds:

```
NEW ENEMY · AEGIS
Reflects single-target damage.
Bypass with AoE / chain.
```

The toast is dismissable (tap), auto-fades, and never shows again for that enemy type. The data model is the existing `_discoveredIds` set in `meta_state.dart` — add `'enemy:<type>'` keys.

### Counter-tip catalog

| Enemy | Toast copy |
|---|---|
| Aegis           | *Reflects single-target damage. Bypass with AoE / chain.* |
| Wraith          | *Phases out for 1s after each hit. Use DOTs or frost.* |
| Cinder-Drinker  | *Heals from Hex damage. Finish with Edge or Daemon.* |
| Splinter        | *Divides on death. Execute or wide AoE.* |
| Sutra-bound     | *Heals nearby enemies. Kill priority.* |
| Sigil-bearer    | *Drops a hazard glyph on death. Kill at the edges.* |

Same treatment for the four base types is optional but cheap (one toast each, four extra strings).

### Why this matters

Discovery without explanation is just frustration. The toast turns "why am I taking damage?" into "oh, I need to AoE." It also reinforces the path identities — *Cinder-Drinker* is a soft tutorial for "Hex isn't always the answer."

---

## 4. Codex Bestiary + Crucibles tabs

The Memory-Core today tracks Archetypes, Fusions, Inflections (per the v3 work). It doesn't track enemies or Crucible events met — so all the new v1 content has no discovery loop, no completionist target, no ember reward for first encounters.

### Proposal

Add two tabs to the Codex screen ([meta_screen.dart](lib/ui/meta_screen.dart)):

#### Bestiary

- 11 enemy entries (4 base + 6 new + bosses are visible after first sighting).
- Greyed out (`???`) until first encounter, then revealed with sprite + counter-tip from §3.
- Each first-time entry pays **+5 embers**, same as Inflection/Fusion discoveries.

> **Figure 4: Bestiary grid** — a 3-column grid of enemy cells, alternating discovered (bright with sprite) and undiscovered (silhouette + ???).

#### Crucibles

- 8 Crucible event entries.
- Greyed out until the player has lived through one.
- Each first encounter pays **+5 embers** plus a one-line description ("*Hivebreak: 8 seconds of fast spawns. Tests sustain."*)

### Codex completion

The "Trinity Sigil" 100% target now requires Bestiary and Crucibles complete too. Players who completed v3's Codex don't lose progress — they just have new tabs to fill.

### Implementation hint

Reuse `_CodexGrid` and `_CodexItem` patterns from the existing meta screen. The data is two static catalogs (already exist for enemies in `EnemyType`, for Crucibles in `CrucibleEvent`).

---

## 5. Wire the two missing modifier effects

Two of the twelve modifiers from the v1 doc are in the enum and HUD chip list but appear unwired:

### Cipher Storm

> *"Random damage-type immunity rotates every 4s."*

Implementation: a `currentImmunity` field on `GameState` cycling through `DamageType` values every 4s when `cipherStorm` is active. `Enemy.takeDamage` checks `if (game.state.cipherStormImmunity == type) return;`. About 30 lines.

### Stance Stutter

> *"Stance decays in 0.5s instead of 1s."*

Implementation: read the modifier set in the Stance decay timer. If `stanceStutter` active, halve the decay window. About 5 lines.

These are small and bring the modifier catalog to fully shipped. Without them, two of the twelve chips lie about what they do — small but corrosive to player trust.

---

## 6. Floor reward room (post-boss, F10 and F20)

Optional but high-leverage. After the player clears F10 (Glass Sovereign) and F20 (Cipher Twin), instead of advancing immediately to the next floor, present a **reward room** — three boons, pick one:

### Boon options (rolled from a pool of ~8)

- *+5% max Nexus HP for the rest of the run*
- *+1 Reroll for the rest of the run*
- *Instant Inflection on a skill of your choice*
- *+25 gold instantly*
- *Halve the cost of one Heretic Cant in the future*
- *Skip the next Heretic Cant offer (banish it)*
- *+1 Sutra mark on a random owned archetype*
- *Reveal the next floor's modifier early*

### Why two reward rooms, not five

- Every floor would feel pacing-fatiguing.
- F10 and F20 are the natural "halfway" beats. F25 is the finale (already has a reward via §1).
- Two rooms gives the system room to expand without overwhelming v1.5 scope.

### Why this isn't already in v1

It was step 10 in the v1 build order — explicitly the lowest priority. v1.5 can either include it (3-4 days) or push it to v1.6 if the rest of v1.5 takes longer than expected.

---

## 7. Build order

Strict priority: each item ships independently. If you only have a week, ship #1, #2, #3.

1. **Tiered boss rewards** *(2 days)* — biggest player payoff per dev-day.
2. **Boss telegraph + arena dim** *(2 days)* — sells the moment.
3. **First-encounter counter tips** *(2 days)* — closes the teaching gap.
4. **Codex Bestiary + Crucibles tabs** *(2-3 days)* — closes the discovery loop.
5. **Wire Cipher Storm + Stance Stutter** *(½ day each)* — finish what the catalog promises.
6. **Floor reward room (F10/F20)** *(3-4 days)* — last because boss rewards from #1 already carry weight.

Total: ~10-12 working days. Ship in two ~one-week increments.

---

## 8. Player-incentive checklist

Same five hooks. v1.5 reinforces:

| Hook | v1.5 addition |
|---|---|
| Numbers go up | Tiered boss rewards (embers, sutra marks); reward room boons |
| Surprise / discovery | Bestiary fills as you play; Cipher Storm rotation creates moment-to-moment variance |
| Visible identity | Boss telegraph names the fight; arena dim sells it |
| Meta progress | Boss rewards are *visible* additions to permanent state |
| Mastery achievement | F25 first-clear unlocks; Bestiary 100% |

---

## 9. What v1.5 deliberately avoids

- **No new bosses, enemies, or modifiers.** v1's catalog is enough. v1.5 finishes; doesn't expand.
- **No new Crucible events.** Eight is enough.
- **No active player abilities** during boss fights. Auto-RPG holds.
- **No mid-run save/restart for boss retries.** If a player dies on F25 they restart the run. That's the contract.
- **No leaderboards or social features.** Single-player descent.
- **No tutorial overlay.** The first-encounter toast (§3) is *the* tutorial — it teaches in context. A separate tutorial flow is its own scope and lives in v2.

---

## 10. Open questions for playtesting

1. **F25 permanent unlock list** — how many entries? Suggest ~5 for v1.5, expandable later. Once exhausted, fall back to embers.
2. **Reward room frequency** — F10/F20 only, or every boss after F10? Two feels right but verify.
3. **Counter tip toast duration** — 4 seconds suggested. Long enough to read, short enough not to occlude gameplay. Verify with playtesters who skip text.
4. **Sutra-mark picker after F10** — does the dialog interrupt the run mid-floor, or wait until run end? Mid-floor is more rewarding (immediate gratification); end-of-run is less disruptive.
5. **Boss telegraph vs floor entry card** — both surface info. Could the boss telegraph replace the floor entry card on boss floors, or do both? Probably both, but verify they don't pile up.
6. **Cipher Storm immunity duration** — 4s suggested. If it ends up frustrating, raise to 6s. If too easy to play around, drop to 3s.

---

*End of v1.5 — six items, two weeks, one finished v1.*
