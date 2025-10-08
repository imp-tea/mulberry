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
│   └── Plant (Items/Plant.gd) - Placeable plants
└── Droppable (Items/Droppable.gd) - Items that can be dropped
```

All items must:
- Extend from `Item` class (or subclasses)
- Add themselves to the "items" group (handled in `Item._ready()`)
- Define `item_name`, `icon`, and `is_stackable` properties

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

### Coordinate Systems

The game uses two coordinate systems:

1. **World coordinates**: Pixel positions (Vector2)
2. **Tile coordinates**: Grid positions calculated via `Global.get_tile(pos)`

Important: `Global.tile_size = 32` but player `TILESIZE = 64` (these differ by design)

### Tile Outline System

The `tile_outline.gd` script creates a visual outline that follows the player's current tile position. It updates in `_process()` by reading `PlayerVariables.tile`.

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
- **items**: All item nodes in the world
- **inventory_slots**: All inventory slot UI elements

## Scene Structure

- `world.tscn`: Main game world
- `player.tscn`: Player character (CharacterBody2D with Area2D for item pickup)
- `map.tscn`: Map/level layout
- `customer.tscn`: NPC customer entities
- Item scenes in `Items/` folder (e.g., `brown_eyed_susan.tscn`, `canebrake_pitcher_plant.tscn`)
