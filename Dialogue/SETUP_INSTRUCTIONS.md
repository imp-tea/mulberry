# Dialogue System Setup Instructions

## Milestone 1 Complete!

The basic dialogue system is now implemented. Here's how to test it:

## Testing the Dialogue System

### 1. Open the project in Godot 4.5

### 2. Create a test dialogue tree for an NPC

**Option A: Using the Inspector (Recommended)**

1. In the Godot editor, navigate to the FileSystem panel
2. Right-click in `Dialogue/Content/Trees/` and select **New Resource**
3. Search for and select `DialogueTree`
4. Name it `shop_keeper_greeting.tres`
5. Click on the new resource to open it in the Inspector
6. Set the `tree_id` to "shop_keeper_greeting"
7. Under `root_node`, click `<empty>` → **New DialogueNode**
8. Configure the root node:
   - `node_id`: "greeting"
   - `type`: LINE
   - `text`: "Welcome to my shop! How can I help you?"
9. Click on `next_node` → **New DialogueNode**
10. Configure the choice hub:
    - `node_id`: "choices"
    - `type`: CHOICE_HUB
11. Under `choices`, click `Add Element` (do this 2-3 times)
12. For each choice element:
    - Click `<empty>` → **New DialogueChoice**
	- Set the `text` (e.g., "I'd like to buy something", "Just looking", "Goodbye")
    - Under `next_node`, create a new DialogueNode with type END

**Option B: Programmatic Creation**

You can also use the helper script at `Dialogue/Content/Trees/example_shop_keeper_dialogue.gd` as a reference for creating trees in code.

### 3. Assign the dialogue tree to an NPC

1. Open `customer.tscn` in the Godot editor
2. Select the root Customer node
3. In the Inspector, you'll see these BaseNPC properties:
   - `npc_id`: Set this to "shop_keeper" (must be unique!)
   - `npc_name`: Set this to "Shop Keeper"
   - `dialogue_trees`: Click to expand, then add your dialogue tree resource
   - `interaction_range`: Leave at 64.0 (or adjust as needed)

### 4. Add the DialogueBox to your scene

1. Open `world.tscn` (your main scene)
2. Add a CanvasLayer node to the root (if one doesn't exist)
3. Instance the DialogueBox scene:
   - Right-click the CanvasLayer
   - Select **Instantiate Child Scene**
   - Navigate to `Dialogue/UI/DialogueBox.tscn`
   - Add it

### 5. Test it!

1. Press F5 to run the game
2. Walk your player near the NPC (within 64 pixels)
3. Press **E** to interact
4. You should see the dialogue box appear!
5. Read the text (it will animate character-by-character)
6. Press **E** or **Enter** to continue to choices
7. Click a choice to see the response
8. The conversation will end automatically

## Controls

- **WASD / Arrow Keys**: Move
- **I**: Toggle Inventory
- **E**: Interact with NPCs (new!)
- **Enter / E**: Advance dialogue text and choices

## Troubleshooting

### "No eligible dialogue trees for NPC"
- Make sure you set the `npc_id` on your NPC
- Make sure you added a DialogueTree to the `dialogue_trees` array
- Check that the DialogueTree has a `root_node` set

### Dialogue box doesn't appear
- Make sure DialogueBox.tscn is added to your scene
- Check the console for errors
- Verify DialogueService is in the autoload list (it should be)

### Can't interact with NPC
- Make sure the player has the "player" group (should be automatic now)
- Make sure the NPC has an `npc_id` set
- Try increasing `interaction_range` on the NPC
- Make sure you're pressing **E** when close to the NPC

### Choice buttons don't appear
- Make sure ChoiceButton.tscn exists at `Dialogue/UI/ChoiceButton.tscn`
- Check that the node paths in DialogueBox are correctly set

## What's Next?

This is Milestone 1 complete! Next milestones will add:
- **Milestone 2**: Conditions (time of day, flags, relationships) and Effects (give items, set flags)
- **Milestone 3**: Ambient barks (NPCs saying things without player interaction)
- **Milestone 4**: Multi-NPC conversations (cutscenes)
- **Milestone 5**: Editor tools and validation
- **Milestone 6**: Save/load and polish

## File Structure

```
Dialogue/
├── DialogueService.gd (Autoload - manages all dialogue)
├── Resources/
│   ├── DialogueTree.gd (Container for dialogue)
│   ├── DialogueNode.gd (Individual lines/choices)
│   └── DialogueChoice.gd (Player choice options)
├── NPC/
│   └── BaseNPC.gd (Base class for all NPCs)
├── UI/
│   ├── DialogueBox.tscn (Main dialogue UI)
│   ├── DialogueBox.gd
│   └── ChoiceButton.tscn (Button template)
└── Content/
    └── Trees/ (Your authored dialogue goes here)
```

## Tips

- Always set unique `npc_id` values for each NPC
- Always set `node_id` values for each DialogueNode (helps with debugging)
- Use NodeType.END to properly end conversations
- Test your dialogue trees by talking to NPCs in-game
- You can have multiple DialogueTrees per NPC (future milestones will add conditions to choose between them)
