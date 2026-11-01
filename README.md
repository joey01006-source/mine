# Lua voxel terrain

Minecraft-style terrain generation in **hi.lua**, using Lua 5.3 or newer and no
external Lua libraries. Generates seeded hills, grass, dirt, stone, sandy shores,
water, and trees, exporting only exposed block faces.

## Windows / VS Code

1. Install Lua 5.3 or newer from a trusted distribution linked at
   [lua.org](https://www.lua.org/start.html#installing). Add its executable directory
   to your Windows user **Path**, then fully restart VS Code.
2. In VS Code's terminal, run `lua -v` to verify the installation. This script uses
   Lua 5.3 integer/bitwise operations; Lua 5.1, LuaJIT, and Roblox Luau are not supported.
3. Open the entire **mine folder** in VS Code and press **Ctrl+Shift+B**, or choose
   **Terminal → Run Task → Voxel: generate world (Lua)**.
4. Open the generated **world.html** from your file manager in a WebGL-capable
   browser. Drag to orbit and scroll to zoom. Opening it in the VS Code editor
   shows its source rather than the terrain.

You can also run directly from the project folder in PowerShell, macOS, or Linux:

```sh
lua hi.lua 42 48 world
```

If your Lua executable is named `lua54` or `lua5.4`, use that name instead of `lua`
and update the task's `command` in `.vscode/tasks.json` accordingly. A Lua editor
extension provides editing assistance; it does not install the Lua interpreter.

## Outputs and options

- `world.html`: self-contained, offline interactive 3D viewer.
- `world.obj` and `world.mtl`: mesh and colors for importing into a 3D editor.

Usage: `lua hi.lua [seed] [width] [output prefix]`.
Defaults: seed `42`, width `48`, prefix `world`. Seeds range from 0 to 4294967295;
width ranges from 16 to 128. The world is 48 blocks tall. The output directory must
already exist. Reusing a prefix replaces its files.

The program exits after generating files; it does not open a game window.
This version provides terrain viewing, without player movement or block editing.
The previous C++ version has been removed; no C++ compiler is required.
