use std::{
    env,
    error::Error,
    fs::File,
    io::{BufWriter, Write},
    path::Path,
};

const HEIGHT: i32 = 48;
const SEA: i32 = 17;
const COLORS: [&str; 8] = [
    "000000", "78ad48", "866044", "858c92", "d8ca8b", "498faf", "765037", "3d803e",
];
const NORMALS: [[i32; 3]; 6] = [
    [1, 0, 0],
    [-1, 0, 0],
    [0, 1, 0],
    [0, -1, 0],
    [0, 0, 1],
    [0, 0, -1],
];
const CORNERS: [[[i32; 3]; 4]; 6] = [
    [[1, 0, 0], [1, 1, 0], [1, 1, 1], [1, 0, 1]],
    [[0, 0, 1], [0, 1, 1], [0, 1, 0], [0, 0, 0]],
    [[0, 1, 1], [1, 1, 1], [1, 1, 0], [0, 1, 0]],
    [[0, 0, 0], [1, 0, 0], [1, 0, 1], [0, 0, 1]],
    [[1, 0, 1], [1, 1, 1], [0, 1, 1], [0, 0, 1]],
    [[0, 0, 0], [0, 1, 0], [1, 1, 0], [1, 0, 0]],
];

fn hash(x: i32, z: i32, seed: u32) -> u32 {
    let h = (x as u32)
        .wrapping_mul(374761393)
        .wrapping_add((z as u32).wrapping_mul(668265263))
        .wrapping_add(seed);
    let h = (h ^ (h >> 13)).wrapping_mul(1274126177);
    h ^ (h >> 16)
}
fn noise(x: f64, z: f64, seed: u32) -> f64 {
    let (ix, iz) = (x.floor() as i32, z.floor() as i32);
    let (u, v) = (x - f64::from(ix), z - f64::from(iz));
    let (u, v) = (u * u * (3.0 - 2.0 * u), v * v * (3.0 - 2.0 * v));
    let n = |a, b| f64::from(hash(a, b, seed)) / f64::from(u32::MAX);
    (1.0 - v) * ((1.0 - u) * n(ix, iz) + u * n(ix + 1, iz))
        + v * ((1.0 - u) * n(ix, iz + 1) + u * n(ix + 1, iz + 1))
}
#[derive(Debug, Clone, PartialEq, Eq)]
struct Face {
    x: i32,
    y: i32,
    z: i32,
    side: usize,
    block: u8,
}
struct World {
    size: i32,
    blocks: Vec<u8>,
}
impl World {
    fn new(size: i32) -> Self {
        Self {
            size,
            blocks: vec![0; (size * size * HEIGHT) as usize],
        }
    }
    fn index(&self, x: i32, y: i32, z: i32) -> Option<usize> {
        if (0..self.size).contains(&x) && (0..HEIGHT).contains(&y) && (0..self.size).contains(&z) {
            Some(((x * self.size + z) * HEIGHT + y) as usize)
        } else {
            None
        }
    }
    fn get(&self, x: i32, y: i32, z: i32) -> u8 {
        self.index(x, y, z).map_or(0, |i| self.blocks[i])
    }
    fn put(&mut self, x: i32, y: i32, z: i32, b: u8) {
        if let Some(i) = self.index(x, y, z) {
            self.blocks[i] = b;
        }
    }
    fn generate(size: i32, seed: u32) -> Self {
        let mut world = Self::new(size);
        let mut tops = vec![0; (size * size) as usize];
        for x in 0..size {
            for z in 0..size {
                let (xf, zf) = (f64::from(x), f64::from(z));
                let top = (9.0
                    + 19.0 * noise(xf / 23.0, zf / 23.0, seed)
                    + 7.0 * noise(xf / 9.0, zf / 9.0, seed)
                    + 3.0 * noise(xf / 3.0, zf / 3.0, seed)) as i32;
                tops[(x * size + z) as usize] = top;
                for y in 0..=top.max(SEA) {
                    let b = if y > top {
                        5
                    } else if y == top {
                        if top <= SEA + 1 {
                            4
                        } else {
                            1
                        }
                    } else if y > top - 4 {
                        2
                    } else {
                        3
                    };
                    world.put(x, y, z, b);
                }
            }
        }
        for x in 3..size - 3 {
            for z in 3..size - 3 {
                let top = tops[(x * size + z) as usize];
                if top <= SEA + 1 || hash(x, z, seed) % 53 != 0 {
                    continue;
                }
                let trunk = 4 + (hash(z, x, seed) % 2) as i32;
                for y in top + trunk - 2..=top + trunk + 1 {
                    for dx in -2_i32..=2 {
                        for dz in -2_i32..=2 {
                            if dx.abs() + dz.abs() <= 3 && world.get(x + dx, y, z + dz) == 0 {
                                world.put(x + dx, y, z + dz, 7);
                            }
                        }
                    }
                }
                for y in top + 1..=top + trunk {
                    world.put(x, y, z, 6);
                }
            }
        }
        world
    }
    fn faces(&self) -> Vec<Face> {
        let mut faces = Vec::new();
        for x in 0..self.size {
            for z in 0..self.size {
                for y in 0..HEIGHT {
                    let block = self.get(x, y, z);
                    if block == 0 {
                        continue;
                    }
                    for (side, n) in NORMALS.iter().enumerate() {
                        let adjacent = self.get(x + n[0], y + n[1], z + n[2]);
                        if adjacent == 0 || (adjacent == 5 && block != 5) {
                            faces.push(Face {
                                x,
                                y,
                                z,
                                side,
                                block,
                            });
                        }
                    }
                }
            }
        }
        faces
    }
}
fn number(value: Option<&String>, default: u32) -> Result<u32, Box<dyn Error>> {
    match value {
        None => Ok(default),
        Some(v) if !v.is_empty() && v.bytes().all(|b| b.is_ascii_digit()) => Ok(v.parse()?),
        _ => Err("Seed and width must be nonnegative integers".into()),
    }
}
fn output(prefix: &str, extension: &str) -> Result<BufWriter<File>, Box<dyn Error>> {
    Ok(BufWriter::new(File::create(format!(
        "{prefix}.{extension}"
    ))?))
}
fn run() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().skip(1).collect();
    if args.len() > 3 {
        return Err("Usage: cargo run --release -- [seed] [width: 16..128] [output prefix]".into());
    }
    let seed = number(args.first(), 42)?;
    let size = number(args.get(1), 48)?;
    if !(16..=128).contains(&size) {
        return Err("Width must be between 16 and 128".into());
    }
    let prefix = args.get(2).map_or("world", String::as_str);
    if prefix.contains(['\n', '\r']) {
        return Err("Output prefix cannot contain newlines".into());
    }
    let faces = World::generate(size as i32, seed).faces();
    let mut html = output(prefix, "html")?;
    write!(
        html,
        "{}Seed {seed} · {size} × {size} blocks</p></aside><script>\nconst size={size}, faces=[\n",
        include_str!("viewer-head.html")
    )?;
    for f in &faces {
        writeln!(html, "[{},{},{},{},{}],", f.x, f.y, f.z, f.side, f.block)?;
    }
    write!(
        html,
        "], {}",
        include_str!("viewer-tail.js").replace("__SIZE__", &size.to_string())
    )?;
    html.flush()?;
    let mut obj = output(prefix, "obj")?;
    let mut mtl = output(prefix, "mtl")?;
    let basename = Path::new(prefix)
        .file_name()
        .ok_or("Output prefix must include a filename")?
        .to_string_lossy();
    writeln!(obj, "# Seed {seed}\nmtllib {basename}.mtl")?;
    for (b, color) in COLORS.iter().enumerate().skip(1) {
        let rgb = u32::from_str_radix(color, 16)?;
        writeln!(
            mtl,
            "newmtl block{b}\nKd {} {} {}\n",
            f64::from((rgb >> 16) & 255) / 255.0,
            f64::from((rgb >> 8) & 255) / 255.0,
            f64::from(rgb & 255) / 255.0
        )?;
    }
    for (i, f) in faces.iter().enumerate() {
        for c in CORNERS[f.side] {
            writeln!(obj, "v {} {} {}", f.x + c[0], f.y + c[1], f.z + c[2])?;
        }
        let v = 4 * i + 1;
        writeln!(
            obj,
            "usemtl block{}\nf {} {} {} {}",
            f.block,
            v,
            v + 1,
            v + 2,
            v + 3
        )?;
    }
    obj.flush()?;
    mtl.flush()?;
    println!("Generated {} exposed faces. Open {prefix}.html in a browser, or import {prefix}.obj into a 3D editor.",faces.len());
    Ok(())
}
fn main() {
    if let Err(e) = run() {
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn terrain_is_repeatable_and_seeded() {
        let a = World::generate(32, 42);
        assert_eq!(a.blocks, World::generate(32, 42).blocks);
        assert_ne!(a.blocks, World::generate(32, 43).blocks);
        for b in 1..=7 {
            assert!(
                World::generate(48, 42).blocks.contains(&b),
                "Missing block type {b}"
            );
        }
    }
    #[test]
    fn mesh_culls_shared_faces() {
        let mut w = World::new(16);
        w.put(1, 1, 1, 3);
        assert_eq!(w.faces().len(), 6);
        w.put(2, 1, 1, 3);
        assert_eq!(w.faces().len(), 10);
        assert_eq!(w.get(-1, 1, 1), 0);
        assert_eq!(w.get(16, 1, 1), 0);
    }
    #[test]
    fn water_does_not_hide_solid_faces() {
        let mut w = World::new(16);
        w.put(1, 1, 1, 3);
        w.put(2, 1, 1, 5);
        let f = w.faces();
        assert_eq!(f.len(), 11);
        assert!(f.iter().any(|f| f.block == 3 && f.side == 0));
        assert!(!f.iter().any(|f| f.block == 5 && f.side == 1));
    }
}
