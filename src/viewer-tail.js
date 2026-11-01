corners=[[[1,0,0],[1,1,0],[1,1,1],[1,0,1]],[[0,0,1],[0,1,1],[0,1,0],[0,0,0]],[[0,1,1],[1,1,1],[1,1,0],[0,1,0]],[[0,0,0],[1,0,0],[1,0,1],[0,0,1]],[[1,0,1],[1,1,1],[0,1,1],[0,0,1]],[[0,0,0],[0,1,0],[1,1,0],[1,0,0]]], colors=["#000000","#78ad48","#866044","#858c92","#d8ca8b","#498faf","#765037","#3d803e"];
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
</script></html>