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

Five autoload scripts manage global state (defined in `project.godot`):

- **Global** (`scripts/autoloads/global.gd`): Tile size constants and tile coordinate conversion
- **PlayerVariables** (`scripts/autoloads/player_variables.gd`): Stores player position, tile, and inventory reference
- **GameState** (`scripts/autoloads/game_state.gd`): Quest states, relationships, and game flags
- **TileManager** (`scripts/autoloads/tile_manager.gd`): Tile occupancy tracking, terrain type detection, and placement validation
- **DialogueManager** (addon): Handles dialogue balloons and dialogue resources

### Item System Hierarchy

Items use an inheritance hierarchy:

```
Item (scripts/items/Item.gd) - Base class for all items
├── Placeable (scripts/items/Placeable.gd) - Items that can be placed in the world
│   ├── Plant (scripts/items/Plant.gd) - Placeable plants
│   └── Structure (scripts/items/Structure.gd) - Placeable structures with pickup requirements
└── Consumable (scripts/items/Consumable.gd) - Items that can be consumed
```

**DroppedItem** (scripts/items/DroppedItem.gd) - Special wrapper class for loose items in the world:
- A Node2D that wraps item data (not part of Item hierarchy)
- Used for items dropped from inventory, loot from enemies/objects, etc.
- Displays as 16x16 pixel sprite (half of Global.tile_size)
- Animated arc ejection: flies in random direction with parabolic "bounce" effect
- Animation uses lerp for horizontal movement, parabolic offset for vertical arc
- 0.5s pickup cooldown timer prevents immediate re-pickup
- Auto-adds to "pickup_items" group after cooldown expires
- When picked up, recreates the original Item and adds it to inventory

All items must:
- Extend from `Item` class (or subclasses)
- Add themselves to the "items" group (handled in `Item._ready()`)
- Define `item_name`, `icon`, `is_stackable`, and `is_droppable` properties
- By default, `is_droppable = true` (set to false for quest items or special items)

Item pickup behavior:
- Items in the "pickup_items" group are automatically collected on contact with player (see `player.gd:166`)
- **DroppedItem** instances are automatically added to "pickup_items" after pickup cooldown
- Regular items in the "items" group must be manually picked up via interaction (E key)
- Placeable items with `picked_up_on_interaction = true` can be picked up from world tiles

### Inventory System

The inventory system (`scripts/ui/inventory/Inventory.gd`) uses a slot-based architecture:

- **Inventory** (Control node): Main inventory controller with grid layout
- **InventorySlot**: Individual inventory slots that can hold items
- **InventoryItem**: Item representations within inventory (separate from world items)
- **Tooltip**: Shared tooltip for all inventory slots

Key inventory concepts:
- Items exist as nodes in the world (extending `Item`)
- When collected, world items are destroyed and converted to `InventoryItem` instances
- The inventory supports both a hotbar (first row, always visible) and full grid (toggled with 'I')
- Dragging/splitting items uses a `selected_item` static variable
- **InventoryItem** stores `item_type` (e.g., "Item", "Placeable", "Plant", "Consumable") and `world_scene_path` for reinstantiation
- Dropping items: Drag item outside inventory bounds to drop at player position (if `is_droppable = true`)
  - Creates a **DroppedItem** wrapper with animated arc effect
  - Item ejects in random direction (24-48 pixels away) with 0.4s arc animation
  - 0.5s pickup cooldown before auto-adding to "pickup_items" group
- Placing items: Press 'E' with Placeable/Plant/Structure in active hotbar slot to place at facing tile

### Coordinate Systems

The game uses two coordinate systems:

1. **World coordinates**: Pixel positions (Vector2)
2. **Tile coordinates**: Grid positions calculated via `Global.get_tile(pos)`

Important: `Global.tile_size = 32` but player `TILESIZE = 64` (these differ by design)

### Tile Outline System

