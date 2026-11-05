# Level Editing

[简体中文](level-editing.md)

1. Duplicate a scene in `scenes/rooms/`. Keep `PlayerSpawn`, `Enemies`, and `Exit` as direct children of the room root.
2. Move `PlayerSpawn` and `Exit`. Place instances of `scenes/actors/enemy.tscn` directly under `Enemies`. Set `Kind` to Chaser or Shooter, and enable `Movement Disabled` to keep an enemy stationary.
3. Set `Arena Size`, `Rhythm Section`, and `Difficulty` on the room root. Keep its rotation at 0 and scale at 1.
4. Save and press **F6** to test the room. Press **R** to restart. Add the room to the root's `Room Scenes` array in `scenes/main.tscn` and press **F5** to play the rooms in order. Edit layouts in their source room scenes.

## Obstacles and Hazards

Place props under the room root or a `Props` node.

| Scene | How to edit |
| --- | --- |
| `scenes/props/obstacle.tscn` | Enable **Editable Children**. Resize or select a rectangle, circle, or capsule in `CollisionShape2D → Shape`. |
| `scenes/props/polygon_obstacle.tscn` | Enable **Editable Children**, select `CollisionPolygon2D`, and edit its vertices in the 2D view. |
| `scenes/props/hazard.tscn` | Set `Size` and `Damage`. Enable `Dash Can Pass Safely` to dash through without damage. |

Solid obstacles block the player, enemies, and bullets. Their appearance follows their collision shape. Hazards can be crossed and deal damage during a dash by default. Clear all enemies to open the exit.

Press **F1** to tune movement, dashes, timing, and volume. See [Dash Modes](dash-modes.en.md).
