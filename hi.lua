-- Minecraft-style voxel terrain. Requires Lua 5.3 or newer.
-- Run: lua hi.lua [seed] [width: 16..128] [output prefix]
local function integer(value, default, limit)
  if value == nil then return default end
  assert(value:match('^%d+$'), 'Seed and width must be nonnegative integers')
  local n = tonumber(value)
  assert(n and n <= limit and n % 1 == 0, 'Number out of range')
  return n
end
local INTRO = [==[<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Voxel terrain</title><style>body{margin:0;overflow:hidden;background:#bedced;font:14px system-ui;color:#142a32}canvas{display:block;touch-action:none}aside{position:fixed;top:18px;left:18px;background:#ffffffe0;padding:16px 20px;border-radius:12px;pointer-events:none}h1{font-size:20px;margin:0 0 6px}p{margin:4px 0}</style>
<canvas aria-label="Interactive voxel terrain"></canvas><aside><h1>Voxel terrain</h1><p>Drag to orbit · Scroll to zoom</p>]==]
local VIEWER = [==[corners=[[[1,0,0],[1,1,0],[1,1,1],[1,0,1]],[[0,0,1],[0,1,1],[0,1,0],[0,0,0]],[[0,1,1],[1,1,1],[1,1,0],[0,1,0]],[[0,0,0],[1,0,0],[1,0,1],[0,0,1]],[[1,0,1],[1,1,1],[0,1,1],[0,0,1]],[[0,0,0],[0,1,0],[1,1,0],[1,0,0]]], colors=["#000000","#78ad48","#866044","#858c92","#d8ca8b","#498faf","#765037","#3d803e"];
const canvas=document.querySelector('canvas'), gl=canvas.getContext('webgl');
if(!gl){document.querySelector('aside').textContent='This viewer requires a browser with WebGL enabled.';throw Error('WebGL unavailable');}
function shader(type,source){const s=gl.createShader(type);gl.shaderSource(s,source);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw Error(gl.getShaderInfoLog(s));return s;}
const program=gl.createProgram();
gl.attachShader(program,shader(gl.VERTEX_SHADER,`attribute vec3 position;attribute vec3 color;uniform vec2 viewport;uniform vec3 camera;varying vec3 tint;
void main(){vec3 p=position-vec3(float(__SIZE__)/2.0,18.0,float(__SIZE__)/2.0);
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
</script></html>]==]
local function main()
  assert(#arg <= 3, 'Usage: lua hi.lua [seed] [width: 16..128] [output prefix]')
  local seed = integer(arg[1], 42, 4294967295)
  local size = integer(arg[2], 48, 128)
  assert(size >= 16, 'Width must be between 16 and 128')
  local prefix = arg[3] or 'world'
  assert(not prefix:find('[\r\n]'), 'Output prefix cannot contain newlines')
  local height, sea = 48, 17
  local colors = {'78ad48', '866044', '858c92', 'd8ca8b', '498faf', '765037', '3d803e'}
  local function hash(x,z)
    local h = (x*374761393 + z*668265263 + seed) & 0xffffffff
    h = ((h ~ (h >> 13))*1274126177) & 0xffffffff
    return (h ~ (h >> 16)) & 0xffffffff
  end
  local function noise(x,z)
    local ix,iz = math.floor(x),math.floor(z)
    local u,v = x-ix,z-iz
    u,v = u*u*(3-2*u),v*v*(3-2*v)
    local function n(a,b) return hash(a,b)/4294967295 end
    return (1-v)*((1-u)*n(ix,iz)+u*n(ix+1,iz))+v*((1-u)*n(ix,iz+1)+u*n(ix+1,iz+1))
  end
  local blocks,tops = {},{}
  local function index(x,y,z) return (x*size+z)*height+y+1 end
  local function get(x,y,z)
    if x<0 or z<0 or y<0 or x>=size or z>=size or y>=height then return 0 end
    return blocks[index(x,y,z)] or 0
  end
  local function put(x,y,z,b)
    if x>=0 and z>=0 and y>=0 and x<size and z<size and y<height then blocks[index(x,y,z)]=b end
  end
  for x=0,size-1 do for z=0,size-1 do
    local top=math.floor(9+19*noise(x/23,z/23)+7*noise(x/9,z/9)+3*noise(x/3,z/3))
    tops[x*size+z]=top
    for y=0,math.max(top,sea) do
      local b=3
      if y>top then b=5
      elseif y==top then b=top<=sea+1 and 4 or 1
      elseif y>top-4 then b=2 end
      put(x,y,z,b)
    end
  end end
  for x=3,size-4 do for z=3,size-4 do
    local top=tops[x*size+z]
    if top>sea+1 and hash(x,z)%53==0 then
      local trunk=4+hash(z,x)%2
      for y=top+trunk-2,top+trunk+1 do
        for dx=-2,2 do for dz=-2,2 do
          if math.abs(dx)+math.abs(dz)<=3 and get(x+dx,y,z+dz)==0 then put(x+dx,y,z+dz,7) end
        end end
      end
      for y=top+1,top+trunk do put(x,y,z,6) end
    end
  end end
  local normals={{1,0,0},{-1,0,0},{0,1,0},{0,-1,0},{0,0,1},{0,0,-1}}
  local corners={
    {{1,0,0},{1,1,0},{1,1,1},{1,0,1}}, {{0,0,1},{0,1,1},{0,1,0},{0,0,0}},
    {{0,1,1},{1,1,1},{1,1,0},{0,1,0}}, {{0,0,0},{1,0,0},{1,0,1},{0,0,1}},
    {{1,0,1},{1,1,1},{0,1,1},{0,0,1}}, {{0,0,0},{0,1,0},{1,1,0},{1,0,0}}}
  local faces={}
  for x=0,size-1 do for z=0,size-1 do for y=0,height-1 do
    local b=get(x,y,z)
    if b~=0 then for s,n in ipairs(normals) do
      local neighbor=get(x+n[1],y+n[2],z+n[3])
      if neighbor==0 or (neighbor==5 and b~=5) then faces[#faces+1]={x,y,z,s,b} end
    end end
  end end end
  local function open(ext) return assert(io.open(prefix..ext,'w')) end
  local function write(file,...) assert(file:write(...)) end
  local function close(file) assert(file:close()) end
  local html=open('.html')
  write(html,INTRO,('Seed %d · %d × %d blocks</p></aside><script>\nconst size=%d, faces=[\n'):format(seed,size,size,size))
  for _,f in ipairs(faces) do write(html,('[%d,%d,%d,%d,%d],\n'):format(f[1],f[2],f[3],f[4]-1,f[5])) end
  write(html,'], ',(VIEWER:gsub('__SIZE__',tostring(size))))
  close(html)
  local obj,mtl=open('.obj'),open('.mtl')
  local basename=prefix:match('([^/\\]+)$') or prefix
  write(obj,('# Seed %d\nmtllib %s.mtl\n'):format(seed,basename))
  for b,color in ipairs(colors) do
    local rgb=tonumber(color,16)
    write(mtl,('newmtl block%d\nKd %.6f %.6f %.6f\n\n'):format(b,((rgb>>16)&255)/255,((rgb>>8)&255)/255,(rgb&255)/255))
  end
  local vertex=1
  for _,f in ipairs(faces) do
    for _,c in ipairs(corners[f[4]]) do write(obj,('v %d %d %d\n'):format(f[1]+c[1],f[2]+c[2],f[3]+c[3])) end
    write(obj,('usemtl block%d\nf %d %d %d %d\n'):format(f[5],vertex,vertex+1,vertex+2,vertex+3))
    vertex=vertex+4
  end
  close(obj); close(mtl)
  print(('Generated %d exposed faces. Open %s.html in a browser, or import %s.obj into a 3D editor.'):format(#faces,prefix,prefix))
end
local ok,err=pcall(main)
if not ok then io.stderr:write('Error: '..tostring(err)..'\n'); os.exit(1) end
