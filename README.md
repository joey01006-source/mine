# C++ voxel terrain

Minecraft-style terrain generation in **hi.c++**, with seeded hills, trees, grass,
dirt, stone, sandy shores, and water. No third-party C++ libraries. Includes an
interactive offline browser viewer and OBJ export. Rust and Lua are not used.

## View it now

Open **terrain.html** from Windows File Explorer in Edge, Chrome, or Firefox.
This included sample needs no compiler or VS Code extensions. Drag to rotate;
scroll to zoom.

## Windows: build and open your world

1. Install [MSYS2](https://www.msys2.org/). Open its **UCRT64** terminal and run:
   `pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-gdb`
2. Add `C:\msys64\ucrt64\bin` (or your installation's `ucrt64\bin`) to your Windows
   user **Path**. Fully restart VS Code.
3. Double-click **run.cmd**. It compiles `hi.c++`, generates the terrain, and opens
   **world.html** in your default browser. On failure the window stays open with
   the error. The launcher also checks MSYS2's default install location.

In VS Code, open the entire **mine folder** and press **Ctrl+Shift+B**. The default
build task runs the same launcher on Windows. No separate executable has to exist
before you run it.

For **F5 debugging**, install Microsoft's **C/C++** extension and select
**Voxel: build and run C++** in Run and Debug. Check `g++ --version` and
`gdb --version` in the VS Code terminal first. The debugger builds automatically,
then writes the output files; open `world.html` manually after debugging.
The extension's license banner is informational. If compilation fails, read the
terminal error rather than choosing Debug Anyway.

## Terminal usage

Windows PowerShell, from the repository folder:

```powershell
g++ -std=c++17 -O2 hi.c++ -o voxel.exe
.\voxel.exe 42 48 world
```

Linux/macOS with a C++17 compiler installed:

```sh
sh run.sh
# Or choose a seed, size, and output prefix:
./voxel 123 64 custom-world
```

Open the generated HTML in a WebGL-capable browser. The program exits after writing
files; it does not launch a native game window. This version generates and displays
terrain, without player movement or block editing.

Arguments: `[seed] [width] [output prefix]`. Defaults: `42`, `48`, `world`.
Seed range: 0–4294967295. Width: 16–128 blocks. Height: 48 blocks.
The output directory must exist. Reusing a prefix overwrites its generated files.
`world.obj` and `world.mtl` can be imported together into a 3D editor.

If you downloaded a ZIP from GitHub, extract it before running. If you use Git,
update the project with `git pull origin main` before following these instructions.
