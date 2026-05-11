# Project Structure

This Godot project is organized by responsibility:

- `scenes/` contains `.tscn` scene files only.
- `scripts/` contains GDScript code and script UIDs.
- `resources/` contains data resources, themes, materials, generated level data, and translations.
- `assets/` contains imported art, sprites, UI images, fonts, audio, and shaders.
- `tests/` contains automated test scenes and scripts.
- `examples/` contains sample/demo resources separated from the game code.
- `docs/` contains project documentation.
- `exports/` contains local export outputs.
- `addons/`, `Dialogic/`, and `ios_plugins/` remain at the project root because Godot plugins and tooling expect those locations.

When adding new files, prefer mirroring the same domain path in `scenes/` and `scripts/`. For example, a player scene belongs under `scenes/actors/player/` and its script belongs under `scripts/actors/player/`.
