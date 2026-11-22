# Hillclimb: Peak Knight

A 2D action-platformer built with **Godot Engine**, featuring responsive movement, melee combat, boss encounters, and timing-based parrying.

## Play the Game

**[Play Hillclimb: Peak Knight on itch.io](https://bananayt.itch.io/hillclimb-peakknight)**

The game is available to play on itch.io!

## Features

### Player Movement
- Horizontal movement and jumping.
- Coyote time and jump buffering for more responsive controls.
- Wall sliding and wall jumping.
- Wall climbing with a stamina system.
- Variable jump height.

### Combat System
- Melee attacks with configurable damage.
- Frame-based hit detection.
- Player health system and health bar.
- Hurt animations and temporary invulnerability after taking damage.

### Parrying
- Timing-based parry mechanic.
- A limited parry window rewards precise timing.
- Successful parries completely negate incoming attacks.
- Missed parries leave the player vulnerable.
- Parry cooldown prevents continuously attempting to parry.

### Boss Encounters
- Boss health system.
- Boss attack and movement animations.
- Player and boss melee combat.

### Level Mechanics
- Goal points that trigger the victory screen.
- Kill zones that eliminate the player when they fall out of the level.
- Restart functionality after reaching the end or dying.

## Controls

Controls are configurable through Godot's **Project Settings → Input Map**.

| Action | Input Map Action |
|---|---|
| Move left | `Walk Backward` |
| Move right | `Walk forward` |
| Jump | `Jump` |
| Climb | `climb` |
| Attack | `attack` |
| Parry | `block` |

The actual keyboard bindings depend on your Input Map configuration.

## Getting Started

### Requirements
- Godot Engine 4.x
- Git (optional, for cloning the repository)

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Bananayt294/HillClimb-Game/
   ```

2. Open Godot Engine.
3. Select **Import**.
4. Navigate to the cloned project directory.
5. Select the `project.godot` file.
6. Run the project using the Play button.

## Technical Details

The game is developed using:
- **Engine:** Godot Engine 4.x
- **Language:** GDScript
- **Physics:** Godot's built-in 2D physics system
- **Rendering:** Godot 2D renderer
- **Animation:** AnimatedSprite2D and SpriteFrames

## Development Status

The project is actively in development. Current work includes player movement, combat, parrying, boss encounters, and level progression.

Future improvements may include:
- Boss stagger mechanics following successful parries.
- More enemy types and attack patterns.
- Additional levels and environments.
- Improved combat feedback and visual effects.
- Sound effects and background music.

## License

MIT
