/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.test.app;

import hauntologl.window;
import hauntologl.gl.vertices;
import hauntologl.gl.shaders;
import hauntologl.gl.draw;
import hauntologl.gl.traits;
import gl3n.linalg;

import std.stdio;
import core.thread;
import hauntologl.gl.framebuffers;
version(TESTAPP):

alias vec2f = Vector!(float, 2);
alias vec4ub = Vector!(ubyte, 4);

struct Vertex {
	vec2f aPos;
	@Normalized vec4ub aColor;
}

void main() {
	auto win = new Window(800, 600);

	win.makeCurrent();

	auto vertSource = import("source/hauntologl/test/vertex.glsl");
	auto fragSource = import("source/hauntologl/test/fragment.glsl");

	auto vertShader = new VertexShader(vertSource);
	auto fragShader = new FragmentShader(fragSource);

	auto fb = new FBO();
	auto rb = new RenderBuffer();

	fb.attach(rb);

	try vertShader.compile();
	catch(Exception e) {
		writeln (vertShader.getLog());
		throw e;
	}
	try	fragShader.compile();
	catch (Exception e) {
		writeln(fragShader.getLog());
		throw e;
	}

	auto program = new ShaderProgram();
	try {
		program.attachShader(vertShader);
		program.attachShader(fragShader);
		program.link();
	} catch (Exception e) {
		writeln(program.getLog());
		throw e;
	}
	program.use();

	Vertex[] vertices = [
		Vertex(vec2f(-0.5, -0.5), vec4ub(ubyte.max, ubyte.min, ubyte.min, ubyte.max)),
		Vertex(vec2f(0.5, -0.5), vec4ub(ubyte.min, ubyte.max, ubyte.min , ubyte.max)),
		Vertex(vec2f(0, 0.5), vec4ub(ubyte.min, ubyte.min, ubyte.max, ubyte.max))
	];

	auto vao = InterleavedVAO!Vertex(VBO.Type.Static, new VBO());

	vao.update(vertices);
	vao.useShader(program);
	
	while(true) {
		import bindbc.sdl;

		SDL_Event e;
		while (SDL_PollEvent(&e) > 0) {
			switch (e.type) {
			case SDL_QUIT:
				SDL_Quit();
				return;
			default:
				break;
			}
		}

		vao.bind();
		clear(vec4ub(cast(ubyte)63, cast(ubyte)127, cast(ubyte)255, cast(ubyte)255));
		vao.draw(Primitive.Triangles, 0, 3);

		win.swap();
		Thread.sleep(dur!"msecs"(100));
	}
	
}