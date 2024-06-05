/**      This file is part of HauntoloGL.

    HauntoloGL is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General 
	Public License as published by the Free Software Foundation, either version 3 of the License, 
	or (at your option) any later version.

    HauntoloGL is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the 
	implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser 
	General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License along with HauntoloGL. 
	If not, see <https://www.gnu.org/licenses/>. */

module hauntologl.gl.config;
import std.traits;

private bool triedInit = false;

version (GLES_20) {
	public import bindbc.gles.gles;

	GLESSupport GLVersion;

	void ensureGL() {
		import std.stdio;

		writeln("Loading GLES");
		if (!triedInit) GLVersion = loadGLES();
		writeln(GLVersion);
		triedInit = true;
	}
	
	enum MAX_VECTOR_LENGTH = 4;
	enum MAX_VERTEX_COMPONENTS = 8;
} else version (GL_20) {
	public import bindbc.opengl;

	GLSupport GLVersion;

	void ensureGL() {
		import std.stdio;
		writeln("Loading GL");
		if (!triedInit) GLVersion = loadOpenGL();
		writeln("GLVersion");
		triedInit = true;

	}

	enum MAX_VECTOR_LENGTH = 4;
	enum MAX_VERTEX_COMPONENTS = 8;
}
