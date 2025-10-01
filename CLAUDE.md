# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Mulberry** is a 2D game built with Godot Engine 4.5 using GDScript. The game features a player character navigating a shop environment with an inventory system for collecting and managing items (plants). The project uses pixel art graphics with integer scaling.

## Running the Project

The project must be opened and run through the Godot Engine editor:

1. Open Godot Engine 4.5 or later
2. Import the project by selecting `project.godot`
3. Press F5 to run the game from the editor
4. Press F6 to run the current scene

**Note**: This is a Godot project with no build scripts. All development and testing happens within the Godot editor.

## Project Architecture

### Autoloaded Singletons (Global State)

Four autoload scripts provide global state and event communication (defined in `project.godot:18-23`):

- **GlobalSettings** (`Globals/GlobalSettings.gd`) - Currently empty, intended for game settings, time, weather, location
- **PlayerVariables** (`Globals/PlayerVariables.gd`) - Currently empty, intended for player state, flags, relationships
- **SignalBus** (`Globals/SignalBus.gd`) - Central event bus for cross-scene communication (currently empty)
- **DialogueService** (`Dialogue/DialogueService.gd`) - Manages all dialogue conversations, NPC memory, and dialogue state

These are accessible globally throughout the game without needing references.

### Inventory System Architecture

The inventory system is a complex multi-component system with drag-and-drop functionality:

**Core Components:**
- **Inventory** (`Inventory/Inventory.gd`) - Main inventory controller, class_name `Inventory`
  - Manages a grid of `InventorySlot` instances (configurable rows/cols)
  - Handles drag-and-drop state via static `selected_item` variable
  - Provides API methods: `add_item()`, `retrieve_item()`, `all_items()`, `all()`, `remove_all()`, `clear_inventory()`
  - Comments indicate destructive vs non-destructive operations
  - Has hotbar functionality (first row of slots visible when inventory closed)

- **InventorySlot** (`Inventory/InventorySlot/InventorySlot.gd`) - Individual slot container, class_name `InventorySlot`
  - Contains optional `item` (InventoryItem) and `hint_item` (restricts slot to specific item type)
  - Emits signals: `slot_input(which, action)` and `slot_hovered(which, is_hovering)`
  - Handles drag operations: `select_item()`, `deselect_item()`, `split_item()` (right-click splits stack in half)
  - Methods check `is_respecting_hint()` to enforce slot restrictions

- **InventoryItem** (`Inventory/InventorySlot/InventoryItem/`) - Visual representation of items in inventory
  - Instanced from scene, not a direct Item copy
  - Has properties: `item_name`, `icon`, `is_stackable`, `amount`, `is_placeable`
  - Label shows format: "amount - name"

- **Item** (`Items/Item.gd`) - Base class for world items, class_name `Item`
  - Properties: `item_name`, `icon`, `is_stackable`, `is_placeable`
  - Automatically joins "items" group on `_ready()`
  - When picked up, the world Item is destroyed and converted to an InventoryItem

**Item Collection Flow:**
1. Player collides with Item in world (via Area2D signals in `player.gd:60-66`)
2. `inventory.add_item(item, 1)` is called
3. Inventory creates InventoryItem instance from preload
4. Original Item is queue_freed (consumed from world)
5. InventoryItem is placed in first available slot, or stacked if stackable

### Player System

**Player** (`scripts/player.gd`) - CharacterBody2D with 8-directional movement
- Movement: WASD or arrow keys, uses `get_vector()` for input
- Has `inventory` export variable that must be connected to an Inventory node
- Supports 8 directional animations (idle/walk × 8 directions)
- Inventory toggle: 'I' key shows/hides inventory (hotbar remains visible when closed)
- Collision detection for item pickup via Area2D child node

### Global Groups

Two global groups are used (defined in `project.godot:30-33`):
- `"items"` - All pickable items in the world
- `"inventory_slots"` - All inventory slot UI elements

Use `get_tree().get_nodes_in_group("group_name")` to access these.

### Input Actions

Custom input actions (defined in `project.godot:35-71`):
- `up`, `down`, `left`, `right` - Movement (WASD + arrows)
- `toggle_inventory` - Show/hide inventory (I key)
- `interact` - Talk to NPCs (E key)

### Dialogue System Architecture (Milestone 1 - COMPLETE)

The dialogue system is a Resource-based system with signal-driven UI:

**Core Components:**
- **DialogueService** (`Dialogue/DialogueService.gd`) - Autoloaded singleton, manages all conversations
  - Tracks registered NPCs and their memory (lines said, conversation count)
  - Orchestrates conversation flow (start, advance, choices, end)
  - Emits signals: `dialogue_started`, `line_displayed`, `choices_presented`, `choice_selected`, `dialogue_finished`
  - Method `is_in_conversation()` checks if dialogue is active

