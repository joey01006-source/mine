# Voxel terrain

A dependency-free C++17 terrain generator with seeded hills, layered grass/dirt/stone,
sandy shores, water, and trees. Only exposed block faces are exported.

## Run in VS Code

1. Install a C++ compiler (see below). VS Code itself does not include one.
2. Open the **mine folder** with **File → Open Folder**, so `.vscode/tasks.json`
   is part of your workspace. Trust the folder if you trust this source code.
3. Press **Ctrl+Shift+B** (**Cmd+Shift+B** on macOS). The included task compiles
   `hi.c++` and runs the generator. You can also choose **Terminal → Run Task →
   Voxel: build and generate world**.
4. Open the generated **world.html** in your web browser using your file manager.
   Drag to orbit and scroll to zoom. VS Code's text editor displays HTML source;
   the browser displays the terrain.

The generator exits after writing its files. It does not open a native game window.
The message **"The executable you want to run does not (yet) exist"** means the
editor tried to launch the program before it was compiled, or used the wrong path.
This project now includes a launch configuration that builds `hi.c++` first and
runs the resulting `voxel.exe` on Windows.

For the **Run and Debug** button or **F5** on Windows:

1. Install Microsoft's **C/C++** VS Code extension (`ms-vscode.cpptools`).
2. Install the compiler and GDB debugger described below, then restart VS Code.
3. In **Run and Debug**, select **Voxel: build and run C++**, then press **F5**.
   Its `preLaunchTask` builds the executable automatically. If compilation fails,
   fix the terminal error rather than choosing **Debug Anyway**.

**Ctrl+Shift+B** builds and generates the world without needing GDB. Use this
route if you only want to view terrain. The generated `world.html` still needs
to be opened in a browser.

### Install a compiler

- **Windows:** Install [MSYS2](https://www.msys2.org/), open its **UCRT64** terminal,
  and run `pacman -S --needed mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-gdb`. Add the installation's
  `ucrt64\bin` directory (normally `C:\msys64\ucrt64\bin`) to your Windows user
  **Path**, then fully restart VS Code. Run `g++ --version` in a new VS Code terminal
  to confirm it is available. For F5, also check `gdb --version`. The task uses
  this compiler to create `voxel.exe` in the project folder.
- **macOS:** Run `xcode-select --install` in Terminal. After installation,
  `clang++ --version` should work; the macOS task uses `clang++`.
- **Ubuntu/Debian Linux:** Run `sudo apt update` then `sudo apt install build-essential`.
  Confirm `g++ --version` works in VS Code's terminal.

If the task reports that `g++` cannot be found, the compiler is missing or its
directory is absent from the Path inherited by VS Code. If no Voxel task is listed,
open the repository folder rather than just `hi.c++`.

## Run from a terminal

From the repository folder on Linux/macOS:

```sh
g++ -std=c++17 -O2 -Wall -Wextra -pedantic hi.c++ -o voxel
./voxel 42 48 world
```

On Windows, with the compiler above installed, use PowerShell:

```powershell
g++ -std=c++17 -O2 -Wall -Wextra -pedantic hi.c++ -o voxel.exe
.\voxel.exe 42 48 world
```

Open `world.html` in a WebGL-capable browser. Drag to orbit and scroll to zoom.
The viewer is self-contained and works offline. Import `world.obj` into a 3D
editor with `world.mtl` alongside it to retain block colors.

Arguments: `voxel [seed] [width] [output prefix]`. Defaults: `42`, `48`, `world`.
Seeds range from 0 to 4294967295; width ranges from 16 to 128 blocks. The world is
48 blocks tall. The output directory must already exist. Reusing a prefix replaces
its generated files. This is a terrain viewer, without player movement or block editing.
