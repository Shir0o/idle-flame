# PixelLab Asset Generation

This project leverages **PixelLab AI** to generate high-fidelity pixel art assets for characters, environments, and combat effects.

## 🎨 Asset Types

### 1. Characters & Mechs
- **Style**: Humanoid (Hero) or Quadruped (Enemies).
- **Proportions**: Realistic or stylized depending on archetype.
- **Views**: 8-directional (South, South-West, West, North-West, North, North-East, East, South-East).
- **Animations**: Standard humanoid sets (walk, idle, attack) and custom archetype-specific actions.

### 2. Environment (Top-Down Tilesets)
- **Format**: Wang Tilesets (16 or 23 tiles).
- **Usage**: Corner-based autotiling for seamless terrain transitions (e.g., floor patterns, dungeon hazards).
- **Consistency**: Use `lower_base_tile_id` to connect multiple terrain types.

### 3. Isometric Tiles & Map Objects
- **Isometric**: Individual blocks or decor for 3D-depth layers.
- **Objects**: Transparent background assets (barrels, terminals, relics) generated with **Style Matching** to ensure they blend with the current map's art direction.

## 🛠️ Generation Guidelines

- **Size**: Standardize on **32px** or **48px** for characters to maintain grid consistency.
- **Outlines**: Prefer **Selective Outline** or **Single Color Black Outline** for clarity against dark backgrounds.
- **Shading**: Use **Medium Shading** or **Detailed Shading** to match the "Neon Ascension" aesthetic.
- **Views**: Always generate **8 directions** for the Hero and major enemies to support full rotation.

## 🚫 Source Control Mandate

As specified in `GEMINI.md`:
- **Do not commit raw assets** (images, videos, or zips) to the Git repository.
- Keep generated media in the local `assets/` directory (which is included in `.gitignore`).
- Document key generation parameters (prompts, seeds) in internal developer notes for reproducible visuals.

---
*Harnessing AI to build infinite neon worlds.*