The `tile_outline.gd` script creates a visual outline that follows the player's facing tile position. It provides real-time placement validation feedback:
- **Green outline** (`Color(0.3, 1.0, 0.3, 0.8)`): Valid placement for current hotbar item
- **Red outline** (`Color(1.0, 0.3, 0.3, 0.8)`): Invalid placement (occupied, wrong terrain, or custom check failed)
- **White outline**: No placeable item in current hotbar slot

The outline updates in `_process()` by reading `PlayerVariables.facing_tile` and validating placement via `TileManager.can_place_item()`.

### Player Mechanics

The player (`scripts/player.gd`) implements:
- **8-directional movement**: Uses `input_to_dir()` to map input angles to 8 directions (e.g., "-down", "-up-right")
- **Position snapping**: Player position is rounded to integer pixels each frame to prevent camera jitter
- **Facing tile tracking**: `PlayerVariables.facing_tile` stores the tile the player is facing (calculated from facing direction)
- **Hotbar system**: `current_hotbar_slot` tracks active hotbar slot (first row of inventory)
- **Item placement**: Press 'E' to place item from active hotbar slot at facing tile
- **Inventory toggle**: Press 'I' or Tab to show/hide full inventory grid (hotbar always visible)

### Tile Management System

The **TileManager** singleton (`tile_manager.gd`) provides centralized tile state management:

**Core functionality:**
- `get_terrain_type(tile: Vector2) -> String`: Returns terrain type ("grass", "dirt", "water", etc.) from TileMap
- `is_tile_occupied(tile: Vector2) -> bool`: Checks if a placed item occupies the tile
- `get_occupying_item(tile: Vector2) -> Node`: Returns the item/structure at a tile (if any)
- `register_placement(tile: Vector2, item: Node)`: Records an item placement
- `unregister_placement(tile: Vector2)`: Removes placement record when item is removed
- `get_tile_state(tile: Vector2) -> Dictionary`: Returns complete state info for a tile
- `can_place_item(item: Placeable, tile: Vector2) -> PlacementResult`: Validates placement (checks occupancy, terrain compatibility, and custom requirements)
- `PlacementResult`: Inner class with `valid: bool` and `reason: String` properties

**Data structure:**
- Uses Dictionary with Vector2 keys for O(1) tile lookups
- Each tile stores: terrain type, occupying item reference, item type
- Only stores data for tiles with placed items (memory efficient)

**Integration:**
- Requires TileMapLayer tagged with "tilemap" group (done in `scenes/environments/map.tscn`)
- Terrain data read from Godot's TileSet terrain system using `get_cell_tile_data()`
- Placement validation automatically called by player placement logic and tile outline visual feedback

## Input Actions

Defined in `project.godot`:
- `up`, `down`, `left`, `right`: Movement (WASD or arrow keys)
- `toggle_inventory`: Toggle inventory display (I or Tab)
- `interact`: Place items, pick up items, trigger interactions/dialogue (E)
- `inspect`: Inspect items or NPCs (F)
- `back`: Cancel/back action (R)
- `ui_select`: Select/drag items in inventory (Left mouse button, Space)

## Shaders

- **Sprite outline shader** (`assets/shaders/outline.gdshader`): Applied to sprites on hover
- **Day/night shader** (`assets/shaders/whole_screen.tres`): Screen-space shader for time-of-day effects

## Dialogue System

Uses the **Dialogue Manager** addon (`addons/dialogue_manager/`):
- Dialogue files: `.dialogue` format in `data/dialogue/` (e.g., `sample_emily.dialogue`)
- Custom balloon UI: `scenes/ui/dialogue/balloon.tscn` (configured in project settings)
- Trigger dialogue via: `DialogueManager.show_dialogue_balloon(resource, "title")`

## Key Global Groups

Defined in `project.godot`:
- **items**: All item nodes in the world (added automatically in `Item._ready()`)
- **pickup_items**: Items that are automatically picked up on contact with player
  - **DroppedItem** instances auto-add to this group after pickup cooldown expires
  - Used for dropped loot, items ejected from inventory, etc.
- **inventory_slots**: All inventory slot UI elements

## Scene Structure

