# Rust voxel terrain

Minecraft-style terrain generation in Rust: seeded hills, grass, dirt, stone,
water, sandy shores, and trees. No third-party Rust dependencies. Exports only
exposed block faces and includes an offline 3D browser viewer.

## Windows / VS Code

1. Install Rust using [rustup](https://rustup.rs/). Use the default Windows MSVC
   toolchain. If prompted, install **Visual Studio Build Tools** with **Desktop
   development with C++** (including the Windows SDK) for the system linker.
   This Rust project does not use the Microsoft C/C++ VS Code extension.
2. Fully restart VS Code. In its terminal, check `cargo --version` and `rustc --version`.
3. Open the entire **mine folder**. Install **rust-analyzer** (`rust-lang.rust-analyzer`)
   for Rust editing support.
4. Press **Ctrl+Shift+B**, or choose **Terminal → Run Task → Voxel: run Rust terrain generator**.
   Cargo compiles the program automatically before running it.
5. Open the generated **world.html** in a WebGL-capable browser using your file
   manager. Drag to orbit; scroll to zoom. Opening it in VS Code displays its source.

If you get an old executable-not-found message, choose the Cargo task above rather
than an old C++ debug configuration. The previous C++ source and launch setup have
been removed. If `cargo` is not recognized, install Rust and restart VS Code. A
`link.exe` error means the MSVC Build Tools/linker prerequisite is missing.

## Terminal usage

From the repository folder, on Windows, macOS, or Linux with Rust installed:

```sh
cargo run --release --locked -- 42 48 world
```

Arguments after `--`: `[seed] [width] [output prefix]`. Defaults: `42`, `48`, `world`.
Seeds range from 0 to 4294967295; width from 16 to 128 blocks. Height is 48 blocks.
The output directory must exist. Reusing a prefix overwrites its generated files.

Outputs:

- `world.html`: self-contained, interactive 3D viewer; no server or downloads needed.
- `world.obj` and `world.mtl`: terrain mesh and colors for a 3D editor.

The generator exits after writing files. It does not launch a native game window;
this is terrain generation and viewing, without player movement or block editing.

Run the Rust tests with `cargo test --locked`.