- **DialogueTree** (`Dialogue/Resources/DialogueTree.gd`) - Resource containing complete conversation
  - Has unique `tree_id` for save/load
  - Contains `root_node` (starting DialogueNode)
  - Can have `variables` dictionary for templating (future feature)

- **DialogueNode** (`Dialogue/Resources/DialogueNode.gd`) - Individual node in dialogue tree
  - Types: LINE (single line), CHOICE_HUB (present choices), END (terminate conversation)
  - Contains `text`, `node_id`, `next_node`, `choices` array, `tags` dictionary
  - LINE nodes auto-advance to `next_node`, CHOICE_HUB presents player choices

- **DialogueChoice** (`Dialogue/Resources/DialogueChoice.gd`) - Player choice option
  - Contains choice `text` and `next_node` to jump to
  - Can have `disabled_text` for unavailable choices (future: conditions)

- **BaseNPC** (`Dialogue/NPC/BaseNPC.gd`) - Base class for all NPCs, extends CharacterBody2D
  - Exports: `npc_id` (unique!), `npc_name`, `dialogue_trees` array, `interaction_range`
  - Automatically registers with DialogueService on `_ready()`
  - Method `can_talk_to_player()` checks distance to player
  - Method `start_conversation()` initiates dialogue with player
  - All NPCs should extend this class and call `super._ready()`

- **DialogueBox** (`Dialogue/UI/DialogueBox.tscn`) - UI for displaying dialogue
  - Control node anchored to bottom center of screen
  - Has RichTextLabel for text, Label for speaker name, VBoxContainer for choices
  - Character-by-character text reveal animation
  - Listens to DialogueService signals to update UI
  - Hidden when no conversation active

**Player Integration:**
- Player is in "player" group (added in `player.gd:_ready()`)
- Press **E** key to interact with nearby NPCs (`scripts/player.gd:45-50`)
- Interaction checks if DialogueService is already in conversation before starting new one

**NPC Integration:**
- NPCs extend BaseNPC and set `npc_id`, `npc_name` in inspector
- Assign DialogueTree resources to `dialogue_trees` array in inspector
- NPCs automatically join "npcs" group via BaseNPC

**Creating Dialogue Content:**
1. Create new DialogueTree resource in `Dialogue/Content/Trees/`
2. Set `tree_id` and create `root_node` (DialogueNode)
3. Build tree: LINE nodes for text, CHOICE_HUB for player choices, END to terminate
4. Assign tree to NPC's `dialogue_trees` array

See `Dialogue/SETUP_INSTRUCTIONS.md` for detailed setup guide.

### Scene Structure

- **world.tscn** - Main game scene (set as main scene), should contain DialogueBox instance
- **player.tscn** - Player character with inventory
- **shop.tscn** - Shop environment
- **customer.tscn** - NPC character (extends BaseNPC)
- **Items/** - Individual item scenes (e.g., `canebrake_pitcher_plant.tscn`, `brown_eyed_susan.tscn`)

### Visual Settings

The game uses pixel art with specific rendering settings:
- Integer scaling mode for crisp pixel graphics
- Default texture filter set to nearest neighbor (0)
- 2D transforms snap to pixel
- GL Compatibility renderer
- Black background color

## Code Conventions

- Use `class_name` for reusable classes (Item, Inventory, InventorySlot, DialogueTree, DialogueNode, BaseNPC)
- Mark API methods with comments indicating if they are destructive (modify/remove) or non-destructive (read-only)
- Use `@export` for inspector-editable properties
- Use `@onready` for references that need the node tree to be ready
- Preload scenes that are frequently instantiated: `preload("res://path/to/scene.tscn")`
- Use signals for component communication (e.g., `slot_input`, `slot_hovered`, `dialogue_started`)
- Group-based detection: Add nodes to groups for easy querying ("items", "npcs", "player")
- Static variables for shared state (e.g., `Inventory.selected_item`)
- When extending base classes, always call `super._ready()` if overriding `_ready()`
- NPCs must have unique `npc_id` values set in inspector

## File Organization

- `/scripts/` - Player and NPC scripts
- `/Inventory/` - Complete inventory system (controller, slots, items, tooltip)
- `/Items/` - Item base class and item scene instances
- `/Globals/` - Autoloaded singleton scripts
- `/Dialogue/` - Complete dialogue system
  - `/Resources/` - DialogueTree, DialogueNode, DialogueChoice base classes
  - `/NPC/` - BaseNPC class
  - `/UI/` - DialogueBox scene and ChoiceButton
  - `/Content/Trees/` - Authored dialogue tree resources (.tres files)
  - `DialogueService.gd` - Autoloaded orchestrator
  - `SETUP_INSTRUCTIONS.md` - Setup and testing guide
- `/sprites/` - Sprite assets
- `/tile-resources/` - Tileset resources
- Root directory contains main scenes (world, player, shop, camera)