- `scenes/world.tscn`: Main game world (main scene)
- `scenes/actors/player.tscn`: Player character (CharacterBody2D with Area2D for item pickup)
- `scenes/environments/map.tscn`: Map/level layout with TileMapLayer
- `scenes/actors/customer.tscn`: NPC customer entities
- `scenes/vfx/tile_outline.tscn`: Visual placement feedback overlay
- `scenes/camera/camera.tscn`: Game camera (follows player)
- `scenes/items/DroppedItem.tscn`: Wrapper for loose/dropped items with physics
- Item scenes in `scenes/entities/plants/` and `scenes/entities/structures/` folders
- UI scenes in `scenes/ui/inventory/` and `scenes/ui/dialogue/`

## Important Implementation Patterns

### Creating New Items

When creating a new item:
1. Extend appropriate base class (Item, Placeable, Plant, Structure, or Consumable)
2. Set `@export` variables: `item_name`, `icon`, `is_stackable`, `is_droppable`
   - `is_droppable` defaults to `true` (set to `false` for quest items)
3. If Placeable:
   - Configure `allowed_terrains` and `blocked_terrains` arrays for placement restrictions
   - Set `picked_up_on_interaction` to allow manual pickup from world
   - Optionally override `on_placed(tile: Vector2)` for custom placement behavior
   - Optionally override `custom_placement_check(tile: Vector2) -> PlacementResult` for advanced validation
4. If Consumable, override `consume(player_vars)` to define consumption effects
5. If Structure, configure `requires_tool_to_pickup` and override `can_pickup()` if needed
6. Save scene in appropriate folder (`scenes/entities/plants/` or `scenes/entities/structures/`)

**Note**: Don't manually add items to "pickup_items" group. Use **DroppedItem** wrapper for loose items instead.

### World-to-Inventory Item Conversion

The conversion process (`Inventory.add_item()`):
1. Determines item type via class hierarchy check (most specific first: Consumable → Plant → Structure → Placeable)
2. Stores `world_scene_path` via `item.scene_file_path` for later reinstantiation
3. Creates `InventoryItem` with all properties including `item_type` and `world_scene_path`
4. Destroys original world item via `queue_free()`
5. Attempts to stack with existing inventory items if stackable
6. Places in first available slot respecting slot hints

**Special case - DroppedItem pickup**:
- Player detects `DroppedItem` in "pickup_items" group
- Checks `can_be_picked_up` flag (ensures pickup cooldown expired)
- Recreates original Item from `world_scene_path`
- Adds to inventory with stored `amount`
- Destroys DroppedItem wrapper

### Inventory-to-World Item Conversion

Two paths exist:
- **Placing** (Placeable/Plant/Structure via 'E' key):
  - Validates placement using `TileManager.can_place_item()`
  - Reinstantiates at facing tile using `load(world_scene_path).instantiate()`
  - Positions at tile center: `tile * Global.tile_size + Vector2.ONE * Global.half_tile`
  - Automatically calls `on_placed()` which registers with TileManager
- **Dropping** (any item with `is_droppable = true` via drag outside inventory):
  - Creates **DroppedItem** wrapper (Node2D) at player position
  - Copies item data (name, icon, stackable, amount, type, scene_path) to wrapper
  - Scales sprite to 16x16 pixels (half of Global.tile_size)
  - Animates arc ejection in random direction (24-48 pixels away)
  - Arc uses horizontal lerp + parabolic vertical offset (32 pixel arc height)
  - Animation duration: 0.4s
  - Starts 0.5s pickup cooldown timer
  - After cooldown, adds to "pickup_items" group for auto-pickup
  - No TileManager registration (dropped items are loose world objects)

### Terrain-Based Placement System

Placeable items support terrain validation:
- **allowed_terrains**: Array of allowed terrain names (empty = allow all)
- **blocked_terrains**: Array of forbidden terrain names
- Terrain names come from TileSet terrain system (e.g., "grass", "dirt", "water")
- Validation is case-insensitive (terrain names are converted to lowercase)
- Example: A plant might have `allowed_terrains = ["grass", "dirt"]` or `blocked_terrains = ["water"]`
