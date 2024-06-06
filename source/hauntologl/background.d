module hauntologl.background;

import gl3n.linalg;
import hauntologl.gl.vertices;
//import hauntologl.gl.textures;
//import hauntologl.gl.shaders;
import hauntologl.drawable;



struct BGVertex {
	Coord[] pos;
	Coord[] texPos;
	Coord[] palPos;
}

struct LightingVertex {
	Coord[] pos;
	ubyte[4][] color;
}

struct Background {
	RenderStates state;

}