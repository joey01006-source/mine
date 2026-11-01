#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

// Build: g++ -std=c++17 -O2 -Wall -Wextra -pedantic hi.c++ -o voxel
// Run: ./voxel [seed] [width: 16..128] [output prefix]
namespace {
constexpr int height = 48, sea = 17;
enum Block { Air, Grass, Dirt, Stone, Sand, Water, Wood, Leaves };
const std::array<const char*, 8> colors = {
    "#000000", "#78ad48", "#866044", "#858c92", "#d8ca8b",
    "#498faf", "#765037", "#3d803e"};
std::uint32_t seed;
std::uint32_t hash(int x, int z) {
    std::uint32_t h = static_cast<std::uint32_t>(x) * 374761393u
                    + static_cast<std::uint32_t>(z) * 668265263u + seed;
    h = (h ^ (h >> 13)) * 1274126177u;
    return h ^ (h >> 16);
}
double noise(double x, double z) {
    int ix = static_cast<int>(std::floor(x)), iz = static_cast<int>(std::floor(z));
    double u = x - ix, v = z - iz;
    u = u * u * (3 - 2 * u); v = v * v * (3 - 2 * v);
    auto n = [](int a, int b) { return hash(a, b) / 4294967295.0; };
    return (1-v)*((1-u)*n(ix,iz)+u*n(ix+1,iz))
               +v*((1-u)*n(ix,iz+1)+u*n(ix+1,iz+1));
}
struct Face { int x, y, z, side, block; };
constexpr int normals[6][3] = {{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}};
// Counterclockwise corners viewed from outside.
constexpr int corners[6][4][3] = {
    {{1,0,0},{1,1,0},{1,1,1},{1,0,1}},
    {{0,0,1},{0,1,1},{0,1,0},{0,0,0}},
    {{0,1,1},{1,1,1},{1,1,0},{0,1,0}},
    {{0,0,0},{1,0,0},{1,0,1},{0,0,1}},
    {{1,0,1},{1,1,1},{0,1,1},{0,0,1}},
    {{0,0,0},{0,1,0},{1,1,0},{1,0,0}}
};
}
int main(int argc, char** argv) {
    try {
        if (argc > 4) throw std::runtime_error("Usage: voxel [seed] [width: 16..128] [output prefix]");
        auto number = [](const char* s, unsigned long long limit) {
            std::string text(s); std::size_t used = 0;
            if (text.empty() || text.find_first_not_of("0123456789") != std::string::npos)
                throw std::runtime_error("Seed and width must be nonnegative integers");
            auto n = std::stoull(text, &used);
            if (used != text.size() || n > limit) throw std::runtime_error("Number out of range");
            return n;
        };
        seed = argc > 1 ? static_cast<std::uint32_t>(number(argv[1], UINT32_MAX)) : 42;
        int size = argc > 2 ? static_cast<int>(number(argv[2], 128)) : 48;
        if (size < 16) throw std::runtime_error("Width must be between 16 and 128");
        std::string prefix = argc > 3 ? argv[3] : "world";
        std::vector<unsigned char> blocks(size * size * height, Air);
        auto index = [=](int x,int y,int z) { return (x*size+z)*height+y; };
        auto get = [&](int x,int y,int z) -> int {
            return x<0 || z<0 || y<0 || x>=size || z>=size || y>=height
                ? static_cast<int>(Air) : static_cast<int>(blocks[index(x,y,z)]);
        };
        auto put = [&](int x,int y,int z,int b) {
            if(x>=0 && z>=0 && y>=0 && x<size && z<size && y<height)
                blocks[index(x,y,z)] = static_cast<unsigned char>(b);
        };
        std::vector<int> tops(size*size);
        for(int x=0;x<size;++x) for(int z=0;z<size;++z) {
            int top = static_cast<int>(9 + 19*noise(x/23.0,z/23.0)
                                        + 7*noise(x/9.0,z/9.0) + 3*noise(x/3.0,z/3.0));
            tops[x*size+z]=top;
            for(int y=0;y<=std::max(top,sea);++y)
                put(x,y,z,y>top ? Water : y==top ? (top<=sea+1?Sand:Grass)
                    : y>top-4 ? Dirt : Stone);
        }
        for(int x=3;x<size-3;++x) for(int z=3;z<size-3;++z) {
            int top=tops[x*size+z];
            if(top<=sea+1 || hash(x,z)%53!=0) continue;
            int trunk=4+static_cast<int>(hash(z,x)%2);
            for(int y=top+trunk-2;y<=top+trunk+1;++y)
                for(int dx=-2;dx<=2;++dx) for(int dz=-2;dz<=2;++dz)
                    if(std::abs(dx)+std::abs(dz)<=3 && get(x+dx,y,z+dz)==Air)
                        put(x+dx,y,z+dz,Leaves);
            for(int y=top+1;y<=top+trunk;++y) put(x,y,z,Wood);
        }
        std::vector<Face> faces;
        for(int x=0;x<size;++x) for(int z=0;z<size;++z) for(int y=0;y<height;++y) {
            int b=get(x,y,z); if(b==Air) continue;
            for(int s=0;s<6;++s) {
                int adjacent=get(x+normals[s][0],y+normals[s][1],z+normals[s][2]);
                if(adjacent==Air || (adjacent==Water && b!=Water)) faces.push_back({x,y,z,s,b});
            }
        }
        std::ofstream obj(prefix+".obj"), mtl(prefix+".mtl"), html(prefix+".html");
        if(!obj || !mtl || !html) throw std::runtime_error("Cannot open output files");
        std::string basename=prefix.substr(prefix.find_last_of("/\\")+1);
        obj<<"# Seed "<<seed<<"\nmtllib "<<basename<<".mtl\n";
        for(int b=1;b<=Leaves;++b) {
            unsigned rgb=static_cast<unsigned>(std::stoul(colors[b]+1,nullptr,16));
            mtl<<"newmtl block"<<b<<"\nKd "<<((rgb>>16)&255)/255.0<<' '
               <<((rgb>>8)&255)/255.0<<' '<<(rgb&255)/255.0<<"\n\n";
        }
        std::size_t vertex=1;
        for(const auto& f:faces) {
            for(const auto& c:corners[f.side]) obj<<"v "<<f.x+c[0]<<' '<<f.y+c[1]<<' '<<f.z+c[2]<<'\n';
            obj<<"usemtl block"<<f.block<<"\nf "<<vertex<<' '<<vertex+1<<' '<<vertex+2<<' '<<vertex+3<<'\n';
            vertex+=4;
        }
        html<<R"HTML(<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Voxel terrain</title><style>body{margin:0;overflow:hidden;background:#bedced;font:14px system-ui;color:#142a32}canvas{display:block;touch-action:none}aside{position:fixed;top:18px;left:18px;background:#ffffffe0;padding:16px 20px;border-radius:12px;pointer-events:none}h1{font-size:20px;margin:0 0 6px}p{margin:4px 0}</style>
<canvas aria-label="Interactive voxel terrain"></canvas><aside><h1>Voxel terrain</h1><p>Drag to orbit · Scroll to zoom</p><p>)HTML";
        html<<"Seed "<<seed<<" · "<<size<<" × "<<size<<" blocks</p></aside><script>\nconst size="<<size<<", faces=[\n";
        for(const auto& f:faces) html<<'['<<f.x<<','<<f.y<<','<<f.z<<','<<f.side<<','<<f.block<<"],\n";
        html<<"], corners=";
        html<<'[';
        for(int s=0;s<6;++s) { if(s) html<<','; html<<'[';
            for(int c=0;c<4;++c) { if(c) html<<','; html<<'['<<corners[s][c][0]<<','<<corners[s][c][1]<<','<<corners[s][c][2]<<']'; }
            html<<']'; }
        html<<"], colors=[";
        for(int b=0;b<=Leaves;++b) { if(b) html<<','; html<<'"'<<colors[b]<<'"'; }
        html<<R"HTML(];
const canvas=document.querySelector('canvas'), gl=canvas.getContext('webgl');
if(!gl){document.querySelector('aside').textContent='This viewer requires a browser with WebGL enabled.';throw Error('WebGL unavailable');}
function shader(type,source){const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s;}
const program=gl.createProgram();
gl.attachShader(program,shader(gl.VERTEX_SHADER,`attribute vec3 position;attribute vec3 color;uniform vec2 viewport;uniform vec3 camera;varying vec3 tint;
void main(){vec3 p=position-vec3(float()HTML"<<size<<R"HTML()/2.0,18.0,float()HTML"<<size<<R"HTML()/2.0);
float a=camera.x,b=camera.y;float x=cos(a)*p.x-sin(a)*p.z;float z=sin(a)*p.x+cos(a)*p.z;
float y=cos(b)*p.y-sin(b)*z;float depth=sin(b)*p.y+cos(b)*z;
gl_Position=vec4(x*camera.z*2.0/viewport.x,y*camera.z*2.0/viewport.y,-depth/300.0,1.0);tint=color;}`));
gl.attachShader(program,shader(gl.FRAGMENT_SHADER,'precision mediump float;varying vec3 tint;void main(){gl_FragColor=vec4(tint,1.0);}'));
gl.linkProgram(program);if(!gl.getProgramParameter(program,gl.LINK_STATUS))throw Error(gl.getProgramInfoLog(program));gl.useProgram(program);
const vertices=[], light=[0.78,0.60,1,0.45,0.85,0.68];
for(const [x,y,z,s,b] of faces){const rgb=colors[b].slice(1).match(/../g).map(v=>parseInt(v,16)/255*light[s]);for(const c of [0,1,2,0,2,3])vertices.push(x+corners[s][c][0],y+corners[s][c][1],z+corners[s][c][2],...rgb);}
gl.bindBuffer(gl.ARRAY_BUFFER,gl.createBuffer());gl.bufferData(gl.ARRAY_BUFFER,new Float32Array(vertices),gl.STATIC_DRAW);
for(const [name,offset] of [['position',0],['color',12]]){const a=gl.getAttribLocation(program,name);gl.enableVertexAttribArray(a);gl.vertexAttribPointer(a,3,gl.FLOAT,false,24,offset);}
const view=gl.getUniformLocation(program,'viewport'),cam=gl.getUniformLocation(program,'camera');
let angle=-0.7,tilt=0.65,zoom=1,drag=null;
function draw(){const ratio=Math.min(devicePixelRatio||1,2);canvas.width=Math.round(innerWidth*ratio);canvas.height=Math.round(innerHeight*ratio);gl.viewport(0,0,canvas.width,canvas.height);gl.clearColor(0.745,0.863,0.929,1);gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);gl.enable(gl.DEPTH_TEST);gl.uniform2f(view,canvas.width,canvas.height);gl.uniform3f(cam,angle,tilt,Math.min(canvas.width,canvas.height)/(size*1.7)*zoom);gl.drawArrays(gl.TRIANGLES,0,vertices.length/6);}
canvas.onpointerdown=e=>{drag=[e.clientX,e.clientY];canvas.setPointerCapture(e.pointerId);};
canvas.onpointermove=e=>{if(!drag)return;angle+=(e.clientX-drag[0])*0.008;tilt=Math.max(0.1,Math.min(1.5,tilt+(e.clientY-drag[1])*0.008));drag=[e.clientX,e.clientY];draw();};
canvas.onpointerup=canvas.onpointercancel=()=>drag=null;
canvas.addEventListener('wheel',e=>{e.preventDefault();zoom=Math.max(0.3,Math.min(5,zoom*Math.exp(-e.deltaY*0.001)));draw();},{passive:false});
addEventListener('resize',draw);draw();
</script></html>)HTML";
        obj.close(); mtl.close(); html.close();
        if(!obj || !mtl || !html) throw std::runtime_error("Failed to write outputs");
        std::cout<<"Generated "<<faces.size()<<" exposed faces. Open "<<prefix<<".html in a browser, or import "<<prefix<<".obj into a 3D editor.\n";
    } catch(const std::exception& e) { std::cerr<<"Error: "<<e.what()<<'\n'; return 1; }
}
