# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Mulberry** is a 2D game built with Godot 4.5 using GDScript. The game features:
- An inventory management system with draggable items and hotbar
- A tile-based world with grid snapping
- Player movement with 8-directional animations
- Dialogue system (using Dialogue Manager addon)
- Day/night shader effects
- Item system with placeable/droppable variants
- Quest and relationship tracking

## Running the Game

This project uses **Godot 4.5**. To run the game:

1. Open the project in Godot Editor
2. Press F5 or click the Play button
3. Main scene: `world.tscn`

There are no build commands - Godot projects run directly from the editor during development.

## Architecture

### Autoload Singletons (Global State)

Four autoload scripts manage global state (defined in `project.godot`):

- **Global** (`scripts/global.gd`): Tile size constants and tile coordinate conversion
- **PlayerVariables** (`scripts/player_variables.gd`): Stores player position, tile, and inventory reference
- **GameState** (`game_state.gd`): Quest states, relationships, and game flags
- **DialogueManager** (addon): Handles dialogue balloons and dialogue resources

### Item System Hierarchy

Items use an inheritance hierarchy:

```
Item (Items/Item.gd)
├── Placeable (Items/Placeable.gd) - Items that can be placed in the world
│   ├── Plant (Items/Plant.gd) - Placeable plants
│   └── Structure (Items/Structure.gd) - Placeable structures with pickup requirements
└── Droppable (Items/Droppable.gd) - Items that can be dropped in the world
    └── Consumable (Items/Consumable.gd) - Droppable items that can be consumed
```

All items must:
- Extend from `Item` class (or subclasses)
- Add themselves to the "items" group (handled in `Item._ready()`)
- Define `item_name`, `icon`, and `is_stackable` properties

Item pickup behavior:
- Items in the "pickup_items" group are automatically collected on contact with player (see `player.gd:144`)
- Regular items in the "items" group must be manually picked up via interaction

### Inventory System

The inventory system (`Inventory/Inventory.gd`) uses a slot-based architecture:

- **Inventory** (Control node): Main inventory controller with grid layout
- **InventorySlot**: Individual inventory slots that can hold items
- **InventoryItem**: Item representations within inventory (separate from world items)
- **Tooltip**: Shared tooltip for all inventory slots

Key inventory concepts:
- Items exist as nodes in the world (extending `Item`)
- When collected, world items are destroyed and converted to `InventoryItem` instances
- The inventory supports both a hotbar (first row, always visible) and full grid (toggled with 'I')
- Dragging/splitting items uses a `selected_item` static variable
- **InventoryItem** stores `item_type` (e.g., "Droppable", "Placeable", "Plant") and `world_scene_path` for reinstantiation
- Dropping items: Drag item outside inventory bounds to drop at player position (only Droppable/Consumable types)
- Placing items: Press 'E' with Placeable/Plant/Structure in active hotbar slot to place at facing tile

### Coordinate Systems

The game uses two coordinate systems:

1. **World coordinates**: Pixel positions (Vector2)
2. **Tile coordinates**: Grid positions calculated via `Global.get_tile(pos)`

Important: `Global.tile_size = 32` but player `TILESIZE = 64` (these differ by design)

### Tile Outline System

The `tile_outline.gd` script creates a visual outline that follows the player's current tile position. It updates in `_process()` by reading `PlayerVariables.tile`.

### Player Mechanics

The player (`scripts/player.gd`) implements:
- **8-directional movement**: Uses `input_to_dir()` to map input angles to 8 directions (e.g., "-down", "-up-right")
- **Position snapping**: Player position is rounded to integer pixels each frame to prevent camera jitter
- **Facing tile tracking**: `PlayerVariables.facing_tile` stores the tile the player is facing (calculated from facing direction)
- **Hotbar system**: `current_hotbar_slot` tracks active hotbar slot (first row of inventory)
- **Item placement**: Press 'E' to place item from active hotbar slot at facing tile
- **Inventory toggle**: Press 'I' or Tab to show/hide full inventory grid (hotbar always visible)

## Input Actions

Defined in `project.godot`:
- `up`, `down`, `left`, `right`: Movement (WASD or arrow keys)
- `toggle_inventory`: Toggle inventory display (I or Tab)
- `interact`: Trigger interactions/dialogue (E)

## Shaders

- **Sprite outline shader** (`Shaders/outline.tres`): Applied to sprites on hover
- **Day/night shader** (`Shaders/whole_screen.tres`): Screen-space shader for time-of-day effects

## Dialogue System

Uses the **Dialogue Manager** addon (`addons/dialogue_manager/`):
- Dialogue files: `.dialogue` format (e.g., `sample_emily.dialogue`)
- Custom balloon UI: `Dialogue/balloon.tscn`
- Trigger dialogue via: `DialogueManager.show_dialogue_balloon(resource, "title")`

## Key Global Groups

Defined in `project.godot`:
- **items**: All item nodes in the world (added automatically in `Item._ready()`)
- **pickup_items**: Items that are automatically picked up on contact with player
- **inventory_slots**: All inventory slot UI elements

## Scene Structure

- `world.tscn`: Main game world
- `player.tscn`: Player character (CharacterBody2D with Area2D for item pickup)
- `map.tscn`: Map/level layout
- `customer.tscn`: NPC customer entities
- Item scenes in `Items/` folder (e.g., `brown_eyed_susan.tscn`, `canebrake_pitcher_plant.tscn`)

## Important Implementation Patterns

### Creating New Items

When creating a new item:
1. Extend appropriate base class (Item, Placeable, Droppable, Plant, Structure, or Consumable)
2. Set `@export` variables: `item_name`, `icon`, `is_stackable`
3. If Placeable, optionally override `on_placed(tile: Vector2)` for custom placement behavior
4. If Consumable, override `consume(player_vars)` to define consumption effects
5. If Structure, configure `requires_tool_to_pickup` and override `can_pickup()` if needed
6. Add to "pickup_items" group in scene if it should be auto-collected on contact

### World-to-Inventory Item Conversion

The conversion process (`Inventory.add_item()`):
1. Determines item type via class hierarchy check (most specific first: Consumable → Plant → Structure → Placeable → Droppable)
2. Stores `world_scene_path` via `item.scene_file_path` for later reinstantiation
3. Creates `InventoryItem` with all properties including `item_type` and `world_scene_path`
4. Destroys original world item via `queue_free()`
5. Attempts to stack with existing inventory items if stackable
6. Places in first available slot respecting slot hints

### Inventory-to-World Item Conversion

Two paths exist:
- **Placing** (Placeable/Plant/Structure via 'E' key): Reinstantiates at facing tile using `load(world_scene_path).instantiate()`
- **Dropping** (Droppable/Consumable via drag outside inventory): Reinstantiates at player position
