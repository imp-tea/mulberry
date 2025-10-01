# Dialogue System Overview

This repository now includes a data-driven dialogue stack designed for Godot 4.5. Dialogue data lives under es://dialogue. Key building blocks:

- core/ – runtime services (DialogueService, context/runtime structs).
- esources/ – resource scripts for graphs, nodes, conditions, snippets, barks.
- effects/ and conditions/ – reusable effect/condition resources.
- ui/ – the reusable DialogueBox scene that listens to the service.
- content/graphs and content/barks – authored assets that are auto-scanned at runtime.

## Runtime Flow

DialogueService is autoloaded and orchestrates conversations, ambient barks, and effect dispatch. It exposes signals:

- conversation_started(graph_id, actor_id, node_id, context)
- snippet_ready(...) / snippet_display_completed(...)
- choice_presented(...) / choice_selected(...)
- conversation_finished(graph_id, actor_id, reason, summary)
- effect_fired(effect_id, payload, runtime)
- ark_fired(set_id, bark_id, snippet_id, payload)

The service also relays a subset to SignalBus for systems that prefer listening there (dialogue_started, dialogue_finished, dialogue_effect). Conversation state is deterministic: node selection honours priority, weight, cooldowns, and per-actor memory. Ambient barks respect cooldown scopes and expose both payloads and events so UI/effects can respond.

DialogueBox.tscn (instanced in World.tscn) handles snippet reveal, player choices, auto-advance, and choice buttons. It reads speaker display names from the registered actor state.

## Authoring Content

1. Create dialogue graphs in dialogue/content/graphs. See customer_intro.tres for a working example: snippets, choice nodes, and per-option effects (DialogueSetPropertyEffect).
2. Ambient bark sets live in dialogue/content/barks (example: customer_idle_barks.tres). The service scans both directories automatically on boot.
3. Graph metadata (e.g. metadata = {"actor_id": "customer"}) can be used by tooling or downstream systems.

### Node & Resource Cheatsheet

- DialogueGraph (dialogue/resources/dialogue_graph.gd) – entry point. Lists nodes, metadata, entry node.
- DialogueLineNode – speaker, snippets, optional auto-advance.
- DialogueChoiceNode + DialogueChoiceOption – branching with per-option conditions/effects.
- DialogueSnippet – individual text chunk, tags, template variables, per-snippet effects (immediate / after display / after input).
- DialogueAmbientBarkSet + DialogueAmbientBark – context-aware barks with cooldown rules.
- DialogueConditionBlock + DialoguePropertyCondition – declarative filtering using context property paths.
- DialogueSetPropertyEffect – mutates context (global.*, ctor.*, etc.) and can emit named events for other systems.

## NPC Integration

scripts/customer.gd now demonstrates:

- Actor registration (egister_actor) with display name.
- Proximity-based interaction using ui_accept to start dialogue_graph_id.
- Periodic ambient bark requests (mbient_bark_set_id) with simple floating text feedback.
- Reacting to DialogueService.bark_fired events for local presentation.

To add a new NPC:

1. Export desired graph/bark IDs on the character script (or set them in the inspector).
2. Register the actor in _ready() with any authoring metadata (display name, custom variables).
3. Trigger DialogueService.start_conversation(graph_id, actor_id, overrides) when appropriate (button press, quest hook, etc.). The overrides dictionary can seed context variables (ctor.position, player.relation, etc.).
4. Optionally call equest_ambient_bark(set_id, actor_id, overrides) on an interval or on state changes.

## Extending & Next Steps

- **Validation tooling** – add editor scripts to scan graphs for orphaned nodes, missing snippets, invalid property paths, etc.
- **Graph authoring UI** – lightweight editor plugin for visually editing DialogueGraph resources.
- **Multi-NPC scenes** – build a ConversationController scene that sequences scripted exchanges and camera cues.
- **Save/Load** – persist _global_state, per-actor memory, and active conversation progress via the save system.
- **Localization** – integrate string tables / translation server, leveraging 	emplate_variables for substitution.
- **Accessibility** – expose DialogueBox options (font size, reveal speed) through settings.

## Quick Tips

- Conditions, effects, and snippets are Resources—compose rather than hardcode logic.
- Use context paths like global.flags.some_flag, ctor.memory.last_gift, player.stats.charisma in property conditions.
- Connect to DialogueService.effect_fired or SignalBus.dialogue_effect to hook into quests, inventory, etc.
- Barks run even while no conversation is active; filter payload["actor_id"] to route responses per NPC.

