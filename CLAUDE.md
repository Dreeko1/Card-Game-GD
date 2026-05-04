# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Godot 4.6 solitaire card game — GDScript only, Forward Plus renderer, D3D12 on Windows, Jolt Physics.

## Running the project

There is no CLI build system. All runs and exports go through the Godot editor or the headless binary:

```bash
# Run from editor (normal workflow)
# Open D:/GodotGS/project-test in Godot 4.6 and press F5

# Headless run (CI / command line)
godot --path . --headless
```

GDScript has no standalone test runner. Logic can be validated by running the project and checking output in the Godot console, or by writing a temporary `@tool` script and executing it from the editor.

## Architecture

The game uses three pure-data classes and one autoloaded manager:

- **`Card`** (`scripts/card.gd`) — `RefCounted`, no node. Holds `value: int` (1–13), `suit: Card.Suit` (enum), and a derived `card_name: String`. Instantiate with `Card.new(value, suit)`.
- **`Deck`** (`scripts/deck.gd`) — `RefCounted`, no node. Builds a 30-card deck (values 1–10, suits CUORI/QUADRI/FIORI) on `_init`. Key API: `shuffle()`, `draw() -> Card`, `remaining() -> int`, `is_empty() -> bool`.
- **`GameManager`** (`scripts/game_manager.gd`) — autoloaded `Node`. Single source of truth for game state (`IDLE / PLAYING / GAME_OVER`), the active `Deck`, the player's `hand: Array[Card]`, and `score: int`. Emits `state_changed`, `card_drawn`, `deck_empty`. Call `GameManager.draw_card()` from any node; connect to its signals rather than polling state.
- **`scenes/`** — empty, reserved for `.tscn` scene files.

## Conventions

- Data objects extend `RefCounted`; only nodes that need the scene tree extend `Node`.
- Typed arrays (`Array[Card]`) and typed return values are used throughout — keep this consistent.
- `Card.Suit.PICCHE` is defined in the enum but intentionally excluded from `Deck.SUITS`; the active deck is 3-suit only.
- `GameManager` starts a new game automatically in `_ready()`. Calling `new_game()` resets everything including score.
