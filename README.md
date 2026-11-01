# Voxel terrain

A dependency-free C++17 terrain generator with seeded hills, layered grass/dirt/stone,
sandy shores, water, and trees. Only exposed block faces are exported.

```sh
g++ -std=c++17 -O2 -Wall -Wextra -pedantic hi.c++ -o /tmp/voxel
/tmp/voxel 42 48 /tmp/world
```

Open `/tmp/world.html` in a WebGL-capable browser. Drag to orbit and scroll to zoom.
The viewer is self-contained and works offline. Import `/tmp/world.obj` into a 3D
editor with `/tmp/world.mtl` alongside it to retain block colors.

Arguments: `voxel [seed] [width] [output prefix]`. Defaults: `42`, `48`, `world`.
Seeds range from 0 to 4294967295; width ranges from 16 to 128 blocks. The world is
48 blocks tall. The output directory must already exist. Reusing a prefix replaces
its generated files. This is a terrain viewer, without player movement or block editing.
